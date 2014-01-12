require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/json",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/Saved",
	"dojo/ready",
	"dojo/domReady!",
	"dojo/dnd/Source"
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
	Saved,
	ready
) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.Saved", [

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
		
		var query	=	new Saved({
			attachPoint : dom.byId("attachPoint")
		});
	
		// VERIFY ORDINALS
		var expectedOrdinals = [1,2,3,4];
		var itemArray = query.getItemArray();
		var ordinals = [];
		for ( var i = 0; i < itemArray.length; i++ ) {
			ordinals.push(itemArray[i].ordinal);
		}
		console.log("new    ordinals");
		doh.assertTrue(util.identicalArrays(ordinals, expectedOrdinals, "ordinals"));
	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
