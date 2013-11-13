/**
 * CLASS  	PluginManager

 * PURPOSE 	MANAGE EXTERNAL PLUGINS ON TOP OF dojo FRAMEWORK
 * LICENCE 	Copyright (c) 2012 Stuart Young youngstuart@hotmail.com
 *          This code is freely distributable under the terms of an MIT-style license.
*/

//dojo.provide("plugins.core.PluginManager");
//
//dojo.require("plugins.core.Plugin");
//
//// OBJECT:  PluginManager
//// PURPOSE: LOAD ALL PLUGINS
//
//dojo.declare( "plugins.core.PluginManager", null,
//{

define( "plugins/core/PluginManager",
[
	"dojo/_base/declare"
	//,
	//"plugins/core/Plugin"
]
,
function (
	declare
	//,
	//Plugin
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
	console.group("PluginManager.loadPlugins    this.pluginsList: ");
	console.dir({this_pluginsList:this.pluginsList});
	
	var length = this.pluginsList.length;
	if ( ! length )	return;
	var doubleLength = 2 * length;
	
	for ( var i = 0; i < this.pluginsList.length; i++ )
	{
		var number = parseInt( (i * 2) + 1);
		console.log("PluginManager.loadPlugins    ******* plugin number" + number);
		var pluginName = this.pluginsList[i];
		console.log("PluginManager.loadPlugins     this.pluginsList[" + i + "]:  " + pluginName);

		var moduleName = pluginName.match(/^plugins\.([^\.]+)\./)[1];
		//console.log("PluginManager.loadPlugins    moduleName: " + dojo.toJson(moduleName));
		//console.log("PluginManager.loadPlugins    pluginName: " + dojo.toJson(pluginName));

		// REPORT PROGRESS
		this.percentProgress(doubleLength, number, "Loading plugin: " + moduleName);
	 
		// LOAD MODULE
		console.log("PluginManager.loadPlugins    DOING dojo[require](" + pluginName + ");");
		var success = dojo["require"](pluginName);
		console.log("PluginManager.loadPlugins    AFTER dojo[require](" + pluginName + ");");
		
		// INSTANTIATE WIDGET
		
		var args = "";
		if ( this.pluginsArgs && this.pluginsArgs[i] )
			args = this.pluginsArgs[i];
		console.log("PluginManager.loadPlugins    args: ");
		console.dir({args:args});
			
		var command= "new " + pluginName + "({ inputs: '" + args + "'})";
		console.log("PluginManager.loadPlugins    command: " + command);
		var newPlugin = eval (command);

		// SAVE TO controllers
		console.log("PluginManager.loadPlugins    DOING Agua.controllers[" + moduleName + "] = newPlugin");
		Agua.controllers[moduleName] = newPlugin;
		
		// DO postLoad IF PRESENT
		console.log("PluginManager.loadPlugins    DOING newPlugin.postLoad: " + newPlugin.postLoad);
		if ( newPlugin.postLoad )	newPlugin.postLoad();
	
		//// CHECK DEPENDENCIES
		var verified = this.checkDependencies(newPlugin.dependencies);
		//console.log("PluginManager.loadPlugins    verified: " + verified);
		
		var number = parseInt( (i * 2) + 2);
		//console.log("PluginManager.loadPlugins    ooooooooooooooooo plugin number" + number);

		// REPORT PROGRESS
		this.percentProgress(doubleLength, number, "Completed loading: " + moduleName);
	}

	console.log("PluginManager.loadPlugins    	FINAL Agua.data: ");
	console.dir({Agua_data:Agua.data});
    console.groupEnd("PluginManager.loadPlugins    this.pluginsList: ");
},
percentProgress : function (total, current, message) {
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
	
	Agua.login.progressBar.set({value:percent, progress:percent});
	
	Agua.login.progressMessage.innerHTML = message;
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

