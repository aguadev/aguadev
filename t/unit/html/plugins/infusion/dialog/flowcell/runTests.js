require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Dialog/Flowcell",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Data, DataStore, DialogFlowcell, ready) {

console.log("# plugins.infusion.Dialog.Flowcell");


// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

var url = "getData.json";
Agua.data = util.fetchJson(url);
var dataObject;
//dataObject.getData(Agua.data);
var flowcellDialog;

/////}}}}}}

var deferred = new doh.Deferred();

doh.register("plugins.infusion.Dialog.Flowcell", [

/////}}}}}}

{

/////}}}}}}
	name: "new",
	timeout : 2000,
	setUp: function(){
		//Agua.data = util.fetchJson(url);
	},
	runTest : function(){

		console.log("# new");

		// CREATE DATA
		dataObject = new Data();
		
		// CREATE DATASTORE
		dataStore = new DataStore();
		dataStore.startup();

		// SET CORE
		var core = new Object();
		core.data = dataObject;
		core.dataStore = dataStore;

		// CREATE INSTANCE OF Data
		dataObject = new Data();
		
		// CREATE INSTANCE OF Dialog.Flowcell
		flowcellDialog = new DialogFlowcell({
			values : {},
			core: core
		});

		setTimeout(function() {
			try {
				console.log("Flowcell.new    flowcellDialog: " + flowcellDialog);
				console.dir({flowcellDialog:flowcellDialog});
	
				// LOAD DATA
				var instantiated = flowcellDialog ? true : false;
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

		setTimeout(function() {
			try {

				console.log("# populateFields");
				var tests = [
					{
						  flowcell_id: 1,
								server:	"uscp-prd-lndt-1-2.local",
					  flowcell_barcode:	"C09LTACXX",
					  update_timestamp:	"2013-02-17 23:33:50",
						  fpga_version:	"3.2.06",
						   rta_version:	"1.13.48",
							run_length:	"101,101",
							   indexed:	"no",
							 status_id:	"11",
							  //operator:	"",
						   description:	"",
								//recipe:	"",
						  machine_name:	"SN901",
							  location:	"/isilon/RUO/Runs/111102_SN901_0125_BC09LTACXX_Genentech",
						run_start_date:	"0000-00-00",
					 priority_flowcell:	"0",
					   //location_md5sum:	"e6969d1b388f7119c78ac80eba36447f",
							  comments:	"",
							  symptoms:	"Computer Freeze",
					  //user_code_and_ip:	"",
					  attempting_rehyb:	"1",
					   lcm_broad_cause:	"Computer",
					lcm_specific_cause:	"Computer-Hardware",
							lcm_status:	"Open",
				 lcm_equipment_related:	"No",
						  lcm_comments:	""
					}
				];
				
				for ( var i in tests ) {
					var test = tests[i];
					console.log("populateFields    test:");
					console.dir({test:test});
					
					console.log("populateFields    BEFORE flowcellDialog.populateFields(data)");
					flowcellDialog.populateFields(test);
					console.log("populateFields    AFTER flowcellDialog.populateFields(data)");
					
					// VERIFY VALUES
					for ( var field in test ) {
						console.log("populateFields    field: " + field);
						var name = flowcellDialog.fieldNameMap[field];
						console.log("populateFields    name: " + name);
						
						doh.assertTrue(flowcellDialog[name].getValue().toString() == test[field].toString());
					}
				}

				deferred.callback(true);

			}
			catch(e) {
			  deferred.errback(e);
			}
		}, 1000);
	}
}
,
{

/////}}}}}}
	name: "getData",
	timeout: 1000,
	setUp: function(){
		//Agua.data = util.fetchJson(url);
	},
	runTest : function(){

		console.log("# getData");
		
		var tests = [
			{
				flowcell_id 				: 	116,
				flowcell_name 			: 	"CHUM_Rouleau1",
				//principal_investigator 	: 	"Rouleau, Charles",
				description				: 	"Study of monkey viruses",
				build_version			:	"NCBI36",				//	CHANGED
				dbsnp_version			:	129,					//	CHANGED
				include_NPF				:	"N",
				flowcell_manager			:	"A Manager",
				data_analyst			:	"An Analyst",
				build_location			:	"/path/to/build",
				flowcell_policy			:	"--build somePolicy"
			}
		];
		
		for ( var i in tests ) {
			var test = tests[i];
			console.log("getData    test:");
			console.dir({test:test});
			
			// POPULATE FIELDS
			flowcellDialog.populateFields(test);
			
			// RETRIEVE FIELDS
			console.log("getData    BEFORE flowcellDialog.getData(data)");
			var data = flowcellDialog.getData(test);
			console.log("getData    AFTER flowcellDialog.getData(data)");
			
			// VERIFY VALUES
			for ( var field in test ) {
				console.log("getData    field: " + field);
				doh.assertTrue(test[field] == data[field]);
			}
		}
	}
}
//,
//{
//
///////}}}}}}
//	name: "setWorkflowOptions",
//	setUp: function(){
//		Agua.data = util.fetchJson(url);
//	},
//	runTest : function () {
//		console.log("# setWorkflowOptions");
//		
//		var data = [
//			{
//				workflow_id			:	"8",
//				workflow_name		:	"isis_bcl_to_gvcf_workflow",
//				workflow_version	:	"1",
//				create_date			: 	"2013-02-09 22:33:42",
//				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
//				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
//			}
//			,
//			{
//				workflow_id			:	"9",
//				workflow_name		:	"isis_bcl_to_gvcf_workflow",
//				workflow_version	:	"2",
//				create_date			: 	"2013-02-09 22:33:42",
//				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
//				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
//			}
//			,
//			{
//				workflow_id			:	"10",
//				workflow_name		:	"isis_bcl_to_gvcf_workflow",
//				workflow_version	:	"3",
//				create_date			: 	"2013-02-09 22:33:42",
//				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
//				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
//			}
//			,
//			{
//				workflow_id			:	"6",
//				workflow_name		:	"casava_bcl_to_gvcf_workflow",
//				workflow_version	:	"9",
//				create_date			: 	"2013-02-09 22:33:42",
//				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
//				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
//			}
//			,
//			{
//				workflow_id			:	"7",
//				workflow_name		:	"casava_bcl_to_gvcf_workflow",
//				workflow_version	:	"10",
//				create_date			: 	"2013-02-09 22:33:42",
//				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
//				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
//			}
//		];
//
//		// ADD DATA
//		Agua.data.workflow = data;
//		
//		// SET WORKFLOW OPTIONS
//		console.log("setWorkflowOptions    BEFORE flowcellDialog.setWorkflowOptions()");
//		flowcellDialog.setWorkflowOptions();
//		console.log("setWorkflowOptions    AFTER flowcellDialog.setWorkflowOptions()");
//
//		// VERIFY WORKFLOW OPTIONS
//		var workflow = flowcellDialog.workflow.getValue();
//		var expected = "casava_bcl_to_gvcf_workflow";
//		console.log("setWorkflowOptions    workflow");
//		doh.assertTrue(workflow == expected)
//		
//		var workflowVersion = flowcellDialog.workflowVersion.getValue();
//		var expectedVersion = "9";
//		console.log("setWorkflowOptions    workflowVersion");
//		doh.assertTrue(workflowVersion == expectedVersion)
//	}
//}

	
]);

// Execute D.O.H.
doh.run();


});
