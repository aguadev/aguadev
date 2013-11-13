dojo.provide("plugins.core.Agua.StageParameter");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	STAGEPARAMETER METHODS  
*/

dojo.declare( "plugins.core.Agua.StageParameter",	[  ], {

/////}}}

// STAGEPARAMETER METHODS
addStageParameter : function (stageParameterObject) {
// 1. REMOVE ANY EXISTING STAGE PARAMETER (UNIQUE KEYS: appname, appnumber, name)
// 		(I.E., THE SAME AS UPDATING AN EXISTING STAGE PARAMETER)
// 2. ADD A STAGE PARAMETER OBJECT TO THE stageparameters ARRAY
//   
// 3. ADD TO stageparameter TABLE IN REMOTE DATABASE

	//console.log("Agua.StageParameter.addStageParameter    plugins.core.Data.addStageParameter(stageParameterObject)");
	//console.log("Agua.StageParameter.addStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	// DO THE REMOVE
	this._removeStageParameter(stageParameterObject);
	
	// DO THE ADD
	var result = this._addStageParameter(stageParameterObject);
	if ( result == false )
    {
        console.log("Agua.StageParameter.addStageParameter    result of _addStageParameter is " + result + ". Returning");
        return result;
    }
    
	// REMOVE FROM REMOTE DATABASE DATABASE:
	// SET URL, ADD RANDOM NUMBER TO DISAMBIGUATE BETWEEN CALLS BY DIFFERENT
	// METHODS TO THE SERVER
	var url = this.cgiUrl + "agua.cgi";

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query 			= 	stageParameterObject;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"addStageParameter";
	query.module 		= 	"Agua::Workflow";
	//console.log("Agua.StageParameter.addStageParameter     query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query});

	// RETURN TRUE OR FALSE
	return result;
},
_addStageParameter : function (stageParameterObject) {
// ADD A STAGE PARAMETER OBJECT TO THE stageparameters ARRAY,
// REQUIRE THAT UNIQUE KEYS ARE DEFINED

	if ( stageParameterObject.chained == null )
		stageParameterObject.chained = "0";
	//console.log("Agua.StageParameter_addStageParameter    plugins.core.Data._addStageParameter(stageParameterObject)");
	//console.log("Agua.StageParameter_addStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	// DO THE ADD
	var uniqueKeys = ["project", "workflow", "appname", "appnumber", "name", "paramtype"];
	return this.addData("stageparameters", stageParameterObject, uniqueKeys);
},
removeStageParameter : function (stageParameterObject) {
// 1. REMOVE A stage PARAMETER OBJECT FROM THE stageparameters ARRAY
// 2. REMOVE FROM stageparameter TABLE IN REMOTE DATABASE

	////console.log("Agua.StageParameterremoveStageParameter    plugins.core.Data.removeStageParameter(stageParameterObject)");
	////console.log("Agua.StageParameterremoveStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	var result = this._removeStageParameter(stageParameterObject);
	if ( result == false )	return result;

	// REMOVE FROM REMOTE DATABASE:
	// SET URL, ADD RANDOM NUMBER TO DISAMBIGUATE BETWEEN CALLS BY DIFFERENT
	// METHODS TO THE SERVER
	var url = this.cgiUrl + "agua.cgi";
	
	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query 		= 	stageParameterObject;
	query.username 	= 	this.cookie("username");
	query.sessionid = 	this.cookie("sessionid");
	query.mode 		= 	"removeStageParameter";
	query.module 	= 	"Agua::Workflow";
	//console.log("Agua.StageParameter.addStageParameter     query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query, timeout : 15000 });

	// RETURN TRUE OR FALSE
	return result;
},
_removeStageParameter : function (stageParameterObject) {
// REMOVE A stage PARAMETER OBJECT FROM THE stageparameters ARRAY,
// IDENTIFY OBJECT USING UNIQUE KEYS
	////console.log("Agua.StageParameter_removeStageParameter    plugins.core.Data._removeStageParameter(stageParameterObject)");
	////console.log("Agua.StageParameter_removeStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	var uniqueKeys = ["project", "workflow", "appname", "appnumber", "name", "paramtype"];
	return this.removeData("stageparameters", stageParameterObject, uniqueKeys);
},
getStageParameters : function (stageObject) {
// RETURN AN ARRAY OF STAGE PARAMETER HASHARRAYS FOR THE GIVEN STAGE
	console.log("Agua.StageParameter.getStageParameters    plugins.core.Data.getStageParameters(stageObject)");
	console.log("Agua.StageParameter.getStageParameters    stageObject: ");
	console.dir({stageObject:stageObject});
	if ( stageObject == null )	return;
	
	var keys = ["project", "workflow", "name", "number"];
	var notDefined = this.notDefined (stageObject, keys);
	console.log("Agua.StageParameter.getStageParameters    notDefined: " + dojo.toJson(notDefined));
	if ( notDefined.length != 0 )
	{
		console.log("Agua.StageParameter.getStageParameters    not defined: " + dojo.toJson(notDefined));
		return;
	}
	
	// CONVERT STAGE number TO appnumber
	stageObject.appnumber = stageObject.number;
	stageObject.appname = stageObject.name;

	var stageParameters = this._getStageParameters();
	console.log("Agua.StageParameter.getStageParameters    INITIAL stageParameters: ");
	console.dir({stageParameters:stageParameters});
	console.log("Agua.StageParameter.getStageParameters    INITIAL stageParameters.length: " + stageParameters.length);	
	var keyArray = ["project", "workflow", "appname", "appnumber"];
	var valueArray = [stageObject.project, stageObject.workflow, stageObject.name, stageObject.number];
	stageParameters = this.filterByKeyValues(stageParameters, keyArray, valueArray);
	console.log("Agua.StageParameter.getStageParameters    Returning stageParameters.length: " + stageParameters.length);
	console.dir({stageParameters:stageParameters});

	return stageParameters;
},
_getStageParameters : function () {
    return this.cloneData("stageparameters");
},
addStageParametersForStage : function (stageObject) {
// ADD parameters ENTRIES FOR A STAGE TO stageparameters
	console.log("Agua.StageParameter.addStageParametersForStage    plugins.core.Data.addStageParametersForStage(stageObject)");
	console.log("Agua.StageParameter.addStageParametersForStage    stageObject: ");
	console.dir({stageObject:stageObject});
	if ( stageObject.name == null )	return null;
	if ( stageObject.number == null )	return null;

	// GET APP PARAMETERS	
	var parameters;
	console.log("Agua.StageParameter.addStageParametersForStage    this.cookie('username'): " + this.cookie('username'));
	console.log("Agua.StageParameter.addStageParametersForStage    stageObject.username: " + stageObject.username);
	if ( stageObject.username == this.cookie("username") )
	{
		console.log("Agua.StageParameter.addStageParametersForStage    Doing this.getParametersByAppname(stageObject.name)");
		parameters = dojo.clone(this.getParametersByAppname(stageObject.name));
	}
	else {
		console.log("Agua.StageParameter.addStageParametersForStage    Doing this.getSHAREDParametersByAppname(stageObject.name)");
		parameters = dojo.clone(this.getParametersByUserAppname(stageObject.owner, stageObject.name));
	}
	console.log("Agua.StageParameter.addStageParametersForStage    parameters.length: " + parameters.length);	
	console.log("Agua.StageParameter.addStageParametersForStage    BEFORE parameters: ");
	console.dir({parameters:parameters});

	// ADD STAGE project, workflow, AND number TO PARAMETERS
	dojo.forEach(parameters, function(parameter) {
		parameter.project = stageObject.project;
		parameter.workflow = stageObject.workflow;
		parameter.appnumber = stageObject.number;
		parameter.appname = stageObject.name;
	});
	console.log("Agua.StageParameter.addStageParametersForStage    AFTER parameters: ");
	console.dir({parameters:parameters});
	console.log("Agua.StageParameter.addStageParametersForStage    parameters.length: " + parameters.length);

	var stageParameters = Agua.cloneData("stageparameters");
	console.log("Agua.StageParameter.addStageParametersForStage    stageParameters.length: " + stageParameters.length);


	// ADD PARAMETERS TO stageparameters ARRAY
	var uniqueKeys = ["owner", "project", "workflow", "appname", "appnumber", "name", "paramtype"];
	var addOk = true;
	var thisObject = this;
	dojo.forEach(parameters, function(parameter)
	{
		console.log("Agua.StageParameter.addStageParametersForStage    Adding parameter: ");
		console.dir({parameter:parameter});

		if ( thisObject.addData("stageparameters", parameter, uniqueKeys) == false) {
			addOk = false;
		}

		stageParameters = Agua.cloneData("stageparameters");
		console.log("Agua.StageParameter.addStageParametersForStage    stageParameters.length: " + stageParameters.length);

	});
	console.log("Agua.StageParameter.addStageParametersForStage    addOk: " + addOk);
	if ( ! addOk ) {
		console.log("Agua.StageParameter.addStageParametersForStage    Could not add one or more parameters to stageparameters");
		return;
	}

	return addOk;
},
removeStageParameters : function (stageObject) {
// REMOVE STAGE PARAMETERS FOR A STAGE FROM stageparameters 
	//console.log("Agua.StageParameterremoveStageParameters    plugins.core.Data.removeStageParameters(stageObject)");
	//console.log("Agua.StageParameterremoveStageParameters    stageObject: " + dojo.toJson(stageObject, true));

	if ( stageObject.name == null ) {
		console.log("Agua.StageParameterremoveStageParameters    stageObject.name is null. Returning.");
		return null;
	}
	if ( stageObject.number == null ) {
		console.log("Agua.StageParameterremoveStageParameters    stageObject.number is null. Returning.");
		return null;
	}

	// GET STAGE PARAMETERS BELONGING TO THIS STAGE
	var keys = [ "owner", "project", "workflow", "appname", "appnumber" ];
	var values = [ stageObject.owner, stageObject.project, stageObject.workflow, stageObject.name, stageObject.number ];
	var removeTheseStageParameters = this.filterByKeyValues(this._getStageParameters(), keys, values);
	//console.log("Agua.StageParameterremoveStageParameters    removeTheseStageParameters.length: " + removeTheseStageParameters.length);

	// REMOVE PARAMETERS FROM stageparameters
	var uniqueKeys = [ "project", "workflow", "appname", "appnumber", "name"];
	var removeOk = this.removeArrayFromData("stageparameters", removeTheseStageParameters, uniqueKeys);
	console.log("Agua.StageParameterremoveStageParameters    removeOk: " + removeOk);
	if ( removeOk == false ) {
		console.log("Agua.StageParameterremoveStageParameters    Could not remove one or more parameters from stageparameters");
		return false;
	}

	return true;
},
getStageParametersByApp : function (appname) {
// RETURN AN ARRAY OF PARAMETER HASHARRAYS FOR THE GIVEN APPLICATION
	//console.log("Agua.StageParameter.getStageParametersByApp    plugins.core.Data.getStageParametersByApp(appname)");
	//console.log("Agua.StageParameter.getStageParametersByApp    appname: " + appname);

	var stageParameters = new Array;
	dojo.forEach(this.getStageParameters(), function(stageparameter) {
		if ( stageparameter.appname == appname )	stageParameters.push(stageparameter);
	});
	
	//console.log("Agua.StageParameter.getStageParametersByApp    Returning stageParameters: " + dojo.toJson(stageParameters));

	return stageParameters;
}

});