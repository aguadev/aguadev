define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/apps/AppRow",
	"plugins/dijit/SyncDialog",
	"plugins/form/DndSource",
	"plugins/form/Inputs",
	"plugins/form/EditRow",
	"plugins/form/DndTrash",
	"plugins/core/Common",
	"dojo/store/Memory",
	"dojo/domReady!",

	"dijit/form/Button",
	"dijit/form/TextBox",
	"dijit/form/Textarea",
	"dijit/layout/ContentPane",
	"dijit/form/ComboBox",
	"dijit/form/Select",
	"dijit/form/CheckBox"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, _Widget, _TemplatedMixin, _WidgetsInTemplateMixin, AppRow, SyncDialog, DndSource, Inputs, EditRow, DndTrash, Common, Memory) {

/////}}}}}

return declare("plugins.apps.App",
	[ _Widget, _TemplatedMixin, _WidgetsInTemplateMixin, DndSource, Inputs, EditRow, DndTrash, Common ], {

// templateString : String	
//		Path to the template of this widget. 
templateString: dojo.cache("plugins", "apps/templates/app.html"),

//addingApp STATE
addingApp : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/apps/css/app.css")
],

formInputs : {
	"name"		: "word",
	"version"	: "word",
	"type"		: "word",
	"executor"	: "word",
	"package"	: "word",
	"location"	: "word",
	"localonly"	: "word",
	"description": "phrase",
	"notes": "phrase",
	"url": "word"
},

requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
	name 	: 1,
	version : 1, 
	type 	: 1, 
	location: 1
},

invalidInputs : {
// THESE INPUTS ARE INVALID
	name 		: 	"Name",
	version		: 	"Version", 
	type 		: 	"Type", 
	executor	: 	"Executor", 
	packageCombo: 	"Package",
	location	: 	"Location",
	description	: 	"Description",
	notes		: 	"Notes",
	url			: 	"URL"
},

defaultInputs : {
// THESE INPUTS ARE default
	name 		: 	"Name",
	type 		: 	"Type", 
	executor	: 	"Executor", 
	packageCombo: 	"Package",
	location	: 	"Location",
	description	: 	"Description",
	notes		: 	"Notes",
	url			: 	"URL"
},

dataFields : ["name", "version", "type", "location"],

avatarItems : [ "name", "description" ],

rowClass : "plugins.apps.AppRow",

// dragType: array
// 		List of permitted dragged items allowed to be dropped
dragTypes : ["app"],

// parentWidget : Widget
//		Widget that created this widget
parentWidget : null,

// attachNode : DOM node
//		Node to attach widget's mainTab
attachNode : null,

/////}}}
constructor : function(args) {
	//console.log("App.constructor     plugins.apps.App.constructor");			

	lang.mixin(this, args);
	//console.log("App.constructor     this.attachNode: " + this.attachNode);			

	// SET this.apps
	if ( this.parentWidget ) {
		this.apps = this.parentWidget.apps;
	}

},
postCreate : function() {
	// LOAD CSS
	//console.log("Controller.postCreate    DOING this.loadCSS()");
	this.loadCSS();		

	//console.log("Controller.postCreate    DOING this.startup()");
	this.startup();
},
startup : function () {

	//console.group("App-" + this.id + "    startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD TO TAB CONTAINER		
	this.attachPane();

	// SET APPS COMBO - WILL CASCADE TO setDragSource
	this.setPackageCombo();

	// SET NEW APP FORM
	this.setForm();

	// SET TRASH
	this.setTrash(this.dataFields);	

	// SET SYNC APPS BUTTON
	this.setSyncApps();
	
	// SET SYNC DIALOG
	this.setSyncDialog();

	// SET SUBSCRIPTIONS
	this.setSubscriptions();

	// SET LISTENERS
	this.setListeners();

	//console.groupEnd("App-" + this.id + "    startup");
},
attachPane : function () {
	//console.log("Controller.attachPane    this.attachNode: " + this.attachNode);
	
	this.attachNode.addChild(this.mainTab);
	this.attachNode.selectChild(this.mainTab);	
},
setSubscriptions : function () {
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateApps");
	
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateSyncApps");
	
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updatePackages");
},
updateApps : function (args) {
// RELOAD PANE AFTER DATA CHANGES IN OTHER PANES
	console.group("apps.App    " + this.id + "    updateApps");
	console.log("App.updateApps    args:");
	console.dir(args);

	// SET DRAG SOURCE
	if ( args != null && args.reload == false )	return;

	console.log("App.updatePackages    DOING this.setAppTypesCombo()");
	this.setAppTypesCombo();

	console.groupEnd("apps.App    " + this.id + "    updateApps");
},
updateParameters : function (args) {
// RELOAD AFTER DATA CHANGES IN OTHER TABS
	console.group("apps.App    " + this.id + "    updateParameters");

	console.log("Apps.updateParameters    args: ");
	console.dir(args);
	
	// REDO PARAMETER TABLE
	if ( args.originator == this ) {
		if ( args.reload == false )	return;
	}

	console.log("App.updatePackages    DOING this.setAppTypesCombo()");
	this.AppTypesCombo();

	console.groupEnd("apps.App    " + this.id + "    updateParameters");
},
updateSyncApps : function (args) {
	//console.warn("App.updateSyncApps    args:");
	//console.dir({args:args});

	this.setSyncApps();
},
updatePackages : function (args) {
// RELOAD PACKAGE COMBO
	console.group("apps.App    " + this.id + "    updatePackages");

	console.log("App.updatePackages    args:");
	console.dir(args);

	// CHECK ARGS
	if ( args != null && args.reload == false )	return;
	if ( args.originator && args.originator == this )	return;
	
	// SET DRAG SOURCE
	console.log("App.updatePackages    DOING this.setPackageCombo()");
	this.setPackageCombo();

	console.groupEnd("apps.App    " + this.id + "    updatePackages");
},
setListeners : function () {
	// PACKAGE COMBO
	var thisObject = this;
	dojo.connect(this.packageCombo, "onChange", dojo.hitch(function(event) {
		//console.log("App.setListeners    this.packageCombo FIRED   event: " + event);
		thisObject.setAppTypesCombo(event);
	}));
},
// COMBOS
setPackageCombo : function (type) {
// SET PARAMETERS COMBO BOX
	//console.log("App.setPackageCombo     type: " + type);

	var itemArray = this.getPackageNames();
	//console.log("App.setPackageCombo     itemArray: " + dojo.toJson(itemArray));
	
	// CREATE STORE
	var store 	=	this.createStore(itemArray);

	// SET COMBO
	this.packageCombo.store = store;
	this.packageCombo.startup();
	//console.log("App.setPackageCombo::setCombo     AFTER this.packageCombo.startup()");

	// SET COMBO VALUE
	var firstValue = itemArray[0];
	this.packageCombo.set('value', firstValue);
	////console.log("App.setPackageCombo::setCombo     AFTER this.packageCombo.setValue(firstValue)");

	// SET PARAMETER NAMES COMBO
	this.setAppTypesCombo();
},
getPackageNames : function () {
	// GET PACKAGES
	var packages = Agua.getPackages();
	//console.log("App.getPackageNames     BEFORE packages.length: " + packages.length);
	//console.dir({packages:packages});
	
	// GET ALL PACKAGES OWNED BY USER (NB agua PACKAGES ARE OWNED BY admin USER)
	var username = Agua.cookie('username');
	//console.log("App.getPackageNames     username: " + username);
	packages = this.filterByKeyValues(packages, ["username"], [username]);
	//console.log("App.getPackageNames     AFTER packages.length: " + packages.length);
	//console.log("App.getPackageNames     packages:");
	//console.dir({packages:packages});
	var packageNames = this.hashArrayKeyToArray(packages, "package");
	//console.log("App.getPackageNames     packageNames:");
	//console.dir({packageNames:packageNames});

	return packageNames;	
},
setAppTypesCombo : function (packageName) {
	// SET APPS COMBO BOX WITH APPLICATION NAME VALUES
	//console.log("App.setAppTypesCombo     plugins.apps.App.setAppTypesCombo()");

	if ( ! packageName )
		packageName = this.packageCombo.get('value');
	//console.log("App.setAppTypesCombo     packageName: " + packageName);

	// GET APPS NAMES
	var apps = Agua.getApps();
	//console.log("App.setAppTypesCombo     INITIAL apps: ");
	//console.dir({apps:apps});
    //console.log("App.setAppTypesCombo    INITIAL apps.length: " + apps.length);
    	
	var username = Agua.cookie("username");
	var keys = ['username', 'package'];
	var values = [ username, packageName ];
	apps = this.filterByKeyValues(apps, keys, values);

	var typesArray = this.hashArrayKeyToArray(apps, "type");
	typesArray = this.uniqueValues(typesArray);
	//console.log("App.setAppTypesCombo     typesArray: ");
	//console.dir({typesArray:typesArray});

	typesArray = this.sortNoCase(typesArray);
	//console.log("App.setAppTypesCombo     AFTER SORT typesArray: ");
	//console.dir({typesArray:typesArray});
	typesArray.splice(0,0, 'Order by Type (A-Z)');
	typesArray.splice(0,0, 'Order by Name (A-Z)');
	
	// SET STORE
	var data = [];
	//console.log("App.setAppTypesCombo data:");
	//console.dir({data:data});
	
	for ( var i = 0; i < typesArray.length; i++ ) {
		data.push({ name: typesArray[i]	});
	}
	var store = new Memory({	idProperty: "name", data: data	});
	
	// SET COMBO
	this.appsCombo.store = store;
	this.appsCombo.startup();

	// SET COMBO VALUE
	var firstValue = typesArray[0];
	this.appsCombo.set('value', firstValue);
	console.log("App.setAppTypesCombo::setCombo     AFTER this.appsCombo.set('value',firstValue)");

	this.setDragSource();
},
setForm : function () {
	// SET ADD ONCLICK
	dojo.connect(this.addAppButton, "onclick", dojo.hitch(this, "saveInputs", null, { reload: true }));

	// SET ONCLICK TO CANCEL INVALID TEXT
	this.setClearValues();

	// CHAIN TOGETHER INPUTS ON 'RETURN' KEYPRESS
	this.chainInputs(["name", "type", "executor", "package", "location", "description", "notes", "url", "addAppButton"]);	
},
getItemArray : function () {
	//console.log("App.getItemArray     plugins.apps.App.getItemArray()");

	var itemArray = Agua.getApps();
	//console.log("App.getItemArray     itemArray[0]: " + dojo.toJson(itemArray[0]));
	//console.log("App.getItemArray    itemArray.length: " + itemArray.length);
	
	var packageName = this.packageCombo.get('value');
	if ( ! packageName ) {
		packageName = itemArray[0].package;
	}
	var username = Agua.cookie("username");
	//console.log("App.getItemArray     packageName: " + packageName);	
	//console.log("App.getItemArray     username: " + username);
	
	itemArray = this.filterByKeyValues(itemArray, ["package", "username"], [packageName, username]);
	//console.log("App.getItemArray    AFTER FILTER itemArray.length: " + itemArray.length);
		
	var type = this.appsCombo.get('value');
	//console.log("App.getItemArray     type: " + type);
	if ( type == "Order by Name (A-Z)" ) {
		itemArray = this.sortHasharray(itemArray, 'name');
		//console.log("App.getItemArray     Name A-Z itemArray: " + dojo.toJson(itemArray));
	}
	else if ( type == "Order by Type (A-Z)" ) {
		itemArray = this.sortHasharray(itemArray, 'type');
		//console.log("App.getItemArray     Type A-Z itemArray: " + dojo.toJson(itemArray));
	}
	else {
		for ( var i = 0; i < itemArray.length; i++ ) {
			if ( itemArray[i].type != type ) {
				itemArray.splice(i, 1);
				i--;
			}
		}
	}	
	//console.log("App.getItemArray    Type " + type + " itemArray.length: " + itemArray.length);
	//console.log("App.getItemArray    RETURNING itemArray: ");
    //console.dir({itemArray:itemArray});
	
	return itemArray;
},
changeDragSource : function () {
	//console.log("App.changeDragSource     plugins.apps.App.changeDragSource()");
	//console.log("App.changeDragSource     this.dragSourceOnchange: " + this.dragSourceOnchange);
	
	//if ( this.dragSourceOnchange == false )
	//{
	//	//console.log("App.changeDragSource     this.dragSourceOnchange is false. Returning");
	//	this.dragSourceOnchange = true;
	//	return;
	//}
	
	//console.log("App.changeDragSource     Doing this.setDragSource");
	this.setDragSource();
},
deleteItem : function (appObject) {
// DELETE APPLICATION FROM Agua.apps OBJECT AND IN REMOTE DATABASE
	//console.log("App.deleteItem    plugins.apps.App.deleteItem(name)");
	//console.log("App.deleteItem    name: " + name);

	// CLEAN UP WHITESPACE
	appObject.name = appObject.name.replace(/\s+$/,'');
	appObject.name = appObject.name.replace(/^\s+/,'');

	// REMOVING APP FROM Agua.apps
	Agua.removeApp(appObject, "custom");
	
	var url = Agua.cgiUrl + "agua.cgi?";
	//console.log("App.deleteStore     url: " + url);		

	// CREATE JSON QUERY
	var query = new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.mode 			= 	"deleteApp";
	query.module = "Agua::Admin";
	query.data 			= 	appObject;
	//console.log("App.deleteItem    query: " + dojo.toJson(query));
	
	// SEND TO SERVER
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			load: function(response, ioArgs) {
				//console.log("App.deleteItem    JSON Post worked.");
				return response;
			},
			error: function(response, ioArgs) {
				//console.log("App.deleteItem    Error with JSON Post, response: " + response + ", ioArgs: " + ioArgs);
				return response;
			}
		}
	);

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateApps");

}, // Apps.deleteItem
saveInputs : function (inputs, updateArgs) {
//	SAVE AN APPLICATION TO Agua.apps AND TO REMOTE DATABASE
	//console.log("App.saveInputs    plugins.apps.App.saveInputs(inputs)");
	//console.log("App.saveInputs    BEFORE inputs: ");
	//console.dir({inputs:inputs});

	if ( this.savingApp == true )	return;
	this.savingApp = true;

	if ( inputs == null )
	{
		inputs = this.getFormInputs(this);

		// RETURN IF INPUTS ARE NULL
		if ( inputs == null )
		{
			this.savingApp = false;
			return;
		}
	}
	
	var username = Agua.cookie("username");
	inputs.username    =    username;
	inputs.owner        =    username;
	
	//console.log("App.saveInputs    AFTER inputs: ");
	//console.dir({inputs:inputs});

	// REMOVE ORIGINAL APPLICATION OBJECT FROM Agua.apps 
	// THEN ADD NEW APPLICATION OBJECT TO Agua.apps
	Agua.removeApp({ name: inputs.name });
	Agua.addApp(inputs);

	// CREATE JSON QUERY
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.mode 			= 	"saveApp";
	query.module = "Agua::Admin";
	query.data 			= 	inputs;
	var url = Agua.cgiUrl + "agua.cgi?";
	//////////console.log("App.saveInputs    query: " + dojo.toJson(query));
	
	// SEND TO SERVER
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			timeout: 15000,
			load: function(response, ioArgs) {
				//////////console.log("App.saveInputs    JSON Post worked.");
				return response;
			},
			error: function(response, ioArgs) {
				//////////console.log("App.saveInputs    Error with JSON Post, response: " + response + ", ioArgs: " + ioArgs);
				return response;
			}
		}
	);

	this.savingApp = false;

	// SUBSCRIBE TO UPDATES
	// NB: updateArgs.reload = true
	Agua.updater.update("updateApps", updateArgs);

}, // Apps.saveInputs
getFormInputs : function (widget) {
// GET INPUTS FROM THE EDITED ITEM
	//console.log("App.getFormInputs    plugins.apps.App.getFormInputs(textarea)");
	//console.log("App.getFormInputs    widget: " + widget);
	//console.dir({widget:widget});

	var inputs = new Object;
	//console.log("App.getFormInputs    inputs: " + inputs);
	//console.dir({inputs:inputs});

	for ( var name in this.formInputs )
	{
		//console.log("App.getFormInputs    DOING inputs[" + name + "]");
		var value;
		if ( name == "localonly" )
		{
			value = 0;
			if ( widget[name].getValue() == "on" )
			{
				value = 1;
			}
		}
		else if ( name == "package" ) {
			value = this.processWidgetValue(widget, "packageCombo");
		}
		else
		{
			//console.log("App.getFormInputs    DOING processWidgetValue. widget: ");
			//console.dir({widget:widget});
			
			value = this.processWidgetValue(widget, name);
		}
		inputs[name] = value;
		//console.log("App.getFormInputs    inputs[" + name + "]: " + inputs[name]);
	}

	inputs = this.checkInputs(widget, inputs);
	//console.log("App.getFormInputs    FINAL inputs: ");
	//console.dir({inputs:inputs});

	return inputs;
},
checkInputs : function (widget, inputs) {
// CHECK INPUTS ARE VALID, IF NOT RETURN NULL
	//console.log("App.checkInputs    inputs: ");
	//console.dir({inputs:inputs});
	
	this.allValid = true;	
	for ( var key in this.formInputs ) {
		var value = inputs[key];
		//console.log("App.checkInputs    Checking " + key + ": " + value);
		
		if ( key == "package" ) {
			if ( this.isValidInput("packageCombo", value) ) {
				this.setValid(widget["packageCombo"]);
			}
			else {
				this.setInvalid(widget["packageCombo"]);
				this.allValid = false;
				continuev;
			}
		}
		else if ( this.isValidInput(key, value) ) {
			//console.log("App.checkInputs    removing 'invalid' class for " + key + ": " + value);
			this.setValid(widget[key]);
		}
		else {
			//console.log("App.checkInputs    adding 'invalid' class for name " + key + ", value " + value);
			
			this.setInvalid(widget[key]);
			this.allValid = false;
		}
	}
	//console.log("App.checkInputs    this.allValid: " + this.allValid);
	if ( this.allValid == false )	return null;

	for ( var key in this.formInputs )
	{
		//console.log("App.checkInputs    BEFORE convert, inputs[key]: " + dojo.toJson(inputs[key]));
		inputs[key] = this.convertAngleBrackets(inputs[key], "htmlToText");
		//inputs[key] = this.convertBackslash(inputs[key], "textToHtml");
		//console.log("App.checkInputs    AFTER convert, inputs[key]: " + dojo.toJson(inputs[key]));
	}

	return inputs;
},
// SYNC
setSyncApps : function () {
// DISABLE SYNC APPS BUTTON IF NO HUB LOGIN

	var hub = Agua.getHub();
	//console.log("App.setSyncApps    hub:")
	//console.dir({hub:hub});

	if ( ! hub.login || ! hub.token ) {
		this.disableSyncApps();
	}
	else {
		this.enableSyncApps();
	}
},
setSyncDialog : function () {
	//console.log("App.loadSyncDialog    plugins.apps.App.setSyncDialog()");
	
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "Sync";
	var header = "Sync Apps";
	
	this.syncDialog = new SyncDialog(
		{
			title 				:	title,
			header 				:	header,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback
		}			
	);

	//console.log("App.loadSyncDialog    this.syncDialog:");
	//console.dir({this_syncDialog:this.syncDialog});

},
showSyncDialog : function () {
	var disabled = dojo.hasClass(this.syncAppsButton, "disabled");
	//console.log("App.loadSyncDialog    disabled: " + disabled);
	
	if ( disabled ) {
		//console.log("App.loadSyncDialog    SyncApps is disabled. Returning");
		return;
	}
	
	var title = "Sync Apps";
	var header = "";
	var message = "";
	var details = "";
	var enterCallback = dojo.hitch(this, "syncApps");
	this.loadSyncDialog(title, header, message, details, enterCallback)
},
loadSyncDialog : function (title, header, message, details, enterCallback) {
	//console.log("App.loadSyncDialog    title: " + title);
	//console.log("App.loadSyncDialog    header: " + header);
	//console.log("App.loadSyncDialog    message: " + message);
	//console.log("App.loadSyncDialog    details: " + details);
	//console.log("App.loadSyncDialog    enterCallback: " + enterCallback);

	this.syncDialog.load(
		{
			title 			:	title,
			header 			:	header,
			message 		:	message,
			details 		:	details,
			enterCallback 	:	enterCallback
		}			
	);
},
disableSyncApps : function () {
	dojo.addClass(this.syncAppsButton, "disabled");
	dojo.attr(this.syncAppsButton, "title", "Input AWS private key and public certificate to enable Sync");
},
enableSyncApps : function () {
	dojo.removeClass(this.syncAppsButton, "disabled");
	dojo.attr(this.syncAppsButton, "title", "Click to sync apps to biorepository");
},
syncApps : function (inputs) {
	//console.log("Hub.syncApps    inputs: ");
	//console.dir({inputs:inputs});
	
	if ( this.syncingApps == true ) {
		//console.log("Hub.syncApps    this.syncingApps: " + this.syncingApps + ". Returning.");
		return;
	}
	this.syncingApps = true;
	
	var query = new Object;
	query.username 			= 	Agua.cookie('username');
	query.sessionid 		= 	Agua.cookie('sessionid');
	query.message			= 	inputs.message;
	query.details			= 	inputs.details;
	query.hubtype			= 	"github";
	query.mode 				= 	"syncApps";
	query.module 		= 	"Agua::Workflow";
	//console.log("Hub.syncApps    query: ");
	//console.dir({query:query});
	
	// SEND TO SERVER
	var url = Agua.cgiUrl + "agua.cgi?";
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "json",
			putData: dojo.toJson(query),
			load: function(response, ioArgs) {
				thisObj.syncingApps = false;

				//console.log("App.syncApps    OK. response:")
				//console.dir({response:response});

				Agua.toast(response);
			},
			error: function(response, ioArgs) {
				thisObj.syncingApps = false;

				//console.log("App.syncApps    ERROR. response:")
				//console.dir({response:response});
				Agua.toast(response);
			}
		}
	);
},
// UTILS
toggle : function () {
// TOGGLE HIDDEN DETAILS
	//console.log("Packages.toggle    this.togglePoint.style.display: " + this.togglePoint.style.display);

	if ( this.togglePoint.style.display == 'inline-block' )	{
		this.togglePoint.style.display='none';
		dojo.removeClass(this.toggler, "open");
		dojo.addClass(this.toggler, "closed");
	}
	else {
		this.togglePoint.style.display = 'inline-block';
		dojo.removeClass(this.toggler, "closed");
		dojo.addClass(this.toggler, "open");
	}

}


}); //	end declare

});	//	end define

