dojo.provide("plugins.form.DndSource");

// PROVIDES FORM INPUT AND ROW EDITING WITH VALIDATION
// INHERITING CLASSES MUST IMPLEMENT saveInputs AND deleteItem METHODS
// THE dnd DRAG SOURCE MUST BE this.dragSourceWidget IF PRESENT

// EXTERNAL MODULES
//dojo.require("dojo.dnd.Source");

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.dnd.Source");
dojo.require("plugins.dnd.Avatar");

dojo.declare("plugins.form.DndSource",
	[ ],
{
// NB: INHERITING CLASS MUST PROVIDE THE FOLLOWING 

// ROW CLASS
rowClass : null,

// AVATAR DISPLAYED DATA ITEMS
avatarItems : [],

// FORM INPUTS (DATA ITEMS TO BE ADDED TO ROWS)
formInputs : {},

// LOADED DND WIDGETS
childWidgets : [],

////}}}
constructor : function(args) {
	//console.log("DndSource.constructor     plugins.form.DndSource.constructor");	
},
postCreate : function() {
	//console.log("DndSource.postCreate    plugins.form.DndSource.postCreate()");
	this.startup();
},
startup : function () {
	//console.group("DndSource-" + this.id + "    startup");
	
	//console.log("DndSource.startup    DOING this.initialiseDragSource()");
	this.initialiseDragSource();

	//console.log("DndSource.startup    DOING this.setDragSourceCreator()");
	this.setDragSourceCreator();

	//console.groupEnd("DndSource-" + this.id + "    startup");	
},
initialiseDragSource : function (node) {
	//console.group("DndSource-" + this.id + "    initialiseDragSource");
	//console.log("DndSource.initialiseDragSource    this.dragSourceNode: " + this.dragSourceNode);
	
	if ( node == null )
		node = this.dragSourceNode; 

	this.dragSource = new plugins.dnd.Source(
		node,
		{
			copyOnly: true,
			selfAccept: false,
			accept : [ "none" ]
		}
	);
	//console.log("DndSource.initialiseDragSource    AFTER this.dragSource = new dojo.dnd.Source");
	//console.log("DndSource.initialiseDragSource    this.dragSource");
	//console.dir({this_dragSource:this.dragSource});
	
	//console.groupEnd("DndSource-" + this.id + "    initialiseDragSource");
},
setDragSourceCreator : function () {
// AVATAR CREATOR
	//console.group("DndSource-" + this.id + "    setDragSourceCreator");

	var thisObject = this;
	this.dragSource.creator = dojo.hitch(this.dragSource, function (item, hint) {
		//console.log("DndSource.setDragSourceCreator     this: " + this);
		//console.log("DndSource.setDragSourceCreator     this.dragSourceWidget.creator    item: " + dojo.toJson(item, true));
		//console.log("DndSource.setDragSourceCreator     this.dragSourceWidget.creator    thisObject.formInputs: ");
		//console.dir({this_formInputs:thisObject.formInputs});
		//console.log("DndSource.setDragSourceCreator     this.dragSourceWidget.creator    thisObject.avatarItems: ");
		//console.dir({this_avatarItems:thisObject.avatarItems});

		var data = item.data;

		var node = dojo.doc.createElement("div");
		node.id = dojo.dnd.getUniqueId();
		node.className = "dojoDndItem";
		node.data = new Object;
		for ( name in thisObject.formInputs ) {
			node.data[name] = item[name];
		}
		
		// SET FANCY FORMAT IN NODE INNERHTML
		var avatarHtml = "<table>";
		//var title = true;
		for ( var i = 0; i < thisObject.avatarItems.length; i++ )
		{
		//dojo.forEach(thisObject.avatarItems, function (name) {
			var name = thisObject.avatarItems[i];
			//console.log("DndSource.setDragSourceCreator     this.dragSourceWidget.creator    name: " + name);
			if ( i == 0 )
			{
				avatarHtml += "<tr><td class='dojoDndAvatarHeader'><strong style='color: darkred'>";
				avatarHtml += data[name] + "</strong></td></tr>";
			}
			else
			{
				avatarHtml += "<tr><td>";
				avatarHtml += data[name] + "</td></tr>";
			}
		}
		//});
		avatarHtml += "</table>";
		//console.log("DndSource.setDragSourceCreator     this.dragSourceWidget.creator    avatarHtml: " + avatarHtml);
		node.innerHTML = avatarHtml;

		return {node: node, data: item, type: ["draggableItem"]};
	});	

	//console.groupEnd("DndSource-" + this.id + "    setDragSourceCreator");
},
// DATA ITEMS FOR ROWS - INHERITING CLASS MUST OVERRIDE
getItemArray : function () {
	// GET A LIST OF DATA ITEMS - ONE FOR EACH ROW
},
clearDragSource : function () {
// DELETE EXISTING TABLE CONTENT

	//console.log("DndSource.clearDragSource     DndSource.clearDragSource()");
	//console.log("DndSource.clearDragSource     this.dragSource: " + this.dragSource);
	var nodes = this.dragSource.getAllNodes();
	//console.log("DndSource.clearDragSource     TO DELETE nodes: " + nodes);
	if ( nodes != null ) {
		//console.log("DndSource.clearDragSource     TO DELETE nodes.length: " + nodes.length);
		for ( var i = 0; i < nodes.length; i++ )
		{
			var node = nodes[i];
			//console.log("DndSource.clearDragSource     DELETING node.id: " + node.id);
			var item = this.dragSource.getItem(node.id);
			//console.log("DndSource.clearDragSource     DELETING node.id: " + node.id);
			this.dragSource.delItem(item);
			dojo.destroy(node);
		}
	}

	if ( this.childWidgets.length != 0 )
	for ( var i = 0; i < this.childWidgets.length; i++ ) {
		dojo.destroy(this.childWidgets[i]);
	}

	this.childWidgets = [];
},
// NB: INHERITING CLASS MUST HAVE this.dragSource
setDragSource : function () {
	//console.log("DndSource.setDragSource     plugins.form.DndSource.setDragSource()");

	// GENERATE DND GROUP
	if ( this.dragSource == null ) {
		this.initialiseDragSource();
		this.setDragSourceCreator();
	}

	// DELETE EXISTING CONTENT
	this.clearDragSource();
	
	var itemArray = this.getItemArray();
	//console.log("DndSource.setDragSource     itemArray.length: " + dojo.toJson(itemArray.length));
	//console.log("DndSource.setDragSource     itemArray: ");
	//console.dir({itemArray:itemArray});
	
	this.loadDragItems(itemArray);
},
loadDragItems : function (itemArray) {
	//console.log("DndSource.loadDragItems     itemArray: ");
	//console.dir({itemArray:itemArray});
	//console.log("DndSource.loadDragItems     itemArray.length: " + itemArray.length);

	// SET FLAG TO ABSORB EXTRANEOUS ONCHANGE FIRE
	this.dragSourceOnchange = false;

	// CHECK itemArray IS NOT NULL OR EMPTY
	if ( itemArray == null || itemArray.length == 0 )	return;

	// GENERATE dataArray TO INSERT INTO DND GROUP TABLE
	var dataArray = new Array;
	for ( var j = 0; j < itemArray.length; j++ )
	{
		var data = itemArray[j];				
		dataArray.push( { data: data, type: ["draggableItem"] } );
	}
	//console.log("DndSource.loadDragItems     dataArray.length: " + dataArray.length);	

	//console.log("DndSource.loadDragItems     this.formInputs: ");
	//console.dir({this_formInputs: this.formInputs});

	
	// INSERT NODES
	//console.log("DndSource.loadDragItems     this.dragSource: ");
	//console.dir({this_dragSource: this.dragSource});
	this.dragSource.insertNodes(false, dataArray);
	
	// SET TABLE ROW STYLE IN dojDndItems
	var allNodes = this.dragSource.getAllNodes();
	//console.log("DndSource.loadDragItems     allNodes.length: " + allNodes.length);
	for ( var k = 0; k < allNodes.length; k++ ) {
		// SET NODE DATA
		var node = allNodes[k];
		node.data = dataArray[k].data;
		//console.log("DndSource.loadDragItems     dataArray[" + k + "].data: " + dojo.toJson( dataArray[k].data));
	
		// SET AVATAR TYPE
		if ( this.avatarType !== null ) {
			node.data.avatarType = this.avatarType;
		}
		// SET ITEM OBJECT
		var itemObject = new Object;
		for ( name in this.formInputs ) {
			//console.log("DndSource.loadDragItems     itemObject[" + name + "] = " + dataArray[k].data[name]);
			itemObject[name] = dataArray[k].data[name];
		}
		//console.log("DndSource.loadDragItems     itemObject: ");
		//console.dir({itemObject:itemObject});
		itemObject.parentWidget = this;

		// CREATE ROW
		var rowClass = this.rowClass;
		//console.log("DndSource.loadDragItems     rowClass: " + rowClass);
		
		//dojo.require("plugins.workflow.Apps.AppRow");
		dojo.require(rowClass);
		var module = dojo.getObject(rowClass);
		//console.log("DndSource.loadDragItems     module: ");
		//console.dir({module:module});
		
		var itemObjectRow = new module(itemObject);
		//console.log("DndSource.loadDragItems     itemObjectRow: ");
		//console.dir({itemObjectRow:itemObjectRow});

		//console.log("DndSource.loadDragItems     node: ");
		//console.dir({node:node});

		this.childWidgets.push(itemObjectRow);
		node.innerHTML = '';
		node.appendChild(itemObjectRow.domNode);
	
		// ADD CONTEXT MENU
		if ( this.contextMenu != null ) this.contextMenu.bind(node);
	}

}

}); // plugins.form.DndSource

