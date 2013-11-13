dojo.provide("plugins.folders.Controller");

// OBJECT:  plugins.folders.Controller
// PURPOSE: GENERATE AND MANAGE Project PANES

// INHERITS
dojo.require("plugins.core.PluginController");

// HAS
dojo.require("plugins.folders.Folders");

dojo.declare( "plugins.folders.Controller",
	[ plugins.core.PluginController ],
{
// PANE ID 
paneId : null,

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "folders/templates/controller.html"),

// CSS FILES
cssFiles : [ dojo.moduleUrl("plugins") + "/folders/css/controller.css" ],

// ARRAY OF TAB PANES
tabPanes : [],

// TAB CLASS
tabClass : "plugins.folders.Folders",

////}}}}

}); // end of Controller

dojo.addOnLoad(
function()
{
	// CREATE TAB
	//Agua.controllers["folders"].createTab();		
}
);