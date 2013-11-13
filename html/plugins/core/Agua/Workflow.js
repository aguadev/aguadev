dojo.provide("plugins.core.Agua.Workflow");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	WORKFLOW METHODS  
*/

dojo.declare( "plugins.core.Agua.Workflow",	[  ], {

/////}}}

// 	WORKFLOW METHODS
getWorkflows : function () {
// RETURN A SORTED COPY OF workflows
	//console.log("Agua.Workflow.getWorkflows    plugins.core.Data.getWorkflows(workflowObject)");
	var workflows = this.cloneData("workflows");
	return this.sortHasharray(workflows, "name");
},
getWorkflowNamesByProject : function (projectName) {
// RETURN AN ARRAY OF NAMES OF WORKFLOWS IN THE SPECIFIED PROJECT
	//console.log("Agua.Workflow.getWorkflowNamesByProject    plugins.core.Data.getWorkflowNamesByProject(projectName)");
	//console.log("Agua.Workflow.getWorkflowNamesByProject    projectName: " + projectName);
	var workflows = this.getWorkflowsByProject(projectName);
	//console.log("Agua.Workflow.getWorkflowNamesByProject    workflows: " + dojo.toJson(workflows));

	// ORDER BY WORKFLOW NUMBER -- NB: REMOVES ENTRIES WITH NO WORKFLOW NUMBER
	workflows = this.sortNumericHasharray(workflows, "number");	

	return this.hashArrayKeyToArray(workflows, "name");
},
getWorkflowsByProject : function (projectName) {
// RETURN AN ARRAY OF WORKFLOWS IN THE SPECIFIED PROJECT
	//console.log("Agua.Workflow.getWorkflowsByProject    plugins.core.Data.getWorkflowsByProject(projectName)");
	//console.log("Agua.Workflow.getWorkflowsByProject    projectName: " + projectName);
	var workflows = this.cloneData("workflows");
	return this.filterByKeyValues(workflows, ["project"], [projectName]);
},
getWorkflow : function (workflowObject) {
// RETURN FULL workflow OBJECT IF WORKFLOW IN PROJECT
	console.log("Agua.Workflow.getWorkflow     plugins.core.Data.getWorkflow(workflowObject)");
	console.log("Agua.Workflow.getWorkflow     workflowObject: ");
	console.dir({workflowObject:workflowObject});
	
	var object = this._getWorkflow(workflowObject);
	if ( ! object )
	{
		console.log("Agua.Workflow.getWorkflow     No workflowObject.name " + workflowObject.name + " found. Returning");
		return null;
	}
	console.log("Agua.Workflow.getWorkflow     object.name: " + object.name);
	console.log("Agua.Workflow.getWorkflow     object: ");
	console.dir({object:object});

	return object;
},
_getWorkflow : function (workflowObject) {
// RETURN WORKFLOW IN workflows IDENTIFIED BY PROJECT AND WORKFLOW NAMES
	console.log("Agua.Workflow._getWorkflow     plugins.core.Data._getWorkflow(workflowObject)");
	console.log("Agua.Workflow._getWorkflow     workflowObject: " + dojo.toJson(workflowObject));
	
	if ( ! this.isProject(workflowObject.project) )
	{
		console.log("Agua.Workflow._getWorkflow     No project found in workflowObject. Returning false.");
		return false;
	}
	
	// GET ALL WORKFLOWS
	var workflows = this.getWorkflows();
	//console.log("Agua.Workflow._getWorkflow     workflows: " + dojo.toJson(workflows));		
	if ( workflows == null ) 
	{
		console.log("Agua.Workflow._getWorkflow     workflows is null. Returning false.");
		return false;
	}
	
	// CHECK FOR OUR PROJECT AND WORKFLOW NAME AMONG WORKFLOWS
	var keyArray = ["project", "name"];
	var valueArray = [ workflowObject.project, workflowObject.name ];
	var workflows = this.filterByKeyValues(workflows, keyArray, valueArray);
	
	if ( ! workflows || workflows.length == 0 )	return;

	return workflows[0];
},
isWorkflow : function (workflowObject) {
// RETURN TRUE IF WORKFLOW NAME IS FOUND IN PROJECT IN workflows
	console.log("Agua.Workflow.isWorkflow     caller: " + this.isWorkflow.caller.nom);
	//console.log("Agua.Workflow.isWorkflow     workflowObject: ");
	//console.dir({workflowObject:workflowObject});
	var object = this._getWorkflow(workflowObject);
	if ( ! object ) {
		console.log("Agua.Workflow.isWorkflow     Returning false");
		return false;
	}
	
	console.log("Agua.Workflow.isWorkflow     Returning true");
	return true;		
},
getWorkflowNumber : function (projectName, workflowName) {
// WORKFLOW NUMBER GIVEN PROJECT AND WORKFLOW IN workflows
	//console.log("Agua.Workflow.getWorkflowNumber     plugins.core.Data.getWorkflowNumber(projectName, workflowName)");
	//console.log("Agua.Workflow.getWorkflowNumber     projectName: " + projectName);
	//console.log("Agua.Workflow.getWorkflowNumber     workflowName: " + workflowName);
	var workflowObject = this._getWorkflow({ project: projectName, name: workflowName });
	if ( ! workflowObject ) return null;
	console.log("Agua.Workflow.getWorkflowNumber    workflowObject:");
	console.dir({workflowObject:workflowObject});

	return workflowObject.number;
},
getMaxWorkflowNumber : function (projectName) {
// WORKFLOW NUMBER GIVEN PROJECT AND WORKFLOW IN workflows
	console.log("Agua.Workflow.getMaxWorkflowNumber     plugins.core.Data.getMaxWorkflowNumber(projectName)");
	console.log("Agua.Workflow.getMaxWorkflowNumber     projectName: " + projectName);
	
	var workflowObjects = this.getWorkflowsByProject(projectName);
	//console.log("Agua.Workflow.getMaxWorkflowNumber     workflowObject: " + dojo.toJson(workflowObjects));		
	if ( workflowObjects == null ) return null;
	if ( workflowObjects.length == 0 ) return null;

	console.log("Agua.Workflow.getMaxWorkflowNumber     Returning workflowObjects.length: " + workflowObjects.length);
	return workflowObjects.length;
},
moveWorkflow : function (workflowObject, newNumber) {
// MOVE A WORKFLOW WITHIN A PROJECT
	console.log("Agua.Workflow.moveWorkflow    workflowObject: " + dojo.toJson(workflowObject, true));	
	//console.log("Agua.Workflow.moveWorkflow    newNumber: " + newNumber);

	var oldNumber = workflowObject.number;
	if ( oldNumber == null )	return false;
	if ( oldNumber == newNumber )	return false;
	//console.log("Agua.Workflow.moveWorkflow    oldNumber: " + oldNumber);
	
	// GET ACTUAL WORKFLOWS DATA
	var workflows = this.getData("workflows");
	//console.log("Agua.Workflow.moveWorkflow     UNSORTED workflows: " + dojo.toJson(workflows));

	// ORDER BY WORKFLOW NUMBER -- NB: REMOVES ENTRIES WITH NO WORKFLOW NUMBER
	workflows = this.sortNumericHasharray(workflows, "number");	
	for ( var i = 0; i < workflows.length; i++ )
	{
		if ( workflows[i].project != projectName )	continue;
		counter++;
	}

	// DO RENUMBER
	var projectName = workflowObject.project;
	var counter = 0;
	for ( var i = 0; i < workflows.length; i++ )
	{
		if ( workflows[i].project != projectName )	continue;
		counter++;

		// SKIP IF BEFORE REORDERED WORKFLOWS
		if ( counter < oldNumber && counter < newNumber )
		{
			workflows[i].number = counter;
		}
		// IF WORKFLOW HAS BEEN MOVED DOWNWARDS, GIVE IT THE NEW INDEX
		// AND DECREMENT COUNTER FOR SUBSEQUENT WORKFLOWS
		else if ( oldNumber < newNumber ) {
			if ( counter == oldNumber ) {
				workflows[i].number = newNumber;
			}
			else if ( counter <= newNumber ) {
				workflows[i].number = counter - 1;
			}
			else {
				workflows[i].number = counter;
			}
		}
		// OTHERWISE, THE WORKFLOW HAS BEEN MOVED UPWARDS SO GIVE IT
		// THE NEW INDEX AND INCREMENT COUNTER FOR SUBSEQUENT WORKFLOWS
		else {
			if ( counter < oldNumber ) {
				workflows[i].number = counter + 1;
			}
			else if ( oldNumber == counter ) {
				workflows[i].number = newNumber;
			}
			else {
				workflows[i].number = counter;
			}
		}
	}
	
	var query = workflowObject;
	query.newnumber = newNumber;
	query.mode = "moveWorkflow";
	query.module 		= 	"Agua::Workflow";
	query.username = Agua.cookie("username");
	query.sessionid = Agua.cookie("sessionid");
	var url = Agua.cgiUrl + "agua.cgi";
	this.doPut({ url: url, query: query, sync: false });
},
renumberWorkflows : function(projectName) {
	console.log("Agua.Workflow.renumberWorkflows     plugins.core.Data.renumberWorkflows(projectName)");
	console.log("Agua.Workflow.renumberWorkflows     projectName: " + projectName);
	var workflows = this.getWorkflowsByProject(projectName);
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);

	this.printObjectKeys(workflows, "number", "UNSORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);
	this.printObjectKeys(workflows, "name", "UNSORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);

	workflows = this.sortHasharrayByKeys(workflows, ["number"]);
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);		

	this.printObjectKeys(workflows, "number", "SORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);
	this.printObjectKeys(workflows, "name", "SORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);

	// DO RENUMBER
	console.log("Agua.Workflow.renumberWorkflows     RENUMBERING workflows");
	var number = 0;
	for ( var i = 0; i < workflows.length; i++ )
	{
		console.log("Agua.Workflow.renumberWorkflows     REMOVING workflow [" + i + "].number: " + workflows[i].number);
		this._removeWorkflow(workflows[i]);
		number++;
		workflows[i].number = number;
		console.log("Agua.Workflow.renumberWorkflows     ADDING workflows [" + i + "].number: " + workflows[i].number);
		this._addWorkflow(workflows[i]);
	}

	workflows = this.getWorkflowsByProject(projectName);
	console.log("Agua.Workflow.renumberWorkflows     BEFORE FILTER workflows.length: " + workflows.length);
	workflows = this.filterByKeyValues(workflows, ["project"], [projectName]);
	console.log("Agua.Workflow.renumberWorkflows     AFTER FILTER workflows.length: " + workflows.length);

},
addWorkflow : function (workflowObject) {
// ADD AN EMPTY NEW WORKFLOW OBJECT TO A PROJECT OBJECT
	console.log("Agua.Workflow.addWorkflow    plugins.workflow.Agua.addWorkflow(workflowObject)");
	console.log("Agua.Workflow.addWorkflow    workflowObject: " + dojo.toJson(workflowObject));
	
	var projectName = workflowObject.project;
	var workflowName = workflowObject.name;
	if ( this.isWorkflow(workflowObject)== true )
	{
		console.log("Agua.Workflow.addWorkflow    Workflow '" + workflowName + "' already exists in project '" + projectName + "'. Returning.");
		return;
	}

    // SET THE WORKFLOW NUMBER
	var maxNumber = this.getMaxWorkflowNumber(projectName);
    console.log("Agua.Workflow.addWorkflow    maxNumber: " + maxNumber);

	var number;
	if ( maxNumber == null )
		number = 1;
	else
		number = maxNumber + 1;
	workflowObject.number = number;
    console.log("Agua.Workflow.addWorkflow    workflowObject.number: " + workflowObject.number);

	var added = this._addWorkflow(workflowObject);
	if ( added == false )
	{
		console.log("Agua.Workflow.addWorkflow    Could not add workflow " + workflowName + " to workflows");
		return;
	}
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.project = projectName;
	query.name = workflowName;
	query.number = number;
	query.username = this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode = "addWorkflow";
	query.module 		= 	"Agua::Workflow";
	console.log("Agua.Workflow.addWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });
},
_addWorkflow : function(workflowObject) {
	var keys = ["project", "name", "number"];
	var added = this.addData("workflows", workflowObject, keys);
},
removeWorkflow : function (workflowObject) {
// REMOVE A WORKFLOW FROM workflows, stages AND stageparameters
	console.log("Agua.Workflow.removeWorkflow    caller: " + this.removeWorkflow.caller.nom);
	console.log("Agua.Workflow.removeWorkflow    workflowObject: " + dojo.toJson(workflowObject));

	// REMOVE WORKFLOW
	this._removeWorkflow(workflowObject);
	
	// RENUMBER WORKFLOWS
	this.renumberWorkflows(workflowObject.project);
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url 		= Agua.cgiUrl + "agua.cgi";
	var query 		= new Object;
	query.project 	= workflowObject.project;
	query.name 		= workflowObject.name;
	query.username 	= this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode 		= "removeWorkflow";
	query.module 		= 	"Agua::Workflow";
	console.log("Agua.Workflow.removeWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });
},
_removeWorkflow : function(workflowObject) {
// REMOVE FROM workflows, stages, ETC.
	console.log("Agua.Workflow._removeWorkflow    BEFORE delete workflows.length: " + this.getWorkflows().length);

	var keys = ["project", "name"];
	var result = this.removeData("workflows", workflowObject, keys);

	console.log("Agua.Workflow._removeWorkflow    delete result: " + result);
	console.log("Agua.Workflow._removeWorkflow    AFTER delete workflows.length: " + this.getWorkflows().length);
	
	// REMOVE FROM stages, stageparameters AND views
	workflowObject.workflow = workflowObject.name;
	keys = ["project", "workflow"];
	this.removeObjectsFromData("stages", workflowObject, keys);
	this.removeObjectsFromData("stageparameters", workflowObject, keys);

},
renameWorkflow : function (workflowObject, newName, callback, standby) {
// RENAME A WORKFLOW FROM workflows, stages AND stageparameters
	console.log("Agua.Workflow.renameWorkflow    plugins.core.Data.renameWorkflow(workflowObject, newName)");
	console.log("Agua.Workflow.renameWorkflow    workflowObject: " + dojo.toJson(workflowObject));
	console.log("Agua.Workflow.renameWorkflow    newName: " + newName);
	console.log("Agua.Workflow.renameWorkflow    callback: " + callback);

	if ( workflowObject.name == null )	return;
	if ( workflowObject.project == null )	return;
	if ( newName == null )	return;

	// COPY WORKFLOW DATA TO NEW WORKFLOW NAMES
	var username = this.cookie("username");
	var date = this.currentMysqlDate();
	this._copyWorkflow(workflowObject, username, workflowObject.project, newName, date, workflowObject.number);
	
	// DELETE OLD WORKFLOW
	this._removeWorkflow(workflowObject);

	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.project = workflowObject.project;
	query.name = workflowObject.name;
	query.newname = newName;
	query.username = this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode = "renameWorkflow";
	query.module 		= 	"Agua::Workflow";
	console.log("Agua.Workflow.renameWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false, callback: callback });
},
copyWorkflow : function (sourceUser, sourceProject, sourceWorkflow, targetUser, targetProject, targetWorkflow, copyFiles) {
// ADD AN EMPTY NEW WORKFLOW OBJECT TO A PROJECT OBJECT
	console.log("Agua.Workflow.copyWorkflow    plugins.workflow.Agua.copyWorkflow(sourceUser, sourceProject, sourceWorkflow, targetUser, targetProject, targetWorkflow)");
	console.log("Agua.Workflow.copyWorkflow    sourceUser: " + sourceUser);
	console.log("Agua.Workflow.copyWorkflow    sourceProject: " + sourceProject);
	console.log("Agua.Workflow.copyWorkflow    sourceWorkflow: " + sourceWorkflow);
	console.log("Agua.Workflow.copyWorkflow    targetUser: " + targetUser);
	console.log("Agua.Workflow.copyWorkflow    targetProject: " + targetProject);
	console.log("Agua.Workflow.copyWorkflow    targetWorkflow: " + targetWorkflow);
	console.log("Agua.Workflow.copyWorkflow    copyFiles: " + copyFiles);

	if ( this.isWorkflow({ project: targetProject, name: targetWorkflow })== true )
	{
		console.log("Agua.Workflow.copyWorkflow    Workflow " + targetWorkflow + " already exists in project " + targetProject + ". Returning FALSE.");
		return false;
	}

	var workflows = this.getSharedWorkflowsByProject(sourceUser, sourceProject);
	workflows = this.filterByKeyValues(workflows, ["name"], [sourceWorkflow]);
	if ( ! workflows || workflows.length == 0 ) {
		console.log("Agua.Workflow.copyWorkflow    Returning because workflows is not defined or empty");
		return;
	}
	var workflowObject = workflows[0];
	
	// ADD STAGES, STAGEPARAMETERS, REPORTS AND VIEWS	
	var date = this.currentMysqlDate();
	var success = this._copyWorkflow(workflowObject, targetUser, targetProject, targetWorkflow, date);
	if ( success == false )	{
		console.log("Agua.Workflow.copyWorkflow    Failed to copy workflow: " + dojo.toJson(workflowObject));
		return false;
	}	

	// SET PROVENANCE
	workflowObject = this.setProvenance(workflowObject, date);

	// COMMIT CHANGES TO REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.sourceuser 		= 	sourceUser;
	query.targetuser 		= 	targetUser;
	query.sourceworkflow 	= 	sourceWorkflow;
	query.sourceproject 	= 	sourceProject;
	query.targetworkflow 	= 	targetWorkflow;
	query.targetproject 	= 	targetProject;
	query.copyfiles 		= 	copyFiles;
	query.date				= 	date;
	query.provenance 		= 	workflowObject.provenance;
	query.username 			= 	this.cookie("username");
	query.sessionid 		= 	this.cookie("sessionid");
	query.mode 				= 	"copyWorkflow";
	query.module 		= 	"Agua::Workflow";
	console.log("Agua.Workflow.copyWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });

	return success;
},
_copyWorkflow : function (workflowObject, targetUser, targetProject, targetWorkflow, date, workflowNumber) {
// COPY WORKFLOW AND THEN ADD STAGES, STAGEPARAMETERS, REPORTS AND VIEWS	
	console.log("XXXXXXXXXXXX Data._copyWorkflow    Data._copyWorkflow(sourceUser, sourceProject, sourceWorkflow, targetUser, targetProject, targetWorkflow, copyFiles, workflowNumber)");
	console.log("Agua.Workflow._copyWorkflow    BEFORE workflowObject: " + dojo.toJson(workflowObject));
	console.dir({workflowObject:workflowObject});
	console.log("Agua.Workflow._copyWorkflow    BEFORE workflowObject.name: " + workflowObject.name);
	console.log("Agua.Workflow._copyWorkflow    targetUser: " + targetUser);
	console.log("Agua.Workflow._copyWorkflow    targetProject: " + targetProject);
	console.log("Agua.Workflow._copyWorkflow    targetWorkflow: " + targetWorkflow);
	console.log("Agua.Workflow._copyWorkflow    date: " + date);

	// GET SOURCE DATA
	var sourceUser = workflowObject.username;
	var sourceWorkflow = workflowObject.name;
	var sourceProject = workflowObject.project;
	console.log("Agua.Workflow._copyWorkflow    sourceWorkflow: " + sourceWorkflow);
	
	// SET PROVENANCE
	workflowObject = this.setProvenance(workflowObject, date);
	
	// SET TARGET DATA
	var maxNumber = this.getMaxWorkflowNumber(targetProject);
	var number;
	if ( workflowNumber ) {
		number = workflowNumber;
	}
	else {
		if ( ! maxNumber )
			number = 1;
		else
			number = maxNumber + 1;
	}
	
	var newObject = dojo.clone(workflowObject);
	newObject.name = targetWorkflow;
	newObject.project = targetProject;
	newObject.username = targetUser;
	newObject.number = number;
	console.log("Agua.Workflow._copyWorkflow    AFTER newObject: ");
	console.dir({newObject:newObject});
	console.dir({workflowObject:workflowObject});
	
	// COPY WORKFLOW
	var keys = ["project", "name"];
	var copied = this.addData("workflows", newObject, keys);
	if ( copied == false ) {
		console.log("Agua.Workflow._copyWorkflow    Could not copy workflow to targetWorkflow: " + targetWorkflow);
		return false;
	}

	// COPY STAGES AND STAGE PARAMETERS
	var stages;
	if ( sourceUser != targetUser )
		stages = this.getSharedStagesByWorkflow(sourceUser, sourceProject, sourceWorkflow);
	else stages = this.getStagesByWorkflow(sourceProject, sourceWorkflow);
	console.log("Agua.Workflow._copyWorkflow    stages.length: " + stages.length);

	for ( var i = 0; i < stages.length; i++ ) {
	 	console.log("Agua.Workflow._copyWorkflow    stages[" + i + "]: " + stages[i]);
		var newStage = dojo.clone(stages[i]);
		newStage.project = targetProject;
		newStage.workflow = targetWorkflow;
		
		this._addStage(newStage);

		// ADD STAGE PARAMETERS
		var stageparams;
		if ( sourceUser != targetUser )
			stageparams = this.getSharedStageParameters(stages[i]);
		else stageparams = this.getStageParameters(stages[i]);
		
		console.log("Agua.Workflow._copyWorkflow    stageparams.length: " + stageparams.length);
		var thisObject = this;
		var oldPath = sourceProject + "/" + sourceWorkflow;
		var newPath = targetProject + "/" + targetWorkflow;
		dojo.forEach(stageparams, function(stageparam, j){
			stageparams[j].project = targetProject;
			stageparams[j].workflow = targetWorkflow;
		
			// REPLACE FILE PATH WITH NEW Project/Workflow
			if ( stageparams[j].value != null
				&& stageparams[j].value.replace )
				stageparams[j].value = stageparams[j].value.replace(oldPath, newPath);
			
			thisObject._addStageParameter(stageparams[j]);
		})
	}

	// COPY VIEWS
	var views = this.getSharedViews({ username: sourceUser, project: sourceProject } );
    if ( views == null )
        views = [];
	//console.log("Agua.Workflow._copyWorkflow    view: " + dojo.toJson(views));
	for ( var i = 0; i < views.length; i++ )
	{
		this._addStage(views[i]);
	}

	//console.log("Agua.Workflow._copyWorkflow    views: " + dojo.toJson(views));
	return true;
},
getWorkflowSubmit : function (workflowObject) {
	if ( ! workflowObject )	return;

	var submit = 0;	
	var stages = this.getStagesByWorkflow(workflowObject.project, workflowObject.workflow);
	if ( ! stages )	return 1;
	
	for ( var i = 0; i < stages.length; i++ ) {
		if ( stages[i].submit == 1 )	return 1;
	}
	
	return 0;
},
// PROVENANCE METHODS
setProvenance : function (object, date) {
	var provenanceString = object.provenance;
	var provenance;
	if ( ! provenanceString )
		provenance = [];
	else
		provenance = dojo.fromJson(provenanceString);
	
	if ( ! date ) date = this.currentMysqlDate();
	var item = {
		copiedby : Agua.cookie("username"),
		original: dojo.clone(object),
		date: date
	};
	
	provenance.push(item);
	provenanceString = dojo.toJson(provenance);
	
	object.provenance = provenanceString;
	
	return object;
}

});