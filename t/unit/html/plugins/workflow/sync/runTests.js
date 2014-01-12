// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
//dojo.require("dijit.dijit");
////dojo.require("dojox.robot.recorder");
////dojo.require("dijit.robot");
dojo.require("doh.runner");
dojo.require("dojo.parser");

// Agua TEST MODULES
dojo.require("t.doh.util");
//dojo.require("dojoc.util.loader");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.workflow.Workflow");

// GLOBAL Agua VARIABLE
var Agua;
dojo.addOnLoad(function(){

Agua = new plugins.core.Agua( {
	cgiUrl : "../../../../../../cgi-bin/agua/",
	database: "aguatest",
	dataUrl: "getData-execute.json"
});
Agua.cookie('username', 'testuser');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.workflow.Controller"
]);

// CREATE TAB
Agua.controllers["workflow"].createTab();

console.log("agua.html    BEFORE Agua.loadPlugins");
Agua.loadPlugins([ "plugins.workflow.Controller" ]);
console.log("agua.html    AFTER Agua.loadPlugins");

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

			// OK LOADS PARAMETER
			var workflow = Agua.controllers["workflow"].tabPanes[0];
			var dragSource = workflow.core.stages.dropTarget;
			var node = dragSource.node.childNodes[0];
			parameters.load(node);
		
		
			// STANDBY TEST CODE COPIED FROM Workflows.js
			console.log("runTests    Doing this.loadParametersPane(allNodes[0])");
			//console.log("runTests    allNodes[0]: " + allNodes[0]);
		
			var stages = this.getStagesStandby();
			console.log("runTests    stages: " + stages);
			console.log("runTests    stages.target: " + stages.target);
			
			console.log("runTests    stages._displayed: " + stages._displayed);
			console.log("runTests    stages.show()");
			stages.show();
			console.log("runTests    stages._displayed: " + stages._displayed);
			
			console.log("runTests    stages.domNode.innerHTML: " + stages.domNode.innerHTML);
			console.log("runTests    stages: ");
			console.dir({ stages:stages });
		
			deferred.callback(true);

		} catch(e) {
		  deferred.errback(e);
		}
	}, 5000);

	return deferred;
}


}]);	// doh.register


}); // dojo.addOnLoad

