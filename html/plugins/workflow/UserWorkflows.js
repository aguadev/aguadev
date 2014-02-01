dojo.provide("plugins.workflow.UserWorkflows");

/* 
	USE CASE SCENARIO 1: INPUT VALIDITY CHECKING WHEN USER LOADS NEW WORKFLOW 

	1. updateDropTarget: load stages

	2. updateDropTarget: CALL -> first stage)

		   load multiple ParameterRows, each checks isValid (async xhr request for each file)
			   CALL -> Agua.setParameterValidity(boolean) to set stageParameter.isValid
	
	3. updateDropTarget: (concurrently with 2.) CALL -> updateRunButton()

		   check isValid for each StageRow:

				CALL-> checkValidParameters (async batch xhr request for multiple files)

				   CALL -> Agua.getParameterValidity(), and if empty check input and then

						CALL -> Agua.setParameterValidity(boolean) to set stageParameter.isValid


	USE CASE SCENARIO 2: USER CREATES NEW WORKFLOW BY TYPING IN WORKFLOW COMBO
	
	Stages.setWorkflowListeners:
	
	this.workflowCombo._onKey LISTENER FIRES
		
		--> Agua.isWorkflow (returns TRUE/FALSE)

			FALSE 	--> Agua.addWorkflow
						
						--> Agua.getMaxWorkflowNumber
						--> Agua._addWorkflow

					-->  Stages.setWorkflowCombo
		

	USE CASE SCENARIO 3: USER CLICKS 'Copy Workflow' BUTTON
	
	copyWorkflow
	
		-->	Agua.isWorkflow (returns TRUE/FALSE)
		
			TRUE 	-->	Message to dialogWidget and quit
		
			FALSE	-->	Message to dialogWidget and copy
			
				--> Stages._copyWorkflow

					-->	Agua.copyWorkflow (returns TRUE/FALSE)
					
						TRUE	--> Stages.setProjectCombo with new workflow

*/

// REQUIRE MODULES
if ( 1 ) {
//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");

// WIDGETS AND TOOLS FOR EXPANDO PANE
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.Tree");
dojo.require("dijit.layout.AccordionContainer");
dojo.require("dijit.layout.TabContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.layout.BorderContainer");
dojo.require("dojox.layout.FloatingPane");
dojo.require("dojo.fx.easing");
dojo.require("dojox.rpc.Service");
dojo.require("dojo.io.script");
dojo.require("dijit.TitlePane");
	
// DnD
dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");

// TIMER
dojo.require("dojox.timing");

// TOOLTIP
dojo.require("dijit.Tooltip");

// TOOLTIP DIALOGUE
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Textarea");
dojo.require("dijit.form.Button");

// STANDBY
dojo.require("dojox.widget.Standby");

// WIDGETS IN TEMPLATE
dojo.require("dijit.layout.SplitContainer");
dojo.require("dijit.layout.ContentPane");

// INPUT DIALOG
dojo.require("plugins.dijit.InteractiveDialog");
dojo.require("plugins.dijit.SelectiveDialog");
dojo.require("plugins.dijit.SyncDialog");

// HAS A
dojo.require("plugins.workflow.StageRow");
dojo.require("plugins.workflow.StageMenu");
dojo.require("plugins.workflow.IO");
dojo.require("dijit.form.ComboBox");
dojo.require("plugins.dijit.Confirm");
dojo.require("plugins.dnd.Target");

// INHERITS
dojo.require("plugins.workflow.Workflows");
}

dojo.declare("plugins.workflow.UserWorkflows",
	[ plugins.workflow.Workflows ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/userworkflows.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CONTEXT MENU
contextMenu : null,

// workflowType : string
// E.g., 'userWorkflows', 'sharedWorkflows'
workflowType : 'userWorkflows',

// syncDialog : plugins.dijit.SyncDialog
syncDialog : null,

/////}}}}
constructor : function (args) {
	console.log("Stages.constructor     plugins.workflow.UserWorkflows.constructor");			
	// GET INFO FROM ARGS
	this.core 						= args.core;
	this.core[this.workflowType]	= this;
	this.parentWidget 				= args.parentWidget;
	this.attachPoint 				= args.attachPoint;

	// LOAD CSS
	this.loadCSS();		
},
preStartup : function () {
	console.group("UserWorkflows-" + this.id + "    preStartup");
	console.log("HERE");
	console.log("UserWorkflows.preStartup    END");
	console.groupEnd("UserWorkflows-" + this.id + "    preStartup");
},
postStartup : function () {
	console.group("UserWorkflows-" + this.id + "    postStartup");

	// SET SYNC WORKFLOWS BUTTON
	this.setSyncWorkflows();
	
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateSyncWorkflows");

	// SET SYNC DIALOG
	this.setSyncDialog();
	
	console.groupEnd("UserWorkflows-" + this.id + "    postStartup");
},
updateSyncWorkflows : function (args) {
	console.warn("UserWorkflows.updateSyncWorkflows    args:");
	console.dir({args:args});

	this.setSyncWorkflows();
},
// DISABLE SYNC WORKFLOWS BUTTON IF NO HUB LOGIN
setSyncWorkflows : function () {
	var hub = Agua.getHub();
	console.log("UserWorkflows.setSyncWorkflows    hub:")
	console.dir({hub:hub});

	if ( ! hub.login || ! hub.token ) {
		this.disableSyncWorkflows();
	}
	else {
		this.enableSyncWorkflows();
	}
},
setSyncDialog : function () {
	console.log("UserWorkflows.loadSyncDialog    plugins.workflows.UserWorkflows.setSyncDialog()");
	
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "Sync";
	var header = "Sync Workflows";
	
	this.syncDialog = new plugins.dijit.SyncDialog(
		{
			title 				:	title,
			header 				:	header,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback
		}			
	);

	console.log("UserWorkflows.loadSyncDialog    this.syncDialog:");
	console.dir({this_syncDialog:this.syncDialog});

},
showSyncDialog : function () {
	var disabled = dojo.hasClass(this.syncWorkflowsButton, "disabled");
	console.log("UserWorkflows.loadSyncDialog    disabled: " + disabled);
	
	if ( disabled ) {
		console.log("UserWorkflows.loadSyncDialog    SyncWorkflows is disabled. Returning");
		return;
	}
	
	var title = "Sync Workflows";
	var header = "";
	var message = "";
	var details = "";
	var enterCallback = dojo.hitch(this, "syncWorkflows");
	this.loadSyncDialog(title, header, message, details, enterCallback)
},
loadSyncDialog : function (title, header, message, details, enterCallback) {
	console.log("UserWorkflows.loadSyncDialog    title: " + title);
	console.log("UserWorkflows.loadSyncDialog    header: " + header);
	console.log("UserWorkflows.loadSyncDialog    message: " + message);
	console.log("UserWorkflows.loadSyncDialog    details: " + details);
	console.log("UserWorkflows.loadSyncDialog    enterCallback: " + enterCallback);

	this.syncDialog.load(
		{
			title 			:	title,
			header 			:	header,
			message 		:	message,
			details 		:	details,
			enterCallback 	:	enterCallback
		}			
	);
},
disableSyncWorkflows : function () {
	dojo.addClass(this.syncWorkflowsButton, "disabled");
	dojo.attr(this.syncWorkflowsButton, "title", "Input AWS private key and public certificate to enable Sync");
},
enableSyncWorkflows : function () {
	dojo.removeClass(this.syncWorkflowsButton, "disabled");
	dojo.attr(this.syncWorkflowsButton, "title", "Click to sync workflows to biorepository");
},
// SYNC WORKFLOWS
syncWorkflows : function (inputs) {
	console.log("UserWorkflows.syncWorkflows    inputs: ");
	console.dir({inputs:inputs});
	
	if ( this.syncingWorkflows == true ) {
		console.log("UserWorkflows.syncWorkflows    this.syncingWorkflows: " + this.syncingWorkflows + ". Returning.");
		return;
	}
	this.syncingWorkflows = true;
	
	var query = new Object;
	query.username 			= 	Agua.cookie('username');
	query.sessionid 		= 	Agua.cookie('sessionid');
	query.message			= 	inputs.message;
	query.details			= 	inputs.details;
	query.hubtype			= 	"github";
	query.mode 				= 	"syncWorkflows";
	query.module 		= 	"Agua::Workflow";
	console.log("UserWorkflows.syncWorkflows    query: ");
	console.dir({query:query});
	
	// SEND TO SERVER
	var url = Agua.cgiUrl + "agua.cgi?";
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "json",
			putData: dojo.toJson(query),
			load: function(response, ioArgs) {
				thisObj.syncingWorkflows = false;

				console.log("Workflows.syncWorkflows    OK. response:")
				console.dir({response:response});

				Agua.toast(response);
			},
			error: function(response, ioArgs) {
				thisObj.syncingWorkflows = false;

				console.log("Workflows.syncWorkflows    ERROR. response:")
				console.dir({response:response});
				Agua.toast(response);
			}
		}
	);
}

}); // plugins.workflow.UserWorkflows
