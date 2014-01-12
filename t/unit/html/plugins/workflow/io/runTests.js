// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
////dojo.require("dijit.dijit");
////dojo.require("dojox.robot.recorder");
////dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// DEBUG LOADER
//dojo.require("dojoc.util.loader");

dojo.require("plugins.core.Agua");
dojo.require("plugins.workflow.Workflow");
dojo.require("plugins.workflow.IO");

// GLOBAL Agua VARIABLE
var Agua;
var data;

dojo.addOnLoad(function(){

Agua = new plugins.core.Agua( {
	cgiUrl	: 	"../../../../../../cgi-bin/agua/"
	, htmlUrl	: 	"../../../../../../agua/"
	, dataUrl	:	"test.json"
});
Agua.cookie('username', 'testuser');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.workflow.Controller"
]);

// CREATE TAB
Agua.controllers["workflow"].createTab();

doh.register("t.plugins.workflow.io.test", [{

name	: 	"chainInputs",
timeout	:	30000,

runTest	: function(){

	// SET DEFERRED OBJECT
	var deferred = new doh.Deferred();
		
	// OPEN DIRECTORIES AUTOMATICALLY
	setTimeout(function() {
		try {
			console.log("runTests    ************************************************");

			var workflow = Agua.controllers["workflow"].tabPanes[0];
			var io = new plugins.workflow.IO({	core: workflow.core	});
			data = t.doh.util.fetchJson("../../../../t/plugins/workflow/io/test.json");
			//Agua.stageparameters = data.stageparameters;
			//Agua.stages = data.stages;
			
			var chained = io.chainStage(data.stage);
			console.log("input 1 chained correctly: " + doh.assertEqual(chained.inputs[0].value, "Project1/Workflow1/accepted_hits.sam"));
			console.log("input 1 chained correctly: " + 		doh.assertEqual(chained.inputs[1].value, "Project1/Workflow1/accepted_hits.db"));
	
			deferred.callback(true);

		} catch(e) {
		  deferred.errback(e);
		}
	}, 5000);

	return deferred;
}

	
}]);	// doh.register


//Execute D.O.H. in this remote file.
doh.run();


}); // dojo.addOnLoad

