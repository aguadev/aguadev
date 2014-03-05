define([
	"dojo/_base/declare",
	"plugins/core/Common/Logger",
	"plugins/dnd/Source",
	"plugins/dnd/Avatar"
],

function (declare, commonLogger, Source, Avatar) {

/////}}}}}

return declare("plugins.form.DndSource",
	[commonLogger], {

// DEBUG : Boolean
//		Print debug output if true
DEBUG : false,

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
	this.logDebug(" plugins.form.DndSource.constructor");	
},
postCreate : function() {
	this.logDebug("plugins.form.DndSource.postCreate()");
	this.startup();
},
startup : function () {
	console.group("DndSource-" + this.id + "    startup");
	
	this.logDebug("DOING this.initialiseDragSource()");
	this.initialiseDragSource();

	this.logDebug("DOING this.setDragSourceCreator()");
	this.setDragSourceCreator();

	console.groupEnd("DndSource-" + this.id + "    startup");	
},
initialiseDragSource : function (node) {
	console.group("DndSource-" + this.id + "    initialiseDragSource");
	this.logDebug("this.dragSourceNode: " + this.dragSourceNode);
	
	if ( node == null )
		node = this.dragSourceNode; 

	this.dragSource = new Source(
		node,
		{
			copyOnly: true,
			selfAccept: false,
			accept : [ "none" ]
		}
	);
	this.logDebug("AFTER this.dragSource = new dojo.dnd.Source");
	this.logDebug("this.dragSource", this.dragSource);
	
	console.groupEnd("DndSource-" + this.id + "    initialiseDragSource");
},
setDragSourceCreator : function () {
// AVATAR CREATOR
	console.group("DndSource-" + this.id + "    setDragSourceCreator");

	var thisObject = this;
	this.dragSource.creator = dojo.hitch(this.dragSource, function (item, hint) {
		this.logDebug(" this: " + this);
		//this.logDebug(" this.dragSourceWidget.creator    item: " + dojo.toJson(item, true));
		this.logDebug(" this.dragSourceWidget.creator    thisObject.formInputs", thisObject.formInputs);
		this.logDebug(" this.dragSourceWidget.creator    thisObject.avatarItems", thisObject.avatarItems);
		
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
			this.logDebug(" this.dragSourceWidget.creator    name: " + name);
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
		this.logDebug(" this.dragSourceWidget.creator    avatarHtml: " + avatarHtml);
		node.innerHTML = avatarHtml;

		return {node: node, data: item, type: ["draggableItem"]};
	});	

	console.groupEnd("DndSource-" + this.id + "    setDragSourceCreator");
},
// DATA ITEMS FOR ROWS - INHERITING CLASS MUST OVERRIDE
getItemArray : function () {
	// GET A LIST OF DATA ITEMS - ONE FOR EACH ROW
},
clearDragSource : function () {
// DELETE EXISTING TABLE CONTENT

	this.logDebug(" DndSource.clearDragSource()");
	this.logDebug(" this.dragSource: " + this.dragSource);
	var nodes = this.dragSource.getAllNodes();
	this.logDebug(" TO DELETE nodes: " + nodes);
	if ( nodes != null ) {
		this.logDebug(" TO DELETE nodes.length: " + nodes.length);
		for ( var i = 0; i < nodes.length; i++ )
		{
			var node = nodes[i];
			this.logDebug(" DELETING node.id: " + node.id);
			var item = this.dragSource.getItem(node.id);
			this.logDebug(" DELETING node.id: " + node.id);
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
	this.logDebug(" plugins.form.DndSource.setDragSource()");

	// GENERATE DND GROUP
	if ( this.dragSource == null ) {
		this.initialiseDragSource();
		this.setDragSourceCreator();
	}

	// DELETE EXISTING CONTENT
	this.clearDragSource();
	
	var itemArray = this.getItemArray();
	this.logDebug(" itemArray.length: " + dojo.toJson(itemArray.length));
	this.logDebug(" itemArray", itemArray);
	
	this.loadDragItems(itemArray);
},
loadDragItems : function (itemArray) {
	this.logDebug(" itemArray", itemArray);
	this.logDebug(" itemArray.length: " + itemArray.length);

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
	this.logDebug(" dataArray.length: " + dataArray.length);	

	this.logDebug(" this.formInputs",  this.formInputs);

	
	// INSERT NODES
	this.logDebug(" this.dragSource",  this.dragSource);
	this.dragSource.insertNodes(false, dataArray);
		
	// SET TABLE ROW STYLE IN dojDndItems
	var allNodes = this.dragSource.getAllNodes();
	this.logDebug(" allNodes.length: " + allNodes.length);
	for ( var k = 0; k < allNodes.length; k++ ) {
		// SET NODE DATA
		var node = allNodes[k];
		node.data = dataArray[k].data;
		this.logDebug(" dataArray[" + k + "].data: " + dojo.toJson( dataArray[k].data));
	
		// SET AVATAR TYPE
		if ( this.avatarType !== null ) {
			node.data.avatarType = this.avatarType;
		}
		// SET ITEM OBJECT
		var itemObject = new Object;
		for ( name in this.formInputs ) {
			this.logDebug(" itemObject[" + name + "] = " + dataArray[k].data[name]);
			itemObject[name] = dataArray[k].data[name];
		}
		this.logDebug(" itemObject", itemObject);
		itemObject.parentWidget = this;

		// CREATE ROW
		var rowClass = this.rowClass;
		this.logDebug(" rowClass: " + rowClass);
		
		dojo.require(rowClass);
		
		
		var module = dojo.getObject(rowClass);
		this.logDebug(" module", module);

		var itemObjectRow = new module(itemObject);

		this.logDebug(" itemObjectRow", itemObjectRow);
		

		this.logDebug(" node", node);

		this.childWidgets.push(itemObjectRow);
		node.innerHTML = '';
		node.appendChild(itemObjectRow.domNode);
	
		// ADD CONTEXT MENU
		if ( this.contextMenu != null ) this.contextMenu.bind(node);
	}

}

}); //	end declare

});	//	end define


