dojo.provide("plugins.core.Agua.Stage");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	STAGE METHODS  
*/

dojo.declare( "plugins.core.Agua.Stage", [], {

/////}}}

// STAGE METHODS
addStage : function (stageObject) {
// ADD AN APP OBJECT TO stages AND COPY ITS PARAMETERS
// INTO parameters. RETURN TRUE OR FALSE.
// ALSO UPDATE THE REMOTE DATABASE.
	console.log("Agua.Stage.addStage    stageObject: ");
	console.dir({stageObject:stageObject});
	
	var result = this._addStage(stageObject);
	
	// ADD PARAMETERS FOR THIS STAGE TO stageparameters
	if ( result == true )	result = this.addStageParametersForStage(stageObject);
	if ( result == false )
	{
		//console.log("Agua.Stage.removeStage    Problem adding stage or stageparameters. Returning.");
		return;
	}
	
	// ADD STAGE ON REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = stageObject;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"addStage";
	query.module 		= 	"Agua::Workflow";
	//console.log("Agua.Stage.addStage    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query });
	
	return result;
},
_addStage : function (stageObject) {
// ADD A STAGE TO stages 
	//console.log("Agua.Stage._addStage    plugins.core.Data._addStage(stageObject)");
	//console.log("Agua.Stage._addStage    stageObject: " + dojo.toJson(stageObject));	
	var requiredKeys = ["project", "workflow", "name", "number"];
	var result = this.addData("stages", stageObject, requiredKeys);
	if ( result == false )
	{
		//console.log("Agua.Stage._addStage    Failed to add stage to stages");
		return false;
	}

	return result;
},
insertStage : function (stageObject) {
// INSERT AN APP OBJECT INTO THE stages ARRAY,
// INCREMENTING THE number OF ALL DOWNSTREAM STAGES
// BEFOREHAND. DO THE SAME FOR THE stageparameters
// ENTRIES FOR THIS APP.
// THEN, MIRROR ON THE REMOTE DATABASE.

	console.log("Agua.Stage.insertStage    plugins.core.Data.insertStage(stageObject)");
	delete stageObject.avatarType;
	console.log("Agua.Stage.insertStage    stageObject: ");
	console.dir({stageObject:stageObject});
	
    // SET THE WORKFLOW NUMBER IN THE STAGE OBJECT
    var workflowNumber = Agua.getWorkflowNumber(stageObject.project, stageObject.workflow);
    stageObject.workflownumber = workflowNumber;    

	// SANITY CHECK
	if ( stageObject == null )	return;
	
	// GET THE STAGES FOR THIS PROJECT AND WORKFLOW
	// ORDERED BY number
	var stages = this.getStagesByWorkflow(stageObject.project, stageObject.workflow);
	//console.log("Agua.Stage.insertStage    pre-insert unsorted stages: " + dojo.toJson(stages, true));
	stages = this.sortHasharray(stages, "number");
	//console.log("Agua.Stage.insertStage    pre-insert sorted stages: ");
	//console.dir({pre_insert_sorted_stages:stages});

	// GET THE INSERTION INDEX OF THE STAGE
	var index = stageObject.number - 1;
	
	var sourceUser = stageObject.owner;
	var targetUser = stageObject.username;
	
	// INCREMENT THE appnumber IN ALL DOWNSTREAM STAGES IN stageparameters
	var result = true;
	for ( var i = stages.length - 1; i > index - 1; i-- )
	{
		// GET THE STAGE PARAMETERS FOR THIS STAGE
		var stageParameters = this.getStageParameters(stages[i]);

		//console.log("Agua.Stage.insertStage    Stage parameters for stages[" + i + "]: ");
		//console.dir({stageParameters:stageParameters});

		if ( stageParameters == null )
		{
			console.log("Agua.Stage.insertStage    Result = false because no stage parameters for stage: " + dojo.toJson(stages[i], true));
			result = false;
		}

		// REMOVE EACH STAGE PARAMETER AND RE-ADD ITS UPDATED VERSION
		var thisObject = this;
		for ( var j = 0; j < stageParameters.length; j++ )
		{
			// REMOVE EXISTING STAGE
			if ( thisObject._removeStageParameter(stageParameters[j]) == false )
			{
				console.log("Agua.Stage.insertStage    Result = false because there was a problem removing stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}

			// INCREMENT STAGE NUMBER
			stageParameters[j].appnumber = (i + 2).toString();

			// ADD BACK STAGE
			if ( thisObject._addStageParameter(stageParameters[j]) == false )
			{
				console.log("Agua.Stage.insertStage    Result = false because there was a problem adding stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}				
		}

		//  ******** DEBUG ONLY ************
		//  ******** DEBUG ONLY ************
		//var updatedStageParameters = this.getStageParameters(stages[i]);
		////console.log("Agua.Stage.insertStage    updatedStageParameters for stages[" + i + "]: " + dojo.toJson(updatedStageParameters));
		//  ******** DEBUG ONLY ************
		//  ******** DEBUG ONLY ************
	}
	if ( result == false )
	{
		console.log("Agua.Stage.insertStage    Returning because there was a problem updating the stage parameters");
		return false;
	}

	// INCREMENT THE number OF ALL DOWNSTREAM STAGES IN stages
	// NB: THE SERVER SIDE UPDATES ARE DONE AUTOMATICALLY
	for ( var i = stages.length - 1; i > index - 1; i-- )
	{
		// REMOVE FROM stages
		if ( this._removeStage(stages[i]) == false )
		{
			console.log("Agua.Stage.spliceStage    Returning because there was a problem removing stages[" + i + "]: " + dojo.toJson(stages[i]));
			return false;
		}

		// INCREMENT STAGE NUMBER
		stages[i].number = (i + 2).toString();

		// ADD BACK TO stages
		if ( this._addStage(stages[i]) == false )
		{
			console.log("Agua.Stage.spliceStage    Returning because there was a problem adding back stages[" + i + "]: " + dojo.toJson(stages[i]));
			return false;
		}
	}
	
	// INSERT THE NEW STAGE (NO EXISTING STAGES WILL HAVE ITS number)
	// (NB: this._addStage CHECKS FOR REQUIRED FIELDS)
	result = this._addStage(stageObject);
	if ( result == false )
	{
		console.log("Agua.Stage.insertStage    Returning FALSE because there was a problem adding the stage to stages: " + dojo.toJson(stageObject));
		return false;
	}
	//console.log("Agua.Stage.insertStage    this._addStage(...) result: " + result);
	
	// ADD PARAMETERS FOR THIS STAGE TO stageparameters
	if ( result == true ) result = this.addStageParametersForStage(stageObject);
	if ( result == false )
	{
		console.log("Agua.Stage.insertStage    Returning because there was a problem copying parameters for the stage:" + dojo.toJson(stageObject));
		return false;
	}

	// ADD STAGE IN REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = stageObject;
	query.username = this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode = "insertStage";
	query.module 		= 	"Agua::Workflow";
	this.doPut({ url: url, query: query });
	
	// RETURN TRUE OR FALSE
	return true;
},
removeStage : function (stageObject) {
// REMOVE AN APP OBJECT FROM THE stages ARRAY
// AND SIMULTANEOUSLY REMOVE CORRESPONDING ENTRIES IN
// parameters FOR THIS STAGE.
// ALSO, MAKE removeStage CALL TO REMOTE DATABASE.

	console.log("Agua.Stage.removeStage    plugins.core.Data.removeStage(stageObject)");
	console.log("Agua.Stage.removeStage    stageObject: " + stageObject);
	
	// DO THE ADD
	var result = this._removeStage(stageObject);

	// ADD PARAMETERS FOR THIS STAGE TO stageparameters
	console.log("Agua.Stage.removeStage    Doing this.removeStageParameters(stageObject)");
	if( result == true ) 	result = this.removeStageParameters(stageObject);

	if ( result == false )
	{
		console.log("Agua.Stage.removeStage    Problem removing stage or stageparameters. Returning.");
		return;
	}
	
	// ADD STAGE TO stage TABLE IN REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = stageObject;
	query.username = this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode = "removeStage";
	query.module 		= 	"Agua::Workflow";
	//console.log("Agua.Stage.removeStage    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query });
	
	// RETURN TRUE OR FALSE
	return result;
},
_removeStage : function (stageObject) {
// REMOVE AN APP OBJECT FROM THE stages ARRAY
// AND SIMULTANEOUSLY REMOVE CORRESPONDING ENTRIES IN
// parameters FOR THIS STAGE
	//console.log("Agua.Stage._removeStage    plugins.core.Data._removeStage(stageObject)");
	//console.log("Agua.Stage._removeStage    stageObject: " + dojo.toJson(stageObject));

	var uniqueKeys = ["project", "workflow", "name", "number"];
	var result = this.removeData("stages", stageObject, uniqueKeys);
	if ( result == false )
	{
		//console.log("Agua.Stage._removeStage    Failed to remove stage from stages");
		return false;
	}
	return result;
},
updateStagesStatus : function (stageList) {
// UPDATE STAGE status, started AND completed
	//console.log("Agua.Stage.updateStagesStatus    stageList: " + dojo.toJson(stageList, true));	
	if ( stageList == null || stageList.length == 0 )	return;
	//console.log("Agua.Stage.updateStagesStatus     stageList.length: " + stageList.length);
	
	// GET ACTUAL stages DATA
	var stages = this.getData("stages");
	
	// ORDER BY STAGE NUMBER -- NB: REMOVES ENTRIES WITH NO NUMBER
	stages = this.sortNumericHasharray(stages, "number");
	//console.log("Agua.Stage.updateStagesStatus     stages.length: " + stages.length);

	var projectName = stages[0].project;
	var workflowName = stages[0].workflow;
	var counter = 0;
	for ( var i = 0; i < stages.length; i++ )
	{
		if ( stages[i].project != projectName )	continue;
		if ( stages[i].workflow != workflowName )	continue;
		counter++;
		//console.log("Agua.Stage.updateStagesStatus     stage " + counter + ": " + dojo.toJson(stages[i], true));
		//console.log("Agua.Stage.updateStagesStatus     stages " + counter + " number: " + stages[i].number + ", status: " + stages[i].status + ", started: " + stages[i].started + ", completed: " + stages[i].completed);
	}
	
	// UPDATE STAGES
	for ( var i = 0; i < stages.length; i++ )
	{
		if ( stages[i].project != projectName )	continue;
		if ( stages[i].workflow != workflowName )	continue;

		for ( var k = 0; k < stageList.length; k++ )
		{
			//console.log("Agua.Stage.updateStagesStatus     stageList " + k);
			if ( stages[i].number == stageList[k].number )
			{
				stages[i].status = stageList[k].status;
				stages[i].started = stageList[k].started;
				stages[i].completed = stageList[k].completed;
				continue;
			}
		}
	}
	
	// DEBUG -- CONFIRM CHANGES
	stages = this.getData("stages");
	stages = this.sortNumericHasharray(stages, "number");
	counter = 0;
	for ( var i = 0; i < stages.length; i++ )
	{
		if ( stages[i].project != projectName )	continue;
		if ( stages[i].workflow != workflowName )	continue;
		counter++;
		//console.log("Agua.Stage.updateStagesStatus     stage " + counter + ": " + dojo.toJson(stages[i], true));
		//console.log("Agua.Stage.updateStagesStatus     stage " + counter + " number: " + stages[i].number + ", status: " + stages[i].status + ", started: " + stages[i].started + ", completed: " + stages[i].completed);
	}
},	
updateStageSubmit : function (stageObject) {
// ADD AN APP OBJECT TO stages AND COPY ITS PARAMETERS
// INTO parameters. RETURN TRUE OR FALSE.
// ALSO UPDATE THE REMOTE DATABASE.
	//console.log("Agua.Stage.updateStageSubmit    plugins.core.Data.updateStageSubmit(stageObject)");
	//console.log("Agua.Stage.updateStageSubmit    stageObject: " + dojo.toJson(stageObject));

	var stages = this.getData("stages");
	var index = this._getIndexInArray(stages, stageObject, ["project", "workflow", "number"]);
	//console.log("Agua.Stage.updateStageSubmit    index: " + index);	
	if ( index == null )	return 0;
	
	//console.log("Agua.Stage.updateStageSubmit    stages[index]: " + dojo.toJson(stages[index]));
	stages[index].submit = stageObject.submit;

	// ADD STAGE ON REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	stageObject.username = this.cookie("username");
	stageObject.sessionid = this.cookie("sessionid");
	stageObject.mode = "updateStageSubmit";
	stageObject.module 		= 	"Workflow";
	//console.log("Agua.Stage.updateStageSubmit    stageObject: " + dojo.toJson(stageObject, true));
	this.doPut({ url: url, query: stageObject });

	return 1;
},
spliceStage : function (stageObject) {
// SPLICE OUT A STAGE FROM stages AND DECREMENT THE
// number OF ALL DOWNSTREAM STAGES.
// DO THE SAME FOR THE CORRESPONDING ENTRIES IN stageparameters
	//console.log("Agua.Stage.spliceStage    plugins.core.Data.updateStage(stageObject)");
	//console.log("Agua.Stage.spliceStage    stageObject: " + dojo.toJson(stageObject, true));
	
	// SANITY CHECK
	if ( stageObject == null )	return;
	
	// GET THE STAGES FOR THIS PROJECT AND WORKFLOW
	var stages = this.getStagesByWorkflow(stageObject.project, stageObject.workflow);
	//////console.log("Agua.Stage.spliceStage    pre-splice unsorted stages: " + dojo.toJson(stages, true));

	// ORDER BY number AND SPLICE OUT THE STAGE 
	stages = this.sortHasharray(stages, "number");
	//////console.log("Agua.Stage.spliceStage    pre-splice sorted stages: " + dojo.toJson(stages, true));
	var index = stageObject.number - 1;
	stages.splice(index, 1);
	
	
	// REMOVE THE STAGE FROM THE stages
	var result = this._removeStage(stageObject);
	if ( result == false )
	{
		////console.log("Agua.Stage.spliceStage    Returning because there was a problem removing the stage from stages: " + dojo.toJson(stageObject));
		return false;
	}

	// REMOVE THE STAGE FROM stageparameters
	//console.log("Agua.Stage.spliceStage    Doing this.removeStageParameters(stageObject)");
	result = this.removeStageParameters(stageObject);
	if ( result == false )
	{
		console.log("Agua.Stage.spliceStage    Returning because there was a problem removing parameters for the stage:" + dojo.toJson(stageObject));
		return false;
	}

	// DECREMENT THE number OF ALL DOWNSTREAM STAGES IN stages
	// NB: THE SERVER SIDE UPDATES ARE DONE AUTOMATICALLY
	for ( var i = index; i < stages.length; i++ )
	{
		// REMOVE IT FROM THE stages ARRAY
		////console.log("Agua.Stage.spliceStage    Replacing stage " + i + " to decrement number to " + (i + 1) );
		this._removeStage(stages[i]);
		stages[i].number = (i + 1).toString();
		this._addStage(stages[i]);
	}

	//  ******** DEBUG ONLY ************
	//  ******** DEBUG ONLY ************
	var newStages = this.getStagesByWorkflow(stageObject.project, stageObject.workflow);
	//////console.log("Agua.Stage.spliceStage    post-splice stages: " + dojo.toJson(newStages, true));
	for ( var i = 0; i < newStages.length; i++ )
	{
		////console.log("Agua.Stage.spliceStage    newStages[" + i + "]:" + newStages[i].name + "\t" + newStages[i].number);
	}
	
	//  ******** DEBUG ONLY ************
	//  ******** DEBUG ONLY ************


	// DECREMENT THE appnumber IN ALL DOWNSTREAM STAGES IN stageparameters
	////console.log("Agua.Stage.spliceStage    Doing from " + (stages.length - 1) + " to " + index);
	for ( var i = stages.length - 1; i > index - 1; i-- )
	{
		// REINCREMENT STAGE NUMBER TO GET ITS STAGE
		// PARAMETERS, WHICH HAVE NOT BEEN DECREMENTED YET
		stages[i].number = (i + 2).toString();
		////console.log("Agua.Stage.spliceStage    Reincremented stage[" + i + "].number to: " + stages[i].number);

		// GET THE STAGE PARAMETERS FOR THIS STAGE
		var stageParameters = this.getStageParameters(stages[i]);
		//////console.log("Agua.Stage.spliceStage    stages[" + i + "]: " + dojo.toJson(stages[i], true));
		//////console.log("Agua.Stage.spliceStage    Stage parameters for stages[" + i + "]: " + dojo.toJson(stageParameters, true));
		if ( stageParameters == null )
		{
			////console.log("Agua.Stage.spliceStage    Returning because no stage parameters for stage: " + dojo.toJson(stages[i], true));
			return false;
		}

		// REMOVE EACH STAGE PARAMETER AND RE-ADD ITS UPDATED VERSION
		var thisObject = this;
		//dojo.forEach( stageParameters, function(stageParameter, i)
		for ( var j = 0; j < stageParameters.length; j++ )
		{
			// REMOVE EXISTING STAGE
			if ( thisObject._removeStageParameter(stageParameters[j]) == false )
			{
				////console.log("Agua.Stage.spliceStage    Result = false because there was a problem removing stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}

			// DECREMENT STAGE NUMBER
			stageParameters[j].appnumber = (i + 1).toString();

			// ADD BACK STAGE
			if ( thisObject._addStageParameter(stageParameters[j]) == false )
			{
				////console.log("Agua.Stage.spliceStage    Result = false because there was a problem adding stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}
		}

		// REDECREMENT STAGE NUMBER
		stages[i].number = (i + 1).toString();
		////console.log("Agua.Stage.spliceStage    Redecremented stage[" + i + "].number to: " + stages[i].number);
	}
	if ( result == false )	return false;

	// REMOVE FROM REMOTE DATABASE DATABASE:
	var url = Agua.cgiUrl + "agua.cgi";

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query = stageObject;
	query.username = this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode = "removeStage";
	query.module 		= 	"Agua::Workflow";
	////console.log("Agua.Stage.spliceStage    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query});
},
isStage : function (stageName) {
// RETURN true IF AN APP EXISTS IN stages
	//console.log("Agua.Stage.isStage    plugins.core.Data.isStage(stageName, stageObject)");
	//console.log("Agua.Stage.isStage    stageName: *" + stageName + "*");
	var stages = this.getStages();
	for ( var i in stages )
	{
		var stage = stages[i];
		//console.log("Agua.Stage.isStage    Checking stage.name: *" + stage.name + "*");
		if ( stage.name.toLowerCase() == stageName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
},
getStageType : function (stageName) {
// RETURN true IF AN APP EXISTS IN stages
	//console.log("Agua.Stage.getStageType    plugins.core.Data.getStageType(stageName, stageObject)");
	////console.log("Agua.Stage.getStageType    stageName: *" + stageName + "*");
	var stages = this.getStages();
	for ( var i in stages )
	{
		var stage = stages[i];
		////console.log("Agua.Stage.getStageType    Checking stage.name: *" + stage.name + "*");
		if ( stage.name.toLowerCase() == stageName.toLowerCase() )
		{
			return stage.type;
		}
	}
	
	return null;
},
getStages : function () {
	//console.log("Agua.Stage.getStages    plugins.core.Data.getStages()");
	
	return this.cloneData("stages");
},
getStagesByWorkflow : function (project, workflow) {
// RETURN AN ARRAY OF STAGE HASHES FOR THIS PROJECT AND WORKFLOW

	////console.log("Agua.Stage.getStagesByWorkflow    plugins.core.Data.getStagesByWorkflow(project, workflow)");
	////console.log("Agua.Stage.getStagesByWorkflow    project: " + project);
	////console.log("Agua.Stage.getStagesByWorkflow    workflow: " + workflow);
	if ( project == null )	return;
	if ( workflow == null )	return;
	var stages = this.cloneData("stages");
	var keyArray = ["project", "workflow"];
	var valueArray = [project, workflow];
	stages = this.filterByKeyValues(stages, keyArray, valueArray);
	
	////console.log("Agua.Stage.getStagesByWorkflow    Returning stages: " + dojo.toJson(stages));

	return stages;
}

});