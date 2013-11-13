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
	"dijit/form/ValidationTextBox"
	],
function (declare, arrayUtil, JSON, on, lang, domClass, CommonUtil) {
/////}}}}}}}
return declare("plugins.form.ValidationTextBox",
	[ dijit._Widget, dijit._Templated, CommonUtil ], {

/////}}}}}}}

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/form/templates/validationtextbox.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

_earlyTemplatedStartup: true,

noStart : false,
 
disabled : "false", 

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("dijit/themes/dijit.css"),
	require.toUrl("dijit/themes/soria/soria.css"),
	require.toUrl("dijit/themes/tundra/tundra.css"),
	require.toUrl("plugins/form/css/validationtextbox.css")
],

// PARENT plugins.workflow.Apps WIDGET
parentWidget : null,

// APPLICATION OBJECT
application : null,

// CORE WORKFLOW OBJECTS
core : null,

// PATTERN to validate input
pattern : ".*",

// label : String
//		Label for text box
label: "",

// value : String
// 		Default value displayed in textbox
value : null,

/////}}}}}

constructor : function(args) {

/////}}}}}

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
	console.log("ValidationTextBox.showValue    this.value: " + this.value);

	if ( this.value ) {
		this.input.textbox.value = this.value;
	}
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
	var valid = this.input.validate(false);
	//console.log("ValidationTextBox.isValid    caller: " + this.isValid.caller.nom);
	//console.log("ValidationTextBox.isValid    valid: " + valid);
	
	if ( ! valid ) {
		this.input._set("state", "Error")
	}
	else {
		this.input._set("state", "")
	}
	
	return valid;
},
getValue : function () {
	return this.input.textbox.value;
},
setValue : function (value) {
	this.input.textbox.value = value;	
}


}); 	//	end declare

});	//	end define
