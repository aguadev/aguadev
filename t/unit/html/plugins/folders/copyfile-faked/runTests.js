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
dojo.require("plugins.folders.Folders");
dojo.require("plugins.folders.ProjectFiles");

var Agua;
var Data;
var data;
var folders;
var projectFiles;

dojo.addOnLoad(function(){

Agua = new plugins.core.Agua({
	cgiUrl 		:	dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
	, database	:	"aguatest"
	, dataUrl	:	"getData.aguatest.120525.json"	
	//dataUrl    :dojo.moduleUrl("t", "json/getData.aguatest.120514.json")
});
Agua.cookie('username', 'testuser');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.database = "aguatest";
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.folders.Controller"
]);

doh.register("t.plugins.folders.copyfile.test", [{
	timeout: 45000,
	name: "copyFile",
	runTest: function() {
	
// SET DEFERRED OBJECT
var deferred = new doh.Deferred();

var file 		= 	"Project2/test/test.out";
var filedir		=	"Project2/test";
var destination = 	"Project1/Workflow1";
var username 	= 	"testuser";
var projectName = 	"Project1";
var destinationfile	=	"Project/Workflow1/test.sh";

// SET folders
var folders 	=	Agua.controllers["folders"].tabPanes[0];

// SET AGUA CGI
Agua.getFoldersUrl = function () {
	//return "../../../../cgi-bin/t/test.cgi";
	return "../../../../cgi-bin/folders.cgi";
};

// CREATE TAB
setTimeout(function() {
	try {
		folders = Agua.controllers["folders"];
		console.log("runTests    ************************ CREATE TAB ************************ folders:");
		console.dir({folders:folders});

		Agua.controllers["folders"].createTab();
		
	} catch(e) {
	  deferred.errback(e);
	}
}, 3000);



// OPEN DIRECTORIES AUTOMATICALLY
setTimeout(function() {
	try {

		console.log("runTests    ************************ OPEN LOCATION ************************ DOING folders.projectFiles.openLocation(" + destination + "," + username + ")");

Agua.controllers["folders"].tabPanes[0].projectFiles.openLocation(destination, username);
Agua.controllers["folders"].tabPanes[0].projectFiles.openLocation(filedir, username);

	// CHECK NUMBER OF OPEN PANES
	
	// CHECK PATHS OF OPEN PANES

	} catch(e) {
	  deferred.errback(e);
	}
}, 5000);

// COPY FILE
setTimeout(function() {
	try {

		var folders = Agua.controllers["folders"].tabPanes[0];
		console.log("runTests    ************************ COPY FILE ************************ folders:");
		console.dir({folders:folders});
		
		var fileDrag = folders.projectFiles.getFileDragByProject(projectName);
		console.dir({fileDrag:fileDrag});
		var dragPanes = fileDrag.getChildren();
		console.log("copyFiles    dragPanes.length: " + dragPanes.length);
		console.dir({dragPanes:dragPanes});
		var dragPane = dragPanes[0];
		dragPane.url = "../cgi-bin/agua/folders.cgi";
		dragPane.putData = {
			mode        :   "copyFile",    
			sessionid   :   "9999999999.9999.999",
			url         :   "../cgi-bin/agua/folders.cgi?",
			username    :   "testuser",
			file        :   file,
			destination :   destination
		};    
		
		console.log("copyFile    Doing timeout    dragSource.onDropExternal(source, nodes, copy)");
		// DELETE DESTINATION FILE
		console.log("runTests.js    SET RESPONSE: 'status':'Initiated remove file'");
		folders.url = 	"../../../../cgi-bin/t/test.cgi?response={'status':'Initiated remove file'}&";


		// SET copyFile TARGET
		var targetFileDrag = folders.projectFiles.fileDrags[0];
		console.log("targetFileDrag: "); 
		console.dir({targetFileDrag:targetFileDrag});
		
		var targetDragPane = targetFileDrag.getChildren()[1];
		console.log("targetDragPane: " + targetDragPane); 
		console.dir({targetDragPane:targetDragPane});
		var targetDragSource = targetDragPane._dragSource;
		
		var sourceFileDrag = folders.projectFiles.fileDrags[1];
		console.log("sourceFileDrag: "); 
		console.dir({sourceFileDrag:sourceFileDrag});
		
		// SET COPY SOURCE
		var sourceDragPane = sourceFileDrag.getChildren()[1];
		console.log("sourceDragPane ");
		console.dir({sourceDragPane:sourceDragPane});
		
		var sourceDragSource = sourceDragPane._dragSource;
		console.log("sourceDragSource: ");
		console.dir({sourceDragSource:sourceDragSource});
		
		var dndItem = sourceDragSource.node.childNodes[0];
		console.log("dndItem: " );
		console.dir({dndItem:dndItem});
		
		var destinationFile = targetDragPane.path + "/" + dndItem.item.path;
		console.log("destinationFile: " + destinationFile);
		console.log("copyFile    Doing Agua.removeRemoteFile XXXXXXXXXXXXXXXXXXXXXXXXXXX");
		
		//var callback = function () {};
		//Agua.removeRemoteFile(username, destinationfile, callback);

		Agua.getFoldersUrl = function () {
			console.log("runTests.js    SET RESPONSE: 'status':'Initiated remove file'");
			return "../../../../../cgi-bin/agua/t/test.cgi?{'status':'Initiated remove file'}&";
		}
		
		Agua.removeRemoteFile(username, destinationFile, null);
		
		Agua.getFoldersUrl = function () {
			console.log("runTests.js    SET RESPONSE: 'status':'completed'");
			return "../../../../../cgi-bin/agua/t/test.cgi?{'status':'completed'}&";
		}

		// TESTS:
		// STANDBY HIDDEN
		// FILE NOT PRESENT
		
		
	//setTimeout(function() {
	//	console.log("copyFile    Doing targetDragSource.onDropExternal() XXXXXXXXXXXXXXXXXXXXXXXXXXX");
	//
	//	
	//	//Agua.getFoldersUrl = function () {
	//	//	return "t/test.cgi?{'status':'completed'}&";
	//	//}
	//
	//
	//
	//	targetDragSource.onDropExternal(sourceDragSource, [dndItem], true);
	//	// TESTS:
	//	// STANDBY HIDDEN
	//	// FILE EXISTS
	//	
	//	
	//}, 10000);
	
		deferred.callback(true);

	} catch(e) {
	  deferred.errback(e);
	}
}, 12000);

return deferred;



	}

}]);	// doh.register


	
//Execute D.O.H.
doh.run();


}); // dojo.addOnLoad


