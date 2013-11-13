require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/Request",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, registry, dom, parser, doh, util, Agua, Request, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.Request", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
		Agua.cgiUrl = "HERE";
	
		Agua.data = {};
		Agua.data.queries = util.fetchJson("./queries.json");
		Agua.data.downloads = util.fetchJson("./downloads.json");
		
	},
	runTest : function(){
		console.log("# new");
	

		ready(function() {
			console.log("new    INSIDE ready");

			var object = new Request({
				url : "./data.json",
				attachPoint : dom.byId("attachPoint")
			});
			console.log("new    object: ");
			console.dir({object:object});

			
			var data = util.fetchJson("./data.json");
			console.log("new    data: ");
			console.dir({data:data});
			
			object.core.grid.setGrid(data); 		
			
			
			
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


