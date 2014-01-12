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

{	name: "new",
	setUp: function(){
	
		Agua.data = {};
		Agua.data.queries = util.fetchJson("./queries.json");
	},
	runTest : function(){
		console.log("# new");
		
		var object	=	new SimpleSearch({
			attachPoint : dom.byId("attachPoint")
		});
	
		console.log("new    instantiated");
		doh.assertTrue(true);
	},
	tearDown: function () {}
},
{	name: "getFilters",
	setUp: function(){
	
		Agua.data = {};
		Agua.data.queries = util.fetchJson("./queries.json");
	},
	runTest : function(){
		console.log("# new");
		
		var object	=	new SimpleSearch({
			attachPoint : dom.byId("attachPoint")
		});
	
		object.searchInput.value = "    these three values    ";
		var actual = object.getFilters();
		var expected = [
			{"action":"OR","field":"ALL","operator":"contains","value":"these"},
			{"action":"OR","field":"ALL","operator":"contains","value":"three"},
			{"action":"OR","field":"ALL","operator":"contains","value":"values"}
		];
		
		console.log("getFilters    'these three values'");
		doh.assertTrue(util.identicalObjectArrays(expected, actual));
	},
	tearDown: function () {}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
