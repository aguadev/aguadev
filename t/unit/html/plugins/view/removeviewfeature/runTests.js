// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t");	

// DOJO TEST MODULES
//dojo.require("dijit.dijit");
//dojo.require("dojox.robot.recorder");
//dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// DEBUG LOADER
//dojo.require("dojoc.util.loader");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.view.View");

var Agua;
var data;
var view;

dojo.addOnLoad( function() {

console.log("FIRST dojo.addOnLoad()");

Agua = new plugins.core.Agua({
	cgiUrl : "../../../../../../cgi-bin/agua/",
	htmlUrl : "../../../../../../agua/"
	//, dataUrl: dojo.moduleUrl("plugins", "getData.120507.json")
	, dataUrl: "test.json"
});

Agua.cookie('username', 'aguatest');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.database = "aguatest";
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.view.Controller"
]);

var controllers = Agua.controllers;
console.log("test.html    controllers: " + controllers);
console.dir({controllers:controllers});

Agua.controllers["view"].createTab({
	baseUrl: "../../../../t/plugins/view/jbrowse"
	, browserRoot: ""
});

var view;
var browsers;
var browser;

doh.register("t.plugins.view.removeviewfeature.test",
[	
	{
		name: "removeViewFeature",
		timeout: 70000,
		runTest: function() {
	
			// SET DEFERRED
			var deferred = new doh.Deferred();

			var expectedFeatures = ['control1', 'test2'];
			//console.log("test.html    expectedFeatures: " + dojo.toJson(expectedFeatures));

			// GET VIEW
			view = Agua.controllers["view"].tabPanes[0];
			//console.log("test.html    view:");
			//console.dir({view:view});

			// DISABLE updateViewTracklist
			view.updateViewTracklist = function () {
				console.log("runTests    OVERRIDE of View.updateViewTracklist()");
			}

			// SET FEATURE LIST FROM featureList COMBO
			var featureList = new Array;
			view.featureList.store.fetch(
				{
					query: { name: "*"},
					onItem: function(item) {
						featureList.push(view.featureList.store.getValue(item, 'name'));
				}
			});
			//console.log("test.html    featureList: ");
			//console.dir({featureList:featureList});
			
			// TEST: FEATURE LIST AS EXPECTED
			doh.assertEqual(featureList, expectedFeatures);
			console.log("test.html    BEFORE removeViewFeature featureList OK: " + doh.assertEqual(featureList, expectedFeatures));

			// REMOVE VIEW FEATURE
			setTimeout(function(){
				try {
					//console.log("test.html    SET response TO running");
					view.url = Agua.cgiUrl + "t/test.cgi?response={'status':'running'}&";

					// ADD VIEW FEATURE
					view.removeViewFeature();
				} catch(e) { deferred.errback(e); }
			}, 4000);
			
			// SET READY
			setTimeout(function(){
				try {
					//console.log("test.html    SET response TO ready");
					view.url = Agua.cgiUrl + "t/test.cgi?response={'status':'ready'}&";
				} catch(e) {
				  deferred.errback(e);
				}
			}, 12000);
			
			// TEST: REMOVED FEATURE NO LONGER IN featureList COMBO 
			setTimeout(function(){
				try {
					expectedFeatures.push('tophat-1');
					//console.log("test.html    expectedFeatures: ");
					//console.dir({expectedFeatures:expectedFeatures});
					featureList = [];
					view.featureList.store.fetch(
						{
							query: { name: "*"},
							onItem: function(item) {
								featureList.push(view.featureList.store.getValue(item, 'name'));
						}
					});
					//console.log("test.html    featureList: ");
					//console.dir({featureList:featureList});
					doh.assertEqual(featureList, expectedFeatures);
					console.log("test.html    BEFORE removeViewFeature featureList OK: " + doh.assertEqual(featureList, expectedFeatures));
			
				} catch(e) { deferred.errback(e); }
			}, 20000);

			deferred.callback(true);
			return deferred;
		}
	}

]);	// doh.register

//Execute D.O.H. in this remote file.
doh.run();


}); // FIRST dojo.removeOnLoad
