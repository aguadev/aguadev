dojo.provide("plugins.core.Common.ComboBox");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	COMBOBOX METHODS  
*/

dojo.require("dojo.store.Memory");

dojo.declare( "plugins.core.Common.ComboBox",	[  ], {

///////}}}
// COMBOBOX METHODS
createStore : function (itemArray) {
	var data = [];
	for ( var i in itemArray ) {
		data.push({ name: itemArray[i]	});
	}
	
	return new dojo.store.Memory({	idProperty: "name", data: data	});
},
setUsernameCombo : function () {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: Agua.sharedprojects DATA OBJECT
//	OUTPUTS:	ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedProjectCombo
	//console.log("  Common.ComboBox.setUsernameCombo    plugins.core.Common.setUsernameCombo()");
	var itemArray = Agua.getSharedUsernames();
	//console.log("  Common.ComboBox.setUsernameCombo    itemArray: " + dojo.toJson(itemArray));

	// RETURN IF projects NOT DEFINED
	if ( itemArray == null || itemArray.length == 0 )
	{
		//console.log("  Common.ComboBox.setUsernameCombo    itemArray not defined. Returning.");
		return;
	}

	// CREATE STORE
	var store 	=	this.createStore(itemArray);
	//console.log("   Common.setUsernameCombo    store: " + dojo.toJson(store));

	// ADD STORE TO USERNAMES COMBO
	this.usernameCombo.store = store;	
	
	// START UP AND SET VALUE
	this.usernameCombo.startup();
	this.usernameCombo.set('value', itemArray[0]);			
},
setSharedProjectCombo : function (username, projectName, workflowName) {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: USERNAME, OPTIONAL PROJECT NAME AND WORKFLOW NAME
//	OUTPUTS: ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedWorkflowCombo

	//console.log("  Common.ComboBox.setSharedProjectCombo    plugins.report.Workflow.setSharedProjectCombo(username, project, workflow)");

	var projects = Agua.getSharedProjectsByUsername(username);
	if ( projects == null ) {
		//console.log("   Common.setSharedProjectCombo    projects is null. Returning");
		return;
	}
	//console.log("  Common.ComboBox.setSharedProjectCombo    projects: " + dojo.toJson(projects));
	
	var itemArray = this.hashArrayKeyToArray(projects, "name");
	itemArray = this.uniqueValues(itemArray);
	//console.log("  Common.ComboBox.setSharedProjectCombo    itemArray: " + dojo.toJson(itemArray));
	
	// RETURN IF projects NOT DEFINED
	if ( itemArray == null || itemArray.length == 0 ) {
		//console.log("  Common.ComboBox.setSharedProjectCombo    itemArray not defined. Returning.");
		return;
	}

	// CREATE STORE
	var store = this.createStore(itemArray);
	//console.log("  Common.ComboBox.setSharedProjectCombo    store: " + dojo.toJson(store));

	// ADD STORE TO USERNAMES COMBO
	this.projectCombo.store = store;	
	
	// START UP AND SET VALUE
	this.projectCombo.startup();
	this.projectCombo.set('value', itemArray[0]);	
},
setSharedWorkflowCombo : function (username, projectName, workflowName) {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: USERNAME, OPTIONAL PROJECT NAME AND WORKFLOW NAME
//	OUTPUTS: ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedWorkflowCombo

	console.log("  Common.ComboBox.setSharedWorkflowCombo    plugins.report.Workflow.setSharedWorkflowCombo(username, project, workflow)");
	console.log("  Common.ComboBox.setSharedWorkflowCombo    projectName: " + projectName);
				
	if ( projectName == null )	projectName = this.projectCombo.get('value');
	console.log("  Common.ComboBox.setSharedWorkflowCombo    AFTER projectName: " + projectName);

	var workflows = Agua.getSharedWorkflowsByProject(username, projectName);
	if ( workflows == null ) {
		console.log("  Common.ComboBox.setSharedWorkflowCombo    workflows is null. Returning");
		return;
	}
	console.log("  Common.ComboBox.setSharedWorkflowCombo    workflows: ");
	console.dir({workflows:workflows});
	
	var itemArray = this.hashArrayKeyToArray(workflows, "name");
	itemArray = this.uniqueValues(itemArray);
	console.log("  Common.ComboBox.setSharedWorkflowCombo    itemArray: " + dojo.toJson(itemArray));
	
	// RETURN IF workflows NOT DEFINED
	if ( itemArray == null || itemArray.length == 0 ) {
		console.log("  Common.ComboBox.setSharedWorkflowCombo    itemArray not defined. Returning.");
		return;
	}

	// CREATE STORE
	var store = this.createStore(itemArray);
	//console.log("  Common.ComboBox.setSharedWorkflowCombo    store: " + dojo.toJson(store));

	// ADD STORE TO USERNAMES COMBO
	this.workflowCombo.store = store;	
	
	// START UP AND SET VALUE
	this.workflowCombo.startup();
	this.workflowCombo.set('value', itemArray[0]);
},
setProjectCombo : function (project, workflow) {
//	INPUT: (OPTIONAL) project, workflow NAMES
//	OUTPUT:	POPULATE COMBOBOX AND SET SELECTED ITEM

	////console.log("  Common.ComboBox.setProjectCombo    plugins.report.Template.Common.setProjectCombo(project,workflow)");
	////console.log("  Common.ComboBox.setProjectCombo    project: " + project);
	////console.log("  Common.ComboBox.setProjectCombo    workflow: " + workflow);

	var itemArray = Agua.getProjectNames();
	////console.log("  Common.ComboBox.setProjectCombo    itemArray: " + dojo.toJson(itemArray));

	// RETURN IF projects NOT DEFINED
	if ( ! itemArray ) {
		//console.log("  Common.ComboBox.setProjectCombo    itemArray not defined. Returning.");
		return;
	}
	////console.log("  Common.ComboBox.setProjectCombo    projects: " + dojo.toJson(projects));

	// SET PROJECT IF NOT DEFINED TO FIRST ENTRY IN projects
	if ( project == null || ! project)	project = itemArray[0];
	
	// CREATE STORE
	var store = this.createStore(itemArray);
	//console.log("  Common.ComboBox.setSharedProjectCombo    store: " + dojo.toJson(store));

	//// GET PROJECT COMBO WIDGET
	var projectCombo = this.projectCombo;
	if ( projectCombo == null ) {
		//console.log("  Common.ComboBox.setProjectCombo    projectCombo is null. Returning.");
		return;
	}

	projectCombo.store = store;	
	////console.log("  Common.ComboBox.setProjectCombo    project: " + project);
	
	// START UP AND SET VALUE
	//projectCombo.startup();
	//console.log("  Common.ComboBox.setProjectCombo    projectCombo.set('value', " + project + ")");
	projectCombo.set('value', project);			
},
setWorkflowCombo : function (project, workflow) {
// SET THE workflow COMBOBOX
	if ( project == null || ! project ) {
		//console.log("  Common.ComboBox.setWorkflowCombo    Project not defined. Returning.");
		return;
	}
	//console.log("  Common.ComboBox.setWorkflowCombo    project: " + project);
	//console.log("  Common.ComboBox.setWorkflowCombo    workflow: " + workflow);

	// CREATE THE DATA FOR A STORE		
	var workflows = Agua.getWorkflowsByProject(project);
	//console.log("  Common.ComboBox.setWorkflowCombo    project '" + project + "' workflows: " + dojo.toJson(workflows));
	workflows = this.sortHasharrayByKeys(workflows, ["number"]);
	var itemArray = this.hashArrayKeyToArray(workflows, "name");
	
	// RETURN IF itemArray NOT DEFINED
	if ( ! itemArray ) {
		console.log("  Common.ComboBox.setWorkflowCombo    itemArray not defined. Returning.");
		return;
	}		

	// CREATE STORE
	var store = this.createStore(itemArray);

	// GET WORKFLOW COMBO
	var workflowCombo = this.workflowCombo;
	if ( workflowCombo == null ) {
		console.log("  Common.ComboBox.setworkflowCombo    workflowCombo is null. Returning.");
		return;
	}

	//console.log("  Common.ComboBox.setWorkflowCombo    workflowCombo: " + workflowCombo);
	workflowCombo.store = store;

	// START UP COMBO AND SET SELECTED VALUE TO FIRST ENTRY IN itemArray IF NOT DEFINED 
	if ( workflow == null || ! workflow )	workflow = itemArray[0];
	//console.log("  Common.ComboBox.setWorkflowCombo    workflow: " + workflow);

	workflowCombo.startup();
	workflowCombo.set('value', workflow);			
},
setReportCombo : function (project, workflow, report) {
// SET THE report COMBOBOX
	//console.log("  Common.ComboBox.setReportCombo    project: " + project);
	//console.log("  Common.ComboBox.setReportCombo    workflow: " + workflow);
	//console.log("  Common.ComboBox.setReportCombo    report: " + report);

	if ( project == null || ! project ) {
		console.log("  Common.ComboBox.setReportCombo    project not defined. Returning.");
		return;
	}
	if ( workflow == null || ! workflow ) {
		console.log("  Common.ComboBox.setReportCombo    workflow not defined. Returning.");
		return;
	}
	//console.log("  Common.ComboBox.setReportCombo    project: " + project);
	//console.log("  Common.ComboBox.setReportCombo    workflow: " + workflow);
	//console.log("  Common.ComboBox.setReportCombo    report: " + report);

	var itemArray = Agua.getReportsByWorkflow(project, workflow);
	if ( itemArray == null )	itemArray = [];
	console.log("  Common.ComboBox.setReportCombo    project " + project + " itemArray: " + dojo.toJson(itemArray));

	var reportNames = this.hashArrayKeyToArray(itemArray, "name");
	console.log("  Common.ComboBox.setReportCombo    reportNames: " + dojo.toJson(reportNames));
	
	// CREATE STORE
	var store = this.createStore(itemArray);

	// GET WORKFLOW COMBO
	var reportCombo = this.reportCombo;
	if ( reportCombo == null )
	{
		console.log("  Common.ComboBox.setreportCombo    reportCombo is null. Returning.");
		return;
	}

	console.log("  Common.ComboBox.setReportCombo    reportCombo: " + reportCombo);
	reportCombo.store = store;

	// GET USER INPUT WORKFLOW
	var snpReport = this;

	// START UP COMBO (?? NEEDED ??)
	reportCombo.startup();
	reportCombo.set('value', report);			
},
setViewCombo : function (projectName, viewName) {
// SET THE view COMBOBOX
	console.log("  Common.ComboBox.setViewCombo    projectName: " + projectName);
	console.log("  Common.ComboBox.setViewCombo    viewName: " + viewName);

	// SANITY CHECK
	if ( ! this.viewCombo )	return;
	if ( ! projectName )	return;

	var itemArray = Agua.getViewNames(projectName);

	console.log("  Common.ComboBox.setViewCombo    BEFORE SORT itemArray: ");
	console.dir({itemArray: itemArray});
	
	itemArray.sort(this.sortNaturally);

	console.log("View.setViewCombo    AFTER SORT itemArray: ");
	console.dir({itemArray:itemArray});
	
	// RETURN IF itemArray NOT DEFINED
	if ( ! itemArray || itemArray.length == 0 )	itemArray = [];
	//console.log("  Common.ComboBox.setViewCombo    itemArray: " + dojo.toJson(itemArray));

	// SET view IF NOT DEFINED TO FIRST ENTRY IN itemArray
	if ( ! viewName) {
		viewName = itemArray[0];
	}
	//console.log("  Common.ComboBox.setViewCombo    viewName: " + viewName);
	
	// CREATE STORE
	var store = this.createStore(itemArray);

	//console.log("  Common.ComboBox.setViewCombo    this.viewCombo: " + this.viewCombo);
	this.viewCombo.store = store;

	// START UP COMBO (?? NEEDED ??)
	this.viewCombo.startup();
	this.viewCombo.set('value', viewName);			
},
getSelectedValue : function (element) {
	var index = element.selectedIndex;
	//console.log("  Common.ComboBox.getSelectedValue    index: " + index);
	var value = element.options[index].text;
	//console.log("  Common.ComboBox.getSelectedValue    value: " + value);
	
	return value;
}



});