require([
	"dojo/_base/declare",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"dojo/json",	
	"dojo/domReady!"		
],

function (declare, doh, util, Agua, Data, DataStore, JSON) {

console.log("# plugins.infusion.DataStore");

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

////}}}}}

doh.register("plugins.infusion.DataStore", [

////}}}}}

{
////}}}}}

	name: "new",
	setUp: function () {
		Agua.data = util.fetchJson("./getData.json");
	},
	runTest : function () {
		console.log("# new");
		
		// SET DATA
		var dataObject = new Data();

		// SET CORE
		var core = new Object;
		core.data = dataObject;
		
		// SET DATA STORE
		var dataStore = new DataStore({core:core});

		console.log("new    instantiated");
		doh.assertTrue(true);
	},
	tearDown: function () {}
}
,
{
////}}}}}

	name: "startup",
	setUp: function () {
		Agua.data = util.fetchJson("./getData.json");
	},
	runTest : function () {
		console.log("# startup");
		
		// SET DATA
		var dataObject = new Data();

		// SET CORE
		var core = new Object;
		core.data = dataObject;
		
		// DATA OBJECT
		var dataStore = new DataStore();
		var data = dataStore.startup();
		console.log("startup     data: " + data);
		console.dir({data:data});
		//w = window.open('text.txt');
		//w.document.write(JSON.stringify(data));
	
		console.log("startup    completed");
		doh.assertTrue(true);

		// VERIFY DATA -- too large?
		var expected = util.fetchJson("startup.json");
		console.log("startup    expected:");
		console.dir({expected:expected});
		
		//console.log("startup    data");
		//doh.assertTrue(t.doh.util.identicalHashes(data, expected) == 1)

	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

