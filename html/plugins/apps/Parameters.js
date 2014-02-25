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

// DEBUG : Boolean
//		Print debug output if true
DEBUG : true,

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

// attachPoint : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

/////}}}}}

constructor : function(args) {
	console.log("******************************HERE");
	this.logDebug("args: ");
	console.dir({args:args});
	console.log("******************************AFTER");

    // MIXIN ARGS
    lang.mixin(this, args);
},
postCreate : function() {
////console.log("Controller.postCreate    plugins.apps.Controller.postCreate()");

	// LOAD CSS
	this.loadCSS();		

	// COMPLETE CONSTRUCTION OF OBJECT
	////this.logDebug("DOING this.inherited(arguments)");
	this.inherited(arguments);	 
	////this.logDebug("AFTER this.inherited(arguments)");

	//this.startup();
},
startup : function () {
	console.group("App-" + this.id + "    startup");

	this.logDebug("this", this);
	var variable = "someValue";
	this.logDebug("variable", variable);

	// COMPLETE CONSTRUCTION OF OBJECT
	////this.logDebug("DOING this.inherited(arguments)");
	this.inherited(arguments);	 
	////this.logDebug("AFTER this.inherited(arguments)");

	// ATTACH PANE
	this.attachPane();

	// SET PARAMETERS COMBO
	this.logDebug("DOING this.setAppTypesCombo()");
	this.setAppTypesCombo();

	
	
	// SET NEW PARAMETER FORM
	this.logDebug("DOING this.setForm()");
	this.setForm();

	// SET TRASH
	this.logDebug("DOING this.setTrash()");

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
	this.logDebug("this.attachPoint: " + this.attachPoint);
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
	////this.logDebug("admin.Parameter.updateApps(args)");
	////this.logDebug("args: ");
	////console.dir(args);

	// SET PARAMTYPES COMBO
	////this.logDebug("Calling setAppNamesCombo()");
	this.setAppNamesCombo();
	
	// SET APPS COMBO
	////this.logDebug("Calling setAppTypesCombo()");
	this.setAppTypesCombo();
	
	// SET DRAG SOURCE
	////this.logDebug("Calling setDragSource()");
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
	this.logDebug(" plugins.apps.Parameters.setAppTypesCombo()");

	// GET PARAMETERS NAMES		
	var apps = Agua.getApps();
	this.logDebug(" plugins.apps.Parameters.setAppTypesCombo()");

	var itemsArray = this.hashArrayKeyToArray(apps, "type");
	itemsArray = this.uniqueValues(itemsArray);
	this.logDebug(" itemsArray: " + dojo.toJson(itemsArray));
	itemsArray = this.sortNoCase(itemsArray);
	itemsArray.splice(0,0, 'Order by Type');
	itemsArray.splice(0,0, 'Order by Name');

	var data = [];
	for ( var i = 0; i < itemsArray.length; i++ ) {
		data.push({ name: itemsArray[i]	});
	}
	this.logDebug(" data: " + dojo.toJson(data));
	var store = new Memory({	idProperty: "name", data: data	});
	
	// SET COMBO
	this.appsCombo.store = store;
	this.appsCombo.startup();
	this.logDebug(" AFTER this.appsCombo.startup()");

	// SET COMBO VALUE
	var firstValue = itemsArray[0];
	this.appsCombo.set('value', firstValue);
	this.logDebug(" AFTER this.appsCombo.setValue(firstValue)");

	// SET PARAMETER NAMES COMBO
	this.setAppNamesCombo();
},
setAppNamesCombo : function () {
/* SET APP NAMES COMBO DEPENDENT ON THE CURRENT SELECTION
	IN THE APP COMBO
*/
	this.logDebug(" plugins.apps.Parameters.setAppNamesCombo()");

	// GET SOURCE ARRAY AND FILTER BY PARAMETER NAME
	var type = this.appsCombo.get('value');
	this.logDebug(" type: " + type);
	var itemArray = Agua.getApps();
	this.logDebug(" BEFORE itemArray.length: " + itemArray.length);
	this.logDebug(" BEFORE itemArray[0]: " + dojo.toJson(itemArray[0]));
	var keyArray = ["type"];
	var valueArray = [type];
	this.logDebug(" valueArray: " + dojo.toJson(valueArray));
	if ( type == "Order by Name" )
		itemArray = this.sortHasharray(itemArray, 'name');
	else if ( type == "Order by Type" ) {
		itemArray = this.sortHasharray(itemArray, 'type');
	}
	else
		itemArray = this.filterByKeyValues(itemArray, keyArray, valueArray);
	this.logDebug(" AFTER itemArray.length: " + itemArray.length);
	
	// CHECK itemArray IS NOT NULL OR EMPTY
	if ( itemArray == null || itemArray.length == 0 )	return;

	// SET STORE
	var data = [];
	for ( var i = 0; i < itemArray.length; i++ ) {
		data.push({ name: itemArray[i]	});
	}
	this.logDebug(" data: ");
	console.dir({data:data});
	var store = new Memory({	idProperty: "name", data: data	});

	// SET COMBO
	this.appNamesCombo.store = store;
	this.appNamesCombo.startup();

	// SET COMBO VALUE
	var firstValue = itemArray[0].name;
	this.appNamesCombo.set('value', firstValue);

	// SET PARAMETERS COMBO
	this.logDebug("Completed. Now calling setDragSource");
	this.setDragSource();
},
setComboListeners : function () {
	////this.logDebug("Parameter.setComboListeners()");

	// SET LISTENER FOR PARAM ORDER COMBO
	dojo.connect(this.paramOrderCombo, "onchange", this, "setDragSource");

	// SET LISTENER FOR PARAM FILTER COMBO
	dojo.connect(this.paramFilterCombo, "onchange", this, "setDragSource");

	dojo.connect(this.appsCombo, "onChange", dojo.hitch(this, function(){
		////this.logDebug("**** appsCombo.onChange fired");
		////this.logDebug("this: " + this);
		////this.logDebug("Doing this.setAppNamesCombo()");
		this.setAppNamesCombo();
	}));
	
	var thisObject = this;
	dojo.connect(this.appNamesCombo, "onChange", dojo.hitch(this, function(){
		////this.logDebug("**** appNamesCombo.onChange fired");
		////this.logDebug("this: " + this);
		////this.logDebug("thisObject: " + thisObject);
		////this.logDebug("Doing this.setDragSource()");
		thisObject.setDragSource();
	}));

},
toggleLock : function () {
	////this.logDebug("plugins.apps.Parameters.toggleLock(name)");	
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
	////this.logDebug("plugins.apps.Parameters.setForm()");

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
	////this.logDebug("appName: " + appName);

	var itemArray = Agua.getParametersByAppname(appName);
	////this.logDebug("BEFORE SORT itemArray.length: " + itemArray.length);

	// ORDER APPS 
	var paramOrder = this.paramOrderCombo.value;
	////this.logDebug("paramOrder: " + paramOrder);
	if ( paramOrder == "Order by Name" )
		itemArray = this.sortHasharray(itemArray, 'name');
	else if ( paramOrder == "Order by Type" )
		itemArray = this.sortHasharray(itemArray, 'paramtype');
	else if ( paramOrder == "Order by Ordinal" )
		itemArray = this.sortHasharray(itemArray, 'ordinal');
	else
		itemArray = this.sortHasharray(itemArray, 'name');

	////this.logDebug("AFTER SORT itemArray.length: " + itemArray.length);

	//////this.logDebug("AFTER SORT itemArray: " + dojo.toJson(itemArray, true));

	// FILTER APPS 
	var paramFilter = this.paramFilterCombo.value;
	////this.logDebug("paramFilter: " + paramFilter);
	var keyArray = ["paramtype"];
	var valueArray = [paramFilter];
	if ( paramFilter == "All" ){
		////this.logDebug("No filter with paramfilter: " + paramFilter);			// do NOTHING
	}
	else
		itemArray = this.filterByKeyValues(itemArray, keyArray, valueArray);

	////this.logDebug("itemArray.length: " + itemArray.length);	
	return itemArray;
},
deleteItem : function (itemObject) {
// DELETE PARAMETER FROM Agua.parameters OBJECT AND IN REMOTE DATABASE
	////this.logDebug("plugins.apps.Parameters.deleteItem(name)");
	////this.logDebug("itemObject: " + dojo.toJson(itemObject));
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
	////this.logDebug("plugins.apps.Parameters.saveInputs(inputs, updateArgs)");
	////this.logDebug("inputs: " + dojo.toJson(inputs));	

	if ( this.savingInputs == true )	return;
	this.savingInputs = true;

	if ( inputs == null )
	{
		inputs = this.getFormInputs(this);
		//this.logDebug("this.allValid: " + this.allValid);	

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
	////this.logDebug("appName: " + appName);
	var appType = Agua.getAppType(appName);
	inputs.apptype = appType;
	////this.logDebug("appType: " + appType);

	// ADD NEW PARAMETER OBJECT TO Agua.parameters ARRAY
	Agua.addParameter(inputs);

	// REMOVE INVALID VALUES
	for ( var name in this.invalidInputs )
	{
		////this.logDebug("name: " + name);
		if ( inputs[name] == null ) inputs[name] = '';
		if ( inputs[name] == this.invalidInputs[name] )	inputs[name] = '';		
		inputs[name] = inputs[name].replace(/'/g, '"');
	}
	//////this.logDebug("AFTER replace DEFAULTS inputs: " + dojo.toJson(inputs));

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
	//////this.logDebug("query: " + dojo.toJson(query));
	this.doPut({ url: url, query: query, sync: false });

	this.savingInputs = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateParameters", updateArgs);

}, // Parameter.saveInputs
getFormInputs : function (widget) {
	////this.logDebug("plugins.apps.Parameterss.getFormInputs(widget)");
	////this.logDebug("widget: " + widget);
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
		////this.logDebug("" + name + ": " + value);
		inputs[name] = value;
		//////this.logDebug("node " + name + " value: " + value);
	}
	////////this.logDebug("inputs: " + dojo.toJson(inputs));
	
	inputs = this.checkInputs(widget, inputs);
	
	return inputs;
},
checkInputs : function (widget, inputs) {
	// SET INPUT FLAG SO THESE INPUTS ARE IGNORED:
	// 	argument AND discretion
	var inputFlag = false;
	//this.logDebug("this.paramtype: " + this.paramtype);
	var paramType = this.paramtype.value;
	//this.logDebug("paramType: " + paramType);
	if ( paramType == 'input' )	inputFlag = true;
	//this.logDebug("inputFlag: " + inputFlag);
	
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

		//this.logDebug("BEFORE inputs[key]: " + dojo.toJson(inputs[key]));
		inputs[key] = this.convertString(inputs[key], "htmlToText");
		inputs[key] = this.convertBackslash(inputs[key], "expand");
		////this.logDebug("AFTER inputs[key]: " + dojo.toJson(inputs[key]));
		
		if ( (this.isValidInput(key, inputs[key]) == false
				&& this.requiredInputs[key] != null)
			|| (this.requiredInputs[key] != null
				&& (inputs[key] == null || inputs[key] == '') ) )
		{
			////this.logDebug("invalid input " + key + ": " + inputs[key]);
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
	this.logDebug("plugins.apps.Parameters.checkArgsBalance(widget)");
	this.logDebug("console.dir(widget):");
	console.dir({widget: widget});
	
	var args = widget.args.innerHTML;
	var inputParams = widget.inputParams.innerHTML;

	this.logDebug("args: " + args);
	this.logDebug("inputParams: " + inputParams);
	
	var argsArray = args.split(/,/);
	this.logDebug("argsArray.length: " + argsArray.length);
	
	var paramsArray = inputParams.split(/,/);
	this.logDebug("paramsArray.length: " + paramsArray.length);
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
	
	this.logDebug("FINAL this.allValid: " + this.allValid);
},
checkSyntax : function(widget) {
	this.logDebug("plugins.apps.Parameterss.checkSyntax(widget)");
	this.logDebug("console.dir(widget):");
	console.dir({widget: widget});

	var inputParams = widget.inputParams.innerHTML;
	var paramFunction = widget.paramFunction.innerHTML;

	this.logDebug("inputParams: " + inputParams);
	this.logDebug("paramFunction: " + paramFunction);

	try {
		var funcString = "var func = function(" + inputParams + ") {" + paramFunction + "}";
		this.logDebug("funcString: " + funcString);
		eval(funcString);
		this.logDebug("eval OK");
		this.setValid(widget.paramFunction);
	}
	catch (error) {
		console.log("error: " + error);
		this.allValid = false;
		this.setInvalid(widget.paramFunction);
	}

	this.logDebug("FINAL this.allValid: " + this.allValid);
}


}); //	end declare

});	//	end define

