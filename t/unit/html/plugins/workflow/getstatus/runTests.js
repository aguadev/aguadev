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
dojo.require("plugins.workflow.RunStatus");

var Agua;
var Data;
var data;
var runStatus;
dojo.addOnLoad(function(){

	Agua = new plugins.core.Agua( {
		cgiUrl : "../../../../../../cgi-bin/agua/t",
		htmlUrl : "../../../../agua/"
	});
	
	runStatus = new plugins.workflow.RunStatus({
		attachNode: Agua.tabs
	});

	// SET DELAY
	runStatus.delay = 21000;
	
	runStatus.setCgiUrl = function (url) {
		var json = t.doh.util.fetchText(url);
		this.cgiUrl = Agua.cgiUrl + "/test.cgi?response=" + json;
	};
	
	Agua.updateStagesStatus = function () {
		console.log("Agua.updateStagesStatus    IN runTests.js");
	};

	Agua.getWorkflowNumber = function () {
		console.log("Agua.getWorkflowNumber    IN runTests.js");
		return 1;
	};

	runStatus.core = new Object;
	runStatus.core.userWorkflows = {}
	runStatus.core.userWorkflows.getProject = function() {
		return "Project1";
	}
	runStatus.core.userWorkflows.getWorkflow = function() {
		return "Workflow1";
	}
	runStatus.core.userWorkflows.getCluster = function() {
		return "";
	}
	
	runStatus.pauseWorkflow = function () {
		console.log("runStatus.pauseWorkflow    IN runTests.js");
	};

	runStatus.stopWorkflow = function () {
		console.log("runStatus.stopWorkflow    IN runTests.js");
	};

	runStatus.core.userWorkflows.dropTarget = {};
	runStatus.core.userWorkflows.dropTarget.getAllNodes = function () {
		return [1,2,3];
	}

	console.clear();
	console.log("After console.clear()");

	doh.register("t.plugins.workflow.runstatus.test",
	[
		{
			name: "getStatus",
			runTest: function(){
				runStatus.runner = {
					childNodes  : [1,2,3],
					cluster     :	"smallcluster",
					project     :	"Project1",
					sessionid   :	"9999999999.9999.999",
					start       :   1,
					stop        :	"",
					username    :	"admin",
					workflow    :	"Workflow1",
					workflownumber:	"1"
				};
				var singleton = false;
				runStatus.polling = false;
				runStatus.setCgiUrl("./test-incomplete-unpretty.json");
				
				console.log("runTests.js    Doing runStatus.getStatus(runner, singleton)");
				runStatus.getStatus(runStatus.runner, singleton);

				var deferred = new doh.Deferred();
				setTimeout(function(){
					try {
						console.log("runTests.js    Checking runStatus.polling");
						console.log("test.html    runStatus.polling is TRUE: " + doh.assertEqual(runStatus.polling, true));
						deferred.callback(true);
					
					} catch(e) {
					  deferred.errback(e);
					}
				}, 3000);

				
				return deferred;
			
			},
			timeout: 15000
		}
	
	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

