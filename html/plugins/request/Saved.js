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
templateString: dojo.cache("plugins", "request/templates/saved.html"),

// cssFiles : ArrayRef
//		Array of CSS files to be loaded for all widgets in template
// 		OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/request/css/saved.css"),
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
	ordinal 	: 	"integer",
	action 		: 	"word",
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
	console.log("Saved.constructor    args: ");
	console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);
},
postCreate : function() {
	// LOAD CSS
	console.log("Saved.postCreate    DOING this.loadCSS()");
	this.loadCSS();		

	console.log("Saved.postCreate    DOING this.startup()");
	this.startup();
},
startup : function () {
	console.group("Saved-" + this.id + "    startup");

	// ATTACH PANE
	this.attachPane();

	// SET SELECTS
	this.setSavedSelect();

	// SET LISTENERS
	this.setListeners();

	// INITIALISE DRAG SOURCE
	this.initialiseDragSource();

	// LOAD FIRST QUERY
	if ( this.savedSelect.value ) {
		this.updateQuery();
	}
	
	console.groupEnd("Saved-" + this.id + "    startup");
},
setListeners : function () {
	console.log("Saved.setListeners");

	on(this.savedSelect, "change", dojo.hitch(this, "updateQuery"));
},
updateQuery : function () {
	var query 	=	this.savedSelect.value;
	console.log("Saved.updateQuery    query: " + query);

	var queries = Agua.getQueries();
	console.log("Saved.updateQuery    queries: ");
	console.dir({queries:queries});
	
	queries = this.filterByKeyValues(queries, ["query"], [query]);
	console.log("Saved.updateQuery    FILTERED queries: ");
	console.dir({queries:queries});

	queries	=	this.sortHasharrayByKeys(queries, ["ordinal"]);
	console.log("Saved.updateQuery    SORTED queries: ");
	console.dir({queries:queries});

	// HACK TO DISPLAY 'action' FIELD WITH FULL SIZE
	var data = dojo.clone(queries);
	
	this.clearDragSource();
	
	this.loadDragItems(data);
},
_onKey : function(key, callback, event){
	//console.log("Saved._onKey    key: " + key);
	//console.log("Saved._onKey    callback: " + callback);
	
	var eventKey = event.keyCode;			
	//console.log("Saved._onKey    eventKey: " + eventKey);
	if ( eventKey == key ) {
		this[callback]();
	}
},
addFilter : function () {
	console.log("Saved.addFilter   DOING this.getFormInputs()");
	var inputs = this.getFormInputs(this);
	console.log("Saved.addFilter   inputs: " + inputs);
	console.dir({inputs:inputs});
	
	this.addSavedRow(inputs);
},
setSavedSelect : function () {
	var queries = this.getQueryNames();
	console.log("Saved.setSelects    queries:");
	console.dir({queries:queries});
	
	this.setSelect(this.savedSelect, queries);
},
getQueryNames : function () {
	var queries = Agua.getQueries();
	
	queries = this.hashArrayKeyToArray(queries, "query");
	
	return this.uniqueValues(queries);
},
toggleSaved : function () {
	this.toggle(this.togglePoint);
},
getItemArray : function () {
	//console.log("Saved.getItemArray    this.dragSource: " + this.dragSource);
	//console.dir({this_dragSource:this.dragSource});

	var childNodes	=	this.dragSource.getAllNodes();
	var itemArray	=	[];
	for ( var i = 0; i < childNodes.length; i++ ) {
		var widget = dijit.getEnclosingWidget(childNodes[i].firstChild);
	
		var hash = {};	
		hash.ordinal = parseInt(i + 1);
		for ( key in this.formInputs ) {
			hash[key]	=	widget[key];
		}
		itemArray.push(hash);
	}
	
	return itemArray;
},
getFormInputs : function (widget) {
	console.log("Saved.getFormInputs    widget: " + widget);
	//console.dir(widget);
	
	var inputs = new Object;	
	for ( var name in this.formInputs )
	{
		console.log("Saved.getFormInputs    name: " + name);
		
		var value = this.getWidgetValue(widget[name]);			
		console.log("Saved.getFormInputs    " + name + ": " + value);
		inputs[name] = value;
	}
	
	return inputs;
}


}); //	end declare

});	//	end define


