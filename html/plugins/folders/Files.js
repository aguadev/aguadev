dojo.provide("plugins.folders.Files");

/*
DISPLAY THE USER'S OWN PROJECTS DIRECTORY AND ALLOW
THE USER TO BROWSE AND MANIPULATE WORKFLOW FOLDERS
AND FILES

LATER FOR MENU: DYNAMICALLY ENABLE / DISABLE MENU ITEM
attr('disabled', bool) 
*/

if ( 1 ) {
dojo.require("plugins.files.FileDrag");
dojo.require("plugins.dojox.data.FileStore");

// DnD
dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");

// TOOLTIP
dojo.require("dijit.Tooltip");

// INHERITS
dojo.require("plugins.core.Common");

//HAS A
dojo.require("plugins.dijit.layout.BorderContainer");
//dojo.require("plugins.dojox.layout.ExpandoPane");

// INHERITS
dojo.require("plugins.core.Common");

// MENUS
dojo.require("plugins.files.FileMenu");
dojo.require("plugins.files.FolderMenu");
dojo.require("plugins.files.WorkflowMenu");

// HAS A TITLE PANE IN ITS TEMPLATE.
// ALSO INSERTS TITLE PANES INTO this.rowsNode
dojo.require("plugins.files.TitlePane");
}

dojo.declare( "plugins.folders.Files",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "folders/templates/filesystem.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PROJECT NAME 
project : null,

// DEFAULT TIME (milliseconds) TO SLEEP BETWEEN FILESYSTEM LOADS
sleep : 300,

// ARRAY OF PANE NAMES TO BE LOADED IN SEQUENCE [ name1, name2, ... ]
loadingPanes : null,

// STORE FILESYSTEM fileDrag OBJECTS
fileDrags : null,

// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins", "folders/css/dialog.css"),
	dojo.moduleUrl("plugins", "files/FileDrag/FileDrag.css"),
	dojo.moduleUrl("dojox", "widget/Dialog/Dialog.css")
],

// TYPE OR PURPOSE OF FILESYSTEM
title : "Workflow",

// core: object
// Contains refs to higher objects in hierarchy
// e.g., { folders: Folders object, files: XxxxxFiles object, ... }
core : null,

// open: bool
// Whether or not title pane is open on load
open : true,

// self: string (MUST BE DEFINED)
// Name used to represent this object in this.core
self : null,

// url: String
// URL FOR REMOTE DATABASE
url: null,

//////}}
constructor : function(args) {
	//console.group("projectFiles-" + this.id + "    constructor");
	//console.log("Files.constructor    plugins.folders.Files.constructor(args)");
	//console.dir({args:args});
	
	// SET ARGS
	if ( args.open )	this.open = args.open;
	if ( this.open == null )	this.open = false;
	this.core = args.core;
	this.attachNode = args.attachNode;
	//console.log("Files.constructor    this.titlePane: " + this.titlePane);
	//console.log("Files.constructor    this.parentWidget: " + this.parentWidget);
	//console.log("Files.constructor    this.attachNode: " + this.attachNode);
	//console.log("Files.constructor    this.open: " + this.open);

	// LOAD CSS
	//console.log("Files.constructor    Doing this.loadCSS()");
	if ( args.cssFiles != null ) this.cssFiles = args.cssFiles;
	this.loadCSS(this.cssFiles);

	//console.groupEnd("projectFiles-" + this.id + "    constructor");
},
postCreate: function() {
// DO STARTUP
	//console.log("Files.postCreate    plugins.folders.Project.postCreate()");
	//console.log("Files.postCreate    this.titlePane: " + this.titlePane);
	//console.log("Files.postCreate    this.title: " + this.title);

	// SET RELOAD CALLBACK
	console.log("Files.postCreate    DOING dojo.hitch(this, 'reload')");
	this.titlePane.reloadCallback = dojo.hitch(this, "reload");
	//console.log("Files.postCreate    this.titlePane.reloadCallback: " + this.titlePane.reloadCallback);

	this.startup();
},
startup : function () {
	console.group("Files    " + this.id + "    startup");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	console.log("Files.startup    BEFORE this.inherited(arguments)");
	this.inherited(arguments);
	console.log("Files.startup    AFTER this.inherited(arguments)");

	// ADD THE PANE TO THE TAB CONTAINER
	console.log("Files.startup    this.mainNode: " + this.mainNode);
	console.log("Files.startup    this.attachNode: " + this.attachNode);
	console.log("Files.startup    this.attachNode.addChild: " + this.attachNode.addChild);
	console.log("Files.startup    this.attachNode.appendChild: " + this.attachNode.appendChild);

	// ADD DIRECTLY TO TAB CONTAINER		
	if ( this.attachNode.addChild != null ) {
		dojo.require("dijit.layout.LayoutContainer");
		var projectFilesContainer = new dijit.layout.LayoutContainer({ title: "Files" }, this.mainNode);
		console.log("Files.startup    projectFilesContainer: " + projectFilesContainer);
		projectFilesContainer.id = "projectFilesContainer";
		this.attachNode.addChild(projectFilesContainer);
	}
    // OTHERWISE, WE ARE TESTING SO APPEND TO DOC BODY
	else {
		this.attachNode.appendChild(this.mainNode);
	}
	console.log("Files.startup    AFTER this.attachNode.appendChild(this.mainNode)");

	// SET this.fileDrags
	this.fileDrags = [];

	// LOAD TITLEPANES
	this.load();

	console.groupEnd("Files    " + this.id + "    startup");
},
reload : function () {
// RELOAD ALL FileDrag OBJECTS
	this.clear();	
	this.load();
},
getDirectories : function () {
// GET DIRECTORIES TO SEARCH FOR FILES
// *** OVERRIDE THIS IN INHERITING CLASS ***
	//console.log("Files.getDirectories    plugins.folders.Project.getDirectories()");

	var projects = Agua.getProjects();
	//console.log("Files.getDirectories    projects: " + projects);
	
	return projects;
},
clear: function () {
	while ( this.rowsNode.firstChild ) {
		this.rowsNode.removeChild(this.rowsNode.firstChild);
	}
},
load : function () {
// LOAD FILESYSTEMS
	console.group("Files    " + this.id + "    load");
	var directories = this.getDirectories();

	if ( directories == null ) {
		//console.log("Files.load	   directories is null. Returning");
		return;
	}
	console.log("Files.load	   directories.length: " + directories.length);
	console.log("Files.load	   directories: ");
	console.dir({directories:directories});

	this.titlePanes = new Array;
	//for ( var i = 0; i < 1; i++ ) {
	for ( var i = 0; i < directories.length; i++ ) {
		var directory = dojo.clone(directories[i]);
		var titlePane = this.setTitlePane(directory);
		this.titlePanes.push(titlePane);
	}
	console.groupEnd("Files    " + this.id + "    load");
},
setTitlePane : function (directory) {
// GENERATE THE FILESYSTEM PANE FOR A PROJECT
	//console.log("Files.setTitlePane	   BEFORE directory: " );
	//console.dir({directory:directory});

	if ( ! directory.owner )
		directory.owner = directory.username;
	directory.description = directory.description || '';
	directory.open = this.open;
	directory.title = this.title;

	//console.log("Files.setTitlePane	   AFTER directory:");
	//console.dir({directory:directory});

	var titlePaneNode = document.createElement('div');
	this.rowsNode.appendChild(titlePaneNode);

	this.core[this.self] = this;
	
	// CREATE TITLE PANE			
	var titlePane = new plugins.files.TitlePane({
			owner 		: 	directory.owner,
			type 		: 	directory.type,
			name		: 	directory.name,
			location	: 	directory.location,
			description	: 	directory.description,
			open		: 	directory.open,
			directory 	: 	directory,
			core 		: 	this.core,
			master		:	this.self
		},
		titlePaneNode
	);
	
	return titlePane;
},
createFileDrag : function (directory) {
// SET THE FILE SYSTEM PANE
	//console.log("Files.createFileDrag	   this.id: " + this.id);
	//console.log("Files.createFileDrag	   directory: ");
	//console.dir({directory:directory});

	// CREATE STORE	
	var store = this.createStore(directory);
	//console.log("Files.createFileDrag	   store: ");
	//console.dir({store:store});
	
	// SET core.files
	this.core[this.self] = this;

	// GENERATE NEW FileDrag OBJECT
	var fileDrag = new plugins.files.FileDrag({
			style			: 	"height: auto; width: 100%; minHeight: 50px;",
			store			: 	store,
			fileMenu		: 	this.fileMenu,
			folderMenu		: 	this.folderMenu,
			workflowMenu	: 	this.workflowMenu,
			core			: 	this.core,
			parentWidget	:	this,
			owner			:	directory.owner,
			path			:	directory.name,
			description		:	directory.description || ''
		}
	);
	
	// ADD TO this.fileDrags
	this.fileDrags.push(fileDrag);	

	// START UP FileDrag
	fileDrag.startup();
	
	return fileDrag;
},
addChild : function (directory) {
	// CREATE TITLEPANE
	var titlePane = this.setTitlePane(directory);
	this.titlePanes.push(titlePane);
	
	// SET FILECACHE
	var name 		= directory.name;
	var username 	= directory.owner;
	var entry		 = {"name":name,"path":name,"total":"0","items":[]};
	Agua.setFileCache(username, name, entry);
	
	// LOAD FILEDRAG
	var event = { stopPropagation : function () {} };
	titlePane.reload(event);
},
removeChild : function (fileDrag) {
	//console.log("Files.removeChild    fileDrag:");
	//console.dir({fileDrag:fileDrag});
	
	if ( ! this.fileDrags ) return false;
	for ( var i = 0; i < this.fileDrags.length; i++ ) {
		if ( this.fileDrags[i] == fileDrag ) {
			this.fileDrags.splice(i, 1);
			//console.log("Files.removeChild    Doing destroyRecursive on child " + i);
			fileDrag.destroyRecursive();
			
			var panes = this.titlePanes.splice(i,1);
			var titlePane = panes[0];
			//console.log("Files.removeChild    titlePane: ");
			//console.dir({titlePane:titlePane});
			titlePane.destroyRecursive();
			
			return true;
		}
	}
	
	return false;
},
getPutData : function (directory) {
// **** OVERRIDE THIS IN SUBCLASS ****
	//console.log("Files.getPutData    this.id: " + this.id);
	//console.log("Files.getPutData    directory:");
	//console.dir({directory:directory});

	var putData = new Object;
	putData.mode 		= 	"fileSystem";
	putData.module 		= 	"Folders";
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid	=	Agua.cookie('sessionid');
	putData.url			=	this.url;
	putData.path		=	directory.name;

	//console.log("Files.getPutData    putData: ");
	//console.dir({putData:putData});

	return putData;
},
createStore : function (directory) {
// CREATE STORE FOR FILE DRAG
	//console.log("Files.createStore     this.id: " + this.id);
	//console.log("Files.createStore	   directory:");
	//console.dir({directory:directory});
	
	// SET URL
	var url 	= this.url;
	var putData	= this.getPutData(directory);
	
	// CREATE STORE
	var store = new plugins.dojox.data.FileStore({
		url					: 	url,
		putData				: 	putData,
		pathAsQueryParam	: 	true,
		parentPath			: 	this.parentPath,
		path				: 	directory.name
	});
	
	// SET FILE STORE path TO project
	store.preamble = function() {
		//console.log("Files.load	   store.preamble	plugins.folders.Files.store.preamble()");
		//console.log("Files.load	   store.preamble	Setting this.store.path = this.arguments[0].path = " + this.arguments[0].path);
		this.store.path = this.arguments[0].path;                     	};

	return store;		
},
openLocation : function (location, username) {
    console.log("Files.openLocation    location: " + location);
    console.log("Files.openLocation    username: " + username);
    
    var folders = location.split(/\//);
    var projectName = folders[0];
    var fileDrag = this.getFileDragByProject(projectName);
    console.log("Files.openLocation    fileDrag: ");
    console.dir({fileDrag:fileDrag});
    if ( ! fileDrag ) {
        //console.log("Files.openLocation    fileDrag is NULL. RETURNING");
        return;
    }

    var dragPanes = fileDrag.getChildren();
    console.dir({dragPanes:dragPanes});
    if ( ! dragPanes )
        fileDrag.startup();
    dragPanes = fileDrag.getChildren();
    console.log("Files.openLocation    dragPanes.length: " + dragPanes.length);
    //console.dir({dragPanes:dragPanes});

    if ( folders.length < 2 )    return;

    console.log("Files.openLocation    Doing this.folderRoundRobin(" + location + ", 1)");
    this.folderRoundRobin(location, 1);    
},
folderRoundRobin : function (location, index) {
	console.log("Files.folderRoundRobin    location: " + location);
	console.log("Files.folderRoundRobin    index: " + index);
	console.log("Files.folderRoundRobin    caller: " + this.folderRoundRobin.caller.nom);
	
	// SET FOLDERS
	var folders = location.split(/\//);
	console.log("Files.folderRoundRobin    folders.length: " + folders.length);
	
	// GET DRAG PANES
	var projectName = folders[0];
	var fileDrag = this.getFileDragByProject(projectName);
	console.dir({fileDrag:fileDrag});    
	var dragPanes = fileDrag.getChildren();
	console.log("Files.folderRoundRobin    dragPanes.length: " + dragPanes.length);

	// REMOVE dojo.connect ON PREVIOUS DRAG PANE
	if ( index > 1 ) {
		console.log("Files.folderRoundRobin    Removing connection for previous dragPane");
		var previousDragPane = dragPanes[index - 1];	
		if ( previousDragPane._connection )
			dojo.disconnect(previousDragPane._connection);
	}

	// SET CALLBACK
	var callback = dojo.hitch(this, "connectRoundRobin", fileDrag, location, index + 1);	

	// OPEN PANE IF NOT OPEN
	var thisObject;
	if ( dragPanes.length < index + 1 ) {
		if ( (index + 1) <= folders.length ) {
			this.openFolder(dragPanes[index - 1], folders[index], callback);
		}
	}
	else {
		// REOPEN PANE IF WRONG FOLDER IS OPEN
		var dragPane = dragPanes[index];
		console.log("Files.folderRoundRobin    dragPane " + index + ": " + dragPane);
		var path = dragPane.path;
		console.log("Files.folderRoundRobin    Doing folder " + index + " path: " + path);
		var folderPath = this.folderPathByIndex(folders, index);
		console.log("Files.folderRoundRobin    Doing folder " + index + " folderPath: " + folderPath);
		
		if ( folderPath != path )
			this.openFolder(dragPanes[index - 1], folders[index], callback);
	}
},
openFolder : function (dragPane, name, callback) {
	//console.log("Files.openFolder    dragPane: " + dragPane);
	//console.log("Files.openFolder    name: " + name);
	
	// REMOVE 'SELECTED' STYLE ON ANY SELECTED ITEMS
	dragPane._dragSource._removeSelection();
	
	var itemIndex = this.getItemIndexByName(dragPane, name);
	//console.log("Files.openFolder    itemIndex: " + itemIndex);
	if ( itemIndex < 0 )	return;
	
	var items = dragPane._dragSource.getAllNodes();
	//console.log("Files.openFolder    items:");
	//console.dir({items:items});
	
	// ADD CLASS dojoDndItemAnchor TO OPENED FOLDER
	//console.log("Files.openFolder    Adding class 'dojoDndItemAnchor' to item " + itemIndex);
	dojo.addClass(items[itemIndex], 'dojoDndItemAnchor');
	
    var item = items[itemIndex].item;
    var event = { target: { item: item } };
	//console.log("Files.openFolder    event:");
	//console.dir({event:event});

	//console.log("Files.openFolder    BEFORE this._connection:");
	//console.dir({this_connection:this._connection});
	if ( this._connection )
		dojo.disconnect(this._connection);
	//console.log("Files.openFolder    AFTER this._connection:");
	//console.dir({this_connection:this._connection});

	delete this._connection;
	this._connection = dojo.connect(dragPane.parentWidget, "addChild", dojo.hitch(this, callback));
	
    dragPane.onclickHandler(event);	
},
testCallback : function (itemPane, index, fileDrag) {
	//console.log("Files.testCallback    fileDrag: " + fileDrag);

},
connectRoundRobin : function (fileDrag, location, index) {
	//console.log("Files.connectRoundRobin    fileDrag:");
	//console.dir({fileDrag:fileDrag});
	//console.log("Files.connectRoundRobin    location: " + location);
	//console.log("Files.connectRoundRobin    index: " + index);

	var dragPanes = fileDrag.getChildren();
	var dragPane = dragPanes[dragPanes.length - 1];
	//console.log("Files.connectRoundRobin    dragPane:");
	//console.dir({dragPane:dragPane});
	
	dragPane._connection = dojo.connect(dragPane, "onLoad", dojo.hitch(this, "folderRoundRobin", location, index));
},
getFileDragByProject : function (projectName) {
	//console.log("Files.getFileDragByProject    projectName: " + projectName);
	//console.log("Files.getFileDragByProject    this.fileDrags.length: " + this.fileDrags.length);
	//console.log("Files.getFileDragByProject    this.fileDrags:");
	//console.dir({this_fileDrags:this.fileDrags});

	for ( var i = 0; i < this.fileDrags.length; i++ ) {
		var fileDrag = this.fileDrags[i];
		//console.log("Files.getFileDragByProject    Checking fileDrag.path " + i + ": " + fileDrag.path);

		if ( fileDrag.path == projectName ) {
			//console.log("Files.getFileDragByProject    Returning fileDrag for project: " + projectName);
			return fileDrag;
		}
	}
	
	return null;
},
refreshFileDrags : function () {
    var projects = Agua.getProjects();
    //console.dir({projects:projects});

	var fileDragNodes = dojo.query(".dojoxFileDrag");
	this.fileDrags = [];
	for ( var i = 0; i < fileDragNodes.length; i++ ) {
		this.fileDrags.push(dijit.byNode(fileDragNodes[i]));
	}
	//console.log("Files.refreshFileDrags    this.fileDrags: ");
	//console.dir({this_fileDrags:this.fileDrags}); 
},
getItemIndexByName : function (dragPane, name) {
	//console.log("Files.getItemIndexByName    dragPane: " + dragPane);
	//console.log("Files.getItemIndexByName    name: " + name);
	var dndItems = dragPane._dragSource.getAllNodes();
	//console.log("Files.getItemIndexByName    dndItems.length: " + dndItems.length);
	//console.dir({dndItems:dndItems});
	for ( var i = 0; i < dndItems.length; i++ ) {
		////console.log("Files.getItemIndexByName    dndItems[" + i + "].item.name: " + dndItems[i].item.name);
		if ( dndItems[i].item.name == name )
			return i;
	}

	return -1;
},
folderPathByIndex : function (folders, index) {
	if ( index > folders.length - 1)	return;

	var path = '';
	for ( var i = 0; i < index + 1; i++ ) {
		if ( i > 0 )
			path += "/";
		path += folders[i];
	}
	
	return path;
}
});

