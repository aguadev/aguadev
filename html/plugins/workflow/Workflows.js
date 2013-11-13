dojo.provide("plugins.workflow.Workflows");

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
	
	Workflows.setWorkflowListeners:
	
	this.workflowCombo._onKey LISTENER FIRES
		
		--> Agua.isWorkflow (returns TRUE/FALSE)

			FALSE 	--> Agua.addWorkflow
						
						--> Agua.getMaxWorkflowNumber
						--> Agua._addWorkflow

					-->  Workflows.setWorkflowCombo
		

	USE CASE SCENARIO 3: USER CLICKS 'Copy Workflow' BUTTON
	
	copyWorkflow
	
		-->	Agua.isWorkflow (returns TRUE/FALSE)
		
			TRUE 	-->	Message to dialogWidget and quit
		
			FALSE	-->	Message to dialogWidget and copy
			
				--> Workflows._copyWorkflow

					-->	Agua.copyWorkflow (returns TRUE/FALSE)
					
						TRUE	--> Workflows.setProjectCombo with new workflow

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
dojo.require("dojo.store.Memory");
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

// INHERITS
dojo.require("plugins.core.Common");

// HAS A
dojo.require("plugins.workflow.StageRow");
dojo.require("plugins.workflow.StageMenu");
dojo.require("plugins.workflow.IO");
dojo.require("dijit.form.ComboBox");
dojo.require("plugins.dijit.Confirm");
dojo.require("plugins.dnd.Target");

// INPUT DIALOG
dojo.require("plugins.dijit.InteractiveDialog");
dojo.require("plugins.dijit.SelectiveDialog");

}

dojo.declare("plugins.workflow.Workflows",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: null,

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// addingApp STATE
addingApp : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins", "workflow/css/workflows.css") ],

// PARENT WIDGET
parentWidget : null,

// TAB CONTAINER
attachNode : null,

// CONTEXT MENU
contextMenu : null,

// CORE WORKFLOW OBJECTS
core : null,

// PREVENT DOUBLE CALL ON LOAD
workflowLoaded : null,
dropTargetLoaded : null,

// FINISHED LOADING COMBOBOXES, ETC.
ready: false,

// ARRAY OF STAGE ROWS
stageRows : null,

// workflowType : string
// E.g., 'userWorkflows', 'sharedWorkflows'
workflowType : null,

/////}}}}
constructor : function (args) {
	console.log("Workflows.constructor     plugins.workflow.Workflows.constructor");			

	// GET ARGS
	this.core 						= args.core;
	this.core[this.workflowType]	= this;
	this.parentWidget 				= args.parentWidget;
	this.attachNode 				= args.attachNode;
	console.log("Workflows.constructor     core.userWorkflows: " + this.core.userWorkflows);			
	console.log("Workflows.constructor     core.sharedWorkflows: " + this.core.sharedWorkflows);			


	// LOAD CSS
	this.loadCSS();		
},
postCreate : function () {

	// PRE STARTUP
	if ( this.preStartup )	this.preStartup();
	
	this.startup();

	// POST STARTUP
	if ( this.postStartup )	this.postStartup();
},
startup : function () {
	console.log("Workflows.startup    plugins.workflow.Workflows.startup()");
	console.group("Workflows-" + this.id + "    startup");

	//console.log("Workflows.startup    Setting this.ready = false");
	this.ready = false;

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD TO TAB CONTAINER		
	this.attachNode.addChild(this.mainTab);
	this.attachNode.selectChild(this.mainTab);

	// SET INPUT/OUTPUT CHAINER
	this.setWorkflowIO();
	
	// SET SELECTIVE DIALOG FOR copyWorkflow	
	this.setSelectiveDialog();
	
	// SET INTERACTIVE DIALOG FOR copyProject
	this.setInteractiveDialog();
		
	// CREATE SOURCE MENU
	this.setContextMenu();

	// CREATE DROP TARGET
	this.setDropTarget();

	// START CASCADE OF COMBO LOADING:
	// PROJECT COMBO, WORKFLOW COMBO, DROP TARGET
	this.setProjectCombo();
	
	// SET ONCLICK FOR PROJECT AND WORKFLOW BUTTONS
	this.setComboButtons();

	// SET LISTENERS
	this.setProjectListeners();
	this.setWorkflowListeners();

	// SET SUBSCRIPTIONS
	this.setSubscriptions();

	console.log("Workflows.startup    END");
	console.groupEnd("Workflows-" + this.id + "    startup");
},
setSubscriptions : function () {
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateProjects");
	Agua.updater.subscribe(this, "updateWorkflows");
	Agua.updater.subscribe(this, "updateClusters");
},
updateProjects : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.warn("workflow.Workflows.updateProjects    args:");
	console.dir({args:args});

	this.setProjectCombo();
},
updateWorkflows : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.warn("workflow.Workflows.updateWorkflows    args:");
	console.dir({args:args});

	this.setProjectCombo();
},
updateClusters : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.warn("admin.Clusters.updateClusters    args:");
	console.dir({args:args});

	this.setClusterCombo();
},
setContextMenu : function () {
// GENERATE CONTEXT MENU

	////console.log("Workflows.setContextMenu     plugins.workflow.Workflows.setContextMenu()");
	this.contextMenu = new plugins.workflow.StageMenu(
		{
			parentWidget: this,
			core: this.core
		}
	);
},
/////////////////// 	 DROP TARGET METHODS
setDroppingApp : function (value) {
// SET this.droppingApp

	////console.log("Workflows.setDroppingApp     plugins.workflow.Workflows.setDroppingApp(" + value + ")");	
	this.droppingApp = value; 
},
setDropTarget : function () {
// CREATE DROP TARGET
	this.dropTarget = new plugins.dnd.Target(
		this.dropTargetContainer,
		{
			accept: ["draggableItem"],
			contextMenu : this.contextMenu,
			parentWidget : this,
			core: this.core
		}
	);

	if ( this.dropTarget == null ) {
		console.log("Workflows._setDropTargetNodes    this.dropTarget is null. Returning");
		return;
	}
},
updateDropTarget : function (project, workflow) {
// SET DND DROP TARGET AND ITS CONTEXT MENU.
// ADD application OBJECT TO EACH NODE, CONTAINING
// THE STAGE INFORMATION INCLUDING number
	//console.group("Workflows-" + this.id + "    updateDropTarget");
	//console.log("Workflows.updateDropTarget    project: " + project);
	//console.log("Workflows.updateDropTarget    workflow: " + workflow);
	//console.log("Workflows.updateDropTarget    caller: " + this.updateDropTarget.caller.nom);
	//console.log("Workflows.updateDropTarget   this.ready: " + this.ready);
	
	// CREATE DROP TARGET
	if ( this.dropTarget == null )
	{
		this.dropTarget = new plugins.dnd.Target( this.dropTargetContainer,
			{
				accept: ["draggableItem"],
				contextMenu : this.contextMenu,
				parentWidget : this,
				core: this.core
			}
		);
	}
	if ( this.dropTarget == null ) {
		console.log("Workflows._updateDropTargetNodes    this.dropTarget is null. Returning");
		return;
	}

	// GET STAGES FOR THIS WORKFLOW
	var stages = Agua.getStagesByWorkflow(project, workflow);
	if ( stages == null )	stages = [];
	//console.log("Workflows.updateDropTarget    stages: ");
	//console.dir({stages:stages});

	this._updateDropTarget(stages);

	//console.groupEnd("Workflows-" + this.id + "    updateDropTarget");	
},
_updateDropTarget : function (stages) {
	console.group("Workflows-" + this.id + "    _updateDropTarget");
	console.log("Workflows._updateDropTarget    stages.length: " + stages.length);
	
	var allNodes = this._updateDropTargetNodes(stages);
	this._updateDropTargetStageRows(stages, allNodes);	
	
	// IF SHARED AND STAGES PRESENT, JUST LOAD THE PARAMETERS PANE
	if ( allNodes.length != 0 && this.shared ) {
		
		console.log("Workflows._updateDropTarget    Shared. Doing this.loadParametersPane(node_0)");
		this.loadParametersPane(allNodes[0]);

		// SET READY TO TRUE
		var thisObject = this;		
		setTimeout(
			function() {
				console.log("Workflows._updateDropTarget    setTimeout; SET this.ready TO TRUE");
				thisObject.ready = true;
			},
			1000
		);
	}

	// IF NOT SHARED AND STAGES PRESENT, SET THE PARAMETERS FOR THE 
	// FIRST STAGE AND CHECK VALIDITY OF PARAMETERS FOR REMAINING STAGES
	else if ( allNodes.length != 0 && ! this.shared )	this.checkStages(allNodes);

	// OTHERWISE, JUST HIDE STANDBY
	else {
		// HIDE LOADING STANDBY
		if ( this.standby )
			this.standby.hide();
		
		// UPDATE RUNBUTTON 
		console.log("Workflows._updateDropTarget    Doing this.updateRunButton()");
		this.updateRunButton();
	}

	////console.log("Workflows._updateDropTarget    END");
	console.groupEnd("Workflows-" + this.id + "    _updateDropTarget");
	
}, // end of Stages._updateDropTarget
_clearTarget : function () {
	while ( this.dropTargetContainer.firstChild ) {
		this.dropTargetContainer.removeChild(this.dropTargetContainer.firstChild);
	}	

	//if ( this.appSources == null || this.appSources.length == 0 )	return;
	//
	//for ( var i = 0; i < this.appSources.length; i++ )
	//{
	//	//console.log("Apps.clearAppSources     Destroying this.appSources[" + i + "]: " + this.appSources[i]);
	//	this.appSources[i].clearDragSource();
	//	this.appSourcesContainer.removeChild(this.appSources[i].domNode);
	//	this.appSources[i].destroy();
	//}

},
_updateDropTargetNodes : function(stages) {
	
	// EMPTY dropTargetContainer
	this._clearTarget();
	
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
	////console.log("Workflows._updateDropTargetNodes     dataArray: " + dojo.toJson(dataArray));

	// INSERT DATA INTO DROP TARGET
	console.log("Workflows._updateDropTargetNodes     Inserting dataArray: ");
	console.dir({dataArray:dataArray});
	console.log("Workflows._updateDropTargetNodes    this.dropTarget: " + this.dropTarget);
	this.dropTarget.insertNodes(false, dataArray);

	// SET NODE CHARACTERISTICS - ONCLICK, CLASS, ETC.
	console.log("Workflows._updateDropTargetNodes    this.dropTarget: " + this.dropTarget);
	allNodes = this.dropTarget.getAllNodes();
	if ( ! allNodes )	allNodes = [];

	//console.log("Workflows._updateDropTarget     Workflow.allNodes.length: " + allNodes.length);
	dojo.forEach(allNodes, function (node, i) {
		////console.log("Workflows._updateDropTarget     Doing node for stages[" + i + "]: " + dojo.toJson(stages[i]));
		var nodeClass = dataArray[i].type;
	});
	
	return allNodes;
},
_updateDropTargetStageRows : function (stages, allNodes) {
	// SET this.stageRows
	this.stageRows = new Array;
	
	var thisObject = this;
	console.log("Workflows._updateDropTargetStageRows     Workflow.allNodes.length: " + allNodes.length);
	dojo.forEach(allNodes, function (node, i)
	{
		console.log("Workflows._updateDropTargetStageRows     Doing node for stages[" + i + "]: ");
		console.dir({stage:stages[i]});

		// GET APP NAME
		var applicationName = node.innerHTML;
		
		// ADD infoId TO NODE
		node.setAttribute('infoId', thisObject.infoId);

		// ADD application TO NODE
		node.application = stages[i];
		console.log("Workflows._updateDropTargetStageRows     stages[" + i + "]: ");
		console.dir({stage:stages[i]});
		
		// DON'T SHOW DESCRIPTION ONCLICK FOR NOW
		// BECAUSE WE ALREADY HAVE AN ONCLICK
		// LISTENER FOR REFRESHING THE INFOPANE
		node.application.description = '';

		// NO DESCRIPTION OR NOTES FOR NOW IN STAGE
		stages[i].description = '';
		stages[i].notes = '';

		// CAN'T SET CLUSTER FOR STAGE YET
		if ( stages[i]["cluster"] == null )	stages[i]["cluster"] = '';
			
		// INSTANTIATE ROW 
		console.log("Workflows._updateDropTargetStageRows    stages[i]: ");
		console.dir({stage:stages[i]});
		
		var stageRow = new plugins.workflow.StageRow(stages[i]);
		stageRow.core = thisObject.core;
		stageRow.parentWidget = thisObject;

		// PUSH TO this.stageRows
		thisObject.stageRows.push(stageRow);

		// CLEAR NODE CONTENT
		node.innerHTML = '';

		// APPEND TO NODE
		node.appendChild(stageRow.domNode);

		// SET stageRow AS node.parentWidget FOR LATER RESETTING OF
		// number ON REMOVAL OR INSERTION OF NODES
		//
		// REM: remove ONCLICK BUBBLES ON stageRow.name NODE RATHER THAN ON node. 
		// I.E., CONTRARY TO DESIRED, this.name IS THE TARGET INSTEAD OF THE node.
		//
		// ALSO ADDED this.name.parentWidget = this IN StageRow.startup()
		node.parentWidget = stageRow;

		// ADD CONTEXT MENU TO NODE
		thisObject.contextMenu.bind(node);

		// SHOW APPLICATION INFO WHEN CLICKED
		dojo.connect(node, "onclick",  dojo.hitch(thisObject, function(event)
			{
				console.log("Workflows._updateDropTargetStageRows    ONCLICK call to this.loadParametersPane()");
				console.log("Workflows._updateDropTargetStageRows    thisObject.ready: " + thisObject.ready);
				event.stopPropagation();
				
				if ( ! thisObject.ready ) {
					console.log("Workflows._updateDropTargetStageRows    QUTTING because thisObject.ready: " + thisObject.ready);
					return;
				}
				
				this.loadParametersPane(node);
			}
		));

	});	// END OF allNodes
	
},
checkStages : function (allNodes) {
/* CHECK STAGES AND SET INFOPANE IF STAGES ARE PRESENT IN WORKFLOW:
 	 
 	 1. SET THE INFOPANE FOR THE FIRST STAGE:
			- CHECK VALIDITY OF PARAMETERS
			- CHANGE PARAMETER NODE STYLES ACCORDINGLY
	 2. CHECK VALIDITY OF PARAMETERS FOR REMAINING STAGES

	 FIRST STAGE:
	 Workflow.loadParametersPane
	     --> CALLS Parameters.load
	         --> CALLS StageRow.checkValidParameters
	 CARRIED OUT SYNCHRONOUSLY (I.E., WAITS TIL DONE)
	
	 OTHER STAGES:
			--> CALL StageRow.checkValidParameters
*/

	console.group("Workflows-" + this.id + "    checkStages");
	console.log("Workflows.checkStages    caller: " + this.checkStages.caller.nom);

	var standby = this.getStandby();
	standby.show();

	var thisObject = this;
	setTimeout(function () {
		//console.group("Workflows-" + thisObject.id + "    checkStages (inside setTimeout)");
		// VALIDATE PARAMETERS FOR FIRST STAGE
		thisObject.loadParametersPane(allNodes[0]);
		
		// FOR THE REMAINING STAGES, DO THE QUERY FOR ALL FILES AT ONCE
		var stageFiles = new Array;
		stageFiles[0] = [];
		if ( allNodes.length >= 1 )
		{
			var filesPresent = 0;
			for ( var i = 1; i < allNodes.length; i++ )
			{
				var stageRow = allNodes[i].parentWidget;
				console.log("Workflows.checkStages    stageRows[" + i + "]: " + stageRow);

				// NB: DON'T FORCE IN CASE STAGE PARAMETER INFORMATION 
				// HAS ALREADY BEEN GENERATED EARLIER IN THIS SESSION
				var force = false;
				stageRow.checkAllParameters(force);
				var files = stageRow.fileStageParameters;
				console.log("Workflows.checkStages    files: ");
				console.dir({files:files});
				if ( ! files )	files = [];
				if ( files != [] && files.length > 0 ) {
					console.log("Workflows.checkStages    Setting filesPresent to 1");
					filesPresent = 1;
				}
				stageFiles[i] = files;
			}
			
			console.log("Workflows.checkStages    No. stageFiles to be checked: " + stageFiles.length);
			console.dir({stageFiles:stageFiles});
			if ( filesPresent == 1 )
				thisObject.checkStageFiles(stageFiles);
			
			console.log("Workflows.checkStages    DOING this.standby.hide()");
			thisObject.standby.hide();
			
			// SET READY TO TRUE
			thisObject.ready = true;
			console.log("Workflows.checkStages    SET this.ready TO TRUE");
		}

		// UPDATE RUNBUTTON 
		console.log("Workflows.checkStages    Doing this.updateRunButton()");
		thisObject.updateRunButton();

		thisObject.ready = true;
		console.log("Workflows.checkStages    SET this.ready: " + thisObject.ready);		
		console.groupEnd("Workflows-" + thisObject.id + "    checkStages (inside setTimeout)");

	}, 100);	
},
checkStageFiles : function (stageFiles) {
	console.group("Workflows-" + this.id + "    checkStageFiles");
	console.dir({stageFiles:stageFiles});
	
	// GET FILEINFO FROM REMOTE FILE SYSTEM
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username = Agua.cookie('username');
	query.sessionid = Agua.cookie('sessionid');
	query.project = this.getProject();
	query.workflow = this.getWorkflow();
	query.mode = "checkStageFiles";
	query.module 		= 	"Agua::Workflow";
	query.stagefiles = stageFiles;

	// SEND TO SERVER
	var thisObject = this;
	dojo.xhrPut({
		url: url,
		contentType: "text",
		sync : false,
		handleAs: "json",
		putData: dojo.toJson(query),
		//timeout: 20000,
		handle : function(stageFileInfos, ioArgs) {
			if ( stageFileInfos.error ) {
				Agua.toastError(stageFileInfos.error);
			}
			else {
				console.log("Workflows.checkStageFiles    Returned stageFileInfos:");
				console.dir({stageFileInfos:stageFileInfos});
				
				thisObject.validateStageFiles(stageFileInfos, stageFiles);
				console.groupEnd("Workflows-" + this.id + "    checkStageFiles");
			}				

			// HIDE LOADING STANDBY
			thisObject.standby.hide();

			// CHECK RUN STATUS		
			console.log("StagescheckStageFiles    BEFORE Do checkRunStatus()");
			if ( thisObject.core.parameters != null 
				&& thisObject.core.parameters.isCurrentApplication(thisObject.application) ) {
				console.log("StagescheckStageFiles    Doing checkRunStatus()");
				thisObject.checkRunStatus();
			}
		}
	});	
},
validateStageFiles : function (stageFileInfos, stageFiles) {
	console.group("Workflows-" + this.id + "    validateStageFiles")
	console.dir({stageFileInfos:stageFileInfos});
	
	// SET NODE CHARACTERISTICS - ONCLICK, CLASS, ETC.
	console.log("Workflows.validateStageFiles    this.dropTarget: " + this.dropTarget);
	var allNodes = this.dropTarget.getAllNodes();
	for ( var i = 1; i < allNodes.length; i++ )
	{
		var stageRow = allNodes[i].parentWidget;
		var files = stageFiles[i];
		var infofiles = stageFileInfos[i];

		console.log("Workflows.validateStageFiles    files: ");
		console.dir({files:files});
		console.log("Workflows.validateStageFiles    infofiles: ");
		console.dir({infofiles:infofiles});

		if ( ! files )	return;
	
		if ( files != null && files.length )
			stageRow.validateFiles(stageFileInfos[i]);
	}

	console.groupEnd("Workflows-" + this.id + "    validateStageFiles")
},
checkRunStatus : function() {
	console.log("Workflows.checkRunStatus    plugins.workflow.Workflows.checkRunStatus");
	
	// DEBUG:
	if ( this.core.runStatus == null )	return;

	// CHECK IF STAGES ARE RUNNING
	console.log("Parameters.load     BEFORE this.indexOfRunningStage()");
	var indexOfRunningStage = this.indexOfRunningStage();
	console.log("Parameters.load     indexOfRunningStage: " + indexOfRunningStage);
	var runner = this.core.runStatus.createRunner(indexOfRunningStage);	
	var singleton = true;
	var selectTab = false;
	console.log("Parameters.load     DOING runStatus.getStatus");
	this.core.runStatus.getStatus(runner, singleton, selectTab);
},
getStandby : function () {
	console.log("Workflows.getStandby    this.standby");
	if ( this.standby ) return this.standby;
		
	console.log("Workflows.getStandby    Creating this.standby");
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

	return this.standby;
},
resetNumbers : function () {
	//console.log("Workflows.resetNumbers    plugins.workflow.Workflows.resetNumbers()");

	//console.log("Workflows.resetNumbers    this.dropTarget: " + this.dropTarget);
	var childNodes = this.dropTarget.getAllNodes();
	//console.log("Workflows.resetNumbers     Resetting number in all childNodes. childNodes.length: " + childNodes.length);
	
	// RESETTING number IN ALL CHILDNODES
	for ( var i = 0; i < childNodes.length; i++ )
	{
		var node = childNodes[i];
		//console.log("Workflows.resetNumbers     //console.dir(childNodes[" + i + "]):");
		//console.dir({node: node});

		// GET WIDGET
		//console.log("Workflows.resetNumbers     Getting widget.");
		var widget = dijit.byNode(node.firstChild);
		//var widget = node.parentWidget;
		//console.log("Workflows.resetNumbers     childNodes[" + i + "].widget: " + widget);			
		if ( widget == null )
		{
			widget = dijit.getEnclosingWidget(childNodes[i]);
		}
		//console.log("Workflows.resetNumbers     Resetting stageRow number to: " + (i + 1));
		node.application.number = (i + 1).toString();
		node.application.appnumber = (i + 1).toString();

		// SET DISPLAYED NUMBER
		//console.log("Workflows.resetNumbers     Doing widget.setNumber(node.application.number)");
		widget.setNumber(node.application.number);
		//console.log("Workflows.resetNumbers     New widget.numberNode.innerHTML: " + widget.numberNode.innerHTML);

		//console.log("Workflows.resetNumbers     Reset widget childNodes[" + i + "].application.name " + node.application.name + ", node.application.number: " + node.application.number);
	}
},
////////////////// 		CLUSTER METHODS
getCluster : function () {
	////console.log("Workflows.getCluster     plugins.workflow.Cluster.getCluster()");
	
	if ( this.clusterCombo == null )	return '';

	return this.clusterCombo.get('value');
},
setClusterCombo : function () {
// POPULATE THE WORKFLOW COMBO BASED ON SELECT VALUE IN PROJECT COMBO
	////console.log("Workflows.setClusterCombo     plugins.workflow.Cluster.setClusterCombo()");

	// AVOID SELF-TRIGGERING OF onChange EVENT WHEN CHANGED PROGRAMMATICALLY
	this.settingCluster = true;

	// QUIT IF SHARED
	if ( this.shared == true )	return;
	
	////console.log("Workflows.setClusterCombo    plugins.workflowCluster.setClusterCombo()");
	var projectName = this.getProject();
	var workflowName = this.getWorkflow();
	////console.log("Workflows.setClusterCombo    projectName: " + projectName);
	////console.log("Workflows.setClusterCombo    workflowName: " + workflowName);

	var clusters = Agua.getClusters();
	////console.log("Workflows.setClusterCombo    clusters: " + dojo.toJson(clusters, true));
    var clusterName = Agua.getClusterByWorkflow(projectName, workflowName);
	if ( clusterName == null )	clusterName = '';
	var regex = Agua.cookie('username') + "-";
	clusterName = clusterName.replace(regex, '');
	////console.log("Workflows.setClusterCombo    clusterName: " + clusterName);
	
	var clusterNames = this.hashArrayKeyToArray(clusters, "cluster");
	clusterNames.splice(0,0, '');
	////console.log("Workflows.setClusterCombo    clusterNames: " + dojo.toJson(clusterNames));

	// REMOVE USERNAME FROM BEGINNING OF CLUSTER NAME
	for ( var i = 0; i < clusterNames.length; i++ )
	{
		clusterNames[i] = clusterNames[i].replace(regex, '');
	}
	clusterNames = clusterNames.sort();
	////console.log("Workflows.setClusterCombo    SORTED clusterNames: " + dojo.toJson(clusterNames));

	// DO data FOR store
	var data = [];
	for ( var i in clusterNames )
	{
		data.push({ name: clusterNames[i]	});
	}
	////console.log("Workflows.setClusterCombo    data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.store.Memory({	idProperty: "name", data: data	});

	this.clusterCombo.store = store;
	this.clusterCombo.startup();
	this.clusterCombo.set('value', clusterName);			
	
	var longClusterName = clusterName;
	var username = Agua.cookie('username');
	if ( clusterName )	longClusterName = username + "-" + clusterName;

	this.setClusterNodes(longClusterName);
},
checkClusterNodes : function (event) {
	////console.log("Workflows.checkClusterNodes    plugins.core.Common.checkClusterNodes(event)");
	////console.log("Workflows.checkClusterNodes    event.keyCode: " + event.keyCode);
	//var key = event.keyCode;
	////console.log("Workflows.checkClusterNodes    key: " + key);

	if (event.keyCode == dojo.keys.ENTER)
	{
		////console.log("Workflows.checkClusterNodes    setting document.body.focus()");
		document.body.focus();
		this.checkNodeNumbers();
		this.updateClusterNodes();
		dojo.stopEvent(event);
	}
},
setClusterNodes : function (clusterName) {
//	RETRIEVE MIN/MAX NODES FOR THE CLUSTER
	console.log("Workflows.setClusterNodes    clusterName: " + clusterName);
	if ( clusterName == null || ! clusterName )
	{
		this.minNodes.set('value', 0);	
		this.maxNodes.set('value', 0);	
		return;
	}
	
	var clusters = Agua.getClusters();
	console.log("Workflows.setClusterNodes    clusters: ");
	console.dir({clusters:clusters});
	clusters = this.filterByKeyValues(clusters, ["cluster"], [clusterName]);
	if ( clusters == null )	return;
	
	if ( clusters[0] != null
		&& clusters[0].minnodes != null
		&& clusters[0].maxnodes != null )
	{
		var minNodes = clusters[0].minnodes;
		var maxNodes = clusters[0].maxnodes;
		console.log("Workflows.setClusterNodes    minNodes: " + minNodes);
		console.log("Workflows.setClusterNodes    maxNodes: " + maxNodes);
		this.minNodes.set('value', minNodes);	
		this.maxNodes.set('value', maxNodes);	
	}
},
checkNodeNumbers : function () {
// SET MIN NODES VALUE TO SENSIBLE NUMBER 
	////console.log("Workflows.checkNodeNumbers     this: " + this);
	////console.log("Workflows.checkNodeNumbers     this.minNodes.get('value'): " + this.minNodes.get('value'));
	////console.log("Workflows.checkNodeNumbers     this.maxNodes.get('value'): " + this.maxNodes.get('value'));
	
	if (this.minNodes.get('value') > this.maxNodes.get('value') )
	{
		////console.log("Workflows.checkNodeNumbers     this.minNodes.get('value') > this.maxNodes.get('value')");
		this.minNodes.set('value', this.maxNodes.get('value'));
	}
},
updateClusterNodes : function () {
	//console.log("Workflows.updateClusterNodes    this.ready: " + this.ready);
	if ( ! this.ready )	return;
	
	var cluster = this.getCluster();
	//console.log("Workflows.updateClusterNodes    cluster: " + cluster);
	
	if ( ! cluster )	return;

	var clusterName = Agua.getClusterLongName(cluster);
	
	if ( this.savingCluster == true )	return;
	this.savingCluster = true;

	var clusterName = Agua.getClusterLongName(cluster);
	var clusterObject = Agua.getClusterObject(clusterName);

	// GET MIN
	var minValue = this.minNodes.get('value');
	//console.log("Workflows.updateClusterNodes    minValue: " + minValue);
	if ( ! minValue )	{
		this.minNodes.set('value', clusterObject.minnodes);
		return;
	}
	else
		clusterObject.minnodes = minValue;	

	// GET MAX
	var maxValue = this.maxNodes.get('value');
	//console.log("Workflows.updateClusterNodes    maxValue: " + maxValue);
	if ( ! maxValue )	{
		this.maxNodes.set('value', clusterObject.maxnodes);
		return;
	}
	else
		clusterObject.maxnodes = maxValue;
		
	//console.log("Workflows.updateClusterNodes    clusterObject: ");
	//console.dir({clusterObject:clusterObject});

	Agua._removeCluster(clusterObject);
	Agua._addCluster(clusterObject);

	this.savingCluster = false;

	// SAVE ON REMOTE DATABASE
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = dojo.clone(clusterObject);
	query.username = Agua.cookie('username');	
	query.sessionid = Agua.cookie('sessionid');	
	query.mode = "updateClusterNodes";
	query.module = "Agua::Admin";
	//console.log("Workflows.updateClusterNodes    query: " + dojo.toJson(query));
	
	// SEND TO SERVER
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			handle: function(response, ioArgs) {
				//console.log("Workflows.updateClusterNodes    response: ");
				//console.dir({response:response});
				if ( response.error ) {
					Agua.toast(response);
				}
			}
		}
	);

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateClusters");	

}, // Clusters.updateClusterNodes
saveClusterWorkflow : function (event) {
//	SAVE A PARAMETER TO Agua.parameters AND TO REMOTE DATABASE

	// AVOID SELF-TRIGGERING OF onChange EVENT WHEN CHANGED PROGRAMMATICALLY
	if ( this.savingCluster == true )	return;
	this.savingCluster = true;

	var cluster = this.getCluster();
	var clusterName = Agua.getClusterLongName(cluster);
	var project = this.getProject();
	var workflow = this.getWorkflow();
	
	if ( project == null || ! project )	return;
	if ( workflow == null || ! workflow )	return;
	
	var clusterObject = new Object;
	clusterObject.cluster = clusterName;
	clusterObject.project = project;
	clusterObject.workflow = workflow;
	////console.log("Workflows.saveClusterWorkflow    clusterObject: " + dojo.toJson(clusterObject));

	if ( Agua.isClusterWorkflow(clusterObject) )
	{
		this.savingCluster = false;
		return;
	}
	
	Agua._removeClusterWorkflow(clusterObject);
	if ( ! Agua._addClusterWorkflow(clusterObject) )
	{
		this.savingCluster = false;
		return;
	}
	
	this.savingCluster = false;

	// SAVE ON REMOTE DATABASE
	var query = dojo.clone(clusterObject);
	query.username = Agua.cookie('username');	
	query.sessionid = Agua.cookie('sessionid');	
	query.mode = "saveClusterWorkflow";
	query.module 		= 	"Agua::Workflow";
	var url = Agua.cgiUrl + "agua.cgi?";
	console.log("Workflows.saveClusterWorkflow    query: " + dojo.toJson(query));
	
	// SEND TO SERVER
	Agua.doPut({
		query: query,
		url: url
	});
	
	var longClusterName = cluster;
	var username = Agua.cookie('username');	
	if ( cluster )	longClusterName = username + "-" + cluster;

	this.setClusterNodes(longClusterName);
	
}, 
/////////////////		INFOPANE METHODS         
clearParameters : function () {
// CLEAR INFO PANE
	////console.log("Workflows.clearParameters    plugins.workflow.Workflows.clearParameters()");

	if ( this.core.parameters == null )
	{
		////console.log("Workflows.clearParameters    this.core.parameters is null. Returning");
		return;
	}

	////console.log("Workflows.clearParameters    DOING this.core.parameters.clear()");
	this.core.parameters.clear();
},
loadParametersPane : function (node) {
// LOAD DATA INTO INFO PANE FROM THE APPLICATION ASSOCIATED WITH THIS NODE
// OVERLOAD THIS TO PASS ADDITIONAL ARGUMENTS TO Parameters.load()
	console.group("Workflows-" + this.id + "    loadParametersPane");
	console.log("Workflows.loadParametersPane    plugins.workflow.Workflows.loadParametersPane(node)");
	
	// WARN AND QUIT IF NO NODE PASSED, E.G., IF WORKFLOW HAS NO STAGES
	if ( node == null )
	{
		//console.log("Workflows.loadParametersPane     Passed node is null (no applications in dropTarget). Returning.");
		console.groupEnd("Workflows-" + this.id + "    loadParametersPane");
		return;
	}
	console.log("Workflows.loadParametersPane    node.application: ");
	console.dir({application:node.application});

	if ( this.core.parameters != null )
	{
		console.log("Workflows.loadParametersPane    Doing this.core.parameters.load(node)");
		this.core.parameters.load(node);
	}
	else
	{
		//console.log("Workflows.loadParametersPane    this.core.parameters is null. Skipping this.core.parameters.load()");
	}
	console.groupEnd("Workflows-" + this.id + "    loadParametersPane");
},
/////////////////		IO METHODS      
setWorkflowIO : function () {
// INITIATE this.core.io OBJECT

	////console.log("Workflows.setWorkflowIO    plugins.workflow.Workflows.setWorkflowIO()");
	if ( this.core.io == null )
	{
		this.core.io = new plugins.workflow.IO(
			{
				parentWidget: this,
				core: this.core
			}
		);
		////console.log("Workflows.setWorkflowIO    this.core.io: " + this.core.io);
	}
},
getChainedValues : function (node) {
// SET THE input, resource AND output PARAMETERS OF THIS STAGE USING
// ANY CORRESPONDING PARAMETERS IN THE PRECEDING STAGE

	//console.group("Workflows-" + this.id + "    getChainedValues");
	////console.log("Workflows.getChainedValues    plugins.workflow.Workflows.getChainedValues(node)");
	////console.log("Workflows.getChainedValues    node: " + node);
	////console.log("Workflows.getChainedValues    node.application: " + dojo.toJson(node.application));
	////console.log("Workflows.getChainedValues    this.core.io: " + this.core.io);

	// CHECK node.application AND node.application.number ARE DEFINED
	////console.log("Workflows.getChainedValues    application: " + dojo.toJson(node.application));
	// GET THE INDEX OF THIS APPLICATION
	if ( node.application == null )
	{
		////console.log("Workflows.getChainedValues    node.application is null. Returning.");
		//console.groupEnd("Workflows-" + this.id + "    getChainedValues");
		return;
	}

	// GET THE INDEX OF THIS APPLICATION
	if ( node.application.number == null )
	{
		this.quit("Workflows.getChainedValues    node.application.number is null. Returning.");
		//console.groupEnd("Workflows-" + this.id + "    getChainedValues");
		return;
	}

	// CHANGE THE STAGE PARAMETERS FOR THIS APPLICATION
	// IF THE args FIELD IS NOT NULL (ALSO params AND paramFunction)
	var force = true;
	this.core.io.chainStage(node.application, force);

	//console.groupEnd("Workflows-" + this.id + "    getChainedValues");
},
chainStages : function (force) {
// CHAIN THE INPUTS/OUTPUTS OF ALL APPLICATIONS IN THE WORKFLOW
// NB: NOT USED YET, JUST IN CASE

	console.log("Workflows.chainStages     plugins.workflow.Workflow.chainStages(force)");
	console.log("Workflows.chainStages     force: " + force);
	
	console.log("Workflows.chainStages    this.dropTarget: " + this.dropTarget);

	var nodes = this.dropTarget.getAllNodes();
	console.log("Workflows.chainStages     nodes.length: " + nodes.length);

	for ( var i = 0; i < nodes.length; i++ )
	{
		////console.log("Workflows.chainStages     nodes[i].application: " + nodes[i].application);
		this.core.io.chainInputs(nodes[i].application, force);
		
		// UPDATE VALID/INVALID CSS IN PARAMETERS PANE
		if ( this.core.parameters != null )
		{
			var keys = ["project", "workflow", "workflownumber", "name", "number"];
			if ( this._objectsMatchByKey(nodes[i].application,
				this.core.parameters.application, keys) )
				this.core.parameters.setParameterRowStyles();
		}
	} 
	
},
/////////////////		PROJECT METHODS      
getProject : function () {
	console.log("Workflows.getProject     caller: " + this.getProject.caller.nom);

	console.log("Workflows.getProject     this.projectCombo.get('value'): " + this.projectCombo.get('value'));
	return this.projectCombo.get('value');
},
setProjectCombo : function (projectName, workflow) {
// POPULATE THE PROJECT COMBO AND THEN RELOAD THE WORKFLOW COMBO
	////console.log("Workflows.setProjectCombo    workflow.Workflows.setProjectCombo(projectName, workflow)");
	////console.log("Workflows.setProjectCombo    projectName: " + projectName);
	////console.log("Workflows.setProjectCombo    workflow: " + workflow);

	// TO AVOID GRATUITOUS EVENT BY onChange LISTENER
	this.settingProject = true;
	
	////console.log("Workflows.setProjectCombo    BEFORE this.inherited(arguments)");
	this.inherited(arguments);
	////console.log("Workflows.setProjectCombo    AFTER this.inherited(arguments)");
	
	if ( projectName == null )
	{
		projectName = this.projectCombo.getValue();
	}

	// RESET THE WORKFLOW COMBO
	////console.log("Workflows.setProjectCombo    END. Doing this.setWorkflowCombo(projectName, workflow)");
	this.setWorkflowCombo(projectName, workflow);
},
setProjectListeners : function () {
	//console.log("Workflows.setProjectListeners    plugins.workflow.Workflows.setProjectListeners()");
	
	// DOJO.CONNECT TO CHANGE THE workflowCombo
	var thisObject = this;
	dojo.connect(this.projectCombo, "onChange", dojo.hitch(this, function(event) {
		var project = event;
		console.log("Workflows.setProjectListeners    this.projectCombo onchange event. DOING this.setWorkflowCombo(" + project + ")");
		//console.log("Workflows.setProjectListeners    thisObject.ready: " + thisObject.ready);

		//if ( thisObject.ready == false) {
		//	console.log("Workflows.setProjectListeners    ONCHANGE fired. thisObject.ready is FALSE. Returning");
		//	//thisObject.settingProject = false;
		//	return;
		//}
		
		// CLEAR THE INFO PANE
		//console.log("Workflows.setProjectListeners    thisObject.clearParameters()");
		thisObject.clearParameters();

		// RESET THE RUNSTATUS PANE		
		//console.log("Workflows.setProjectListeners    thisObject.clearParameters()");
		thisObject.clearRunStatus();
		
		// SET WORKFLOW COMBO
		////console.log("Workflows.setProjectListeners    DOING thisObject.setWorkflowCombo(" + project + ")");
		thisObject.setWorkflowCombo(project);
		//event.stopPropagation();
	}));

	// SET NEW PROJECT LISTENER
	var thisObject = this;
	this.projectCombo._onKey = function(evt){
		////console.log("Workflows.setProjectListeners._onKey	dijit.form.ComboBox._onKey(/*Event*/ evt)");
		
		// summary: handles keyboard events
		var key = evt.keyCode;
		////console.log("Workflows.setProjectListeners._onKey	key: " + key);
		
		if ( key == 13 )
		{
			//thisObject.projectCombo._hideResultList();
			
			var sourceProject = thisObject.projectCombo.getValue();
			sourceProject = sourceProject.replace(/\s+/g, '');
			thisObject.projectCombo.set('value', sourceProject);

			var projectObject = new Object;
			projectObject.name = sourceProject;
			////console.log("Workflows.setProjectListeners._onKey	   projectObject: " + dojo.toJson(projectObject));
			
			if ( Agua.isProject(sourceProject) == false )
			{
				// CLEAR THE INFO PANE
				thisObject.clearParameters();

				// ADD THE PROJECT
				////console.log("Workflows.setProjectListeners._onKey	   Doing Agua.addProject(projectObject)");
				Agua.addProject(projectObject);
				
				// RELOAD RELEVANT DISPLAYS
				Agua.updater.update("updateProjects");
			}

			if ( thisObject.projectCombo._popupWidget != null )
			{
				thisObject.projectCombo._showResultList();
			}
		}
	};

},
deleteProject : function (event) {
// DELETE A PROJECT AFTER ONCLICK deleteProject BUTTON
	////console.log("Workflows.deleteProject    plugins.workflow.Workflows.deleteProject(event)");
	
	// SET this.doingDelete OR EXIT IF BUSY
	if ( this.doingDelete == true )
	{
		////console.log("Workflows.deleteProject    this.doingDelete is true. Returning.");
		return;
	}
	this.doingDelete = true;

	if ( ! Agua.getStages() )
	{
		////console.log("Workflows.deleteProject    Agua.stages not defined. Returning.");
		return;
	}
	
	// GET DELETED PROJECT NAME OR QUIT IF EMPTY
	var project = this.projectCombo.getValue();
	////console.log("Workflows.deleteProject    project: " + project);
	if ( project == null || ! project )
	{
		////console.log("Workflows.deleteWorkflow    deleted project is null. Returning.");
		this.doingDelete = false;
		return;
	}

	// SET ARGS FOR CONFIRM DELETE
	var args = new Object;
	args.project = project;
	args.workflow = null;
	
	// DO CONFIRM DELETE
	this.confirmDelete(args);
	
	// UNSET this.doingDelete
	this.doingDelete = false;
},
/////////////////		WORKFLOW METHODS      
getWorkflow : function () {
	////console.log("Workflows.getWorkflow     plugins.workflow.Workflow.getWorkflow()");
	console.log("Workflows.getWorkflow     this.workflowCombo.get('value'): " + this.workflowCombo.get('value'));
	return this.workflowCombo.get('value');
},
getWorkflowNumber : function () {
	////console.log("Workflows.getWorkflow     plugins.workflow.Workflow.getWorkflow()");
	var project = this.getProject();
	var workflow = this.getWorkflow();
	if ( project == null || workflow == null ) {
		////console.log("Workflows.getWorkflow    project or workflow is null. Returning null");
		return;
	}

	return Agua.getWorkflowNumber(project, workflow);
},
setWorkflowCombo : function (projectName, workflowName) {
// POPULATE THE WORKFLOW COMBO BASED ON SELECT VALUE IN PROJECT COMBO
	//console.group("Workflows-" + this.id + "    setWorkflowCombo");
	//console.log("Workflows.setWorkflowCombo    caller: " + this.setWorkflowCombo.caller.nom);
	//console.log("Workflows.setWorkflowCombo    this.ready: " + this.ready);

	// POPULATE THE WORKFLOW COMBO AND SET FIRST VALUE TO
	// workflowName OR THE FIRST WORKFLOW IF workflowName NOT DEFINED
	this.inherited(arguments);

	// SET DROP TARGET (LOAD MIDDLE PANE, BOTTOM)
	if ( workflowName == null )
		workflowName = this.workflowCombo.getValue();
	
	////console.log("Workflows.setWorkflowCombo    DOING this.setClusterCombo(" + projectName + ", " + workflowName + ")");
	this.setClusterCombo(projectName, workflowName);

	////console.log("Workflows.setWorkflowCombo    DOING this.updateDropTarget(" + projectName + ", " + workflowName + ")");
	this.updateDropTarget(projectName, workflowName);

	//console.groupEnd("Workflows-" + this.id + "    setWorkflowCombo");
},
setWorkflowListeners : function () {
////console.log("Workflows.setWorkflowListeners    plugins.workflow.Workflows.setWorkflowListeners()");
	// DOJO.CONNECT TO POPULATE APPLICATIONS IN DROP TARGET
	// WHICH THEN POPULATES THE INFO PANE 

	var thisObject = this;
	dojo.connect(thisObject.workflowCombo, "onChange", dojo.hitch(this, function(event) {
		//console.log("Workflows.setWorkflowListeners    onchange event. Workflow is: " + event);
		//console.log("Workflows.setWorkflowListeners    this.ready: " + this.ready);
		var workflowName = event;
		var projectName = thisObject.getProject();

		if ( thisObject.ready == false) {
			//console.log("Workflows.setWorkflowListeners    ONCHANGE fired. thisObject.ready is FALSE. Returning");
			return;
		}

		// RESET THE RUNSTATUS PANE		
		thisObject.clearRunStatus();
		
		////console.log("Workflows.setWorkflowListeners    DOING this.setClusterCombo(" + projectName + ", " + workflowName + ")");
		thisObject.setClusterCombo(projectName, workflowName);

		////console.log("Workflows.setWorkflowListeners    connect onchange. Doing thisObject.updateDropTarget(" + projectName + ", " + workflowName + ")");		
		thisObject.updateDropTarget(projectName, workflowName);
	}));

	// SET NEW PROJECT LISTENER
	var thisObject = this;
	this.workflowCombo._onKey = function(evt){
		////console.log("Workflows.setWorkflowCombo._onKey	dijit.form.ComboBox._onKey(/*Event*/ evt)");
		
		// summary: handles keyboard events
		var key = evt.keyCode;			
		////console.log("Workflows.setWorkflowCombo._onKey	key: " + key);
		if ( key == 13 ) {
			//thisObject.workflowCombo._hideResultList();
			
			var projectName = thisObject.getProject();
			var workflowName = thisObject.getWorkflow();
			workflowName = workflowName.replace(/\s+/g, '');
			thisObject.workflowCombo.set('value', workflowName);
			////console.log("Workflows.setWorkflowCombo._onKey	   projectName: " + projectName);
			////console.log("Workflows.setWorkflowCombo._onKey	   workflowName: " + workflowName);
			
			// STOP PROPAGATION
			evt.stopPropagation();
			
			var isWorkflow = Agua.isWorkflow({ project: projectName, name: workflowName });
			if ( isWorkflow == false ) {
				Agua.addWorkflow({ project: projectName, name: workflowName });
				////console.log("Workflows.setWorkflowCombo._onKey	isWorkflow is FALSE. Doing thisObject.setWorkflowCombo(projectName, workflowName)");
				thisObject.setWorkflowCombo(projectName, workflowName);
			}
				
			if ( thisObject.workflowCombo._popupWidget != null ) {
				thisObject.workflowCombo._showResultList();
			}
		}
	};
},
newWorkflow : function (sourceProject, workflowName) {
// CREATE A NEW WORKFLOW ON TRIGGER this.workflowCombo._onKey ENTER

	////console.log("Common.newWorkflow    plugins.workflow.Common.addWorkflow(workflowObject)");
	////console.log("Common.newWorkflow    sourceProject: " + sourceProject);
	////console.log("Common.newWorkflow    workflowName: " + workflowName);

	if ( this.doingNewWorkflow == true ) {
		////console.log("Common.newWorkflow    this.doingNewWorkflow is true. Returning.");
		return;
	}
	
	// SET this.doingNewWorkflow
	this.doingNewWorkflow = true;

	// SEND TO SERVER
	Agua.addWorkflow({ project: sourceProject, name: workflowName });
	
	// UNSET this.doingNewWorkflow
	this.doingNewWorkflow = false;

	// RESET THE WORKFLOW COMBO
	////console.log("Common.newWorkflow    Doing this.setWorkflowCombo(sourceProject, workflowName)");
	this.setWorkflowCombo(sourceProject, workflowName);

	// SEND TO SERVER
	Agua.addProjectWorkflow(sourceProject, workflowName);
},
setComboButtons : function () {
// SET ONLICK LISTENERS FOR PROJECT AND WORKFLOW DELETE BUTTONS
	
	// SET download BUTTON ONCLICK TO OPEN FILE MANAGER
	var thisObject = this;
	
	dojo.connect(this.deleteProjectButton, "onclick", function(event)
	{
		thisObject.deleteProject(event);
	});
	
	dojo.connect(this.deleteWorkflowButton, "onclick", function(event)
	{
		thisObject.deleteWorkflow(event);
	});
},
deleteWorkflow : function (event) {
// DELETE A WORKFLOW AFTER ONCLICK deleteWorkflow BUTTON

	console.log("Workflows.deleteWorkflow    event:");
	console.dir({event:event});

	// SET this.doingDelete OR EXIT IF BUSY
	if ( this.doingDelete == true ) {
		////console.log("Workflows.deleteWorkflow    this.doingDelete is true. Returning.");
		return;
	}
	this.doingDelete = true;
	
	// GET DELETED PROJECT NAME OR QUIT IF EMPTY
	var project = this.projectCombo.getValue();
	if ( project == null || ! project ) {
		////console.log("Workflows.deleteWorkflow    project is null. Returning.");
		this.doingDelete = false;
		return;
	}
	////console.log("Workflows.deleteWorkflow    project: " + project);
	
	// GET DELETED WORKFLOW NAME OR QUIT IF EMPTY
	var workflow = this.workflowCombo.getValue();
	if ( workflow == null || ! workflow ) {
		////console.log("Workflows.deleteWorkflow    workflow is null. Returning.");
		this.doingDelete = false;
		return;
	}
	////console.log("Workflows.deleteWorkflow    workflow: " + workflow);

	// SET ARGS FOR CONFIRM DELETE
	var args = new Object;
	args.project = project;
	args.workflow = workflow;
	
	// DO CONFIRM DELETE
	this.confirmDelete(args);

	// UNSET this.doingDelete
	this.doingDelete = false;
},
indexOfRunningStage : function () {
	var project = this.getProject();
	var workflow = this.getWorkflow();
	////console.log("Workflows.indexOfRunningStage    project: " + project);
	////console.log("Workflows.indexOfRunningStage    workflow: " + workflow);

	var stages = Agua.getStagesByWorkflow(project, workflow);
	////console.log("Workflows.indexOfRunningStage    stages: " + dojo.toJson(stages));
	var running = 0;
	for ( var i = 0; i < stages.length; i++ ) {
		if ( stages[i].status == "running" )	return i + 1;
	}
	
	return 0;
},
/////////////////		STAGE METHODS         
updateStageNumber : function (stageObject, previousNumber) {
// UPDATE THE number OF A STAGE IN this.stages
// AND ON THE REMOTE SERVER

	////console.log("Workflows.updateStageNumber     Workflow.updateStageNumber(stageObject)");
	////console.log("Workflows.updateStageNumber    stageObject.project: " + stageObject.project);
	////console.log("Workflows.updateStageNumber    stageObject.workflow: " + stageObject.workflow);
	////console.log("Workflows.updateStageNumber    stageObject.name: " + stageObject.name);
	////console.log("Workflows.updateStageNumber    stageObject.number: " + stageObject.number);
	
	// REMOVE FROM Agua DATA
	var addOk = Agua.updateStageNumber(stageObject, previousNumber);
	if ( ! addOk )
	{
		////console.log("Workflows.updateStageNumber    Failed to add stage to Agua data");
		return;
	}
	////console.log("Workflows.updateStageNumber     addOk: " + addOk);
},
/////////////////		RUN STATUS METHODS         
clearRunStatus : function () {
	////console.log("Workflows.clearRunStatus    plugins.workflow.Workflows.clearRunStatus()");
	if ( this.core.runStatus == null )	return;

	////console.log("Workflows.clearRunStatus    this.core.runStatus: " + this.core.runStatus);
	this.core.runStatus.clear();
	this.core.runStatus.polling = false;
},
/////////////////		RUN BUTTON METHODS         
updateRunButton : function () {
// CHECK ALL STAGE INPUTS ARE VALID, ADJUST 'RUN' BUTTON CSS ACCORDINGLY

	console.log("Workflows.updateRunButton    plugins.workflow.Workflows.updateRunButton()");
	console.log("Workflows.updateRunButton    this.dropTarget: " + this.dropTarget);
	if ( ! this.dropTarget ) {
		console.log("Workflows.updateRunButton    Returning because this.dropTarget not defined");
		return;
	}

	var stageNodes = this.dropTarget.getAllNodes();
	console.log("Workflows.updateRunButton    stageNodes.length: " + stageNodes.length);

	this.isValid = true;
	
	for ( var i = 0; i < stageNodes.length; i++ )
	{
		var stageRow = stageNodes[i].parentWidget;
		//var stageRow = dijit.getEnclosingWidget(stageNodes[i]);
		if ( stageRow == null )
			stageRow = dijit.byNode(stageNodes[i].firstChild);
		
		if ( stageRow == null )
		{
			////console.log("Workflows.updateRunButton    [" + (i + 1) + "]    stageRow is NULL. Setting this.isValid = false and returning");
			this.isValid = false;
			return;
		}

		////console.log("Workflows.updateRunButton    [" + i + "]    StageRow (" + (i + 1) + " of " + stageNodes.length + ") isValid : "  + stageRow.isValid);
		
		if ( stageRow.isValid == false || stageRow.isValid == null )
			this.isValid = false;
	}	
	////console.log("Workflows.updateRunButton    this.isValid: " + this.isValid);
	
	if ( this.isValid == true )	this.enableRunButton();
	else this.disableRunButton();
},
enableRunButton : function () {
// ENABLE RUN BUTTON - ADD ONCLICK AND REMOVE invalid CSS

	////console.log("Workflows.enableRunButton    plugins.workflow.Workflows.enableRunButton()");

	// GET RUN BUTTON AND TITLE NODE		
	var node = this.runButton;
	////console.log("Workflows.enableRunButton    node: " + node);

	// ADD enabled CSS
	dojo.removeClass(node, 'runButtonDisabled');
	dojo.addClass(node, 'runButtonEnabled');

	// REMOVE 'RUN' ONCLICK
	if ( node.onclickListener != null )
	{
		dojo.disconnect(node.onclickListener);
	}

	// SET 'RUN' ONCLICK
	if ( this.shared == true )	return;
	var thisObject = this;
	node.onclickListener = dojo.connect( node, "onclick", function(event)
	{
		console.log("Workflows.enableRunButton     runButton onclick triggered");
		
		// RUN ALL STAGES IN THE WORKFLOW (ASSUMES ALL STAGES ARE VALID)
		if ( thisObject.core.runStatus == null )	return;
		var runner = thisObject.core.runStatus.createRunner(1);	
		thisObject.core.runStatus.runWorkflow(runner);
	});
},
disableRunButton : function () {
// DISABLE RUN BUTTON - REMOVE ONCLICK AND ADD invalid CSS

	////console.log("Workflows.disableRunButton    plugins.workflow.Workflows.disableRunButton()");
	
	// GET RUN BUTTON AND TITLE NODE		
	var node = this.runButton;
	////console.log("Workflows.disableRunButton    node: " + node);

	// REMOVE enabled CSS
	dojo.removeClass(node, 'runButtonEnabled');
	dojo.addClass(node, 'runButtonDisabled');


	// REMOVE 'RUN' ONCLICK
	if ( node.onclickListener != null )
	{
		dojo.disconnect(node.onclickListener);
	}
	
},
/////////////////		CONFIRM DELETE
commitDelete : function (args) {
// DELETE THE WORKFLOW/PROJECT AND UPDATE THE WORKFLOW COMBO BOX
	////console.log("Workflows.commitDelete    plugins.workflow.Workflows.commitDelete(args)");
	console.log("Workflows.commitDelete    args: " + dojo.toJson(args));
	
	if ( args.project == null )	return;
	
	// DELETE THE WORKFLOW AND UPDATE THE WORKFLOW COMBO BOX
	if ( args.workflow != null ) {
		Agua.removeWorkflow({ project: args.project, name: args.workflow});
	
		// CLEAR THE INFO PANE
		this.clearParameters();
	
		//  RESET THE WORKFLOW COMBO
		var sourceProject = this.projectCombo.getValue();
		this.setWorkflowCombo(sourceProject);
		Agua.toastMessage({
			message: "Deleted workflow: " + args.project + "." + args.workflow,
			type: "message"
		});
		
		// RELOAD RELEVANT DISPLAYS
		Agua.updater.update("updateWorkflows", {originator:this, reload: false});	
	}
	
	// DELETE THE PROJECT AND UPDATE THE PROJECT COMBO BOX
	else {
		Agua.removeProject({ name: args.project });
	
		// RELOAD RELEVANT DISPLAYS
		Agua.updater.update("updateProjects");

		Agua.toastMessage({
			message: "Deleted project '" + args.project + "'",
			type: "warning"
		});

		// RELOAD RELEVANT DISPLAYS
		Agua.updater.update("updateProjects", {originator:this, reload: false});	
	}
},
confirmDelete : function (args) {
	////console.log("Workflows.confirmDelete    plugins.workflow.Workflows.confirmDelete(args)");
	console.log("Workflows.confirmDelete    args: " + dojo.toJson(args));

	// SET CALLBACKS
	var thisObject = this;
	var yesCallback = function()
	{
		thisObject.commitDelete(args);
	};
	var noCallback = function(){};

	// SET TITLE
	var title = "Delete project: " + args.project + "?";
	if ( args.workflow != null )
		title = "Delete workflow: " + args.workflow + "?";

	// SET MESSAGE
	var message = "All stages and data will be destroyed<br><span style='color: #222;'>Click 'Yes' to delete or 'No' to cancel</span>";
	if ( args.workflow != null )
		message = "All data will be destroyed<br><span style='color: #222;'>Click 'Yes' to delete or 'No' to cancel</span>";

	////console.log("Workflows.confirmDelete    title: " + title);
	////console.log("Workflows.confirmDelete    message: " + message);

	// IF NOT EXISTS, INSTANTIATE WIDGET CONTAINING CONFIRMATION DIALOGUE POPUP
	if ( this.confirm != null ) 	this.confirm.destroy();

	// LOAD THE NEW VALUES AND SHOW THE DIALOGUE
	this.confirm = new plugins.dijit.Confirm({
		parentWidget : this,
		title: title,
		message : message,
		yesCallback : yesCallback,
		noCallback : noCallback
	});
	this.confirm.show();
},
setSelectiveDialog : function () {
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "";
	var message = "";
	var inputMessage = "";
	
	////console.log("Workflows.setSelectiveDialog    plugins.workflow.Workflows.setSelectiveDialog()");
	this.selectiveDialog = new plugins.dijit.SelectiveDialog(
		{
			title 				:	title,
			message 			:	message,
			inputMessage 		:	inputMessage,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
	////console.log("Workflows.setSelectiveDialog    this.selectiveDialog: " + this.selectiveDialog);
},
loadSelectiveDialog : function (title, message, comboValues, inputMessage, comboMessage, checkboxMessage, enterCallback, cancelCallback) {
	////console.log("Workflows.loadSelectiveDialog    plugins.workflow.Workflows.loadSelectiveDialog()");
	////console.log("Workflows.loadSelectiveDialog    enterCallback.toString(): " + enterCallback.toString());
	////console.log("Workflows.loadSelectiveDialog    title: " + title);
	////console.log("Workflows.loadSelectiveDialog    message: " + message);
	////console.log("Workflows.loadSelectiveDialog    enterCallback: " + enterCallback);
	////console.log("Workflows.loadSelectiveDialog    cancelCallback: " + cancelCallback);

	this.selectiveDialog.load(
		{
			title 				:	title,
			message 			:	message,
			comboValues 		:	comboValues,
			inputMessage 		:	inputMessage,
			comboMessage 		:	comboMessage,
			checkboxMessage		:	checkboxMessage,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}
	);
},
setInteractiveDialog : function () {
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "";
	var message = "";
	var inputMessage = "";
	
	////console.log("FileMenu.setInteractiveDialog    plugins.files.FileMenu.setInteractiveDialog()");
	this.interactiveDialog = new plugins.dijit.InteractiveDialog(
		{
			title 				:	title,
			message 			:	message,
			inputMessage 		:	inputMessage,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
	////console.log("FileMenu.setInteractiveDialog    this.interactiveDialog: " + this.interactiveDialog);
},
loadInteractiveDialog : function (title, message, enterCallback, cancelCallback, checkboxMessage) {
	////console.log("FileMenu.loadInteractiveDialog    plugins.files.FileMenu.loadInteractiveDialog()");
	////console.log("FileMenu.loadInteractiveDialog    enterCallback.toString(): " + enterCallback.toString());
	////console.log("FileMenu.loadInteractiveDialog    title: " + title);
	////console.log("FileMenu.loadInteractiveDialog    message: " + message);
	////console.log("FileMenu.loadInteractiveDialog    checkboxMessage: " + checkboxMessage);
	////console.log("FileMenu.loadInteractiveDialog    enterCallback: " + enterCallback);
	////console.log("FileMenu.loadInteractiveDialog    cancelCallback: " + cancelCallback);

	this.interactiveDialog.load(
		{
			title 				:	title,
			message 			:	message,
			checkboxMessage 	:	checkboxMessage,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
},
/////////////////		COPY WORKFLOW / PROJECT
copyWorkflow : function () {
// DISPLAY A 'Copy Workflow' DIALOG THAT ALLOWS THE USER TO SELECT 
// THE DESTINATION PROJECT AND THE NAME OF THE NEW WORKFLOW

	////console.log("Workflows.copyWorkflow    plugins.workflow.Workflows.copyWorkflow()");
	////console.log("Workflows.copyWorkflow    this.selectiveDialog: " + this.selectiveDialog);

	// SET TITLE AND MESSAGE
	var sourceProject = this.projectCombo.get('value');
	var sourceWorkflow = this.workflowCombo.get('value');

	////console.log("Workflows.copyWorkflow     Agua.getProjectNames(): " + dojo.toJson(Agua.getProjectNames()));


	// SET CALLBACKS
	var cancelCallback = function (){
		////console.log("Workflows.copyWorkflow    cancelCallback()");
	};
	var thisObject = this;
	
	var enterCallback = dojo.hitch(this, function (targetWorkflow, targetProject, copyFiles, dialogWidget)
		{
			////console.log("Workflows.copyWorkflow    Doing enterCallback(targetWorkflow, targetProject, copyfiles, dialogWidget)");
			////console.log("Workflows.copyWorkflow    targetWorkflow: " + targetWorkflow);
			////console.log("Workflows.copyWorkflow    targetProject: " + targetProject);
			////console.log("Workflows.copyWorkflow    copyFiles: " + copyFiles);
			////console.log("Workflows.copyWorkflow    dialogWidget: " + dialogWidget);
			
			// SET BUTTON LABELS
			var enterLabel = "Copy";
			var cancelLabel = "Cancel";
			
			// SANITY CHECK
			if ( targetWorkflow == null || targetWorkflow == '' )	return;
			targetWorkflow = targetWorkflow.replace(/\s+/, '');
			////console.log("Workflows.copyWorkflow    targetWorkflow: " + targetWorkflow);

			// QUIT IF WORKFLOW EXISTS ALREADY
			if ( Agua.isWorkflow({ project: targetProject, name: targetWorkflow }) == true )
			{
				////console.log("Workflows.copyWorkflow    Workflow '" + targetWorkflow + "' already exists in project " + targetProject + ". Sending message to dialog.");
				////console.dir({messageNode: dialogWidget.messageNode});
				dialogWidget.messageNode.innerHTML = "/" + targetWorkflow + "' already exists in '" + targetProject + "'";
				return;
			}
			else {
				////console.log("Workflows.copyWorkflow    Workflow '" + targetWorkflow + "' is unique in project " + targetProject + ". Adding workflow.");
				dialogWidget.messageNode.innerHTML = "Creating workflow";
				dialogWidget.close();
			}
			
			thisObject._copyWorkflow(sourceProject, sourceWorkflow, targetProject, targetWorkflow, copyFiles);
		}
	);		

	// SHOW THE DIALOG
	this.selectiveDialog.load(
		{
			title 				:	"Copy Workflow",
			message 			:	"Source: '" + sourceProject + ":" + sourceWorkflow + "'",
			comboValues 		:	Agua.getProjectNames(),
			inputMessage 		:	"Workflow",
			comboMessage 		:	"Project",
			checkboxMessage		:	"Copy files",
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback,
			enterLabel			:	"Copy",
			cancelLabel			:	"Cancel"
		}			
	);
},
_copyWorkflow : function (sourceProject, sourceWorkflow, targetProject, targetWorkflow, copyFiles) {
	////console.log("Workflows._copyWorkflow    plugins.workflow.Workflows._copyWorkflow(sourceProject, sourceWorkflow, targetProject, targetWorkflow, copyFiles)");
	
	var username = Agua.cookie('username');
	var success = Agua.copyWorkflow(username, sourceProject, sourceWorkflow, username, targetProject, targetWorkflow, copyFiles);
	////console.log("Workflows._copyWorkflow    success: " + success);

	if ( success == true )
		this.setProjectCombo(targetProject, targetWorkflow);
},
copyProject : function () {
// ADD A NEW WORKFLOW USING A DIALOG BOX FOR WORKFLOW NAME INPUT

	////console.log("Workflows.copyProject    plugins.workflow.Workflows.copyProject()");
	////console.log("Workflows.copyProject    this.interactiveDialog: " + this.interactiveDialog);

	var sourceProject = this.projectCombo.get('value');
	
	// SET CALLBACKS
	var cancelCallback = function (){
		////console.log("Workflows.copyProject    cancelCallback()");
	};
	
	var thisObject = this;
	var enterCallback = dojo.hitch(this, function (targetProject, copyFiles, interactiveDialog)
		{
			////console.log("Workflows.copyProject    Doing enterCallback(targetProject, interactiveDialog");
			////console.log("Workflows.copyProject    targetProject: " + targetProject);
			////console.log("Workflows.copyProject    interactiveDialog: " + interactiveDialog);
		
			// SANITY CHECK
			if ( targetProject == null || targetProject == '' )	return;
			targetProject = targetProject.replace(/\s+/, '');
			////console.log("Workflows.copyProject    targetProject: " + targetProject);

			// QUIT IF WORKFLOW EXISTS ALREADY
			if ( Agua.isProject(targetProject) == true )
			{
				////console.log("Workflows.copyProject    Project '" + targetProject + "' already exists in project " + targetProject + ". Sending message to dialog.");
				
				interactiveDialog.messageNode.innerHTML = "Project name already exists";
				return;
			}
			else {
				////console.log("Workflows.copyProject    Project '" + targetProject + "' is unique in project " + targetProject + ". Adding project.");

				interactiveDialog.messageNode.innerHTML = "Creating project";
				interactiveDialog.close();
			}

			thisObject._copyProject(sourceProject, targetProject, copyFiles);
		}
	);	

	// SHOW THE DIALOG
	this.interactiveDialog.load(
		{
			title 				:	"Copy Project",
			message 			:	"Please enter project name",
			checkboxMessage 	:	"Copy files",
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
},
_copyProject : function (sourceProject, targetProject, copyFiles) {
	////console.log("Workflows._copyProject    plugins.workflow.Workflows._copyProject(sourceProject, sourceProject, targetProject, targetProject, copyFiles)");

	var username = Agua.cookie('username');
	// ADD PROJECT
	Agua.copyProject(username, sourceProject, username, targetProject, copyFiles);

	this.setProjectCombo(targetProject);
}

}); // plugins.workflow.Workflows
