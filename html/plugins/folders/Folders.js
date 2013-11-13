dojo.provide("plugins.folders.Folders");

/* SUMMARY: 

	DISPLAY THE USER'S PROJECTS DIRECTORY AND ALLOW
	
	THE USER TO BROWSE FILES AND MANIPULATE WORKFLOW
	
	FOLDERS AND FILES

	USAGE SCENARIO 1: LOAD NEW 'FOLDERS' TAB
	
	Folders->loadPanes (populate this.titlePanes)
		ProjectFiles -> load (returns array of titlePanes)
			projectFiles -> setTitlePane
				
				
		SourceFiles -> load (returns array of titlePanes)
			... inherits from ProjectFiles ...

	Folders->roundRobin
		this.titlePanes[0] -> reload
			ProjectFiles (or SourceFiles) -> createFileDrag
				ProjectFiles -> createStore
					fileDrag.path = directory.name
				new plugins.files.FileDrag
					FileDrag -> startup
						fileDrag -> _getPaneForItem
							fileDrag -> getPaneForItem
								new plugins.files._GroupDragPane
									_GroupDragPane -> _load
										_GroupDragPane -> _doQuery 
											FileStore -> fetch({query: ...})
											
			Folders -> roundRobin
				... UNTIL this.titlePanes IS EMPTY
	
	
	USAGE SCENARIO 2: USE CLICKS ON A FOLDER
	
	Folders->loadPanes (populate this.titlePanes)
	
	
	
*/

if ( 1 ) {
// FILE DRAG
dojo.require("plugins.files.FileDrag");
dojo.require("plugins.files._FileInfoPane");
dojo.require("dojox.data.FileStore");

// DnD
dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");

// LAYOUT
dojo.require("dijit.layout.ContentPane");
//dojo.require("plugins.dojox.layout.ExpandoPane");
dojo.require("dijit.TitlePane");

// TOOLTIP
dojo.require("dijit.Tooltip");

// INHERITS
dojo.require("plugins.core.Common");

// HAS A
dojo.require("plugins.folders.ProjectFiles");
dojo.require("plugins.folders.SharedProjectFiles");
dojo.require("plugins.folders.SourceFiles");
dojo.require("plugins.folders.SharedSourceFiles");

// MENUS
dojo.require("plugins.files.FileMenu");
dojo.require("plugins.files.FolderMenu");
dojo.require("plugins.files.WorkflowMenu");

// INHERITS
dojo.require("plugins.core.Common");
}

dojo.declare( "plugins.folders.Folders",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "folders/templates/folders.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT NODE, I.E., TABS NODE
parentWidget : null,

// core: Object.
// { files: XxxxxFiles object, folders: Folders object, etc. }
core : null,

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,

// POLL SERVER FOR WORKFLOW STATUS
polling : false,

// INSERT TEXT BREAKS WIDTH, CORRESPONDS TO CSS WIDTH OF INPUT 'value' TABLE ELEMENT
textBreakWidth : 22,

// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins") + "folders/css/folders.css"
],

// XxxxxFiles: object
// Reference to components file groups
projectFiles 		: 	null,
sourceFiles 		: 	null,
sharedProjectFiles 	: 	null,
sharedSourceFiles 	:	null,

// callback : Function reference
// Call this after module has loaded
callback : null,

// url: String
// URL FOR REMOTE DATABASE
url: null,

//////}}
constructor : function(args) {		
	console.log("Folders.constructor    args:");
	console.dir({args:args});
	
	if ( ! args )	return;
	
	// GET ARGS
	this.callback = args.callback;
	this.project = args.project;

	this.attachWidget = Agua.tabs;	
	
	// SET CORE
	this.core = new Object;
	this.core.folders = this;

	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "/agua.cgi";

	// LOAD CSS
	////console.log("Folders.constructor    Doing this.loadCSS()");
	this.loadCSS();
},
postCreate: function() {
	////console.log("Folders.postCreate    plugins.folders.Folders.postCreate()");
	this.startup();
},
startup : function () {
	//console.log("Folders.startup    plugins.folders.Folders.startup()");

	if ( ! this.attachWidget ) {
		//console.log("Folders.startup    this.attachWidget is null. Returning");
		return;
	}
	
	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// ADD THE PANE TO THE TAB CONTAINER
	////console.log("Folders.startup    this.mainTab: " + this.mainTab);
	if ( this.attachWidget.addChild )
	{
		this.attachWidget.addChild(this.mainTab);
		this.attachWidget.selectChild(this.mainTab);
	}
	if ( this.attachWidget.appendChild )
	{
		this.attachWidget.appendChild(this.mainTab.domNode);
	}
	// SET MENUS
	this.setMenus();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateProjects");
	Agua.updater.subscribe(this, "updateWorkflows");
	Agua.updater.subscribe(this, "updateSources");

	// LOAD APPLICATIONS DND SOURCE AND TARGET INTO FRAMEWORK
	this.loadPanes();
	
	// DO CALLBACK IF COMPLETED
},
updateProjects : function (args) {
	////console.warn("Projects.updateProjects    project.Projects.updateProjects(args)");
	////console.warn("Projects.updateProjects    args:");
	////console.dir(args);

	// REDO PARAMETER TABLE
	if ( args != null && args.originator == this )
	{
		if ( args.reload == false )	return;
	}

	////console.warn("Projects.updateProjects    Calling this.loadProjects()");
	this.loadProjects;
},
updateWorkflows : function (args) {
	////console.warn("Workflows.updateWorkflows    project.Workflows.updateWorkflows(args)");
	////console.warn("Workflows.updateWorkflows    args:");
	////console.dir(args);

	// REDO PARAMETER TABLE
	if ( args != null && args.originator == this )
	{
		if ( args.reload == false )	return;
	}

	////console.warn("Workflows.updateWorkflows    Calling this.loadWorkflows()");
	this.loadWorkflows;
},
updateSources : function (args) {
	////console.warn("Sources.updateSources    project.Sources.updateSources(args)");
	////console.warn("Sources.updateSources    args:");
	////console.dir(args);

	// REDO PARAMETER TABLE
	if ( args != null && args.originator == this )
	{
		if ( args.reload == false )	return;
	}

	////console.warn("Sources.updateSources    Calling this.loadSources()");
	this.loadSources;
},
setMenus : function () {
	////console.log("Folders.setMenus     plugins.folders.Folders.setMenus()"); 	
	this.fileMenu = new plugins.files.FileMenu({parentWidget : this});
	this.folderMenu = new plugins.files.FolderMenu({parentWidget : this});
	this.workflowMenu = new plugins.files.WorkflowMenu({parentWidget : this});
	////console.log("Folders.setMenus     this.workflowMenu: " + this.workflowMenu);
	
	// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.folderMenu.menu.domNode, "oncontextmenu", function (event)
	{
		event.stopPropagation();
	});
	
	// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.workflowMenu.menu, "oncontextmenu", function (event)
	{
		event.stopPropagation();
	});
},
loadPanes : function ()	{
	////console.log("Folders.loadPanes     plugins.folders.Folders.loadPanes");

	// RENEW this.titlePanes
	this.titlePanes = [];

	// LOAD PANES
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadProjects());
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadSources());
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadSharedProjects());
	this.titlePanes = this.concatArrays(this.titlePanes, this.loadSharedSources());
	
	//console.log("Folders.loadPanes    this.titlePanes.length: " + this.titlePanes.length);

	this.roundRobin();
},
concatArrays : function(array1, array2) {
	for ( var i = 0; i < array2.length; i++ ) {
		array1.push(array2[i]);
	}
	
	return array1;
},
roundRobin : function () {
	//console.log("Folders.roundRobin    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX caller: " + this.roundRobin.caller.nom);
	//console.log("Folders.roundRobin    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX this.titlePanes.length: " + this.titlePanes.length);

	// DO CALLBACK IF LAST TITLE PANE
	if ( ! this.titlePanes || this.titlePanes.length < 1 )	{
		console.log("Folders.roundRobin    Doing this.callback if defined: " + this.callback);
		if ( this.callback )	this.callback();
		return;
	}
	
	var array = this.titlePanes.splice(0, 1);
	var titlePane = array[0];
	//console.log("Folders.roundRobin    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX titlePane.name:" + titlePane.name);
	//console.dir({titlePane:titlePane});
	var fakeEvent = {
		stopPropagation : function() {
			//console.log("Folders.roundRobin    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX fakeEvent.stopPropagation()");
		}
	}
	titlePane.reload(fakeEvent);
	
},
loadProjects : function () {
	////console.log("Folders.loadProjects     plugins.folders.Folders.loadProjects()");
	this.remove("projectsNode", this.projectFiles);	

	this.projectFiles = new plugins.folders.ProjectFiles(
	{
		open			:	true,
		title			:	'Projects',
		type			:	'Project',
		attachNode		:	this.projectsNode,
		fileMenu		:	this.fileMenu,
		folderMenu		:	this.folderMenu,
		workflowMenu	:	this.workflowMenu,
		core			:	this.core,
		url				:	this.url
	});
	////console.log("Folders.loadProjects     AFTER NEW plugins.folders.ProjectFiles()");
	
	return this.projectFiles.titlePanes;
},
loadSources : function () {
// LOAD SOURCE FILE PANES
	////console.log("Folders.loadSources     plugins.folders.Folders.loadSources()");

	// REMOVE EXISTING TITLE PANES
	while ( this.sourcesNode.firstChild ) {
		this.sourcesNode.removeChild(this.sourcesNode.firstChild);
	}

	this.sourceFiles = new plugins.folders.SourceFiles(
	{
		open			:	true,
		title			: 	'Sources',
		type			: 	'Source',
		attachNode		: 	this.sourcesNode,
		project			: 	this.project,
		fileMenu		: 	this.fileMenu,
		folderMenu		: 	this.folderMenu,
		workflowMenu	: 	this.workflowMenu,
		core			:	this.core,
		url				:	this.url
	});
	////console.log("Folders.loadSources     AFTER NEW plugins.folders.SourceFiles()");
	return this.sourceFiles.titlePanes;
},
loadSharedProjects : function () {
	////console.log("FileManager.loadSharedProjects     plugins.folders.Folders.loadSharedProjects()");
	this.sharedProjectFiles = new plugins.folders.SharedProjectFiles({
		open			:	false,
		title			:	'Shared Projects',
		type			:	'Shared Project',
		attachNode		:	this.sharedProjectsNode,
		fileMenu		:	this.fileMenu,
		folderMenu		:	this.folderMenu,
		workflowMenu	:	this.workflowMenu,
		core			:	this.core,
		url				:	this.url
	});
	////console.log("FileManager.loadSharedProjects     AFTER NEW plugins.folders.SharedProjectFiles()");
	
	return this.sharedProjectFiles.titlePanes;
},
loadSharedSources : function () {
	////console.log("FileManager.loadSharedSources     plugins.folders.Folders.loadSharedSources()");
	this.sharedSourceFiles = new plugins.folders.SharedSourceFiles({
		open			:	false,
		title			:	'SharedSources',
		type			:	'Shared Source',
		attachNode		:	this.sharedSourcesNode,
		project			:	this.project,
		fileMenu		:	this.fileMenu,
		folderMenu		:	this.folderMenu,
		workflowMenu	:	this.workflowMenu,
		core 			:	this.core,
		url				:	this.url
	});
	////console.log("FileManager.loadSharedSources     AFTER NEW plugins.folders.SharedSourceFiles()");
	
	return this.sharedSourceFiles.titlePanes;
},
remove : function (nodeName, widget) {
	////console.log("Folders.remove     project.Project.remove(nodeName, widget)");
	////console.log("Folders.remove     nodeName: " + nodeName);
	////console.log("Folders.remove     widget: " + widget);

	// REMOVE EXISTING TITLE PANES
	while ( this[nodeName].firstChild )
	{
		this[nodeName].removeChild(this[nodeName].firstChild);
	}

	if ( widget != null )	widget.destroy();
},
destroyRecursive : function () {
	console.log("Folders.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}

}); // end of plugins.folders.Folders
