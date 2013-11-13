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

return declare("plugins.form.Dialog.Base",
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

// core: Hash
// 		Holder for major components
core : null,

/////}}}}}
constructor : function(args) {
    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
},
populateFields : function (values) {
	//console.log("Base.populateFields     values:");
	//console.dir({values:values});
	//console.log("Base.populateFields     value.length: " + values.length);
	
	for ( var field in values ) {
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
	
	this.values = values;	
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

