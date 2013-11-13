require([
	"dojo/_base/declare",
	"dojo/dom",
	"dijit/registry",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Details/Sample",
	"dojo/ready",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojo/domReady!"
],

function (declare, dom, registry, doh, util, Agua, Data, DataStore, SampleDetails, TabContainer, ContentPane, ready) {

console.log("# plugins.infusion.Detailed.Sample");

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

var url = "getData.json";
var dataObject;
var dataStore;
var core;

doh.register("Infusion.Detailed.Project", [
{
	name: "setInformation",
	setUp: function(){
		Agua.data = util.fetchJson(url);
		Agua.data.workflow = util.fetchJson("./workflow.json");
		Agua.data.workflowqueue = util.fetchJson("./workflowQueue.json");
		Agua.data.workflowqueuesamplesheet = util.fetchJson("./workflowQueueSamplesheet.json");
		console.log("setInformation    Agua.data: " + Agua.data);		
		console.dir({Agua_data:Agua.data});

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

		var tabContainer = new dijit.layout.TabContainer({
			style: "height: 100%; max-height: 130px !important; width: 100%;",
			tabStrip 	: 	true,
			title		:	"Lane"
		},
		"attachPoint");
		tabContainer.startup();

		// CREATE INSTANCE OF Detailed.Project
		var sampleDetails = new SampleDetails({
			attachPoint 	:	registry.byId("attachPoint"),
			core			: 	core,
			title			:	"Samples",
			label			:	"Samples"				
		});
		
		// UPDATE GRID
		var thisObject = this;
		setTimeout(function(thisObj) {

			// NB: NO LANES
			// var sampleBarcode = "LP6005057-DNA_A01";

			// 7 LANES
			var sampleBarcode = "LP6005059-DNA_H01";
	
			sampleDetails.updateGrid(sampleBarcode);
			
		}, 1500, this);

		//w = window.open('text.txt');
		//w.document.write(JSON.stringify(samples));
		
		// LATER: INTERROGATE GRID TO VERIFY VALUES
		
	}
}
,
{
	name: "getLaneStats",
	setUp: function(){
		console.log("setUp    fetching url: " + url);
		data = util.fetchJson(url);
		console.log("setUp    data: ");
		console.dir({data:data});
		Agua.data = data;
	},
	runTest : function(){
		// CREATE DATA
		dataObject = new Data();
		
		// CREATE DATASTORE
		dataStore = new DataStore();
		dataStore.startup();

		// SET CORE
		core = new Object();
		core.data = dataObject;
		core.dataStore = dataStore;
		
		// CREATE INSTANCE OF Detailed.Project
		var sampleDetails = new SampleDetails({
			core	: core
		});
		sampleDetails.getTable = function (table) {
			return Agua.cloneData(table);
		};
		//console.log("runTests    sampleDetails: ");
		//console.dir({sampleDetails:sampleDetails});

		// CHUM_Rouleau1
		//var sampleBarcode = "LP6005059-DNA_H01";
		var sampleBarcode = "LP6005057-DNA_B01";
		var samples = Agua.cloneData("sample");
		//console.log("getLaneStats    samples: ");
		//console.dir({samples:samples});

		// GET SAMPLE BARCODE VS SAMPLE ID HASH
		var sampleBarcodeIdHash = sampleDetails.getHash("sample", "hash", "sample_barcode", "sample_id");
		//console.log("getLaneStats    sampleBarcodeIdHash: ");
		//console.dir({sampleBarcodeIdHash:sampleBarcodeIdHash});

		// GET SAMPLE OBJECT
		var sampleId = sampleBarcodeIdHash[sampleBarcode];
		//console.log("getLaneStats    sampleId: " + sampleId);
		var sample = Agua._getObjectByKeyValue(samples, "sample_id", sampleId);
		//console.log("getLaneStats    sample: ");
		//console.dir({sample:sample});
		
		// GET LANES
		var sampleIdLanesObjectArrayHash = sampleDetails.getHash("lane", "objectArrayHash", "sample_id");
		var lanes = sampleIdLanesObjectArrayHash[sampleId];
		//console.log("getLaneStats    lanes:");
		//console.dir({lanes:lanes});
		
		// GET LANE STATS
		var laneStats = sampleDetails.getLaneStats(sample, lanes);
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
	name: "getYieldStats",
	setUp: function(){
		Agua.data = util.fetchJson(url);
	},
	runTest : function(){
		// CREATE DATA
		dataObject = new Data();
		
		// CREATE DATASTORE
		dataStore = new DataStore();
		dataStore.startup();

		// SET CORE
		core = new Object();
		core.data = dataObject;
		core.dataStore = dataStore;
		
		// CREATE INSTANCE OF Detailed.Project
		var sampleDetails = new SampleDetails({
			core	: 	core
		});
		sampleDetails.getTable = function (table) {
			return Agua.cloneData(table);
		};
		//console.log("getYieldStats    sampleDetails: ");
		//console.dir({sampleDetails:sampleDetails});

		var sampleBarcode = "LP6005059-DNA_H01";
		//console.log("getYieldStats    sampleBarcode: " + sampleBarcode);
		//console.log("getYieldStats    DOING Agua.cloneData");
		var samples = Agua.cloneData("sample");
		//console.log("getYieldStats    samples: ");
		//console.dir({samples:samples});
		
		// GET SAMPLE BARCODE VS SAMPLE ID HASH
		var sampleBarcodeIdHash = sampleDetails.getHash("sample", "hash", "sample_barcode", "sample_id");
		//console.log("getYieldStats    sampleBarcodeIdHash: ");
		//console.dir({sampleBarcodeIdHash:sampleBarcodeIdHash});

		// GET SAMPLE OBJECT
		var sampleId = sampleBarcodeIdHash[sampleBarcode];
		console.log("getYieldStats    sampleId: " + sampleId);
		var sample = Agua._getObjectByKeyValue(samples, "sample_id", sampleId);
		//console.log("getYieldStats    sample: ");
		//console.dir({sample:sample});
		
		// GET LANES
		var lanes = sampleDetails.getLanes(sampleId);
		
		// GET LANE STATS
		sample = sampleDetails.getLaneStats(sample, lanes);

		// GET YIELD STATS
		var yieldStats = sampleDetails.getYieldStats(sample, lanes);
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
	},
	tearDown: function () {

	}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

