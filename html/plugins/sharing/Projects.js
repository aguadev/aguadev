dojo.provide("plugins.sharing.Projects");

// ALLOW THE USER TO ADD, REMOVE AND MODIFY PROJECTS

// EXTERNAL MODULES
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.form.EditForm");

// HAS A
dojo.require("plugins.sharing.ProjectRow");

dojo.declare("plugins.sharing.Projects",
	[ dijit._Widget, dijit._Templated, plugins.core.Common, plugins.form.EditForm ],
{

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/projects.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//adding STATE
adding : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ "plugins/sharing/css/projects.css" ],

// PARENT WIDGET
parentWidget : null,

// FORM INPUTS AND TYPES (word|phrase)
formInputs : {
	name		: "word",
	description	: "phrase",
	notes		: "word"
},

defaultInputs : {
	name 		: "Name",
	description	: "Description",
	notes		: "Notes"
},
	
requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
	name 		: 1
},

invalidInputs : {
// INVALID INPUTS (e.g., DEFAULT INPUTS)
	name 		: "Name",
	description	: "Description",
	notes		: "Notes"
},

dataFields : [
	"name"
],

avatarItems : [
	"name",
	"description"
],

rowClass : "plugins.sharing.ProjectRow",

/////}}}

constructor : function(args) {
	//////console.log("Projects.constructor     plugins.sharing.Projects.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.projects = args.parentWidget.projects;

	// LOAD CSS
	this.loadCSS();		
},

postCreate : function() {
	//////console.log("Controller.postCreate    plugins.sharing.Controller.postCreate()");
	this.startup();
},

startup : function () {
	//////console.log("Projects.startup    plugins.sharing.Projects.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD TO TAB CONTAINER		
	this.attachPoint.addChild(this.projectsTab);
	this.attachPoint.selectChild(this.projectsTab);

	// SET DRAG PROJECT - LIST OF PROJECTS
	this.setDragSource();

	// SET NEW PROJECT FORM
	this.setForm();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateProjects");

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateWorkflows");

	// SET TRASH
	this.setTrash(this.dataFields);	
},

updateProjects : function (args) {
	//console.log("Projects.updateProjects    sharing.Projects.updateProjects(args)");
	//console.log("Projects.updateProjects    args:");
	//console.dir(args);

	// SET DRAG SOURCE
	if ( args == null || args.reload != false )
	{
		//console.log("Projects.updateProjects    Calling setDragSource()");
		this.setDragSource();
	}
},

setForm : function () {
	//console.log("Projects.setForm    plugins.sharing.Projects.setForm()");
	// SET ADD PROJECT ONCLICK
	dojo.connect(this.addProjectButton, "onClick", dojo.hitch(this, "saveInputs", null, null));
	
	// SET ONCLICK TO CANCEL INVALID TEXT
	this.setClearValues();

	// CHAIN TOGETHER INPUTS ON 'RETURN' KEYPRESS
	this.chainInputs(["name","description","notes", "addProjectButton"]);
},

getItemArray : function () {
	var dataArray = new Array;
	var itemArray = Agua.getProjects();
	//console.log("Projects.getItemArray    itemArray: " + dojo.toJson(itemArray));
	return this.sortHasharray(itemArray, 'name');	
},

deleteItem : function (itemObject) {
	//console.log("Projects.deleteItem    Projects.deleteItem(itemObject)");	
	//console.log("Projects.deleteItem    itemObject: " + dojo.toJson(itemObject));	

	if ( ! Agua.isProject(itemObject.name) )	return;

	// REMOVING PROJECT FROM Agua.projects
	Agua.removeProject(itemObject);

	// RELOAD RELEVANT DISPLAYS
	//console.log("Projects.deleteItem    Doing Agua.updater.update('updateProjects')");	
	Agua.updater.update("updateProjects");

}, // Projects.deleteItem

addItem : function (itemObject, formAdd) {
	//////console.log("Projects.addItem    plugins.sharing.Projects.addItem()");
	//console.log("Projects.addItem    plugins.sharing.Projects.addItem(itemObject)");
	//console.log("Projects.addItem    itemObject:");
	//console.dir(itemObject);

	if ( this.adding == true )	return;
	this.adding = true;
	
	if ( formAdd && Agua.isProject(itemObject.name) )
	{
		//console.log("Projects.addItem    project exists already. Returning");
		this.adding = false;
		return;
	}
	
	// ADD PROJECT TO Agua.projects ARRAY
	Agua.addProject(itemObject);
	
	this.adding = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateProjects");

} // Projects._addItem



}); // plugins.sharing.Projects
