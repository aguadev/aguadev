dojo.provide("plugins.workflow.Grid");

dojo.require("dojo.parser");
dojo.require("dijit.form.ComboBox");
dojo.require("dojox.layout.GridContainer");

// HAS A
dojo.require("dijit.layout.BorderContainer");
dojo.require("plugins.workflow.GridWorkflow");
dojo.require("plugins.dijit.TitlePane");

// INHERITS
dojo.require("plugins.core.Common");

dojo.declare("plugins.workflow.Grid",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/grid.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "workflow/css/grid.css"),
	dojo.moduleUrl("dojo", "resources/dojo.css"),
	dojo.moduleUrl("dijit", "themes/tundra/tundra.css"),
	dojo.moduleUrl("dojox", "layout/resources/GridContainer.css"),
//	dojo.moduleUrl("dojox", "layout/resources/DndGridContainer.css")
],

// PARENT WIDGET
parentWidget : null,

// ARRAY OF CHILD WIDGETS
childWidgets : null,

// CORE WORKFLOW OBJECTS
core : null,

/////}
constructor : function(args) {
	console.log("Grid.constructor     plugins.workflow.Grid.constructor");		
	this.core = args.core;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	this.startup();
},
startup : function () {
// DO inherited, LOAD ARGUMENTS AND ATTACH THE MAIN TAB TO THE ATTACH NODE
	console.log("Grid.startup    plugins.workflow.Grid.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

//	console.log("Grid.startup    this.mainTab: " + this.mainTab);
//	console.log("Grid.startup    this.attachNode: " + this.attachNode);
//	console.dir({mainTab: this.mainTab});
// 	console.dir({attachNode: this.attachNode});

	// ADD TO TAB CONTAINER
	console.log("Grid.startup    Doing this.attachNode.addChild(this.mainTab)");
	this.attachNode.addChild(this.mainTab);

	console.log("Grid.startup    Doing this.attachNode.selectChild(this.mainTab)");
	this.attachNode.selectChild(this.mainTab);
	
	// SET CHILD WIDGETS
	this.childWidgets = new Array;
	
	// SET PROJECT COMBO
	this.setProjectCombo();
	//this.setProjectListeners();
	var thisObject = this;
	setTimeout(function(){thisObject.setProjectListeners();}, 100, this);

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateProjects");

	// SET DND SUBSCRIPTIONS
	this.setSubscriptions();
},
updateProjects : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.log("workflow.Stages.updateProjects    workflow.Stages.updateProjects(args)");
	console.log("workflow.Stages.updateProjects    args:");
	console.dir({args:args});

	this.setProjectCombo();
},

/////////////////	PROJECT METHODS      
getProject : function () {
	//console.log("Grid.getProject     plugins.workflow.Workflow.getProject()");

	//console.log("Grid.getProject     this: " + this);
	return this.projectCombo.get('value');
},
setProjectCombo : function (projectName) {
// POPULATE THE PROJECT COMBO AND THEN RELOAD THE WORKFLOW COMBO
	console.log("Grid.setProjectCombo    workflow.Stages.setProjectCombo(projectName)");


	// TO AVOID GRATUITOUS EVENT BY onChange LISTENER
	this.settingProject = true;
	
	//console.log("Grid.setProjectCombo    BEFORE this.inherited(arguments)");
	this.inherited(arguments);
	//console.log("Grid.setProjectCombo    AFTER this.inherited(arguments)");
	
	if ( projectName == null )
		projectName = this.projectCombo.getValue();
	//console.log("Grid.setProjectCombo    projectName: " + projectName);

	// RESET THE WORKFLOW COMBO
	//console.log("Grid.setProjectCombo    END. Doing this.setWorkflowCombo(projectName)");
	this.setWorkflows(projectName);
},
setProjectListeners : function () {
	//console.log("Grid.setProjectListeners    Stages.setProjectListeners()");

	// DOJO.CONNECT TO CHANGE THE workflowCombo
	var thisObject = this;
	dojo.connect(this.projectCombo, "onChange", dojo.hitch(this, function(event) {
		var project = event;
		console.log("Grid.setProjectListeners    onchange event. Doing this.setWorkflowCombo(" + project + ")");
		console.log("Grid.setProjectListeners    thisObject.settingProject: " + thisObject.settingProject);
	
		//// AVOID SELF-TRIGGERING OF onChange EVENT WHEN VALUE OF COMBO
		//// IS CHANGED PROGRAMMATICALLY
		//if ( thisObject.settingProject == true ){
		//	console.log("Grid.setProjectListeners    ONCHANGE fired. thisObject.settingProject is true. Returning");
		//	thisObject.settingProject = false;
		//	return;
		//}
		
		// SET WORKFLOW COMBO
		thisObject.setWorkflows(project);
	}));
},

/////////////////	WORKFLOW METHODS      
setWorkflows : function (projectName) {
	console.log("Grid.setWorkflows    plugins.workflow.Parameters.setWorkflows(projectName)");
	console.log("Grid.setWorkflows    projectName: " + projectName);
	//console.log("Grid.setWorkflows    this.mainPanel: " + this.mainPanel);
	//console.dir({mainPanel: this.mainPanel});
	
	// CLEAR GRID CONTAINER
	this.clearPanel(this.mainPanel);	

	var workflows = Agua.getWorkflowsByProject(projectName);
	//console.log("Grid.setWorkflows    BEFORE ORDER workflows: " + dojo.toJson(workflows));

	// ORDER BY WORKFLOW NUMBER -- NB: REMOVES ENTRIES WITH NO WORKFLOW NUMBER
	workflows = this.sortNumericHasharray(workflows, "number");		
	//console.log("Grid.setWorkflows    workflows.length:" + workflows.length);
	if ( workflows == null || workflows == [] )
	{
		//console.log("Grid.setWorkflows     workflows is null or empty. Returning.");
		return;
	}
	
	var thisObject = this;
	dojo.forEach(workflows, function(workflow, i) {
		////console.log("Grid.setWorkflows    **** workflow " + i + ":" + workflowName);
		var projectNumber = workflow.project;
		var workflowName = workflow.name;
		var workflowNumber = workflow.number;
		//console.log("Grid.setWorkflows    **** workflow " + i + ":" + workflowNumber + " " + workflowName);

		var stages = Agua.getStagesByWorkflow(projectName, workflowName);
		//if ( stages.length == 0 ) return;
		////console.log("Grid.setWorkflows    stages.length:" + stages.length);		

		var projectWorkflow = new plugins.workflow.GridWorkflow({
			title: workflowName,
			project: projectName,
			workflow: workflowName,
			number: workflowNumber,
			stages: stages,
			core: thisObject.core
		});

		thisObject.addChild(projectWorkflow);
	});	
},
addChild : function (projectWorkflow) {
	this.mainPanel.addChild(projectWorkflow);

	// PUSH ONTO ARRAY OF CHILD WIDGETS
	this.childWidgets.push(projectWorkflow);
},
setWorkflowStyles : function () {
	console.log("Grid.setWorkflowStyles     workflow.Parameters.setWorkflowStyles()");
	
	var parameterRows = this.childWidgets;
	var parameterHash = new Object;
	for ( var i = 0; i < parameterRows.length; i++ )
	{
		console.log("Grid.setWorkflowStyles     parameterRows[" + i + "]: "+ parameterRows[i]);
		console.log("Grid.setWorkflowStyles     " + parameterRows[i].name + ", parameterRows[" + i + "].paramtype: " + parameterRows[i].paramtype);
		if ( parameterRows[i].paramtype == "input" ) 
			parameterHash[parameterRows[i].name] = parameterRows[i];
	}
	console.dir(parameterHash);
	console.log("Grid.setWorkflowStyles     parameterHash:");
	//for ( var key in parameterHash )
	//{
	//	console.log(key + ": " + parameterHash[key]);
	//}

	console.log("Grid.setWorkflowStyles     this.application: " + dojo.toJson(this.application, true));
	var stageParameters = Agua.getStageParameters(this.application);
	console.log("Grid.setWorkflowStyles     stageParameters: " + dojo.toJson(stageParameters, true));
	console.log("Grid.setWorkflowStyles     stageParameters.length: " + stageParameters.length);
	for ( var i = 0; i < stageParameters.length; i++ )
	{
		if ( stageParameters[i].paramtype != "input" ) continue;

		var parameterRow = parameterHash[stageParameters[i].name];
		console.log("Grid.setWorkflowStyles    stageParameters[i] " + stageParameters[i].name + " (paramtype: " + stageParameters[i].paramtype + ") parameterRow: " + parameterRow);

		var isValid = Agua.getParameterValidity(stageParameters[i]);
		console.log("Grid.setWorkflowStyles     stageParameters[" + i + "] '" + stageParameters[i].name + "' isValid: " + isValid);
		if ( isValid == true || isValid == null )
		{
			console.log("Grid.setWorkflowStyles     Doing parameterRows[" + i +  "].setValid()");
			parameterRow.setValid(parameterRow.domNode);
		}
		else
		{
			parameterRow.setInvalid(parameterRow.domNode);
		}
	}	
},
clearPanel : function (panel) {
// CLEAR GRID CONTAINER CONTENTS
	//console.log("Grid.clearPanel    clearPanel()")
	children = panel.getChildren(); 
	while ( children != null && children.length != 0 )
	{
		//console.log("Grid.setWorkflows    removing child:");
		//console.dir({child: children[0]});
		panel.removeChild(children[0]);
		children = panel.getChildren();
	}	
},
getWorkflowNumber : function (projectName, workflowName) {
	//console.log("Grid.getWorkflow     plugins.workflow.Grid.getWorkflowNumber(projectName, workflowName)");
	if ( projectName == null || workflowName == null ) {
		console.log("Grid.getWorkflow    project or workflow is null. Returning null");
		return;
	}

	return Agua.getWorkflowNumber(projectName, workflowName);
},
updateWorkflowNumber : function (workflowObject, previousNumber) {
// UPDATE THE number OF A STAGE IN this.workflows
// AND ON THE REMOTE SERVER

	console.log("Workflows.updateWorkflowNumber     Workflow.updateWorkflowNumber(workflowObject)");
	console.log("Workflows.updateWorkflowNumber    workflowObject.project: " + workflowObject.project);
	console.log("Workflows.updateWorkflowNumber    workflowObject.workflow: " + workflowObject.workflow);
	console.log("Workflows.updateWorkflowNumber    workflowObject.name: " + workflowObject.name);
	console.log("Workflows.updateWorkflowNumber    workflowObject.number: " + workflowObject.number);
	
	// REMOVE FROM Agua DATA
	var addOk = Agua.updateWorkflowNumber(workflowObject, previousNumber);
	if ( ! addOk ) {
		//console.log("Workflows.updateWorkflowNumber    Failed to add workflow to Agua data");
		return;
	}
	////console.log("Workflows.updateWorkflowNumber     addOk: " + addOk);
},
resetNumbers : function (node, targetArea, indexChild) {	
	console.log("Grid.resetNumbers    plugins.workflow.GridWorkflow.resetNumbers(node, targetArea, indexChild)");
	//console.log("Grid.resetNumbers    node: ");
	//console.dir({node: node})
	//console.log("Grid.resetNumbers    targetArea: ");
	//console.dir({targetArea: targetArea})
	console.log("Grid.resetNumbers    indexChild: " + indexChild);
	var projectWorkflow = dijit.byNode(node);
	var workflowObject = {
		project:	projectWorkflow.project, 
		name: 		projectWorkflow.title,
		number:		projectWorkflow.number
	};
	//console.log("Grid.resetNumbers    workflowObject: " + dojo.toJson(workflowObject, true)); 
	// UPDATE ALL WORKFLOWS IN PROJECT
	Agua.moveWorkflow(workflowObject, indexChild + 1);

	// UPDATE ALL projectWorkflow OBJECTS AND THEIR workflowStage OBJECTS
	console.log("Grid.updateWorkflowNumber    DOING renumberWorkflows()");
	this.renumberWorkflows();
	
	// RELOAD RELEVANT DISPLAYS
	console.log("Grid.updateWorkflowNumber    DOING Agua.updater.update('updateProjects')");
	Agua.updater.update("updateProjects", { originator: this, reload: false});
},
renumberWorkflows : function () {
// RESET number IN ALL projectWorkflows AND THEIR workflowStages
	console.log("Grid.renumberWorkflows     renumberWorkflows()");
	
	var workflows = this.mainPanel.getChildren();
	for ( var i = 0; i < workflows.length; i++ )
	{
		var workflow = workflows[i];
		workflow.setNumber(i + 1);

		var stages = workflow.childWidgets;
		if ( stages == null )	continue;
		for ( var j = 0; j < stages.length; j++ )
		{
			stages[j].workflownumber = i + 1;
		}
	}
},

/////////////////	CONTROL METHODS
confirmStopProject : function () {
	
},
confirmPauseProject : function () {
	
},
startProject : function () {
	
},

/////////////////	DEBUG METHODS
setSubscriptions : function () {
	var thisObject = this;
	// example subscribe to events	
	dojo.subscribe("/dojox/mdnd/adapter/dndToDojo/over", null,  function(arg) {
		console.log("dndToDojo/over");
	});
	dojo.subscribe("/dojox/mdnd/adapter/dndToDojo/out", null, function(arg) {
		console.log("dndToDojo/out");
	});
	dojo.subscribe("/dojox/mdnd/adapter/dndToDojo/drop", null, function(arg) {
		console.log("dndToDojo/drop");
	});
	dojo.subscribe("/dojox/mdnd/adapter/dndToDojo/cancel", null, function(arg) {
		console.log("dndToDojo/cancel");
	});
	
	dojo.subscribe("/dojo/dnd/manager/overSource", function(source){
		console.debug("/dojo/dnd/manager/overSource", source);
	});
	
	dojo.subscribe("/dojox/mdnd/drag/start", function(node, targetArea, indexChild){
		console.dir({node: node});
		console.log("Doing /dojox/mdnd/drag/start    targetArea: ");
		console.dir({targetArea: targetArea})
		console.log("Doing /dojox/mdnd/drag/start    indexChild: " + indexChild);
	});
	
	dojo.subscribe("/dojox/mdnd/drop", null, function(node, targetArea, indexChild){
		console.log("Doing /dojox/mdnd/drop    node: " + node);
		console.log("Doing /dojox/mdnd/drop    targetArea: " + targetArea);
		console.dir({targetArea: targetArea})
		console.log("Doing /dojox/mdnd/drop    indexChild: " + indexChild);

		thisObject.resetNumbers(node, targetArea, indexChild);
	});
	
	dojo.subscribe("/dojox/mdnd/dropMode.OverDropMode/getDragPoint", function(node, targetArea, indexChild){
		console.log("Doing /dojox/mdnd/dropMode.OverDropMode/getDragPoint    node: " + node);
		console.log("Doing /dojox/mdnd/drop    targetArea: " + targetArea);
		console.dir({targetArea: targetArea})
		console.log("Doing /dojox/mdnd/drop    indexChild: " + indexChild);
	});


	/*
	//dojo.subscribe("/dojox/mdnd/drag/over", function(source){
	//	console.debug("over", source);
	//});
	
	//dojo.subscribe("/dojox/mdnd/drag/cancel", function(source, nodes, copy, target) {
	//	console.debug("cancel", source);
	//});
	
	//dojo.subscribe("/dojox/mdnd/out", function(source){
	//	console.debug("out", source);
	//});
	//dojo.subscribe("/dojox/mdnd/cancel", function(source){
	//	console.debug("cancel", source);
	//});
	*/
}


}); // plugins.workflow.Grid

