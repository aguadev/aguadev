dojo.provide("plugins.core.Agua.Admin");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	ADMIN METHODS  
*/

dojo.declare( "plugins.core.Agua.Admin",	[  ], {

///////}}}

// ADMIN METHODS
getAdminHeadings : function () {
	console.log("Agua.Admin.getAdminHeadings    plugins.core.Data.getAdminHeadings()");
	var headings = this.cloneData("adminheadings");
	console.log("Agua.Admin.getAdminHeadings    headings: " + dojo.toJson(headings));
	return headings;
},
getAccess : function () {
	//console.log("Agua.Admin.getAccess    plugins.core.Data.getAccess()");
	return this.cloneData("access");
}

});