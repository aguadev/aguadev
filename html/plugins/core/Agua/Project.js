dojo.provide("plugins.core.Agua.Project");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	PROJECT METHODS  
*/

dojo.declare( "plugins.core.Agua.Project",	[  ], {

/////}}}

// PROJECT METHODS
getProjects : function () {
// RETURN A SORTED COPY OF 
	//console.log("Agua.Project.getProjects    plugins.core.Data.getProjects(projectObject)");
	var projects = this.cloneData("projects");
	return this.sortHasharray(projects, "name");
},
getProjectNames : function (projects) {
// RETURN AN ARRAY OF ALL PROJECT NAMES IN projects
	console.log("Agua.Project.getProjectNames    projects: ");
	console.dir({projects:projects});
	if ( projects == null )	projects = this.getProjects();
	return this.hashArrayKeyToArray(projects, "name");
},
addProject : function (projectObject) {
// ADD A PROJECT OBJECT TO THE projects ARRAY

	console.log("Agua.Project.addProject    plugins.core.Data.addProject(projectName)");
	console.log("Agua.Project.addProject    projectObject: " + dojo.toJson(projectObject));
	projectObject.description = projectObject.description || "";
	projectObject.notes = projectObject.notes || "";

	console.log("Agua.Project.addProject    this.addingProject: " + this.addingProject);
	if ( this.addingProject == true )	return;
	this.addingProject == true;
	
	this.removeData("projects", projectObject, ["name"]);
	
	if ( ! this.addData("projects", projectObject, ["name" ]) )
	{
		console.log("Agua.Project.addProject    Could not add project to projects: " + projectName);
		this.addingProject == false;
		return;
	}
	this.sortData("projects", "name");
	this.addingProject == false;
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	
	// SET QUERY
	var query = dojo.clone(projectObject);
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"addProject";
	query.module 		= 	"Agua::Workflow";
	console.log("Agua.Project.addProject    query: " + dojo.toJson(query, true));
	
	this.doPut({ url: url, query: query, sync: false });
},
copyProject : function (sourceUser, sourceProject, targetUser, targetProject, copyFiles) {
// ADD AN EMPTY NEW WORKFLOW OBJECT TO A PROJECT OBJECT

	console.log("Agua.Project.copyProject    plugins.folders.Agua.copyProject(sourceUser, sourceProject, sourceProject, targetUser, targetProject, targetProject)");
	console.log("Agua.Project.copyProject    sourceUser: " + sourceUser);
	console.log("Agua.Project.copyProject    sourceProject: " + sourceProject);
	console.log("Agua.Project.copyProject    targetUser: " + targetUser);
	console.log("Agua.Project.copyProject    targetProject: " + targetProject);
	console.log("Agua.Project.copyProject    copyFiles: " + copyFiles);

	if ( this.isProject(targetProject) == true )
	{
		console.log("Agua.Project.copyProject    Project '" + targetProject + "' already exists. Returning.");
		return;
	}

	// GET PROJECT
	var projects = this.getSharedProjectsByUsername(sourceUser);
	console.log("Agua.Project.copyProject    projects: " + dojo.toJson(projects));
	projects = this.filterByKeyValues(projects, ["name"], [sourceProject]);
	console.log("Agua.Project.copyProject    FILTERED projects: " + dojo.toJson(projects));
	
	if ( ! projects || projects.length == 0 ) {
		console.log("Agua.Project.copyProject    Returning becacuse  projects is null or empty: " + dojo.toJson(projects));
	}
	var projectObject = projects[0];
	
	// SET PROVENANCE
	var date = this.currentMysqlDate();
	projectObject = this.setProvenance(projectObject, date);
	
	// SET TARGET VARIABLES
	projectObject.name = targetProject;
	projectObject.project  = targetProject;
	projectObject.username = targetUser;
	console.dir({projectObject:projectObject});
	var keys = ["name"];
	var copied = this.addData("projects", projectObject, keys);
	if ( copied == false )
	{
		console.log("Agua.Project.copyProject    Could not copy project " + projectObject.name + " to projects");
		return;
	}
	
	// COPY WORKFLOWS
	var workflows = this.getSharedWorkflowsByProject(sourceUser, sourceProject);
	for ( var i = 0; i < workflows.length; i++ ) {
		var sourceWorkflow = workflows[i].name;
		console.log("Agua.Project.copyProject    workflows[" + i + "]: " + dojo.toJson(workflows[i]));
		this._copyWorkflow(workflows[i], targetUser, targetProject, sourceWorkflow, date);
	}

	// COMMIT CHANGES TO REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.sourceuser 	= 	sourceUser;
	query.targetuser 	= 	targetUser;
	query.sourceproject = 	sourceProject;
	query.targetproject = 	targetProject;
	query.copyfiles 	= 	copyFiles;
	query.date			= 	date;
	query.provenance 	= 	projectObject.provenance;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"copyProject";
	query.module 		= 	"Agua::Workflow";
	console.log("Agua.Project.copyProject    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });
},
removeProject : function (projectObject) {
// REMOVE A PROJECT OBJECT FROM: projects, workflows, groupmembers
// stages AND stageparameters
	console.log("Agua.Project.removeProject    plugins.core.Data.removeProject(projectObject)");
	console.log("Agua.Project.removeProject    projectObject: " + dojo.toJson(projectObject));
	
	// SET ADDITIONAL FIELDS
	projectObject.project = projectObject.name;
	projectObject.owner = this.cookie("username");
	projectObject.type = "project";

	// REMOVE PROJECT FROM projects
	var success = this.removeData("projects", projectObject, ["name"]);
	if ( success == true )	console.log("Agua.Project.removeProject    Removed project from projects: " + projectObject.name);
	else	console.log("Agua.Project.removeProject    Could not remove project from projects: " + projectObject.name);
	
	// REMOVE FROM workflows
	this.removeData("workflows", projectObject, ["project"]);

	// REMOVE FROM groupmembers 
	var keys = ["owner", "name", "type"];
	this.removeData("groupmembers", projectObject, keys);

	// REMOVE FROM stages AND stageparameters
	var keys = ["project"];
	this.removeData("stages", projectObject, keys);

	// REMOVE FROM stageparameters
	var keys = ["project"];
	this.removeData("stageparameters", projectObject, keys);
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi";
	var query = projectObject;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"removeProject";
	query.module 		= 	"Agua::Workflow";
	console.log("Agua.Project.removeProject    query: " + dojo.toJson(query, true));
	
	this.doPut({ url: url, query: query, sync: false });
},
isProject : function (projectName) {
// RETURN true IF A PROJECT EXISTS IN projects
	//console.log("Agua.Project.isProject    core.Data.isProject(projectName)");
	//console.log("Agua.Project.isProject    projectName: " + projectName);

	var projects = this.getProjects();
	for ( var i in projects )
	{
		var project = projects[i];
		if ( project.name.toLowerCase() == projectName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
},
isGroupProject : function (groupName, projectObject) {
// RETURN true IF A PROJECT BELONGS TO THE SPECIFIED GROUP

	console.log("Agua.Project.isGroupProject    plugins.core.Data.isGroupProject(groupName, projectObject)");
	console.log("Agua.Project.isGroupProject    groupName: " + groupName);
	console.log("Agua.Project.isGroupProject    projectObject: " + dojo.toJson(projectObject));
	
	var groupProjects = this.getGroupProjects();
	if ( groupProjects == null )	return false;
	
	groupProjects = this.filterByKeyValues(groupProjects, ["groupname"], [groupName]);
	
	return this._objectInArray(groupProjects, projectObject, ["groupname", "name"]);
},
addProjectToGroup : function (groupName, projectObject) {
// ADD A PROJECT OBJECT TO A GROUP ARRAY IF IT DOESN"T EXIST THERE ALREADY 

	console.log("Agua.Project.addProjectToGroup    caller: " + this.addProjectToGroup.caller.nom);
	console.log("Agua.Project.addProjectToGroup    groupName: " + groupName);
	console.log("Agua.Project.addProjectToGroup    projectObject: " + dojo.toJson(projectObject));

	if ( this.isGroupProject(groupName, projectObject) == true )
	{
		console.log("Agua.Project.addProjectToGroup     project already exists in projects: " + projectObject.name + ". Returning.");
		return false;
	}
	
	projectObject.owner = projectObject.username;
	projectObject.groupname = groupName;
	projectObject.type = "project";

	var groups = this.getGroups();
	console.log("Agua.Project.addProjectToGroup    groups: " + dojo.toJson(groups));
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	if ( group == null )	return false;
	console.log("Agua.Project.addProjectToGroup    group: " + dojo.toJson(group));
	projectObject.groupdesc = group.description;

	console.log("Agua.Project.addProjectToGroup    New projectObject: " + dojo.toJson(projectObject));

	var requiredKeys = ["owner", "groupname", "name", "type"];
	return this.addData("groupmembers", projectObject, requiredKeys);
},
removeProjectFromGroup : function (groupName, projectObject) {
// REMOVE A PROJECT OBJECT FROM A GROUP ARRAY, IDENTIFY OBJECT BY "name" KEY VALUE

	console.log("Agua.Project.removeProjectFromGroup     caller: " + this.removeProjectFromGroup.caller.nom);
	console.log("Agua.Project.removeProjectFromGroup     groupName: " + groupName);
	console.log("Agua.Project.removeProjectFromGroup     projectObject: " + dojo.toJson(projectObject));
	
	projectObject.owner = projectObject.username;
	projectObject.groupname = groupName;
	projectObject.type = "project";

	// REMOVE THIS LATER		
	var groups = this.getGroups();
	console.log("Agua.Project.removeProjectFromGroup    groups: " + dojo.toJson(groups));
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	if ( group == null )	return false;
	console.log("Agua.Project.removeProjectFromGroup    group: " + dojo.toJson(group));
	projectObject.groupdesc = group.description;

	var requiredKeys = [ "owner", "groupname", "name", "type"];
	return this.removeData("groupmembers", projectObject, requiredKeys);
},
getProjectsByGroup : function (groupName) {
// RETURN THE ARRAY OF PROJECTS THAT BELONG TO A GROUP

	var groupProjects = this.getGroupProjects();
	if ( groupProjects == null )	return null;

	var keyArray = ["groupname"];
	var valueArray = [groupName];
	var projects = this.filterByKeyValues(groupProjects, keyArray, valueArray);

	return this.sortHasharray(projects, "name");
},
getGroupsByProject : function (projectName) {
// RETURN THE ARRAY OF PROJECTS THAT BELONG TO A GROUP

	var groupProjects = this.getGroupProjects();
	if ( groupProjects == null )	return null;

	var keyArray = ["type", "name"];
	var valueArray = ["project", projectName];
	return this.filterByKeyValues(groupProjects, keyArray, valueArray);
}

});