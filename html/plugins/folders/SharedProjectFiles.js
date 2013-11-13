dojo.provide("plugins.folders.SharedProjectFiles");

// **********************
// *** LOAD SHARED PROJECTS  ****
// **********************

// LATER FOR MENU: DYNAMICALLY ENABLE / DISABLE MENU ITEM
// attr('disabled', bool) 

// DISPLAY THE SHARED PROJECT DIRECTORIES AND ALLOW
// THE USER TO BROWSE AND COPY FILES AND WORKFLOWS

// INHERITS
dojo.require("plugins.folders.ProjectFiles");

dojo.declare( "plugins.folders.SharedProjectFiles",
	[ plugins.folders.Files ], {

// open: bool
// Whether or not title pane is open on load
open : true,

// self: string
// Name used to represent this object in this.core
self : "sharedprojectfiles",

////}}}}}

load : function () {
// *** LOAD FILESYSTEM ****
	console.group("sharedProjectFiles    " + this.id + "    load");

	this.titlePanes = new Array;
	
	var usernames = Agua.getSharedUsernames();
	//console.log("SharedProjectFiles.loadSharedProjects	   usernames: ");
	//console.dir({usernames:usernames});
	for ( var j = 0; j < usernames.length; j++ )
	//for ( var j = 0; j < 1; j++ )
	{
		//console.log("SharedProjectFiles.loadSharedProjects	   usernames[" + j + "] : " + dojo.toJson(usernames[j]));
		
		if ( usernames[j] == "agua" ) {
			//console.log("SharedProjectFiles.loadSharedProjects	   user is 'agua'. Doing 'continue'");
			continue;
		}

		var directories = Agua.getSharedProjectsByUsername(usernames[j]);
		////console.log("SharedProjectFiles.loadSharedProjects	   directories: " + dojo.toJson(directories));

		for ( var i = 0; i < directories.length; i++ )
		{
			//console.log("SharedProjectFiles.loadSharedProjects	   directory " + i + " : ")
			//console.dir({directory:directories[i]});

			var directory 	= dojo.clone(directories[i]);
			directory.open	=	this.open;
			this.titlePanes.push(this.setTitlePane(directory));
		
		} // shares

	} // usernames

	console.groupEnd("sharedProjectFiles    " + this.id + "    load");
},

createFileDrag : function (directory) {
	console.log("SharedProjectFiles.createFileDrag    directory: ");
	console.dir({directory:directory});

	var store = this.createStore(directory);

	// GENERATE NEW FileDrag OBJECT
	var fileDrag = new plugins.files.FileDrag(
		{
			style		: 	"height: auto; width: 100%; minHeight: 50px;",
			store		: 	store,
			fileMenu	: 	this.fileMenu,
			folderMenu	: 	this.folderMenu,
			workflowMenu: 	this.workflowMenu,
			owner		: 	directory.owner,
			parentWidget: 	this,
			core		:	this.core
		}
	);

	// SET PATH FOR THIS SHARE
	//console.log("SharedProjectFiles.createFileDrag    Setting fileDrag.path = directory.name = " + directory.name);
	fileDrag.path = directory.name;                    
	
	// START UP FileDrag
	fileDrag.startup();

	return fileDrag;
},

getPutData : function (directory) {
	console.log("folders.SharedProjectFiles    directory:");
	console.dir({directory:directory});
	
	var putData = new Object;
	putData.mode 		= 	"fileSystem";
	putData.module 		= 	"Folders";
	putData.sessionid	=	Agua.cookie('sessionid');
	putData.url			=	Agua.cgiUrl + "agua.cgi?";
	putData.requestor	=	Agua.cookie('username');
	putData.username	=	directory.owner;
	putData.groupname	=	directory.groupname;

	//console.log("ProjectFiles.getPutData    putData: ");
	//console.dir({putData:putData});

	return putData;
}

});
