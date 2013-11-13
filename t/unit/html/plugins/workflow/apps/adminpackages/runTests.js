// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");

// DOJO TEST MODULES
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.workflow.Apps.AdminPackages");

var Agua;
var Data;
var data = new Object;
var packageApps;
dojo.addOnLoad(function(){

///}}}})))}}]]

/////}}}}}}]]

	Agua = new plugins.core.Agua( {
		cgiUrl : "../../../../../../cgi-bin/agua/",
		htmlUrl : "../../../../agua/"
	});

	// GET DATA
	Agua.data = {};
	Agua.data.apps = t.doh.util.fetchJson("apps.json");
	Agua.data.conf = t.doh.util.fetchJson("conf.json");
	console.log("runTests    Agua.data: ");
	console.dir({Agua_data:Agua.data});
	console.log("runTests    Agua.data.apps: ");
	console.dir({Agua_data_apps:Agua.data.apps});
	
	doh.register("t.plugins.workflow.runstatus.test", [

/////}}}}]]]]}}}

		{
			name: "new",
			runTest: function(){
				packageApps = new plugins.workflow.Apps.AdminPackages({
					attachNode: Agua.tabs
				});			

				doh.assertTrue(true);
			},	
			timeout: 10000 
		}
	
	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

