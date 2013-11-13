// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
dojo.require("doh.runner");
//dojo.require("dojoc.util.loader");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.workflow.RunStatus.Status");

var Agua = new Object;
var Data;
var data = new Object;
var runStatus;
dojo.addOnLoad(function(){

/////}}}}}}]]
	Agua = new plugins.core.Agua( {
		cgiUrl : "../../../../../../cgi-bin/agua/",
		htmlUrl : "../../../../agua/"
	});
	
	// GET DATA
	// status range:
	// cluster	: cluster starting, cluster running, cluster error
	// balancer	: balancer starting, balancer running, balancer error
	// sge		: sge starting, sge running, sge error
	// workflow : pending, running, error, stopped
	
	runStatus = new plugins.workflow.RunStatus.Status({
		attachNode	: Agua.tabs
	});

	// AUTOMATICALLY GENERATE TEST
	var generateTest = function (file, timeout, expected) {
		console.log("file: " + file);
		console.log("timeout: " + timeout);
		var test = {
			name: file,
			runTest: function(){
				console.log("#### " + file);

				var data = t.doh.util.fetchJson(file);
				runStatus.showStatus(data);

				var selectedTab = runStatus.getSelectedTab();
				console.log("test file " + file + " selectedTab : " + selectedTab);
				console.log("doh.assertTrue(selectedTab == " + expected + ")");
				doh.assertTrue(selectedTab == expected);

				// SET DEFERRED OBJECT
				var deferred = new doh.Deferred();

				// DO TIMEOUT
				setTimeout(function() {
					try {
						console.log("runTests    DOING timeout: " + timeout);

						deferred.callback(true);				
					} catch(e) {
					  deferred.errback(e);
					}
				}, timeout);

				return deferred;
			},	
			timeout: timeout
		};
		
		return test;
	};
	
	var files = [
		"notstarted.json"
		,"cluster-starting.json"
		,"cluster-running.json"
		,"balancer-starting.json"
		,"balancer-running.json"
		,"sge-starting.json"
		,"sge-running.json"
		,"started.json"
	];

	var expecteds = [
		"stageStatus"
		,"clusterStatus"
		,"clusterStatus"
		,"clusterStatus"
		,"clusterStatus"
		,"queueStatus"
		,"queueStatus"
		,"stageStatus"
	];

	// GENERATE TESTS
	var tests = [];
	var timeout = 2000;
	for ( var i = 0; i < files.length; i++ ) {
		var test = generateTest(files[i], timeout, expecteds[i]);
		tests.push(test);
	}
	
	// doh.register
	doh.register("t.plugins.workflow.runstatus.startup.test", tests);
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

