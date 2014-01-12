// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
//dojo.require("dijit.dijit");
////dojo.require("dojox.robot.recorder");
////dojo.require("dijit.robot");
dojo.require("doh.runner");
//dojo.require("dojoc.util.loader");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.workflow.RunStatus.Status");

var Agua;
var Data;
var data;
var runStatus;
dojo.addOnLoad(function(){

	Agua = new plugins.core.Agua( {
		cgiUrl : "../../../../../../cgi-bin/agua/",
		htmlUrl : "../../../../agua/"
	});
	
	runStatus = new plugins.workflow.RunStatus.Status({
		attachNode: Agua.tabs
	});

//	runStatus.stageStatus = new plugins.workflow.RunStatus.StageStatus({
//        attachNode: runStatus.stagesStatusContainer
//    });
	
	// SET runStatus.core.userWorkflows
	var userWorkflows = new Object;
	userWorkflows.getProject = function () { return "Project1"; }
	userWorkflows.getWorkflow = function () { return "Workflow1"; }
	userWorkflows.getCluster = function () { return "microcluster"; }
	runStatus.core.userWorkflows = userWorkflows;

	runStatus.clusterStatus.runner = {
		username:	"testuser",
		sessionid:	"",
		cluster: 	"microcluster",
		project:	"Project1",
		workflow:	"Workflow1",
		start:		1
	};
	
	// GET DATA
	data = t.doh.util.fetchJson("../../../../t/plugins/workflow/clusterstatus/test.json");
	Agua.data = {};
	Agua.data.stages = data.test1.response.stages;
	
	doh.register("t.plugins.workflow.runstatus.test",
	[
		{	name: "getStatus",
			runTest: function() {
		
				// GET DATA
				var response = dojo.toJson(data.test1.response);
				response = response.replace(/#/g, '-');
				response = response.replace(/'/g, "\\'");
				//response = response.replace(/>/g, "&gt;");
				runStatus.cgiUrl = Agua.cgiUrl + "/t/test.cgi?response=" + response;
				console.log("runTests    FIRST PREPARED response: ");
				console.dir({response:response});
		
				var childNode1 = dojo.create('div');
				document.body.appendChild(childNode1);
				var childNode2 = dojo.create('div');
				document.body.appendChild(childNode2);
		
				var runner = {
					username:	"testuser",
					sessionid:	"",
					cluster: 	"microcluster",
					project:	"Project1",
					workflow:	"Workflow1",
					start:		1,
					childNodes: [ childNode1, childNode2 ]
				};
		
				console.log("runTests    DOING FIRST runStatus.getStatus(runner)");
				runStatus.getStatus(runner, true);
				
				// SET DEFERRED OBJECT
				var deferred = new doh.Deferred();
				
				// TEST AFTER FIRST queryStatus
				setTimeout(function() {
					try {
						console.log("runTests    AFTER FIRST queryStatus");
						console.log("runTests    runStatus.stageStatus is NULL: " + doh.assertFalse(runStatus.stageStatus == null));
						console.log("runTests    data and rows[1] 'queued' values match");
						console.log("runTests    runStatus.stageStatus.rows[1].queuedNode.innerHTML: " + runStatus.stageStatus.rows[1].queuedNode.innerHTML);
						console.log("runTests    data.test2.response.stagestatus.stages[1].queued: " + data.test2.response.stagestatus.stages[1].queued);
						doh.assertEqual(runStatus.stageStatus.rows[1].queuedNode.innerHTML, data.test2.response.stagestatus.stages[1].queued);
						
						console.log("runTests    data and rows[1] 'started' values match");
						console.log("runTests    runStatus.stageStatus.rows[1].started: " + runStatus.stageStatus.rows[1].started);
						doh.assertEqual(runStatus.stageStatus.rows[1].started, data.test2.response.stagestatus.stages[1].started);
	
					} catch(e) {
						deferred.errback(e);
					}
				}, 4000);
	
	
				// DO SECOND queryStatus
				setTimeout(function() {
					try {
						// GET DATA
						response = dojo.toJson(data.test2.response);
						response = response.replace(/#/g, '-');
						response = response.replace(/'/g, "\\'");
						//response = response.replace(/>/g, "&gt;");
						runStatus.cgiUrl = Agua.cgiUrl + "/t/test.cgi?response=" + response;
				
						console.log("runTests    DOING SECOND runStatus.getStatus(runner)");
						runStatus.getStatus(runner, true);
				
					} catch(e) {
					  deferred.errback(e);
					}
				}, 8000);
			
				// TEST AFTER SECOND queryStatus
				setTimeout(function() {
					try {
						console.log("runTests    AFTER SECOND queryStatus");
						console.log("runTests    data and rows[1] 'completed' values match: " + doh.assertEqual(runStatus.stageStatus.rows[1].completed, data.test2.response.stagestatus.stages[1].completed));
						console.log("runTests    data and rows[1] 'status' values match: " + doh.assertEqual(runStatus.stageStatus.rows[1].status, data.test2.response.stagestatus.stages[1].status));
						console.log("runTests    duration is correct: " + doh.assertEqual(runStatus.stageStatus.rows[1].durationNode.innerHTML, "13 hours 31 min 5 sec"));
			
						deferred.callback(true);				
					} catch(e) {
					  deferred.errback(e);
					}
				}, 12000);
			
				return deferred;
			
			},
			timeout: 15000
		}	// getStatus


		//,
		//{	name: "stopCluster",
		//	runTest: function() {
		//
		//		// SET OVERRIDER
		//		var message = "";
		//		var overRider = function(args) {
		//			console.log("runTests    stopCluster    OVERRIDE args:");
		//			//console.dir({args:args});
		//			//console.log("runTests    stopCluster    message: " + message);
		//			console.log("runTests    correct Agua.toastMessage: " + (message == args.message) + ", expected: '" + message + "'");
		//			doh.assertTrue(message == args.message)
		//		};
		//		var connection = dojo.connect(Agua, "toastMessage", overRider);
		//
		//		// CLUSTER IS NULL
		//		runStatus.clusterStatus.runner.cluster = null;
		//		message = "Cluster not defined";
		//		runStatus.clusterStatus.stopCluster();
		//
		//		// STATUS IS NULL
		//		runStatus.clusterStatus.runner.cluster = "microcluster";
		//		runStatus.clusterStatus.status = null;
		//		message = "Cluster is already stopped";
		//		runStatus.clusterStatus.stopCluster();
		//
		//		// STATUS IS stopped
		//		runStatus.clusterStatus.runner.cluster = "microcluster";
		//		runStatus.clusterStatus.status = "stopped";
		//		message = "Cluster is already stopped";
		//		runStatus.clusterStatus.stopCluster();
		//
		//		// STATUS IS stopping
		//		runStatus.clusterStatus.runner.cluster = "microcluster";
		//		runStatus.clusterStatus.status = "stopped";
		//		message = "Cluster is already stopped";
		//		runStatus.clusterStatus.stopCluster();
		//
		//		// STATUS IS stopping
		//		runStatus.clusterStatus.runner.cluster = "microcluster";
		//		runStatus.clusterStatus.status = "stopped";
		//		message = "Cluster is already stopped";
		//		runStatus.clusterStatus.stopCluster();
		//
		//		// DISCONNECT OVERRIDER
		//		dojo.disconnect(connection);
		//
		//		//// RESET OVERRIDER
		//		//overRider = function(input) {
		//		//	console.log("runTests    stopCluster    OVERRIDE input: " + input);
		//		//	console.log("runTests    correct ClusterStatus.confirmStopCluster input: '" + message + "'");
		//		//	doh.assertTrue(message == input)
		//		//};
		//		//connection = dojo.connect(runStatus.ClusterStatus, "confirmStopCluster", overRider);
		//		//
		//		//// CALL TO confirmStopCluster
		//		//runStatus.clusterStatus.runner.cluster = "microcluster";
		//		//runStatus.clusterStatus.status = "waiting";
		//		//message = "microcluster";
		//		//runStatus.clusterStatus.stopCluster();
		//		//
		//		//// DISCONNECT OVERRIDER
		//		//dojo.disconnect(connection);
		//		
		//	}
		//}

		
	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

