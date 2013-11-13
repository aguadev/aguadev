dojo.provide("plugins.core.Agua.Access");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	ADMIN METHODS  
*/

dojo.declare( "plugins.core.Agua.Access",	[  ], {

///////}}}

getAccess : function () {
	//console.log("Agua.Access.getAccess    plugins.core.Data.getAccess()");
	return this.cloneData("access");
}

});