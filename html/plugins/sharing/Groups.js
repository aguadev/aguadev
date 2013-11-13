dojo.provide("plugins.sharing.Groups");

// ALLOW THE USER TO ADD, REMOVE AND MODIFY GROUPS

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
dojo.require("plugins.sharing.GroupRow");

dojo.declare("plugins.sharing.Groups",
	[ dijit._Widget, dijit._Templated, plugins.core.Common, plugins.form.EditForm ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/groups.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingGroup STATE
addingGroup : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ "plugins/sharing/css/groups.css" ],

// PARENT WIDGET
parentWidget : null,

formInputs : {
// FORM INPUTS AND TYPES (word|phrase)
	groupname	:	"word",
	description	:	"phrase",
	notes		:	"phrase"
},

defaultInputs : {
// DEFAULT INPUTS
	groupname	:	"Groupname",
	description	:	"Description",
	notes		:	"Notes"
},

requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
// combo INPUTS ARE AUTOMATICALLY NOT ''
	groupname 	: 1
},

invalidInputs : {
// THESE INPUTS ARE INVALID
	groupname	:	"Groupname",
	description	:	"Description",
	notes		:	"Notes"
},

dataFields : [
	"groupname"
],

avatarItems : [
	"groupname",
	"description"
],

rowClass : "plugins.sharing.GroupRow",

/////}}}}

constructor : function(args) {
	////console.log("Groups.constructor     plugins.sharing.Groups.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.groups = args.parentWidget.groups;
-
	// LOAD CSS
	this.loadCSS();		
},

postCreate : function() {
	////console.log("Controller.postCreate    plugins.sharing.Controller.postCreate()");

	this.startup();
},


startup : function () {
	////console.log("Groups.startup    plugins.sharing.Groups.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD TO TAB CONTAINER		
	this.attachPoint.addChild(this.groupsTab);
	this.attachPoint.selectChild(this.groupsTab);

	// SET DRAG GROUP - LIST OF GROUPS
	this.setDragSource();

	// SET NEW GROUP FORM
	this.setForm();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateGroups");

	// SET TRASH
	this.setTrash(this.dataFields);	
},

updateGroups : function (args) {
// RELOAD THE COMBO AND DRAG SOURCE AFTER CHANGES
// TO DATA IN OTHER TABS
	//console.log("Groups.updateGroups(args)");
	//console.log("Groups.updateGroups    args: " );
	//console.dir(args);
	
	// SET DRAG SOURCE
	if ( args == null || args.reload != false )
	{
		//console.log("Groups.updateGroups    Calling setDragSource()");
		this.setDragSource();
	}
},

setForm : function () {
// SET 'ADD NEW GROUP' FORM
	////console.log("Groups.setForm    plugins.sharing.Groups.setForm()");

	// SET ADD GROUP ONCLICK
	dojo.connect(this.addGroupButton, "onClick", dojo.hitch(this, "saveInputs", null, null));

	// SET ONCLICK TO CANCEL INVALID TEXT
	this.setClearValues();

	// CHAIN TOGETHER INPUTS ON 'RETURN' KEYPRESS
	this.chainInputs(["groupname", "description", "notes", "addGroupButton"]);
},

getItemArray : function () {
	var itemArray = Agua.getGroups();
	//console.log("Groups.getItemArray    itemArray: " + dojo.toJson(itemArray));
	return this.sortHasharray(itemArray, 'groupname');
},

deleteItem : function (groupObject) {
	////console.log("Groups.deleteItem    plugins.sharing.Groups.deleteItem(groupname)");
	////console.log("Groups.deleteItem    groupname: " + groupname);

	// REMOVE GROUP FROM Agua.groups
	Agua.removeGroup(groupObject)

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateGroups");

}, // Groups.deleteItem


addItem : function (groupObject, formAdd) {
	//console.log("Groups.addItem    plugins.sharing.Groups.addItem(groupObject)");
	//console.log("Groups.addItem    groupObject:");
	//console.dir(groupObject);

	if ( this.savingGroup == true )	return;
	this.savingGroup = true;
	
	Agua.addGroup(groupObject);

	this.savingGroup = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateGroups");

} // Groups.addItem


}); // plugins.sharing.Groups

