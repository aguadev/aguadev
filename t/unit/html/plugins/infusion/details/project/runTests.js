require([
	"dojo/_base/declare",
	"dojo/dom",
	"dijit/registry",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Details/Project",
	"dojo/ready",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojo/domReady!"
],

function (declare, dom, registry, doh, util, Agua, Data, DataStore, ProjectDetails, ready) {

console.log("# plugins.infusion.Detailed.Project");

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;
	
// GLOBALS
var dataObject;
var dataStore;
var core;
var url 	= "./getData.json";	

/////}}}}}}
doh.register("plugins.infusion.Detailed.Project", [
/////}}}}}}

{
/////}}}}}}
	name: "getSamples",
	setUp: function(){
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
	},
	runTest : function(){
		console.log("# getSamples");

		// CREATE INSTANCE OF Detailed.Project
		var projectDetails = new ProjectDetails({
			core: core
		});
		console.log("AFTER new ProjectDetails");
		
		// ATTACH GRID TO PAGE
		var attachPoint = dom.byId("attachPoint");
		attachPoint.appendChild(projectDetails.containerNode)

		// GET SAMPLES
		var projectName = "CHUM_Rouleau1";
		var samples = projectDetails.getSamples(projectName);
		console.log("AFTER ProjectDetails.getSamples(" + projectName + ")");
		
		// GET EXPECTED
		var expectedSamples = util.fetchJson("./samples.json");
		
		// TEST
		console.log("getSamples    samples");
		doh.assertTrue(util.identicalArrayHashes(samples, expectedSamples));
	}
}
,
{
/////}}}}}}
	name: "getLaneStats",
	setUp: function () {
		data = util.fetchJson(url);
		Agua.data = data;

		// CREATE DATA
		dataObject = new Data();
		
		// CREATE DATASTORE
		dataStore = new DataStore();
		dataStore.startup();

		// SET CORE
		core = new Object();
		core.data = dataObject;
		core.dataStore = dataStore;
	},
	runTest : function () {
		console.log("# getLaneStats");

		// CREATE INSTANCE OF Detailed.Project
		var projectDetails = new ProjectDetails({
			core: core
		});
		projectDetails.getTable = function (table) {
			return Agua.cloneData(table);
		};

		// CHUM_Rouleau1
		//var sampleBarcode = "LP6005059-DNA_H01";
		var sampleBarcode = "LP6005057-DNA_B01";
		var samples = Agua.cloneData("sample");
		//console.log("getLaneStats    samples: ");
		//console.dir({samples:samples});

		// GET SAMPLE BARCODE VS SAMPLE ID HASH
		var sampleBarcodeIdHash = projectDetails.getHash("sample", "hash", "sample_barcode", "sample_id");
		//console.log("getLaneStats    sampleBarcodeIdHash: ");
		//console.dir({sampleBarcodeIdHash:sampleBarcodeIdHash});

		// GET SAMPLE OBJECT
		var sampleId = sampleBarcodeIdHash[sampleBarcode];
		//console.log("getLaneStats    sampleId: " + sampleId);
		var sample = Agua._getObjectByKeyValue(samples, "sample_id", sampleId);
		//console.log("getLaneStats    sample: ");
		//console.dir({sample:sample});
		
		// GET LANES
		var sampleIdLanesObjectArrayHash = projectDetails.getHash("lane", "objectArrayHash", "sample_id");
		var lanes = sampleIdLanesObjectArrayHash[sampleId];
		//console.log("getLaneStats    lanes:");
		//console.dir({lanes:lanes});
		
		// GET LANE STATS
		var laneStats = projectDetails.getLaneStats(sample, lanes);
		//console.log("getLaneStats    laneStats: ");
		//console.dir({laneStats:laneStats});	
	
		expected = {
			total_lanes		:	5,
			bad_lanes		: 	2,
			good_lanes		:	3,
			sequencing_lanes: 	0, 	
			requeued_lanes	: 	0
		};
		
		var fields = [
			"total_lanes",
			"bad_lanes",
			"good_lanes",
			"sequencing_lanes", 	
			"requeued_lanes"
		];
		console.log("getLaneStats    laneStats");
		doh.assertTrue(t.doh.util.identicalFields(laneStats, expected, fields));
	},
	tearDown: function () {}
}
,
{
/////}}}}}}
	name: "getYieldStats",
	setUp: function(){
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
	},
	runTest : function(){
		console.log("# getYieldStats");
				
		// CREATE INSTANCE OF Detailed.Project
		var projectDetails = new ProjectDetails({
			core: core
		});
		
		projectDetails.getTable = function (table) {
			return Agua.cloneData(table);
		};
		//console.log("getYieldStats    projectDetails: ");
		//console.dir({projectDetails:projectDetails});

		var sampleBarcode = "LP6005059-DNA_H01";
		//console.log("getYieldStats    sampleBarcode: " + sampleBarcode);
		//console.log("getYieldStats    DOING Agua.cloneData");
		var samples = Agua.cloneData("sample");
		//console.log("getYieldStats    samples: ");
		//console.dir({samples:samples});
		
		// GET SAMPLE BARCODE VS SAMPLE ID HASH
		var sampleBarcodeIdHash = projectDetails.getHash("sample", "hash", "sample_barcode", "sample_id");
		//console.log("getYieldStats    sampleBarcodeIdHash: ");
		//console.dir({sampleBarcodeIdHash:sampleBarcodeIdHash});

		// GET SAMPLE OBJECT
		var sampleId = sampleBarcodeIdHash[sampleBarcode];
		//console.log("getYieldStats    sampleId: " + sampleId);
		var sample = Agua._getObjectByKeyValue(samples, "sample_id", sampleId);
		//console.log("getYieldStats    sample: ");
		//console.dir({sample:sample});
		
		// GET LANES
		var lanes = projectDetails.getLanes(sampleId);
		
		// GET LANE STATS
		sample = projectDetails.getLaneStats(sample, lanes);

		// GET YIELD STATS
		var yieldStats = projectDetails.getYieldStats(sample, lanes);
		//console.log("getYieldStats    yieldStats: ");
		//console.dir({yieldStats:yieldStats});
	
		expected = {
			trimmed_yield	:	93.93,
			aligned_yield	: 	82.50,
			estimated_yield	:	93.93,
			missing_yield	: 	11.07, 	
			need_lanes		: 	1
		};
		
		var fields = [
			"trimmed_yield",
			"aligned_yield",
			"estimated_yield",
			"missing_yield",
			"need_lanes"
		];
		console.log("getYieldStats    yieldStats");
		doh.assertTrue(t.doh.util.identicalFields(yieldStats, expected, fields));
	}
}
,
{
/////}}}}}}
	name: "updateGrid",
	setUp: function () {
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
	},
	runTest : function(){
		console.log("# updateGrid");
		
		var tabContainer = new dijit.layout.TabContainer({
			style: "height: 100%; max-height: 130px !important; width: 100%;",
			tabStrip 	: 	true,
			title		:	"Lane"
		},
		"attachPoint");
		tabContainer.startup();		

		// CREATE INSTANCE OF Detailed.Project
		var projectDetails = new ProjectDetails({
			attachPoint 	:	registry.byId("attachPoint"),
			core			: 	core,
			title			:	"Lanes",
			label			:	"Lanes"				
		});
				
		// UPDATE GRID
		var projectName = "CHUM_Rouleau1";
		projectDetails.updateGrid(projectName);
		
		// ASSERT TRUE - NO ERRORS WHILE LOADING
		console.log("updateGrid    true");
		doh.assertTrue(true);
	}
}


	
]);

// Execute D.O.H.
doh.run();


});
