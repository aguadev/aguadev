dojo.provide("plugins.infusion.Menu.Base");

// WIDGET PARSER
dojo.require("dojo.parser");

// INHERITS
dojo.require("plugins.core.Common");

// HAS A
dojo.require("plugins.menu.Menu");
dojo.require("plugins.dijit.InputDialog");
dojo.require("plugins.dijit.InteractiveDialog");
dojo.require("plugins.dijit.ConfirmDialog");

dojo.declare("plugins.infusion.Menu.Base",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
	
// templatePath : String
// Path to the template of this widget.
//		e.g., require.toUrl("plugins/infusion/templates/Menu/base.html")
templatePath: null,

// widgetsInTemplate : Boolean
// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// cssFiles : Array of Strings
// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/css/Menu/projectmenu.css"),
	require.toUrl("dojox/form/resources/FileInput.css")
],

// core: Hash
// 		Holder for major components, e.g., core.data, core.dataStore
core : null,


// delay: Integer (thousandths of a second)
// Poll delay
delay : 6000,

/////}}
	
constructor : function(args) {
	console.log("Menu.Base.constructor     args: " + args);
	console.dir({args:args});

	// GET INFO FROM ARGS
	this.core = args.core;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	//console.log("Controller.postCreate    plugins.files.Controller.postCreate()");

	// SET INPUT DIALOG
	this.setInputDialog();

	// SET INTERACTIVE DIALOG
	this.setInteractiveDialog();

	// SET CONFIRM DIALOG
	this.setConfirmDialog();

	//// SET LABEL
	//this.setTitle("Project Menu");

	// CONNECT SHORTKEYS FOR MENU
	this.setMenu();

	// DO INHERITED STARTUP
	this.startup();
},
startup : function () {
	console.group("Menu.Base    " + this.id + "    startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// DISABLE MENU ITEMS
	//this.disableMenuItem('select');
	//this.disableMenuItem('add');
	this.menu._started = false;
	this.menu.startup();

	// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.menu.domNode, "oncontextmenu", function (event) {
		event.stopPropagation();
	});

	// SUBSCRIBE TO UPDATES
	if ( Agua && Agua.updater && Agua.updater.subscribe ) {
		Agua.updater.subscribe(this, "updateProjects");
		Agua.updater.subscribe(this, "updateWorkflows");	
	}

	console.groupEnd("Menu.Base    " + this.id + "    startup");
},
updateProjects : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.log("workflow.Stages.updateProjects    workflow.Stages.updateProjects(args)");
	console.log("workflow.Stages.updateProjects    args:");
	console.dir(args);

	this.core.infusion.updateProjects();
},
updateClusters : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.log("admin.Clusters.updateClusters    admin.Clusters.updateClusters(args)");
	console.log("admin.Clusters.updateClusters    args:");
	console.dir(args);
	this.setClusterCombo();
},
setMenu : function () {
// CONNECT SHORTKEYS FOR MENU
	//console.log("Menu.Base.setMenu     plugins.files.Workflow.setMenu()");

	this.disableRightClick();
	
	this.setShortKeys();
	
	this.menu.onCancel = function(event) {
		console.log("Menu.Base.setMenu     DOING this.menu.onCancel(event)");
	}
},
disableRightClick : function () {
	//// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.menu.domNode, "contextmenu", function (event)
	{
		console.log("Menu.Base.setMenu    quenching contextmenu");
		event.preventDefault();
		event.stopPropagation();
		return false;
	});
},
setShortKeys : function () {
	// NOTE: USE accelKey IN DOJO 1.3 ONWARDS
	dojo.connect(this.menu, "onKeyPress", dojo.hitch(this, function(event)
	{
		console.log("Menu.Base.setMenu     this.menu.onKeyPress(event)");
		var key = event.keyCode;
		if ( this.altOn == true )
		{
			switch (key)
			{
				case "h" : this.hold(); break;
				case "c" : this.complete(); break;
				case "l" : this.cancel(); break;
			}
		}
		event.stopPropagation();
	}));

	// SET ALT KEY ON/OFF
	dojo.connect(this.menu, "onKeyDown", dojo.hitch(this, function(event){
		console.log("Menu.Base.setMenu     this.menu.onKeyDown(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = true;
	}));
	dojo.connect(this.menu, "onKeyUp", dojo.hitch(this, function(event){
		console.log("Menu.Base.setMenu     this.menu.onKeyUp(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = false;
	}));	
},
// UTILITIES
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
	console.log("Menu.Base.loadConfirmDialog    plugins.infusion.Menu.Base.loadConfirmDialog()");
	console.log("Menu.Base.loadConfirmDialog    yesCallback.toString(): " + yesCallback.toString());
	console.log("Menu.Base.loadConfirmDialog    title: " + title);
	console.log("Menu.Base.loadConfirmDialog    message: " + message);
	console.log("Menu.Base.loadConfirmDialog    yesCallback: " + yesCallback);
	console.log("Menu.Base.loadConfirmDialog    noCallback: " + noCallback);

	this.confirmDialog.load(
		{
			title 				:	title,
			message 			:	message,
			yesCallback 		:	yesCallback,
			noCallback 			:	noCallback
		}			
	);
},
setInputDialog : function () {
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "";
	var message = "";
	
	this.inputDialog = new plugins.dijit.InputDialog(
		{
			title 				:	title,
			message 			:	message,
			inputMessage		:	"",
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
},
loadInputDialog : function (title, message, enterCallback, cancelCallback) {
	console.log("Menu.Base.loadInputDialog    plugins.infusion.Menu.Base.loadInputDialog()");
	console.log("Menu.Base.loadInputDialog    enterCallback.toString(): " + enterCallback.toString());
	console.log("Menu.Base.loadInputDialog    title: " + title);
	console.log("Menu.Base.loadInputDialog    message: " + message);
	console.log("Menu.Base.loadInputDialog    enterCallback: " + enterCallback);
	console.log("Menu.Base.loadInputDialog    cancelCallback: " + cancelCallback);

	this.inputDialog.load(
		{
			title 				:	title,
			message 			:	message,
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
	
	console.log("Menu.Base.setInteractiveDialog    plugins.infusion.Menu.Base.setInteractiveDialog()");
	this.interactiveDialog = new plugins.dijit.InteractiveDialog(
		{
			title 				:	title,
			message 			:	message,
			inputMessage 		:	"",
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
	console.log("Menu.Base.setInteractiveDialog    this.interactiveDialog: " + this.interactiveDialog);
},
loadInteractiveDialog : function (title, message, enterCallback, cancelCallback, checkboxMessage) {
	console.log("Menu.Base.loadInteractiveDialog    plugins.infusion.Menu.Base.loadInteractiveDialog()");
	console.log("Menu.Base.loadInteractiveDialog    enterCallback.toString(): " + enterCallback.toString());
	console.log("Menu.Base.loadInteractiveDialog    title: " + title);
	console.log("Menu.Base.loadInteractiveDialog    message: " + message);
	console.log("Menu.Base.loadInteractiveDialog    enterCallback: " + enterCallback);
	console.log("Menu.Base.loadInteractiveDialog    cancelCallback: " + cancelCallback);

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
bind : function (node) {
// BIND THE MENU TO A NODE
	console.log("Menu.Base.bind     plugins.infusion.Menu.Base.bind(node)");
	if ( node == null )
		console.log("Menu.Base.bind     node is null. Returning...");

	return this.menu.bindDomNode(node);	
},
getPath : function () {
// RETURN THE FILE PATH OF THE FOCUSED GROUP DRAG PANE
	console.log("Menu.Base.getPath     plugins.infusion.Menu.Base.getPath()");
	console.log("Menu.Base.setUploader     this.menu.currentTarget: " + this.menu.currentTarget);
	var groupDragPane = dijit.getEnclosingWidget(this.menu.currentTarget);
	console.log("Menu.Base.setUploader     groupDragPane: " + groupDragPane);

	if ( groupDragPane == null || ! groupDragPane )	return;
	console.log("Menu.Base.setUploader     Returning path: " + groupDragPane.path);

	return groupDragPane.path;
},
hide : function () {
	console.log("Menu.Base.hide    this.core.infusion: " + this.core.infusion);
	this.core.infusion.hide();
},
//setTitle : function (title) {
//// SET THE MENU TITLE
//	console.log("Menu.Base.setTitle    title: " + title);
//	this.titleNode.containerNode.innerHTML = title;
//},
show : function () {
	console.log("Menu.Base.show    infusion.Menu.Base.show()");
	
	console.log("Menu.Base.show    this.menu.currentTarget: " + this.menu.currentTarget);
	console.dir({currentTarget:this.menu.currentTarget});
	dojo.addClass(this.menu.currentTarget, 'dojoDndItemOver');

	dojo.style(this.containerNode, {
		opacity: 1,
		overflow: "visible"
	});
},
disableMenuItem : function (name) {
	console.log("Menu.Base.disableMenuItem    name: " + name);

	if ( this[name + "Node"] )
		this[name + "Node"].disabled = true;
    var item = this[name + "Node"];
	dojo.addClass(item.domNode, "dijitMenuItemDisabled");
},
enableMenuItem : function (name) {
	console.log("Menu.Base.enableMenuItem    name: " + name);
	if ( this[name + "Node"] )
		this[name + "Node"].disabled = false;
    var item = this[name + "Node"];
	dojo.removeClass(item.domNode, "dijitMenuItemDisabled");
},
disable : function () {
	console.log("Menu.Base.disable    infusion.Menu.Base.disable()");
	this.menu.enabled = false;
},
enable : function () {
	console.log("Menu.Base.enable    infusion.Menu.Base.enable()");
	this.menu.enabled = true;
},
setShortKeys : function () {
	// NOTE: USE accelKey IN DOJO 1.3 ONWARDS
	dojo.connect(this.menu, "onKeyPress", dojo.hitch(this, function(event)
	{
		console.log("Menu.Base.setMenu     this.menu.onKeyPress(event)");
		var key = event.keyCode;
		if ( this.altOn == true )
		{
			switch (key)
			{
				case "s" : this.select(); break;
				case "a" : this.add(); break;
				case "n" : this.newFolder(); break;
				case "m" : this.rename(); break;
				case "l" : this.deleteFile(); break;
				case "o" : this.openWorkflow(); break;
				case "u" : this.upload(); break;
				case "w" : this.download(); break;
				case "r" : this.refresh(); break;
			}
		}
		event.stopPropagation();
	}));

	// SET ALT KEY ON/OFF
	dojo.connect(this.menu, "onKeyDown", dojo.hitch(this, function(event){
		console.log("Menu.Base.setMenu     this.menu.onKeyDown(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = true;
	}));
	dojo.connect(this.menu, "onKeyUp", dojo.hitch(this, function(event){
		console.log("Menu.Base.setMenu     this.menu.onKeyUp(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = false;
	}));	
},
refresh : function (event) {
	console.log("Menu.Base.refresh    DO NOTHING");
},
// UTILITIES
confirmAction : function  (mode, command, callback) {
	console.log("Menu.Base.confirmAction     mode: " + mode);
	console.log("Menu.Base.confirmAction     command: " + command);

	var projectName = this.currentProject;
	console.log("Menu.Base.confirmAction     this.projectName: " + projectName);
	
	if ( this.menu.currentTarget == null )	return;

	var list = dijit.getEnclosingWidget(this.menu.currentTarget);
	console.log("Menu.Base.newFolder     list: " + list);
	console.dir({list:list});
	console.log("Menu.Base.confirmAction    Doing list.standby.show()");
	//list.standby.show();

	// CALLBACKS
	var noCallback = function (){
		console.log("Menu.Base.confirmAction    noCallback()");
		console.log("Menu.Base.confirmAction    Doing dragPane.standby.hide()");
		//dragPane.standby.hide();
	};
	var yesCallback = dojo.hitch(this, function ()
		{
			console.log("Menu.Base.confirmAction    Doing enterCallback");

			var url 			= 	Agua.cgiUrl + "agua.cgi?";
			var putData 		= 	new Object;
			putData.mode		=	mode;
			putData.module		=	"Project";
			putData.sessionid	=	Agua.cookie('sessionid');
			putData.username	=	Agua.cookie('username');
			putData.project		=	projectName;
	
			var thisObject = this;
			dojo.xhrPut(
				{
					url			: 	url,
					putData		:	dojo.toJson(putData),
					handleAs	: 	"json",
					sync		: 	false,
					handle		: 	function(response) {
						if ( response.error ) {
							console.log("Menu.Base.confirmAction    xhrPut response. Doing dragPane.standby.hide()");
							//dragPane.standby.hide();

							Agua.error(response.error);
						}
						else if ( response.status ) {
							callback(projectName);
						}
					}
				}
			);
		}
	);

	// SET TITLE AND MESSAGE
	var title = command + " project " + projectName;
	var message = "Click 'Yes' to confirm";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);	
},	//	confirmAction
getFilesWidget : function () {
// RETURN THE PROJECT TAB WIDGET CONTAINING THIS FILE DRAG OBJECT
	if ( this.menu.currentTarget == null )	return null;

	// GET THE PROJECT WIDGET
	var item = this.menu.currentTarget.item;
	var widget = dijit.getEnclosingWidget(this.menu.currentTarget);
	var filesWidget = widget.core.infusion.core.infusion;
	console.log("Menu.Base.getFilesWidget     filesWidget: " + filesWidget);

	return filesWidget;
},
getProjectName : function () {
// RETURN THE PROJECT NAME FOR THIS FILE DRAG OBJECT
	
	// SANITY		
	if ( this.menu.currentTarget == null )	return null;

	// GET THE PROJECT WIDGET
	var item = this.menu.currentTarget.item;
	//////console.log("Menu.Base.newFolder     this.menu.currentTarget: " + this.menu.currentTarget);
	//////console.log("Menu.Base.newFolder     item: " + item);
	var widget = dijit.getEnclosingWidget(this.menu.currentTarget);
	var projectName = widget.path;

	return projectName;
},
getStandby : function () {
	console.log("Menu.Base.getStandby    WorkflowMenu.getStandby()");
	
	if ( this.standby )	return this.standby;

	var id = dijit.getUniqueId("dojox_widget_Standby");
	this.standby = new dojox.widget.Standby (
		{
			//onClick	: 	"reload",
			text	: 	"",
			id 		: 	id,
			url		: 	"plugins/core/images/agua-biwave-24.png"
		}
	);
	document.body.appendChild(this.standby.domNode);
	console.log("Menu.Base.getStandby    this.standby: " + this.standby);

	return this.standby;
},
getUserName : function () {
	// GET USERNAME
	var fileDrag = this.getFileDrag();
	return fileDrag.owner;
},
selectTarget : function (args) {
	var dragPane = this.getDragPane();
	dragPane._dragSource._addItemClass(this.menu.currentTarget, "Selected");
},
deselectTarget : function (args) {
	var dragPane = this.getDragPane();
	dragPane._dragSource._removeItemClass(this.menu.currentTarget, "Selected");
}

}); // plugins.infusion.Menu.Base
