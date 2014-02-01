dojo.provide("plugins.workflow.RunStatus.Status");

/* PURPOSE: POLL SERVER FOR UPDATED INFORMATION ON
 * CLUSTER AND WORKFLOW STATUS

	xhrPut RESPONSE FORMAT:

	{
		stagestatus 	=> 	{
			project		=>	String,
			workflow	=>	String,
			stages		=>	HashArray,
			status		=>	String
		},
		clusterstatus	=>	{
			project		=>	String,
			workflow	=>	String,
			list		=>	String,
			log			=> 	String,
			status		=>	String
		},
		queuestatus		=>	{
			queue		=>	String,
			status		=>	String			
		}
	}
*/

// TITLE PANE
dojo.require("dijit.TitlePane");

// HAS A
dojo.require("plugins.workflow.RunStatus.ClusterStatus");
dojo.require("plugins.workflow.RunStatus.QueueStatus");
dojo.require("plugins.workflow.RunStatus.StageStatus");
dojo.require("plugins.dijit.ConfirmDialog");

// INHERITS
dojo.require("plugins.core.Common");

dojo.declare( "plugins.workflow.RunStatus.Status",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/RunStatus/templates/runstatus.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins") + "/workflow/RunStatus/css/runstatus.css" ],

// TIMER OBJECT
timer: null,

// timerInterval: integer
// Pause in ms between polls
timerInterval: 20000,

// polling : Boolean
// If false, stop polling
polling : false,

// core : hash
// Workflow-related objects
core : null,

// delay: integer
// Default delay between polls
delay : 11000,

// deferreds: array
// Array of xhr deferred objects
deferreds : [],

/////}}}}]]}}}
constructor : function(args) {
	console.log("Status.constructor    plugins.workflow.RunStatus.constructor(args)");

	// GET ARGS
	this.core = args.core || {};
	this.core.runStatus = this;
	console.log("Status.constructor    args.parentWidget: " + args.parentWidget);
	console.log("Status.constructor    args.attachPoint: " + args.attachPoint);

	if ( args.parentWidget	)	this.parentWidget = args.parentWidget;
	if ( args.attachPoint	)	this.attachPoint = args.attachPoint;

	if ( args.cgiUrl != null )
		this.cgiUrl = args.cgiUrl;
	if ( this.cgiUrl == null )
		this.cgiUrl = 	Agua.cgiUrl + "agua.cgi";

	if ( args.timerInterval	)	this.timerInterval = args.timerInterval;
	
	// LOAD CSS
	this.loadCSS();
},
postMixInProperties: function() {
	console.log("Status.postMixInProperties    plugins.workflow.RunStatus.postMixInProperties()");
},
postCreate: function() {
	console.log("Status.postCreate    plugins.workflow.RunStatus.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Status.startup    caller: " + this.startup.caller.nom);

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	console.log("Status.startup    this.attachPoint: " + this.attachPoint);
	console.log("Status.startup    this.stagesTab: " + this.stagesTab);
	//console.log("Status.startup    this.clusterTab: " + this.clusterTab);
	//console.log("Status.startup    this.queueTab: " + this.queueTab);
	
	// ADD TO TAB CONTAINER		
	if ( this.attachPoint.addChild != null ) {
		this.attachPoint.addChild(this.stagesTab);
		//this.attachPoint.addChild(this.queueTab);
	}
    // OTHERWISE, WE ARE TESTING SO APPEND TO DOC BODY
	else {
		var div = dojo.create('div');
		document.body.appendChild(div);
		div.appendChild(this.stagesTab.domNode);
		//div.appendChild(this.queueTab.domNode);
	}
	//this.attachPoint.selectChild(this.mainTab);	
	
	// START UP CONFIRM DIALOGUE
	this.setConfirmDialog();

	// INSTANTIATE SEQUENCE (POLLING DELAY)
	this.setSequence();

	// SET STAGE STATUS
	this.setStageStatus();

	// SET CLUSTER STATUS
	this.setClusterStatus();

	// SET QUEUE STATUS
	this.setQueueStatus();

	// SET INPUTS AS SELECTED
	this.attachPoint.selectChild(this.core.parameters);
},

// RUN WORKFLOW
runWorkflow : function (runner) {
// RUN WORKFLOW, QUIT IF ERROR, PROMPT FOR stopRun IF ALREADY RUNNING
	console.group("runStatus-" + this.id + "    runWorkflow");
	console.log("RunStatus.runWorkflow      runner: ");
	console.dir(runner);

	// SELECT THIS TAB NODE
	this.attachPoint.selectChild(this.stagesTab);

	// SET this.runner AS RUNNER IF PROVIDED
	if ( runner != null ) {
		delete this.runner;
		this.runner = runner;
	}
	
	var project		=	runner.project;
	var workflow	=	runner.workflow;
	var start		=	runner.start;	
	console.log("Status.runWorkflow      project: " + project);
	console.log("Status.runWorkflow      workflow: " + workflow);
	console.log("Status.runWorkflow      start: " + start);

	// SET MESSAGE
	this.displayWorkflowStatus("starting");

	// GET URL 
	var url = Agua.cgiUrl + "agua.cgi";
	console.log("Status.runWorkflow      url: " + url);		

	// GET submit
	var submit = Agua.getWorkflowSubmit(this.runner);

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query = new Object;
	query.project			=	this.runner.project;
	query.workflow			=	this.runner.workflow;
	query.workflownumber	=	this.runner.workflownumber;
	query.start				=	this.runner.start;
	query.stop				=	this.runner.stop;
	query.username 			= 	Agua.cookie('username');
	query.sessionid	 		= 	Agua.cookie('sessionid');
	query.mode 				= 	"executeWorkflow";
	query.module 		= 	"Agua::Workflow";
	query.submit			=	submit;
	
	// SET CLUSTER 
	query.cluster			=	this.runner.cluster;
	if ( query.cluster != '' )	query.cluster = query.username + "-" + query.cluster;
    else query.cluster = '';
	console.log("Status.runWorkflow     query: " + dojo.toJson(query));

	//// CLEAR DEFERREDS
	//this.clearDeferreds();
	
	// RUN WORKFLOW
	var thisObject = this;
	var deferred = dojo.xhrPut({
		url: url,
		putData: dojo.toJson(query),
		handleAs: "json",
		sync: false,
		handle: function(response){
			console.log("Status.runWorkflow     response: ");
			console.dir({response:response});
			
			// QUIT IF ERROR
			if (response == null ) {
				// SET NODE CLASS TO running
				console.log("0000000000000000000000    RunStatus.runWorkflow     DOING this.setNodeClass(runner.childNodes[" + start + "])");
				thisObject.setNodeClass(runner.childNodes[start - 1], 'running');
			}
			else if ( response.error ) {
				// CLEAR DEFERREDS (KILL PENDING POLL STATUS)
				thisObject.clearDeferreds();
				thisObject.polling = false;
				thisObject.displayNotPolling();
				
				if ( response.error.match(/running$/) {
			        console.log("Status.runWorkflow    Doing this.confirmStopWorkfkow()");
					thisObject.displayWorkflowStatus("running");
					thisObject.confirmStopWorkflow(project, workflow);
				}
				else {
				    Agua.toastError(response.error);
				}
				
				console.groupEnd("runStatus-" + thisObject.id + "    runWorkflow");
				return;
			}
			
			console.groupEnd("runStatus-" + thisObject.id + "    runWorkflow");
		}
	});

    console.log("Status.runWorkflow    AFTER dojo.xhrPut. WAITING FOR RESPONSE");
return;


	this.deferreds.push(deferred);

	// SET POLLING TO TRUE
	this.polling = true;

	// DO DELAYED POLL WORKFLOW STATUS
	// (KILLED IF runWorkflow xhrPut CALL ABOVE RETURNS ERROR)
	var singleton = false;
	var magicNumber = 2000;
	var selectTab = true;
	//this.delayedQueryStatus(this.runner, singleton);
	this.delayCountdownTimeout = setTimeout( function() {
			thisObject.displayActive();
			thisObject.queryStatus(thisObject.runner, singleton, selectTab);
			//thisObject.delayCountdown(countdown, project, workflow);
		},
		magicNumber,
		this
	);
},
checkRunning : function (project, workflow, callback) {
// PERIODICALLY CHECK THE STATUS OF THE WORKFLOW
	console.group("runStatus-" + this.id + "    checkRunning");

	console.log("Status.checkRunning     project: " + project);
	console.log("Status.checkRunning     workflow: " + workflow);
	console.log("Status.checkRunning     callback: " + callback);

	// GET URL 
	var url = Agua.cgiUrl + "agua.cgi";
	console.log("Status.checkRunning     url: " + url);		

	// GENERATE QUERY
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.project 		= 	project;
	query.workflow 		= 	workflow;
	query.mode 			= 	"getStatus";
	query.module 		= 	"Agua::Workflow";
	console.log("Status.checkRunning    query: " + dojo.toJson(query));

	// DO DELAYED POLL WORKFLOW STATUS
	// (KILLED IF runWorkflow CALL RETURNS ERROR)
	var thisObject = this;
	var deferred = dojo.xhrPut(
		{
			url: url,
			putData: dojo.toJson(query),
			handleAs: "json",
			sync: false,
			handle: function(response) {
				console.log("Status.checkRunning    response: ");
				console.dir({response:response});
				
				var isRunning = false;
				if ( response.stagestatus == null )	return false;

				for ( var i = 0; i < response.stagestatus.length; i++ ) {
					if ( response.stagestatus[i].status == "running" ) {
						isRunning = true;
						console.log("Status.checkRunning    stage " + i + " (" + response.stagestatus[i].name + ") is running.");
						break;
					}
				}
				console.log("Status.checkRunning    Doing  callback " + callback + "(" + isRunning + ")");

				thisObject[callback](project, workflow, isRunning);

				console.groupEnd("runStatus-" + thisObject.id + "    checkRunning");
				return null;
			}
		}
	);

	// CLEAR DEFERREDS
	//this.clearDeferreds(deferred);
		
	this.deferreds.push(deferred);
},
createRunner : function (startNumber, stopNumber) {
	console.group("RunStatus-" + this.id + "    createRunner");
	if ( ! this.core.userWorkflows.dropTarget ) {
		console.log("workflow.RunStatus.createRunner    Returning without childNodes because this.core.userWorkflows.dropTarget is null");
		console.groupEnd("RunStatus-" + this.id + "    createRunner");
		return runner;
	}
	
	var childNodes = this.core.userWorkflows.dropTarget.getAllNodes();
	
	if ( startNumber == null )	startNumber = 1;
	if ( stopNumber == null )	stopNumber = childNodes.length;
    console.log("workflow.RunStatus.createRunner    startNumber: " + startNumber);
    console.log("workflow.RunStatus.createRunner    stopNumber: " + stopNumber);

	var projectName 	= this.core.userWorkflows.getProject();
	var workflowName 	= this.core.userWorkflows.getWorkflow();
	var workflowNumber 	= Agua.getWorkflowNumber(projectName, workflowName);
    console.log("workflow.RunStatus.createRunner    workflowNumber: " + workflowNumber);

	var clusterName		= this.core.userWorkflows.getCluster();
    console.log("workflow.RunStatus.createRunner    clusterName: " + clusterName);
	
	var runner 			= new Object;
    runner.username 	= Agua.cookie('username');
    runner.sessionid 	= Agua.cookie('sessionid');
    runner.project 		= projectName;
	runner.workflow 	= workflowName;
	runner.cluster 		= clusterName;
	runner.start 		= startNumber;
	runner.stop 		= stopNumber;
	runner.workflownumber = workflowNumber;
	runner.childNodes = childNodes;
	
    console.log("workflow.RunStatus.createRunner    runner: ");
	console.dir({runner:runner});
	
	console.groupEnd("RunStatus-" + this.id + "    createRunner");
	return runner;
},

// GET STATUS
getStatus : function (runner, singleton) {
// KEEP POLLING SERVER FOR RUN STATUS UNTIL COMPLETE
	console.group("RunStatus-" + this.id + "    getStatus");
	console.log("Status.getStatus    runner: ");
	console.dir({runner:runner});
	console.log("Status.getStatus      singleton: " + singleton);
	console.log("Status.getStatus     this.polling: " + this.polling);

	if ( this.polling == true ) {
		console.log("Status.getStatus     Returning because this.polling is TRUE");
		console.groupEnd("RunStatus-" + this.id + "    getStatus");
		return;
	}
	this.polling = true;
	
	// SET this.runner FOR LATER USE (E.G., IN ClusterStatus.js)
	this.runner = runner;
	if ( ! this.runner )  {
		console.log("Status.getStatus    Doing this.runner	= this.createRunner(stageNumber)");
		var stageNumber = 1;
		this.runner	= this.createRunner(stageNumber);
	}
	this.clusterStatus.runner = this.runner;

	if ( ! this.runner.childNodes && this.core.userWorkflows.dropTarget) {
		this.runner.childNodes = this.core.userWorkflows.dropTarget.getAllNodes();
	}

	if ( singleton ) {
		dojo.addClass(this.toggle, 'pollingActive');
	}
	else {
		dojo.addClass(this.toggle, 'pollingStarted');
	}
	
	var project		=	this.runner.project;
	var workflow	=	this.runner.workflow;
	var start		=	this.runner.start;
	var childNodes	=	this.runner.childNodes;
	console.log("Status.getStatus      project: " + project);
	console.log("Status.getStatus      workflow: " + workflow);
	console.log("Status.getStatus      start: " + start);
	console.log("Status.getStatus      childNodes.length: " + childNodes.length);

	// SET NOTIFIER
	this.displayWorkflowStatus("loading...");

	// SANITY CHECKS
	if ( project == null
		||	workflow == null
		||	start == null ) {
		console.groupEnd("RunStatus-" + this.id + "    getStatus");
		return;
	}
	if ( childNodes == null || ! childNodes || childNodes.length == 0 )
	{
		console.log("Status.getStatus      No childNodes in dropTarget. Returning...");
		console.groupEnd("RunStatus-" + this.id + "    getStatus");
		return;
	}

    // FIRST QUERY
    this.queryStatus(this.runner, singleton);

//	console.groupEnd("RunStatus-" + this.id + "    getStatus");
},
queryStatus : function (runner, singleton, selectTab) {
// QUERY RUN STATUS ON SERVER
	if ( this.queryStatus.caller )
		console.log("Status.queryStatus    caller: " + this.queryStatus.caller.nom);

	console.log("Status.queryStatus    passed runner: ");
	console.dir({runner:runner});
	console.log("Status.queryStatus    passed singleton: " + singleton);

	// GENERATE QUERY FOR THIS WORKFLOW
	var url 			= 	this.cgiUrl;
	var query 			= 	new Object;
	query.username  	= 	runner.username;
	query.sessionid 	= 	runner.sessionid;
	query.project   	= 	runner.project;
	query.workflow  	= 	runner.workflow;
	query.mode 			= 	"getStatus";
	query.module 		= 	"Agua::Workflow";
	console.log("Status.queryStatus    query: " + dojo.toJson(query));

	var thisObject = this;
	var deferred = dojo.xhrPut(
	{
		url: url,
		putData: dojo.toJson(query),
		handleAs: "json",
		sync: false,
		handle: function(response) {
			if ( thisObject.runCompleted(response) ) {
				console.log("Status.getStatus    response:");
				console.dir({response:response});

				// RUN handleStatus
					console.log("Status.queryStatus     DOING thisObject.handleStatus(runner, response)");
					thisObject.handleStatus(runner, response, selectTab);
				
				console.groupEnd("RunStatus-" + thisObject.id + "    getStatus");
				if ( ! singleton )
					thisObject.delayedQueryStatus(runner, singleton);
				else
					thisObject.stopPolling();
			}
			else if ( ! singleton ) {
				thisObject.delayedQueryStatus(runner, singleton);
			}
			else
				thisObject.stopPolling();
		}
	});

	//// CLEAR DEFERREDS
	//this.clearDeferreds(deferred);	

	this.deferreds.push(deferred);
},
clearDeferreds : function (ignore) {
	console.log("Status.clearDeferreds    ignore: ");
	console.dir({ignore:ignore});
	console.log("Status.clearDeferreds    No. deferreds: " + this.deferreds.length);
	
	dojo.forEach(this.deferreds, function(deferred, index) {
		if ( deferred == ignore )	{
			console.log("Status.clearDeferreds    ignoring deferred: ");
			console.dir({ignore:ignore});
			return;
		}
		console.log("Status.clearDeferreds    Clearing deferred " + index);
		
		deferred.callback = function() {
			console.log("Status.clearDeferreds    deleted callback");
		}
		
		console.log("Status.clearDeferreds    BEFORE deferred.destroy deferred:");
		console.dir({deferred:deferred});
		
		//deferred.destroy();
	});
	
	this.deferreds = [];
	
	// STOP this.sequence IF ALREADY SET
	console.log("Status.clearDeferreds    Doing this.sequence.stop()");
	this.sequence.stop();

},
showMessage : function (message) {
	console.log("Status.showMessage    message: " + message);	
	console.log("Status.showMessage    Doing queryStatus after delay: " + this.delay);	
},
delayedQueryStatus : function (runner, singleton) {
	console.log("_GroupDragPane.delayedQueryStatus    runner:");
	console.dir({runner:runner});
	console.log("_GroupDragPane.delayedQueryStatus    singleton: " + singleton);
	console.log("_GroupDragPane.delayedQueryStatus    this.polling: " + this.polling);
	
	if ( ! this.polling ) {
		console.log("_GroupDragPane.delayedQueryStatus    this.polling is FALSE. Returning");
		return;
	}
	
	var delay = this.delay;

	// CLEAR COUNTDOWN
	this.clearCountdown();
		
	// START COUNTDOWN
	var project = runner.project;
	var workflow = runner.workflow;
	var delayInteger = parseInt(delay/1000);
	this.delayCountdown(delayInteger, project, workflow);
	
	// DO DELAY
	var commands = [
		{ func: [ this.showMessage, this, "RunStatus.delayedQueryStatus"], pauseAfter: delay },
		{ func: [ this.queryStatus, this, runner, singleton ] } 
	];
	console.log("_GroupDragPane.delayedPollCopy    commands: ");
	console.dir({commands:commands});
	
	this.sequence.go(commands, function() {
		console.log('RunStatus.delayedQueryStatus    Doing this.sequence.go(commands)');
	});	
},
runCompleted : function (response) {
	var completed = true;
	for ( var i = 0; i < response.length; i++ ) {
		console.log("Status.runCompleted    response.stagestatus.stages[" + i + "].status: " + response.stagestatus.stages[i].status);
		if ( response.stagestatus.stages[i].status == "completed" )
			completed = false;
	}
	
	return completed;
},
handleStatus : function (runner, response) {
	console.group("RunStatus-" + this.id + "    handleStatus");
	var project		=	this.runner.project;
	var workflow	=	this.runner.workflow;
	var start		=	this.runner.start;
	var childNodes	=	this.runner.childNodes;

	console.log("Status.handleStatus     response: ");
	console.dir({response:response});
	
	console.log("Status.handleStatus      this.polling: " + this.polling);
	if ( ! this.polling )	return false;

	// REPORT NO RESPONSE
	if ( ! response ) {
		this.displayWorkflowStatus("error: no response");
		return;
	}

	// REPORT ERROR
	if ( response.error ) {
		this.displayWorkflowStatus("error");
		return;
	}
	
	// SET MESSAGE
	this.displayWorkflowStatus("processing");

	// SAVE RESPONSE
	this.response = response;

	// SET COMPLETED FLAG
	this.completed = true;
	
	// SET THE NODE CLASSES BASED ON STATUS
	console.log("Status.handleStatus    Setting class of " + response.stagestatus.stages.length  + " stage nodes");
	
	// CHANGE CSS ON RUN NODES
	var status = "completed";
	var startIndex = runner.start - 1;
	if ( startIndex < 0 ) startIndex = 0;
	console.log("Status.handleStatus    startIndex: " + startIndex);
	for ( var i = startIndex; i < response.stagestatus.stages.length; i++ ) {
		var nodeClass = response.stagestatus.stages[i].status;
		console.log("Status.handleStatus   response.stagestatus.stages[" + i + "].status: " + response.stagestatus.stages[i].status);
		//console.log("Status.handleStatus    response nodeClass " + i + ": " + nodeClass);
		//console.log("Status.handleStatus    runner.childNodes[" + i + "]: " + runner.childNodes[i]);

		// SKIP IF NODE NOT DEFINED
		if ( ! runner.childNodes[i] )
			continue;

		this.setNodeClass(runner.childNodes[i], nodeClass);
		
		// UNSET COMPLETED FLAG IF ANY NODE IS NOT COMPLETED
		if ( nodeClass != "completed" && status == "completed" ) {
			console.log("Status.handleStatus    Setting this.completed = false");
			this.completed = false;
			status = nodeClass;
		}
	}
	console.log("Status.handleStatus    this.completed: " + this.completed);
	this.displayWorkflowStatus(status);

	if ( this.completed == true ) {
		this.stopPolling();
	}

	console.log("Status.handleStatus     BEFORE Agua.updateStagesStatus(startIndex, response)");
	Agua.updateStagesStatus(response.stagestatus);
	console.log("Status.handleStatus     AFTER Agua.updateStagesStatus(startIndex, response)");

	console.log("Status.handleStatus     BEFORE this.showStatus(startIndex, response)");
	this.showStatus(response);
	console.log("Status.handleStatus     AFTER this.showStatus(startIndex, response)");

	console.groupEnd("RunStatus-" + this.id + "    handleStatus");
	
	return null;
},
setNodeClass : function(node, nodeClass) {
	console.log("XXXXX RunStatus.setNodeClass    nodeClass: " + nodeClass);
	dojo.removeClass(node, 'stopped');
	dojo.removeClass(node, 'waiting');
	dojo.removeClass(node, 'running');
	dojo.removeClass(node, 'completed');
	dojo.addClass(node, nodeClass);	
},
// POLLING
clearCountdown : function () {
	if ( this.delayCountdownTimeout )
		clearTimeout(this.delayCountdownTimeout);
	this.pollCountdown.innerHTML = "";
},
delayCountdown : function (countdown, project, workflow) {
	console.log("Status.delayCountdown    countdown: " + countdown);
	if ( countdown == 1 ) {
		// DOING POLL
		this.displayWorkflowStatus("loading...");
		this.displayActive();
	}
	
	countdown -= 1;
	console.log("Status.delayCountdown    countdown: " + countdown);

	this.pollCountdown.innerHTML = countdown;
	if ( countdown < 1 )	return;
	
	var magicNumber = 850; // 1 sec. ADJUSTED FOR RUN DELAY
	var thisObject = this;
	this.delayCountdownTimeout = setTimeout( function() {
			thisObject.displayPolling();
			thisObject.delayCountdown(countdown, project, workflow);
		},
		magicNumber,
		this
	);
},
togglePoller : function () {
// START TIME IF STOPPED OR STOP IT IF ITS RUNNING 
	console.log("Status.togglePoller      plugins.workflow.RunStatus.togglePoller()");
	console.log("Status.togglePoller      this.polling: " + this.polling);

	if ( this.polling )
	{
		console.log("Status.togglePoller      Setting this.polling to FALSE and this.completed to FALSE");
		this.polling = false;
		this.completed = false;
		this.stopPolling();
	}
	else {
		console.log("Status.togglePoller      Setting this.polling to TRUE and this.completed to TRUE");
		this.polling = true;
		this.completed = true;
		if ( ! this.runner ) {
			this.runner = this.createRunner(1, null);
		}
		this.startPolling();
	}
},
displayActive : function () {
	console.log("Status.displayActive");
	dojo.removeClass(this.toggle, 'pollingStopped');
	dojo.removeClass(this.toggle, 'pollingStarted');
	dojo.addClass(this.toggle, 'pollingActive');
},
displayPolling : function () {
	//console.log("Status.displayPolling    caller: " + this.displayPolling.caller.nom);
	dojo.removeClass(this.toggle, 'pollingStopped');
	dojo.removeClass(this.toggle, 'pollingActive');
	dojo.addClass(this.toggle, 'pollingStarted');
},
displayNotPolling : function () {
	console.log("Status.displayStarted");
	dojo.removeClass(this.toggle, 'pollingStarted');
	dojo.removeClass(this.toggle, 'pollingActive');
	dojo.addClass(this.toggle, 'pollingStopped');
},
stopPolling : function () {
// STOP POLLING THE SERVER FOR RUN STATUS
	console.log("Status.stopPolling      plugins.workflow.RunStatus.stopPolling()");

	console.log("Status.stopPolling      Setting this.polling to FALSE");
	this.polling = false;

	// CLEAR COUNTDOWN
	this.clearCountdown();
	this.clearDeferreds();
	
	// UPDATE DISPLAY
	this.displayNotPolling();
},
startPolling : function () {
// RESTART POLLING THE SERVER FOR RUN STATUS
	console.log("Status.startPolling      plugins.workflow.RunStatus.startPolling()");
	console.log("Status.startPolling      this.polling: " + this.polling);
	console.log("Status.togglePoller      Setting this.polling to FALSE (ahead of check this.polling in getStatus)");
    this.polling = false;

	if ( ! this.runner ) {
		console.log("Status.startPolling      this.runner is null. Returning");
		this.polling = false;
		return;
	}

	// UPDATE DISPLAY
	this.displayPolling();

	console.log("Status.togglePoller      Doing this.getStatus(null, false)");
	this.getStatus(null, false);
},

// SHOW STATUS
showStatus : function (response, selectTab) {
// POPULATE THE 'STATUS' PANE WITH RUN STATUS INFO
	console.log("Status.showStatus      response: ");
	console.dir({response:response});
    if ( ! response ) return;
	
	// SHOW STAGES STATUS
	console.log("Status.showStatus      Doing this.displayStageStatus(response.stages)");
	this.displayStageStatus(response.stagestatus);

	// SHOW CLUSTER STATUS
	console.log("Status.showStatus      Doing this.displayClusterStatus(response.clusterstatus)");
	this.displayClusterStatus(response.clusterstatus);

	// SHOW QUEUE STATUS
	console.log("Status.showStatus      Doing this.displayQueueStatus(response.queuestatus)");
	this.displayQueueStatus(response.queuestatus);

	// SELECT TAB BASED ON CLUSTER STATUS
    if ( selectTab )
    	this.selectTab(response);

	// GET SELECTED TAB
	var selectedTab = this.getSelectedTab();
	console.log("Status.showStatus    -------------------------- selectedTab : " + selectedTab);
},
selectTab : function (response) {
	// SELECT THIS TAB IF CLUSTER OR BALANCER STILL STARTING
	console.log("Status.selectTab      response: ");
	console.dir({response:response});

	if ( ! response || ! response.clusterstatus ) {
		console.log("Status.selectTab      response or response.clusterstatus is null. SELECTING 'STAGE' TAB");
		this.attachPoint.selectChild(this.stagesTab);
		return;
	}

	var status = response.clusterstatus.status;
	console.log("Status.selectTab      status: " + status);	
	
	if ( status == null ) {
		console.log("Status.selectTab      clusterstatus.status is null. SELECTING 'STAGE' TAB");
		this.attachPoint.selectChild(this.stagesTab);	
	}
	else if ( status.match(/^cluster/)
		|| status.match(/^balancer/) ) {
		console.log("Status.selectTab      SELECTING 'CLUSTER' TAB");
		this.attachPoint.selectChild(this.clusterStatus.mainTab);	
	}
	else if ( status.match(/sge/ ) ) {
		console.log("Status.selectTab      SELECTING 'QUEUE' TAB");
		this.attachPoint.selectChild(this.queueStatus.mainTab);	
	}
	else {
		console.log("Status.selectTab      SELECTING 'STAGE' TAB");
		this.attachPoint.selectChild(this.stagesTab);	
	}
},
getSelectedTab : function () {
	console.log("Status.getSelectedTab    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});

	console.log("Status.getSelectedTab    this.stageTab: " + this.stagesTab);
	
	console.log("Status.getSelectedTab    this.attachPoint.selectedChildWidget: " + this.attachPoint.selectedChildWidget);
	console.dir({selectedChildWidget:this.attachPoint.selectedChildWidget});
	
	if ( this.attachPoint.selectedChildWidget == this.stagesTab )
		return "stageStatus";
	if ( this.attachPoint.selectedChildWidget == this.clusterStatus.mainTab)
		return "clusterStatus";
	if ( this.attachPoint.selectedChildWidget == this.queueStatus.mainTab)
		return "queueStatus";
	
	return null;
},
displayWorkflowStatus: function (status) {
	this.workflowStatus.innerHTML = "";
},
displayStageStatus : function (status) {
	console.log("Status.displayStageStatus      status:");
	console.dir({status:status});
	this.stageStatus.displayStatus(status);
},
displayClusterStatus : function (status) {
	console.log("Status.displayClusterStatus      status:");
	console.dir({status:status});
	this.clusterStatus.displayStatus(status);
},
displayQueueStatus : function (status) {
	console.log("Status.displayQueueStatus      status:");
	console.dir({status:status});
	this.queueStatus.displayStatus(status);
},
clear : function () {
	console.log("Status.clear      plugins.workflow.RunStatus.clear()");

	this.queueStatus.clearStatus();
	this.clusterStatus.clearStatus();
	while ( this.stagesStatusContainer.firstChild ) {
		this.stagesStatusContainer.removeChild(this.stagesStatusContainer.firstChild);
	}	
},
setTime : function (stage) {
	console.log("Status.setTime    stage: "  + dojo.toJson(stage));

	this.displayWorkflowTime(stage.now);
},
displayWorkflowTime : function(time) {
	console.log("Status.displayWorkflowTime    time: " + time);
    // LATER: FINISH
	
},

// WORKFLOW CONTROLS
pauseWorkflow : function () {
	console.log("Status.pauseWorkflow    ");
	var project = this.core.userWorkflows.getProject();
	var workflow = this.core.userWorkflows.getWorkflow();

	this.displayWorkflowStatus("pausing");

	this.checkRunning(project, workflow, "confirmPauseWorkflow");
},
stopWorkflow : function () {
	console.log("Status.stopWorkflow    ");
	var project = this.core.userWorkflows.getProject();
	var workflow = this.core.userWorkflows.getWorkflow();
    console.log("Status.stopWorkflow    project: " + project);
    console.log("Status.stopWorkflow    workflow: " + workflow);

	this.displayWorkflowStatus("stopping");

	this.checkRunning(project, workflow, "confirmStopWorkflow");
},
startWorkflow : function () {
	console.log("Status.startWorkflow    ");
	var project = this.core.userWorkflows.getProject();
	var workflow = this.core.userWorkflows.getWorkflow();

	this.displayWorkflowStatus("starting");

	this.checkRunning(project, workflow, "confirmStartWorkflow");
},
confirmPauseWorkflow : function (project, workflow, isRunning) {
	// EXIT IF NO STAGES ARE CURRENTLY RUNNING
	console.log("Status.confirmPauseWorkflow    project: " + project);
	console.log("Status.confirmPauseWorkflow    workflow: " + workflow);
	console.log("Status.confirmPauseWorkflow    isRunning: " + isRunning);
	if ( ! isRunning )	{
		this.displayWorkflowStatus("cancelled pause");
		return;
	}

	// ASK FOR CONFIRMATION TO STOP THE WORKFLOW
	var noCallback = function (){
		console.log("WorkflowMenu.confirmPauseWorkflow    noCallback()");
	};
	var yesCallback = dojo.hitch(this, function()
		{
			console.log("WorkflowMenu.confirmPauseWorkflow    yesCallback()");
			this.doPauseWorkflow();
		}								
	);

	// GET THE INDEX OF THE FIRST RUNNING STAGE
	var indexOfRunningStage = this.core.userWorkflows.indexOfRunningStage();
	console.log("Status.confirmPauseWorkflow   indexOfRunningStage: " + indexOfRunningStage);
	this.runner = this.core.runStatus.createRunner(indexOfRunningStage);	

	// SET TITLE AND MESSAGE
	var title = project + "." + workflow + " is running";
	var message = "Are you sure you want to stop it?";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);
},
confirmStartWorkflow : function (project, workflow, isRunning) {
	console.log("Status.confirmStartWorkflow    project: " + project);
	console.log("Status.confirmStartWorkflow    workflow: " + workflow);
	console.log("Status.confirmStartWorkflow    isRunning: " + isRunning);

	// EXIT IF STAGES ARE CURRENTLY RUNNING
	if ( isRunning )	{
		this.displayWorkflowStatus("cancelled start");
		return;
	}

	// ASK FOR CONFIRMATION TO STOP THE WORKFLOW
	var noCallback = function (){
		console.log("Status.startWorkflow    noCallback()");
	};
	var yesCallback = dojo.hitch(this, function()
		{
			console.log("Status.startWorkflow    yesCallback()");
			this.doStartWorkflow();
		}								
	);

	// SET TITLE AND MESSAGE
	var title = "Run " + project + "." + workflow + " from start to finish";
	var message = "Please confirm (click Yes to run)";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);

},
confirmStopWorkflow : function (project, workflow, isRunning) {
	console.log("Status.confirmStopWorkflow    project: " + project);
	console.log("Status.confirmStopWorkflow    workflow: " + workflow);
	console.log("Status.confirmStopWorkflow    isRunning: " + isRunning);
	
	// EXIT IF NO STAGES ARE CURRENTLY RUNNING
	if ( ! isRunning )	{
		this.displayWorkflowStatus("cancelled stop");
		return;
	}
	
	// OTHERWISE, ASK FOR CONFIRMATION TO STOP THE WORKFLOW
	var noCallback = function (){
		console.log("Status.stopWorkflow    noCallback()");
	};
	var yesCallback = dojo.hitch(this, function()
		{
			console.log("Status.stopWorkflow    yesCallback()");
			this.doStopWorkflow();
		}								
	);
	
	// SET TITLE AND MESSAGE
	var title = "Stop workflow " + project + "." + workflow + "?";
	var message = "Please confirm (click Yes to run)";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);
},
doPauseWorkflow : function () {
	console.log("Status.doPauseWorkflow    plugins.workflow.RunStatus.pauseWorkflow");
	this.pauseRun();	
},
doStartWorkflow : function () {
	console.log("Status.doStartWorkflow    plugins.workflow.RunStatus.startWorkflow");
	this.runner = this.core.runStatus.createRunner(1);	
	this.runWorkflow(this.runner);		
},
doStopWorkflow : function () {
	console.log("Status.doStopWorkflow    plugins.workflow.RunStatus.doStopWorkflow()");	
	var project		=	this.runner.project;
	var workflow	=	this.runner.workflow;
	var cluster		=	this.runner.cluster;
	var start		=	this.runner.start;

	var username = Agua.cookie('username');
	var sessionid = Agua.cookie('sessionid');

	// SET TIMER CSS 
	dojo.removeClass(this.toggle, 'pollingStopped');
	dojo.addClass(this.toggle, 'pollingStarted');

	// SET MESSAGE
	this.displayWorkflowStatus("stopping");

	// GET URL 
	var url = Agua.cgiUrl + "agua.cgi";
	console.log("Status.doStopWorkflow      url: " + url);		
	
	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query 			= 	new Object;
	query.username 		= 	username;
	query.sessionid 	= 	sessionid;
	query.project 		= 	project;
	query.workflow 		= 	workflow;
	query.cluster 		= 	username + "-" + cluster;
	query.mode 			= 	"stopWorkflow";
	query.module 		= 	"Agua::Workflow";
	query.start 		= 	start;
	console.log("Status.doStopWorkflow     query: " + dojo.toJson(query));
	
	var deferred = dojo.xhrPut(
		{
			url: url,
			putData: dojo.toJson(query),
			handleAs: "json",
			sync: false,
			load: function(response){
				Agua.toast(response);
			}
		}
	);
	
	//// CLEAR DEFERREDS
	//this.clearDeferreds();

	this.deferreds.push(deferred);
},
stopRun : function () {
	// STOP POLLING
	console.log("Status.stopRun    DOING this.stopPolling()");
	this.stopPolling();

	if ( ! this.core.userWorkflows.dropTarget ) {
		console.log("workflow.RunStatus.stopRun    Returning because this.core.userWorkflows.dropTarget is null");
		return;
	}

	console.log("Status.stopRun      this.stageStatus: " + this.stageStatus);
	console.dir({stageStatus: this.stageStatus});

	if ( this.stageStatus == null
		|| this.stageStatus.rows == null
		|| this.stageStatus.rows.length == 0 )	return;

	// SET ROWS IN STAGE TABLE
	for ( var i = 0; i < this.stageStatus.rows; i++ )
	{
		var row  = this.stageStatus.rows[i];
		console.log("Status.stopRun    row.status " + i + ": " + row.status);
		if ( row.status == 'running' )
			row.status = "stopped";
	}

	// SET CSS IN STAGES dropTarget
	var stageNodes = this.core.userWorkflows.dropTarget.getAllNodes();
	for ( var i = 0; i < this.stageNodes; i++ )
	{
		var node = this.stageNodes[i];
		console.log("Status.stopRun    node " + i + ": " + node);
		if ( dojo.hasClass(node, 'running') )
		{
			dojo.removeClass(node, 'running');
			dojo.addClass(node, 'stopped');
		}
	}

	// SEND STOP SIGNAL TO SERVER
	this.stopWorkflow();	
},	
pauseRun : function () {
// STOP AT THE CURRENT STAGE. TO RESTART FROM  STAGE, HIT 'START' BUTTON
	// STOP POLLING
	console.log("Status.pauseRun      DOING this.stopPolling()");
	this.stopPolling();

	// SEND STOP SIGNAL TO SERVER
	this.stopWorkflow();	

	if ( this.response == null )	return;
	
	// SET THE NODE CLASSES BASED ON STATUS
	console.log("Status.pauseRun    Checking " + this.response.length  + " stage nodes");
	for ( var i = 0; i < this.response.length; i++ )
	{
		// SET this.runner.start TO FIRST RUNNING OR WAITING STAGE
		// SO THAT IF 'RUN' BUTTON IS HIT, WORKFLOW WILL RESTART FROM
		// THAT STAGE (I.E., IT WON'T START OVER FROM THE BE)
		if ( this.response[i].status == "completed" )	continue;
		this.runner.start = (startIndex + 1);

		dojo.removeClass(childNodes[i], 'waiting');
		dojo.removeClass(childNodes[i], 'running');
		dojo.removeClass(childNodes[i], 'completed');
		dojo.addClass(childNodes[i], 'waiting');
		break;
	}
},
setConfirmDialog : function () {
	var yesCallback = function (){};
	var noCallback = function (){};
	var title = "Dialog title";
	var message = "Dialog message";
	
	this.confirmDialog = new plugins.dijit.ConfirmDialog(
		{
			title 				:	title,
			message 			:	message,
			parentWidget 		:	this,
			yesCallback 		:	yesCallback,
			noCallback 			:	noCallback
		}			
	);
},
loadConfirmDialog : function (title, message, yesCallback, noCallback) {
	console.log("FileMenu.loadConfirmDialog    yesCallback.toString(): " + yesCallback.toString());
	console.log("FileMenu.loadConfirmDialog    title: " + title);
	console.log("FileMenu.loadConfirmDialog    message: " + message);
	console.log("FileMenu.loadConfirmDialog    yesCallback: " + yesCallback);
	console.log("FileMenu.loadConfirmDialog    noCallback: " + noCallback);

	this.confirmDialog.load(
		{
			title 				:	title,
			message 			:	message,
			yesCallback 		:	yesCallback,
			noCallback 			:	noCallback
		}			
	);
},

// SETTERS
setSequence : function () {
	this.sequence = new dojox.timing.Sequence({});
},
setStageStatus : function () {
	console.log("Status.setStageStatus    DOING new plugins.workflow.RunStatus.StageStatus()");
	this.stageStatus = new plugins.workflow.RunStatus.StageStatus({
		core		: this.core,
		attachPoint	: this.stagesStatusContainer
	});	
},
setClusterStatus : function () {
	console.log("Status.setClusterStatus    DOING new plugins.workflow.RunStatus.ClusterStatus()");
	this.clusterStatus = new plugins.workflow.RunStatus.ClusterStatus({
		core: this.core,
		attachPoint	: this.attachPoint
	});	
},
setQueueStatus : function () {
	console.log("Status.setQueueStatus    DOING new plugins.workflow.RunStatus.QueueStatus()");
	this.queueStatus = new plugins.workflow.RunStatus.QueueStatus({
		core: this.core,
		attachPoint	: this.attachPoint
	});	
}

});	// plugins.workflow.RunStatus

