dojo.provide("plugins.apps.Modules");

/* SUMMARY: DISPLAY THE REQUIRED MODULES INSTALLED TO COMPOSE THE AGUA PLATFORM
*/

// EXTERNAL MODULES
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.form.CheckBox");
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");
dojo.require("dojo.store.Memory");

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("dijit.form.ComboBox");
dojo.require("plugins.form.EditForm");

// HAS A
dojo.require("plugins.apps.PackageRow");

dojo.declare("plugins.apps.Modules",
	[ dijit._Widget, dijit._Templated, plugins.core.Common, plugins.form.EditForm ], {
		
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "apps/templates/modules.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingPackage STATE
addingPackage : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins", "apps/css/modules.css") ],

// PARENT WIDGET
parentWidget : null,

// attachNode : Dijit Tab Container
//		Add this widget as a tab to this tab container
attachNode : null,


formInputs : {
	"package"		:	"word",
	"version"		:	"word",
	"privacy"		:	"word",
	"opsdir"		:	"word",
	"installdir"	:	"word",
	"description"	:	"phrase",
	"notes"			:	"phrase",
	"url"			:	"word"
},

requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
	'package' 	:	1,
	version 	:	1, 
	opsdir		:	1,
	installdir	:	1
},

invalidInputs : {
// THESE INPUTS ARE INVALID
	'package' 	: 	"Name",
	version     : 	"Version", 
	privacy		: 	"Privacy",
	opsdir		: 	"Opsdir",
	installdir	: 	"Installdir",
	description	: 	"Description",
	notes		: 	"Notes",
	url			: 	"URL"
},

defaultInputs : {
// THESE INPUTS ARE default
	'package' 	: 	"Name",
	version 	: 	"Version", 
	privacy		: 	"Privacy",
	opsdir		: 	"Opsdir",
	installdir	: 	"Installdir",
	description	: 	"Description",
	notes		: 	"Notes",
	url			: 	"URL"
},

dataFields : ["package", "version", "privacy", "opsdir", "installdir"],

avatarItems : [ "package", "description" ],

rowClass : "plugins.apps.PackageRow",

/////}}}
constructor : function(args) {
	////////////console.log("Modules.constructor     plugins.apps.Modules.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.packages = args.parentWidget.packages;
	this.attachNode	=	args.attachNode;
},
postCreate : function() {
	////////////console.log("Controller.postCreate    plugins.apps.Controller.postCreate()");
	// LOAD CSS
	this.loadCSS();		

	this.startup();
},
startup : function () {

	console.group("App-" + this.id + "    startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD TO TAB CONTAINER		
	console.log("Modules.startup    BEFORE this.attachPane()");
	this.attachPane();
	
	// SET DRAG SOURCE
	console.log("Modules.startup    BEFORE this.setDragSource()");
	this.setDragSource();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updatePackages");

	console.groupEnd("App-" + this.id + "    startup");
},
attachPane : function () {
	this.attachNode.addChild(this.mainTab);
	this.attachNode.selectChild(this.mainTab);	
},
updatePackages : function (args) {
// RELOAD GROUP COMBO AND DRAG SOURCE AFTER CHANGES
// TO SOURCES OR GROUPS DATA IN OTHER TABS
	console.log("Modules.updatePackages    Packages.updatePackages(args)");
	console.log("Modules.updatePackages    args:");
	console.dir(args);

	// CHECK ARGS
	if ( args != null && args.reload == false )	return;
	if ( args.originator && args.originator == this )	return;
	
	// SET DRAG SOURCE
	console.log("Modules.updatePackages    Calling setDragSource()");
	
	this.setDragSource();
},
getItemArray : function () {
	//console.log("Modules.getItemArray     plugins.apps.Modules.getItemArray()");
	var itemArray = Agua.getPackages();
	console.log("Modules.getItemArray    itemArray.length: " + itemArray.length);
    console.log("Modules.getItemArray    itemArray:");
    console.dir({itemArray:itemArray});

	// FILTER OUT NON-AGUA USER PACKAGES
	itemArray = this.filterByKeyValues(itemArray, ["owner"], ["agua"]);
	
	itemArray = itemArray.sort();
	return itemArray;
},
changeDragSource : function () {
	//console.log("Modules.changeDragSource     plugins.apps.Modules.changeDragSource()");
	//console.log("Modules.changeDragSource     this.dragSourceOnchange: " + this.dragSourceOnchange);
	
	//if ( this.dragSourceOnchange == false )
	//{
	//	//console.log("Modules.changeDragSource     this.dragSourceOnchange is false. Returning");
	//	this.dragSourceOnchange = true;
	//	return;
	//}
	
	//console.log("Modules.changeDragSource     Doing this.setDragSource");
	this.setDragSource();
}, // Packages.deleteItem
saveInputs : function (inputs, updateArgs) {
	console.log("Modules.saveInputs    DO NOTHING. Returning");
	return;

//	SAVE AN APPLICATION TO Agua.packages AND TO REMOTE DATABASE
	console.log("Modules.saveInputs    caller: " + this.saveInputs.caller.nom);
	console.log("Modules.saveInputs    inputs: ");
	console.dir({inputs:inputs});

	console.log("Modules.savethis.rowWidget    this.rowWidget: ");
	console.dir({this_rowWidget:this.rowWidget});
	var className = this.getClassName(this.rowWidget);
	console.log("Modules.saveInputs    className: " + className);
	
	if ( this.savingPackage == true )	return;
	this.savingPackage = true;

	if ( inputs == null )
	{
		inputs = this.getFormInputs(this);

		// RETURN IF INPUTS ARE NULL
		if ( inputs == null )
		{
			this.savingPackage = false;
			return;
		}
	}
	console.log("Modules.saveInputs    FINAL inputs: ");
	console.dir({inputs:inputs});

	// RETURN IF PACKAGE ALREADY EXISTS
	var isPackage = Agua.isPackage(inputs["package"]);
	console.log("Modules.saveInputs    isPackage: " + isPackage)
	if ( isPackage && className != "plugins.apps.PackageRow" ) {
		console.log("Modules.saveInputs    package exists already. Returning");
		this.setInvalid(this["package"]);
		Agua.toastMessage({
			message: "Package exists already: " + inputs["package"],
			type: "error"
		});
		this.savingPackage = false;
		return;
	}	

	inputs.owner = Agua.cookie('username');
	inputs.username = Agua.cookie('username');

	// REMOVE ORIGINAL APPLICATION OBJECT FROM Agua.packages 
	// THEN ADD NEW APPLICATION OBJECT TO Agua.packages
	Agua.removePackage({ thisPackage: inputs["package"] });
	Agua.addPackage(inputs);

	// CREATE JSON QUERY
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.mode 			= 	"addPackage";
	query.module = "Agua::Admin";
	query.data 			= 	inputs;
	var url = Agua.cgiUrl + "agua.cgi?";
	////////////console.log("Modules.saveInputs    query: " + dojo.toJson(query));
	
	// SEND TO SERVER
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			//timeout: 15000,
			handle: function(response, ioArgs) {
				////////////console.log("Modules.saveInputs    JSON Post worked.");
				return response;
			},
			error: function(response, ioArgs) {
				////////////console.log("Modules.saveInputs    Error with JSON Post, response: " + response + ", ioArgs: " + ioArgs);
				return response;
			}
		}
	);

	this.savingPackage = false;

	// TRIGGER UPDATES
	// NB: updateArgs.reload = true
	Agua.updater.update("updatePackages", updateArgs);

}, // Packages.saveInputs
toggle : function () {
// TOGGLE HIDDEN DETAILS	
	////console.log("Modules.toggle    plugins.workflow.Packages.toggle()");
	//////console.log("Modules.toggle    this.description: " + this.description);
	var array = [ "descriptionTitle", "description", "notesTitle", "notes", "urlTitle" , "url" ];
	
	for ( var i in array )
	{
		//console.log("PackageRow.toggle    this[" + array[i] + "] :" + this[array[i]]);
		if ( this[array[i]].style.display == 'inline' )	
			this[array[i]].style.display='none';
		else
			this[array[i]].style.display = 'inline';
	}
},
getFormInputs : function (widget) {
// GET INPUTS FROM THE EDITED ITEM
	////console.log("Modules.getFormInputs    plugins.apps.Modules.getFormInputs(textarea)");
	//////console.log("Modules.getFormInputs    widget: " + widget);
	var inputs = new Object;
	for ( var name in this.formInputs )
	{
		inputs[name]  = this.processWidgetValue(widget, name);
		////console.log("Modules.getFormInputs    inputs[name]: " + inputs[name]);
	}

	inputs = this.checkInputs(widget, inputs);
	////console.log("Modules.getFormInputs    FINAL inputs: " + dojo.toJson(inputs));

	return inputs;
}


}); // plugins.apps.Modules
