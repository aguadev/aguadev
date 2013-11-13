define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-class",
	"plugins/core/Common/Util",
	"dojo/ready",
	"dojo/domReady!",

	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/form/Select"
	],

function (declare, arrayUtil, JSON, on, lang, domClass, CommonUtil, ready) {

return declare("plugins.form.Select",
	[ dijit._Widget, dijit._TemplatedMixin, CommonUtil ], {
		
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/form/templates/select.html"),

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
	require.toUrl("plugins/form/css/select.css")
],

// tooltipPosition: String[]
//		See description of `dijit/Tooltip.defaultPosition` for details on this parameter.
tooltipPosition: [],

// options: Hash[]
// Array of options hashes with 'label' and 'value' slots (optional slot: 'selected')
options: [],

// disabled : Boolean
//		Disable input by preventing popup and grey out
//		Supported inputs: 'disabled' to disable, '' to enable
disabled : '',

/////}}}}}

constructor : function(args) {
	dojo.mixin(this, args);
	
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {

	if ( this.options ) {
		this.setOptions(this.options);
	}
},
setOptions : function (options) {
	console.log("Select.setOptions    options:");
	console.dir({options:options});

	var optionString = "";
	for ( var i in options ) {
		optionString += "<option class='options' value='" + options[i].value + "'";
		if ( options[i].selected )
			optionString += " selected='selected'" ;
		optionString += ">";
		optionString += options[i].label + "</option>\n";
	}
	this.input.innerHTML = optionString;	
},
isValid : function () {
	return 1;
},
setValue : function (value) {
	//console.log("plugins.form.Select.setValue    value: " + value);
	//console.log("plugins.form.Select.setValue    this: " + this);
	//console.dir({this:this});
	
	this.input.value = value;
},
getValue : function () {
	return this.input.value || "";
}



}); 	//	end declare

});	//	end define
