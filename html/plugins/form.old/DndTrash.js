dojo.provide("plugins.form.DndTrash");

// PROVIDES FORM INPUT AND ROW EDITING WITH VALIDATION
// INHERITING CLASSES MUST IMPLEMENT saveInputs AND deleteItem METHODS
// THE dnd DRAG SOURCE MUST BE this.dragSourceWidget IF PRESENT

// EXTERNAL MODULES
dojo.require("dojo.dnd.Source");

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.form.DndSource");

dojo.declare("plugins.form.DndTrash",
	[ ],
{

// DATA FIELDS TO BE RETRIEVED FROM DELETED ITEM
dataFields : ["name"],

////}}}

constructor : function(args) {
	console.log("Dnd.constructor     plugins.form.DndTrash.constructor");			
},

postCreate : function() {
	console.log("Dnd.postCreate    ");
	this.startup();
},

startup : function () {
	console.log("Dnd.startup    plugins.form.DndTrash.startup()");

	//this.setSubscriptions();
	this.setTrash(this.dataFields);	
},

//setSubscriptions : function () {
//	dojo.subscribe("/dnd/source/over", null,  function(arg) {
//		console.log("/dnd/source/over");
//	});
//
//	dojo.subscribe("/dnd/start",  null,  function(arg) {
//		console.log("/dnd/start");
//	});
//	
//	dojo.subscribe("/dnd/drop",   null,  function(arg) {
//		console.log("/dnd/drop");
//	});
//	
//	dojo.subscribe("/dnd/cancel", null,  function(arg) {
//		console.log("/dnd/cancel");
//	});
//},

setTrash : function (dataFields) {
//	DELETE NODE IF DROPPED INTO TRASH. ACTUAL REMOVAL FROM THE
//	DATA IS ACCOMPLISHED IN THE onDndDrop LISTENER OF THE SOURCE
	//console.log("Dnd.setTrash     plugins.form.DndTrash.setTrash(dataFields)");
	//console.log("Dnd.setTrash     dataFields: " + dojo.toJson(dataFields));

	this.trash = new dojo.dnd.Source(
		this.trashContainer,
		{
			accept : [ "draggableItem" ]
		}
	);
	////console.log("Dnd.setTrash     trash: " + trash);

	// REMOVE DUPLICATE NODES
	var thisObject = this;
	dojo.connect(this.trash, "onDndDrop", dojo.hitch(this, function(source, nodes, copy, target){
		//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    checking if target == this.");
		//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    target: " + target);
		//console.dir({target:target});
		//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    nodes.length: " + nodes.length);
		//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    nodes[0].name: " + nodes[0].name);

		// NODE DROPPED ON SELF --> DELETE THE NODE
		if ( target == thisObject.trash )
		{
			//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    target == this. Removing dropped nodes");

			// TRY TO AVOID THIS ERROR: node.parentNode is null
			try {
				var node = nodes[0];
				var itemObject = new Object;
				for ( var i = 0; i < dataFields.length; i++ )
				{
					itemObject[dataFields[i]] = node.data[dataFields[i]];
					//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    Deleting dataFields[i] " + dataFields[i] + ": " + node.data[dataFields[i]]);
				}			
				//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    Deleting itemObject: " + dojo.toJson(itemObject));
				
				node.parentNode.removeChild(node);
				thisObject.deleteItem(itemObject);
			}
			catch (error) {
				//console.log("Dnd.setTrash    error: " + dojo.toJson(error));
			}
			
			// EMPTY TRASH CONTAINER
			while ( thisObject.trashContainer.childNodes.length > 2 )
			{
				//console.log("Dnd.setTrash    dojo.connect(onDndDrop)    Removing thisObject.trashContainer.childNodes[1]: " + thisObject.trashContainer.childNodes[2]);
			
				thisObject.trashContainer.removeChild(thisObject.trashContainer.childNodes[2]);
			}
		}
	}));
}


}); // plugins.form.DndTrash

