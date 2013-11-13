dojo.provide("plugins.core.Agua.Data");
/* SUMMARY: THIS CLASS IS INHERITED BY  Agua.js AND CONTAINS THE MAJORITY
  
  OF THE DATA MANIPULATION METHODS (SUPPLEMENTED BY Common.js WHICH Agua.js
  
  ALSO INHERITS).
  
  THE "MUTATORS AND ACCESSORS" METHODS JUST BELOW ARE PRIVATE - THEY SHOULD
  
  NOT BE CALLED DIRECTLY OR OVERRIDDEN.

*/
dojo.declare( "plugins.core.Agua.Data",	[  ], {

/////}}}
// MUTATORS AND ACCESSORS (GET, SET, CLONE, ETC.)
cloneData : function (name) {
	var caller = this.cloneData.caller.nom;
	//console.log("Data.cloneData    caller: " + caller);
	//console.log("Data.cloneData    name: " + name);
	//console.log("Data.cloneData    this.data:");
	//console.dir({this_data:this.data});
	if ( this.data[name] != null )
	    return dojo.clone(this.data[name]);
	else return [];
},
getData : function(name) {
	////console.log("Data.getData    core.Data.getData()");		
	//console.log("Data.getData    this.data:");
	//console.dir({this_data:this.data});
	if ( this.data[name] == null )
		this.data[name] = [];
	return this.data[name];
},
setData : function(name, value) {
	////console.log("Data.setData    core.Data.setData()");		
	//console.log("Data.setData    this.data:");
	//console.dir({this_data:this.data});
    this.data[name] = value;
},
addData : function(name, object, keys) {
	////console.log("Data.addData    name: " + name);		
	////console.log("Data.addData    object: " + dojo.toJson(object));		
	////console.log("Data.addData    keys: " + dojo.toJson(keys));		
	//console.log("Data.addData    this.data:");
	//console.dir({this_data:this.data});
	return this._addObjectToArray(this.data[name], object, keys);	
},
removeData : function(name, object, keys) {
	////console.log("Data.removeData    name: " + name);		
	//console.log("Data.removeData    this.data:");
	//console.dir({this_data:this.data});
	return this._removeObjectFromArray(this.data[name], object, keys);	
},
removeArrayFromData : function (name, array, keys) {
	//console.log("Data.removeArrayFromData    this.data:");
	//console.dir({this_data:this.data});
	return this._removeArrayFromArray(this.data[name], array, keys);
},
addArrayToData : function (name, array, keys) {
	//console.log("Data.addArrayToData    this.data:");
	//console.dir({this_data:this.data});
	return this._addArrayToArray(this.data[name], array, keys);
},
removeObjectsFromData : function (name, array, keys) {
	//console.log("Data.removeObjectsFromData    BEFORE REMOVE, this.data[" + name + "]");
	//console.dir({this_data:this.data[name]});
	return this._removeObjectsFromArray(this.data[name], array, keys);
},
sortData : function (name, key) {
	this.sortHasharray(this.getData(name), key);
},
loadData : function (data) {
	////console.log("Data.loadData    Agua.loadData(data)");
	////console.log("Data.loadData    data: " + data);
	Agua.data = dojo.clone(data);	
},
}); // end of Agua
