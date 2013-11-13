require([
	"dojo/_base/declare",
	"doh/runner",
	"t/plugins/dojo/declare/MyClass",
	"t/plugins/dojo/declare/MySubClass",
	"t/plugins/dojo/declare/OtherClass",
	"t/plugins/dojo/declare/AnotherClass",
	"t/plugins/dojo/declare/MixinClass",
	"dojo/domReady!"
],

//function (declare, doh, MyClass) {
function (declare, doh, MyClass, MySubClass, OtherClass, AnotherClass, MixinClass) {
	console.log("runTests    MyClass.color: " + MyClass.color);
	console.dir({MyClass:MyClass});
	console.log("runTests    MyClass:");

	var myClass = new MyClass();
	console.log("runTests    myClass:");
	console.dir({myClass:myClass});
	console.log("runTests    myClass.color: " + myClass.color);

	//var mixinClass = new MixinClass();
	//console.log("runTests    mixinClass:");
	//console.dir({mixinClass:mixinClass});

	
	console.log("runTests    MySubClass:");
	console.dir({MySubClass:MySubClass});
	console.log("runTests    OtherClass:");
	console.dir({OtherClass:OtherClass});
	console.log("runTests    AnotherClass:");
	console.dir({AnotherClass:AnotherClass});
	console.log("runTests    MixinClass:");
	console.dir({MixinClass:MixinClass});
	
	console.log("runTests    MixinClass.color: " + MixinClass.color);

	var mixinClass = new MixinClass();
	console.log("runTests    mixinClass:");
	console.dir({MixinClass:MixinClass});
	console.log("runTests    mixinClass.color: " + mixinClass.color);

	
	
	doh.register("Infusion.Detailed.Project", [
		//{
		//	name: "getSamples",
		//	setUp: function(){
		//
		//		console.log("getSamples    setUp    fetching url: " + url);
		//		data = util.fetchJson(url);
		//		console.log("getSamples    setUp    data: ");
		//		console.dir({data:data});
		//		Agua.data = data;
		//	},
		//	runTest : function(){
		//
		//		// CREATE INSTANCE OF Data
		//		var dataObject = new Data();
		//		//console.log("getSamples    runTests    dataObject:");
		//		//console.dir({dataObject:dataObject});
		//		
		//		// USE THIS BECAUSE Agua OUT OF SCOPE IN Data	
		//		dataObject.getTable = function (table) {
		//			return Agua.cloneData(table);
		//		};
		//		dataObject.initialiseData();
		//		
		//		// CREATE INSTANCE OF Detailed.Project
		//		var detailedProject = new DetailedProject({
		//			parent: dataObject
		//		});
		//		detailedProject.getTable = function (table) {
		//			return Agua.cloneData(table);
		//		};
		//		//console.log("runTests    detailedProject: ");
		//		//console.dir({detailedProject:detailedProject});
		//		
		//		// GET SAMPLES
		//		var projectName = "CHUM_Rouleau1";
		//		var samples = detailedProject.getSamples(projectName);
		//		console.log("getSamples    samples: ");
		//		//w = window.open('text.txt');
		//		//w.document.write(JSON.stringify(samples));
		//		
		//		// GET EXPECTED
		//		var expectedSamples = util.fetchJson("./samples.json");
		//		console.log("getHash    expectedSamples:");
		//		console.dir({expectedSamples:expectedSamples});
		//		
		//		// TEST
		//		doh.assertTrue(util.identicalArrayHashes(samples, expectedSamples));
		//	}
		//}
		//,
		//{
		//	name: "getLaneStats",
		//	setUp: function(){
		//		console.log("setUp    fetching url: " + url);
		//		data = util.fetchJson(url);
		//		console.log("setUp    data: ");
		//		console.dir({data:data});
		//		Agua.data = data;
		//	},
		//	runTest : function(){
		//		// CREATE INSTANCE OF Data
		//		var dataObject = new Data();
		//		dataObject.getTable = function (table) {
		//			return Agua.cloneData(table);
		//		};
		//		dataObject.initialiseData();
		//		//console.log("getSamples    runTests    dataObject:");
		//		//console.dir({dataObject:dataObject});				
		//		
		//		// CREATE INSTANCE OF Detailed.Project
		//		var detailedProject = new DetailedProject({
		//			parent: dataObject
		//		});
		//		detailedProject.getTable = function (table) {
		//			return Agua.cloneData(table);
		//		};
		//		//console.log("runTests    detailedProject: ");
		//		//console.dir({detailedProject:detailedProject});
		//
		//		// CHUM_Rouleau1
		//		//var sampleBarcode = "LP6005059-DNA_H01";
		//		var sampleBarcode = "LP6005057-DNA_B01";
		//		console.log("getLaneStats    sampleBarcode: " + sampleBarcode);
		//		
		//		console.log("getLaneStats    DOING Agua.cloneData");
		//		var samples = Agua.cloneData("sample");
		//		console.log("getLaneStats    samples: ");
		//		console.dir({samples:samples});
		//
		//		// GET SAMPLE BARCODE VS SAMPLE ID HASH
		//		var sampleBarcodeIdHash = detailedProject.getHash("sample", "hash", "sample_barcode", "sample_id");
		//		console.log("getLaneStats    sampleBarcodeIdHash: ");
		//		console.dir({sampleBarcodeIdHash:sampleBarcodeIdHash});
		//
		//		// GET SAMPLE OBJECT
		//		var sampleId = sampleBarcodeIdHash[sampleBarcode];
		//		console.log("getLaneStats    sampleId: " + sampleId);
		//		var sample = Agua._getObjectByKeyValue(samples, "sample_id", sampleId);
		//		console.log("getLaneStats    sample: ");
		//		console.dir({sample:sample});
		//		
		//		// GET LANES
		//		var sampleIdLanesObjectArrayHash = detailedProject.getHash("lane", "objectArrayHash", "sample_id");
		//		var lanes = sampleIdLanesObjectArrayHash[sampleId];
		//		//console.log("getLaneStats    lanes:");
		//		//console.dir({lanes:lanes});
		//		
		//		// GET LANE STATS
		//		var laneStats = detailedProject.getLaneStats(sample, lanes);
		//		//console.log("getLaneStats    laneStats: ");
		//		//console.dir({laneStats:laneStats});	
		//	
		//		expected = {
		//			total_lanes		:	5,
		//			bad_lanes		: 	2,
		//			good_lanes		:	3,
		//			sequencing_lanes: 	0, 	
		//			requeued_lanes	: 	0
		//		};
		//		
		//		var fields = [
		//			"total_lanes",
		//			"bad_lanes",
		//			"good_lanes",
		//			"sequencing_lanes", 	
		//			"requeued_lanes"
		//		];
		//		console.log("getLaneStats    identicalFields");
		//		doh.assertTrue(t.doh.util.identicalFields(laneStats, expected, fields));
		//	},
		//	tearDown: function () {
		//
		//	}
		//}
		//,
		//{
		//	name: "getYieldStats",
		//	setUp: function(){
		//		console.log("setUp    fetching url: " + url);
		//		data = util.fetchJson(url);
		//		console.log("setUp    data: ");
		//		console.dir({data:data});
		//		Agua.data = data;
		//	},
		//	runTest : function(){
		//		// CREATE INSTANCE OF Data
		//		var dataObject = new Data();
		//		dataObject.getTable = function (table) {
		//			return Agua.cloneData(table);
		//		};
		//		dataObject.initialiseData();
		//		//console.log("getYieldStats    getYieldStats    dataObject:");
		//		//console.dir({dataObject:dataObject});				
		//		
		//		// CREATE INSTANCE OF Detailed.Project
		//		var detailedProject = new DetailedProject({
		//			parent: dataObject
		//		});
		//		detailedProject.getTable = function (table) {
		//			return Agua.cloneData(table);
		//		};
		//		//console.log("getYieldStats    detailedProject: ");
		//		//console.dir({detailedProject:detailedProject});
		//
		//		var sampleBarcode = "LP6005059-DNA_H01";
		//		console.log("getYieldStats    sampleBarcode: " + sampleBarcode);
		//		//console.log("getYieldStats    DOING Agua.cloneData");
		//		var samples = Agua.cloneData("sample");
		//		//console.log("getYieldStats    samples: ");
		//		//console.dir({samples:samples});
		//		
		//		// GET SAMPLE BARCODE VS SAMPLE ID HASH
		//		var sampleBarcodeIdHash = detailedProject.getHash("sample", "hash", "sample_barcode", "sample_id");
		//		//console.log("getYieldStats    sampleBarcodeIdHash: ");
		//		//console.dir({sampleBarcodeIdHash:sampleBarcodeIdHash});
		//
		//		// GET SAMPLE OBJECT
		//		var sampleId = sampleBarcodeIdHash[sampleBarcode];
		//		console.log("getYieldStats    sampleId: " + sampleId);
		//		var sample = Agua._getObjectByKeyValue(samples, "sample_id", sampleId);
		//		//console.log("getYieldStats    sample: ");
		//		//console.dir({sample:sample});
		//		
		//		// GET LANES
		//		var lanes = detailedProject.getLanes(sampleId);
		//		
		//		// GET LANE STATS
		//		sample = detailedProject.getLaneStats(sample, lanes);
		//
		//		// GET YIELD STATS
		//		var yieldStats = detailedProject.getYieldStats(sample, lanes);
		//		console.log("getYieldStats    yieldStats: ");
		//		console.dir({yieldStats:yieldStats});
		//	
		//		expected = {
		//			trimmed_yield	:	93.93,
		//			aligned_yield	: 	82.50,
		//			estimated_yield	:	93.93,
		//			missing_yield	: 	11.07, 	
		//			need_lanes		: 	1
		//		};
		//		
		//		var fields = [
		//			"trimmed_yield",
		//			"aligned_yield",
		//			"estimated_yield",
		//			"missing_yield",
		//			"need_lanes"
		//		];
		//		doh.assertTrue(t.doh.util.identicalFields(yieldStats, expected, fields));
		//	},
		//	tearDown: function () {
		//
		//	}
		//}
	]);

	//Execute D.O.H. in this remote file.
	doh.run();
});


					//FTAT: "N",
					//analysis: null,
					//cancer: "N",
					//comment: null,
					//concentration: "55",
					//delivered_date: "2012-06-14",
					//do_build: "yes",
					//due_date: null,
					//ethnicity: "Ashkenazi Jew",
					//extraction_method: "Qiagen",
					//gender: "U",
					//genotype_report: "/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GenotypingReports/FinalReport_HumanOmni2.5-8v1_LP6005059-DNA_H01.txt",
					//gt_call_rate: null,
					//gt_deliv_src: "/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GT_Deliverables/LP6005059-DNA_H01",
					//gt_gender: "M",
					//gt_p99_cr: null,
					//match_sample_ids: null,
					//match_sample_type: null,
					//od_260_280: "1.88",
					//parent_1_sample_id: null,
					//parent_2_sample_id: null,
					//plate_barcode: null,
					//project_id: "107",
					//replicates_id: null,
					//sample_barcode: "LP6005059-DNA_H01",
					//sample_id: "3423",
					//sample_name: "BP221014",
					//sample_policy: null,
					//sequencing_lanes: 0,
					//species: "Human",
					//status_id: "50",
					//target_fold_coverage: "30",
					//tissue_source: "Whole Blood",
					//update_date: "2012-12-11 01:01:30",
					//user_code_and_ip: null,
					//volume: "100"
