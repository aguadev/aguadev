dojo.provide("plugins.core.Plugin");

/**
 * PLUGIN FRAMEWORK, Version 0.1
 * Copyright (c) 2012 Stuart Young youngstuart@hotmail.com
 * This code is freely distributable under the terms of an MIT-style license.
 * 
 *  This code provides the following functions
 *
 *    Plugin.isInstalled(String name)           // RETURN Boolean PLUGIN INSTALL STATUS
 *    Plugin.getVersion(String name)            // RETURN PLUGIN VERSION
 *    Plugin.getDescription(String name)        // RETURN PLUGIN DESCRIPTION
 *    Plugin.getPluginPage(String name)         // RETURN PLUGIN URL
 *    Plugin.getInfo(String name)               // RETURN PLUGIN INFO (NAME, VERSION, DESCRIPTION, IS INSTALLED)
 *
 *        Boolean isInstalled
 *        String  version
 *        String  description
 *        String  pluginPage   URL to download the plugin
 *
 * CHANGELOG:
 * Sat 18th October 2008: Version 0.1
 *   load plugins
 *   load plugins
 *   added license
 * 
 * you may remove the comments section, but please leave the copyright
/*--------------------------------------------------------------------*/

// OBJECT:  Plugin
// PURPOSE: ATTEMPT TO LOAD A PLUGIN USING dojo.require AND STORE
//			WHETHER THE LOAD WAS SUCCESSFUL OR NOT AS installed=BOOLEAN

dojo.declare( "plugins.core.Plugin", null, {

installed : false,

////}}}}

setInstalled : function () {
	if ( this.installed != false && installed != true )
		return 0;
	this.installed = true;

	return 1;
},

getInstalled : function () {
	return this.installed;    
},

getVersion : function () {
	return this.version;
},

getDescription : function () {
	return this.description;
},

getPluginUrl : function () {
	return this.pluginUrl;
},

getInfo : function () {
	var info = '';
	info += 'Status: ';
	info += this.getInstalled();
	info += '\n';
	info += 'Version: ';
	info += this.version();
	info += '\n';
	info += 'Description: ';
	info += this.description();
	info += '\n';
	info += 'Plugin Url: ';
	info += this.pluginUrl();
	info += '\n';
	
	return info;
}

});    
    