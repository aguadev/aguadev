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
	"plugins/request/QueryRow",
	"plugins/form/DndSource",
	"plugins/form/Inputs",
	"plugins/core/Common/Util",
	"dojo/store/Memory",
	"dojo/domReady!",

	"dijit/form/Select",
	"dijit/layout/BorderContainer",
	"dijit/form/Button",
	"dijit/layout/ContentPane",
	"plugins/form/SelectList",
	"plugins/form/ValidationTextBox"
],

function (
	declare,
	arrayUtil,
	JSON,
	on,
	lang,
	domAttr,
	domClass,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	QueryRow,
	DndSource,
	Inputs,
	CommonUtil,
	Memory
) {

/////}}}}}

return declare("plugins.request.Saved",
	[
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	DndSource,
	Inputs,
	CommonUtil
], {

// templateString : String
//		The template of this widget. 
templateString: dojo.cache("plugins", "request/templates/simplesearch.html"),

// cssFiles : ArrayRef
//		Array of CSS files to be loaded for all widgets in template
// 		OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/request/css/simplesearch.css"),
	require.toUrl("dojo/tests/dnd/dndDefault.css")
	//,
	//require.toUrl("dojo/resources/dojo.css"),
	//require.toUrl("plugins/infusion/css/infusion.css"),
	//require.toUrl("dojox/layout/resources/ExpandoPane.css"),
	//require.toUrl("plugins/infusion/images/elusive/css/elusive-webfont.css")
],

// parentWidget : Widget
//			Parent of this widget
parentWidget : null,

// DATA FIELDS TO BE RETRIEVED FROM DELETED ITEM
dataFields : [ "name", "appname", "paramtype" ],

rowClass : "plugins.request.QueryRow",

avatarItems: [ "name", "description"],

avatarType : "parameters",

// LOADED DND WIDGETS
// attachPoint : DOM node or widget
// 		Attach this.mainTab using appendChild (DOM node) or addChild (Tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

// formInputs : HashKey
//		Hash of input names
formInputs : {
	action 	: 	"word",
	field		:	"phrase",
	operator	:	"word",
	value		:	"phrase"
},

// dragSource : DndSource Widget
//		The source container for DnD items
dragSource : null,

// core : HashRef
//		Hash of core classes
core : {},

/////}}}}}

constructor : function(args) {
	console.log("SimpleSearch.constructor    args: ");
	console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);
},
postCreate : function() {
	// LOAD CSS
	console.log("SimpleSearch.postCreate    DOING this.loadCSS()");
	this.loadCSS();		

	console.log("SimpleSearch.postCreate    DOING this.startup()");
	this.startup();
},
startup : function () {
	console.group("SimpleSearch-" + this.id + "    startup");

	// ATTACH PANE
	this.attachPane();

	// SET LISTENERS
	this.setListeners();

	this.setFocus();
	console.groupEnd("SimpleSearch-" + this.id + "    startup");
},
setListeners : function () {
	console.log("SimpleSearch.setListeners    this.saveButton: ");
	console.dir({this_saveButton:this.saveButton});

	// RETURN SEARCH
	var returnKey = 13;
	this.setOnkeyListener(this.searchInput, returnKey, dojo.hitch(this, "search"));

	// SUBMIT SAVE
	on(this.saveButton, "click", dojo.hitch(this, "saveSearch"));
},
setFocus : function () {
	this.searchInput.focus();
},
search : function () {
	console.log("SimpleSearch.search    DOING this.getFilters()");
	var filters = this.getFilters();
	console.log("SimpleSearch.search    filters: " + JSON.stringify(filters));
	this.core.grid.updateGrid(filters)
},
getFilters : function () {
	var value 	=	this.searchInput.value;
	console.log("SimpleSearch.getFilters    value: " + value);
	value	=	value.replace(/\s+$/g, '');
	value	=	value.replace(/^\s+/g, '');
	
	var values = value.split(" ");
	console.log("SimpleSearch.getFilters    values: " + JSON.stringify(values));
	
	var filters = [];
	for ( var i = 0; i < values.length; i++ ) {
		var filter = {
			action 	: 	"OR",
			field 	: 	"ALL",
			operator:	"contains",
			value 	:	values[i],
			query	:	value
		};
		filters.push(filter);
	}
	console.log("SimpleSearch.getFilters    filters: " + JSON.stringify(filters));
	
	return filters;
},
saveSearch : function () {
	console.log("SimpleSearch.saveSearch");
	var filters = this.getFilters();
	console.log("SimpleSearch.saveSearch    filters.length: " + filters.length);
	console.dir({filters:filters});
	
	Agua.addQuery(filters);
},
toggleDisplay : function () {
	console.log("SimpleSearch.toggleSaved");
	this.toggle(this.togglePoint);
}

}); //	end declare

});	//	end define




