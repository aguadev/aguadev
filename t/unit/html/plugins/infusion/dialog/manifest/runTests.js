require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Dialog/Manifest",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Data, DataStore, DialogManifest) {

console.log("# plugins.infusion.Dialog.Manifest");

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;
	
// DATA URL
var url 	= "./getData.json";	

/////}}}}}}

doh.register("plugins.infusion.Dialog.Manifest", [

/////}}}}}}

{

/////}}}}}}
	name: "createManifest",
	setUp: function(){
		// GET AGUA DATA
		Agua.data = util.fetchJson(url);

		// CREATE VIEWSIZE
		viewSize = new ViewSize({});
	},
	runTest : function(){

		console.log("# validationTextBox");

		// CREATE INSTANCE OF Data
		var dataObject = new Data();
		dataObject.initialiseData();
		
		// CREATE INSTANCE OF Dialog.Manifest
		dialogManifest = new DialogManifest({
			parent: dataObject
		});
		
		// ATTACH GRID TO PAGE
		var attachPoint = dom.byId("attachPoint");
		attachPoint.appendChild(dialogManifest.containerNode)

		// GET SAMPLES
		//var projectName = "CHUM_Rouleau1";
		//var samples = dialogManifest.getSamples(projectName);

		//// GET EXPECTED
		//var expectedSamples = util.fetchJson("./samples.json");
		
		//// TEST
		//console.log("getSamples    samples");
		//doh.assertTrue(util.identicalArrayHashes(samples, expectedSamples));
	}
}
	
]);

// Execute D.O.H.
doh.run();


});
