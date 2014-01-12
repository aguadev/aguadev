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

return declare("plugins.request.Query",
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
templateString: dojo.cache("plugins", "request/templates/query.html"),

// cssFiles : ArrayRef
//		Array of CSS files to be loaded for all widgets in template
// 		OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/request/css/query.css"),
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
	ordinal 	: 	"word",
	action 		: 	"word",
	field		:	"phrase",
	operator	:	"word",
	value		:	"phrase"
},

// fields : ArrayRef
//		Array of field options
fields : null,

// fieldOperators : HashRef
//		Hash of fields against operators
fieldOperators : null,

// fieldTypes : HashRef
//		Hash of fields against input types
fieldTypes : null,

// actions : ArrayRef
//		Array of action options
actions : [
	"AND",
	"OR"
],

// dragSource : DndSource Widget
//		The source container for DnD items
dragSource : null,

// filters : ArrayRef
//		Array of filter hashes
filters : null,

// core : HashRef
//		Hash of core classes
core : {},

/////}}}}}

constructor : function(args) {
	console.log("Query.constructor    args: ");
	console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);
},
postCreate : function() {
	// LOAD CSS
	console.log("Query.postCreate    DOING this.loadCSS()");
	this.loadCSS();		

	console.log("Query.postCreate    DOING this.startup()");
	this.startup();
},
startup : function () {
	console.group("Query-" + this.id + "    startup");

	// ATTACH PANE
	this.attachPane();

	// SET SELECTS
	this.setSelects();

	// SET LISTENERS
	this.setListeners();

	// INITIALISE DRAG SOURCE
	this.initialiseDragSource();

	console.groupEnd("Query-" + this.id + "    startup");
},
setListeners : function () {
	console.log("Search.setListeners");
	
	// SET VALUE LISTENER
	var returnKey = 13;
	this.setOnkeyListener(this.value, returnKey, "addFilter");

	// SET OPERATOR LISTENER
	on(this.field, "change", dojo.hitch(this, "_setOperators"));
	on(this.field, "change", dojo.hitch(this, "_setInputType"));

	// SUBMIT SAVE
	on(this.saveButton, "click", dojo.hitch(this, "saveSearch"));
},
_setInputType : function () {
	console.log("Query._setInputType    this.operator.value: " + this.field.value);
	
	var fieldTypes	=	this.fieldTypes[this.field.value];
	console.log("Query._setInputType    fieldTypes: " + JSON.stringify(this.fieldTypes));
	
	//this.setSelect(this.operator, fieldTypes);	
	var fieldType	=	this.fieldTypes[this.field.value];
	console.log("Query._setInputType    fieldType: " + fieldType);
	console.log("Query._setInputType    this.value: ");
	console.dir({this_value:this.value});

	domAttr.set(this.value, "type", fieldType);
},
_setOperators : function () {
	console.log("Query._setOperators    this.field.value: " + this.field.value);
	
	var operators	=	this.fieldOperators[this.field.value];
	console.log("Query._setOperators    operators: " + JSON.stringify(operators));
	
	this.setSelect(this.operator, operators);
},
addFilter : function () {
	console.log("Query.addFilter   ");

	// GET FILTER
	var filter = this.getFormInputs(this);
	console.log("Query.addFilter   filter: " + filter);
	console.dir({filter:filter});
	console.log("Query.addFilter   filter.value: " + filter.value);

	// QUIT IF value IS EMPTY
	if ( ! filter.value || filter.value === "" ) {
		console.log("Query.addFilter   filter.value is invalid");
		domClass.add(this.value, "invalid");
		this.setInvalidValue();
		return;
	}
	else {
		domClass.remove(this.value, "invalid");
	}
	
	// ADD TERM TO QUERY
	this.addQueryRow(filter);
	
	// UPDATE GRID
	this.core.grid.updateGrid(this.filters);
},
setSelects : function () {
	console.log("Query.setSelects");
	this.setSelect(this.action, this.actions);
	this.setSelect(this.field, this.fields);

	this.setSelect(this.operator, this.fieldOperators[this.field.value]);
},
toggleQuery : function () {
	//console.log("Query.toggleQuery");
	this.toggle(this.togglePoint);
},
addQueryRow : function (inputs) {
	console.log("Query.addQueryRow    this: " + this);
	console.dir({this:this});

	console.log("Query.getFormInputs    inputs: " + inputs);
	console.dir(inputs);

	var itemArray 	=	this.getItemArray();
	itemArray.push(inputs);	

	// SET FILTERS
	this.filters = itemArray;
	
	this.clearDragSource();
	
	this.loadDragItems(itemArray);
},
deleteQueryRow : function (node) {
	var item = this.dragSource.getItem(node.id);
	console.log("Query.deleteQueryRow    DELETING node.id: " + node.id);

	this.dragSource.delItem(item);
	dojo.destroy(node);

	var itemArray 	=	this.getItemArray();
	console.log("Query.deleteQueryRow    itemArray: " + JSON.stringify(itemArray));

	// SET FILTERS
	this.filters = itemArray;

	this.clearDragSource();
	
	this.loadDragItems(itemArray);
	
	// UPDATE GRID
	this.core.grid.updateGrid(this.filters);

	return itemArray;
},
getItemArray : function () {
	console.log("Query.getItemArray    this.dragSource: " + this.dragSource);
	console.dir({this_dragSource:this.dragSource});

	var childNodes	=	this.dragSource.getAllNodes();
	console.log("Query.getItemArray    childNodes: " + childNodes);
	console.dir(childNodes);

	console.log("DndSource.loadDragItems     childNodes.length: " + childNodes.length);
	var itemArray	=	[];
	for ( var i = 0; i < childNodes.length; i++ ) {
		var widget = dijit.getEnclosingWidget(childNodes[i].firstChild);	
		var hash = {};	
		hash.ordinal = parseInt(i + 1);
		for ( key in this.formInputs ) {
			console.log("Query.getItemArray    widget[" + key + "]: " + widget[key]);
			hash[key]	=	widget[key];
		}
		itemArray.push(hash);
	}
	
	return itemArray;
},
getFormInputs : function (widget) {
	console.log("Query.getFormInputs    widget: " + widget);
	//console.dir(widget);
	
	var inputs = new Object;	
	for ( var name in this.formInputs )
	{
		console.log("Query.getFormInputs    name: " + name);

		
		
		var value = this.getWidgetValue(widget[name]);			
		console.log("Query.getFormInputs    " + name + ": " + value);
		inputs[name] = value;
	}
	
	return inputs;
},
saveSearch : function () {
	console.log("Query.saveSearch");
	
	
	
}



}); //	end declare

});	//	end define

