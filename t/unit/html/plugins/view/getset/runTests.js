// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t");	

// DOJO TEST MODULES
//dojo.require("dijit.dijit");
//dojo.require("dojox.robot.recorder");
//dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// DEBUG LOADER
//dojo.require("dojoc.util.loader");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.view.View");

var Agua;
var data;
var view;

dojo.addOnLoad( function() {

console.log("FIRST dojo.addOnLoad()");

Agua = new plugins.core.Agua({
	cgiUrl : "../../../../../../cgi-bin/agua/",
	htmlUrl : "../../../../../../agua/"
	//, dataUrl: dojo.moduleUrl("plugins", "getData.120507.json")
	, dataUrl: "getData.120521.testuser.json"
});

Agua.cookie('username', 'aguatest');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.database = "aguatest";
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.view.Controller"
]);

var controllers = Agua.controllers;
console.log("runTests.js    controllers: " + controllers);
console.dir({controllers:controllers});

Agua.controllers["view"].createTab({
	baseUrl: "../../../../t/plugins/view/jbrowse"
	, browserRoot: ""
});

var view;
var browsers;
var browser;

doh.register("t.plugins.view.getset.test",
[	
	{
		name: "getters",
		timeout: 70000,
		runTest: function() {

			// CLEAR CONSOLE 
			console.clear();
			console.log("After console.clear()");

			// GET VIEW
			view = Agua.controllers["view"].tabPanes[0];
			console.log("runTests.js    view:");
			console.dir({view:view});

			// SET VIEW COMBO
			view.viewProjectCombo.set('value', 'Project1');
			view.viewCombo.set('value', 'View4');
			view.loadBrowser("Project1", "View4");
			
			// SET DEFERRED
			var deferred = new doh.Deferred();


			setTimeout(function(){
				try {
					console.log("runTests.js    STARTING getters");
					console.log("runTests.js    project is correct (Project1): " + doh.assertEqual(view.getProject(), "Project1"));
					console.log("runTests.js    workflow is correct (Workflow1): " + doh.assertEqual(view.getWorkflow(), "Workflow1"));
					
					console.log("runTests.js    BEFORE view.getView()");
					var view = view.getView();
					console.log("runTests.js    view: " + view);
					
					console.log("runTests.js    view is correct (View1): " + doh.assertEqual(view.getView(), "View1"));
					console.log("runTests.js    AFTER view.getView()");
					
					console.log("runTests.js    viewFeature is correct (control1): " + doh.assertEqual(view.getViewFeature(), "control1"));
					console.log("runTests.js    species is correct (human): " + doh.assertEqual(view.getFeatureSpecies(), "human"));
					console.log("runTests.js    build is correct (hg19): " + doh.assertEqual(view.getFeatureBuild(), "hg19"));
					console.log("runTests.js    feature is correct (tophat-1): " + doh.assertEqual(view.getFeature(), "tophat-1"));

			deferred.callback(true);
			
				} catch(e) {
				  deferred.errback(e);
				}
			}, 5000);
			
			setTimeout(function(){
				try {
					// GET BROWSER
					browsers = view.browsers;
					browser = browsers[0].browser;
					console.log("runTests.js    browser: ");
					console.dir({browser:browser});
					
					console.log("runTests.js    className: " + doh.assertEqual("plugins.view.jbrowse.js.Browser", Agua.getClassName(browser), "plugins.view.jbrowse.js.Browser"));
					console.log("runTests.js    isBrowser: " + doh.assertEqual(view.isBrowser(browser.params.viewObject.project, browser.params.viewObject.view), 1));

			deferred.callback(true);
				} catch(e) { deferred.errback(e); }
			}, 10000);
			
			//
			//setTimeout(function(){
			//	try {
			//		console.log("runTests.js    SET response TO ready");
			//		view.url = Agua.cgiUrl + "t/test.cgi?response={'status':'none'}&";
			//	} catch(e) {
			//	  deferred.errback(e);
			//	}
			//}, 15000);

			setTimeout(function(){
				try {
					//deferred.callback(true);
			
				} catch(e) {
				  deferred.errback(e);
				}
			}, 12000);

			deferred.callback(true);

			return deferred;
		}
	}


]);	// doh.register

//Execute D.O.H. in this remote file.
doh.run();


}); // FIRST dojo.addOnLoad
