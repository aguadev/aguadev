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

console.log("# plugins.infusion.Data");

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

// DATA URL
var url 	= 	"./getData.json";

////}}}}}


doh.register("plugins.infusion.Data", [

////}}}}}

//{
//////}}}}}
//
//	name: "getItems",
//	setUp: function () {
//		Agua.data = util.fetchJson(url);
//	},
//	runTest : function () {
//		console.log("# getItems");
//		
//		// DATA OBJECT
//		var dataObject = new Data();
//
//		// GENERATE DATA
//		var items = dataObject.getItems();
//		//console.log("getItems    items:");
//		//console.dir({items:items});
//		//w = window.open('text.txt');
//		//w.document.write(JSON.stringify(items));
//
//		// GET EXPECTED
//		var expectedItems = util.fetchJson("./getItems.json");
//		//console.log("getItems    expectedItems:");
//		//console.dir({expectedItems:expectedItems});
//
//		// TEST
//		console.log("getItems    items");
//		doh.assertTrue(util.identicalArrayHashes(items, expectedItems));
//	},
//	tearDown: function () {}
//}
//,
//{
//////}}}}}
//
//	name: "addSamplesWithoutLanes",
//	setUp: function () {
//		Agua.data = util.fetchJson(url);
//		//console.log("addSamplesWithoutLanes    Agua.data:");
//		//console.dir({Agua_data:Agua.data});
//	},
//	runTest : function () {
//		console.log("# addSamplesWithoutLanes");
//		
//		// DATA OBJECT
//		var dataObject = new Data();
//
//		var lanes = Agua.data.lane;
//		//console.log("addSamplesWithoutLanes    lanes:");
//		//console.dir({lanes:lanes});
//		
//		// ADD SAMPLE WITHOUT LANES
//		var sample = {
//			project_id		:	1000000,
//			project_name	:	"Test Project",
//			sample_id		:	"99999999",
//			sample_barcode	:	"ABC123",
//			sample_name		:	"XYZ000"
//		};
//		Agua.data.sample.push(sample);
//		
//		// GENERATE DATA
//		//console.log("addSamplesWithoutLanes    BEFORE lanes.length: " + lanes.length);
//		lanes = dataObject.addSamplesWithoutLanes(lanes);
//		//console.log("addSamplesWithoutLanes    AFTER lanes.length: " + lanes.length);
//
//		var added = lanes.pop();
//		//console.log("addSamplesWithoutLanes    added:");
//		//console.dir({added:added});
//		
//		// TEST
//		console.log("addSamplesWithoutLanes    added");
//		doh.assertTrue(util.identicalHashes(sample, added));
//	},
//	tearDown: function () {}
//}
//,
//{
//////}}}}}
//
//	name: "generateData",
//	setUp: function () {
//		//console.log("generateData    fetching url: " + url);
//		Agua.data = util.fetchJson(url);
//		//console.log("generateData    Agua.data: ");
//		//console.dir({Agua_data:Agua.data});
//	},
//	runTest : function () {
//		console.log("# generateData");
//		//console.log("generateData    thisObject: ");
//		//console.dir({thisObject:thisObject});
//
//		// DATA OBJECT
//		var dataObject = new Data();
//		
//		//	Default list of keys for thisObject.storedHashes
//		var dataKeys = [
//			"project::hash::project_id::project_name",
//			"project::objectHash::project_id::project_name",	
//			"sample::hash::sample_id::project_id",
//			"sample::hash::sample_id::sample_name",
//			"sample::hash::sample_id::sample_barcode",
//			"flowcell::hash::flowcell_id::flowcell_barcode"
//		];
//		
//		// GENERATE DATA
//		dataObject.flushData();
//		dataObject.generateData(dataKeys);
//		
//		// CHECK HASH
//		var expected = util.fetchJson("./projectIdNameHash.json");
//		var projectIdNameHash = dataObject.getHash("project", "hash", "project_id", "project_name");
//		//console.log("generateData    util.identicalHashes(projectIdNameHash, expected): " + util.identicalHashes(projectIdNameHash, expected));
//		console.log("generateData    projectIdNameHash");
//		doh.assertTrue(util.identicalHashes(projectIdNameHash, expected));
//	
//		// CHECK HASHKEYS
//		var keys = util.getHashKeys(dataObject.storedHashes);
//		//console.log("generateData    keys: ");
//		//console.dir({keys:keys});
//		//console.log("generateData    util.identicalArrays(keys, dataKeys): " + util.identicalArrays(keys, dataKeys));
//		console.log("generateData    keys");
//		doh.assertTrue(util.identicalArrays(keys, dataKeys));
//	},
//	tearDown: function () {}
//}
//,
//
//{
//////}}}}}
//
//	name: "getHash",
//	setUp: function () {
//		//console.log("getHash    fetching url: " + url);
//		Agua.data = util.fetchJson(url);
//		//console.log("getHash    Agua.data: ");
//		//console.dir({Agua_data:Agua.data});
//	},
//	runTest : function () {
//		console.log("# getHash");
//
//		// DATA OBJECT
//		var dataObject = new Data();
//
//		//	Default list of keys for thisObject.storedHashes
//		var dataKeys = [
//			"project::hash::project_id::project_name",
//			"project::objectHash::project_name",	
//			"sample::hash::sample_id::project_id",
//			"sample::hash::sample_id::sample_name",
//			"sample::hash::sample_id::sample_barcode",
//			"flowcell::hash::flowcell_id::flowcell_barcode"
//		];
//		
//		// GENERATE DATA
//		dataObject.flushData();
//		dataObject.generateData(dataKeys);
//		
//		// CHECK FAIL
//		var emptyHash = dataObject.getHash("DOES NOT EXIST", "objectHash", "project_name");
//		console.log("getHash    NONEXISTENT table");
//		doh.assertEqual(emptyHash, {});
//
//		// CHECK objectHash
//		var projectName = "CHUM_Rouleau1";
//		var expectedObjectHash = util.fetchJson("./CHUM_Rouleau1.json");
//		var objectHash = dataObject.getHash("project", "objectHash", "project_name")[projectName];
//		console.log("getHash    objectHash");
//		doh.assertTrue(util.identicalHashes(objectHash, expectedObjectHash));
//
//		// CHECK objectArrayHash
//		var expectedObjectArrayHash = util.fetchJson("./objectArrayHash.json");
//		var objectArrayHash = dataObject.getHash("lane", "objectArrayHash", "sample_id");
//		//console.log("getHash    objectArrayHash");
//		//console.dir({objectArrayHash:objectArrayHash});
//		//w = window.open('text.txt');
//		//w.document.write(JSON.stringify(objectArrayHash));
//		doh.assertTrue(util.identicalArrayHashes(objectArrayHash, expectedObjectArrayHash));
//	},
//	tearDown: function () {}
//}
//,
//{
//
///////}}}}}}
//
//	name: "updateTable",
//	setUp: function(){
//		Agua.data = util.fetchJson(url);
//	},
//	runTest : function(){
//
//		console.log("# updateTable");
//	
//		var tests = [
//			{
//				table	:	"project",
//				key		:	"project_name",
//				data 	: 	{
//					project_id 				: 	116,
//					project_name 			: 	"CHUM_XXX",					//	CHANGED
//					description				: 	"Study of HUMAN viruses",	//	CHANGED
//					build_version			:	"NCBI36",					//	CHANGED
//					dbsnp_version			:	129,						//	CHANGED
//					include_NPF				:	"N",
//					project_manager			:	"A Manager",
//					data_analyst			:	"An Analyst",
//					build_location			:	"/path/to/build",
//					project_policy			:	"--build somePolicy"
//				}
//			}
//		];
//
//		// DATA OBJECT
//		var dataObject = new Data();
//
//		for ( var i in tests ) {
//			var test = tests[i];
//
//			// RETRIEVE DATA FOR PROJECT
//			var key = test.key;
//			var table = test.table;
//			//console.log("updateTable    key: " + key);
//			var getter = "get" + table.substring(0,1).toUpperCase() + table.substring(1) + "Object";
//			//console.log("updateTable    getter: " + getter);
//			
//			var data = dataObject[getter](test.data[key]);
//			//console.log("updateTable    data: ");
//			//console.dir({data:data});
//			
//			console.log("updateTable    failed");
//			doh.assertFalse(t.doh.util.identicalHashes(data, test.data) == 1)
//
//			//console.log("updateTable    BEFORE this.updateTable(table, data)");
//			dataObject.updateTable(test.table, test.data);
//			console.log("updateTable    AFTER this.updateTable(table, data)");
//	
//			data = dataObject[getter](test.data[key]);
//			//console.log("updateTable    data: ");
//			//console.dir({data:data});
//
//			console.log("updateTable    success");
//			doh.assertTrue(t.doh.util.identicalHashes(data, test.data) == 1)
//
//
//		}
//	}
//}
//,
{

/////}}}}}}

	name: "addSamples",
	setUp: function(){
		Agua.data = util.fetchJson(url);
	},
	runTest : function(){

		console.log("# addSamples");
	
		var tests = [
			{
				table	:	"sample",
				key		:	"sample_id",
				data 	: 	[
					{
						sample_id:	"1",
					   project_id:	"1",
				   sample_barcode:	"LP0022845-DNA_A01",
					  sample_name:	"NACC498348",
					plate_barcode:	"LP0022845-DNA",
						  species:	"Human",
						   gender:	"U",
						   volume:	"100",
					concentration:	"70",
					   od_260_280:	"1.99",
					tissue_source:	"Blood",
				extraction_method:	"Perlegen",
						ethnicity:	"Caucasian",
			   parent_1_sample_id:	"NULL",
			   parent_2_sample_id:	"NULL",
					replicates_id:	"NULL",
						   cancer:	"N",
				 match_sample_ids:	"NULL",
				match_sample_type:	"NULL",
						  comment:	"NACC498348",
						 due_date:	"NULL",
			 target_fold_coverage:	"30",
						gt_gender:	"M",
						 do_build:	"yes",
						status_id:	"50",
					sample_policy:	"NULL",
					  update_date:	"2012-12-11 01:01:20",
				   delivered_date:	"2011-12-28",
				  genotype_report:	"/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GenotypingReports/FinalReport_HumanOmni2.5-8v1_LP0022845-DNA_A01.txt",
					 gt_deliv_src:	"/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GT_Deliverables/LP0022845-DNA_A01",
				 user_code_and_ip:	"NULL",
							 FTAT:	"N",
						 analysis:	"NULL",
					 gt_call_rate:	"NULL",
						gt_p99_cr:	"NULL",
					},
					{
						sample_id:	"2",
					   project_id:	"1",
				   sample_barcode:	"LP0022845-DNA_B01",
					  sample_name:	"NACC310566",
					plate_barcode:	"LP0022845-DNA",
						  species:	"Human",
						   gender:	"U",
						   volume:	"100",
					concentration:	"70",
					   od_260_280:	"2.06",
					tissue_source:	"Blood",
				extraction_method:	"Perlegen",
						ethnicity:	"Caucasian",
			   parent_1_sample_id:	"NULL",
			   parent_2_sample_id:	"NULL",
					replicates_id:	"NULL",
						   cancer:	"N",
				 match_sample_ids:	"NULL",
				match_sample_type:	"NULL",
						  comment:	"NACC310566",
						 due_date:	"NULL",
			 target_fold_coverage:	"30",
						gt_gender:	"NULL",
						 do_build:	"yes",
						status_id:	"63",
					sample_policy:	"NULL",
					  update_date:	"2012-10-08 19:06:41",
				   delivered_date:	"NULL",
				  genotype_report:	"NULL",
					 gt_deliv_src:	"NULL",
				 user_code_and_ip:	"NULL",
							 FTAT:	"N",
						 analysis:	"NULL",
					 gt_call_rate:	"NULL",
						gt_p99_cr:	"NULL",
					},
					{
						sample_id:	"3",
					   project_id:	"1",
				   sample_barcode:	"LP0022845-DNA_C01",
					  sample_name:	"NACC856571",
					plate_barcode:	"LP0022845-DNA",
						  species:	"Human",
						   gender:	"U",
						   volume:	"100",
					concentration:	"70",
					   od_260_280:	"2.03",
					tissue_source:	"Blood",
				extraction_method:	"Perlegen",
						ethnicity:	"Caucasian",
			   parent_1_sample_id:	"NULL",
			   parent_2_sample_id:	"NULL",
					replicates_id:	"NULL",
						   cancer:	"N",
				 match_sample_ids:	"NULL",
				match_sample_type:	"NULL",
						  comment:	"NACC856571",
						 due_date:	"NULL",
			 target_fold_coverage:	"30",
						gt_gender:	"M",
						 do_build:	"yes",
						status_id:	"50",
					sample_policy:	"NULL",
					  update_date:	"2012-12-11 01:01:20",
				   delivered_date:	"2011-12-28",
				  genotype_report:	"/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GenotypingReports/FinalReport_HumanOmni2.5-8v1_LP0022845-DNA_C01.txt",
					 gt_deliv_src:	"/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GT_Deliverables/LP0022845-DNA_C01",
				 user_code_and_ip:	"NULL",
							 FTAT:	"N",
						 analysis:	"NULL",
					 gt_call_rate:	"NULL",
						gt_p99_cr:	"NULL",
					}
				]
			}
		];

		// DATA OBJECT
		var dataObject = new Data();

		for ( var i in tests ) {
			var test = tests[i];

			Agua.data.sample = [];

			// ADD DATA
			var samples = test.data;
			dataObject.addSamples(samples);
			
			var added = Agua.data.sample;
			
			console.log("addSamples    success");
			doh.assertTrue(t.doh.util.identicalHashes(samples, added) == 1)
		}
	}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

