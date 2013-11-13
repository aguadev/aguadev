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
	data.test1 = t.doh.util.fetchJson("../../../../../t/plugins/workflow/runstatus/status/test1.json");
	data.test2 = t.doh.util.fetchJson("../../../../../t/plugins/workflow/runstatus/status/test2.json");
	data.test3 = t.doh.util.fetchJson("../../../../../t/plugins/workflow/runstatus/status/test3.json");
	
	runStatus = new plugins.workflow.RunStatus.Status({
		attachNode	: Agua.tabs
	});
	
	doh.register("t.plugins.workflow.runstatus.test", [
		
//////}}}}}

		{    name: "showStatus1",
			runTest: function(){
				console.log("#### showStatus1");

				runStatus.showStatus(dojo.clone(data.test1));
			},	
			timeout: 10000 
		}
		,
		{    name: "showStatus2",
			runTest: function(){
				console.log("#### showStatus2");
				
				runStatus.showStatus(dojo.clone(data.test2));
			},	
			timeout: 10000 
		}
		,
		{    name: "getStatus",
			runTest: function() {
				console.log("#### getStatus");

				// GET DATA
				console.log("runTest.getStatus    data.test1:");
				console.dir({data_test1:data.test1});
				
				var response = dojo.toJson(dojo.clone(data.test1));

				console.log("runTest.getStatus    response:");
				console.dir({response:response});
				response = response.replace(/#/g, '-');
				runStatus.cgiUrl = Agua.cgiUrl + "/test.cgi?response=" + response;
		
				var childNode1 = dojo.create('div');
				document.body.appendChild(childNode1);
				var childNode2 = dojo.create('div');
				document.body.appendChild(childNode2);
		
				var runner = {
					project:	"Project1",
					workflow:	"Workflow1",
					number:		1,
					childNodes: [ childNode1, childNode2 ]
				};
				console.log("runTests    Doing runStatus.getStatus(runner)");
				runStatus.getStatus(runner);

				// GET DATA
				response = dojo.toJson(dojo.clone(data.test2));
				response = response.replace(/#/g, '-');
				runStatus.cgiUrl = Agua.cgiUrl + "/test.cgi?response=" + response;
				console.log("runTests    runStatus.stageStatus.rows: " + runStatus.stageStatus);		
				console.dir({rows:runStatus.stageStatus.rows});
				
				// SET DEFERRED OBJECT
				var deferred = new doh.Deferred();
				
				// TEST AFTER FIRST queryStatus
				setTimeout(function() {
					try {
						console.log("runTests    AFTER FIRST queryStatus");
						console.log("runTests    runStatus.stageStatus is NULL: " + doh.assertFalse(runStatus.stageStatus == null));
						console.log("runTests    data and rows[1] 'queued' values match");
						console.log("runTests    runStatus.stageStatus.rows[1].queuedNode.innerHTML: " + runStatus.stageStatus.rows[1].queuedNode.innerHTML);
						console.log("runTests    data.test2.stagestatus.stages[1].queued: " + data.test2.stagestatus.stages[1].queued);
						doh.assertEqual(runStatus.stageStatus.rows[1].queuedNode.innerHTML, data.test2.stagestatus.stages[1].queued);
						
						console.log("runTests    data and rows[1] 'started' values match");
						console.log("runTests    runStatus.stageStatus.rows[1].started: " + runStatus.stageStatus.rows[1].started);
						doh.assertEqual(runStatus.stageStatus.rows[1].started, data.test2.stagestatus.stages[1].started);
						
						console.log("runTests    runStatus.completed is false: " + doh.assertFalse(runStatus.completed));
						console.log("runTests    runStatus.polling is true: " + doh.assertTrue(runStatus.polling));
						
					} catch(e) {
						deferred.errback(e);
					}

				}, 1000);


				// TEST AFTER SECOND queryStatus
				setTimeout(function() {
					try {
						console.log("runTests    AFTER SECOND queryStatus");
						console.log("runTests    data and rows[1] 'completed' values match: " + doh.assertEqual(runStatus.stageStatus.rows[1].completed, data.test2.stagestatus.stages[1].completed));
						console.log("runTests    data and rows[1] 'status' values match: " + doh.assertEqual(runStatus.stageStatus.rows[1].test, data.test2.stagestatus.stages[1].test));
						
						console.log("runTests    duration is correct: " + doh.assertEqual(runStatus.stageStatus.rows[1].durationNode.innerHTML, "13 hours 31 min 5 sec"));

						deferred.callback(true);				
					} catch(e) {
					  deferred.errback(e);
					}
				}, 12000);

				return deferred;
			},
			timeout: 15000
		}
	
	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

