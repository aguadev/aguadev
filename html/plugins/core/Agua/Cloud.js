dojo.provide("plugins.core.Agua.Cloud");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	ADMIN METHODS  
*/

dojo.declare( "plugins.core.Agua.Cloud",	[  ], {

///////}}}

getCloudHeadings : function () {
	console.log("Agua.Cloud.getCloudHeadings    plugins.core.Data.getCloudHeadings()");
	var headings = this.cloneData("cloudheadings");
	console.log("Agua.Cloud.getCloudHeadings    headings: " + dojo.toJson(headings));
	return headings;
}

});