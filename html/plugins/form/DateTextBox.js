define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-class",
	"plugins/core/Common/Util",
	"dojo/domReady!",

	"dijit/_Widget",
	"dijit/_Templated",
	"dojox/form/DateTextBox"
	],

function (declare, arrayUtil, JSON, on, lang, domClass, CommonUtil) {

return declare("plugins.form.DateTextBox",
	[ dijit._Widget, dijit._Templated, CommonUtil ], {

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/form/templates/datetextbox.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

_earlyTemplatedStartup: true,

noStart : false,
 
// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("dijit/themes/dijit.css"),
	require.toUrl("dijit/themes/soria/soria.css"),
	require.toUrl("dijit/themes/tundra/tundra.css"),
	require.toUrl("dojox/widget/Calendar/Calendar.css"),
	require.toUrl("plugins/form/css/datetextbox.css")
],

// parentWidget : Object
// 		The widget that created this widget
parentWidget : null,

// core : HashRef
//		Exchange for major objects
core : null,

// pattern : String
// 		Pattern is used in regex to validate input
pattern : ".*",

// value : String
// 		Default value displayed in textbox
value : null,

// promptMessage : String
//		Display this message if user clicks on empty input if its required
promptMessage : null,

// invalidMessage : String
//		Display this message the input is invalid
invalidMessage : null,

// required : Boolean
//		True if input is required, otherwise false
required : null,

// constraints : String
//		Hash
constraints : null,

/////}}}}}
constructor : function(args) {
	dojo.mixin(this, args);
	
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	this.inherited(arguments);
	
	this.setParameters();
	
	this.showValue();
},
showValue : function () {
	console.log("DateTextBox.showValue    this.value: " + this.value);
	if ( this.value ) {
		this.input.textbox.value = this.value;
	}
	else {
		var date = new Date();
		console.log("DateTextBox.showValue    this.value: " + this.value);
		console.dir({date:date});
		
		var dateString = this.formatDate(date);
		console.log("DateTextBox.showValue    dateString: " + dateString);
		
		this.input.textbox.value = dateString;
	}
},
formatDate : function (date) {
	var string = ('0' + (date.getMonth()+1)).slice(-2) + '/'
		+ ('0' + date.getDate()).slice(-2) + '/'
		+ date.getFullYear();
	
	return string;
},
setParameters : function () {
	var parameters = [
		"pattern",
		"maxlength",
		"value",
		"invalidMessage",
		"promptMessage",
		"required"
	];
	for ( var i in parameters ) {
		var parameter = parameters[i];
		this.input[parameter] = this[parameter];
	}
},
isValid : function () {
	var value = this.input.valueNode.value;
	//console.log("DateTextBox.isValid    value: " + value);
	var valid	= this.validate(value);
	//console.log("DateTextBox.isValid    valid: " + valid);
	
	if ( ! valid ) {
		this.input._set("state", "Error")
	}
	else {
		this.input._set("state", "")
	}
	
	return valid;
},
validate : function(value){	
	var result = true;
	if (
		value == ""
		|| value == null
		|| isNaN(value)
		|| typeof value == "object"
		|| value.toString() == this._invalidDate
	) {
		valid = false;
	}
	
	var regex = new RegExp(this.pattern);
	if ( ! value.match(regex) ) {
		result = false;
	}
	
	return result;
},
getValue : function () {
	return this.input.textbox.value;
}


}); 	//	end declare

});	//	end define
