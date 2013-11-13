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

	doh.register("t.plugins.core.common.array.test",
	[
		{
			name		:	"_identicalHashes",
			runTest		:	function () {
				var tests = [
					{
						name	:	"nestedHash",	
						hashA 	:	{
							callback: "_handleAddView",
							sourceid: "plugins_view_View_0",
							status: "ready",
							viewobject: {
								project: "Project1",
								view: "View2"
							}
						}
						,
						hashB 	:	{
							callback: "_handleAddView",
							sourceid: "plugins_view_View_0",
							status: "ready",
							viewobject: {
								project: "Project1",
								view: "View2"
							}
						}
					}
					,
					{
						name	:	"nestedArray",	
						hashA 	:	{
							callback: "_handleAddView",
							sourceid: "plugins_view_View_0",
							status: "ready",
							viewobject: [1,2,3,4]
						}
						,
						hashB 	:	{
							callback: "_handleAddView",
							sourceid: "plugins_view_View_0",
							status: "ready",
							viewobject: [1,2,3,4]
						}
					}
					
				];
		
				for ( var i in tests ) {
					var test 	= 	tests[i];
					var name	=	test.name;
					var hashA	=	test.hashA;
					var hashB	=	test.hashB;
					
					var identical = common._identicalHashes(hashA, hashB);
					console.log("runTests._identicalHashes    identical: " + identical);
					console.log("runTests._identicalHashes    " + name + ": " + doh.assertEqual(1, identical));
				}
			}
		}
		,
		{
			name		:	"_getIndexInArray",
			runTest		:	function () {
				var tests = [
					{
						name	:	"nestedHash",	
						browsers : [
							{
								project: "Project1",
								view: "View2",
								viewid: "plugins_view_View_0"
							}
						]
						,
						project: "Project1",
						view: "View2"
					}					
				];

				for ( var i in tests ) {
					var test 	= 	tests[i];
					var name	=	test.name;
					var project	=	test.project;
					var view	=	test.view;
					
					var browsers=	test.browsers;
					
					var index = common._getIndexInArray(browsers, {project: project, view: view}, [ "project", "view" ]);
					console.log("runTests._indexHashes    index: " + index);
					console.log("runTests._identicalHashes    " + name + ": " + doh.assertEqual(0, index));
				}
			}
		}
		
	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

