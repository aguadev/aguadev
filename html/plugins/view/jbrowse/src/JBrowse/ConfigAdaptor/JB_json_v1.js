define( "JBrowse/ConfigAdaptor/JB_json_v1", [ 'dojo/_base/declare',
          'dojo/_base/lang',
          'dojo/_base/array',
          'dojo/_base/json',
          'JBrowse/Util',
          'JBrowse/Digest/Crc32',
          'JBrowse/ConfigAdaptor/AdaptorUtil'
        ], function( declare, lang, array, json, Util, digest, AdaptorUtil ) {

var dojof = Util.dojof;

return declare('JBrowse.ConfigAdaptor.JB_json_v1',null,

    /**
     * @lends JBrowse.ConfigAdaptor.JB_json_v1.prototype
     */
    {

        /**
         * Configuration adaptor for JBrowse JSON version 1 configuration
         * files (formerly known as trackList.json files).
         * @constructs
         */
        constructor: function() {},

        /**
         * Load the configuration file from a URL.
         *
         * @param args.config.url {String} URL for fetching the config file.
         * @param args.onSuccess {Function} callback for a successful config fetch
         * @param args.onFailure {Function} optional callback for a
         *   config fetch failure
         * @param args.context {Object} optional context in which to
         *   call the callbacks, defaults to the config object itself
         */
        load: function( /**Object*/ args ) {
            console.log("JB_json_v1.load    args.config.url: " + args.config.url);

            //console.log("JB_json_v1.load    args: ");
            //console.dir({args:args});

            var that = this;
            if( args.config.url ) {
                var url = Util.resolveUrl( args.baseUrl || window.location.href, args.config.url );
                var handleError = function(e) {
                    e.url = url;
                    if( args.onFailure )
                        args.onFailure.call( args.context || this, e );
                };
                dojo.xhrGet({
                                url: url,
                                handleAs: 'text',
                                load: function( o ) {
                                    try {
                                        o = that.parse_conf( o, args ) || {};
                                        o.sourceUrl = url;
                                        o = that.regularize_conf( o, args );

                                        //console.log("JB_json_v1.load    o: ");
                                        //console.dir({o:o});

                                        args.onSuccess.call( args.context || that, o );
                                    } catch(e) {
                                        handleError(e);
                                    }
                                },
                                error: handleError
                            });
            }
            else if( args.config.data ) {
                var conf = this.regularize_conf( args.config.data, args );
                args.onSuccess.call( args.context || this, conf );
            }
        },

        /**
         * In this adaptor, just evals the conf text to parse the JSON, but
         * other conf adaptors might want to inherit and override this.
         * @param {String} conf_text the configuration text
         * @param {Object} load_args the arguments that were passed to <code>load()</code>
         * @returns {Object} the parsed JSON
         */
        parse_conf: function( conf_text, load_args ) {
            return json.fromJson( conf_text );
        },

        /**
         * Applies defaults and any other necessary tweaks to the loaded JSON
         * configuration.  Called by <code>load()</code> on the JSON
         * configuration before it calls the <code>onSuccess</code> callback.
         * @param {Object} o the object containing the configuration, which it
         *                   modifies in-place
         * @param {Object} load_args the arguments that were passed to <code>load()</code>
         * @returns the same object it was passed
         */
        regularize_conf: function( o, load_args ) {

            //console.log("JB_json_v1.regularize_conf    o: ");
            //console.dir({o:o});
            //console.log("JB_json_v1.regularize_conf    load_args: ");
            //console.dir({load_args:load_args});

            o.sourceUrl = o.sourceUrl || load_args.config.url;
            o.baseUrl   = o.baseUrl || Util.resolveUrl( o.sourceUrl, '.' );
            if( o.baseUrl.length && ! /\/$/.test( o.baseUrl ) )
                o.baseUrl += "/";

            // set a default baseUrl in each of the track and store confs, and the names conf, if needed
            if( o.sourceUrl ) {
                var addBase =
                    []
                    .concat( o.tracks || [] )
                    .concat( dojof.values(o.stores||{}) ) ;

                if( o.names )
                    addBase.push( o.names );
                array.forEach( addBase, function(t) {
                    if( ! t.baseUrl )
                        t.baseUrl = o.baseUrl || '/';
                },this);
            }

            o = AdaptorUtil.evalHooks( o );

            o = this._regularizeTrackConfigs( o );

            return o;
        },

        _regularizeTrackConfigs: function( conf ) {
            conf.stores = conf.stores || {};

            array.forEach( conf.tracks || [], function( trackConfig ) {
                
                //console.log("JB_json_v1._regularizeTrackConfigs    trackConfig.key: " + trackConfig.key);
                //console.dir({trackConfig:trackConfig});

                // if there is a `config` subpart,
                // just copy its keys in to the
                // top-level config
                if( trackConfig.config ) {
                    var c = trackConfig.config;
                    delete trackConfig.config;
                    for( var prop in c ) {
                        if( !(prop in trackConfig) && c.hasOwnProperty(prop) ) {
                            trackConfig[prop] = c[prop];
                        }
                    }
                }

                // skip if it's a new-style track def
                if( trackConfig.store )
                    return;                
                
                var trackClassName = this._regularizeClass(
                    'JBrowse/View/Track', {
                        'FeatureTrack':      'JBrowse/View/Track/HTMLFeatures',
                        'ImageTrack':        'JBrowse/View/Track/FixedImage',
                        'ImageTrack.Wiggle': 'JBrowse/View/Track/FixedImage/Wiggle',
                        'SequenceTrack':     'JBrowse/View/Track/Sequence'
                    }[ trackConfig.type ]
                    || trackConfig.type
                );
                trackConfig.type = trackClassName;

                // figure out what data store class to use with the track,
                // applying some defaults if it is not explicit in the
                // configuration
                var urlTemplate = trackConfig.urlTemplate;
                var storeClass = this._regularizeClass(
                    'JBrowse/Store',
                    trackConfig.storeClass                    ? trackConfig.storeClass :
                        /\/FixedImage/.test( trackClassName ) ? 'JBrowse/Store/TiledImage/Fixed' +( trackConfig.backendVersion == 0 ? '_v0' : '' )  :
                        /\.jsonz?$/i.test( urlTemplate )        ? 'JBrowse/Store/SeqFeature/NCList'+( trackConfig.backendVersion == 0 ? '_v0' : '' )  :
                        /\.bam$/i.test( urlTemplate )         ? 'JBrowse/Store/SeqFeature/BAM'                                                      :
                        /\.(bw|bigwig)$/i.test( urlTemplate ) ? 'JBrowse/Store/SeqFeature/BigWig'                                                   :
                        /\/Sequence$/.test( trackClassName )  ? 'JBrowse/Store/Sequence/StaticChunked'                                              :
                                                                 null
                );

                //console.log("JB_json_v1._regularizeTrackConfigs    storeClass: " + storeClass);

                if( ! storeClass ) {
                    console.error( "Unable to determine an appropriate data store to use with track '"
                                   + trackConfig.label + "', please explicitly specify a "
                                   + "storeClass in the configuration." );
                    return;
                }

                // synthesize a separate store conf
                var storeConf = lang.mixin( {}, trackConfig );
                lang.mixin( storeConf, {
                    type: storeClass
                });

                // if this is the first sequence store we see, and we
                // have no refseqs store defined explicitly, make this the refseqs store.
                if( storeClass == 'JBrowse/Store/Sequence/StaticChunked' && !conf.stores['refseqs'] )
                    storeConf.name = 'refseqs';
                else
                    storeConf.name = 'store'+digest.objectFingerprint( storeConf );

                // record it
                conf.stores[storeConf.name] = storeConf;

                // connect it to the track conf
                trackConfig.store = storeConf.name;

            }, this);

            return conf;
        },

        _regularizeClass: function( root, class_ ) {
            if( ! class_ )
                return null;

            // prefix the class names with JBrowse/* if they contain no slashes
            if( ! /\//.test( class_ ) )
                class_ = root+'/'+class_;
            class_ = class_.replace(/^\//);
            return class_;
        }
});
});
