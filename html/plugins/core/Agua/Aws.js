dojo.provide("plugins.core.Agua.Aws");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	AWS METHODS  
*/

dojo.declare( "plugins.core.Agua.Aws",	[  ], {

/////}}}

getAws : function () {
// RETURN CLONE OF this.aws
	//console.log("Agua.Aws.getAws    plugins.core.Data.getAws(username)");
	//console.log("Agua.Aws.getAws    username: " + username);
	return this.cloneData("aws");
},
setAws : function (aws) {
// RETURN ENTRY FOR username IN this.aws
	console.log("Agua.Aws.setAws    plugins.core.Data.setAws(aws)");
	console.log("Agua.Aws.setAws    aws: " + dojo.toJson(aws));
	if ( aws == null )
	{
		console.log("Agua.Aws.setAws    aws is null. Returning");
		return;
	}
	if ( aws.amazonuserid == null )
	{
		console.log("Agua.Aws.setAws    aws.amazonuserid is null. Returning");
		return;
	}
	this.setData("aws", aws);
	
	return aws;
},
getAvailzonesByRegion : function (region) {
	if ( region == null )	return;
	var regionzones = this.cloneData("regionzones");
	if ( regionzones[region] != null )
		return regionzones[region];
	
	return [];
}


});