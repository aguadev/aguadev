// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
dojo.require("doh.runner");
//dojo.require("dojoc.util.loader");

// Agua TEST MODULES
dojo.require("t.doh.util");

var Agua;
var Data;
var data;
var home;
dojo.addOnLoad(function(){

doh.register("plugins.home.GitHub",
[
	{
		name: "getTags",
		runTest: function() {
	
			var url = "https://api.github.com/repos/agua/agua/tags";
			var timeout = 60000;
	
			// SEND TO SERVER
			dojo.xhrGet(
				{
					url: url,
					contentType: "text",
					preventCache : true,
					sync: false,
					handleAs: "json",
					timeout: timeout,
					load: function(response, ioArgs) {
						console.log("    Common.Util.doPut    response: ");
						console.dir({response:response});
						doh.assertTrue(response != null);
						
						console.log("    Common.Util.doPut    response[0].name: " + response[0].name)
						doh.assertTrue(response[0].name != null);
					},
					error: function(response, ioArgs) {
						console.log("    Common.Util.doPut    Error with put. Response: " + response);
						return response;
					}
				}
			);	
		}
	}

]);	// doh.register


////]}}



//Execute D.O.H. in this remote file.
doh.run();

}); // dojo.addOnLoad

	
