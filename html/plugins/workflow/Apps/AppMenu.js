dojo.provide("plugins.workflow.Apps.AppMenu");

// ALLOW THE USER TO ADD, REMOVE AND MODIFY APPS

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dojo.parser");

// HAS A
dojo.require("dijit.Menu");
dojo.require("plugins.menu.Menu");

// INHERITS
dojo.require("plugins.core.Common");


dojo.declare("plugins.workflow.Apps.AppMenu",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/Apps/templates/appsmenu.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingApp STATE
addingApp : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins") + "/workflow/Apps/css/appsmenu.css" ],


// PARENT WIDGET
parentWidget : null,

// CORE WORKFLOW OBJECTS
core : null,

/////}
constructor : function(args) {
	//////console.log("AppsMenu.constructor     plugins.workflow.AppMenu.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	//////console.log("AppsMenu.constructor     this.parentWidget: " + this.parentWidget);
	//////console.log("AppsMenu.constructor     this.parentWidget.parentWidget: " + this.parentWidget.parentWidget);

	// LOAD CSS
	this.loadCSS();		
},

postCreate : function() {
	//////console.log("Controller.postCreate    plugins.workflow.Controller.postCreate()");

	this.startup();
},


startup : function () {
	//////console.log("AppsMenu.startup    plugins.workflow.AppMenu.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// SET DRAG APP - LIST OF APPS
	this.setMenu();
},


bind : function (node) {
// BIND THE MENU TO A NODE
	//////console.log("AppsMenu.bind     plugins.workflow.AppMenu.bind(node)");

	if ( node == null )
	{
		//////console.log("AppsMenu.bind     node is null. Returning...");
		
	}
	return this.menu.bindDomNode(node);	
},

about : function (event) {
// SHOW 'ABOUT' INFORMATION
	////console.log("AppsMenu.about     plugins.workflow.Workflow.about()");
	////console.log("AppsMenu.about     this.parentWidget: " + this.parentWidget);
	////console.log("AppsMenu.about     this.parentWidget.parentWidget: " + this.parentWidget.parentWidget);

	event.stopPropagation();

	var appRow = this.menu.currentTarget.parentWidget;
	//console.log("FileMenu.onUploadComplete    appRow: " + appRow);
	if ( appRow == null ) 	return;
	
	var application = appRow.application;
	//console.log("FileMenu.onUploadComplete    application: " + dojo.toJson(application));
	if ( application == null )	return;
	
	var linkurl = application.linkurl;
	//console.log("FileMenu.onUploadComplete    linkurl: " + linkurl);
	
	window.open(linkurl);
},		

website : function (event) {
// OPEN WINDOW TO APPLICATION WEBSITE
	//console.log("AppsMenu.website     plugins.workflow.Workflow.website(event)");
	event.stopPropagation();

	var appRow = this.menu.currentTarget.parentWidget;
	//console.log("FileMenu.onUploadComplete    appRow: " + appRow);
	if ( appRow == null ) 	return;
	
	var application = appRow.application;
	//console.log("FileMenu.onUploadComplete    application: " + dojo.toJson(application));
	if ( application == null )	return;
	
	var url = application.url;
	//console.log("FileMenu.onUploadComplete    url: " + url);
	
	window.open(url);
	
},

setMenu : function () {
// ADD PROGRAMMATIC CONTEXT MENU
	//////console.log("AppsMenu.setMenu     plugins.workflow.Workflow.setMenu()");
	//////console.log("AppsMenu.setMenu     this.aboutNode: " + this.aboutNode);
	//////console.log("AppsMenu.setMenu     this.websiteNode: " + this.websiteNode);

}
	
}); // plugins.workflow.AppMenu

