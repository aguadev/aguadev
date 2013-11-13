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
	"plugins/apps/ParameterRow",
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
	"dijit/form/Select"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, _Widget, _TemplatedMixin, _WidgetsInTemplate, ParameterRow, DndSource, Inputs, EditRow, DndTrash, Common, Memory) {

/////}}}}}

return declare("plugins.apps.Parameters",
	[ _Widget, _TemplatedMixin, _WidgetsInTemplate, DndSource, Inputs, EditRow, DndTrash, Common ], {

// templateString : String
//		The template of this widget. 
templateString: dojo.cache("plugins", "apps/templates/parameters.html"),

// addingParameter : Boolean
//		addingParameter STATE
addingParameter : false,

// cssFiles : ArrayRef
//		Array of CSS files to be loaded for all widgets in template
// 		OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/apps/css/parameters.css"),
	require.toUrl("dojo/tests/dnd/dndDefault.css")
],

// parentWidget : Widget
//			Parent of this widget
parentWidget : null,

// formInputs : Hash\
//		Hash of form inputs against input types (word|phrase)
formInputs : {
	locked: "",
	name: "word",
	argument: "word",
	valuetype: "word",
	category: "word",
	value: "word",
	ordinal: "word",
	discretion: "word",
	description: "phrase",
	paramtype: "paramtype",
	format: "word",
	args: "word",
	inputParams: "phrase",
	paramFunction: "phrase"
},

defaultInputs : {
	name : "Name",
	argument : "Argument", 
	//type : "ValueType", 
	category: "Category",
	value: "Value",
	//discretion: "Discretion",
	description: "Description",
	format: "Format",
	//paramtype: "Paramtype",
	args: "Args",
	inputParams: "Params",
	paramFunction: "ParamFunction"
},

requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
	name : 1,
	paramtype : 1, 
	valuetype: 1,
	category: 1,
	discretion: 1
},

invalidInputs : {
// INVALID INPUTS (e.g., DEFAULT INPUTS)
	name : "Name",
	argument : "Argument", 
	valuetype : "ValueType", 
	category: "Category",
	value: "Value",
	discretion: "Discretion",
	description: "Description",
	paramtype: "Paramtype",
	format: "Format",
	args: "Args",
	inputParams: "Params",
	paramFunction: "ParamFunction"
},

// DATA FIELDS TO BE RETRIEVED FROM DELETED ITEM
dataFields : [ "name", "appname", "paramtype" ],

rowClass : "plugins.apps.ParameterRow",

avatarItems: [ "name", "description"],

avatarType : "parameters",

// LOADED DND WIDGETS
childWidgets : [],

// attachNode : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachNode : null,

/////}}}}}

constructor : function(args) {
	console.log("Parameters.constructor    args: ");
	console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);
},
postCreate : function() {
////console.log("Controller.postCreate    plugins.apps.Controller.postCreate()");

	// LOAD CSS
	this.loadCSS();		

	// COMPLETE CONSTRUCTION OF OBJECT
	////console.log("Parameters.postCreate    DOING this.inherited(arguments)");
	this.inherited(arguments);	 
	////console.log("Parameters.postCreate    AFTER this.inherited(arguments)");

	//this.startup();
},
startup : function () {
	console.group("App-" + this.id + "    startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	////console.log("Parameters.startup    DOING this.inherited(arguments)");
	this.inherited(arguments);	 
	////console.log("Parameters.startup    AFTER this.inherited(arguments)");

	// ATTACH PANEprint Dumper ;
	this.attachPane();

	// SET PARAMETERS COMBO
	console.log("Parameters.startup    DOING this.setAppTypesCombo()");
	this.setAppTypesCombo();

	// SET NEW PARAMETER FORM
	console.log("Parameters.startup    DOING this.setForm()");
	this.setForm();

	// SET TRASH
	console.log("Parameters.startup    DOING this.setTrash()");
	this.setTrash(this.dataFields);	

	// SET COMBOBOX onChange LISTENERS
	setTimeout( function(thisObj){ thisObj.setComboListeners(); }, 1000, this);

	// SUBSCRIBE TO UPDATES
	if ( Agua.updater ) {
		Agua.updater.subscribe(this, "updateApps");
		Agua.updater.subscribe(this, "updateParameters");
	}

	console.groupEnd("App-" + this.id + "    startup");
},
attachPane : function () {
	console.log("Parameters.attachPane    this.attachNode: " + this.attachNode);
	if ( this.attachPoint.addChild ) {
		this.attachPoint.addChild(this.mainTab);
		this.attachPoint.selectChild(this.mainTab);
	}
	if ( this.attachPoint.appendChild ) {
		this.attachPoint.appendChild(this.mainTab.domNode);
	}	
},
updateApps : function (args) {
// RELOAD AFTER DATA CHANGES IN OTHER TABS
	console.group("apps.Parameters    " + this.id + "    updateApps");
	console.log("apps.Parameters.updateApps    args:");
	console.dir(args);
	////console.log("Parameters.updateApps    admin.Parameter.updateApps(args)");
	////console.log("Parameters.updateApps    args: ");
	////console.dir(args);

	// SET PARAMTYPES COMBO
	////console.log("Parameters.updateApps    Calling setAppNamesCombo()");
	this.setAppNamesCombo();
	
	// SET APPS COMBO
	////console.log("Parameters.updateApps    Calling setAppTypesCombo()");
	this.setAppTypesCombo();
	
	// SET DRAG SOURCE
	////console.log("Parameters.updateApps    Calling setDragSource()");
	this.setDragSource();

	console.groupEnd("apps.Parameters    " + this.id + "    updateApps");
},
updateParameters : function (args) {
// RELOAD AFTER DATA CHANGES IN OTHER TABS
	console.group("apps.Parameters    " + this.id + "    updateParameters");
	console.log("apps.Parameters.updateParameters    args:");
	console.dir(args);
	
	// REDO PARAMETER TABLE
	if ( args.originator == this )
	{
		if ( args.reload == false )	return;
	}

	this.setDragSource();

	console.groupEnd("apps.Parameters    " + this.id + "    updateParameters");
},
toggleDescription : function () {
// TOGGLE DESCRIPTION DETAILS
	console.log("Packages.toggle    this.togglePoint.style.display: " + this.togglePoint.style.display);
	if ( this.togglePoint.style.display == 'inline-block' )	
		this.togglePoint.style.display='none';
	else
		this.togglePoint.style.display = 'inline-block';
},
setAppTypesCombo : function (type) {
// SET PARAMETERS COMBO BOX
	console.log("Parameters.setAppTypesCombo     plugins.apps.Parameters.setAppTypesCombo()");

	// GET PARAMETERS NAMES		
	var apps = Agua.getApps();
	console.log("Parameters.setAppTypesCombo     plugins.apps.Parameters.setAppTypesCombo()");

	var itemsArray = this.hashArrayKeyToArray(apps, "type");
	itemsArray = this.uniqueValues(itemsArray);
	console.log("Parameters.setAppTypesCombo     itemsArray: " + dojo.toJson(itemsArray));
	itemsArray = this.sortNoCase(itemsArray);
	itemsArray.splice(0,0, 'Order by Type');
	itemsArray.splice(0,0, 'Order by Name');

	var data = [];
	for ( var i = 0; i < itemsArray.length; i++ ) {
		data.push({ name: itemsArray[i]	});
	}
	console.log("Parameters.setAppTypesCombo     data: " + dojo.toJson(data));
	var store = new Memory({	idProperty: "name", data: data	});
	
	// SET COMBO
	this.appsCombo.store = store;
	this.appsCombo.startup();
	console.log("Parameters.setAppTypesCombo::setCombo     AFTER this.appsCombo.startup()");

	// SET COMBO VALUE
	var firstValue = itemsArray[0];
	this.appsCombo.set('value', firstValue);
	console.log("Parameters.setAppTypesCombo::setCombo     AFTER this.appsCombo.setValue(firstValue)");

	// SET PARAMETER NAMES COMBO
	this.setAppNamesCombo();
},
setAppNamesCombo : function () {
/* SET APP NAMES COMBO DEPENDENT ON THE CURRENT SELECTION
	IN THE APP COMBO
*/
	console.log("Parameters.setAppNamesCombo     plugins.apps.Parameters.setAppNamesCombo()");

	// GET SOURCE ARRAY AND FILTER BY PARAMETER NAME
	var type = this.appsCombo.get('value');
	console.log("Parameters.setAppNamesCombo     type: " + type);
	var itemArray = Agua.getApps();
	console.log("Parameters.setAppNamesCombo     BEFORE itemArray.length: " + itemArray.length);
	console.log("Parameters.setAppNamesCombo     BEFORE itemArray[0]: " + dojo.toJson(itemArray[0]));
	var keyArray = ["type"];
	var valueArray = [type];
	console.log("Parameters.setAppNamesCombo     valueArray: " + dojo.toJson(valueArray));
	if ( type == "Order by Name" )
		itemArray = this.sortHasharray(itemArray, 'name');
	else if ( type == "Order by Type" ) {
		itemArray = this.sortHasharray(itemArray, 'type');
	}
	else
		itemArray = this.filterByKeyValues(itemArray, keyArray, valueArray);
	console.log("Parameters.setAppNamesCombo     AFTER itemArray.length: " + itemArray.length);
	
	// CHECK itemArray IS NOT NULL OR EMPTY
	if ( itemArray == null || itemArray.length == 0 )	return;

	// SET STORE
	var data = [];
	for ( var i = 0; i < itemArray.length; i++ ) {
		data.push({ name: itemArray[i]	});
	}
	console.log("Parameters.setAppNamesCombo     data: ");
	console.dir({data:data});
	var store = new Memory({	idProperty: "name", data: data	});

	// SET COMBO
	this.appNamesCombo.store = store;
	this.appNamesCombo.startup();

	// SET COMBO VALUE
	var firstValue = itemArray[0].name;
	this.appNamesCombo.set('value', firstValue);

	// SET PARAMETERS COMBO
	console.log("Parameters.setAppNamesCombo    Completed. Now calling setDragSource");
	this.setDragSource();
},
setComboListeners : function () {
	////console.log("Parameters.setComboListeners    Parameter.setComboListeners()");

	// SET LISTENER FOR PARAM ORDER COMBO
	dojo.connect(this.paramOrderCombo, "onchange", this, "setDragSource");

	// SET LISTENER FOR PARAM FILTER COMBO
	dojo.connect(this.paramFilterCombo, "onchange", this, "setDragSource");

	dojo.connect(this.appsCombo, "onChange", dojo.hitch(this, function(){
		////console.log("Parameters.setComboListeners    **** appsCombo.onChange fired");
		////console.log("Parameters.setComboListeners    this: " + this);
		////console.log("Parameters.setComboListeners    Doing this.setAppNamesCombo()");
		this.setAppNamesCombo();
	}));
	
	var thisObject = this;
	dojo.connect(this.appNamesCombo, "onChange", dojo.hitch(this, function(){
		////console.log("Parameters.setComboListeners    **** appNamesCombo.onChange fired");
		////console.log("Parameters.setComboListeners    this: " + this);
		////console.log("Parameters.setComboListeners    thisObject: " + thisObject);
		////console.log("Parameters.setComboListeners    Doing this.setDragSource()");
		thisObject.setDragSource();
	}));

},
toggleLock : function () {
	////console.log("Parameters.toggleLock    plugins.apps.Parameters.toggleLock(name)");	
	if ( dojo.hasClass(this.locked, 'locked') ) {
		dojo.removeClass(this.locked, 'locked');
		dojo.addClass(this.locked, 'unlocked');
		Agua.warning("Parameter has been unlocked. Users can change this parameter");
	}	
	else {
		dojo.removeClass(this.locked, 'unlocked');
		dojo.addClass(this.locked, 'locked');
		Agua.warning("Parameter has been locked. Users cannot change this parameter");
	}	
},
setForm : function () {
// SET LISTENERS TO ACTIVATED SAVE BUTTON AND TO CLEAR DEFAULT TEXT
// WHEN INPUTS ARE CLICKED ON
	////console.log("Parameters.setForm    plugins.apps.Parameters.setForm()");

	// SET ADD PARAMETER ONCLICK
	dojo.connect(this.addParameterButton, "onclick", dojo.hitch(this, "saveInputs", null, {originator: this, reload: true}));

	// SET ONCLICK TO CANCEL INVALID TEXT
	this.setClearValues();

	// CHAIN TOGETHER INPUTS ON 'RETURN' KEYPRESS
	this.chainInputs(["name", "argument", "valuetype", "category", "value", "ordinal", "paramtype", "description", "discretion", "format", "args", "inputParams", "paramFunction", "addParameterButton"]);
},
getItemArray : function () {
	// FILTER SOURCE ARRAY BY type
	var appName = this.appNamesCombo.get('value');
	////console.log("Parameters.getItemArray    appName: " + appName);

	var itemArray = Agua.getParametersByAppname(appName);
	////console.log("Parameters.getItemArray    BEFORE SORT itemArray.length: " + itemArray.length);

	// ORDER APPS 
	var paramOrder = this.paramOrderCombo.value;
	////console.log("Parameters.getItemArray    paramOrder: " + paramOrder);
	if ( paramOrder == "Order by Name" )
		itemArray = this.sortHasharray(itemArray, 'name');
	else if ( paramOrder == "Order by Type" )
		itemArray = this.sortHasharray(itemArray, 'paramtype');
	else if ( paramOrder == "Order by Ordinal" )
		itemArray = this.sortHasharray(itemArray, 'ordinal');
	else
		itemArray = this.sortHasharray(itemArray, 'name');

	////console.log("Parameters.getItemArray    AFTER SORT itemArray.length: " + itemArray.length);

	//////console.log("Parameters.getItemArray    AFTER SORT itemArray: " + dojo.toJson(itemArray, true));

	// FILTER APPS 
	var paramFilter = this.paramFilterCombo.value;
	////console.log("Parameters.getItemArray    paramFilter: " + paramFilter);
	var keyArray = ["paramtype"];
	var valueArray = [paramFilter];
	if ( paramFilter == "All" ){
		////console.log("Parameters.getItemArray    No filter with paramfilter: " + paramFilter);			// do NOTHING
	}
	else
		itemArray = this.filterByKeyValues(itemArray, keyArray, valueArray);

	////console.log("Parameters.getItemArray    itemArray.length: " + itemArray.length);	
	return itemArray;
},
deleteItem : function (itemObject) {
// DELETE PARAMETER FROM Agua.parameters OBJECT AND IN REMOTE DATABASE
	////console.log("Parameters.deleteItem    plugins.apps.Parameters.deleteItem(name)");
	////console.log("Parameters.deleteItem    itemObject: " + dojo.toJson(itemObject));
	if ( itemObject.name == null ) 	return;
	if ( itemObject.appname == null ) 	return;

	itemObject.owner = Agua.cookie('username');

	// REMOVING PARAMETER FROM Agua.parameters
	Agua.removeParameter(itemObject)
	
	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateParameters", { originator: this });

}, // Parameter.deleteItem
saveInputs : function (inputs, updateArgs) {
	//	SAVE A PARAMETER TO Agua.parameters AND TO REMOTE DATABASE
	////console.log("Parameters.saveInputs    plugins.apps.Parameters.saveInputs(inputs, updateArgs)");
	////console.log("Parameters.saveInputs    inputs: " + dojo.toJson(inputs));	

	if ( this.savingInputs == true )	return;
	this.savingInputs = true;

	if ( inputs == null )
	{
		inputs = this.getFormInputs(this);
		//console.log("Parameters.saveInputs    this.allValid: " + this.allValid);	

		// RETURN IF INPUTS ARE NULL OR INVALID
		if ( inputs == null || this.allValid == false )
		{
			this.savingInputs = false;
			return;
		}
	}
	// SET OWNER AS SELF
	inputs.owner = Agua.cookie('username');

	// SET inputs APPLICATION NAME AND TYPE
	var appName = this.appNamesCombo.get('value');
	inputs.appname = appName;
	////console.log("Parameters.saveInputs    appName: " + appName);
	var appType = Agua.getAppType(appName);
	inputs.apptype = appType;
	////console.log("Parameters.saveInputs    appType: " + appType);

	// ADD NEW PARAMETER OBJECT TO Agua.parameters ARRAY
	Agua.addParameter(inputs);

	// REMOVE INVALID VALUES
	for ( var name in this.invalidInputs )
	{
		////console.log("Parameters.saveInputs    name: " + name);
		if ( inputs[name] == null ) inputs[name] = '';
		if ( inputs[name] == this.invalidInputs[name] )	inputs[name] = '';		
		inputs[name] = inputs[name].replace(/'/g, '"');
	}
	//////console.log("Parameters.saveInputs    AFTER replace DEFAULTS inputs: " + dojo.toJson(inputs));

	// DOUBLE-UP BACKSLASHES
	for ( var i = 0; i < inputs.length; i++ )
	{
		inputs[i] = this.convertBackslash(inputs[i], "expand");
	}

	// *** NOTE *** : SHIFT TO Agua.addParameter LATER

	// SAVE NEW PARAMETER TO REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi?";
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.mode 			= 	"saveParameter";
	query.module 		= 	"Agua::Workflow";
	query.data 			= 	inputs;
	//////console.log("Parameters.saveInputs    query: " + dojo.toJson(query));
	this.doPut({ url: url, query: query, sync: false });

	this.savingInputs = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateParameters", updateArgs);

}, // Parameter.saveInputs
getFormInputs : function (widget) {
	////console.log("Parameters.getFormInputs    plugins.apps.Parameterss.getFormInputs(widget)");
	////console.log("Parameters.getFormInputs    widget: " + widget);
	//////console.dir(widget);
	
	var inputs = new Object;	
	for ( var name in this.formInputs )
	{
		var value;
		// GET 'LOCKED' / 'UNLOCKED'
		if (dojo.hasClass(widget[name], 'locked'))
			value = "1";
		else if (dojo.hasClass(widget[name], 'unlocked'))
			value = "0";
		else value = this.getWidgetValue(widget[name]);			
		////console.log("Parameters.getFormInputs    " + name + ": " + value);
		inputs[name] = value;
		//////console.log("Parameters.getFormInputs    node " + name + " value: " + value);
	}
	////////console.log("Parameters.getFormInputs    inputs: " + dojo.toJson(inputs));
	
	inputs = this.checkInputs(widget, inputs);
	
	return inputs;
},
checkInputs : function (widget, inputs) {
	// SET INPUT FLAG SO THESE INPUTS ARE IGNORED:
	// 	argument AND discretion
	var inputFlag = false;
	//console.log("Parameters.checkInputs    this.paramtype: " + this.paramtype);
	var paramType = this.paramtype.value;
	//console.log("Parameters.checkInputs    paramType: " + paramType);
	if ( paramType == 'input' )	inputFlag = true;
	//console.log("Parameters.checkInputs    inputFlag: " + inputFlag);
	
	// CHECK INPUTS ARE VALID AND REQUIRED INPUTS ARE NOT EMPTY
	this.allValid = true;	
	for ( var key in this.formInputs )
	{
		// IGNORE THE argument AND discretion INPUTS IF IT'S NOT AN INPUT PARAMETER
		//if ( (key == "argument" || key == "discretion")
		if ( key == "argument" 
			&& inputFlag == false )
		{
			dojo.removeClass(widget[key], 'invalid');
			continue;
		}

		//console.log("Parameters.checkInputs    BEFORE inputs[key]: " + dojo.toJson(inputs[key]));
		inputs[key] = this.convertString(inputs[key], "htmlToText");
		inputs[key] = this.convertBackslash(inputs[key], "expand");
		////console.log("Parameters.checkInputs    AFTER inputs[key]: " + dojo.toJson(inputs[key]));
		
		if ( (this.isValidInput(key, inputs[key]) == false
				&& this.requiredInputs[key] != null)
			|| (this.requiredInputs[key] != null
				&& (inputs[key] == null || inputs[key] == '') ) )
		{
			////console.log("Parameters.this.allValid    invalid input " + key + ": " + inputs[key]);
			this.addClass(widget[key], 'invalid');
			this.allValid = false;
		}
		else{
			this.removeClass(widget[key], 'invalid');
		}
	}

	this.checkArgsBalance(widget);
	this.checkSyntax(widget);
	

	if ( this.allValid == false )	return null;
	return inputs;
},
checkArgsBalance : function(widget) {
	console.log("Parameters.checkArgsBalance    plugins.apps.Parameters.checkArgsBalance(widget)");
	console.log("Parameters.checkArgsBalance    console.dir(widget):");
	console.dir({widget: widget});
	
	var args = widget.args.innerHTML;
	var inputParams = widget.inputParams.innerHTML;

	console.log("Parameters.checkArgsBalance    args: " + args);
	console.log("Parameters.checkArgsBalance    inputParams: " + inputParams);
	
	var argsArray = args.split(/,/);
	console.log("Parameters.checkArgsBalance    argsArray.length: " + argsArray.length);
	
	var paramsArray = inputParams.split(/,/);
	console.log("Parameters.checkArgsBalance    paramsArray.length: " + paramsArray.length);
	if ( paramsArray == null )	return;
	if ( paramsArray.length == null || paramsArray.length == 0 )	return;
	
	if ( argsArray.length == null
		|| argsArray.length != paramsArray.length )
	{
		this.allValid = false;
		this.setInvalid(widget.args);
		this.setInvalid(widget.inputParams);
	}
	else {
		this.setValid(widget.args);
		this.setValid(widget.inputParams);
	}
	
	console.log("Parameters.checkArgsBalance    FINAL this.allValid: " + this.allValid);
},
checkSyntax : function(widget) {
	console.log("Parameters.checkSyntax    plugins.apps.Parameterss.checkSyntax(widget)");
	console.log("Parameters.checkSyntax    console.dir(widget):");
	console.dir({widget: widget});

	var inputParams = widget.inputParams.innerHTML;
	var paramFunction = widget.paramFunction.innerHTML;

	console.log("Parameters.checkSyntax    inputParams: " + inputParams);
	console.log("Parameters.checkSyntax    paramFunction: " + paramFunction);

	try {
		var funcString = "var func = function(" + inputParams + ") {" + paramFunction + "}";
		console.log("Parameters.checkSyntax    funcString: " + funcString);
		eval(funcString);
		console.log("Parameters.checkSyntax    eval OK");
		this.setValid(widget.paramFunction);
	}
	catch (error) {
		console.log("error: " + error);
		this.allValid = false;
		this.setInvalid(widget.paramFunction);
	}

	console.log("Parameters.checkArgsBalance    FINAL this.allValid: " + this.allValid);
}


}); //	end declare

});	//	end define

