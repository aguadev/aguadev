// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
//dojo.require("dijit.dijit");
////dojo.require("dojox.robot.recorder");
////dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Common");

var common;

dojo.addOnLoad(function(){

	common = new plugins.core.Common({});

	doh.register("t.plugins.core.common.sort.test",
	[
		{
			name		:	"sortHasharrayByKeys",
			runTest		:	function () {
				var workflows = [
					{
						description: "",
						name: "Workflow1",
						notes: "",
						number: "2",
						project: "Project1",
						provenance: "",
						username: "admin",
					},
					{
						description: "",
						name: "Workflow2",
						notes: "",
						number: "1",
						project: "Project1",
						provenance: "",
						username: "admin"				
					}
				];
				
				var sortedByNumber = [
					{
						description: "",
						name: "Workflow2",
						notes: "",
						number: "1",
						project: "Project1",
						provenance: "",
						username: "admin"				
					},
					{
						description: "",
						name: "Workflow1",
						notes: "",
						number: "2",
						project: "Project1",
						provenance: "",
						username: "admin",
					}
				];

				var hasharrayCopy = dojo.clone(workflows);
				hasharrayCopy = common.sortHasharrayByKeys(hasharrayCopy, ["number"]);
				console.log("sorted by number: " + doh.assertEqual(t.doh.util.identicalOrderHashArrays(hasharrayCopy, sortedByNumber), 1));
				
				var hasharrayCopy = dojo.clone(workflows);
				hasharrayCopy = common.sortHasharrayByKeys(hasharrayCopy, ["name"]);
				console.log("sorted by name: " + doh.assertEqual(t.doh.util.identicalOrderHashArrays(hasharrayCopy, workflows), 1));
			}
		}
		,
		{
			name		: 	"sortNaturally",
			runTest		: 	function () {
				var actual = [
"project44",
"project22",
"project32",
"project33",
"proj4",
"project4",
"project2",
"project11",
"project22",
"project1",
"proj2",
"project3"
];

				var expected = [
"proj2",
"proj4",
"project1",
"project2",
"project3",
"project4",
"project11",
"project22",
"project22",
"project32",
"project33",
"project44"
];

				actual.sort(common.sortNaturally);
				//console.log("runTests.js    actual:");
				//console.dir({actual:actual});
			
				console.log("sort naturally: " + doh.assertEqual(t.doh.util.identicalArrays(actual, expected), 1));
			
			}
		}
		,
		{
			name	:	"sortObjectsNaturally",
			runTest	:	function () {
				
				var hasharray = t.doh.util.fetchJson("sortObjectsNaturally.json");
				//console.log("runTests.js    BEFORE randomizeArray    hasharray:");
				var hasharrayCopy = dojo.clone(hasharray);
				//console.dir({hasharrayCopy:hasharrayCopy});
				
				// RANDOMIZE ARRAY
				hasharray = t.doh.util.randomizeArray(hasharray);
				//console.log("runTests.js    AFTER randomizeArray    hasharray:");
				//var hasharrayCopy2 = dojo.clone(hasharray);
				//console.dir({hasharrayCopy:hasharrayCopy2});
				
				hasharray.sort(function(a,b) {
					return common.sortObjectsNaturally(a, b, "view");
				});
				
				//console.log("runTests.js    AFTER sortObjectsNaturally    hasharray:");
				//console.dir({hasharray:hasharray});
				
				console.log("sort objects naturally by view: " + doh.assertEqual(t.doh.util.identicalObjectArrays(hasharrayCopy, hasharray, "view"), 1));
				
			}
		}
		
	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

