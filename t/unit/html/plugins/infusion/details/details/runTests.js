require([
	"dojo/_base/declare",
	"dojo/dom",
	"dijit/registry",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Details",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"dojo/ready",
	"dojo/domReady!",
	"dijit/layout/ContentPane",
	"dijit/layout/BorderContainer",
	"dijit/layout/TabContainer"
],

function (declare, dom, registry, doh, util, Agua, Details, Data, DataStore, ready) {

// GLOBAL VARIABLES
window.Agua = Agua;
var details;
var dataObject;
var dataStore;
var core;
var url 	= "./getData.json";	

Agua.data = util.fetchJson(url);

// CREATE DATA
dataObject = new Data();

// CREATE DATASTORE
dataStore = new DataStore();
dataStore.startup();

// SET CORE
core = new Object();
core.data = dataObject;
core.dataStore = dataStore;

var tabContainer = new dijit.layout.TabContainer({
	style: "height: 100%; max-height: 130px !important; width: 100%;",
	tabStrip 	: 	true,
	title		:	"Lane"
},
"attachPoint");
tabContainer.startup();		

////}}}}}

doh.register("plugins.infusion.Details", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
	},
	runTest : function(){
		console.log("# new");
		
		details = new Details({
			attachPoint 	:	registry.byId("attachPoint"),
			core			: 	core,
			title			:	"Lanes",
			label			:	"Lanes"				
		});
		details.setPanes();
		
	},
	tearDown: function () {}
}
,
{
/////}}}}}}
	name: "showDetails",
	setUp: function () {
	},
	runTest : function(){
		console.log("# showDetails");
		
		// UPDATE GRID
		var projectName = "MSKCC_Viale_2";
		var success = details.showDetails("project", projectName);
		
		// ASSERT TRUE - NO ERRORS WHILE LOADING
		console.log("showDetails    projectDetails");
		doh.assertTrue(success);

		// UPDATE GRID - PROJECT
		var sampleBarcode = "SS6004155";
		success = details.showDetails("sample", sampleBarcode);
		
		// ASSERT TRUE - NO ERRORS WHILE LOADING
		console.log("showDetails    projectDetails");
		doh.assertTrue(success);

		// UPDATE GRID - SAMPLE
		var sampleBarcode = "SS6004155";
		success = details.showDetails("sample", sampleBarcode);
		
		// ASSERT TRUE - NO ERRORS WHILE LOADING
		console.log("showDetails    projectDetails");
		doh.assertTrue(success);

		// UPDATE GRID - FLOWCELL
		var flowcellBarcode = "C09LTACXX";
		success = details.showDetails("flowcell", flowcellBarcode);
		
		// ASSERT TRUE - NO ERRORS WHILE LOADING
		console.log("showDetails    projectDetails");
		doh.assertTrue(success);
		
		// UPDATE GRID - LANE
		var laneBarcode = "C09LTACXX_1";
		success = details.showDetails("lane", laneBarcode);
		
		// ASSERT TRUE - NO ERRORS WHILE LOADING
		console.log("showDetails    projectDetails");
		doh.assertTrue(success);
	}
}




]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

