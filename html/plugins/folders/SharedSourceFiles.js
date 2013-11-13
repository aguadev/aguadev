dojo.provide("plugins.folders.SharedSourceFiles");

// DISPLAY THE USER'S OWN SOURCES DIRECTORY AND ALLOW
// THE USER TO BROWSE AND MANIPULATE FOLDERS AND FILES

// LATER FOR MENU: HOW TO DYNAMICALLY
// ENABLE / DISABLE MENU ITEM
// attr('disabled', bool) 

// INHERITS
dojo.require("plugins.folders.Files");

dojo.declare( "plugins.folders.SharedSourceFiles",
	[ plugins.folders.Files ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "folders/templates/filesystem.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT WIDGET
parentWidget : null,

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,

// DEFAULT TIME (milliseconds) TO SLEEP BETWEEN FILESYSTEM LOADS
sleep : 250,

// title : string
// Label of title pane
title : "Shared Sources",

// open: bool
// Whether or not title pane is open on load
open : true,


// titlePanes: array
// List of title pane widgets belonging to this pane
titlePanes : null,

self : "sourcefiles",

/////}}}

// CONSTRUCTOR	
constructor : function(args) {
	////console.log("SharedSourceFiles.constructor    plugins.folders.SharedSourceFiles.constructor(args)");
	
	// SET PANE ID
	this.paneId = args.paneId;

	// SET ARGS
	this.project 	= args.project;
	this.core 		= args.core;
	this.attachNode = args.attachNode;
	////console.log("SharedSourceFiles.constructor    this.parentWidget: " + this.parentWidget);
	////console.log("SharedSourceFiles.constructor    this.attachNode: " + this.attachNode);
	////console.log("SharedSourceFiles.constructor    this.project: " + this.project);

	// LOAD CSS
	////console.log("SharedSourceFiles.constructor    Doing this.loadCSS()");
	this.loadCSS();
},

postCreate: function() {
	////console.log("SharedSourceFiles.postCreate    plugins.folders.SharedSourceFiles.postCreate()");

	this.startup();
},

startup : function () {
// START MENUS
	////console.log("SharedSourceFiles.startup    plugins.folders.SharedSourceFiles.startup()");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
},


load : function () {
// *** LOAD FILESYSTEM ****
	//console.group("sharedSourceFiles-" + this.id + "    load");

	var usernames = Agua.getSharedUsernames();
	//console.log("SharedSourceFiles.loadSharedSourceFiles	   usernames: ");
	//console.dir({usernames:usernames});
	if ( ! usernames )	{
		//console.log("SharedSourceFiles.loadSharedSourceFiles	   usernames is null. Returning");
		//console.groupEnd("sharedSourceFiles-" + this.id + "    load");
		return;
	}

	this.titlePanes = new Array;
	for ( var j = 0; j < usernames.length; j++ )
	//for ( var j = 0; j < 1; j++ )
	{
		//console.group("sharedSourceFiles-" + this.id + "    load username: " + usernames[j]);

		//console.log("SharedSourceFiles.loadSharedSourceFiles	   usernames[" + j + "] : " + dojo.toJson(usernames[j]));
		
		if ( usernames[j] == "agua" ) {
			//console.log("SharedSourceFiles.loadSharedSourceFiles	   user is 'agua'. Doing 'continue'");
			//console.groupEnd("sharedSourceFiles-" + this.id + "    load username: " + usernames[j]);
			continue;
		}

		var directories = Agua.getSharedSourcesByUsername(usernames[j]);
		//console.log("SharedSourceFiles.loadSharedSourceFiles	   username " + usernames[j] + " directories: ");
		//console.dir({directories:directories});
		
		if ( ! directories ) {
			//console.log("SharedSourceFiles.loadSharedSourceFiles	   directories is null. Doing 'continue'");
			continue;
		}
		
		for ( var i = 0; i < directories.length; i++ )
		{
			//console.log("SharedSourceFiles.loadSharedSourceFiles	   directory " + i + " : ")
			//console.dir({directory:directories[i]});

			var directory 	= dojo.clone(directories[i]);
			directory.open	=	this.open;
			this.titlePanes.push(this.setTitlePane(directory));
			
		
			////console.log("SharedSourceFiles.load    BEFORE this.createStore(directories[i]). directory: ");
			////console.dir({directory:directory});
			//var store = this.createStore(directory);
			//
			//// GENERATE NEW FileDrag OBJECT
			//var fileDrag = new plugins.files.FileDrag({
			//	style			: 	"height: auto; width: 100%; minHeight: 50px;",
			//	store			: 	store,
			//	fileMenu		: 	this.fileMenu,
			//	folderMenu		: 	this.folderMenu,
			//	workflowMenu	: 	this.workflowMenu,
			//	owner			: 	directory.owner,
			//	parentWidget	: 	this,
			//	core			:	this.core
			//});
			//
			//// SET PATH FOR THIS SHARE
			////console.log("SharedSourceFiles.load    Setting fileDrag.path = directory.location = " + directory.location);
			//fileDrag.path = directory.location;                    
			//
			//// START UP FileDrag
			//fileDrag.startup();
			//
			//// ADD directoryDrag TO TITLE PANE
			//titlePane.containerNode.appendChild(fileDrag.domNode);

			////console.log("SharedSourceFiles.load    BREAK");
//break;

		} // shares

		//console.groupEnd("sharedSourceFiles-" + this.id + "    load username: " + usernames[j]);

	} // usernames

	//console.groupEnd("sharedSourceFiles-" + this.id + "    load");
},

getDirectories : function () {
// GET DIRECTORIES TO SEARCH FOR FILES
	return Agua.getSharedSources();
},


createFileDrag : function (directory) {
	////console.log("SharedSourceFiles.setFileDrag	   plugins.folders.SharedSourceFiles.setFileDrag(directory)");
	//console.log("SharedSourceFiles.createFileDrag	   directory: ");
	//console.dir({directory:directory});
	
	var store = this.createStore(directory);
	
	// GENERATE NEW FileDrag OBJECT
	var fileDrag = new plugins.files.FileDrag({
		style			: 	"height: auto; width: 100%; minHeight: 50px;",	
		store			: 	store,
		fileMenu		: 	this.fileMenu,
		folderMenu		: 	this.folderMenu,
		workflowMenu	: 	this.workflowMenu,
		owner			: 	directory.owner,
		parentWidget	: 	this,
		core			:	this.core
	});
	
	// SET PATH AS LOCATION
	fileDrag.path = directory.location;                    
	
	// ADD TO this.fileDrags
	this.fileDrags.push(fileDrag);	

	// START UP FileDrag
	fileDrag.startup();
	
	// ADD fileDrag TO TITLE PANE
	return fileDrag;
},

getPutData : function (directory) {
// CREATE DATA OBJECT FOR xhrPut

	//console.log("SharedSourceFiles.getPutData    directory:");
	//console.dir({directory:directory});

	var putData = new Object;
	putData.mode 		= 	"fileSystem";
	putData.module 		= 	"Folders";
	putData.requestor 	= 	Agua.cookie('username');
	putData.sessionid	=	Agua.cookie('sessionid');
	putData.location	=	directory.location;
	putData.url			=	Agua.cgiUrl + "agua.cgi?";
	putData.username	=	directory.owner;
	putData.owner		=	directory.owner;
	putData.location	=	directory.location;
	putData.groupname	=	directory.groupname;

	//console.log("SharedSourceFiles.getPutData    putData: ");
	//console.dir({putData:putData});

	return putData;
}

//,

//createStore : function (directory) {
//// CREATE STORE FOR FILE DRAG
//	////console.log("SharedSourceFiles.createStore     plugins.folders.SharedSourceFiles.createStore(directory)");
//	////console.log("SharedSourceFiles.createStore     directory: " + dojo.toJson(directory, true));
//	
//	
//	// SET URL
//	var url = this.url;
//	
//	// CREATE STORE
//	var store = new dojox.data.FileStore(
//		{
//			//id: paneNodeId + "-fileStore",
//			url: url,
//			pathAsQueryParam: true
//		}
//	);
//	
//	// SET FILE STORE path TO project
//	store.preamble = function()
//	{
//		////console.log("SharedSourceFiles.load	   store.preamble	plugins.folders.SharedSourceFiles.store.preamble()");
//		this.store.path = this.arguments[0].path;                        
//	};
//
//	return store;		
//},

//setTitlePane : function (directory) {
//// CREATE TITLE PANE
//	//console.log("SharedSourceFiles.setTitlePane	   BEFORE directory: " );
//	//console.dir({directory:directory});
//
//	directory.owner = directory.username;
//	directory.description = directory.description || '';
//	directory.open = this.open;
//	directory.title = this.title;
//
//	//console.log("SharedSourceFiles.setTitlePane	   AFTER directory:");
//	//console.dir({directory:directory});
//
//	var titlePaneNode = document.createElement('div');
//	this.rowsNode.appendChild(titlePaneNode);
//
//	// CREATE TITLE PANE			
//	var titlePane = new plugins.files.TitlePane({
//			owner 			: directory.owner,
//			type 			: directory.type,
//			name			: directory.name,
//			description		: directory.description,
//			open			: this.open,
//			//reloadCallback : callback,
//			directory 		: directory,
//			parentWidget 	: this,
//			core			:	this.core
//		},
//		titlePaneNode
//	);
//
//
//	return titlePane;
//}

	

});

