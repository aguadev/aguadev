define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/core/Common/Util",
	"plugins/core/Common/Array",
	"plugins/core/Common/Sort",
	"plugins/core/Util/ViewSize",
	"dojo/ready",
	"dojo/domReady!",

	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/form/ValidationTextBox",
	"plugins/form/TextArea",
	"plugins/form/Select",
	"dijit/layout/ContentPane",
	"dijit/form/Button",
	"dijit/form/Select",
	"plugins/dojox/widget/Dialog"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, CommonUtil, CommonArray, CommonSort, ViewSize, ready) {

/////}}}}}

return declare("plugins.infusion.Dialog.Base",
	[ dijit._Widget, dijit._Templated, CommonUtil, CommonArray, CommonSort ], {

//Path to the template of this widget. 
templatePath: null,

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// type : String
//		Type of dialog, e.g., project, sample, flowcell, lane, requeue
type : null,

// fields : String[]
//		Array of form input fields
fields: [],

// fieldNameMap : String{}
//		Hash mapping between table fields and input names
fieldNameMap : {},

// nameFieldMap : String{}
//		Hash mapping between input names and table fields
//		Calculated as reverse of fieldNameMap on startup
nameFieldMap : {},

// values : String{}
//		Hash of values provided in instantiation arguments
values : {},

// status_id : Integer
// 		Corresponds to a status value in the 'status' table
status_id : null,

// core: Hash
// 		Holder for major components, e.g., core.data, core.dataStore
core : null,

/////}}}}}
constructor : function(args) {
    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Base.postCreate plugins.infusion.Dialog.Base");

	this.startup();
},
startup : function () {
	console.log("Base.startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);

	// ADD TO TAB CONTAINER		
	console.log("Base.startup    BEFORE appendChild(this.mainTab.domNode)");
	dojo.byId("attachPoint").appendChild(this.mainTab.domNode);
	console.log("Base.startup    AFTER appendChild(this.mainTab.domNode)");
	
	// SET SAVE BUTTON
	dojo.connect(this.saveButton, "onClick", dojo.hitch(this, "save"));

	// SET SELECTS
	console.log("Base.startup    DOING this.setSelects()");
	this.setSelects();

	// SET nameFieldMap
	this.setNameFieldMap();
	
	// POPULATE FIELDS
	console.log("Base.startup    DOING this.populateFields(this.values)");
	console.dir({this_values:this.values});
	this.populateFields(this.values);
	
	// SHOW
	console.log("Base.startup    DOING this.mainTab.show()");
	this.mainTab.show();
},
setNameFieldMap : function () {
	var nameFieldMap = {};
	for ( var field in this.fieldNameMap ) {
		nameFieldMap[this.fieldNameMap[field]] = field;
	}
	console.log("Base.setNameFieldMap    nameFieldMap: ");
	console.dir({nameFieldMap:nameFieldMap});
	
	this.nameFieldMap = nameFieldMap;
},
populateFields : function (values) {
	//console.log("Base.populateFields     values:");
	//console.dir({values:values});
	//console.log("Base.populateFields     value.length: " + values.length);
	
	if ( values.status_id ) {
		values = this.setStatus(values);
	}
	if ( values.lcm_broad_cause ) {
		values = this.setBroadCauses(this.type);
	}
	if ( values.lcm_specific_cause ) {
		values = this.setSpecificCauses(this.type);
	}
	
	for ( var field in values ) {
		if ( field == "status_id" ) {
			this["status_id"]	= values[field] || "";
		}
		else {
			//console.log("Base.populateFields     field: " + field);
			var name = this.fieldNameMap[field];
			if ( ! this[name]) {
				console.log("Base.populateFields     this[" + name + "]: not defined. Skipping");
				continue;
			}
			//console.log("Base.populateFields     name: " + name);
			
			var value = values[field] || "";
			//console.log("Base.populateFields     value: " + value);
			
			if ( this[name] ) {
				//console.log("Base.populateFields     setting this[" + name + "] to value: " + value);
				
				this[name].setValue(value);
			}
		}
	}
	
	this.values = values;	
},
setStatus : function (values) {
	//console.log("Base.setStatus    values: ");
	//console.dir({values:values});
	
	var status = values.status_id;
	//console.log("Base.setStatus    status: " + status);
	
	var hash = this.core.data.getHash("status", "hash", "status_id", "status");
	var status = hash[status];
	//console.log("Base.setStatus    status: " + status);
	
	values.status = status;
	delete values.status_id;
	
	return values;
},
setSelects : function () {},
setFailureMode : function () {
	//console.log("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Base.setFailureMode    this.values: ");
	//console.dir({this_values:this.values});
	
	this.setSymptoms(this.type);
	this.setBroadCauses(this.type);
	if ( this.values && this.values.lcm_specific_cause ) {
		this.setSpecificCauses(this.type, null);
	}
	this.setLcmStatus(this.type);
	this.setLcmEquipmentRelated(this.type);
},
setSymptoms: function (type) {
	//console.log("------------------------------------Base.setSymptoms    type: " + type);
	var table = this.core.data.getTable("symptoms") || [];
	//console.log("------------------------------------Base.setSymptoms    table: ");
	//console.dir({table:table});

	var hasharray = this.filterByKeyValues(table, ["category"], [type]);
	//console.log("------------------------------------Base.setSymptoms    hasharray: ");
	//console.dir({hasharray:hasharray});

	var options = this.hashArrayKeyToArray(hasharray, "symptom");
	options.unshift("");
	//console.log("------------------------------------Base.setSymptoms    options: " + options);
	
	var selected = this.values.symptoms || null;
	this.setSelectOptions("symptoms", options, selected);
},
setBroadCauses: function (type) {
	//console.log("------------------------------------Base.setBroadCauses    type: " + type);
	var table = this.core.data.getTable("causes") || [];
	//console.log("------------------------------------Base.setBroadCauses    table: ");
	//console.dir({table:table});
	//console.log("------------------------------------Base.setBroadCauses    Agua.data: ");
	//console.dir({Agua_data:Agua.data});

	var hasharray = this.filterByKeyValues(table, ["category"], [type]);
	//console.log("------------------------------------Base.setBroadCauses    hasharray: ");
	//console.dir({hasharray:hasharray});

	var options = this.hashArrayKeyToArray(hasharray, "lcm_broad_cause");
	options = this.uniqueValues(options);
	options.unshift("");
	//console.log("------------------------------------Base.setBroadCauses    options: " + options);
	
	// SET WORKFLOW LISTENER
	// NOTE: LATER CHANGE TO 'on'
	//console.log("------------------------------------Base.setBroadCauses    this.lcmBroadCause: ");
	//console.dir({this_lcmBroadCause:this.lcmBroadCause});
	//console.log("------------------------------------Base.setBroadCause.inputs    this.lcmBroadCause.input: ");
	//console.dir({this_lcmBroadCause_input:this.lcmBroadCause.input});
	var thisObject = this;
	dojo.connect(this.lcmBroadCause.input, "onchange", function() {
		//console.log("------------------------------------Base.setBroadCauses    options: this.lcmBroadCause.onChange FIRED");
		var broadCause = thisObject.lcmBroadCause.getValue();
		//console.log("------------------------------------broadCause: " + broadCause);
		
		thisObject.setSpecificCauses(type, broadCause);
	})	

	this.setSelectOptions("lcmBroadCause", options, null);
},
setSpecificCauses: function (type, broadCause) {
	//console.log("000000000000000000 Base.setSpecificCauses    type: " + type);
	//console.log("000000000000000000 Base.setSpecificCauses    broadCause: " + broadCause);
	if ( ! broadCause ) {
		//console.log("000000000000000000 Base.setSpecificCauses    broadCause not defined. Clearning and returning");
		this.setSelectOptions("lcmSpecificCause", [], null);
		return;
	}
	
	var table = this.core.data.getTable("causes") || [];
	//console.log("000000000000000000 Base.setSpecificCauses    table: ");
	//console.dir({table:table});
	//console.log("000000000000000000 Base.setSpecificCauses    Agua.data: ");
	//console.dir({Agua_data:Agua.data});

	var hasharray = this.filterByKeyValues(table, ["category", "lcm_broad_cause"], [type, broadCause]);

	var options = this.hashArrayKeyToArray(hasharray, "lcm_specific_cause");
	//console.log("000000000000000000 Base.setSpecificCauses    options: " + options);
	
	this.setSelectOptions("lcmSpecificCause", options, null);
},
setLcmStatus : function (type) {
	this.setSelectOptions("lcmStatus", ["", "Open", "Closed", "Tentative"], null);	
},
setLcmEquipmentRelated : function (type) {
	this.setSelectOptions("lcmEquipmentRelated", ["", "Yes", "No"], null);	
},
setStatusOptions : function () {
	var type = this.type;
	var table = this.core.data.getTable("statustype") || [];
	//console.log("Base.setStatusOptions    type: " + type);
	//console.log("Base.setStatusOptions    table: ");
	//console.dir({table:table});

	var hasharray = this.filterByKeyValues(table, ["type"], [type]);

	var options = this.hashArrayKeyToArray(hasharray, "status");
	//console.log("Base.setStatusOptions    options: " + options);

	var selected = this.getStatus() || null;
	this.setSelectOptions("status", options, selected);

	return;
},
getStatus : function () {
	var hash = this.core.data.getHash("status", "hash", "status_id", "status");
	
	var status_id = this.values.status_id;
	if ( ! status_id )	return null;
	
	return hash[status_id];
},
getStatusId : function (status) {
	var hash = this.core.data.getHash("status", "hash", "status", "status_id");
	
	if ( ! status )	return null;
	
	return hash[status];
},
setSelectOptions : function (selectName, array, selected) {
	//console.log("********************* Base.setSelectOptions    selectName: " + selectName);
	//console.log("Base.setSelectOptions    array: " + array);
	//console.log("Base.setSelectOptions    selected: " + selected);
	var options = [];
	var first = true;
	for ( var index in array ) {
		var item = array[index];
		//console.log("Base.setSelectOptions    item: " + item);
		if ( ! selected ) {
			if ( first )
				options.push({ label: item, value: item, 'selected': true });
			else
				options.push({ label: item, value: item });
			first = false;
		}
		else {
			if ( item == selected )
				options.push({ label: item, value: item, 'selected': true });
			else
				options.push({ label: item, value: item });
		}
	}
	
	//console.log("DOING this[" + selectName + "].setOptions(options)");
	this[selectName].setOptions(options);
},
// SAVE
save : function (event) {
	console.log("Base.save    event: " + event);
	
	if ( this.saving == true ) {
		console.log("Base.save    this.saving: " + this.saving + ". Returning.");
		return;
	}
	this.saving = true;

	var query = this.getData();
	if ( ! query ) {
		console.log("Base.save    One or more inputs not valid. Returning");
		this.saving = false;
		return;
	}

	this.sendQuery(query);
},
getData : function () {
	console.log("Base.getData");	

	var parameters = this.fields;
	var data = {};
	for ( var i = 0; i < parameters.length; i++ ) {
		var parameter = parameters[i];
		console.log("Base.save    ******* parameter: " + parameter);
		var value = this[parameter].getValue();
		console.log("Base.save    value: " + value);
		var valid = this[parameter].isValid();
		console.log("Base.save    valid: " + valid);

		if ( ! valid ) {
			return null;
		}
		
		var field = this.nameFieldMap[parameter];
		data[field] = value || "";
	}

	// CONVERT STATUS ID FROM STATUS
	data.status_id = this.getStatusId(this.status.getValue()) || "";
	
	return data;
},
sendQuery : function (data) {
	console.log("Base.sendQuery    data: " + dojo.toJson(data));
	console.dir({data:data});

	var mode = "update" + this.type.substring(0,1).toUpperCase() + this.type.substring(1);
	console.log("Base.sendQuery    mode: " + mode);
	
	var url = Agua.cgiUrl + "infusion.cgi?";
	
	// CREATE JSON QUERY
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie("username");
	query.sessionid 	= 	Agua.cookie("sessionid");
	query.taskid		=	this.core.infusion.taskid;
	query.mode 			= 	mode;
	query.module		= 	"Infusion::Base";
	query.token			= 	this.core.infusion.token;
	query.data 			= 	data;
	console.log("Base.save    query: " + dojo.toJson(query));
	console.dir({query:query});
	
	// SEND TO SERVER
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			handle : function(json, ioArgs) {
				console.log("Base.save    json:");
				console.dir({json:json});
				
				var response = JSON.parse(json);
				thisObj.handleSave(response.data);
			},
			error : function(response, ioArgs) {
				console.log("Base.save    Error with JSON Post, response: ");
				console.dir({response:response});
			}
		}
	);
	
	this.saving = false;
},
handleSave : function (data) {
	console.log("Base.handleSave    data: ");
	console.dir({data:data});

	// UPDATE TABLE IN data
	console.log("Base.handleSave    DOING this.core.data.updateTable('sample', data)");
	this.core.data.updateTable(this.type, data);
},
cleanEdges : function (string) {
// REMOVE WHITESPACE FROM EDGES OF TEXT
	if ( string == null )	{ 	return null; }
	string = string.replace(/^\s+/, '');
	string = string.replace(/\s+$/, '');
	return string;
},
show : function () {
	console.log("Base.show    DOING .mainTab.show()");
	
	this.mainTab.show();
},
hide : function () {
	console.log("Base.hide    DOING .mainTab.hide()");
	
	this.mainTab.hide();
}

}); 	//	end declare

});	//	end define

