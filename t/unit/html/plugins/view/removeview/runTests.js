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
if ( 1 ) {

var view;
var browsers;
var browser;
	
Agua = new plugins.core.Agua({
	cgiUrl : "../../../../../../cgi-bin/agua/",
	htmlUrl : "../../../../../../agua/"
	//, dataUrl: dojo.moduleUrl("plugins", "getData.120507.json")
	, dataUrl : "../../../../t/json/getData-110605.json"

	//, dataUrl: "getData.120521.testuser.json"
});

Agua.cookie('username', 'aguatest');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.database = "aguatest";
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.view.Controller"
]);

var controllers = Agua.controllers;
//console.log("runTests.js    controllers: " + controllers);
//console.dir({controllers:controllers});

Agua.controllers["view"].createTab({
	baseUrl: "../../../../t/plugins/view/jbrowse"
	, browserRoot: ""
});

}

doh.register("t.plugins.view.removeview.test",
[	
	{
		name: "removeView",
		timeout: 70000,
		runTest: function() {
			
			// SET DEFERRED
			var deferred = new doh.Deferred();
	
			// GET VIEW
			view = Agua.controllers["view"].tabPanes[0];
			//console.log("runTests.js    view:");
			//console.dir({view:view});
	
			// SET VIEW COMBO
			var projectName 	= 	"Project1";
			var viewName 		=	"View4";
			var speciesBuild	=	"human(hg19)";
			view.viewProjectCombo.set('value', projectName);
			view.viewCombo.set('value', viewName);
			view.loadBrowser(projectName, viewName);
	
			setTimeout(function(){
				try {
					// REMOVE VIEW
					view.removeView(projectName, viewName, speciesBuild);

					//// VERIFY BROWSER DOES NOT EXIST FOR REMOVED VIEW
					//console.log("runTests.js    Browser does not exist after removeView: " + doh.assertEqual(view.getBrowser(projectName, viewName), null));
					// VERIFY VIEW DOES NOT EXIST
					console.log("runTests.js    View does not exist after removeView: " + doh.assertEqual(Agua.isView(projectName, viewName), false));

					deferred.callback(true);
			
				} catch(e) { deferred.errback(e); }
			}, 15000);
	
			return deferred;
		}
	}
	
	,
	
	{
		name: "removeView-BEFORE",
		timeout: 70000,
		runTest: function() {
	
			// GET VIEW
			view = Agua.controllers["view"].tabPanes[0];
			//console.log("runTests.js    view:");
			//console.dir({view:view});
			
			// SET VIEW COMBO
			var tempGetViews = dojo.clone(Agua.getViews);
			
			Agua.getViews = function () {
				return [
					{	project: "Project0", view: "View44" },
					{	project: "Project0", view: "View4" },
					{	project: "Project0", view: "View33" },
					{	project: "Project0", view: "View12" },
					{	project: "Project0", view: "View1" },
					{	project: "Project0", view: "View11" },
					{	project: "Project2", view: "View9" },
					{	project: "Project2", view: "View8" },
					{	project: "Project2", view: "View7" },
					{	project: "Project2", view: "View6" },
					{	project: "Project2", view: "View2" }
				]
			}
			
			var viewObject = {	project: "Project1", view: "View10" };
			var previousView = Agua.getPreviousView(viewObject);
			//console.log("runTests.js    previousView: ");
			//console.dir({previousView:previousView});	
			
			var expectedView = {	project: "Project0", view: "View44" };
			
			console.log("removeView-Project2     expected: " + doh.assertEqual(t.doh.util.identicalHashes(previousView, expectedView), 1));
		}
	}
	
	,	
	
	{
		name: "removeView-AFTER",
		timeout: 70000,
		runTest: function() {
			
			// GET VIEW
			view = Agua.controllers["view"].tabPanes[0];
			//console.log("runTests.js    view:");
			//console.dir({view:view});
			
			// SET VIEW COMBO
			var tempGetViews = dojo.clone(Agua.getViews);
			
			Agua.getViews = function () {
				return [
					{	project: "Project2", view: "View44" },
					{	project: "Project2", view: "View4" },
					{	project: "Project2", view: "View33" },
					{	project: "Project2", view: "View12" },
					{	project: "Project2", view: "View1" },
					{	project: "Project2", view: "View11" },
					{	project: "Project2", view: "View9" },
					{	project: "Project2", view: "View8" },
					{	project: "Project2", view: "View7" },
					{	project: "Project2", view: "View6" },
					{	project: "Project2", view: "View2" }
				]
			}
			
			var viewObject = {	project: "Project1", view: "View10" };
			var previousView = Agua.getPreviousView(viewObject);
			//console.log("runTests.js    previousView: ");
			//console.dir({previousView:previousView});	
			
			var expectedView = {	project: "Project2", view: "View1" };
			
			console.log("removeView-Project2     expected: " + doh.assertEqual(t.doh.util.identicalHashes(previousView, expectedView), 1));
		}
	}
	
	,
	
	{
		name: "removeView-INSIDE",
		timeout: 70000,
		runTest: function() {
			// GET VIEW
			view = Agua.controllers["view"].tabPanes[0];
			//console.log("runTests.js    view:");
			//console.dir({view:view});
			
			// SET VIEW COMBO
			var tempGetViews = dojo.clone(Agua.getViews);
			
			Agua.getViews = function () {
				return [
					{	project: "Project1", view: "View44" },
					{	project: "Project1", view: "View4" },
					{	project: "Project1", view: "View33" },
					{	project: "Project1", view: "View12" },
					{	project: "Project1", view: "View1" },
					{	project: "Project1", view: "View11" },
					{	project: "Project1", view: "View9" },
					{	project: "Project1", view: "View8" },
					{	project: "Project1", view: "View7" },
					{	project: "Project1", view: "View6" },
					{	project: "Project1", view: "View2" }
				]
			}
			
			var viewObject = {	project: "Project1", view: "View10" };
			var previousView = Agua.getPreviousView(viewObject);
			//console.log("runTests.js    previousView: ");
			//console.dir({previousView:previousView});
			
			var expectedView = {	project: "Project1", view: "View9" };
			
			console.log("removeView-Project2     expected: " + doh.assertEqual(t.doh.util.identicalHashes(previousView, expectedView), 1));
		
		}
	}

]);	// doh.register

//Execute D.O.H. in this remote file.
doh.run();


}); // FIRST dojo.addOnLoad
