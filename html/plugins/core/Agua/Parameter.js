dojo.provide("plugins.core.Agua.Parameter");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	PARAMETER METHODS  
*/

dojo.declare( "plugins.core.Agua.Parameter",	[  ], {

/////}}}

// PARAMETER METHODS
addParameter : function (parameterObject) {
// ADD A PARAMETER OBJECT TO THE parameters ARRAY
	console.log("Agua.Parameter.addParameter    parameterObject:");
	console.dir({parameterObject:parameterObject});

	// REMOVE THE PARAMETER OBJECT IF IT EXISTS ALREADY
	var result = this.removeData("parameters", parameterObject, ["appname", "name", "paramtype"]);

	// DO THE ADD
	var requiredKeys = [ "appname", "name", "paramtype" ];
	return result = this.addData("parameters", parameterObject, requiredKeys);
},
removeParameter : function (parameterObject) {
// REMOVE AN PARAMETER OBJECT FROM THE parameters ARRAY.
// RETURN TRUE OR FALSE.
	console.log("Agua.Parameter.removeParameter    plugins.core.Data.removeParameter(parameterObject)");
	console.log("Agua.Parameter.removeParameter    parameterObject: ");
	console.dir({parameterObject:parameterObject});

	if ( ! this._removeParameter(parameterObject) ) 	return false;

	// PUT JSON QUERY
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"deleteParameter";
	query.module 		= 	"Agua::Workflow";
	query.data 			= 	parameterObject;
	//console.log("Parameter.deleteItem    query: " + dojo.toJson(query));
	this.doPut({ url: url, query: query });

	return true;
},
_removeParameter : function (parameterObject) {
	return this.removeData("parameters", parameterObject, ["appname", "name", "paramtype"]);
},
isParameter : function (appName, parameterName) {
// RETURN true IF AN PARAMETER EXISTS IN parameters

	console.log("Agua.Parameter.isParameter    plugins.core.Data.isParameter(parameterName, parameterObject)");
	console.log("Agua.Parameter.isParameter    parameterName: *" + parameterName + "*");
	
	var parameters = getParametersByAppname(appName);
	if ( parameters == null )	return false;

	for ( var i in parameters )
	{
		if ( parameters[i].name.toLowerCase() == parameterName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
},
getParametersByAppname : function (appname) {
// RETURN AN ARRAY OF PARAMETERS FOR THE GIVEN APPLICATION
	console.log("Agua.Parameter.getParametersByAppname    core.Agua.getParametersByAppname(appname)");
	console.log("Agua.Parameter.getParametersByAppname    appname: " + appname);
	if ( appname == null )	return null;	
	var parameters = new Array;
	var params = this.cloneData("parameters");
	for ( var i = 0; i < params.length; i++ )
	{
		var parameter = params[i];
		//console.log("Agua.Parameter.getParametersByAppname    parameter " + parameter.name + ": " + parameter.value);
		if ( parameter.appname == appname ){
			//console.log("Agua.Parameter.getParametersByAppname    PUSHING parameter " + parameter.name + ": " + dojo.toJson(parameter));

			parameters.push(parameter);
		}
	}
	console.log("Agua.Parameter.getParametersByAppname    Returning parameters : ");
	console.dir({parameters:parameters});
	
	return parameters;
},
getParameter : function (appName, parameterName) {
// RETURN A NAMED PARAMETER FOR A GIVEN APPLICATION
// E.G., WHEN RETURNING VALUE TO DEFAULT

	//console.log("Agua.Parameter.getParameter    plugins.core.Data.getParameter(appName)");
	//console.log("Agua.Parameter.getParameter    appName: " + appName);
	//console.log("Agua.Parameter.getParameter    parameterName: " + parameterName);

	if ( appName == null )	return null;
	if ( parameterName == null )	return null;
	
	var parameters = getParametersByAppname(appName);
	if ( parameters == null )	return false;

	for ( var i in parameters )
	{
		if ( parameters[i].name.toLowerCase() == parameterName.toLowerCase() )
		{
			return parameters[i];
		}
	}
	
	return null;
},
getParametersByUserAppname : function(owner, appname) {
// RETURN AN ARRAY OF PARAMETERS FOR THE GIVEN APPLICATION OWNED BY ANOTHER USER
	console.log("Agua.Shared.getAdminParametersByAppname    owner: " + owner);
	console.log("Agua.Shared.getAdminParametersByAppname    appname: " + appname);
	if ( appname == null )	return null;
	var params = this.cloneData("parameters");
	////console.log("Agua.Shared.getAdminParametersByAppname    params : " + dojo.toJson(params));
	var keys = [ "owner", "appname" ];
	var values = [ owner, appname ];
	var parameters = this.filterByKeyValues(params, keys, values);
	////console.log("Agua.Shared.getAdminParametersByAppname    Returning parameters : " + dojo.toJson(parameters));
	
	return parameters;
}


});