dojo.provide("plugins.core.PluginController");

/* 	OBJECT:  plugins.core.PluginController

	PURPOSE: GENERIC PLUGIN CONTROLLER
*/

// INHERITS
dojo.require("plugins.core.Common");

dojo.declare( "plugins.core.PluginController",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
// PANE ID 
paneId : null,

//Path to the template of this widget. 
templatePath: null,

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CSS FILES
cssFiles : [],

// ARRAY OF TAB PANES
tabPanes : [],

// moduleName : String
// Name of tab pane class, e.g., "plugins.folders.Folders"
tabClass : null,

////}}}}

// CONSTRUCTOR	
constructor : function(args) {
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	//console.log("core.Controller.startup    plugins.core.Controller.startup()");
	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);
	
	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET ADMIN BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab", {});
},
createTab : function (args) {
	console.log("PluginController.createTab    args: ");
	console.dir({args:args});

	// CLEAR ANNOYING ALL-SELECTED
	window.getSelection().removeAllRanges();

	// SET DEFAULT ARGS
	if ( ! args )	args = {};

	// CREATE TAB WIDGET
	var module = dojo.getObject(this.tabClass);
	var widget = new module(args);
	this.tabPanes.push(widget);

	// ADD TAB WIDGET TO _supportingWidgets FOR INCLUSION IN DESTROY	
	this._supportingWidgets.push(widget);
}

}); // end of Controller

dojo.addOnLoad(
function()
{
	// CREATE TAB
	//Agua.controllers["folders"].createTab();		
}
);