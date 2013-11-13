require([
	"dojo/_base/declare",
	"dojo/dom",
	"dijit/registry",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Details/Lane",
	"dojo/ready",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojo/domReady!"
],

function (declare, dom, registry, doh, util, Agua, Data, DataStore, LaneDetails, TabContainer, ContentPane, ready) {

console.log("# plugins.infusion.Detailed.Lane");

// GLOBAL VARIABLES
window.Agua = Agua;
var dataObject;
var dataStore;
var core;
var url 	= "./getData.json";	

doh.register("Infusion.Detailed.Project", [

{
	
	name: "setInformation",
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

		var tabContainer = new dijit.layout.TabContainer({
			style: "height: 100%; max-height: 130px !important; width: 100%;",
			tabStrip 	: 	true,
			title		:	"Lane"
		},
		"attachPoint");
		tabContainer.startup();		
		
		var laneDetails = new LaneDetails({
			attachPoint 	:	registry.byId("attachPoint"),
			core			: 	core,
			title			:	"Lanes",
			label			:	"Lanes"				
		});

		var thisObject = this;
		setTimeout(function(thisObj) {
			// 2 LANES
			var laneBarcode = "C05U1ACXX_8";
			//var laneBarcode = "80CWFABXX_8";
			laneDetails.updateGrid(laneBarcode);
		}, 1500, this);
	
		//w = window.open('text.txt');
		//w.document.write(JSON.stringify(samples));
		
		// TEST
		console.log("setInformation    samples");
		doh.assertTrue(true);

	}
}

]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
