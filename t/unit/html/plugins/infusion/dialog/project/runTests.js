require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Dialog/Project",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Data, DataStore, DialogProject, ready) {

console.log("# plugins.infusion.Dialog.Project");


// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

var url = "getData.json";
Agua.data = util.fetchJson(url);
var dataObject;
var dataStore;
var projectDialog;

/////}}}}}}

doh.register("plugins.infusion.Dialog.Project", [

/////}}}}}}

{

/////}}}}}}
	name: "new",
	timeout : 3000,
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
		
		// CREATE INSTANCE OF Dialog.Project
		projectDialog = new DialogProject({
			values : {},
			core: core
		});
		projectDialog.startup()
		
		setTimeout(function() {
			try {
				console.log("Project.new    projectDialog: " + projectDialog);
				console.dir({projectDialog:projectDialog});
	
				// LOAD DATA
				var instantiated = projectDialog ? true : false;
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
				project_id 				: 	116,
				project_name 			: 	"CHUM_Rouleau1",
				//principal_investigator 	: 	"Rouleau, Charles",
				description				: 	"Study of monkey viruses",
				build_version			:	"NCBI36",				//	CHANGED
				dbsnp_version			:	129,					//	CHANGED
				include_NPF				:	"N",
				project_manager			:	"A Manager",
				data_analyst			:	"An Analyst",
				build_location			:	"/path/to/build",
				project_policy			:	"--build somePolicy"
			}
		];
		for ( var i in tests ) {
			var test = tests[i];
			console.log("populateFields    test:");
			console.dir({test:test});
			
			console.log("populateFields    BEFORE projectDialog.populateFields(data)");
			projectDialog.populateFields(test);
			console.log("populateFields    AFTER projectDialog.populateFields(data)");
			
			// VERIFY VALUES
			for ( var field in test ) {
				console.log("populateFields    field: " + field);
				var name = projectDialog.fieldNameMap[field];
				console.log("populateFields    name: " + name);
				
				doh.assertTrue(projectDialog[name].getValue() == test[field]);
			}
		}
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
				project_id 				: 	116,
				project_name 			: 	"CHUM_Rouleau1",
				//principal_investigator 	: 	"Rouleau, Charles",
				description				: 	"Study of monkey viruses",
				build_version			:	"NCBI36",				//	CHANGED
				dbsnp_version			:	129,					//	CHANGED
				include_NPF				:	"N",
				project_manager			:	"A Manager",
				data_analyst			:	"An Analyst",
				build_location			:	"/path/to/build",
				project_policy			:	"--build somePolicy"
			}
		];
		
		for ( var i in tests ) {
			var test = tests[i];
			console.log("getData    test:");
			console.dir({test:test});
			
			// POPULATE FIELDS
			projectDialog.populateFields(test);
			
			// RETRIEVE FIELDS
			console.log("getData    BEFORE projectDialog.getData(data)");
			var data = projectDialog.getData(test);
			console.log("getData    AFTER projectDialog.getData(data)");
			
			// VERIFY VALUES
			for ( var field in test ) {
				console.log("getData    field: " + field);
				doh.assertTrue(test[field] == data[field]);
			}
		}
	}
}
,
{

/////}}}}}}
	name: "setWorkflowOptions",
	setUp: function(){
		Agua.data = util.fetchJson(url);
	},
	runTest : function () {
		console.log("# setWorkflowOptions");
		
		var data = [
			{
				workflow_id			:	"8",
				workflow_name		:	"isis_bcl_to_gvcf_workflow",
				workflow_version	:	"1",
				create_date			: 	"2013-02-09 22:33:42",
				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
			}
			,
			{
				workflow_id			:	"9",
				workflow_name		:	"isis_bcl_to_gvcf_workflow",
				workflow_version	:	"2",
				create_date			: 	"2013-02-09 22:33:42",
				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
			}
			,
			{
				workflow_id			:	"10",
				workflow_name		:	"isis_bcl_to_gvcf_workflow",
				workflow_version	:	"3",
				create_date			: 	"2013-02-09 22:33:42",
				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
			}
			,
			{
				workflow_id			:	"6",
				workflow_name		:	"casava_bcl_to_gvcf_workflow",
				workflow_version	:	"9",
				create_date			: 	"2013-02-09 22:33:42",
				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
			}
			,
			{
				workflow_id			:	"7",
				workflow_name		:	"casava_bcl_to_gvcf_workflow",
				workflow_version	:	"10",
				create_date			: 	"2013-02-09 22:33:42",
				driver_location		: 	"/home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh",
				sge_min_parameters	: 	"qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y -terse"
			}
		];

		// ADD DATA
		Agua.data.workflow = data;
		
		// SET WORKFLOW OPTIONS
		console.log("setWorkflowOptions    BEFORE projectDialog.setWorkflowOptions()");
		projectDialog.setWorkflowOptions();
		console.log("setWorkflowOptions    AFTER projectDialog.setWorkflowOptions()");

		// VERIFY WORKFLOW OPTIONS
		var workflow = projectDialog.workflow.getValue();
		var expected = "casava_bcl_to_gvcf_workflow";
		console.log("setWorkflowOptions    workflow");
		doh.assertTrue(workflow == expected)
		
		var workflowVersion = projectDialog.workflowVersion.getValue();
		var expectedVersion = "9";
		console.log("setWorkflowOptions    workflowVersion");
		doh.assertTrue(workflowVersion == expectedVersion)
	}
}

	
]);

// Execute D.O.H.
doh.run();


});
