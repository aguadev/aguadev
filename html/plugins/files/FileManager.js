dojo.provide("plugins.files.FileManager");

/*
DISPLAY THE USER'S PROJECTS DIRECTORY AND ALLOW
THE USER TO BROWSE FILES AND MANIPULATE WORKFLOW
FOLDERS AND FILES   
*/

// EXTERNAL MODULES
if ( 1 ) {
dojo.require("dojox.widget.RollingList");
dojo.require("plugins.data.FileStore");

// DIALOG FLOATING PANE
dojo.require("plugins.dojox.layout.FloatingPane");

dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");
dojo.require("dijit.TitlePane");
dojo.require("dijit.Tooltip");

// INTERNAL MODULES
dojo.require("plugins.files.FileDrag");
dojo.require("plugins.files.FileMenu");
dojo.require("plugins.files.FolderMenu");
dojo.require("plugins.files.WorkflowMenu");
dojo.require("plugins.folders.ProjectFiles");
dojo.require("plugins.folders.SourceFiles");
dojo.require("plugins.folders.SharedProjectFiles");
dojo.require("plugins.folders.SharedSourceFiles");
}

dojo.declare( "plugins.files.FileManager",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "files/templates/filemanager.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// STORE DND SOURCE ID AND DND TARGET ID
sourceId: '',

// OWNER workflowObject
workflowObject : null,

// ID FOR THIS FILE MANAGER DIALOG PANE
dialogId : null,

// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins", "files/css/filemanager.css"),
	dojo.moduleUrl("dojox", "layout/resources/FloatingPane.css")
	//, dojo.moduleUrl("plugins", "folders/css/folders.css")
],

// callback FUNCTION AND DATA FROM OBJECT THAT GENERATED THE FileManager
callback : null,

// CORE WORKFLOW OBJECTS
core : null,

// CORE WORKFLOW OBJECTS:
// 	dialog:		DIALOGUE TO DISPLAY FILE MANAGER
//	nodes:		CONTAINER NODES FOR PROJECTS, SOURCES, ETC. 
// 	widgets:	ARRAY OF WIDGETS FOR PROJECTS, SOURCES, ETC.
dialog : null,
	
atomic : {},
////}}}

preamble: function(){
	//console.log("FileManager.preamble	plugins.files.FileManager.preamble()");
	this.callback = arguments[0].callback;
},
constructor : function(args) {
	console.log("XXXXXX FileManager.constructor	args:");
	console.dir({args:args});

	// LOAD CSS
	this.loadCSS();

	// SET MENUS
	this.setMenus();

	// SET CORE
	this.core = new Object;
	this.core.folders = this;
},
postCreate : function() {
	//console.log("Controller.postCreate    plugins.files.Controller.postCreate()");
	this.startup();
},
startup : function () {
// INSTANTIATE AND POPULATE FILE MANAGER DIALOG

	console.log("FileManager.startup	plugins.files.FileManager.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	console.log("FileManager.startup	BEFORE this.inherited(arguments)");
	this.inherited(arguments);	 
	console.log("FileManager.startup	AFTER this.inherited(arguments)");

console.log("startup, this.core: ");
console.log(this.core);


	// INSTANTIATE this.atomic.dialog
	this.createDialog();
	console.log("FileManager.startup	AFTER this.createDialog()");

	// SET ATOMIC
	this.setAtomic();

	//// SET REFRESH BUTTONS
	//this.setRefreshButtons();
	
	// SET NODES
	this.setNodes();

	// LOAD CONTENT (PROJECTS, SOURCES, ...)
	this.loadPanes();

	// START UP DIALOG ???
	this.atomic.dialog.startup();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateProjects");

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateSources");
},
updateProjects : function (args) {
// RELOAD PROJECT PANES
	console.log("FileManager.updateProjects    Cluster.updateProjects()");
	console.log("FileManager.updateProjects    this: " + this);

	// SET DRAG SOURCE
	console.log("FileManager.updateProjects    Calling this.loadPanes()");
	this.loadProjects();
},
updateWorkflows : function (args) {
	//console.warn("Workflows.updateWorkflows    project.Workflows.updateWorkflows(args)");
	//console.warn("Workflows.updateWorkflows    args:");
	//console.dir(args);

	// REDO PARAMETER TABLE
	if ( args != null && args.originator == this )
	{
		if ( args.reload == false )	return;
	}

	//console.warn("Workflows.updateWorkflows    Calling this.loadWorkflows()");
	this.loadWorkflows;
},
updateSources : function (args) {
// RELOAD SOURCE PANES
	console.log("FileManager.updateSources    Cluster.updateSources()");
	console.log("FileManager.updateSources    this: " + this);

	// SET DRAG SOURCE
	console.log("FileManager.updateSources    Calling this.loadSourceTab()");
	this.loadSources();	
},
setMenus : function () {
	//console.log("FileManager.setMenus     plugins.project.Project.setMenus()");

	this.fileMenu = new plugins.files.FileMenu({parentWidget : this});
	this.folderMenu = new plugins.files.FolderMenu({parentWidget : this});
	this.workflowMenu = new plugins.files.WorkflowMenu({parentWidget : this});
	
	//// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	//dojo.connect(this.folderMenu.menu.domNode, "oncontextmenu", function (event)
	//{
	//	event.stopPropagation();
	//});
	//
	//// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	//dojo.connect(this.workflowMenu.menu.domNode, "oncontextmenu", function (event)
	//{
	//	event.stopPropagation();
	//});
},
createDialog : function () {
	console.log("FileManager.createDialog    plugins.files.FileManager.createDialog()");

	var dialogId = dojo.dnd.getUniqueId();		
	this.dialogId = dialogId;
	var node = dojo.create('div');
	document.body.appendChild(node);

	// CREATE DIALOGUE
	this.atomic.dialog = new plugins.dojox.layout.FloatingPane ({

		id			: 	dialogId,

		draggable	: 	true,
		showTitle	: 	true,
		title		: 	"File Manager",
	
		region		:	"bottom",
		dockable	:	"true",
		duration	:	"10",
		height		:	"500px",
		width		:	"900px",

		resizable	:	"true",
		maxable		:	"false",
		closable	:	"false",
		
		dockClass	:	"filesDockNode"
		
	}, node);		

	// MAKE SURE DIALOG IS MINIMIZED ON startup
	dojo.style(this.atomic.dialog.domNode, "display", "none");
	dojo.style(this.atomic.dialog.domNode, "visibility", "hidden");

	// STARTUP
	this.atomic.dialog.startup();
	
	// MAXIMISE ON SHOW
	dojo.connect(this.atomic.dialog, "_onShow", this.atomic.dialog, "maximize");
	console.log("FileManager.createDialog    AFTER create dialog");

	// SET CLASS FOR STYLE OF INSERTED PANE
	console.log("FileManager.createDialog    Doing set class 'folders dijitDialog'");
	dojo.attr(dojo.byId(dialogId), 'class', 'folders dijitDialog');

	// SET DOM NODE POSITION
	console.log("FileManager.createDialog    Doing set style.top");
	this.atomic.dialog.domNode.style.top='100px';
	
	// SET DOM NODE CLASS
	console.log("FileManager.createDialog    Doing add class 'folders'");
	dojo.addClass(this.atomic.dialog.domNode, 'folders');

	// SET FILE MANAGER DIALOGUE CONTENT TO PANE NODE
	console.log("FileManager.createDialog     Doing this.atomic.dialog.content = this.mainTab.containerNode");
	console.log("FileManager.createDialog     this.mainTab.containerNode: " + this.mainTab.containerNode);

	dojo.connect(this.atomic.dialog, "minimize", this, "disableMenuSelect");
	dojo.connect(this.atomic.dialog, "minimize", this, "disableMenuAdd");
	
	this.atomic.dialog.containerNode.appendChild(this.mainTab.containerNode);	
},
setAtomic : function () {
	this.atomic.nodes = new Object;
	this.atomic.widgets = new Object;
},
setRefreshButtons : function () {
	console.log("FileManager.setRefreshButtons    FileManager.setRefreshButtons()");

	var commands = [
		{
			titleNode: this.projectsTitle.focusNode,
			title : "Refresh Projects",
			onclick : "loadProjects"
		},
		{
			titleNode: this.sharedProjectsTitle.focusNode,
			title : "Refresh Shared Projects",
			onclick : "loadSharedProjects"
		},
		{
			titleNode: this.sourcesTitle.focusNode,
			title : "Refresh Sources",
			onclick : "loadSources"
		},
		{
			titleNode: this.sharedSourcesTitle.focusNode,
			title : "Refresh Shared Sources",
			onclick : "loadSharedSources"
		}
	];
	
	var thisObject = this;
	dojo.forEach(commands, dojo.hitch(thisObject, function(command) {
		console.log("FileManager.setRefreshButtons    FileManager.setRefreshButtons(command)");
		console.log("FileManager.setRefreshButtons    command: ");
		console.dir(command);
		var node = document.createElement('div');
		command.titleNode.appendChild(node);
		dojo.attr(node, 'title', command.title);
		dojo.addClass(node, "refreshButton");
		dojo.connect(node, "onclick", this, command.onclick);
	}));
},
setNodes : function () {
	console.log("FileManager.setNodes    workflow.FileManager.setNodes()");
	// CREATE PANE NODE TO HOLD CONTENT
	var paneNode = document.createElement('div');
	dojo.addClass(paneNode, 'folders');
	this.paneNode = paneNode;
	
	var nodeNames = ["projects", "sharedProjects", "sources", "sharedSources"];
	var thisObject = this;
	dojo.forEach(nodeNames, function(nodeName) {
		console.log("FileManager.setNodes    thisObject[" + nodeName + "Node]: " + thisObject[nodeName + "Node"]);
		//var node = document.createElement('div');
		thisObject.atomic.nodes[nodeName] = thisObject[nodeName + "Node"];
		//paneNode.appendChild(node);
		//console.log("FileManager.remove     node: " + node);

		thisObject.atomic.widgets[nodeName] = new Array;
	});
},
loadPanes : function () {
	console.log("FileManager.loadPanes	   plugins.files.FileManager.loadPanes()");

	this.titlePanes = [];
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadProjects());
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadSources());
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadSharedProjects());
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadSharedSources());

	console.log("Folders.loadPanes    this.titlePanes.length: " + this.titlePanes.length);

	// DO ROUND ROBIN LOADING OF LEVEL 1
	this.roundRobin();
},
loadProjects : function () {
	//console.log("FileManager.loadProjects     plugins.folders.Folders.loadProjects()");
	this.remove("projectsNode", this.projectFiles);	

	this.projectFiles = new plugins.folders.ProjectFiles({
		open: 			false,
		title: 			'Projects',
		type: 			'Project',
		attachNode: 	this.projectsNode,
		fileMenu: 		this.fileMenu,
		folderMenu: 	this.folderMenu,
		workflowMenu: 	this.workflowMenu,
		core: 			this.core
	});
	//console.log("FileManager.loadProjects     AFTER NEW plugins.folders.ProjectFiles()");
	
	return this.projectFiles.titlePanes;
},
loadSources : function () {
// LOAD SOURCE FILE PANES
	//console.log("FileManager.loadSources     plugins.folders.Folders.loadSources()");

	// REMOVE EXISTING TITLE PANES
	while ( this.sourcesNode.firstChild ) {
		this.sourcesNode.removeChild(this.sourcesNode.firstChild);
	}

	this.sourceFiles = new plugins.folders.SourceFiles({
		open: 			false,
		title: 			'Sources',
		type: 			'Source',
		attachNode: 	this.sourcesNode,
		project: 		this.project,
		fileMenu: 		this.fileMenu,
		folderMenu: 	this.folderMenu,
		workflowMenu: 	this.workflowMenu,
		core: 			this.core
	});
	//console.log("FileManager.loadSources     AFTER NEW plugins.folders.SourceFiles()");
	return this.sourceFiles.titlePanes;
},
loadSharedProjects : function () {
	//console.log("FileManager.loadSharedProjects     plugins.folders.Folders.loadSharedProjects()");
	this.sharedProjectFiles = new plugins.folders.SharedProjectFiles({
		open: 			false,
		title: 			'Shared Projects',
		type: 			'Shared Project',
		attachNode: 	this.sharedProjectsNode,
		fileMenu: 		this.fileMenu,
		folderMenu: 	this.folderMenu,
		workflowMenu: 	this.workflowMenu,
		core: 			this.core
	});
	//console.log("FileManager.loadSharedProjects     AFTER NEW plugins.folders.SharedProjectFiles()");
	
	return this.sharedProjectFiles.titlePanes;
},
loadSharedSources : function () {
	//console.log("FileManager.loadSharedSources     plugins.folders.Folders.loadSharedSources()");
	this.sharedSourceFiles = new plugins.folders.SharedSourceFiles({
		open: 			false,
		title: 			'SharedSources',
		type: 			'Shared Source',
		attachNode: 	this.sharedSourcesNode,
		project: 		this.project,
		fileMenu: 		this.fileMenu,
		folderMenu: 	this.folderMenu,
		workflowMenu: 	this.workflowMenu,
		core : 			this.core
	});
	//console.log("FileManager.loadSharedSources     AFTER NEW plugins.folders.SharedSourceFiles()");
	
	return this.sharedSourceFiles.titlePanes;
},
roundRobin : function () {
	console.group("FileManager-" + this.id + "    roundRobin");
	console.log("FileManager.roundRobin    caller: " + this.roundRobin.caller.nom);
	console.log("FileManager.roundRobin    this.titlePanes.length: " + this.titlePanes.length);
	if ( ! this.titlePanes || this.titlePanes.length < 1 )	return;
	var array = this.titlePanes.splice(0, 1);
	var titlePane = array[0];
	console.log("FileManager.roundRobin    titlePane.name:" + titlePane.name);
	console.dir({titlePane:titlePane});
	var fakeEvent = {
		stopPropagation : function() {
			console.log("FileManager.roundRobin    fakeEvent.stopPropagation()");
		}
	}
	titlePane.reload(fakeEvent);
},
remove : function (nodeName, widget) {
// REMOVE EXISTING TITLE PANES
	console.log("FileManager.remove     nodeName: " + nodeName);
	console.log("FileManager.remove     widget: " + widget);

	while ( this[nodeName].firstChild )	{
		this[nodeName].removeChild(this[nodeName].firstChild);
	}

	if ( widget )	widget.destroy();
},
hide : function () {
	console.log("FileManager.hide    Doing this.atomic.dialog.minimize()");
	this.atomic.dialog.minimize();
},
show : function (parameterWidget) {
	console.log("FileManager.show    parameterWidget:");
	console.dir({parameterWidget:parameterWidget});

	// SET this.parameterWidget AND IN MENUS
	this.parameterWidget = parameterWidget;
	this.fileMenu.parameterWidget = parameterWidget;
	this.folderMenu.parameterWidget = parameterWidget;
	this.workflowMenu.parameterWidget = parameterWidget;

	// SHOW
	this.atomic.dialog.show();
	
	// OPEN PROJECT IF DEFINED
	var project = this.parameterWidget.project;
	var workflow = this.parameterWidget.workflow;
	console.log("FileManager.show    project: " + project);
	console.log("FileManager.show    workflow: " + workflow);
	
	this.openProjectLocation(project, workflow);
},
openProjectLocation : function (project, workflow) {
	var location = project;
	if ( workflow ) location += "/" + workflow;
	var username = Agua.cookie('username');
	
	var projectFiles = this.projectFiles;
	console.log("projectFiles: ");
	console.dir({projectFiles:projectFiles});
	projectFiles.openLocation(location, username);
},
openProject : function (project, workflow) {
	// OPEN THE TITLE PANE FOR THIS PROJECT
	console.log("FileManager.show	project: " + project);
	console.log("FileManager.show	workflow: " + workflow);

	var projectTitlePanes= this.atomic.nodes.projects;
	for ( var i = 0; i < projectTitlePanes.length; i++ )
	{
		var titlePane = this.projectTitlePanes[i];
		if ( titlePane.title == project )
		{
			console.log("FileManager.show	titlePane fo project '" + project + "': " + titlePane);
			// OPEN PROJECT PANE
			titlePane.open = false;
			titlePane.toggle();
			console.log("FileManager.show    AFTER titlePane.toggle()");
			console.log("FileManager.show    titlePane.fileSelector: " + titlePane.fileSelector);
			
			// SELECT WORKFLOW IF DEFINED
			if ( workflow != null && workflow )
				titlePane.fileSelector.selectChild(workflow);
			console.log("FileManager.show    AFTER titlePane.fileSelector.selectChild(" + workflow + ")");

/*
			//// SELECT DESIGNATED
			//setTimeout(function() {
			//	try {
			//
			//		console.log("FileManager.show    copyFile    Doing timeout groupDragPane.onclickHandler(event)");
			//		var fileDrag = projectFiles.fileDrag
			//		var children = fileDrag.getChildren();
			//		var groupDragPane = children[0];
			//		var item = groupDragPane.items[0];
			//		var event = { target: { item: item } };
			//		console.log("event: " + dojo.toJson(event));
			//		groupDragPane.onclickHandler(event);
			//
			//	} catch(e) {
			//	  console.log("FileManager.show    setTimeout error: " + dojo.toJson(e));
			//	}
			//}, 10000);
*/


		}
	}
},
openWorkflow : function (project, workflow) {
},
enableMenus : function () {
	console.log("FileManager.enableMenus     plugins.files.FileManager.enableMenus()");	
	this.fileMenu.enable();
	this.folderMenu.enable();
	this.workflowMenu.enable();
},
enableMenuSelect: function () {
	console.log("FileManager.enableMenuSelect     plugins.files.FileManager.enableMenuSelect()");	
	this.fileMenu.enableMenuItem("select");
	this.folderMenu.enableMenuItem("select");
	this.workflowMenu.enableMenuItem("select");
},
enableMenuAdd: function () {
	console.log("FileManager.enableMenuAdd     plugins.files.FileManager.enableMenuAdd()");	
	this.fileMenu.enableMenuItem("add");
	this.folderMenu.enableMenuItem("add");
	this.workflowMenu.enableMenuItem("add");
},
disableMenus : function () {
	console.log("FileManager.disableMenus     plugins.files.FileManager.disableMenus()");
	this.fileMenu.disable();
	this.folderMenu.disable();
	this.workflowMenu.disable();
},
disableMenuSelect: function () {
	this.fileMenu.disableMenuItem("select");
	this.folderMenu.disableMenuItem("select");
	this.workflowMenu.disableMenuItem("select");
},
disableMenuAdd: function () {
	this.fileMenu.disableMenuItem("add");
	this.folderMenu.disableMenuItem("add");
	this.workflowMenu.disableMenuItem("add");
},
concatArrays : function(array1, array2) {
	//console.log("FileManager.concatArrays    array1: ");
	//console.dir({array1:array1});
	//console.log("FileManager.concatArrays    array2: ");
	//console.dir({array2:array2});
	for ( var i = 0; i < array2.length; i++ ) {
		array1.push(array2[i]);
	}
	
	return array1;
}




}); 
