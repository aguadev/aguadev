require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/parser",
	"dojo/dom",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/cloud/Hub",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare,
	registry,
	parser,
	dom,
	doh,
	util,
	Agua,
	Hub,
	ready) {

window.Agua = Agua;

console.log("runTests    Agua:");
console.dir({Agua:Agua});


////}}}}}

doh.register("plugins.apps.Dialog.Scrape", [

////}}}}}

{
	name	: 	"new",
	timeout	:	30000,
	setUp: function(){
		Agua.cgiUrl	=	"../../../../../../cgi-bin/aguadev/";
		Agua.cookie("username", "testuser");
		Agua.cookie("sessionid", "0000000000.0000.000");
		Agua.data	= 	util.fetchJson("./data.json");
		console.dir({Agua_data:Agua.data});
	},
	
	runTest	: function(){
	
		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred();
			
		// OPEN DIRECTORIES AUTOMATICALLY
		setTimeout(function() {
			try {
				console.log("runTests    new");
		
				var hub = new Hub({
					attachPoint: dom.byId("attachPoint")
				});

				doh.assertTrue(true);
				deferred.callback(true);
	
			} catch(e) {
			  deferred.errback(e);
			}
		}, 1000);
	
		return deferred;
	}
}

]);	// doh.register


//Execute D.O.H. in this remote file.
doh.run();



});

