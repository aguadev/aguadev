/**
 * CLASS  	PluginManager

 * PURPOSE 	MANAGE EXTERNAL PLUGINS ON TOP OF dojo FRAMEWORK
 * LICENCE 	Copyright (c) 2012 Stuart Young youngstuart@hotmail.com
 *          This code is freely distributable under the terms of an MIT-style license.
*/

define( "plugins/core/PluginManager",
[
	"dojo/_base/declare",
	"dojo/Deferred",
	"dojo/DeferredList",
	"dojo/promise/all",
]
,
function (
	declare,
	Deferred,
	DeferredList,
	all
) {

return declare("plugins/dijit/InputDialog",
	[], {

// HASH OF INSTALLED PLUGINS
_installedPlugins : {},
plugins : [],

parentWidget : null,

// PLUGINS TO BE LOADED
pluginsList : null,

// ARGUMENTS FOR PLUGINS TO BE LOADED
pluginsArgs : null,

// loaded : Boolean
//		Set to true if the plugins have been loaded
loaded : false,

////}}}}

constructor : function(args) {
	//console.log("PluginManager.constructor      ");
	
	// SET INPUT PLUGINS LIST IF PROVIDED
	if ( args.pluginsList != null && args.pluginsList )
		this.pluginsList = args.pluginsList;

	// SET INPUT PLUGINS LIST IF PROVIDED
	if ( args.pluginsArgs != null && args.pluginsArgs )
		this.pluginsArgs = args.pluginsArgs;

	// SET PARENT WIDGET IF PROVIDED
	if ( args.parentWidget != null && args.parentWidget )
		this.parentWidget = args.parentWidget;
	
	// LOAD PLUGINS
	this.loadPlugins();
},

loadPlugins : function ()   {
	console.group("PluginManager.loadPlugins    this.loaded: " + this.loaded);
	if ( this.loaded == true ) {
	    console.groupEnd("PluginManager.loadPlugins");
		console.group("PluginManager.loadPlugins    this.loaded is true. Returning");
		return;
	}

	console.group("PluginManager.loadPlugins    this.pluginsList: ");
	console.dir({this_pluginsList:this.pluginsList});
	console.log("PluginManager.loadPlugins    caller: " + this.loadPlugins.caller.nom);
	
	var length = this.pluginsList.length;
	if ( ! length )	return;
	for ( var i = 0; i < this.pluginsList.length; i++ ) {
		var number = parseInt( (i * 2) + 1);
		console.log("PluginManager.loadPlugins    ******* plugin number" + number);

		var pluginName = this.pluginsList[i];
		console.log("PluginManager.loadPlugins     this.pluginsList[" + i + "]:  " + pluginName);

		this.loadPlugin(pluginName, i, length);
		console.log("PluginManager.loadPlugins    plugin " + number + " " + pluginName);
	}

	console.dir({Agua_data:Agua.data});
    console.groupEnd("PluginManager.loadPlugins    this.pluginsList: ");
	
	// SET this.loaded TO TRUE
	this.loaded = true;
},

loadPlugin : function (pluginName, index, length) {
	console.group("PluginManager.loadPlugin    ooooooooooooooooo pluginName: " + pluginName);
	console.log("PluginManager.loadPlugin    ooooooooooooooooo index: " + index);

	var moduleName = pluginName.match(/^plugins\.([^\.]+)\./)[1];

	// REPORT PROGRESS
	var doubleLength = 2 * length;
	var number = parseInt( (index * 2) + 1);
	this.percentProgress(doubleLength, number, "Loading plugin: " + moduleName);
 
	// LOAD MODULE
	console.log("PluginManager.loadPlugin    ooooooooooooooooo DOING dojo[require](" + pluginName + ");");
	var success = dojo["require"](pluginName);
	console.log("PluginManager.loadPlugin    ooooooooooooooooo AFTER dojo[require](" + pluginName + ");");
	
	// INSTANTIATE WIDGET
	var args = "";
	if ( this.pluginsArgs && this.pluginsArgs[index] )
		args = this.pluginsArgs[index];
	console.log("PluginManager.loadPlugin    ooooooooooooooooo args: ");
	console.dir({args:args});
		
	var command		=	"new " + pluginName + "({ inputs: '" + args + "'})";
	console.log("PluginManager.loadPlugin    ooooooooooooooooo command: " + command);
	var newPlugin 	=	eval(command);

	// SAVE TO controllers
	console.log("PluginManager.loadPlugin    ooooooooooooooooo DOING Agua.controllers[" + moduleName + "] = newPlugin");
	Agua.controllers[moduleName] = newPlugin;
	
	// DO postLoad IF PRESENT
	console.log("PluginManager.loadPlugin    ooooooooooooooooo DOING newPlugin.postLoad: " + newPlugin.postLoad);
	if ( newPlugin.postLoad )	newPlugin.postLoad();

	//// CHECK DEPENDENCIES
	var verified = this.checkDependencies(newPlugin.dependencies);
	//console.log("PluginManager.loadPlugin    verified: " + verified);
	
	// REPORT PROGRESS
	var thisObj = this;
	setTimeout(function() {
		thisObj.percentProgress(doubleLength, number, "Completed loading: " + moduleName);

		//deferred.resolve({success:true});
	},
	10);

	this.loaded = true;
	
	console.groupEnd("PluginManager.loadPlugin    ooooooooooooooooo pluginName: " + pluginName);
},
percentProgress : function (total, current, message) {
	console.log("PluginManager.percentProgress    ooooooooooooooooo total plugins: " + total);
	console.log("PluginManager.percentProgress    ooooooooooooooooo current plugin: " + current);

	// DEFAULT MESSAGE IS EMPTY
	if ( ! message )	message = '';
	console.log("PluginManager.percentProgress    	" + current + " out of " + total +", message:" + message);

	var percent = 0;
	if ( total == current )
		percent = 100;
	else
		percent = parseInt((current/total) * 100);

	console.log("PluginManager.percentProgress    percent: " + percent);
	if ( ! Agua.login )	return;
	
	console.log("PluginManager.percentProgress    DOING Agua.login.progressBar.set()");
	console.log("PluginManager.percentProgress    Agua.login: " + Agua.login);
	console.log("PluginManager.percentProgress    Agua.login.progressBar: " + Agua.login.progressBar);
	Agua.login.progressBar.set({value:percent, progress:percent});
	console.log("PluginManager.percentProgress    AFTER Agua.login.progressBar.set()");
	
	Agua.login.progressMessage.innerHTML = message;
},
_milestoneFunction : function( /**String*/ name, func ) {

    console.log("Browser._milestoneFunction    name: " + name);
    
    var thisB = this;
    var args = Array.prototype.slice.call( arguments, 2 );

    var d = thisB._getDeferred( name );
    args.unshift( d );
    try {
        func.apply( thisB, args ) ;
    } catch(e) {
        console.error( e, e.stack );
        d.resolve({ success:false, error: e });
    }

    return d;
},
/**
 * Fetch or create a named Deferred, which is how milestones are implemented.
 */
_getDeferred : function( name ) {
    if( ! this._deferred )
        this._deferred = {};
    return this._deferred[name] = this._deferred[name] || new Deferred();
},
checkDependencies : function (dependencies) {
	// CHECK DEPENDENCIES ARE ALREADY LOADED AND CORRECT VERSION
	//console.log("PluginManager.checkDependencies    plugins.core.PluginManager.checkDependencies");
	//console.dir({installedPlugins:this._installedPlugins});
	//console.log("PluginManager.checkDependencies    this._installedPlugins: " + dojo.toJson(this._installedPlugins));
	
	// DEBUG
	return 1;
	
	if ( ! dependencies )	{	return 1;	}
	
	//console.log("PluginManager.checkDependencies     dependencies is defined");
	//console.log("PluginManager.checkDependencies     dependencies: " + dojo.toJson(dependencies));	
	
	for ( var i = 0; i < dependencies.length; i++ )
	{
		//console.log("PluginManager.checking dependencies[" + i + "]: " + dojo.toJson(dependencies[i]));
		var requiredName = dependencies[i].name;
		var requiredVersion = dependencies[i].version;
		//console.log("PluginManager.requiredName: " + requiredName);

		// CHECK DEPENDENCY CLASS IS LOADED
		if ( requiredName )
		{
			////console.log("PluginManager.Dependency is loaded: " + requiredName);                
			////console.log("PluginManager.this._installedPlugins.length: " + this._installedPlugins.length);
			//console.dir({installedPlugins:this.installedPlugins});


			var dependency = Agua.controllers[requiredName];


			//var dependency = this._installedPlugins[requiredName];

			////console.log("PluginManager.dependency: " + dojo.toJson(dependency));
			
			// CHECK VERSION IS MINIMUM OR GREATER
			if ( dependency.version >= requiredVersion  )    
			{        
				// CHECK THAT THE DEPENDENCY ACTUALLY INSTALLED OKAY
				if ( ! dependency.installed )
				{
					//console.log("PluginManager.checkDependencies     Required dependency is not installed: " + requiredName + ". Dependency is present but dependency.installed is false");
					return 0;
				}
				else
				{
					////console.log("PluginManager.Required dependency is installed: " + requiredName);
				}
			}
			else
			{
				//console.log("PluginManager.checkDependencies     Actual dependency '" + requiredName + "' version (" + dependency.version + ") < required version (" + requiredVersion + ")");
				return 0;
			}
		}
		else
		{
			//console.log("PluginManager.checkDependencies     Required dependency is not loaded:" + requiredName);
			return 0;
		}
	}
	
	//console.log("PluginManager.checkDependencies     Dependencies satisfied"); 
	return 1;        
},
getInstalledPlugins : function ()   {
// RETURN HASH OF INSTALLED PLUGINS
	return this._installedPlugins;
}

});

});

