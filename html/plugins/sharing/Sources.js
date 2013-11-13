dojo.provide("plugins.sharing.Sources");

// ALLOW THE USER TO ADD, REMOVE AND MODIFY SOURCES

// EXTERNAL MODULES
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.form.EditForm");

// HAS A
dojo.require("plugins.sharing.SourceRow");

dojo.declare("plugins.sharing.Sources",
	[ dijit._Widget, dijit._Templated, plugins.core.Common, plugins.form.EditForm ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/sources.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingSource STATE
addingSource : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ "plugins/sharing/css/sources.css" ],

// PARENT WIDGET
parentWidget : null,

// FORM INPUTS AND TYPES (word|phrase)
formInputs : {
	name		: "phrase",
	description	: "phrase",
	location	: "word"
},

defaultInputs : {
	name : "Name",
	description: "Description",
	location: "Location"
},
	
requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
	name : 1,
	location: 1
},

invalidInputs : {
// INVALID INPUTS (e.g., DEFAULT INPUTS)
	name : "Name",
	description: "Description",
	location: "Location"
},

// DATA ITEMS FOR ROW
dataFields : ["name", "description", "location"],

// AVATAR DISPLAYED DATA ITEMS
avatarItems : [ "name", "description", "location" ],

// ROW CLASS FOR DRAG SOURCE
rowClass : "plugins.sharing.SourceRow",

////}}}

constructor : function(args) {
	//////console.log("Sources.constructor     plugins.sharing.Sources.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.sources = args.parentWidget.sources;

	// LOAD CSS
	this.loadCSS();		
},

postCreate : function() {
	//////console.log("Controller.postCreate    plugins.sharing.Controller.postCreate()");

	this.startup();
},

startup : function () {
	//////console.log("Sources.startup    plugins.sharing.GroupSources.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD ADMIN TAB TO TAB CONTAINER		
	this.attachPoint.addChild(this.sourcesTab);
	this.attachPoint.selectChild(this.sourcesTab);

	// SET DRAG SOURCE - LIST OF SOURCES
	this.setDragSource();

	// SET NEW SOURCE FORM
	this.setForm();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateSources");

	// SET TRASH
	this.setTrash(this.dataFields);	
},

updateSources : function (args) {
// RELOAD RELEVANT DISPLAYS
	//console.log("Sources.updateSources    sharing.Sources.updateSources(args)");
	//console.log("Sources.updateSources    args:");
	//console.dir(args);

	// REDO PARAMETER TABLE
	if ( args != null && args.originator == this )
	{
//		if ( args.reload == null )	return;
		if ( args.reload == false )	return;
	}

	//console.log("Sources.updateSources    Calling setDragSource()");
	this.setDragSource();
},

setForm : function () {
	//////console.log("Sources.setForm    plugins.sharing.GroupSources.setForm()");

	// SET ADD SOURCE ONCLICK
	dojo.connect(this.addSourceButton, "onClick", dojo.hitch(this, "saveInputs", null, null));
	
	// SET ONCLICK TO CANCEL INVALID TEXT
	this.setClearValues();
	
	// CHAIN TOGETHER INPUTS ON 'RETURN' KEYPRESS
	this.chainInputs(["name", "description", "location", "addSourceButton"]);
},

getItemArray : function () {
	var itemArray = Agua.getSources();
	itemArray = this.sortHasharray(itemArray, 'name');	

	console.log("Sources.getItemArray    Returning itemArray: ");
	console.dir({itemArray:itemArray});
	
	return itemArray;
},

deleteItem : function (itemObject) {
	//console.log("Sources.deleteItem    plugins.sharing.Sources.deleteItem(itemObject)");
	//console.log("Sources.deleteItem    itemObject: " + itemObject);

	// CLEAN UP WHITESPACE
	itemObject.name = itemObject.name.replace(/\s+$/,'');
	itemObject.name = itemObject.name.replace(/^\s+/,'');

	// REMOVING SOURCE FROM Agua.sources
	var success = Agua.removeSource(itemObject)
	//console.log("Sources.deleteItem    Agua.removeSource(itemObject) success: " + success);
	
	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateSources");

}, // Sources.deleteItem


addItem : function (sourceObject, reload) {
	//////console.log("Sources.addItem    plugins.sharing.Sources.addItem(source)");
	//////console.log("Sources.addItem    source: " + source);	
	if ( this.savingSource == true )	return;
	this.savingSource = true;

	Agua.addSource(sourceObject);

	this.savingSource = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateSources", reload);

} // Sources.addItem

}); // plugins.sharing.Sources


//setDragSource : function () {
//	console.log("Sources.setDragSource     plugins.sharing.GroupSources.setDragSource()");
//
//	var dataArray = new Array;
//	var sourceArray = Agua.getSources();
//
//	sourceArray = this.sortHasharray(sourceArray, 'name');
//
//	// CHECK sourceArray IS NOT NULL OR EMPTY
//	if ( sourceArray == null || sourceArray.length == 0 )
//	{
//		console.log("Sources.setDragSource     sourceArray is null or empty. Returning.");
//		return;
//	}
//
//	// GENERATE dataArray TO INSERT INTO DND SOURCE TABLE
//	for ( var j = 0; j < sourceArray.length; j++ )
//	{
//		var data = sourceArray[j];				
//		data.toString = function () { return this.name; }
//		dataArray.push( { data: data, type: ["draggableItem"] } );
//	}
//
//	// GENERATE DND SOURCE
//	var dragSource = new dojo.dnd.Source(
//		this.dragSourceNode,
//		{
//			copyOnly: true,
//			selfAccept: false,
//			accept : [ "none" ]
//		}
//	);
//	// SET THIS dragSourceWidget
//	this.dragSourceWidget = dragSource;
//
//	// INSERT NODES
//	dragSource.insertNodes(false, dataArray);
//
//	// SET TABLE ROW STYLE IN dojDndItems
//	var allNodes = dragSource.getAllNodes();
//	console.log("Sources.setDragSource     After insertNodes. allNodes.length: " + allNodes.length);
//	for ( var k = 0; k < allNodes.length; k++ )
//	{
//		// ADD CLASS FROM type TO NODE
//		var node = allNodes[k];
//
//		console.log("Sources.setDragSource     Setting node " + k + " data: " + dojo.toJson(dataArray[k]));
//
//		// SET NODE name AND description
//		node.name = dataArray[k].data.name;
//		node.description = dataArray[k].data.description;
//		node.location = dataArray[k].data.location;
//		if ( node.location == null )
//		{
//			node.location = '';
//		}
//
//		var sourceRow = new plugins.sharing.SourceRow({
//			name : node.name,
//			description : node.description,
//			location : node.location,
//			parentWidget : this
//		});
//		//console.log("Sources.setDragSource     sourceRow: " + sourceRow);
//		//console.log("Sources.setDragSource     sourceRow.description: " + sourceRow.description);
//
//		node.innerHTML = '';
//		node.appendChild(sourceRow.domNode);
//
//		//console.log("Sources.setDragSource     node.name: " + node.name);
//	}
//
//	dragSource.creator = function (item, hint)
//	{
//		console.log("Sources.setDragSource dragSource.creator         item: " + dojo.toJson(item));
//		//console.log("Sources.setDragSource dragSource.creator         item: " + item);
//		//console.log("Sources.setDragSource dragSource.creator         hint: " + hint);
//
//		var node = dojo.doc.createElement("div");
//		node.name = item.name;
//		node.description = item.description;
//		node.location = item.location;
//		node.id = dojo.dnd.getUniqueId();
//		node.className = "dojoDndItem";
//
//		//console.log("Sources.setDragSource dragSource.creator         node.name: " + node.name);
//		//console.log("Sources.setDragSource dragSource.creator         node.description: " + node.description);
//
//		// SET FANCY FORMAT IN NODE INNERHTML
//		node.innerHTML = "<table> <tr><td><strong style='color: darkred'>" + item.name + "</strong></td></tr><tr><td> " + item.description + "</td></tr></table>";
//
//		return {node: node, data: item, type: ["text"]};
//	};
//},

