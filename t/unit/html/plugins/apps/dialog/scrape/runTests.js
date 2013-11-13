require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/parser",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/apps/Dialog/Scrape",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, registry, parser, doh, util, Agua, Scrape, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.apps.Dialog.Scrape", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
		// ENSURE attachPoint WIDGET IS INSTANTIATED
		//parser.parse();
		
		Agua.data = new Object;
	},
	runTest : function(){
		console.log("# new");
	
		
		var access = new Scrape({
			attachPoint : dojo.byId("attachPoint")
		});
		//console.log("access: " + access);
		//console.dir({access:access});
		
		console.log("new    instantiated");
		doh.assertTrue(true);
	},
	tearDown: function () {}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});



