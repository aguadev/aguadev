define([
	"dojo/_base/declare",
	"plugins/core/Common",
	"dojo/dnd/Source"
],

function (
	declare,
	Common,
	Source
) {

/////}}}}}

return declare("plugins/dnd/Source",
	[ Source, Common ], {

		cssFiles : [
		dojo.moduleUrl("plugins", "dnd/css/dnd.css")
	],
	
	constructor : function(){
		console.log("dnd.Source.constructor    Agua:");
		console.dir({Agua:Agua});
		
		console.log("dnd.Source.constructor    DOING Agua.loadCSSFile(this.cssFiles[0])");
		Agua.loadCSSFile(this.cssFiles[0]);
	},
	
	//onMouseUp: function(e){
	//	// summary:
	//	//		event processor for onmouseup
	//	// e: Event
	//	//		mouse event
	//
	//	console.log("plugins.dnd.Source.onMouseUp -----------------------------------------------------");
	//
	//	//if(this.mouseDown){
	//	//	this.mouseDown = false;
	//	//	Source.superclass.onMouseUp.call(this, e);
	//	//}
	//},
	//onDndCancel: function(){
	//	// summary:
	//	//		topic event processor for /dnd/cancel, called to cancel the DnD operation
	//
	//	console.log("plugins.dnd.Source.onDndCancel -----------------------------------------------------");
	//
	//
	//	//if(this.targetAnchor){
	//	//	this._unmarkTargetAnchor();
	//	//	this.targetAnchor = null;
	//	//}
	//	//this.before = true;
	//	//this.isDragging = false;
	//	//this.mouseDown = false;
	//	//this._changeState("Source", "");
	//	//this._changeState("Target", "");
	//},
	//onDrop: function(){
	//	// summary:
	//	//		topic event processor for /dnd/cancel, called to cancel the DnD operation
	//
	//	console.log("plugins.dnd.Source.onDrop -----------------------------------------------------");
	//}
	
	//// object attributes (for markup)
	//isSource: true,
	//horizontal: false,
	//copyOnly: false,
	//selfCopy: false,
	//selfAccept: true,
	//skipForm: false,
	//withHandles: false,
	//autoSync: false,
	//delay: 0, // pixels
	//accept: ["text"],
	//generateText: true,
	//
	//creator : function (item, hint) {
	//	console.log("dnd.Source.setDragSourceCreator     this.dragSourceWidget.creator    item: " + dojo.toJson(item, true));
	//
	//	var data = item.data;
	//	var node = dojo.doc.createElement("div");
	//	node.id = dojo.dnd.getUniqueId();
	//	node.className = "dojoDndItem";
	//	node.data = new Object;
	//	for ( name in thisObject.formInputs ) {
	//		node.data[name] = item[name];
	//	}
	//
	//	// SET FANCY FORMAT IN NODE INNERHTML
	//	var avatarHtml = "<table>";
	//	var title = true;
	//	for ( var i = 0; i < thisObject.avatarItems.length; i++ ) {
	//		var name = thisObject.avatarItems[i];
	//		////console.log("DndSource.setDragSourceCreator     this.dragSourceWidget.creator    name: " + name);
	//		if ( title == true ) {
	//			avatarHtml += "<tr><td><strong style='color: darkred'>";
	//			avatarHtml += data[name] + "</strong></td></tr>";
	//		}
	//		else {
	//			avatarHtml += "<tr><td>";
	//			avatarHtml += data[name] + "</td></tr>";
	//		}
	//	}
	//
	//	avatarHtml += "</table>";
	//	console.log("dnd.Source.setDragSourceCreator     this.dragSourceWidget.creator    avatarHtml: " + avatarHtml);
	//	node.innerHTML = avatarHtml;
	//
	//	return {node: node, data: item, type: ["draggableItem"]};
	//}
	//,
	//
	//startup: function(){
	//	// summary:
	//	//		collects valid child items and populate the map
	//	
	//	// set up the real parent node
	//	if(!this.parent){
	//		// use the standard algorithm, if not assigned
	//		this.parent = this.node;
	//		
	//		console.log("plugins.dnd.Source.startup    plugins.dnd.Source.startup()");
	//		console.log("plugins.dnd.Source.startup    console.dir(this.parent):");
	//		console.dir({parent: this.parent});
	//
	//		if ( this.parent.tagName != null ) {
	//			if(this.parent.tagName.toLowerCase() == "table"){
	//				var c = this.parent.getElementsByTagName("tbody");
	//				if(c && c.length){ this.parent = c[0]; }
	//			}
	//		}
	//	}
	//	this.defaultCreator = dojo.dnd._defaultCreator(this.parent);
	//
	//	// process specially marked children
	//	this.sync();
	//
	//	console.log("plugins.dnd.Source.startup    END");
	//}
	
});

});
