dojo.provide("plugins.data.FileStore");

// EXTERNAL MODULES
dojo.require("dojo.dnd.Source");

// INTERNAL MODULES
dojo.require("dojox.data.FileStore");

dojo.declare("plugins.data.FileStore",
	[ dojox.data.FileStore ],
{

// OVERRIDE _processItemArray TO RETURN [] IF itemArray IS NULL to AVOID ERROR

_processItemArray: function(itemArray){
	// summary:
	// Internal function for processing an array of items for return.
	if ( itemArray == null )	return [];
	var i;
	for(i = 0; i < itemArray.length; i++){
		this._processItem(itemArray[i]);
	}
	return itemArray;
},

// OVERRIDE _assertIsItem TO AVOID ERROR:
// Error: dojox.data.FileStore: a function was passed an item argument that was not an item

_assertIsItem: function(/* item */ item){

	if ( item == null )	return false;
	// summary:
	// This function tests whether the item passed in is indeed an item in the store.
	// item:
	// The item to test for being contained by the store.
	if(!this.isItem(item)){
		throw new Error("dojox.data.FileStore: a function was passed an item argument that was not an item");
	}
},



}); // plugins.data.FileStore

