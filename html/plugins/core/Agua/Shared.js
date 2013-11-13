dojo.provide("plugins.core.Agua.Shared");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	SHARED METHODS  
*/

dojo.declare( "plugins.core.Agua.Shared",	[  ], {

/////}}}

getSharedSources : function () {
// RETURN A COPY OF sharedsources
	//console.log("Agua.Shared.getSharedSources    plugins.core.Data.getSharedSources()");
	return this.cloneData("sharedsources");
},
getSharedSourcesByUsername : function(username) {
/// RETURN ALL SHARED PROJECTS PROVIDED BY THE SPECIFIED USER
	//console.log("Agua.Shared.getSharedSourcesByUsername    username: " + username);
	
	var sharedSources = this.cloneData("sharedsources");
	//console.log("Agua.Shared.getSharedSourcesByUsername    BEFORE sharedSources: " + dojo.toJson(sharedSources));

	if ( ! sharedSources || ! sharedSources[username] )	return [];
	else return sharedSources[username];
},
getSharedUsernames : function() {
// RETURN AN ARRAY OF ALL OF THE NAMES OF USERS WHO HAVE SHARED PROJECTS
// WITH THE LOGGED ON USER
	console.log("Agua.Shared.getSharedUsernames    plugins.core.Data.getSharedUsernames()");

	var sharedProjects = this.getSharedProjects();	
	var usernames = new Array;
	for ( var name in sharedProjects ) {
		usernames.push(name);
	}
	usernames = usernames.sort();
	console.log("Agua.Shared.getSharedUsernames    usernames: " + dojo.toJson(usernames));

	return usernames;
},
getSharedProjects : function() {
	console.log("Agua.Shared.getSharedProjects    plugins.core.Data.getSharedProjects()");	
	var sharedProjects = this.cloneData("sharedprojects");
	console.log("Agua.Shared.getSharedProjects    sharedProjects: ");
	console.dir({sharedProjects:sharedProjects});

	return sharedProjects;
},
getSharedProjectsByUsername : function(username) {
/// RETURN ALL SHARED PROJECTS PROVIDED BY THE SPECIFIED USER
	//console.log("Agua.Shared.getSharedProjectsByUsername    username: " + username);
	
	var sharedProjects = this.cloneData("sharedprojects");
	//console.log("Agua.Shared.getSharedProjectsByUsername    BEFORE sharedProjects: " + dojo.toJson(sharedProjects));

	if ( ! sharedProjects || ! sharedProjects[username] )	return [];
	else return sharedProjects[username];
},
getSharedStagesByUsername : function(username) {
// RETURN AN ARRAY OF STAGES SHARED BY THE USER
	var sharedStages = this.cloneData("sharedstages");
	if ( sharedStages == null || sharedStages[username] == null )	return [];
	else return sharedStages[username];
},
getSharedWorkflowsByProject : function(username, project) {
// RETURN AN ARRAY OF ALL OF THE NAMES OF USERS WHO HAVE SHARED PROJECTS
// WITH THE LOGGED ON USER

	console.log("Agua.Shared.getSharedWorkflowsByProject    plugins.core.Data.getSharedWorkflowsByProject(username, project)");		
	console.log("Agua.Shared.getSharedWorkflowsByProject    username: " + username);
	console.log("Agua.Shared.getSharedWorkflowsByProject    project: " + project);

	var sharedWorkflows = this.cloneData("sharedworkflows") || [];
	sharedWorkflows = sharedWorkflows[username] || [];
	console.dir({sharedWorkflows:sharedWorkflows});
	sharedWorkflows = this.filterByKeyValues(sharedWorkflows, ["project"], [project]);
	console.log("Agua.Shared.getSharedWorkflowsByProject    sharedWorkflows: ");
	console.dir({sharedWorkflows:sharedWorkflows});

	return sharedWorkflows;
},
getSharedStagesByWorkflow : function(username, project, workflow) {
// RETURN AN ARRAY OF ALL OF THE NAMES OF USERS WHO HAVE SHARED PROJECTS
// WITH THE LOGGED ON USER

	console.log("Agua.Shared.getSharedStagesByWorkflow    plugins.core.Data.getSharedStagesByWorkflow(username, project, workflow)");		
	console.log("Agua.Shared.getSharedStagesByWorkflow    username: " + username);
	console.log("Agua.Shared.getSharedStagesByWorkflow    project: " + project);
	console.log("Agua.Shared.getSharedStagesByWorkflow    workflow: " + workflow);
	
	var sharedStages = this.getSharedStagesByUsername(username);
	console.log("Agua.Shared.getSharedStagesByWorkflow    BEFORE FILTER PROJECT, sharedStages: ");
	console.dir({sharedStages:sharedStages});
	sharedStages = this.filterByKeyValues(sharedStages, ["project"], [project]);

	console.log("Agua.Shared.getSharedStagesByWorkflow    BEFORE FILTER WORKFLOW, sharedStages: ");
	console.dir({sharedStages:sharedStages});

	sharedStages = this.filterByKeyValues(sharedStages, ["workflow"], [workflow]);
	console.log("Agua.Shared.getSharedStagesByWorkflow    AFTER sharedStages: ");
	console.dir({sharedStages:sharedStages});

	return sharedStages;
},
getSharedStageParameters : function (stageObject) {
// RETURN AN ARRAY OF STAGE PARAMETER HASHARRAYS FOR A STAGE
	//console.log("Agua.Shared.getSharedStageParameters    plugins.core.Data.getSharedStageParameters(stageObject)");
	//console.log("Agua.Shared.getSharedStageParameters    stageObject: " + dojo.toJson(stageObject));
	
	var keys = ["username", "project", "workflow", "name", "number"];
	var notDefined = this.notDefined (stageObject, keys);
	console.log("Agua.Shared.getSharedStageParameters    notDefined: " + dojo.toJson(notDefined));
	if ( notDefined.length != 0 )
	{
		console.log("Agua.Shared.getSharedStageParameters    not defined: " + dojo.toJson(notDefined));
		return;
	}
	var username = stageObject.username;
	var sharedStageParameters = this.cloneData("sharedstageparameters");
	if ( sharedStageParameters == null || sharedStageParameters[username] == null )	return [];
	var stageParameters = sharedStageParameters[username];
	//console.log("Agua.Shared.getSharedStageParameters    BEFORE stageParameters: " + dojo.toJson(stageParameters, true));
	
	// ADD appname AND appnumber FOR STAGE PARAMETER IDENTIFICATION
	stageObject.appname = stageObject.name;
	stageObject.appnumber = stageObject.number;
	
	var keyArray = ["username", "project", "workflow", "appname", "appnumber"];
	var valueArray = [stageObject.username, stageObject.project, stageObject.workflow, stageObject.name, stageObject.number];
	stageParameters = this.filterByKeyValues(stageParameters, keyArray, valueArray);
	
	//console.log("Agua.Shared.getSharedStageParameters    AFTER  stageParameters: " + dojo.toJson(stageParameters));

	return stageParameters;
},
getSharedViews : function (viewObject) {
// RETURN AN ARRAY OF VIEWS IN THE SHARED PROJECT
	console.log("Agua.Shared.getSharedViews    plugins.core.Data.getSharedViews(viewObject)");
	console.log("Agua.Shared.getSharedViews    viewObject: " + dojo.toJson(viewObject));
	
	var keys = ["project", "username"];
	var notDefined = this.notDefined (viewObject, keys);
	console.log("Agua.Shared.getSharedViews    notDefined: " + dojo.toJson(notDefined));
	if ( notDefined.length != 0 )
	{
		console.log("Agua.Shared.getSharedViews    not defined: " + dojo.toJson(notDefined));
		return;
	}

	var username = viewObject.username;
	var sharedViews = this.cloneData("sharedsharedViews");
	if ( sharedViews == null || sharedViews[username] == null )	return [];
	var views = sharedViews[username];
	console.log("Agua.Shared.getSharedViews    BEFORE views: " + dojo.toJson(views, true));	
	
	var keyArray = ["project", "username"];
	var valueArray = [viewObject.username, viewObject.project, viewObject.workflow, viewObject.name, viewObject.number];
	views = this.filterByKeyValues(views, keyArray, valueArray);
	
	console.log("Agua.Shared.getSharedViews    AFTER  views: " + dojo.toJson(views));

	return views;
}


});