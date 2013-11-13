define(
    "JBrowse/ConfigManager", [
        'dojo/_base/declare',
        'JBrowse/Util'
    ],
function( declare, Util ) { return declare(null,

/**
 * @lends JBrowse.ConfigManager.prototype
 */
{

/**
 * @constructs
 */
constructor: function( args ) {

  	console.group("JBrowse.ConfigManager-" + this.id + "    constructor");

    console.log("ConfigManager.constructor    START    args:");
    console.dir({args:args});

    this.config = dojo.clone( args.config || {} );
    this.defaults = dojo.clone( args.defaults || {} );
    this.browser = args.browser;
    this.skipValidation = args.skipValidation;
    this.topLevelIncludes = this.config.include || this.defaults.include;
    delete this.defaults.include;
    delete this.config.include;

    console.log("ConfigManager.constructor    END");

  	console.groupEnd("JBrowse.ConfigManager-" + this.id + "    constructor");
},

/**
 * @param callback {Function} callback, receives a single arguments,
 * which is the final processed configuration object
 */
getFinalConfig: function( callback ) {

    console.log("ConfigManager.getFinalConfig    DOING this._loadIncludes() dojo.hitch");

    this._loadIncludes({ include: this.topLevelIncludes }, dojo.hitch( this, function( includedConfig ) {

        console.log("ConfigManager.getFinalConfig    INSIDE this._loadIncludes() dojo.hitch");
        console.log("ConfigManager.getFinalConfig    includedConfig: ");
        console.dir({includedConfig:includedConfig});
        console.log("ConfigManager.getFinalConfig    this.config: ");
        console.dir({this_config:this.config});

        // merge the root config *into* the included config last, so
        // that values in the root config override the others
        this.config = this._mergeConfigs( includedConfig, this.config );

        // now validate the final merged config, and finally give it
        // to the callback
        this.config = this._applyDefaults( this.config, this.defaults );
        if( ! this.skipValidation ) {

            console.log("ConfigManager.getFinalConfig    this.config:");
            console.dir({this_config:this.config});
            
            this._validateConfig( this.config );
        }

        console.log("ConfigManager.getFinalConfig    DOING callback(this.config)");

        callback( this.config );
    }));
},

/**
 * Instantiate the right config adaptor for a given configuration source.
 * @param {Object} config the configuraiton
 * @param {Function} callback called with the new config object
 * @returns {Object} the right configuration adaptor to use, or
 * undefined if one could not be found
 * @private
 */

_getConfigAdaptor: function( config_def, callback ) {
    console.log("ConfigManager._getConfigAdaptor    config_def: " + dojo.toJson(config_def));
    
    var adaptor_name = "JBrowse/ConfigAdaptor/" + config_def.format;
    if( 'version' in config_def )
        adaptor_name += '_v'+config_def.version;
    adaptor_name.replace( /\W/g,'' );
    console.log("ConfigManager._getConfigAdaptor    adaptor_name: " + adaptor_name);
    console.dir({adaptor_name:adaptor_name});
    
    return require([adaptor_name], function(adaptor_class) {
        //console.log("ConfigManager._getConfigAdaptor    INSIDE REQUIRE    adaptor_class: " + adaptor_class);
        //console.dir({adaptor_class:adaptor_class});
        console.log("ConfigManager._getConfigAdaptor    INSIDE REQUIRE    config_def: " + config_def);
        console.dir({config_def:config_def});

        callback( new adaptor_class( config_def ) );

    });
},

/**
 * Recursively fetch, parse, and merge all the includes in the given
 * config object.  Calls the callback with the resulting configuration
 * when finished.
 * @private
 */
_loadIncludes: function( inputConfig, callback ) {
    inputConfig = dojo.clone( inputConfig );

    var includes = inputConfig.include || [];
    console.log("ConfigManager._loadIncludes    includes: " + dojo.toJson(includes));

    delete inputConfig.include;

    // coerce include to an array
    if( typeof includes != 'object' )
        includes = [ includes ];
    // coerce bare strings in the includes to URLs
    for (var i = 0; i < includes.length; i++) {
        if( typeof includes[i] == 'string' )
            includes[i] = { url: includes[i] };
    }

    var configs_remaining = includes.length;
    var included_configs = dojo.map( includes, function( include ) {

        console.log("ConfigManager._loadIncludes    include: " + dojo.toJson(include));

        var loadingResult = {};

        // include array might have undefined elements in it if
        // somebody left a trailing comma in and we are running under
        // IE
        if( !include )
            return loadingResult;

        // set defaults for format and version
        if( ! ('format' in include) ) {
            include.format = 'JB_json';
        }
        if( include.format == 'JB_json' && ! ('version' in include) ) {
            include.version = 1;
        }

        // instantiate the adaptor and load the config
        this._getConfigAdaptor( include, dojo.hitch(this, function(adaptor) {
            
            console.log("ConfigManager._loadIncludes    INSIDE dojo.hitch    adaptor:");
            console.dir({adaptor:adaptor});

            if( !adaptor ) {
                loadingResult.error = "Could not load config "+include.url+", no configuration adaptor found for config format "+include.format+' version '+include.version;
                return;
            }

            console.log("ConfigManager._loadIncludes    include: ");
            console.dir({include:include});
            
            adaptor.load({
                config: include,
                baseUrl: inputConfig.baseUrl,
                onSuccess: dojo.hitch( this, function( config_data ) {
                    this._loadIncludes( config_data, dojo.hitch(this, function( config_data_with_includes_resolved ) {
                        loadingResult.loaded = true;
                        loadingResult.data = config_data_with_includes_resolved;
                        if( ! --configs_remaining )
                            callback( this._mergeIncludes( inputConfig, included_configs ) );
                     }));
                }),
                onFailure: dojo.hitch( this, function( error ) {
                    
                    console.log("ConfigManager._loadIncludes    onFailure    error: ");
                    console.dir({error:error});
                            
                    loadingResult.error = error;
                    if( error.status != 404 ) // if it's a missing file, browser will have logged it
                        this._fatalError( error );
                    if( ! --configs_remaining )
                        callback( this._mergeIncludes( inputConfig, included_configs ) );
                })
            });
        }));
        return loadingResult;
    }, this);

    // if there were not actually any includes, just call our callback
    if( ! included_configs.length ) {
        callback( inputConfig );
    }

    console.log("ConfigManager._loadIncludes    END");
},

/**
 * @private
 */
_mergeIncludes: function( inputConfig, config_includes ) {
    // load all the configuration data in order
    dojo.forEach( config_includes, function( config ) {
                      if( config.loaded && config.data )
                              this._mergeConfigs( inputConfig, config.data );
                  }, this );
    return inputConfig;
},

/**
 * @private
 */
_applyDefaults: function( config, defaults ) {
    return Util.deepUpdate( dojo.clone(defaults), config );
},

/**
 * Examine the loaded and merged configuration for errors.  Throws
 * exceptions if it finds anything amiss.
 * @private
 * @returns nothing meaningful
 */
_validateConfig: function( c ) {
    
    console.log("ConfigManager._validateConfig    caller: " + this._validateConfig.caller.nom);
    console.log("ConfigManager._validateConfig    c: ");
    console.dir({c:c});

    if( ! c.tracks || ! c.tracks.length )
        this._fatalError('No tracks defined in configuration.');
    if( ! c.baseUrl ) {
        this._fatalError( 'Must provide a <code>baseUrl</code> in configuration' );
    }
    if( this.hasFatalErrors )
        throw "Errors in configuration, cannot start.";

    console.log("ConfigManager._validateConfig    END");
},

/**
 * @private
 */
_fatalError: function( error ) {
    this.hasFatalErrors = true;
    if( error.url )
        error = error + ' when loading '+error.url;
    this.browser.fatalError( error );
},

/**
 * Merges config object b into a.  a <- b
 * @private
 */
_mergeConfigs: function( a, b, spaces ) {
    console.log("ConfigManager._mergeConfigs    a.tracks: ");
    console.dir({a_tracks:a.tracks});
    console.log("ConfigManager._mergeConfigs    b.tracks: ");
    console.dir({b_tracks:b.tracks});
    
    if( b === null )
        return null;

    if( a === null )
        a = {};

    for (var prop in b) {
        if( prop == 'tracks' && (prop in a) ) {

            console.log("ConfigManager._mergeConfigs    DOING this._mergeTrackConfigs( a[prop], b[prop] )");
            
            a[prop] = this._mergeTrackConfigs( a[prop], b[prop] );
        }
        else if ( (prop in a)
              && ("object" == typeof b[prop])
              && ("object" == typeof a[prop]) ) {
            a[prop] = this._mergeConfigs(a[prop], b[prop]);
        } else if( typeof a[prop] == 'undefined' || typeof b[prop] != 'undefined' ){
            a[prop] = b[prop];
        }
    }

    console.log("ConfigManager._mergeConfigs    FINAL a.tracks: ");
    console.dir({a_tracks:a.tracks});
    
    return a;
},

/**
 * Special-case merging of two <code>tracks</code> configuration
 * arrays.
 * @private
 */
_mergeTrackConfigs: function( a, b ) {
    if( ! b.length ) return;

    // index the tracks in `a` by track label
    var aTracks = {};
    dojo.forEach( a, function(t,i) {
        t.index = i;
        aTracks[t.label] = t;
    });

    dojo.forEach( b, function(bT) {
        var aT = aTracks[bT.label];
        if( aT ) {
            this._mergeConfigs( aT, bT );
        } else {
            a.push( bT );
        }
    },this);

    return a;
}

});
});

