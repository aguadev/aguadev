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

// DEBUG LOADER
//dojo.require("dojoc.util.loader");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.files.FileManager");
dojo.require("plugins.workflow.Parameters");

// GLOBAL VARIABLES
var Agua;
var data;
var parameterWidget;
var fileManager;

dojo.addOnLoad(function(){

Agua = new plugins.core.Agua({
	cgiUrl : dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
	, database	:	"aguatest"
	, dataUrl: "getData-110711.json"
});
Agua.cookie('username', 'testuser');
Agua.cookie('sessionid', '9999999999.9999.999');

Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.files.Controller"
]);

var setParameters = function () {
// SET DATA TAB IN INFO PANE BY INSTANTIATING Parameters OBJECT
	////console.log("Workflow.setParameters    plugins.workflow.Stages.setParameters()");

		return new plugins.workflow.Parameters(
		{
			attachNode : Agua.tabs,
			parentWidget: null,
			core: null
		});
	//}
};
parameterWidget = setParameters();
parameterWidget.project = "Project1";
parameterWidget.workflow = "Workflow1";

setFileManager = function() {

/* OPEN FILE MANAGER TO ALLOW SELECTION OF FILE AS ARGUMENT VALUE	
	NB: PASS THE callback ON THROUGH FileManager, FileSelector AND _GroupSelectorPane.
	SEE END OF DOCUMENT FOR DETAILS. */
	console.log("setFileManager     setFileManager()");
	
	// SET SELECT CALLBACK
	var selectCallback = dojo.hitch(this, function(file, location, type, parameterWidget)
	{
		console.log("setFileManager     Doing selectCallback(file, location, type, parameterWidget)");
		console.log("setFileManager     file: " + file);
		console.log("setFileManager     location: " + location);
		console.log("setFileManager     type: " + type);
		console.log("setFileManager     parameterWidget: " + parameterWidget);
		console.dir(parameterWidget);
		
		var newValue;
		if ( file != null && location != null )	newValue = location + "/" + file;
		else if ( location != null )	newValue = location;
		else if ( file != null )	newValue = file;
		console.log("setFileManager     newValue: " + newValue);
		
		parameterWidget.changeValue(parameterWidget.valueNode, parameterWidget.valueNode.innerHTML, newValue, type);
	});

	// SET SELECT CALLBACK
	var addCallback = dojo.hitch(this, function(file, location, type)
	{
		console.log("setFileManager     Doing addCallback(file, location, type, parameterWidget)");
		console.log("setFileManager     file: " + file);
		console.log("setFileManager     location: " + location);
		console.log("setFileManager     type: " + type);
		console.log("setFileManager     Agua.fileManagerNode: " + Agua.fileManagerNode);
		console.log("setFileManager     this.valueNode.innerHTML: " + this.valueNode.innerHTML);

		var newValue;
		if ( file != null && location != null )	newValue = location + "/" + file;
		else if ( location != null )	newValue = location;
		else if ( file != null )	newValue = file;
		console.log("setFileManager     newValue: " + newValue);

		parameterWidget.addValue(parameterWidget.valueNode, parameterWidget.valueNode.innerHTML, newValue, type);
	});

	console.log("setFileManager    Doing this.fileManager = new plugins.files.FileManager(...)");

	Agua.fileManager.selectCallback 	=  selectCallback;
	Agua.fileManager.addCallback		=	addCallback;

	return Agua.fileManager;	
};


fileManager = setFileManager();


fileManager.parameterWidget = parameterWidget;
console.log("BEFORE fileManager.show(parameterWidget)");
fileManager.show(parameterWidget);

//console.clear();
//console.log("After console.clear()");

//Agua = new plugins.core.Agua( {
//	cgiUrl : dojo.moduleUrl("plugins", "../../../cgi-bin/agua/"),
//	database: "aguatest",
//	testing: true,
//	dataUrl: dojo.moduleUrl("t", "json/getData.json")
//});
//console.log("agua.html    AFTER new plugins.core.Agua");

//console.log("agua.html    BEFORE Agua.loadPlugins");
//Agua.loadPlugins();
//console.log("agua.html    AFTER Agua.loadPlugins");

//var runStatus = new plugins.workflow.RunStatus({
//	attachNode: Agua.tabs
//});

//	runStatus.stageStatus = new plugins.workflow.StageStatus({
//        attachNode: runStatus.stagesStatusContainer
//    });

//console.clear();
//console.log("After console.clear()");



//var workflow = Agua.widgets["workflow"][0];
//var filemanager = workflow.core.fileManager;
//var dialog = filemanager.fileManagerDialog;



//var fileDrag = projectFiles.projectFileDrags[1];
//var children = fileDrag.getChildren();
//
//console.log("children.length: " + children.length);
//
//for ( var i = 0; i < children.length; i++ )
//{
//    console.log("child " + i + ":" + children[i]);
//}
//
//var groupDragPane = children[0];
//
//var item = groupDragPane.items[0];
//console.dir(item);
//
//////fileDrag._getPaneForItem(item, groupDragPane, item.children);
//
//fileDrag._onItemClick(null, groupDragPane, item, item.children);
//var event = { target: { item: item }};
//console.log("event: " + event);
//
//console.log("BEFORE fileDrag.getChildren().length: " + fileDrag.getChildren().length);
//
//groupDragPane.onclickHandler(event);
//console.log("AFTER fileDrag.getChildren().length: " + fileDrag.getChildren().length);


}); // FIRST dojo.addOnLoad
