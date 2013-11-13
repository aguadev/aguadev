dojo.provide("plugins.files.WorkflowMenu");

// WIDGET PARSER
dojo.require("dojo.parser");

// INHERITS
dojo.require("plugins.files.FileMenu");

// HAS A
dojo.require("dijit.Menu");
dojo.require("plugins.dijit.SelectiveDialog");

dojo.declare("plugins.files.WorkflowMenu",
	[ plugins.files.FileMenu ], {
	/////}}	
	
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "files/templates/workflowmenu.html"),

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "files/css/workflowmenu.css")
],

constructor : function() {
	// LOAD CSS
	this.loadCSS();		

},
postCreate : function() {
	// SET INPUT DIALOG
	this.setInputDialog();

	// SET INTERACTIVE DIALOG
	this.setInteractiveDialog();

	// SET CONFIRM DIALOG
	this.setConfirmDialog();

	// SET LABEL
	this.setTitle("Workflow Menu");

	// CONNECT SHORTKEYS FOR MENU
	this.setMenu();
	
	// DO STARTUP
	this.startup();
},
startup : function () {
	//////console.log("FileMenu.startup    plugins.files.FileMenu.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// CONNECT SHORTKEYS FOR MENU
	this.setMenu();	

	// DISABLE MENU ITEMS
	this.disableMenuItem('select');
	this.disableMenuItem('add');

	// CONNECT HIGHLIGHT TARGET WITH hide/dhow
	dojo.connect(this.menu, "_openMyself", this, "selectTarget");
	dojo.connect(this.menu, "_markInactive", this, "deselectTarget");

	// SET SELECTIVE DIALOG FOR copyWorkflow	
	this.setSelectiveDialog();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateProjects");
},
updateProjects : function (args) {
	//console.warn("WorkflowMenu.updateProjects    args:");
	//console.dir(args);

},
setTitle : function (title) {
// NO TITLE - DO NOTHING
},
setShortKeys : function () {
	// NOTE: USE accelKey IN DOJO 1.3 ONWARDS
	dojo.connect(this.menu, "onKeyPress", dojo.hitch(this, function(event)
	{
		////console.log("FileMenu.setMenu     this.menu.onKeyPress(event)");
		var key = event.keyCode;
		if ( this.altOn == true )
		{
			switch (key)
			{
				case "s" : this.select(); break;
				case "a" : this.add(); break;
				case "p" : this.newProject(); break;
				case "w" : this.newWorkflow(); break;
				case "r" : this.renameWorkflow(); break;
				case "d" : this.deleteProject(); break;
				case "l" : this.deleteWorkflow(); break;
				case "o" : this.openWorkflow(); break;
				case "c" : this.copyWorkflow(); break;
			}
		}
		event.stopPropagation();
	}));

	// SET ALT KEY ON/OFF
	dojo.connect(this.menu, "onKeyDown", dojo.hitch(this, function(event){
		////console.log("FileMenu.setMenu     this.menu.onKeyDown(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = true;
	}));
	dojo.connect(this.menu, "onKeyUp", dojo.hitch(this, function(event){
		////console.log("FileMenu.setMenu     this.menu.onKeyUp(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = false;
	}));	
},
// MAIN METHODS
newProject : function () {
// ADD A NEW PROJECT USING A DIALOG BOX FOR PROJECT NAME INPUT
	// GET INPUTS
	var username = this.getUserName();
	var interactiveDialog = this.interactiveDialog;
	var filesWidget = this.getFilesWidget();
	//console.log("WorkflowMenu.newProject     filesWidget: " + filesWidget);
	//console.dir({filesWidget:filesWidget});
	
	// CALLBACKS
	var cancelCallback = function () {};
	var enterCallback = dojo.hitch(this, function (projectName)
		{
			// SANITY CHECK
			if ( projectName == null )	return;
			if ( projectName == '' )	return;
			projectName = projectName.replace(/\s+/g, '');
			//console.log("WorkflowMenu.newProject    projectName: " + projectName);
		
			// NEW PROJECT OBJECT
			var projectObject = new Object;
			projectObject.name = projectName;
			if ( Agua.isProject(projectName) == true )
			{
				//console.log("WorkflowMenu.newProject    project " + projectName + " already exists. Returning");
				interactiveDialog.messageNode.innerHTML = "Project already exists";
				return;
			}
			
			// ADD PROJECT FILEDRAG
			var directory = {
				username	:	username,
				owner		:	username,
				name		:	projectName,
				title		:	projectName
			};
			//console.log("WorkflowMenu.newProject    Doing filesWidget.addChild()");
			filesWidget.addChild(directory);
			
			// ADD PROJECT
			Agua.addProject(projectObject);
		}
	);		

	var title = "New Project";
	var message = "Please enter project name";
	//console.log("WorkflowMenu.newProject    plugins.files.WorkflowMenu.newProject()");
	this.loadInputDialog(title, message, enterCallback, cancelCallback);
},
newWorkflow : function () {
// ADD A NEW WORKFLOW USING A DIALOG BOX FOR WORKFLOW NAME INPUT

	// GET INPUTS
	var projectName = this.getProjectName();
	var interactiveDialog = this.interactiveDialog;
	var username = this.getUserName();
	var dragPane = this.getDragPane();
	
	// SET TITLE AND MESSAGE
	var title = "New Workflow";
	var message = "Please enter workflow name";
	
	// CALLBACKS
	var cancelCallback = function () {};

	// CALLBACK CALL FORMAT:
	// this.dialog.enterCallback(input, checked);	
	var enterCallback = dojo.hitch(this, function (workflowName, undefined ) {
		// SANITY CHECK
		workflowName = workflowName.replace(/\s+/, '');
		if ( ! workflowName )	return;
		// QUIT IF WORKFLOW EXISTS ALREADY
		if ( Agua.isWorkflow({ project: projectName, name: workflowName }) == true )
		{
			//console.log("WorkflowMenu.newWorkflow    Workflow '" + workflowName + "' already exists in project " + projectName + ". Sending message to dialog.");
			interactiveDialog.messageNode.innerHTML = "Workflow already exists";
			return;
		}
		else {
			interactiveDialog.messageNode.innerHTML = "Creating workflow";
			interactiveDialog.close();
		}
		
		// ADD WORKFLOW
		var location = dragPane.path + "/" + workflowName;
		//console.log("WorkflowMenu.newWorkflow    location: " + location);
		Agua.addWorkflow({ project: projectName, name: workflowName });

		// ADD ITEM TO DRAGPANE
		dragPane.addItem(workflowName, "workflow", username, location);
	});

	// SHOW THE DIALOG
	this.loadInteractiveDialog(title, message, enterCallback, cancelCallback);
},
copyWorkflow : function () {
// DISPLAY A 'Copy Workflow' DIALOG THAT ALLOWS THE USER TO SELECT 
// THE DESTINATION PROJECT AND THE NAME OF THE NEW WORKFLOW

	////console.log("WorkflowMenu.copyWorkflow    plugins.files.WorkflowMenu.copyWorkflow()");
	////console.log("WorkflowMenu.copyWorkflow    this.selectiveDialog: " + this.selectiveDialog);

	var item = this.menu.currentTarget.item;
	//////console.log("WorkflowMenu.copyWorkflow     item: " + dojo.toJson(item));
	var sourceProject = item.parentPath;	
	var sourceWorkflow = item.path;	
	////console.log("WorkflowMenu.copyWorkflow     sourceProject: " + sourceProject);
	////console.log("WorkflowMenu.copyWorkflow     sourceWorkflow: " + sourceWorkflow);

	// SET CALLBACKS
	var cancelCallback = function (){
		////console.log("WorkflowMenu.copyWorkflow    cancelCallback()");
	};
	var thisObject = this;
	
	var enterCallback = dojo.hitch(this, function (targetProject, targetWorkflow, copyFiles, dialogWidget)
		{
			////console.log("WorkflowMenu.copyWorkflow    Doing enterCallback(targetWorkflow, targetProject, copyfiles, dialogWidget)");
			////console.log("WorkflowMenu.copyWorkflow    targetWorkflow: " + targetWorkflow);
			////console.log("WorkflowMenu.copyWorkflow    targetProject: " + targetProject);
			////console.log("WorkflowMenu.copyWorkflow    copyFiles: " + copyFiles);
			////console.log("WorkflowMenu.copyWorkflow    dialogWidget: " + dialogWidget);
			
			// SET BUTTON LABELS
			var enterLabel = "Copy";
			var cancelLabel = "Cancel";
			
			// SANITY CHECK
			if ( targetWorkflow == null || targetWorkflow == '' )	return;
			targetWorkflow = targetWorkflow.replace(/\s+/, '');
			////console.log("WorkflowMenu.copyWorkflow    targetWorkflow: " + targetWorkflow);

			// QUIT IF WORKFLOW IS EMPTY
			if ( targetWorkflow == null || targetWorkflow == '' )
			{
				dialogWidget.messageNode.innerHTML = "Please input name of new Workflow";
				return;
			}

			// QUIT IF WORKFLOW EXISTS ALREADY
			if ( Agua.isWorkflow({ project: targetProject, name: targetWorkflow }) == true )
			{
				////console.log("WorkflowMenu.copyWorkflow    Workflow '" + targetWorkflow + "' already exists in project " + targetProject + ". Sending message to dialog.");
				
				dialogWidget.messageNode.innerHTML = "/" + targetWorkflow + "' already exists in '" + targetProject + "'";
				return;
			}
			else {
				////console.log("WorkflowMenu.copyWorkflow    Workflow '" + targetWorkflow + "' is unique in project " + targetProject + ". Adding workflow.");

				dialogWidget.messageNode.innerHTML = "Creating workflow";
				dialogWidget.close();
			}
			
			thisObject._copyWorkflow(sourceProject, sourceWorkflow, targetWorkflow, targetProject, copyFiles);
		}
	);		

	// SHOW THE DIALOG
	this.selectiveDialog.load(
		{
			title 				:	"Copy Workflow",
			message 			:	"Source: '" + sourceProject + ":" + sourceWorkflow + "'",
			comboValues 		:	Agua.getProjectNames(),
			inputMessage 		:	"Workflow name",
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
	////console.log("WorkflowMenu._copyWorkflow    WorkflowMenu._copyWorkflow(sourceProject, sourceWorkflow, targetProject, targetWorkflow, copyFiles)");
	
	var username = Agua.cookie('username');
	// ADD PROJECT
	Agua.copyWorkflow(username, sourceProject, sourceWorkflow, username, targetProject, targetWorkflow, copyFiles);
},
renameWorkflow : function () {
	// GET PROJECT WIDGET		
	var filesWidget = this.getFilesWidget();
	if ( filesWidget == null )	return;
	//console.log("WorkflowMenu.renameWorkflow     filesWidget: " + filesWidget);

	// GET DRAGPANE
	var dragPane = this.getDragPane();
	//console.log("WorkflowMenu.renameWorkflow     dragPane: ");
	//console.dir({dragPane:dragPane});
	
	// GET USERNAME
	var username = this.getUserName();
	
	// GET DND ITEM		
	var dndItem = this.menu.currentTarget;
	//console.log("WorkflowMenu.deleteWorkflow    dndItem: ");
	//console.dir({dndItem:dndItem});

	// SET WORKFLOW OBJECT
	var projectName = this.getProjectName();
	var oldWorkflowName = this.getWorkflowName();
	var workflowNumber = this.getWorkflowNumber();
	var workflowObject 		= new Object;
	workflowObject.project 	= projectName;
	workflowObject.name 	= oldWorkflowName;
	workflowObject.number	= workflowNumber;
	//console.log("WorkflowMenu.deleteWorkflow     workflowObject: ");
	//console.dir({workflowObject:workflowObject});

	// SET TITLE AND MESSAGE
	var title = "Rename workflow '" + oldWorkflowName + "'";
	var message = "Please enter new name";
	
	// CALLBACKS
	var cancelCallback = function () {};
	var enterCallback = dojo.hitch(this, function (newWorkflowName)
		{
			if ( newWorkflowName == null )	return;
			newWorkflowName = newWorkflowName.replace(/\s+/, '');
			if ( newWorkflowName == '' )	return;

			// CHECK IF NAME EXISTS ALREADY
			if ( Agua.isWorkflow({
				project: projectName,
				name: newWorkflowName })
			) {
				//console.log("WorkflowMenu.renameWorkflow    Workflow '" + newWorkflowName + "' already exists. Returning");
				return;
			}
			
			// RENAME FILECACHE 
			//console.log("WorkflowMenu.renameWorkflow    Doing Agua.renameFileTree()");
			var oldLocation = projectName + "/" + oldWorkflowName;
			var newLocation = projectName + "/" + newWorkflowName;
			Agua.renameFileTree(username, oldLocation, newLocation);

			// RENAME DND ITEM
			dragPane.renameItem(dndItem, newWorkflowName);
	
			// RENAME WORKFLOW (AND STAGES, STAGEPARAMETERS, ETC.)
			//console.log("WorkflowMenu.renameWorkflow    Doing Agua.renameWorkflow()");
            Agua.renameWorkflow(workflowObject, newWorkflowName);

			// RELOAD RELEVANT DISPLAYS
			Agua.updater.update("updateProjects", {originator: this.parentWidget, reload: false});
		}
	);		

	// SHOW THE DIALOG
	this.loadInputDialog(title, message, enterCallback, cancelCallback);	
},
openWorkflow : function () {
	//console.log("WorkflowMenu.openWorkflow    plugins.files.WorkflowMenu.openWorkflow()");

	// LABEL THIS AS SELECTED WORKFLOW
	dojo.addClass(this.menu.currentTarget, 'dojoDndItemOver');

	// GET PROJECT WIDGET		
	var filesWidget = this.getFilesWidget();
	if ( filesWidget == null )	return;
	//console.log("WorkflowMenu.openWorkflow     filesWidget: " + filesWidget);

	var projectName = this.getProjectName();
	//console.log("WorkflowMenu.openWorkflow     projectName: " + projectName);

	var workflowName = this.getWorkflowName();
	//console.log("WorkflowMenu.openWorkflow     workflowName: " + workflowName);

	// CHECK IF WORKFLOW CONTROLLER IS LOADED
	var workflowController = Agua.controllers["workflow"];
	//console.log("WorkflowMenu.openWorkflow    workflowController: " + workflowController);

	// OPEN WORKFLOW TAB
	if ( Agua.controllers["workflow"] ) 
		Agua.controllers["workflow"].createTab({project: projectName, workflow: workflowName});
},
deleteWorkflow : function () {
// DELETE A WORKFLOW AFTER DIALOG BOX CONFIRMATION BY USER

	// SET WORKFLOW OBJECT
	var projectName = this.getProjectName();
	var workflowName = this.getWorkflowName();
	var workflowNumber = this.getWorkflowNumber();
	var workflowObject 		= new Object;
	workflowObject.project 	= projectName;
	workflowObject.name 	= workflowName;
	workflowObject.number	= workflowNumber;
	//console.log("WorkflowMenu.deleteWorkflow     workflowObject: ");
	//console.dir({workflowObject:workflowObject});
	
	// CALLBACKS
	var noCallback = function () { };
	var yesCallback = dojo.hitch(this, function () {

		// QUIT IF WORKFLOW DOES NOT EXIST
		if ( Agua.isWorkflow({ project: projectName, name: workflowName }) == false ) {
			//console.log("WorkflowMenu.deleteWorkflow    workflow " + workflowName + " does not exist. Returning");
			return;
		}

		// GET DND ITEM		
		var dndItem = this.menu.currentTarget;
		//console.log("WorkflowMenu.deleteWorkflow    dndItem: ");
		//console.dir({dndItem:dndItem});

		// REMOVE FILECACHES FOR FILE/FOLDER
		this.removeItemFileCache(dndItem);

		// REMOVE DND ITEM FROM DRAGPANE
		var dragPane = dijit.getEnclosingWidget(this.menu.currentTarget);
		//console.log("WorkflowMenu.deleteWorkflow     dragPane: " + dragPane);
		//console.dir({dragPane:dragPane});
		dragPane.deleteItem(dndItem);
		
		// REMOVE WORKFLOW
		Agua.removeWorkflow(workflowObject);
	});		

	// SET TITLE AND MESSAGE
	var title = "Delete workflow '" + workflowName + "'?";
	var message = "All files and data will be destroyed";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);
},
removeItemFileCache : function (dndItem) {
	var location = dndItem.item.parentPath + "/" + dndItem.item.path;
	var username = this.getUserName();
	//console.log("WorkflowMenu.removeItemFileCache     location: " + location);
	//console.log("WorkflowMenu.removeItemFileCache     username: " + username);
	Agua.removeFileTree(username, location);	
},
deleteProject : function () {
// DELETE A PROJECT AFTER DIALOG BOX CONFIRMATION BY USER
	// GET PROJECT WIDGET		
	var filesWidget = this.getFilesWidget();
	//console.log("WorkflowMenu.deleteProject     filesWidget: " );
	//console.dir({filesWidget:filesWidget});

	var fileDrag = this.getFileDrag();
	//console.log("WorkflowMenu.deleteProject     fileDrag: " );
	//console.dir({fileDrag:fileDrag});

	if ( filesWidget == null )	return;
	////////console.log("WorkflowMenu.deleteProject     filesWidget: " + filesWidget);

	var projectName = this.getProjectName();
	////////console.log("WorkflowMenu.deleteProject     projectName: " + projectName);

	// CALLBACKS
	var noCallback = function (){
		////////console.log("WorkflowMenu.deleteProject    noCallback()");
	};
	var yesCallback = dojo.hitch(this, function ()
		{
			// SANITY CHECK
			if ( ! Agua.isProject(projectName) ) {
				return;
			}

			// REMOVE PROJECT
			Agua.removeProject({ name: projectName });
			
			// RELOAD THE PROJECTS TAB
			setTimeout(function(thisObj) {
				//console.log("WorkflowMenu.deleteProject    Doing filesWidget.removeChild()");
				filesWidget.removeChild(fileDrag);
			}, 1000, this);
		}
	);		

	// SET TITLE AND MESSAGE
	var title = "Delete project '" + projectName + "'?";
	var message = "All workflows and data will be destroyed";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);
	
},
refresh : function (event) {
    var folder = this.menu.currentTarget.innerHTML;
	//console.log("WorkflowMenu.refresh    folder: " + folder);
	
	var dragPane = dijit.getEnclosingWidget(this.menu.currentTarget.offsetParent);
	//console.log("WorkflowMenu.refresh    dragPane: ");
	//console.dir({dragPane:dragPane});

	// GET LOCATION
	var location = dragPane.path + "/" + folder;
	//console.log("WorkflowMenu.refresh    location: " + location);

	// GET USERNAME
	var fileDrag = dragPane.parentWidget;
	//console.log("WorkflowMenu.refresh    fileDrag.store: ");
	//console.dir({fileDrag_store:fileDrag.store});
	var username = fileDrag.owner;
	//console.log("WorkflowMenu.refresh    username: " + username);	

	// RESET putData
	fileDrag.store.putData.mode		=	"fileSystem";
	fileDrag.store.putData.module	=	"Folders";
		
	// REMOVE EXISTING FILE CACHE
	//console.log("WorkflowMenu.refresh    Doing Agua.setFileCache(username, location, null)");
	Agua.setFileCache(username, location, null);
	
	//console.log("WorkflowMenu.refresh    Doing this.reloadPane(dragPane, folder)");	
	this.reloadPane(dragPane, folder);
},
// UTILITIES
getWorkflowName : function () {
// RETURN THE WORKFLOW NAME FOR THIS GROUP DRAG PANE OBJECT
	var item = this.menu.currentTarget.item;
	var workflowName = item.path;
	workflowName = workflowName.replace(/\s+/g, '');
	//////////console.log("WorkflowMenu.getWorkflowName     workflowName: " + workflowName);

	return workflowName;
},
getWorkflowNumber : function () {
// RETURN THE WORKFLOW Number FOR THIS GROUP DRAG PANE OBJECT
	var workflowName = this.menu.currentTarget.item.path;
	var dragPane = this.getDragPane();
	for ( var i = 0; i < dragPane.items.length; i++ ) {
		if ( dragPane.items[i].name == workflowName ) {
			return (i + 1);
		}
	}

	return null;
},
setSelectiveDialog : function () {
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "";
	var message = "";
	
	//////console.log("WorkflowMenu.setSelectiveDialog    plugins.files.Stages.setSelectiveDialog()");
	this.selectiveDialog = new plugins.dijit.SelectiveDialog(
		{
			title 				:	title,
			message 			:	message,
			inputMessage 		:	"",
			checkboxMessage 	:	"",
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
	//////console.log("WorkflowMenu.setSelectiveDialog    this.selectiveDialog: " + this.selectiveDialog);
},
loadSelectiveDialog : function (title, message, comboValues, inputMessage, comboMessage, checkboxMessage, enterCallback, cancelCallback) {
	//////console.log("WorkflowMenu.loadSelectiveDialog    enterCallback.toString(): " + enterCallback.toString());
	//////console.log("WorkflowMenu.loadSelectiveDialog    title: " + title);
	//////console.log("WorkflowMenu.loadSelectiveDialog    message: " + message);
	//////console.log("WorkflowMenu.loadSelectiveDialog    enterCallback: " + enterCallback);
	//////console.log("WorkflowMenu.loadSelectiveDialog    cancelCallback: " + cancelCallback);

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
getStandby : function () {
	//console.log("WorkflowMenu.getStandby    WorkflowMenu.getStandby()");
	
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
	//console.log("WorkflowMenu.getStandby    this.standby: " + this.standby);

	return this.standby;
},
getFileDrag : function () {
	var dragPane = this.getDragPane();
	return dragPane.parentWidget;
},
getDragPane : function () {
	//console.log("WorkflowMenu.getDragPane     this.menu.currentTarget: " );
	//console.dir({this_menu_currentTarget:this.menu.currentTarget});

	return dijit.getEnclosingWidget(this.menu.currentTarget);
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

}); // plugins.files.WorkflowMenu
