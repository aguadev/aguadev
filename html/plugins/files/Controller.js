dojo.provide("plugins.files.Controller");

// OBJECT:  plugins.files.Controller
// PURPOSE: GENERATE AND MANAGE Workflow PANES

// INHERITS
dojo.require("plugins.core.Common");

// HAS
dojo.require("plugins.files.FileManager");

dojo.declare( "plugins.files.Controller",
	[ plugins.core.Common ], {

name: "plugins.files.Controller",
version : "0.01",
url : '',
description : "Load the floating pane File Manager",

dependencies :[
	{	name: "plugins.core.Agua", version: 0.01	}
],


//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/controller.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CSS FILE FOR BUTTON STYLING
cssFiles : [
	dojo.moduleUrl("plugins") + "workflow/css/controller.css",
	dojo.moduleUrl("plugins") + "workflow/css/workflow.css"
],

// ARRAY OF TAB PANES
tabPanes : [],

////}}}
constructor : function(args) {
	// LOAD CSS FOR BUTTON
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	////console.log("Controller.startup    plugins.files.Controller.startup()");
	////console.log("Controller.startup    Agua: " + Agua);

	this.inherited(arguments);

},
createFileManager : function () {
	//console.log("files.Controller.createFileManager    plugins.files.Controller.createFileManager()");
},
postLoad : function () {
		console.log("plugins.files.Controller.postLoad    DOING new plugins.files.FileManager");
		
// OPEN FILE MANAGER ONCE PLUGIN HAS LOADED
	Agua.fileManager = new plugins.files.FileManager({
		paneId: "fileManager" + this.paneId,
		tabsNodeId: "tabs"
	});	
}


}); // end of Controller

dojo.addOnLoad( function() {

});