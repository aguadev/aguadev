define([
	"dojo/_base/declare",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common/Util",
	"dojo/domReady!",
	"dijit/layout/TabContainer",
	"dijit/form/Select"
],

function (
	declare,
	on,
	lang,
	domAttr,
	domClass,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	CommonUtil
) {

/////}}}}}

return declare("plugins.request.QueryRow",
	[
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	CommonUtil
], {

// templateString : String
//		Template of this widget. 
templateString: dojo.cache("plugins", "request/templates/queryrow.html"),

// parentWidget	:	Widget object
// 		Widget that has this parameter row
parentWidget : null,

// action : String
//		Action related to query term: AND or OR
action : "",

// field : String
//		Field name, e.g., "Participant ID"
field : "",

// operator : String
//		Action related to query term: ==, !=, >, <, >=, <=, contains, !contains
operator : "",

// value : String
//		Query term
value : "",

// cssFiles : Array
//		Array of CSS files to be loaded for all widgets in template
// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/request/css/queryrow.css"),
	require.toUrl("dojo/tests/dnd/dndDefault.css"),
	require.toUrl("dijit/themes/claro/document.css")
	//,
	//require.toUrl("dijit/tests/css/dijitTests.css")
],
/////}}}}}
constructor : function(args) {
	console.log("QueryRow.constructor    args: ");
	console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
	
	this.lockedValue = args.locked;

	console.log("QueryRow.constructor    END");
},
postCreate : function(args) {
	console.log("QueryRow.postCreate    plugins.workflow.QueryRow.postCreate(args)");
	//this.formInputs = this.parentWidget.formInputs;

	this.startup();
},
startup : function () {
	console.log("QueryRow.startup    plugins.workflow.QueryRow.startup()");	
	this.actionNode.innerHTML = this.action;
	this.fieldNode.innerHTML = this.field;	
	this.operatorNode.innerHTML = this.operator;	
	this.valueNode.innerHTML = this.value;	
},
setValues : function (values) {
	for ( var key in values ) {
		var nodeName = values[key] + "Node";
		

		this[key]	=	values[key];
		this[nodeName].innerHTML = values[key];	
		
	}
},
deleteSelf : function () {
	console.log("QueryRow.deleteSelf    this:");
	console.dir({this:this});
	
	if ( this.parentWidget && this.parentWidget.deleteQueryRow ) {
		this.parentWidget.deleteQueryRow(this.domNode.parentNode);
	}
}

}); //	end declare

});	//	end define

