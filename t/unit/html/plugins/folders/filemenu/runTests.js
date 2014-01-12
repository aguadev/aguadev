// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
dojo.require("dijit.dijit");
//dojo.require("dojox.robot.recorder");
//dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
//dojo.require("plugins.core.Agua");
//dojo.require("plugins.project.Project");
//dojo.require("plugins.project.ProjectFiles");
dojo.require("plugins.files.FileMenu")

var Agua;
var data;
var project;
var projectFiles;

var showMenu;
var fileMenu;

dojo.addOnLoad(function() {

	//Agua = new plugins.core.Agua({
	//	cgiUrl : dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
	//});
	//// GET DATA
	//data = t.doh.util.fetchJson(dojo.moduleUrl("t", "json/getData.json"));
	//Agua.projects = data.projects;


	// DUMMY Agua
	Agua = new Object;
	Agua.updater = new Object;
	Agua.updater.subscribe = function () {};
	Agua.getProjects = function() { return Agua.projects; }
	Agua.cookies = new Object;
	Agua.cookie = function (name, value) {
		if ( value != null )
			Agua.cookies[name] = value;
		else if ( name != null )
			return Agua.cookies[name];
		return 0;
	};	
	Agua.cgiUrl = "../../../../../../cgi-bin/agua/";
	Agua.cookie('username', 'testuser');
	Agua.cookie('sessionid', '9999999999.9999.999');
	Agua.error = function () { return false };
	Agua.warning = function () { return false };

	// ADD DUMMY FILE NODE DATA item
	dojo.byId("showmenu").item = {
		parentPath: "Project1/Workflow1/uploads",
		path: "oldFilename"
	};

	fileMenu = new plugins.files.FileMenu({
		type: "file",
		selectCallback: this.selectCallback,
		addCallback: this.addCallback
	});
	fileMenu.bind(dojo.byId("showmenu"));
	//filemenu.uploader.show();

	// RENAME - DISABLE inFiles FUNCTION
	fileMenu.inFiles = function () { return false };


	//var folderMenu = new plugins.files.FolderMenu({});
	//var workflowMenu = new plugins.files.WorkflowMenu({});
	//
	//project = new plugins.project.Project({
	//	attachWidget: dojo.byId("attachPoint")
	//	//attachWidget: Agua.tabs
	//});
	//
	//projectFiles = new plugins.project.ProjectFiles({
	//	open: true,
	//	title: 'Projects',
	//	type: 'Project',
	//	parentWidget : project,
	//	fileMenu: fileMenu,
	//	folderMenu: folderMenu,
	//	workflowMenu: workflowMenu,
	//	attachNode: project.projectsNode
	//});
	//



}); // dojo.addOnLoad

