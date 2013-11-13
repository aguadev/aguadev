dojo.provide("plugins.workflow.Controller");

// OBJECT:  plugins.workflow.Controller
// PURPOSE: GENERATE AND MANAGE Workflow PANES

// INHERITS
dojo.require("plugins.core.Common");

// HAS
dojo.require("plugins.workflow.Workflow");

dojo.declare( "plugins.workflow.Controller",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

name: "plugins.workflow.Controller",
version : "0.01",
url : '',
description : "",
dependencies : [
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
	//console.log("workflow.Controller.constructor    args:");
	//console.dir({args:args});

	// SET INPUTS IF PRESENT
	if ( args.inputs )
		this.inputs = args.inputs;
	
	// LOAD CSS FOR BUTTON
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	////console.log("Controller.startup    plugins.workflow.Controller.startup()");
	////console.log("Controller.startup    Agua: " + Agua);

	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);
	
	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET ADMIN BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab");
},
createTab : function (args) {
	////console.log("Controller.createTab    plugins.workflow.Controller.createTab");
	//console.log("Controller.createTab    args: ");
	//console.dir({args:args});

	// CLEAR ANNOYING ALL-SELECTED
	window.getSelection().removeAllRanges();

	if ( args == null ) args = new Object;
	args.attachWidget = Agua.tabs;

	// GET INPUTS
	var inputs = this.inputs;
	args.inputs=	inputs;
	
	// CREATE WIDGET	
	var widget = new plugins.workflow.Workflow(args);
	//var widget;
	//if ( ! inputs )
	//	widget = new plugins.workflow.Workflow(args);
	//else
	//	widget = new plugins.workflow.Workflow({inputs:inputs});


	this.tabPanes.push(widget);

	// ADD TO _supportingWidgets FOR INCLUSION IN DESTROY	
	this._supportingWidgets.push(widget);
},
refreshTabs : function () {
    //console.log("workflow.Controller.refreshTabs    Populating this.tabPanes");
    //console.log("workflow.Controller.refreshTabs    BEFORE this.tabPanes: ");
    //console.dir({this_tabPanes:this.tabPanes});

	var thisObject = this;
	dijit.registry.byClass("plugins.workflow.Workflow").forEach(function(workflow) {
		//console.log("workflow: " + workflow);
		//console.dir({workflow:workflow});
		thisObject.tabPanes.push(workflow);    
	});
    
    //console.log("workflow.Controller.refreshTabs    AFTER this.tabPanes: ");
    //console.dir({this_tabPanes:this.tabPanes});
}

}); // end of Controller

//dojo.addOnLoad( function() {
//		// CREATE TAB
//		Agua.controllers["workflow"].createTab();		
//	}
//);