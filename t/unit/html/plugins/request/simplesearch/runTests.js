require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/SimpleSearch",
	"dojo/ready",
	"dojo/domReady!",
	"dojo/dnd/Source"
],

function (declare, registry, dom, parser, doh, util, Agua, SimpleSearch, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.SimpleSearch", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
	
		Agua.data = {};
		Agua.data.queries = util.fetchJson("./queries.json");
	},
	runTest : function(){
		console.log("# new");
		
		var search	=	new SimpleSearch({
			attachPoint : dom.byId("attachPoint")
		});
	

		//console.log("new    node: " + node);
		//console.dir({node:node});
		//
		//var itemArray = util.fetchJson("./rows.json");
		//console.log("new    itemArray:");
		//console.dir({itemArray:itemArray});
		//
		//query.dragSourceNode.loadDragItems(itemArray);
		//
		//
		//console.log("new    instantiated");
		////doh.assertTrue(true);
	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
