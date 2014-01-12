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
dojo.require("plugins.home.Home");

var Agua;
var Data;
var data;
var home;
dojo.addOnLoad(function(){

Agua = new plugins.core.Agua({
	cgiUrl : dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
	, dataUrl: dojo.moduleUrl("t", "json/getData-111127.json")
});

Agua.cookie('username', 'testuser');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.home.Controller"
]);

//plugins.home.Home.loadPane = function () {
//	console.log("Dummy loadPane()");
//}
home = new plugins.home.Home({
	attachWidget: Agua.tabs
});
console.dir({home:home});


var arraysHaveSameOrder = function (arrayA, arrayB) {
	if (arrayA.length != arrayB.length) { return false; }
	for (var i = 0, l = arrayA.length; i < l; i++) {
		if (arrayA[i] !== arrayB[i]) { 
			return false;
		}
	}
	return true;
};

doh.register("plugins.home.Home",
[
	{
		name: "versionSort-versions1",
		runTest: function() {
			console.log("versionSort-versions1");
	
			var versions = [ "1.0.0", "0.8.0", "0.9.1", "0.11.0" ];
			var correct = ["0.8.0","0.9.1","0.11.0","1.0.0"];
			var output = home.sortVersions(versions);
			console.log("sortVersions output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
		}
	}
	,
	{
		name: "versionSort-versions2",
		runTest: function() {
			console.log("versionSort-versions2");
			var versions = [ "1.0.0", "0.8.0", "0.9.1", "0.11.0", "12.0.0", "2.0.0" ];
			var correct = ["0.8.0","0.9.1","0.11.0","1.0.0","2.0.0","12.0.0"];
			var output = home.sortVersions(versions);
			console.log("sortVersions output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
		}
	}
	,
	{
		name: "versionSort-builds-3-permutations",
		runTest: function() {
			// BUILDS: 3 DIFFERENT ORDER PERMUTATIONS:
			// 1
			console.log("versionSort-builds-3-permutations");
			var versions = [ "0.8.0+build11", "0.8.0+build1", "0.8.0+build2" ];
			var correct = ["0.8.0+build1","0.8.0+build2","0.8.0+build11"]
			var output = home.sortVersions(versions);
			//console.log("output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
			
			// 2
			versions = ["0.8.0+build1", "0.8.0+build2",  "0.8.0+build11" ];
			correct = ["0.8.0+build1","0.8.0+build2","0.8.0+build11"]
			output = home.sortVersions(versions);
			//console.log("output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
			
			// 3
			versions = [ "0.8.0+build1", "0.8.0+build11", "0.8.0+build2" ];
			correct = ["0.8.0+build1","0.8.0+build2","0.8.0+build11"]
			output = home.sortVersions(versions);
			//console.log("output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
		}
	}
	,
	{
		name: "versionSort-build-vs-release",
		runTest: function() {
			console.log("versionSort-build-vs-release");
			// BUILD VERSUS RELEASE
			var versions = [ "0.8.0-rc2", "0.8.0+build11" ];
			var correct = ["0.8.0+build11","0.8.0-rc2"];
			var output = home.sortVersions(versions);
			//console.log("output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
		}
	}
	,
	{
		name: "versionSort-composite-3-permutations",
		runTest: function() {
			// COMPOSITE: MIXTURE OF VERSIONS, RELEASES AND BUILDS IN 3 PERMUTATIONS
			console.log("versionSort-composite-3-permutations");
			var versions = [ "1.0.0", "0.8.0", "0.9.1", "0.11.0", "12.0.0", "2.0.0", "0.8.0-alpha", "0.8.0-alpha.1", "0.8.0-beta", "0.8.0-rc2", "0.8.0+build11", "0.8.0+build1" ];
			 var correct = ["0.8.0","0.8.0+build1","0.8.0+build11","0.8.0-alpha","0.8.0-alpha.1","0.8.0-beta","0.8.0-rc2","0.9.1","0.11.0","1.0.0","2.0.0","12.0.0"];
			var output = home.sortVersions(versions);
			//console.log("output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
			
			versions = [ "2.0.0",  "0.8.0+build11", "0.8.0+build1", "0.8.0-alpha", "0.8.0-alpha.1", "0.8.0-beta", "0.8.0-rc2", "1.0.0", "0.8.0", "0.9.1", "0.11.0", "12.0.0" ];
			correct = ["0.8.0","0.8.0+build1","0.8.0+build11","0.8.0-alpha","0.8.0-alpha.1","0.8.0-beta","0.8.0-rc2","0.9.1","0.11.0","1.0.0","2.0.0","12.0.0"];
			output = home.sortVersions(versions);
			//console.log("output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
			
			versions = [ "0.8.0-alpha", "0.8.0-alpha.1",  "0.8.0-alpha.12",  "0.8.0-alpha.2",  "0.8.0-beta", "0.8.0-rc2", "0.8.0+build11", "0.8.0+build1", "0.8.0+build2" ];
			correct = ["0.8.0+build1","0.8.0+build2","0.8.0+build11","0.8.0-alpha","0.8.0-alpha.1","0.8.0-alpha.2","0.8.0-alpha.12","0.8.0-beta","0.8.0-rc2"];
			output = home.sortVersions(versions);
			//console.log("output: " + dojo.toJson(output));
			doh.assertTrue(arraysHaveSameOrder(output, correct));
		}
	}
	,
	{
		name: "removeCurrentVersion",
		runTest: function() {
			console.log("removeCurrentVersion");
			var versions = [
				{
					"owner": "agua",
					"installdir": "/agua",
					"version": "0.6.0",
					"status": "ready",
					"description": "A cloud workflow platform for next-gen bioinformatics",
					"datetime": "0000-00-00 00:00:00",
					"package": "agua",
					"username": "admin",
					"opsdir": "/agua/repos/public/biorepository",
					"notes": "Pre-alpha",
					"current": [
						"0.5.0",
						"0.6.0",
						"0.6.1",
						"0.7.1",
						"0.7.0",
						"0.7.2"
					],
					"url": "http://www.aguadev.org/confluence"
				}
			];
			
			var correct = [
				{
					"owner": "agua",
					"installdir": "/agua",
					"version": "0.6.0",
					"status": "ready",
					"description": "A cloud workflow platform for next-gen bioinformatics",
					"datetime": "0000-00-00 00:00:00",
					"package": "agua",
					"username": "admin",
					"opsdir": "/agua/repos/public/biorepository",
					"notes": "Pre-alpha",
					"current": [
						"0.5.0",
						"0.6.1",
						"0.7.1",
						"0.7.0",
						"0.7.2"
					],
					"url": "http://www.aguadev.org/confluence"
				}
			];

			//versions = home.removeCurrentVersion(versions);
			//console.log("versions: " + dojo.toJson(versions));
			//doh.assertTrue(arraysHaveSameOrder(output, correct));
		}
	}
	



]);	// doh.register


////]}}



//Execute D.O.H. in this remote file.
doh.run();

}); // dojo.addOnLoad

	
