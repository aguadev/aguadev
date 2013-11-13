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

// GLOBAL VARIABLES
var Agua;
var Data;
var data;
var folders;
var projectFiles;

dojo.addOnLoad(function(){

Agua = new plugins.core.Agua({
	cgiUrl 		: 	dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
	, dataUrl	:	"getData.aguatest.120525.json"	
});

Agua.cookie('username', 'aguatest');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.folders.Controller"
]);

// CREATE TAB
Agua.controllers["folders"].createTab();

doh.register("t.plugins.folders.filedrag.test",
[	
	{
		name: "fileDrag",
		runTest: function(){

			projectFiles = Agua.controllers["folders"].tabPanes[0].projectFiles;
			console.log("copyFile    projectFiles: ");
			console.dir({projectFiles:projectFiles});

			
			// SET DEFERRED OBJECT
			var deferred = new doh.Deferred();
			
			// OPEN DIRECTORIES AUTOMATICALLY
			setTimeout(function() {
				try {
					console.log("copyFile    Doing timeout groupDragPane.onclickHandler(event)");
					var fileDrag1 = projectFiles.fileDrags[0];
					console.log("fileDrag1 not null: " + doh.assertFalse(fileDrag1 == null));
					console.log("fileDrag1.getChildren().length == 1: " + doh.assertEqual(fileDrag1.getChildren().length, 1));
					var groupDragPane1 = fileDrag1.getChildren()[0];
					var item = groupDragPane1.items[0];
					var event = { target: { item: item } };
					groupDragPane1.onclickHandler(event);
					console.log("fileDrag1.getChildren().length == 2: " + doh.assertEqual(fileDrag1.getChildren().length, 2));

					var fileDrag2 = projectFiles.fileDrags[1];
					console.log("fileDrag2 not null: " + doh.assertFalse(fileDrag2 == null));
					console.log("fileDrag2.getChildren().length == 1: " + doh.assertEqual(fileDrag2.getChildren().length, 1));
					var groupDragPane2 = fileDrag2.getChildren()[0];
					var item = groupDragPane2.items[0];
					var event = { target: { item: item } };

					// OPEN DIRECTORIES AUTOMATICALLY
					groupDragPane2.onclickHandler(event);
					console.log("fileDrag2.getChildren().length == 2: " + doh.assertEqual(fileDrag2.getChildren().length, 2));
	
				} catch(e) {
				  deferred.errback(e);
				}
			}, 15000);

			// FAKE DRAG DROP
			setTimeout(function() {
				try {
					console.log("copyFile    Doing timeout    dragSource.onDropExternal(source, nodes, copy)");
					var fileDrag1 = projectFiles.fileDrags[0];
					var groupDragPane3 = fileDrag1.getChildren()[1];
					console.log("groupDragPane3 " + groupDragPane3); 
					var dragSource1 = groupDragPane3._dragSource;
					
					var fileDrag2 = projectFiles.fileDrags[1];
					var groupDragPane4 = fileDrag2.getChildren()[1];
					console.log("groupDragPane4 " + groupDragPane4); 
					var dragSource2 = groupDragPane4._dragSource;
					console.log("dragSource2: " + dragSource2);
					var dndItem = dragSource2.node.childNodes[6];
					console.log("dndItem: " + dndItem);
					
					dragSource1.onDropExternal(dragSource2, [dndItem], true);

					deferred.callback(true);		

				} catch(e) {
					deferred.errback(e);
				}
			}, 30000);

			return deferred;
		},	
		timeout: 45000 
	}

]);	// doh.register

//Execute D.O.H. in this remote file.
doh.run();



}); // dojo.addOnLoad

