// REGISTER MODULE PATHS
//dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
dojo.require("doh.runner");
//dojo.require("dojoc.util.loader");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua")

// GLOBAL Agua VARIABLE
var Agua;
var home;

dojo.addOnLoad(function(){

// SET UP
Agua = new plugins.core.Agua( {
	cgiUrl 		:	dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
	, database	: 	"aguatest"
	, dataUrl	: 	"test.json"
});
Agua.cookie('username', 'testuser');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.files.Controller",
	"plugins.home.Controller"
]);

// REMOVE EXISTING home TAB	
var oldHome = Agua.controllers["home"].tabPanes[0];
Agua.tabs.removeChild(oldHome.mainTab);

// CREATE NEW home TAB
home = Agua.controllers["home"].createTab();

// REMOVE BOTTOM PANE
dojo.destroy(home.bottomPane);

// SET PROGRESS PANE
var progressPane = home.progressPane;
console.dir({progressPane:progressPane});

// SET PACKAGE COMBO
var username = Agua.cookie('username');
console.dir({username:username});
Agua.data.packages[0].username = username;
home.setPackageCombo();

// RUN TESTS
doh.register("t.plugins.admin.hub.test", [
{
	name	: 	"progressPane-show",
	timeout	:	30000,	
	runTest	: function(){
	
		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred();
		
		// SHOW PROGRESS PANE
		setTimeout(function() {
			try {
				console.log("runTests    DOING progressPane.show()");

				var version = Agua.data.packages[0].version;
				console.log("runTests    version: " + version);
				home.progressPane.set('title', "Agua " + version + " Upgrade Log");
				home.progressPane.set('content', "TESTING upgrade log progress pane");
	
				console.log("runTests    DOING home.progressPane.show()");
				home.progressPane.show();
				home.resizeProgress();

				var visibility = dojo.style(progressPane.domNode, "visibility");
				console.log("runTests    visibility: " + visibility);
				var display = dojo.style(progressPane.domNode, "display");
				console.log("runTests    display: " + display);
				
				doh.assertTrue(visibility == "visible");
				doh.assertTrue(display == "block");
				
				deferred.callback(true);
	
			} catch(e) {
			  deferred.errback(e);
			}
		}, 1000);
	
		return deferred;
	}
}

,

{

	name	: 	"progressPane-minimize",
	timeout	:	30000,
	
	runTest	: function(){
		
		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred();
			
		console.log("runTests    DOING home.progressPane.minimize()");
		home.progressPane.minimize();

		// MINIMIZE PROGRESS PANE
		setTimeout(function() {
			try {
				var visibility = dojo.style(home.progressPane.domNode, "visibility");
				console.log("runTests    home.progressPane.domNode.visibility: " + visibility);
				var display = dojo.style(home.progressPane.domNode, "display");
				console.log("runTests    home.progressPane.domNode.display: " + display);

				doh.assertTrue(visibility == "hidden");
				doh.assertTrue(display == "none");
				
				deferred.callback(true);
	
			} catch(e) {
			  deferred.errback(e);
			}
		}, 5000);
	
		return deferred;
	}
}

,

{

	name	: 	"progressPane-dockNode",
	timeout	:	30000,
	
	runTest	: function(){
		
		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred();
			
		// HIDE PROGRESS PANE
		setTimeout(function() {
			try {
				var search = ".homeDockNode";
				console.log("runTests    DOING dojo.query(" + search + ")");
				var dockNode = dojo.query(search)[0];
				//console.log("runTests    dockNode:");
				//console.dir({dockNode:dockNode});
				
				var visibility = dojo.style(dockNode, "visibility");
				console.log("runTests    dockNode.visibility: " + visibility);
				var display = dojo.style(dockNode, "display");
				console.log("runTests    dockNode.display: " + display);

				doh.assertTrue(visibility == "visible");
				doh.assertTrue(display == "list-item");
				
				deferred.callback(true);
	
			} catch(e) {
			  deferred.errback(e);
			}
		}, 5000);
	
		return deferred;
	}
}

]);	// doh.register


//Execute D.O.H. in this remote file.
doh.run();




	

});

