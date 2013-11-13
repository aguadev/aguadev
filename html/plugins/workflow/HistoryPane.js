dojo.provide("plugins.workflow.HistoryPane");

// DISPLAY THE STATUS OF A WORKFLOW STAGE

dojo.declare( "plugins.workflow.HistoryPane",
	[ dijit._Widget, dijit._Templated ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/historypane.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//srcNodeRef: null,

// ROWS OF ENTRIES
rows : null,

// CORE WORKFLOW OBJECTS
core : null,

/////}
constructor : function(args) { 	
	//console.log("HistoryPane.constructor    plugins.workflow.HistoryPane.constructor(args)");
	//console.log("HistoryPane.constructor    args: " + dojo.toJson(args));
	//this.project = rows[0].project;
	//this.workflow = rows[0].workflow;
	this.rows = args.rows;

	this.core = args.core;

},

postMixInProperties: function() {
	////console.log("HistoryPane.postMixInProperties    plugins.workflow.HistoryPane.postMixInProperties()");
	////console.log("HistoryPane.postMixInProperties    this.containerNode: " + this.containerNode);
},

postCreate: function() {
	////console.log("HistoryPane.postCreate    plugins.workflow.HistoryPane.postCreate()");
	////console.log("HistoryPane.postCreate    this.domNode: " + this.domNode);

	this.startup();		
},

startup : function () {
	//console.log("HistoryPane.startup    plugins.workflow.HistoryPane.startup()");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	for ( var i = 0; i < this.rows.length; i++ )
	{
		////console.log("HistoryPane.startup    dojo.toJson(this.rows[" + i + "]): " + dojo.toJson(this.rows[i]));
		var historyPaneRow = new plugins.workflow.HistoryPaneRow(this.rows[i]);
		////console.log("HistoryPane.startup    historyPaneRow: " + historyPaneRow);
		////console.log("HistoryPane.startup    this.rowsNode: " + this.rowsNode);

		this.rowsNode.innerHTML += historyPaneRow.domNode.innerHTML;

	}
},

openWorkflow : function () {
	var projectName = this.project;
	var workflowName = this.workflow;
	console.log("HistoryPane.openWorkflow    projectName: " + projectName);
	console.log("HistoryPane.openWorkflow    workflowName: " + workflowName);
	
	// OPEN WORKFLOW TAB
	if ( Agua.controllers["workflow"] ) 
		Agua.controllers["workflow"].createTab({project: projectName, workflow: workflowName});
}

}); // end of plugins.workflow.HistoryPane


dojo.declare( "plugins.workflow.HistoryPaneRow",
	[ dijit._Widget, dijit._Templated ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/historypanerow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//srcNodeRef: null,

// CORE WORKFLOW OBJECTS
core : null,

/////}
constructor : function(args) {
	////console.log("HistoryPaneRow.constructor    plugins.workflow.HistoryPaneRowRow.constructor(args)");
	////console.log("HistoryPaneRow.constructor    args: " + dojo.toJson(args));
	this.core = args.core;
},

postCreate : function() {
	this.startup();
},

startup : function () {
	//console.log("HistoryPaneRow.startup    plugins.workflow.HistoryPaneRow.startup()");

	this.inherited(arguments);
}

});
