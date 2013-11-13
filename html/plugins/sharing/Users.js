dojo.provide("plugins.sharing.Users");

// ALLOW THE ADMIN USER TO ADD, REMOVE AND MODIFY USERS
// NEW USERS MUST HAVE username AND email

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
dojo.require("plugins.sharing.UserRow");

dojo.declare("plugins.sharing.Users",
	[ dijit._Widget, dijit._Templated, plugins.core.Common, plugins.form.EditForm ],
{

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/users.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ "plugins/sharing/css/users.css" ],

// PARENT WIDGET
parentWidget : null,

formInputs : {
// FORM INPUTS AND TYPES (word|phrase)
	username	:	"word",
	firstname	:	"phrase",
	lastname	:	"phrase",
	email		:	"phrase",
	password	:	"phrase"
},

defaultInputs : {
// DEFAULT INPUTS
	username	:	"Username",
	firstname	:	"Firstname",
	lastname	:	"Lastname",
	email		:	"Email"
},

requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
// combo INPUTS ARE AUTOMATICALLY NOT ''
	username 	: 1,
	firstname	: 1,
	lastname	: 1,
	email		: 1
},

invalidInputs : {
// THESE INPUTS ARE INVALID
	username	:	"Username",
	firstname	:	"Firstname",
	lastname	:	"Lastname",
	email		:	"Email"
},

dataFields : [
	"username"
],

avatarItems : [
	"username",
	"email"
],

// MOTHBALLED WITH TWO-D ARRAYS
//fieldIndexes : [
//	"username",
//	"firstname",
//	"lastname",
//	"email"
//],

rowClass : "plugins.sharing.UserRow",

/////}}}

constructor : function(args) {
	//////console.log("Users.constructor     plugins.sharing.Users.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.users = args.parentWidget.users;

	// LOAD CSS
	this.loadCSS();		
},

postCreate : function() {
	//////console.log("Controller.postCreate    plugins.sharing.Controller.postCreate()");

	this.startup();
},

startup : function() {
	console.log("Users.startup    plugins.sharing.Users.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD ADMIN TAB TO TAB CONTAINER		
	this.attachPoint.addChild(this.mainTab);
	this.attachPoint.selectChild(this.mainTab);

	// SET DRAG SOURCE - LIST OF USERS
	this.setDragSource();

	// SET NEW SOURCE FORM
	this.setForm();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateUsers");

	// SET TRASH
	this.setTrash(this.dataFields);	
},

updateUsers : function (args) {
	//console.log("Users.updateUsers    sharing.Users.updateUsers(args)");
	//console.log("Users.updateUsers    args:");
	//console.dir(args);

	// SET DRAG SOURCE
	if ( args == null || args.reload != false )
	{
		console.log("Users.updateUsers    Doing this.setDragSource()");
		this.setDragSource();
	}
},

setForm : function () {
	//////console.log("Users.setForm    plugins.sharing.Users.setForm()");

	// SET ADD SOURCE ONCLICK
	dojo.connect(this.addUserButton, "onClick", dojo.hitch(this, "saveInputs", null, null));

	// SET ONCLICK TO CANCEL INVALID TEXT
	this.setClearValues();

	// CHAIN TOGETHER INPUTS ON 'RETURN' KEYPRESS
	this.chainInputs(["username", "firstname", "lastname", "email", "password", "addUserButton"]);
},

getItemArray : function () {
	var dataArray = new Array;
	var itemArray = Agua.getUsers();

	//var userArray = Agua.getUsers();
	// MOTHBALLED WITH TWO-ARRAYS
	//var itemArray = new Array;
	////for( var i = 0; i < userArray.length; i++ )
	//for( var i = 0; i < 10; i++ )
	//{
	//	var itemObject = new Object;
	//	for( var j = 0; j < this.fieldIndexes.length; j++ )
	//	{
	//		itemObject[this.fieldIndexes[j]] = userArray[i][j];
	//	}
	//	itemArray.push(itemObject);
	//}
	////console.log("Users.getItemArray    itemArray[0]: " + dojo.toJson(itemArray[0]));

	return this.sortHasharray(itemArray, 'username');
},

deleteItem : function (itemObject) {
	//console.log("Users.deleteItem    plugins.sharing.Users.deleteItem(itemObject)");
	//console.log("Users.deleteItem    itemObject: " + dojo.toJson(itemObject));

	Agua.removeUser(itemObject);
	
	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateUsers");

}, // Users.deleteItem

addItem : function (itemObject, formAdd) {
	console.log("Users.addItem    itemObject: ");
	console.dir({itemObject:itemObject});
	
	// CLEAN UP WHITESPACE AND SUBSTITUTE NON-JSON SAFE CHARACTERS
	itemObject.originalName = this.jsonSafe(itemObject.originalName, 'toJson');
	itemObject.username = this.jsonSafe(itemObject.username, 'toJson');
	itemObject.firstname = this.jsonSafe(itemObject.firstname, 'toJson');
	itemObject.email = this.jsonSafe(itemObject.email, 'toJson');
	itemObject.password = this.jsonSafe(itemObject.password, 'toJson');

	if ( this.saving == true )	return;
	this.saving = true;

	if ( formAdd == true && Agua.isUser(itemObject) )	return;

	Agua.addUser(itemObject);

	this.saving = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateUsers");

}	// Users.addItem


}); // plugins.sharing.Users

