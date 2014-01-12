define(
	[
		"dojo/_base/declare",
		"dojo/store/Memory",
		"dojo/_base/array",
	],
///////}}}}}}}

function(declare, Memory, Data, arrayUtil){	

///////}}}}}
///////}}}}}}}

return declare("plugins/request/DataStore",[Memory], {

// data : ArrayRef
//		Array of data entries
data: null,

///////}}}}}
///////}}}}}}}

startup : function () {
	if ( ! this.core ) {
		this.core = new Object();
	}
	//console.log("request.DataStore.startup    DOING this.getData()");
	var data = this.data;
	//console.log("request.DataStore.startup    data: ");
	//console.dir({data:data});

	if ( data )	{
		this.setData(data);
	}
	
	return data;
},
setData : function (data) {
	//console.log("request.DataStore.setData    data:");
	//console.dir({data:data});

	this.data	=	data;
},
getData : function () {
// GET DATA FOR dataStore
	//console.log("request.DataStore.getData    DOING this.getItems()");
	var items = this.getItems();	
	//console.log("request.DataStore.getData    items:");
	//console.dir({items:items});

	var data = {
		identifier	: 	"Analysis ID",
		label		:	"Analysis ID",
		items		:	items
	};	
	this.data = data;

	//console.log("request.DataStore.getData    Returning data:");
	//console.dir({data:data});
	
	return data;
},
getItems : function () {
	//console.log("request.DataStore.getItems");

	var thisObject = this;
	var items = [];
	arrayUtil.forEach(thisObject.data, function(entry, i) {
		var item 			=	entry;
		items.push(item);
	});
	
	return items;	
}


}); 	//	end declare

});	//	end define

	
