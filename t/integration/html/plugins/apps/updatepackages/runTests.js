// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.workflow.Apps.AguaPackages");
dojo.require("plugins.apps.App");
dojo.require("plugins.apps.Packages");

var Agua;
var Data;
var data = new Object;
var packageApps;
var apps;
var packages;

dojo.addOnLoad(function(){

///}}}})))}}]]

/////}}}}}}]]

	Agua = new plugins.core.Agua( {
		cgiUrl : "../../../../../../cgi-bin/aguadev/",
		htmlUrl : "../../../../aguadev/"
	});

	// GET DATA
	Agua.data = {};
	Agua.data.apps = t.doh.util.fetchJson("apps.json");
	Agua.data.packages = t.doh.util.fetchJson("packages.json");
	Agua.data.conf = t.doh.util.fetchJson("conf.json");
	console.log("runTests    Agua.data: ");
	console.dir({Agua_data:Agua.data});
	console.log("runTests    Agua.data.apps: ");
	console.dir({Agua_data_apps:Agua.data.apps});
	
	doh.register("t.plugins.workflow.runstatus.test", [

/////}}}}]]]]}}}

		{	name: "new",
			runTest: function() {

				packageApps = new plugins.workflow.Apps.AguaPackages({
					attachNode: Agua.tabs
				});
				console.log("runTests.new    CREATED packageApps");
				doh.assertTrue(true);

				packages = new plugins.apps.Packages({
					attachNode: Agua.tabs
				});
				console.log("runTests.new    CREATED packages");
				doh.assertTrue(true);

				apps = new plugins.apps.App({
					attachNode: Agua.tabs
				});
				console.log("runTests.new    CREATED apps");
				doh.assertTrue(true);

				// SET COOKIE username
				Agua.cookie("username", "agua");

				var inputs = t.doh.util.fetchJson("newpackage.json");
				inputs.username 	= 	"agua";
				inputs.sessionid 	= 	"0000000000.0000.000";
				packages.saveInputs(inputs, {reload: false, originator: packages});
				
				var newapp = t.doh.util.fetchJson("newapp.json");
				apps.saveInputs(newapp, {reload: false, originator: packages});
			},
			timeout: 10000 
		}
		//,
		//{	name: "updatePackages",
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
		//{	name: "updateApps",
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

