dojo.provide("plugins.core.Agua.Ami");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	CLUSTER METHODS  
*/

dojo.declare( "plugins.core.Agua.Ami",	[  ], {

/////}}}
getAmis : function () {
// RETURN A COPY OF THE amis ARRAY
	//console.log("Agua.Ami.getAmis    plugins.core.Data.getAmis()");
	return this.cloneData("amis");
},
getAmiObjectById : function (amiid) {
	//console.log("Agua.Ami.getAmiObjectById    plugins.core.Data.getAmiObjectById()");
	var amis = this.getAmis();	
	//console.log("Agua.Ami.getAmiObjectById    amis: " + dojo.toJson(amis));
	return this._getObjectByKeyValue(amis, ["amiid"], amiid);	
},
addAmi : function (amiObject) {
	this._removeAmi(amiObject);
	this._addAmi(amiObject);

	// SAVE ON REMOTE DATABASE
	var url = this.cgiUrl + "agua.cgi?";
	amiObject.username = this.cookie("username");	
	amiObject.sessionid = this.cookie("sessionid");	
	amiObject.mode = "addAmi";
	amiObject.module = "Agua::Workflow";
	console.log("Agua.Ami.addAmi    amiObject: " + dojo.toJson(amiObject));
	
	this.doPut({ url: url, query: amiObject, sync: false, timeout: 15000 });
},
removeAmi : function (amiObject) {
	console.log("Agua.Ami.removeAmi    Agua.removeAmi(amiObject)");
	//console.log("Agua.Ami.removeAmi    amiObject: " + dojo.toJson(amiObject));

	var success = this._removeAmi(amiObject)
	if ( success == false ) {
		console.log("this.removeAmi    this._removeAmi(amiObject) returned false for ami: " + amiObject.ami);
		return;
	}
	
	var url = this.cgiUrl + "agua.cgi?";
	amiObject.username = this.cookie("username");
	amiObject.sessionid = this.cookie("sessionid");
	amiObject.mode = "removeAmi";
	amiObject.module = "Agua::Workflow";
	//console.log("this.removeAmi    amiObject: " + dojo.toJson(amiObject));

	this.doPut({ url: url, query: amiObject, sync: false, timeout: 15000 });	
},
_removeAmi : function (amiObject) {
// REMOVE A CLUSTER OBJECT FROM THE amis ARRAY
	console.log("Agua.Ami._removeAmi    plugins.core.Data._removeAmi(amiObject)");
	//console.log("Agua.Ami._removeAmi    amiObject: " + dojo.toJson(amiObject));
	var requiredKeys = ["amiid"];
	return this.removeData("amis", amiObject, requiredKeys);
},
_addAmi : function (amiObject) {
// ADD A CLUSTER TO amis AND SAVE ON REMOTE SERVER
	console.log("Agua.Ami._addAmi    plugins.core.Data._addAmi(amiObject)");
	//console.log("Agua.Ami._addAmi    amiObject: " + dojo.toJson(amiObject));

	// DO THE ADD
	var requiredKeys = ["amiid"];
	return this.addData("amis", amiObject, requiredKeys);
}


});