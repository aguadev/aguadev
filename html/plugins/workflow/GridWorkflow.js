dojo.provide("plugins.workflow.GridWorkflow");

/* 
	USE CASE SCENARIO 1: USER REORDERS WORKFLOWS IN PROJECT
	

*/

// REQUIRE MODULES
if ( 1 ) {
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");

// WIDGETS
dojo.require("plugins.dijit.TitlePane");
	
// DnD
//dojo.require("dojo.dnd.Source"); // Source & Target
//dojo.require("dojo.dnd.Moveable");
//dojo.require("dojo.dnd.Mover");
//dojo.require("dojo.dnd.move");

// INHERITS
dojo.require("plugins.core.Common");

// HAS A
dojo.require("plugins.workflow.GridStage");
dojo.require("plugins.dnd.Target");
}

dojo.declare("plugins.workflow.GridWorkflow",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/gridworkflow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
],

// PARENT WIDGET
parentWidget : null,

// ARRAY OF CHILD WIDGETS
childWidgets : null,

// TAB CONTAINER
attachPoint : null,

// CONTEXT MENU
contextMenu : null,

// CORE WORKFLOW OBJECTS
core : null,

// PREVENT DOUBLE CALL ON LOAD
workflowLoaded : null,
dropTargetLoaded : null,

// WORKFLOW-RELATED VARIABLES
project : null,
workflow: null,
number : null,

/////}

constructor : function(args) {
	//console.log("GridWorkflow.constructor     plugins.workflow.GridWorkflow.constructor");			
	// GET ARGS
	this.stages 	= 	args.stages;
	this.core 		= 	args.core;
	this.project 	= 	args.project;
	this.workflow 	= 	args.workflow;
	this.number 	= 	args.number;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	this.startup();
},
startup : function () {
	//console.log("GridWorkflow.startup    plugins.workflow.GridWorkflow.startup()");

	//console.log("GridWorkflow.startup    this.titlePane: " + this.titlePane);
	//console.dir({titlepane: this.titlePane});
	
	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// POPULATE WITH STAGES
	this.setStages(this.stages);
},
setStages : function (stages) {
	//console.log("GridWorkflow.setStages     plugins.workflow.GridWorkflow.setStages(stages)");
	//console.log("GridWorkflow.setStages    stages: " + dojo.toJson(stages));
	//console.log("GridWorkflow.setStages    stages.length: " + stages.length);	

	// CLEAR STAGES
	this.clearStages();
	
	// SET CHILD WIDGETS
	this.childWidgets = new Array;

	// SORT STAGES
	stages = this.sortNumericHasharray(stages, "number");

	// GENERATE APPLICATIONS ARRAY FOR DRAG AND DROP
	// FROM WORKFLOW APPLICATIONS LIST
	var dataArray = new Array;
	for ( var i = 0; i < stages.length; i++ )
	{
		var hash = new Object;
		hash.data = stages[i].name;
		hash.type = [ "draggableItem" ];
		dataArray.push(hash);
	}
	console.log("GridWorkflow.setStages     dataArray: ");
	console.dir({dataArray:dataArray});

	// CREATE DROP TARGET
	if ( this.dropTarget == null )
	{
		this.dropTarget = new plugins.dnd.Target( this.dropTargetContainer,
			{
				accept: [],
				parentWidget : this
			}
		);
	}

	// INSERT DATA INTO DROP TARGET
	console.log("GridWorkflow.setStages     this.dropTarget: " + this.dropTarget);
	this.dropTarget.insertNodes(false, dataArray);

	// SET GridStage WIDGET FOR EACH STAGE
	allNodes = this.dropTarget.getAllNodes();
	var thisObject = this;
	dojo.forEach(allNodes, function (node, i)
	{
		//console.log("GridWorkflow.setStages     Doing node for stages[" + i + "]: " + dojo.toJson(stages[i]));

		// ENSURE NON-NULL ENTRIES
		stages[i].description = stages[i].stagedescription || '';
		stages[i].submit = stages[i].submit || '';
		
		// INSTANTIATE ROW 
		var gridStage = new plugins.workflow.GridStage(stages[i]);

		// SET gridStage.parentWidget = GridWorkflow
		gridStage.parentWidget = thisObject;
		//console.log("GridWorkflow.setStages     gridStage.parentWidget: " + gridStage.parentWidget);

		// APPEND TO NODE
		node.innerHTML = '';
		node.appendChild(gridStage.domNode);

		// PUSH ONTO ARRAY OF CHILD WIDGETS
		thisObject.childWidgets.push(gridStage);
		
		
	});	// END OF allNodes

}, // end of Stages.setStages
setNumber : function (number) {
// SET THE NUMBER NODE TO THE stage.number 
	//console.log("GridStage.setNumber    plugins.workflow.GridStage.setNumber(" + number + ")");

	this.number = number;
	this.titlePane.set('number', number);
},
clearStages : function () {
// EMPTY dropTargetContainer
	while ( this.dropTargetContainer.firstChild )
	{
		this.dropTargetContainer.removeChild(this.dropTargetContainer.firstChild);
	}	
},
getStagesStandby : function () {
	console.log("GridWorkflow.getStagesStandby    Stages.getStagesStandby()");
	if ( this.standby == null ) {

		var id = dijit.getUniqueId("dojox_widget_Standby");
		this.standby = new dojox.widget.Standby (
			{
				target: this.dropTargetContainer,
				//onClick: "reload",
				text: "Checking stage inputs",
				id : id,
				url: "plugins/core/images/agua-biwave-24.png"
			}
		);
		document.body.appendChild(this.standby.domNode);
	}

	console.log("GridWorkflow.getStagesStandby    this.standby: " + this.standby);

	return this.standby;
}


}); // plugins.workflow.GridWorkflow
