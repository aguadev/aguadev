dojo.provide("plugins.dojox.Timing");

/* 

	1. REPEATEDLY POLL WHILE WAITING FOR EVENTS TO FINISH
	
	2. CARRY OUT A SPECIFIED ACTION ON COMPLETION
	
*/

// TIMER
dojo.require("dojox.timing");

// INHERITS
//dojo.require("plugins.core.Common");


dojo.declare( "plugins.dojox.Timing",
	//[ plugins.core.Common ],
	null,
{

////}

// PARENT WIDGET
parentWidget : null,

// INTERVAL IN 1000ths OF A SECOND
timingInterval : 5000,

constructor : function(args) {
	console.log("IO.constructor     plugins.dojox.Timing.constructor");			
	this.pollProgress 	= args.pollProgress;
	this.onEnd 			= args.onEnd;

	// INSTANTIATE NEW TIMER
	this.setTimer();
},

postCreate : function() {
	console.log("IO.postCreate    plugins.workflow.Controller.postCreate()");
	this.startup();
},

startup : function () {
	console.log("IO.startup    plugins.dojox.Timing.startup()");

},

setTimer : function () {
	console.log("RunStatus.setTimer    this.timerInterval: " + this.timerInterval);
	
	if ( this.timer != null ) {
		return;
	}
	
	this.timer = new dojox.timing.Timer;
	this.timer.setInterval(this.timerInterval);	// 1000ths OF A SECOND	
	var thisObject = this;	
	this.timer.onTick = function()
	{
		console.log("RunStatus.setTimer    onTick()");
		console.log("RunStatus.setTimer    time: " + new Date().toTimeString());

		// STOP POLLING WHEN THE LAST RUNNING ITEM HAS
		// COMPLETED (I.E., WHEN 'this.completed' == true)
		console.log("RunStatus.setTimer     thisObject.completed: " + dojo.toJson(thisObject.completed));
		if ( thisObject.completed == true )
		{
			console.log("RunStatus.setTimer     Stopping timer because thisObject.completed: " + thisObject.completed);
			thisObject.stopTimer();
			return;
		}

        setTimeout(function() {
            try {
                console.log("RunStatus.setTimer     Doing setTimeout(this.queryStatus(this.runner))");
                thisObject.queryStatus(thisObject.runner);
            } catch(error) {
                console.log("RunStatus.setTimer     Error doing setTimeout(this.queryStatus(this.runner)): " + dojo.toJson(error));
            }
        }, 100);

	};	//	timer.onTick
},

getStatus : function (runner, singleton) {
// KEEP POLLING SERVER FOR RUN STATUS UNTIL COMPLETE
	console.log("RunStatus.getStatus      plugins.workflow.Controller.getStatus(runner, singleton)");
	console.log("RunStatus.getStatus      runner: " + runner);
	console.log("RunStatus.getStatus      singleton: " + singleton);
	
	console.log("RunStatus.getStatus     this.polling: " + this.polling);
	if ( this.polling == true )
	{
		console.log("RunStatus.getStatus     Returning because this.polling is TRUE");
		return;
	}
	this.polling = true;
	
	if ( runner != null )	this.runner = runner;
	else
	{
		var stageNumber = 1;
		this.runner	= this.createRunner(stageNumber);
	}

    dojo.removeClass(this.toggle, 'timerStopped');
    dojo.addClass(this.toggle, 'timerStarted');
	
	// SET MESSAGE
	this.displayWorkflowStatus("loading");

	var project		=	this.runner.project;
	var workflow	=	this.runner.workflow;
	var start		=	this.runner.start;
	var childNodes	=	this.runner.childNodes;
	console.log("RunStatus.getStatus      project: " + project);
	console.log("RunStatus.getStatus      workflow: " + workflow);
	console.log("RunStatus.getStatus      start: " + start);
	console.log("RunStatus.getStatus      childNodes.length: " + childNodes.length);

	// SANITY CHECKS
	if ( project == null ) { return; }
	if ( workflow == null ) { return; }
	if ( start == null ) { return; }
	if ( childNodes == null || ! childNodes || childNodes.length == 0 )
	{
		console.log("RunStatus.getStatus      No childNodes in dropTarget. Returning...");
		return;
	}

    // FIRST QUERY
    this.queryStatus(this.runner);
	if ( singleton != null ) {
		console.log("RunStatus.getStatus     Quitting getStatus early because singleton");
		this.stopTimer();
		return;
	}

	// START TIMER
	console.log("RunStatus.getStatus     Doing this.timer.start()");
	this.completed = false;
	this.timer.start();
},
    
queryStatus : function (runner) {
// QUERY RUN STATUS ON SERVER

	// GENERATE QUERY FOR THIS WORKFLOW
	var url = this.cgiUrl;
	var query 			= 	new Object;
	query.username  	= 	runner.username;
	query.sessionid 	= 	runner.sessionid;
	query.project   	= 	runner.project;
	query.workflow  	= 	runner.workflow;
	query.mode 			= 	"getStatus";
	query.module 		= 	"Agua::Workflow";
	console.log("RunStatus.queryStatus    query: " + dojo.toJson(query));

	var thisObject = this;
	dojo.xhrPut(
	{
		url: url,
		putData: dojo.toJson(query),
		handleAs: "json",
		timeout : 50000,
		sync: false,
		load: function(response) {
			thisObject.handleStatus(runner, response)
		}
	});
},

handleStatus : function (runner, response) {

	var project		=	this.runner.project;
	var workflow	=	this.runner.workflow;
	var start		=	this.runner.start;
	var childNodes	=	this.runner.childNodes;
	console.log("RunStatus.handleStatus      project: " + project);
	console.log("RunStatus.handleStatus      workflow: " + workflow);
	console.log("RunStatus.handleStatus      start: " + start);
	console.log("RunStatus.handleStatus      childNodes.length: " + childNodes.length);
	
	console.log("RunStatus.handleStatus     response: " + dojo.toJson(response));

	if ( response == null )	return;
	if ( response.stages == null )	return false;

	// SET MESSAGE
	this.displayWorkflowStatus("processing");

	// SAVE RESPONSE
	this.response = response;

	// SET COMPLETED FLAG
	this.completed = true;
	
	// SET THE NODE CLASSES BASED ON STATUS
	console.log("RunStatus.handleStatus    Setting class of " + response.stages.length  + " stage nodes");
	
	// CHANGE CSS ON RUN NODES
	var startIndex = runner.start - 1;
	if ( startIndex < 0 ) startIndex = 0;
	console.log("RunStatus.handleStatus    startIndex: " + startIndex);
	for ( var i = startIndex; i < response.stages.length; i++ )
	{
		var nodeClass = response.stages[i].status;
		console.log("RunStatus.handleStatus    response nodeClass " + i + ": " + nodeClass);
		dojo.removeClass(runner.childNodes[i], 'stopped');
		dojo.removeClass(runner.childNodes[i], 'waiting');
		dojo.removeClass(runner.childNodes[i], 'running');
		dojo.removeClass(runner.childNodes[i], 'completed');
		dojo.addClass(runner.childNodes[i], nodeClass);
		
		// UNSET COMPLETED FLAG IF ANY NODE IS NOT COMPLETED
		if ( nodeClass != "completed" )
		{
			console.log("RunStatus.handleStatus    Setting this.completed = false");
			this.completed = false;
		}
	}

	if ( this.completed == true )
	{
		this.stopTimer();
	}
	console.log("RunStatus.handleStatus    this.completed: " + this.completed);

	console.log("RunStatus.handleStatus     BEFORE Agua.updateStagesStatus(startIndex, response)");
	Agua.updateStagesStatus(response.stages);
	console.log("RunStatus.handleStatus     AFTER Agua.updateStagesStatus(startIndex, response)");

	console.log("RunStatus.handleStatus     BEFORE this.showStatus(startIndex, response)");
	this.showStatus(response);
	console.log("RunStatus.handleStatus     AFTER this.showStatus(startIndex, response)");
}


});


