dojo.provide("plugins.folders.SourceFiles");
/*
DISPLAY THE USER'S OWN SOURCES DIRECTORY AND ALLOW
THE USER TO BROWSE AND MANIPULATE FOLDERS AND FILES

LATER FOR MENU: DYNAMICALLY ENABLE / DISABLE MENU ITEM
attr('disabled', bool) 
*/

// INHERITS
dojo.require("plugins.folders.Files");


dojo.declare( "plugins.folders.SourceFiles",
	[ plugins.folders.Files ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "folders/templates/filesystem.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// core: Object. { files: XxxxxFiles object, folders: Folders object, etc. }
core : null,

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,

// DEFAULT TIME (milliseconds) TO SLEEP BETWEEN FILESYSTEM LOADS
sleep : 250,

// open: bool
// Whether or not title pane is open on load
open : false,

// self: string
// Name used to represent this object in this.core
self : "sourcefiles",

/////}}}

// CONSTRUCTOR	
constructor : function(args) {
	//console.group("sourceFiles-" + this.id + "    constructor");

	////console.log("SourceFiles.constructor    plugins.folders.SourceFiles.constructor(args)");
	
	// SET PANE ID
	this.paneId = args.paneId;

	// SET ARGS
	this.project 	= args.project;
	this.core 		= args.core;
	this.attachNode = args.attachNode;
	////console.log("SourceFiles.constructor    this.parentWidget: " + this.parentWidget);
	////console.log("SourceFiles.constructor    this.attachNode: " + this.attachNode);
	////console.log("SourceFiles.constructor    this.project: " + this.project);

	// LOAD CSS
	////console.log("SourceFiles.constructor    Doing this.loadCSS()");
	this.loadCSS();

	//console.groupEnd("sourceFiles-" + this.id + "    constructor");
},

postCreate: function() {
	////console.log("SourceFiles.postCreate    plugins.folders.Project.postCreate()");

	this.startup();
},


startup : function () {
// START MENUS
	////console.log("SourceFiles.startup    plugins.folders.Project.startup()");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
},

load: function () {
	//console.group("sourceFiles-" + this.id + "    load");

	this.inherited(arguments);
	
	//console.groupEnd("sourceFiles-" + this.id + "    load");
},

getDirectories : function () {
// GET DIRECTORIES TO SEARCH FOR FILES
	return Agua.getSources();
},

createFileDrag : function (directory) {
// SET THE FILE SYSTEM PANE
	//console.log("SourceFiles.createFileDrag	   plugins.folders.ProjectFiles.createFileDrag(directory)");	   
	//console.log("SourceFiles.createFileDrag	   directory: ");
	//console.dir({directory:directory});

	// CREATE STORE	
	var store = this.createSourceStore(directory);

	// SET core
	this.core[this.self] = this;

	// GENERATE NEW FileDrag OBJECT
	var fileDrag = new plugins.files.FileDrag(
		{
			style			: 	"height: auto; width: 100%; minHeight: 50px;",
			store			: 	store,
			fileMenu		: 	this.fileMenu,
			folderMenu		: 	this.folderMenu,
			workflowMenu	: 	this.workflowMenu,
			core			: 	this.core,
			parentWidget	:	this,
			owner			: 	directory.owner,
			path			:	'',
			description		:	directory.description || ''
		}
	);
	
	// ADD TO this.fileDrags
	this.fileDrags.push(fileDrag);	

	// START UP FileDrag
	fileDrag.startup();
	
	return fileDrag;
},

createSourceStore : function (directory) {
// CREATE STORE FOR FILE DRAG
	//console.log("ProjectFiles.createStore     this.id: " + this.id);
	//console.log("ProjectFiles.createStore	   directory:");
	//console.dir({directory:directory});
	
	// SET URL
	var url 	= this.url;
	var putData	= this.getSourcePutData(directory);
	
	// CREATE STORE
	var store = new plugins.dojox.data.FileStore({
		url					: 	url,
		putData				: 	putData,
		pathAsQueryParam	: 	true,
		parentPath			: 	this.parentPath,
		path				: 	directory.name
	});
	
	return store;		
},

getSourcePutData : function (directory) {
// CREATE DATA OBJECT FOR xhrPut
	//console.log("SourceFiles.getPutData    this.id: " + this.id);
	//console.log("SourceFiles.getPutData    directory:");
	//console.dir({directory:directory});

	var putData = new Object;
	putData.mode 		= 	"fileSystem";
	putData.module 		= 	"Folders";
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid	=	Agua.cookie('sessionid');
	putData.location	=	directory.location;
	putData.url			=	Agua.cgiUrl + "agua.cgi?";

	//console.log("SourceFiles.getPutData    putData: ");
	//console.dir({putData:putData});

	return putData;
}

	
});


/*
 
 setFileDrag : function (directory) {
	//console.log("SourceFiles.setFileDrag	   plugins.folders.SourceFiles.setFileDrag(directory)");	   
	//console.log("SourceFiles.setFileDrag	   directory: ");
	//console.dir({directory:directory});

	var owner = directory.username;
	var name = directory.name;
	var description = directory.description;
	var location = directory.location;
	if ( ! description ) { description = '' };
		
	var titlePane = this.createTitlePane(
	{
		owner: owner,
		name: name,
		description: description,
		location: location,
		open: this.open
	});

	// REMOVE NAME TO SET QUERY AS ''
	var thisStore = this.createStore(directory);
	
	// GENERATE NEW FileDrag OBJECT
	var fileDrag = new plugins.files.FileDrag(
		{
			style: "height: auto; width: 100%; minHeight: 50px;",
			store: thisStore,
			fileMenu: this.fileMenu,
			folderMenu: this.folderMenu,
			workflowMenu: this.workflowMenu,
			owner: owner,
			parentWidget: this
		}
	);
	
	// SET PATH AS LOCATION
	////console.log("SourceFiles.setFileDrag	   BEFORE replace directory.location: **" + directory.location + "**");
	directory.location = directory.location.replace(/\s+/g, '');
	//console.log("SourceFiles.setFileDrag	   AFTER replace directory.location: **" + directory.location + "**");

	fileDrag.path = directory.location;                    
	
	// START UP FileDrag
	fileDrag.startup();

//////console.log("SourceFiles.load	   ////console.dir(fileDrag): " + fileDrag);
//////console.dir(fileDrag);
	
	// ADD fileDrag TO TITLE PANE
	titlePane.containerNode.appendChild(fileDrag.domNode);
},

 */