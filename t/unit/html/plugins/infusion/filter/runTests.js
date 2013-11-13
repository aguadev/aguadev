require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/_base/lang",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Filter",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"dojo/domReady!"		
],

function (declare, registry, lang, doh, util, Agua, Filter, Data, DataStore) {

window.Agua = Agua;

var url = "getData.json";
var dataObject;
var dataStore;
var core;
var filter;
var TestFilter = declare([Filter, Data], {
	constructor : function(args) {		
		console.log("TestFilter.constructor    args:");
		console.dir({args:args});
		
		if ( ! args )	return;
		
		// MIXIN ARGS
		lang.mixin(this, args);
	
		// SET core.lists
		if ( ! this.core ) 	this.core = new Object;
	}
});

////}}}}}

//select * from status where status = "hold" or status="active" or status="complete" or status = "cancelled";
//+-----------+-----------+---------------------------------+
//| status_id | status    | description                     |
//+-----------+-----------+---------------------------------+
//|        63 | active    | the sample or project is active |
//|        28 | cancelled | sample was cancelled altogether |
//|        58 | complete  | project complete                |
//|        19 | hold      | wait                            |
//+-----------+-----------+---------------------------------+

////}}}}}

doh.register(" plugins.infusion.Filter", [

////}}}}}

{

////}}}}}

	name: "filterByStatus",
	setUp: function(){
		// CREATE DATA
		dataObject = new Data();
		
		Agua.data = {};
		Agua.data.project = util.fetchJson("filterByStatus-project.json");
		Agua.data.status = util.fetchJson("filterByStatus-status.json");
		
		// CREATE DATASTORE
		dataStore = new DataStore();
		dataStore.startup();
		
		// SET CORE
		core = new Object();
		core.data = dataObject;
		core.dataStore = dataStore;
		
		
		filter = new TestFilter({
			core	:	core
		});
	},
	runTest : function(){

		console.log("# filterByStatus");

		var array = util.fetchJson("filterByStatus-projectsArray.json");
		
		// ACTIVE PROJECTS
		var active = filter.filterByStatus("project", "project_name", array, "Active");
		console.log("filterByStatus    active: " + active);
		console.dir({active:active});

console.log("HERE");

		var expectedActive = util.fetchJson("filterByStatus-expectedActive.json");
		console.log("filterByStatus    active projects");
		doh.assertTrue(util.identicalArrays(active, expectedActive), "active projects");
console.log("HERE 2");

		// COMPLETED PROJECTS
		var complete = filter.filterByStatus("project", "project_name", array, "Complete");
		console.log("filterByStatus    complete: " + complete);
		console.dir({complete:complete});
		var expectedComplete = util.fetchJson("filterByStatus-expectedComplete.json");
		console.log("filterByStatus    complete projects");
		doh.assertTrue(util.identicalArrays(complete, expectedComplete), "complete projects");	
		
		// HOLD PROJECTS
		var hold = filter.filterByStatus("project", "project_name", array, "Hold");
		//console.log("filterByStatus    hold: " + hold);
		//console.dir({hold:hold});
		var expectedhold = util.fetchJson("filterByStatus-expectedHold.json");
		console.log("filterByStatus    hold projects");
		doh.assertTrue(util.identicalArrays(hold, expectedhold), "hold projects");	

		// CANCELLED PROJECTS
		var cancelled = filter.filterByStatus("project", "project_name", array, "Cancelled");
		//console.log("filterByStatus    cancelled: " + cancelled);
		//console.dir({cancelled:cancelled});
		var expectedCancelled = util.fetchJson("filterByStatus-expectedCancelled.json");
		console.log("filterByStatus    cancelled projects");
		doh.assertTrue(util.identicalArrays(cancelled, expectedCancelled), "cancelled projects");	

	},
	tearDown: function () {}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

