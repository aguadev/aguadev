dojo.provide("plugins.workflow.RunStatus.QueueStatus");

// TITLE PANE
dojo.require("dijit.TitlePane");

// HAS A
dojo.require("plugins.dijit.ConfirmDialog");

// INHERITS
dojo.require("plugins.core.Common");

dojo.declare( "plugins.workflow.RunStatus.QueueStatus",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/RunStatus/templates/queuestatus.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins") + "/workflow/RunStatus/css/queuestatus.css" ],

// CORE WORKFLOW OBJECTS
core : null,

// status: string
// Queue status ('', 'starting', 'running', 'pausing', 'paused', 'stopping', 'stopped')
status : '',

// runner: object
// RUNNER OBJECT SET IN RunStatus
runner : null,

/////}
constructor : function(args) {
	console.log("QueueStatus.constructor    args:");
	console.dir({args:args});

	// GET ARGS
	this.core = args.core;
	this.attachNode = args.attachNode;

	if ( args.cgiUrl != null )
		this.cgiUrl = args.cgiUrl;
	else
		this.cgiUrl = 	Agua.cgiUrl + "agua.cgi";
	
	// LOAD CSS
	this.loadCSS();		
},
postCreate: function() {
	console.log("QueueStatus.postCreate    plugins.workflow.RunStatus.QueueStatus.postCreate()");

	this.startup();
},
startup : function () {
	console.log("QueueStatus.startup    plugins.workflow.RunStatus.QueueStatus.startup()");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	console.log("QueueStatus.startup    this.attachNode: " + this.attachNode);
	//console.log("QueueStatus.startup    this.stagesTab: " + this.stagesTab);
	//console.log("QueueStatus.startup    this.queueTab: " + this.queueTab);
	
	// ADD TO TAB CONTAINER		
	if ( this.attachNode.addChild != null )
		this.attachNode.addChild(this.mainTab);

    // OTHERWISE, WE ARE TESTING SO APPEND TO DOC BODY
	else {
		var div = dojo.create('div');
		document.body.appendChild(div);
		div.appendChild(this.mainTab.domNode);
	}
	this.attachNode.selectChild(this.mainTab);	
},
displayStatus : function (queuestatus) {
	console.log("QueueStatus.displayStatus      queuestatus:");
	console.dir({queuestatus:queuestatus});
	
	// REMOVE EXISTING STATUS 	
	this.clearStatus();

	// LEAVE EMPTY AND RETURN IF NO STATUS
	if ( ! queuestatus || ! queuestatus.status ) {
		this.statusList.innerHTML = "No queue information available";
		return;
	}
	
	// DISPLAY STATUS
	this.statusList.innerHTML = "<PRE>" + queuestatus.status + "</PRE>";
},
clearStatus : function () {
	console.log("QueueStatus.clearStatus      clearing this.statusList");
	this.statusList.innerHTML = "";
	
	while ( this.statusList.firstChild )
		this.statusList.removeChild(this.statusList.firstChild);

}

});	// plugins.workflow.RunStatus.QueueStatus

