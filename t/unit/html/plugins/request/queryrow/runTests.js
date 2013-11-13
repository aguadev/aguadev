require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/QueryRow",
	"plugins/form/DndSource",
	"dojo/ready",
	"dojo/domReady!",
	"dojo/dnd/Source"
],

function (
	declare,
	registry,
	dom,
	domAttr,
	domClass,
	parser,
	doh,
	util,
	Agua,
	QueryRow,
	DndSource,
	ready
) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.QueryRow", [

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
		
		var dndSource = new DndSource({});
		console.log("new    dndSource: " + dndSource);
		console.dir({dndSource:dndSource});
		
		// SET FORM INPUTS (TO SET ROW DATA)
		dndSource.formInputs = {
			action 	: 	1,
			field	:	1,
			operator:	1,
			value	:	1
		};

		// SET ROW CLASS
		dndSource.rowClass 	=	"plugins.request.QueryRow";		

		var node 	=	dom.byId("attachPoint");
		console.log("new    node: " + node);
		console.dir({node:node});

		dndSource.initialiseDragSource(node);
		
		domAttr.set(node, 'style', 'width: 380px !important');
		domClass.add(node, "query");
		

		console.log("new    dndSource:");
		console.dir({dndSource:dndSource});

		var itemArray = util.fetchJson("./rows.json");
		console.log("new    itemArray:");
		console.dir({itemArray:itemArray});
		dndSource.loadDragItems(itemArray);

		console.log("new    instantiated");
		//doh.assertTrue(true);
	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
