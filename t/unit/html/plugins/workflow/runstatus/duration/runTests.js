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
var data = new Object;
var runStatus;
dojo.addOnLoad(function(){

///}}}})))}}]]

/////}}}}}}]]

	Agua = new plugins.core.Agua( {
		cgiUrl : "../../../../../../cgi-bin/agua/",
		htmlUrl : "../../../../agua/"
	});
	
	runStatus = new plugins.workflow.RunStatus.Status({
		attachNode: Agua.tabs
	});

	runStatus.stageStatus = new plugins.workflow.RunStatus.StageStatus({
        attachNode: runStatus.stagesStatusContainer
    });
	
	// GET DATA
	data.status1 = t.doh.util.fetchJson("../../../../../t/plugins/workflow/runstatus/duration/test1.json");
	data.status2 = t.doh.util.fetchJson("../../../../../t/plugins/workflow/runstatus/duration/test2.json");
	data.status3 = t.doh.util.fetchJson("../../../../../t/plugins/workflow/runstatus/duration/test3.json");
	data.status4 = t.doh.util.fetchJson("../../../../../t/plugins/workflow/runstatus/duration/test4.json");
	
	doh.register("t.plugins.workflow.runstatus.test", [

/////}}}}]]]]}}}

		{    name: "calculateDuration1",
			runTest: function(){
				var duration = runStatus.stageStatus.calculateDuration(data.status1.stagestatus[0]);
				doh.assertEqual(duration, data.status1.duration);
			},	
			timeout: 10000 
		}
		,
		{    name: "calculateDuration2",
			runTest: function(){
				var duration = runStatus.stageStatus.calculateDuration(data.status2.stagestatus[0]);
				doh.assertEqual(duration, data.status2.duration);
			},	
			timeout: 10000 
		}
		,
		{    name: "calculateDuration3",
			runTest: function(){
				var duration = runStatus.stageStatus.calculateDuration(data.status3.stagestatus[0]);
				doh.assertEqual(duration, data.status3.duration);
			},	
			timeout: 10000 
		}
		,
		{    name: "calculateDuration4",
			runTest: function(){
				var duration = runStatus.stageStatus.calculateDuration(data.status4.stagestatus[0]);
				doh.assertEqual(duration, data.status4.duration);
			},	
			timeout: 10000 
		}	
	
	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

