require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/Query",
	"dojo/ready",
	"dojo/domReady!",
	"dojo/dnd/Source"
],

function (declare, registry, dom, parser, doh, util, Agua, Query, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.Query", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
		// ENSURE attachPoint __WIDGET__ IS INSTANTIATED
		parser.parse();
	},
	runTest : function(){
		console.log("# new");
		
		var query	=	new Query({
			attachPoint : dom.byId("attachPoint")
		});

		//query.value.click();

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
