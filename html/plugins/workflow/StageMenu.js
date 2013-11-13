dojo.provide("plugins.workflow.StageMenu");

// PROVIDE A POPUP CONTEXT MENU AND IMPLEMENT ITS 
// ONCLICK FUNCTIONS

//Open a context menu	On Windows: shift-f10 or the Windows context menu key On Firefox on the Macintosh: ctrl-space. On Safari 4 on Mac: VO+shift+m (VO is usually control+opton)
//Navigate menu items	Up and down arrow keys
//Activate a menu item	Spacebar or enter
//Open a submenu	Spacebar, enter, or right arrow
//Close a context menu or submenu	Esc or left arrow
//Close a context menu and all open submenus	Tab

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dojo.parser");

// HAS A
dojo.require("plugins.menu.Menu");

// INHERITS
dojo.require("plugins.core.Common");


dojo.declare("plugins.workflow.StageMenu",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/stagemenu.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingApp STATE2
addingApp : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins") + "/workflow/css/stagemenu.css" ],

// PARENT WIDGET
parentWidget : null,

// CORE WORKFLOW OBJECTS
core : null,

////////}

constructor : function(args) {
	console.log("StageMenu.constructor     plugins.workflow.StageMenu.constructor");			
	this.core = args.core;
	console.log("StageMenu.constructor     this.core: " + this.core);
	
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	this.startup();
},
startup : function () {
	////console.log("StageMenu.startup    plugins.workflow.StageMenu.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// SET DRAG APP - LIST OF APPS
	this.setMenu();
},
setMenu : function () {
// CONNECT LISTENERS FOR MENU
	////console.log("StageMenu.setMenu     plugins.workflow.StageMenu.setMenu()");
	
	//dojo.connect(this.removeNode, "onClick", dojo.hitch(this, function(event)
	//{
	//	////console.log("StageMenu.setMenu     onClick remove");
	//	this.remove(event);
	//	event.stopPropagation();
	//}));
	//
	//dojo.connect(this.runNode, "onClick", dojo.hitch(this, function(event)
	//{
	//	////console.log("StageMenu.setMenu     onClick run");
	//	this.run(event);
	//}));
},
bind : function (node) {
// BIND THE MENU TO A NODE
	////console.log("StageMenu.bind     plugins.workflow.StageMenu.bind(node)");
	////console.log("StageMenu.bind     node: " + node);

	if ( node == null )
	{
		////console.log("StageMenu.bind     node is null. Returning...");
	}
	return this.menu.bindDomNode(node);	
},
remove : function (event) {
// REMOVE THE STAGE FROM THE WORKFLOW
	console.log("StageMenu.remove     plugins.workflow.StageMenu.remove(event)");

	// REM: WE ARE NOT INTERESTED IN event.target 
	// BECAUSE ITS THE CLICKED MENU NODE. WE WANT
	// THE NODE UNDERNEATH
	var node = this.menu.currentTarget;
	console.log("StageMenu.remove     node: ");
	console.dir({node:node});
	var application = node.parentWidget.application;
	console.log("StageMenu.remove     application: " + dojo.toJson(application));
	
	//if ( widget == null )	return;

	// PHYSICALLY REMOVE THE CLICKED NODE
	//var itemNode = widget.domNode.parentNode;
	//this.parentWidget.dropTarget.delItem(itemNode.id);
	//dojo.destroy(itemNode);

	this.parentWidget.dropTarget.delItem(node.id);
	dojo.destroy(node);

	// SET username
	var username = Agua.cookie(username);

	// REMOVE THE CLICKED STAGE FROM THE WORKFLOW
	var stageObject = {
		username: username,
		project: this.parentWidget.projectCombo.getValue(),
		workflow: this.parentWidget.workflowCombo.getValue(),
		name: application.name,
		owner: application.owner,
		number: application.number,
		type: application.type
	};
	////console.log("StageMenu.remove     stageObject: " + dojo.toJson(stageObject));

	// REMOVE STAGE IN AGUA ON CLIENT AND ON REMOTE SERVER
	setTimeout(function(thisObj) {
			console.log("StageMenu.remove     Doing Agua.spliceStage(stageObject); }, 100, this)");
			Agua.spliceStage(stageObject);
		},
		100,
		this
	);
	

	// UPDATE ANY NODES COMING AFTER THE INSERTION POINT OF THE NEW NODE
	// NB: THE SERVER SIDE UPDATES ARE DONE AUTOMATICALLY
	////console.log("StageMenu.remove     this.parentWidget: " + this.parentWidget);
	////console.log("StageMenu.remove     this.parentWidget.dropTarget: " + this.parentWidget.dropTarget);
	var childNodes = this.parentWidget.dropTarget.getAllNodes();
	for ( var i = application.number; i < childNodes.length; i++ )
	{
		childNodes[i].application.number = (i + 1).toString();
	}

	// RESETTING number IN ALL CHILDNODES
	////console.log("StageMenu.remove     Resetting number in all childNodes. childNodes.length: " + childNodes.length);
	for ( var i = 0; i < childNodes.length; i++ )
	{
		var node = childNodes[i];
		////console.log("StageMenu.remove     //console.dir(childNodes[" + i + "]):" + node);
		////console.dir(node);

		// GET WIDGET
		////console.log("StageMenu.remove     Getting widget.");
		var widget = dijit.byNode(node.firstChild);
		//var widget = node.parentWidget;
		////console.log("StageMenu.remove     childNodes[" + i + "].widget: " + widget);			
		if ( widget == null )
		{
			widget = dijit.getEnclosingWidget(childNodes[i]);
		}
		////console.log("StageMenu.remove     Resetting stageRow number to: " + (i + 1));
		node.application.number = (i + 1).toString();
		node.application.appnumber = (i + 1).toString();

		widget.setNumber(node.application.number);

		console.log("StageMenu.remove     Reset widget childNodes[" + i + "].application.name " + node.application.name + ", node.application.number: " + node.application.number);
	}

	console.log("StageMenu.remove    this.parentWidget: " + this.parentWidget);
	
	// DO INFOPANE
	if ( childNodes.length ) {
		this.parentWidget.loadParametersPane(childNodes[0]);
	}
	else {
		this.parentWidget.clearParameters();
	}
	
	// CALL Stages TO CHECK VALID STAGES		
	this.parentWidget.updateRunButton();
	
	// UPDATE RUN STATUS
	console.log("StageMenu.remove    Doing this.core.userWorkflows.checkRunStatus()");
	this.core.runStatus.polling = false;
	this.core.userWorkflows.checkRunStatus();
	
},	//	remove
run : function () {
// RUN STAGE
	console.log("StageMenu.run     plugins.workflow.StageMenu.run()");
	var node = this.menu.currentTarget;
	var application = this.getApplication(node);

	// START RUN
	var runner = this.core.runStatus.createRunner(application.number, application.number);
	this.core.runStatus.runWorkflow(runner);
},
stop : function () {
// STOP STAGE
	console.log("StageMenu.stop     plugins.workflow.StageMenu.stop()");
	var node = this.menu.currentTarget;
	var application = node.parentWidget.application;
	console.log("StageMenu.stop     application: " + dojo.toJson(application));

	// START RUN
	var runner = this.core.runStatus.createRunner(application.number, application.number);
	this.core.runStatus.confirmStopWorkflow(application.project, application.workflow, true);
},
runAll : function () {
// ADD PROGRAMMATIC CONTEXT MENU
	console.log("StageMenu.runAll     plugins.workflow.StageMenu.runAll()");
	var node = this.menu.currentTarget;
	var application = this.getApplication(node);
	////console.log("StageMenu.runAll     application: " + dojo.toJson(application));

	// START run
	var runner = this.core.runStatus.createRunner(application.number);
	this.core.runStatus.runWorkflow(runner);
},
chain : function () {
// CHAIN THE INPUTS AND OUTPUTS OF THIS STAGE TO THE PARAMETER VALUES
// OF THE PRECEDING STAGE
	////console.log("StageMenu.chain     plugins.workflow.StageMenu.chain()");

	// REM: WE ARE NOT INTERESTED IN event.target 
	// BECAUSE ITS THE CLICKED MENU NODE. WE WANT
	// THE NODE UNDERNEATH
	var node = this.menu.currentTarget;
	console.log("StageMenu.chain    node: ");
	console.dir({node:node});
	var application = this.getApplication(node);
	////console.log("StageMenu.chain     application: " + dojo.toJson(application));

	// PREPARE STAGE OBJECT
	var stageObject = {
		project: this.parentWidget.projectCombo.getValue(),
		workflow: this.parentWidget.workflowCombo.getValue(),
		owner: application.owner,
		appname: application.name,
		appnumber: application.number,
		name: application.name,
		number: application.number
	};
	////console.log("StageMenu.chain     stageObject: " + dojo.toJson(stageObject));

	// CHANGE THE STAGE PARAMETERS FOR THIS APPLICATION
	// IF THE args FIELD IS NOT NULL (ALSO params AND paramFunction)
	console.log("StageMenu.chain     DOING this.parentWidget.core.io.chainstage()");
	console.log("StageMenu.chain     this.parentWidget.core.io: " + this.parentWidget.core.io);
	var force = true;
	this.core.io.chainStage(stageObject, force);
	
	// SET INFO PANE FOR DROPPED NODE
	this.core.userWorkflows.loadParametersPane(node);
},
refresh : function () {
// REFRESH VALIDATION OF STAGE PARAMETERS
	console.log("StageMenu.refresh     plugins.workflow.StageMenu.refresh()");
	var node = this.menu.currentTarget;
	var application = this.getApplication(node);

	var username = Agua.cookie('username');
	var shared = false;
	if ( application.username != username )
		shared = true;
	var force = true;
	this.core.parameters.load(node, shared, force);
},
// UTILS
getApplication : function (node) {
	return node.parentWidget.application;
}

}); // plugins.workflow.StageMenu

