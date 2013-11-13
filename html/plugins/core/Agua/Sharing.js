dojo.provide("plugins.core.Agua.Sharing");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	ADMIN METHODS  
*/

dojo.declare( "plugins.core.Agua.Sharing",	[  ], {

///////}}}

// ADMIN METHODS
getSharingHeadings : function () {
	console.log("Agua.Sharing.getSharingHeadings    plugins.core.Data.getSharingHeadings()");
	var headings = this.cloneData("sharingheadings");
	console.log("Agua.Sharing.getSharingHeadings    headings: " + dojo.toJson(headings));
	return headings;
},
getAccess : function () {
	//console.log("Agua.Sharing.getAccess    plugins.core.Data.getAccess()");
	return this.cloneData("access");
}

});