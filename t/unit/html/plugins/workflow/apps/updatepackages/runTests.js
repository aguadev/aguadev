require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/workflow/Apps/AguaPackages",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Graph, ready) {

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

var object;
	
// DATA URL
var url 	= "./getData.json";	

var test = "unit.plugins.workflow.apps.updatepackages";
console.log("# test: " + test);
dom.byId("pagetitle").innerHTML = test;
dom.byId("pageheader").innerHTML = test;

doh.register(test, [
{
	name: "new",
	setUp: function(){
		//Agua.data = util.fetchJson(url);
		Agua.data = {};
		Agua.data.apps = util.fetchJson("apps.json");
		Agua.data.conf = util.fetchJson("conf.json");
		console.log("new    Agua.data: ");
		console.dir({Agua_data:Agua.data});
		console.log("new    Agua.data.apps: ");
		console.dir({Agua_data_apps:Agua.data.apps});
	},
	runTest : function(){
		console.log("# print");

		var attachPoint	=	dom.byId("attachPoint");
		console.log("new    attachPoint:");
		console.dir({attachPoint:attachPoint});
		
		object = new plugins.workflow.Apps.AguaPackages({
			attachPoint: dom.byId("attachPoint")
		});
		
		doh.assertTrue(true);
	},
	timeout: 10000 
}
//,
//{
//	name: "updatePackages",
//	runTest: function(){
//
//		// SET DEFERRED OBJECT
//		var deferred = new doh.Deferred();
//		
//		// TEST AFTER FIRST queryStatus
//		setTimeout(function() {
//			try {
//				console.log("");
//				console.log("");
//				console.log("");
//				
//				Agua.data.apps = t.doh.util.fetchJson("newpackage.json");
//
//				console.log("runTests    DOING Agua.updater.update('updatePackages')");
//				Agua.updater.update("updatePackages");
//				doh.assertTrue(true);
//				
//				console.log("runTests    packageApps.packageApps[0].apps: ");
//				console.dir({apps:packageApps.packageApps[0].apps});
//				doh.assertEqual(packageApps.packageApps[0].apps, Agua.data.apps);
//
//				deferred.callback(true);				
//				
//			} catch(e) {
//				deferred.errback(e);
//			}
//
//		}, 1000);
//
//		return deferred;
//
//	},
//	timeout: 15000 
//}	
//,
//{
//	name: "updateApps",
//	runTest: function(){
//
//		// SET DEFERRED OBJECT
//		var deferred = new doh.Deferred();
//
//		// TEST AFTER FIRST queryStatus
//		setTimeout(function() {
//			try {
//				console.log("");
//				console.log("");
//				console.log("");
//				
//				// RESTORE APPS
//				Agua.data.apps = t.doh.util.fetchJson("apps.json");
//
//				console.log("runTests    DOING Agua.updater.update('updateApps')");
//				Agua.updater.update("updateApps");
//				doh.assertTrue(true);
//				
//				var app = t.doh.util.fetchJson("ELAND.json");
//				console.log("runTests    packageApps.packageApps[0].apps: ");
//				console.dir({apps:packageApps.packageApps[0].apps[0]});
//				doh.assertEqual(packageApps.packageApps[0].apps[0], app);
//
//				deferred.callback(true);				
//				
//			} catch(e) {
//				deferred.errback(e);
//			}
//
//		}, 1000);
//
//		return deferred;
//
//	},
//	timeout: 15000 
//}	


]);	// doh.register

	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

