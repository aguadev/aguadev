
dojo.provide("plugins.files.FolderMenu");

// WIDGET PARSER
dojo.require("dojo.parser");

// INHERITS
dojo.require("plugins.files.FileMenu");

// HAS A
dojo.require("dijit.Menu");

dojo.declare("plugins.files.FolderMenu",
	[ plugins.files.FileMenu ], {

	//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "files/templates/foldermenu.html"),

/////}}}}}
constructor : function(args) {
	////////console.log("FolderMenu.constructor     plugins.files.FolderMenu.constructor");			
	// GET INFO FROM ARGS
	//this.parentWidget = args.parentWidget;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	////////console.log("FolderMenu.postCreate    plugins.files.FolderMenu.postCreate()");

	// DISABLE DOWNLOAD
	//this.downloadNode.destroy();
	
	// SET LABEL
	this.setTitle("Folder Menu");

	// SET INPUT DIALOG
	this.setInputDialog();

	// SET CONFIRM DIALOG
	this.setConfirmDialog();

	// CONNECT SHORTKEYS FOR MENU
	this.setMenu();

	// SET THE UPLOAD OBJECT
	this.setUploader();

	// DO STARTUP
	this.startup();
},
refresh : function (event) {
    var folder = this.menu.currentTarget.innerHTML;
	//console.log("FolderMenu.refresh    folder: " + folder);
	
	var dragPane = dijit.getEnclosingWidget(this.menu.currentTarget.offsetParent);
	//console.log("FolderMenu.refresh    dragPane: ");
	//console.dir({dragPane:dragPane});

	// GET LOCATION
	var location = dragPane.path + "/" + folder;
	//console.log("FolderMenu.refresh    location: " + location);

	// GET USERNAME
	var fileDrag = dragPane.parentWidget;
	//console.log("FolderMenu.refresh    fileDrag.store: ");
	//console.dir({fileDrag_store:fileDrag.store});
	var username = fileDrag.owner;
	//console.log("FolderMenu.refresh    username: " + username);	

	// RESET putData
	fileDrag.store.putData.mode		=	"fileSystem";
	fileDrag.store.putData.module	=	"Folders";
		
	// REMOVE EXISTING FILE CACHE
	//console.log("FolderMenu.refresh    Doing Agua.setFileCache(username, location, null)");
	Agua.setFileCache(username, location, null);
	
	//console.log("FolderMenu.refresh    Doing this.reloadPane(dragPane, folder)");	
	this.reloadPane(dragPane, folder);
}



}); // plugins.files.FolderMenu
