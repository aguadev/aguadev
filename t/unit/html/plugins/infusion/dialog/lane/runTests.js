require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Dialog/Lane",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Data, DataStore, DialogLane, ready) {

console.log("# plugins.infusion.Dialog.Lane");


// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;

var url = "getData.json";
var dataObject;
var dataStore;
var core;
var laneDialog;

//Agua.data = util.fetchJson(url);

/////}}}}}}

doh.register("plugins.infusion.Dialog.Lane", [

/////}}}}}}

{

/////}}}}}}
	name: "new",
	timeout : 1000,
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
		console.log("# new");

		// CREATE INSTANCE OF Dialog.Lane
		laneDialog = new DialogLane({
			values : {},
			core: core
		});

		var deferred = new doh.Deferred();

		setTimeout(function() {
			try {
				console.log("Lane.new    laneDialog: " + laneDialog);
				console.dir({laneDialog:laneDialog});
	
				// LOAD DATA
				var instantiated = laneDialog ? true : false;
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
		flowcell_samplesheet_id: 	"1",
					flowcell_id: 	"2",
					  sample_id: 	"1001",
						lane_id: 	"1",
				   ref_sequence:	"",
						control: 	"N",
					  status_id: 	"63",
					   indexval: 	"NULL",
						 md5sum: 	"196b1f3ba961f396cda4c713f03925da",
					   location: 	"/isilon/RUO/Runs/111017_SN1012_0089_AC09A9ACXX_MSK4155565860/SampleSheet.csv",
				   date_updated: 	"2012-10-22 21:37:39"
			}
		];
		
		for ( var i in tests ) {
			var test = tests[i];
			console.log("populateFields    test:");
			console.dir({test:test});
			
			console.log("populateFields    BEFORE laneDialog.populateFields(data)");
			laneDialog.populateFields(test);
			console.log("populateFields    AFTER laneDialog.populateFields(data)");
			console.log("populateFields    laneDialog:");
			console.dir({laneDialog:laneDialog});
			
			// VERIFY VALUES
			for ( var field in test ) {
				console.log("populateFields    field: " + field);
				var name = laneDialog.fieldNameMap[field];
				console.log("populateFields    name: " + name);
				if ( ! name || name == "status") continue;
				
				console.log("populateFields    field: " + field);
				doh.assertTrue(laneDialog[name].getValue() == test[field]);
			}
		}
	}
}



]);

// Execute D.O.H.
doh.run();


});
