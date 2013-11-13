dojo.provide("plugins.files.FileMenu");

// WIDGET PARSER
dojo.require("dojo.parser");

// INHERITS
dojo.require("plugins.core.Common");

// HAS A
dojo.require("plugins.menu.Menu");
dojo.require("plugins.dijit.InputDialog");
dojo.require("plugins.dijit.InteractiveDialog");
dojo.require("plugins.dijit.ConfirmDialog");
dojo.require("plugins.form.UploadDialog");
dojo.require("dojo.io.iframe");

dojo.declare("plugins.files.FileMenu",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
		
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "files/templates/filemenu.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingApp STATE
addingApp : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "files/css/filemenu.css"),
	dojo.moduleUrl("dojox", "form/resources/FileInput.css")
],

// PARENT WIDGET
parentWidget : null,

// delay: Integer (thousandths of a second)
// Poll delay
delay : 6000,

/////}}
	
constructor : function(args) {
	//////console.log("FileMenu.constructor     plugins.files.FileMenu.constructor");			

	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	//////console.log("Controller.postCreate    plugins.files.Controller.postCreate()");

	// SET INPUT DIALOG
	this.setInputDialog();

	// SET INTERACTIVE DIALOG
	this.setInteractiveDialog();

	// SET CONFIRM DIALOG
	this.setConfirmDialog();

	// SET LABEL
	this.setTitle("File Menu");

	// CONNECT SHORTKEYS FOR MENU
	this.setMenu();

	// DO INHERITED STARTUP
	this.startup();
},
startup : function () {
	console.group("FileMenu    " + this.id + "    startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// SET THE UPLOAD OBJECT
	this.setUploader();

	// DISABLE MENU ITEMS
	this.disableMenuItem('select');
	this.disableMenuItem('add');
	this.menu._started = false;
	this.menu.startup();

	// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.menu.domNode, "oncontextmenu", function (event) {
		event.stopPropagation();
	});

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateProjects");
	Agua.updater.subscribe(this, "updateWorkflows");	

	console.groupEnd("FileMenu    " + this.id + "    startup");
},
updateProjects : function (args) {
// RELOAD RELEVANT DISPLAYS
	////console.log("workflow.Stages.updateProjects    workflow.Stages.updateProjects(args)");
	////console.log("workflow.Stages.updateProjects    args:");
	////console.dir(args);

	this.parentWidget.updateProjects();
},
updateClusters : function (args) {
// RELOAD RELEVANT DISPLAYS
	////console.log("admin.Clusters.updateClusters    admin.Clusters.updateClusters(args)");
	////console.log("admin.Clusters.updateClusters    args:");
	////console.dir(args);
	this.setClusterCombo();
},
// SELECT
select : function (event) {
// STORE SELECTED FILE OR FOLDER
    //console.log("FileMenu.select    plugins.files.FileSelectorMenu.select(event)");

    //console.log("FileMenu.select    event: " + event);
    //console.log("FileMenu.select    event.target: " + event.target);

    // GET PROJECT WIDGET
    var location = this.getPath();
    if ( ! location == null ) {
        //console.log("FileMenu.select     location is null. Returning");
        return;
    }
    var filename = this.menu.currentTarget.innerHTML;

    //console.log("FileMenu.select     filename: " + filename);
    //console.log("FileMenu.select     location: " + location);
    //console.log("FileMenu.select     this.type: " + this.type);
    
    var newValue;
    if ( filename != null && location != null )    newValue = location + "/" + filename;
    else if ( location != null )    newValue = location;
    else if ( filename != null )    newValue = filename;
    //console.log("FileMenu.select     newValue: " + newValue);

    var application = this.parameterWidget.core.parameters.application;
    application.value = newValue;
    //console.log("FileMenu.select     application: ");
    //console.dir({application:application});
    
    //console.log("FileMenu.select     Doing this.parameterWidget.changeValue()");
    this.parameterWidget.changeValue(this.parameterWidget.valueNode, this.parameterWidget.valueNode.innerHTML, newValue, this.type);

    //console.log("FileMenu.select     Doing this.parameterWidget.core.io.chainOutputs()");
    var force = true;
    this.parameterWidget.core.io.chainOutputs(application, true);
    var stageRow = this.parameterWidget.core.parameters.stageRow;
    var node = stageRow.domNode;
    node.application = stageRow.application;
    node.parentWidget = stageRow;
    this.parameterWidget.core.stages.loadParametersPane(node);


    this.hide();
},
// ADD
add : function () {
// ADD VALUE TO PARAMETER
    var location = this.getPath();
    if ( location == null ) {
        //console.log("FileMenu.add     location is null. Returning");
        return;
    }

    var filename = this.menu.currentTarget.innerHTML;
    //console.log("FileMenu.add     filename: " + filename);
    //console.log("FileMenu.add     location: " + location);
    //console.log("FileMenu.add     this.type: " + this.type);
    //console.log("FileMenu.add     this.parameterWidget.valueNode.innerHTML: " + this.parameterWidget.valueNode.innerHTML);

    var newValue;
    if ( filename != null && location != null )    newValue = location + "/" + filename;
    else if ( location != null )    newValue = location;
    else if ( filename != null )    newValue = filename;
    //console.log("FileMenu.add     newValue: " + newValue);

    this.parameterWidget.addValue(this.parameterWidget.valueNode,   this.parameterWidget.valueNode.innerHTML, newValue, this.type);

    this.hide();
},
// UPLOAD
upload : function (event) {
	//console.log("FileMenu.upload     this.menu.currentTarget: " + this.menu.currentTarget);
	//console.dir({currentTarget:this.menu.currentTarget});

	//console.log("FileMenu.upload     Doing dojo.stopEvent(event)");
	dojo.stopEvent(event);	

	// SET UPLOADER PATH AND SHOW
	var item = this.menu.currentTarget.item;
	//console.log("FileMenu.upload     item: ");
	//console.dir({item:item});
	var path = item.parentPath;
	//console.log("FileMenu.upload     path: " + path);
	if ( ! path )	return;
	this.uploader.setPath(path);
	this.uploader.show();

	// SET RELOAD CALLBACK
	var parentFolder = path.match('([^\/]+)$')[1];
	//console.log("parentFolder: " + parentFolder);
	
	var dragPane = dijit.getEnclosingWidget(this.menu.currentTarget.offsetParent);
	//console.log("fileMenu.upload    dragPane: " + dragPane);

	this.callback = dojo.hitch(this, "reloadPane", dragPane, parentFolder);
},
onComplete : function() {
	//console.log("fileMenu.onComplete    this.callback: " + this.callback);
    this.callback();
},
reloadPane : function(dragPane, folder) {
// USE FAKE event TO RELOAD DIRECTORY
	//console.log("fileMenu.reloadPane    dragPane: ");
	//console.dir({dragPane:dragPane});
	//console.log("fileMenu.reloadPane    folder: " + folder);
	
	// SET FAKE EVENT
	var fileDrag = dragPane.parentWidget;
	//console.log("fileMenu.reloadPane    fileDrag: ");
	//console.dir({fileDrag:fileDrag});

	var index = 0;
	var items = dragPane.items;
	for ( var i = 0; i < items.length; i++ ) {
		if ( items[i].name == folder ) {
			index = i;
			break;
		}
	}
	//console.log("fileMenu.reloadPane    index: " + index);
	var event = { target: { item: items[index] } };

	// RESET putData
	fileDrag.store.putData.query 	= 	dragPane.path;
	fileDrag.store.putData.mode		=	"fileSystem";
	fileDrag.store.putData.module 	= 	"Folders";
	
	dragPane.onclickHandler(event);
},
setUploader : function () {
	//console.log("FileMenu.setUploader     plugins.files.FileMenu.setUploader()");
	var uploaderId = dijit.getUniqueId("plugins.form.UploadDialog");
	var username = Agua.cookie('username');
	var sessionid = Agua.cookie('sessionid');
	this.uploader = new plugins.form.UploadDialog(
	{
		uploaderId	: uploaderId,
		username	: 	username,
		sessionid	: 	sessionid,
		url			:	Agua.cgiUrl + "upload.cgi"
	});
	
	// SET CONNECT
	dojo.connect(this.uploader, "onComplete", this, "onComplete");
},	//	setUploader
setMenu : function () {
// CONNECT SHORTKEYS FOR MENU
	//////console.log("FileMenu.setMenu     plugins.files.Workflow.setMenu()");

	this.disableRightClick();
	
	this.setShortKeys();
	
	this.menu.onCancel = function(event) {
		////console.log("FileMenu.setMenu     DOING this.menu.onCancel(event)");
	}
},
disableRightClick : function () {
	//// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.menu.domNode, "contextmenu", function (event)
	{
		////console.log("FileMenu.setMenu    quenching contextmenu");
		event.preventDefault();
		event.stopPropagation();
		return false;
	});
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
				case "n" : this.newFolder(); break;
				case "m" : this.rename(); break;
				case "l" : this.deleteFile(); break;
				case "o" : this.openWorkflow(); break;
				case "u" : this.upload(); break;
				case "w" : this.download(); break;
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
// OPEN WORKFLOW
openWorkflow : function () {
	//console.log("FileMenu.openWorkflow     plugins.files.FileMenu.openWorkflow()");

	// LABEL THIS AS SELECTED FILE
	dojo.addClass(this.menu.currentTarget, 'dojoDndItemOver');
	
	var item = this.menu.currentTarget.item;
	//console.log("FileMenu.openWorkflow     item: " + dojo.toJson(item));
	if ( ! item.parentPath.match(/^([^\/]+)\/([^\/]+)/) )	return;
	var project = item.parentPath.match(/^([^\/]+)\/[^\/]+/)[1];	
	var workflow = item.parentPath.match(/^[^\/]+\/([^\/]+)/)[1];	
	//console.log("FileMenu.openWorkflow     project: " + project);
	//console.log("FileMenu.openWorkflow     workflow: " + workflow);
	var workflowController = Agua.controllers["workflow"];
	//console.log("FileMenu.openWorkflow     workflowController: " + workflowController);
	if ( workflowController == null )	return;
	//console.log("FileMenu.openWorkflow     Doing workflowController.createTab({ project: " + project + ", workflow: " + workflow + "})");
	workflowController.createTab({ project: project, workflow: workflow });
},
// RENAME
rename : function () {
// RENAME FILE OR FOLDER
	// GET INPUTS
	var username		= this.getUserName();
	var dragPane  		= this.getDragPane();
	var dndItem 		= this.menu.currentTarget;
	var item 			= this.menu.currentTarget.item;
	var path 			= item.path;
	var oldFileName		= item.path;
	var parentPath 		= item.parentPath;
	var interactiveDialog = this.interactiveDialog;

	// SET TITLE AND MESSAGE
	var title = "Rename file '" + oldFileName + "'";
	var message = "Please enter new name";
	
	// CALLBACKS
	var cancelCallback = function () {};
	var enterCallback = dojo.hitch(this, function (newFileName)
		{
			// SANITY CHECK
			if ( newFileName == null )	return;
			newFileName = newFileName.replace(/\s+/, '');
			if ( newFileName == '' )	return;
			//console.log("FileMenu.rename    newFileName: " + newFileName);

			// CHECK IF NAME EXISTS ALREADY
			if ( dragPane.inItems(newFileName) ) {
				Agua.toastMessage({message: "FileName '" + newFileName + "' already exists " });
				interactiveDialog.dialog.duration = 1500;
				interactiveDialog.messageNode.innerHTML = "Workflow already exists";
				return;
			}

			// RENAME FILECACHE 
			//console.log("FileMenu.renameWorkflow    Doing Agua.renameFileTree()");
			var newFilePath 	= parentPath + "/" + newFileName;
			var oldFilePath 	= parentPath + "/" + path;
			Agua.renameFileTree(username, oldFilePath, newFilePath);

			// RENAME DND ITEM
			//console.log("FileMenu.renameWorkflow    Doing dragPane.renameItem(dndItem, newFileName))");
			dragPane.renameItem(dndItem, newFileName);

			// CHANGE FILE ON SERVER
			Agua.renameFile(oldFilePath, newFilePath);
		}
	);		

	// SHOW THE DIALOG
	this.loadInputDialog(title, message, enterCallback, cancelCallback);
},
// NEW FOLDER
newFolder : function () {
// CREATE A NEW FOLDER
	// GET INPUTS
	var username = this.getUserName();
	var dragPane = this.getDragPane();
	//console.log("FileMenu.newFolder    location: " + location);

	// SET TITLE AND MESSAGE
	var title = "New Folder";
	var message = "Please enter folder name";
	
	// CALLBACKS
	var cancelCallback = function (){};
	var enterCallback = dojo.hitch(this, function (newFolderName)
		{
			// SANITY CHECK
			if ( newFolderName == null )	return;
			newFolderName = newFolderName.replace(/\s+/, '');
			if ( newFolderName == '' )	return;

			// CHECK IF NAME EXISTS ALREADY
			if ( dragPane.inItems(newFolderName) ) {
				//console.log("FileMenu.newFolder    File '" + newFolderName + "' already exists. Returning");
				return;
			}

			// ADD ITEM TO DRAGPANE AND SET FILECACHE
			var location = dragPane.path + "/" + newFolderName;
			dragPane.addItem(newFolderName, "folder", username, location);

			// CREATE FOLDER ON SERVER	
			var url 		= 	Agua.cgiUrl + "agua.cgi?";
			var folderPath 	= 	dragPane.path + "/" + newFolderName;
			var query 		= 	new Object;
			query.mode		=	"newFolder";
			query.module = "Agua::Folders";
			query.sessionid	=	Agua.cookie('sessionid');
			query.username	=	Agua.cookie('username');
			query.folderpath=	folderPath;
			
			var thisObject = this;
			dojo.xhrPut(
				{
					url			: 	url,
					putData		:	dojo.toJson(query),
					handleAs	: 	"json",
					sync		: 	false,
					handle		: 	function(response) {
						if ( response.error ) {
							Agua.error(response.error);
						}
						else if ( response.status ) {
							// status: initiated, ongoing, completed
							Agua.warning(response.status);
							var parentNode = thisObject.menu.currentTarget.parentNode;
							parentNode.removeChild(thisObject.menu.currentTarget);
						}
					}
				}
			);
		}
	);		

	// SHOW THE DIALOG
	this.loadInputDialog(title, message, enterCallback, cancelCallback);
},
// DELETE
deleteFile : function () {
	console.log("FileMenu.deleteFile     plugins.files.Workflow.deleteFile(event)");
	if ( this.menu.currentTarget == null )	return;

	// GET THE PROJECT WIDGET
	var filename = this.menu.currentTarget.item.name;
	////console.log("FileMenu.deleteFile     filename: " + filename);

	var isDirectory = this.menu.currentTarget.item.directory;
	////console.log("FileMenu.deleteFile     isDirectory: " + isDirectory);
	var type = "file";
	if ( isDirectory == true )	type = "folder";

	var dragPane = dijit.getEnclosingWidget(this.menu.currentTarget);
	//////console.log("FileMenu.newFolder     dragPane: " + dragPane);
	//console.log("FileMenu.deleteFile    Doing dragPane.standby.show()");
	dragPane.standby.show();

	// CALLBACKS
	var noCallback = function (){
		//console.log("FileMenu.deleteFile    noCallback()");
		//console.log("FileMenu.deleteFile    Doing dragPane.standby.hide()");
		dragPane.standby.hide();
	};
	var yesCallback = dojo.hitch(this, function ()
		{
			////console.log("FileMenu.newFolder    Doing enterCallback");
			//dragPane._dragSource.deleteSelectedNodes();

			var item = this.menu.currentTarget.item;
			var file = item.parentPath + "/" + item.path;
			
			var url = Agua.cgiUrl + "agua.cgi?";
			var putData 		= 	new Object;
			putData.mode		=	"removeFile";
			putData.module		=	"Folders";
			putData.sessionid	=	Agua.cookie('sessionid');
			putData.username	=	Agua.cookie('username');
			putData.file		=	file;
	
			var thisObject = this;
			dojo.xhrPut(
				{
					url			: 	url,
					putData		:	dojo.toJson(putData),
					handleAs	: 	"json",
					sync		: 	false,
					handle		: 	function(response) {
						if ( response.error ) {
							//console.log("FileMenu.deleteFile    xhrPut response. Doing dragPane.standby.hide()");
							dragPane.standby.hide();

							Agua.error(response.error);
						}
						else if ( response.status ) {
							thisObject.pollDelete(putData, dragPane);
						}
					}
				}
			);
		}
	);

	// SET TITLE AND MESSAGE
	var title = "Delete " + type + ":<br>" + filename;
	var message = "All its data will be destroyed";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);
	
},	//	deleteFile
delayedPollDelete : function (putData, dragPane) {
	//console.log("FileMenu.delayedPollDelete    Doing this.sequence.go(commands, ...)");
	var delay = this.delay;
	var commands = [
		{ func: [this.showMessage, this, "FileMenu.delayedPollDelete"], pauseAfter: delay },
		{ func: [this.pollDelete, this, putData, dragPane ] } 
	];
	//console.log("FileMenu.delayedPollDelete    commands: ");
	//console.dir({commands:commands});
	
	this.sequence.go(commands, function(){ });	
},
pollDelete : function(putData, dragPane) {
// POLL SERVER UNTIL status == 'completed'
	//console.log("FileMenu.pollDelete    putData: ");
	//console.dir({putData:putData});
	//console.log("FileMenu.pollDelete    dragPane: ");
	//console.dir({dragPane:dragPane});
	
	putData.modifier = "status";
	var url = Agua.cgiUrl + "agua.cgi?";

	var thisObject = this;
	dojo.xhrPut({
		url			: 	url,
		handleAs	: 	"json-comment-optional",
		sync		: 	false,
		putData		:	dojo.toJson(putData),
		handle		: 	function (response) {
			//console.log("FileMenu.pollDelete    this.response: ");
			//console.dir({response:response});
			
			// status: initiated, ongoing, completed
			if ( response.status == 'completed' ) {
				thisObject.handleDelete(putData, dragPane, response);
			}
			else if ( response.error ) {
				thisObject.standby.hide();
			}
			else
				thisObject.delayedPollDelete(putData, dragPane);
		}
	});
},
handleDelete : function (putData, dragPane, response) {
	//console.log("FileMenu.handleDelete    putData: ");
	//console.dir({putData:putData});
	//console.log("FileMenu.handleDelete    dragPane: ");
	//console.dir({dragPane:dragPane});
	//console.log("FileMenu.handleDelete    response: ");
	//console.dir({response:response});

	// HIDE STANDBY
	dragPane.standby.hide();
	
	// DELETE EXISTING FILECACHE
	var location = putData.file;
	var folder = location.match(/^(.+?)\/[^\/]+$/)[1];
	//console.log("FileMenu.handleDelete    folder: " + folder);
	Agua.setFileCache(putData.username, location, null);
	Agua.setFileCache(putData.username, folder, null);

	// RELOAD DRAGPANE
	var path = dragPane.path;
	var folder = path.match(/([^\/]+)$/)[1];
	//console.log("FileMenu.handleDelete    folder: " + folder);
	var previousPane = dragPane.getPreviousPane();
	//console.log("FileMenu.handleDelete    previousPane: ");
	//console.dir({previousPane:previousPane});
	
	this.reloadPane(previousPane, folder);	
},
// DOWNLOAD
download : function () {
// DOWNLOAD FILE FROM FOLDER
	////console.log("FileMenu.download     plugins.files.Workflow.download()");

	var item = this.menu.currentTarget.item;
	////console.log("FileMenu.download     item: " + dojo.toJson(item));

	if ( ! item.parentPath.match(/^([^\/]+)\/([^\/]+)/) )	return;
	var project = item.parentPath.match(/^([^\/]+)\/[^\/]+/)[1];	
	var workflow = item.parentPath.match(/^[^\/]+\/([^\/]+)/)[1];	
	////console.log("FileMenu.download     project: " + project);
	////console.log("FileMenu.download     workflow: " + workflow);

	var filepath = item.parentPath;
	if ( item.path != null && item.path != '' )
		filepath += "/" + item.path;
	////console.log("FileMenu.download     filepath: " + filepath);
	
	var url = item._S.url;
	var owner;
	if ( url.match(/owner=([^&]+)/) )
	{
		owner = url.match(/owner=([^&]+)/)[1];	
	}
	////console.log("FileMenu.download     owner: " + owner);

	var query = "?mode=downloadFile";

	// SET requestor = THIS_USER IF core.parameters.shared IS TRUE
	if ( owner != null )
	{
		query += "&username=" + owner;
		query += "&requestor=" + Agua.cookie('username');
	}
	else
	{
		query += "&username=" + Agua.cookie('username');
	}

	query += "&sessionid=" + Agua.cookie('sessionid');
	query += "&filepath=" + filepath;
	////console.log("FileMenu.download     query: " + query);
	
	var downloadUrl = Agua.cgiUrl + "download.cgi";
	////////console.log("FileMenu.download     url: " + url);
	
	var args = {
		method: "GET",
		url: downloadUrl + query,
		handleAs: "json",
		timeout: 10000,
		load: this.handleDownload
	};
	////////console.log("FileMenu.download     args: ", args);

	// do an IFrame request to download the csv file.
	////console.log("FileMenu.download     Doing dojo.io.iframe.send(args))");
	var value = dojo.io.iframe.send(args);
	////console.log("FileMenu.download     value: " + dojo.toJson(value));

},
handleDownload : function (response, ioArgs) {
	////console.log("ParameterRow.handleDownload     plugins.workflow.ParameterRow.handleDownload(response, ioArgs)");
	////console.log("ParameterRow.handleDownload     response: " + dojo.toJson(response));
	////console.log("ParameterRow.handleDownload     response.message: " + response.message);

	if ( response.message == "ifd.getElementsByTagName(\"textarea\")[0] is undefined" )
	{
		Agua.toastMessage({
			message: "Download failed: File is not present",
			type: "error"
		});
	}	
},
openFileDownload : function (filepath) {
	////console.log("FileMenu.openFileDownload     plugins.files.FileMenu.openFileDownload(filepath)");
	////console.log("FileMenu.openFileDownload     filepath: " + filepath);
	
	var query = "?username=" + Agua.cookie('username');
	query += "&sessionid=" + Agua.cookie('sessionid');
	query += "&filepath=" + filepath;
	
	var url = Agua.cgiUrl + "download.cgi";	
	var args = {
		method: "GET",
		url: url + query,
		//content: {},
		handleAs: "html",
		timeout: 10000
		//load: dojo.hitch(this, "onDownloadComplete"),
		//error: dojo.hitch(this, "onDownloadError")
	};
	// do an IFrame request to download the csv file.
	////console.log("FileMenu.openFileDownload    Doing dojo.io.iframe.send(args))");
	dojo.io.iframe.send(args);
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
	////console.log("FileMenu.loadConfirmDialog    plugins.files.FileMenu.loadConfirmDialog()");
	////console.log("FileMenu.loadConfirmDialog    yesCallback.toString(): " + yesCallback.toString());
	////console.log("FileMenu.loadConfirmDialog    title: " + title);
	////console.log("FileMenu.loadConfirmDialog    message: " + message);
	////console.log("FileMenu.loadConfirmDialog    yesCallback: " + yesCallback);
	////console.log("FileMenu.loadConfirmDialog    noCallback: " + noCallback);

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
	////console.log("FileMenu.loadInputDialog    plugins.files.FileMenu.loadInputDialog()");
	////console.log("FileMenu.loadInputDialog    enterCallback.toString(): " + enterCallback.toString());
	////console.log("FileMenu.loadInputDialog    title: " + title);
	////console.log("FileMenu.loadInputDialog    message: " + message);
	////console.log("FileMenu.loadInputDialog    enterCallback: " + enterCallback);
	////console.log("FileMenu.loadInputDialog    cancelCallback: " + cancelCallback);

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
	
	////console.log("FileMenu.setInteractiveDialog    plugins.files.FileMenu.setInteractiveDialog()");
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
	////console.log("FileMenu.setInteractiveDialog    this.interactiveDialog: " + this.interactiveDialog);
},
loadInteractiveDialog : function (title, message, enterCallback, cancelCallback, checkboxMessage) {
	////console.log("FileMenu.loadInteractiveDialog    plugins.files.FileMenu.loadInteractiveDialog()");
	////console.log("FileMenu.loadInteractiveDialog    enterCallback.toString(): " + enterCallback.toString());
	////console.log("FileMenu.loadInteractiveDialog    title: " + title);
	////console.log("FileMenu.loadInteractiveDialog    message: " + message);
	////console.log("FileMenu.loadInteractiveDialog    enterCallback: " + enterCallback);
	////console.log("FileMenu.loadInteractiveDialog    cancelCallback: " + cancelCallback);

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
	////console.log("FileMenu.bind     plugins.files.FileMenu.bind(node)");
	if ( node == null )
		////console.log("FileMenu.bind     node is null. Returning...");

	return this.menu.bindDomNode(node);	
},
getPath : function () {
// RETURN THE FILE PATH OF THE FOCUSED GROUP DRAG PANE
	////console.log("FileMenu.getPath     plugins.files.FileMenu.getPath()");
	////console.log("FileMenu.setUploader     this.menu.currentTarget: " + this.menu.currentTarget);
	var groupDragPane = dijit.getEnclosingWidget(this.menu.currentTarget);
	////console.log("FileMenu.setUploader     groupDragPane: " + groupDragPane);

	if ( groupDragPane == null || ! groupDragPane )	return;
	////console.log("FileMenu.setUploader     Returning path: " + groupDragPane.path);

	return groupDragPane.path;
},
hide : function () {
	////console.log("FileMenu.hide    this.parentWidget: " + this.parentWidget);
	this.parentWidget.hide();
},
setTitle : function (title) {
// SET THE MENU TITLE
	//console.log("FileMenu.setTitle    title: " + title);
	this.titleNode.containerNode.innerHTML = title;
},
show : function () {
	////console.log("FileMenu.show    files.FileMenu.show()");
	
	//console.log("FileMenu.show    this.menu.currentTarget: " + this.menu.currentTarget);
	//console.dir({currentTarget:this.menu.currentTarget});
	dojo.addClass(this.menu.currentTarget, 'dojoDndItemOver');

	dojo.style(this.containerNode, {
		opacity: 1,
		overflow: "visible"
	});
},
disableMenuItem : function (name) {
	//console.log("FileMenu.disableMenuItem    name: " + name);

	if ( this[name + "Node"] )
		this[name + "Node"].disabled = true;
    var item = this[name + "Node"];
	dojo.addClass(item.domNode, "dijitMenuItemDisabled");
},
enableMenuItem : function (name) {
	//console.log("FileMenu.enableMenuItem    name: " + name);
	if ( this[name + "Node"] )
		this[name + "Node"].disabled = false;
    var item = this[name + "Node"];
	dojo.removeClass(item.domNode, "dijitMenuItemDisabled");
},
disable : function () {
	////console.log("FileMenu.disable    files.FileMenu.disable()");
	this.menu.enabled = false;
},
enable : function () {
	////console.log("FileMenu.enable    files.FileMenu.enable()");
	this.menu.enabled = true;
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
refresh : function (event) {
	//console.log("FileMenu.refresh    DO NOTHING");
},
// UTILITIES
getFilesWidget : function () {
// RETURN THE PROJECT TAB WIDGET CONTAINING THIS FILE DRAG OBJECT
	if ( this.menu.currentTarget == null )	return null;

	// GET THE PROJECT WIDGET
	var item = this.menu.currentTarget.item;
	var widget = dijit.getEnclosingWidget(this.menu.currentTarget);
	var filesWidget = widget.parentWidget.parentWidget;
	//console.log("WorkflowMenu.getFilesWidget     filesWidget: " + filesWidget);

	return filesWidget;
},
getProjectName : function () {
// RETURN THE PROJECT NAME FOR THIS FILE DRAG OBJECT
	
	// SANITY		
	if ( this.menu.currentTarget == null )	return null;

	// GET THE PROJECT WIDGET
	var item = this.menu.currentTarget.item;
	//////////console.log("WorkflowMenu.newFolder     this.menu.currentTarget: " + this.menu.currentTarget);
	//////////console.log("WorkflowMenu.newFolder     item: " + item);
	var widget = dijit.getEnclosingWidget(this.menu.currentTarget);
	var projectName = widget.path;

	return projectName;
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

}); // plugins.files.FileMenu
