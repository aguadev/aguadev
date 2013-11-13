require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/json",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/Grid",
	"dojo/ready",
	"dojo/domReady!"
],

function (
	declare,
	registry,
	dom,
	JSON,
	parser,
	doh,
	util,
	Agua,
	Grid,
	ready
) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.Grid", [

////}}}}}

//{
//
//////}}}}}
//
//	name: "new",
//	setUp: function(){
//		Agua.cgiUrl = "HERE";
//	},
//	runTest : function(){
//		console.log("# new");
//	
//		ready(function() {
//			console.log("new    INSIDE ready");
//
//			var grid = new Grid({
//				attachPoint : dom.byId("attachPoint")
//			});
//
//			var data = util.fetchJson("./data.json");
//			console.log("new    data: ");
//			console.dir({data:data});
//			grid.setGrid(data); 		
//			
//			console.log("new    instantiated");
//			doh.assertTrue(true);
//		});
//
//	},
//	tearDown: function () {}
//}
//,
{

////}}}}}

	name: "updateGrid",
	setUp: function(){
		Agua.cgiUrl = "HERE";
	},
	runTest : function(){
		console.log("# updateGrid");
	
		ready(function() {
			console.log("updateGrid    INSIDE ready");

			var object = new Grid({
				attachPoint : dom.byId("attachPoint")
			});

			var data 	= 	util.fetchJson("./data.json");
			console.log("updateGrid    data: ");
			console.dir({data:data});

			// SET GRID
			object.setGrid(data); 		
			
			// RUN FILTERS
			var filters	=	util.fetchJson("./filters.json");
			console.log("updateGrid    filters: " + JSON.stringify(filters));
			console.dir({filters:filters});
			
			object.updateGrid(filters, dojo.clone(data));
			
			console.log("updateGrid    instantiated");
			doh.assertTrue(true);
		});
	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});


