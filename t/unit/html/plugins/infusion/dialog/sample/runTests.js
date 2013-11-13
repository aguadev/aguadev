require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Dialog/Sample",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Data, DataStore, DialogSample, ready) {

console.log("# plugins.infusion.Dialog.Sample");


// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

var url = "getData.json";
Agua.data = util.fetchJson(url);
var dataObject;
//dataObject.getData(Agua.data);
var sampleDialog;

/////}}}}}}

doh.register("plugins.infusion.Dialog.Sample", [

/////}}}}}}

{

/////}}}}}}
	name: "new",
	timeout : 1000,
	setUp: function(){
		//Agua.data = util.fetchJson(url);
	},
	runTest : function(){

		console.log("# new");

		var deferred = new doh.Deferred();

		// CREATE DATA
		dataObject = new Data();
		
		// CREATE DATASTORE
		dataStore = new DataStore();
		dataStore.startup();

		// SET CORE
		var core = new Object();
		core.data = dataObject;
		core.dataStore = dataStore;

		// CREATE INSTANCE OF Dialog.Sample
		sampleDialog = new DialogSample({
			values : {},
			core: core
		});

		setTimeout(function() {
			try {
				console.log("Sample.new    sampleDialog: " + sampleDialog);
				console.dir({sampleDialog:sampleDialog});
	
				// LOAD DATA
				var instantiated = sampleDialog ? true : false;
				console.log("new    instantiated is true: " + instantiated);		
				doh.assertTrue(instantiated);

				//deferred.callback(true);

			}
			catch(e) {
			  deferred.errback(e);
			}
		}, 300);
	}
}
,
{

/////}}}}}}
	name: "populateFields",
	timeout: 1000,
	setUp: function(){
		//Agua.data = util.fetchJson(url);
	},
	runTest : function(){

		console.log("# populateFields");
		var tests = [
			{
				sample_id	:	"1",
			   project_id	:	"1",
		   sample_barcode	:	"LP0022845-DNA_A01",
			  sample_name	:	"NACC498348",
			plate_barcode	:	"LP0022845-DNA",
				  species	:	"Human",
				   gender	:	"U",
				   volume	:	"100",
			concentration	:	"70",
			   od_260_280	:	"1.99",
			tissue_source	:	"Blood",
		extraction_method	:	"Perlegen",
				ethnicity	:	"Caucasian",
	   parent_1_sample_id	:	"",
	   parent_2_sample_id	:	"",
			replicates_id	:	"",
				   cancer	:	"N",
		 match_sample_ids	:	"",
		match_sample_type	:	"",
				  comment	:	"NACC498348",
				 due_date	:	"",
	 target_fold_coverage	:	"30",
				gt_gender	:	"M",
				 do_build	:	"yes",
				status_id	:	"63",
			sample_policy	:	"",
			  update_date	:	"2012-12-11 01:01:20",
		   delivered_date	:	"2011-12-28",
		  genotype_report	:	"/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GenotypingReports/FinalReport_HumanOmni2.5-8v1_LP0022845-DNA_A01.txt",
			 gt_deliv_src	:	"/illumina/scratch/Genotyping_Data/InstituteReports/WGS_GT_Deliverables/LP0022845-DNA_A01",
		 //user_code_and_ip	:	"",
					 FTAT	:	"N",
				 analysis	:	"",
			 gt_call_rate	:	"",
				gt_p99_cr	:	""
			}
		];
		
		for ( var i in tests ) {
			var test = tests[i];
			console.log("populateFields    test:");
			console.dir({test:test});
			
			console.log("populateFields    BEFORE sampleDialog.populateFields(data)");
			sampleDialog.populateFields(test);
			console.log("populateFields    AFTER sampleDialog.populateFields(data)");
			console.log("populateFields    sampleDialog:");
			console.dir({sampleDialog:sampleDialog});
			
			// VERIFY VALUES
			for ( var field in test ) {
				console.log("populateFields    field: " + field);
				var name = sampleDialog.fieldNameMap[field];
				console.log("populateFields    name: " + name);
				
				console.log("populateFields    field: " + field);
				doh.assertTrue(sampleDialog[name].getValue() == test[field]);
			}
		}
	}
}
	
]);

// Execute D.O.H.
doh.run();


});
