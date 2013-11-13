require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/Search",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, registry, dom, parser, doh, util, Agua, Search, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.Search", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
	},
	runTest : function(){
		console.log("# new");
	
		ready(function() {
			console.log("new    INSIDE ready");

			var search = new Search({
				attachPoint : dom.byId("attachPoint")
			});
			//console.log("new    parameters: " + parameters);
			//console.dir({parameters:parameters});
			//
			console.log("new    instantiated");
			doh.assertTrue(true);
		});

	},
	tearDown: function () {}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

