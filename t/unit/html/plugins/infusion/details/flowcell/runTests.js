require([
	"dojo/_base/declare",
	"dojo/dom",
	"dijit/registry",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Details/Flowcell",
	"dojo/ready",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojo/domReady!"
],

function (declare, dom, registry, doh, util, Agua, Data, DataStore, FlowcellDetails, ready) {

console.log("# plugins.infusion.Detailed.Flowcell");

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;
	
// DATA URL
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

	
		// CREATE INSTANCE
		var flowcellDetails = new FlowcellDetails({
			attachPoint 	:	registry.byId("attachPoint"),
			core			: 	core,
			title			:	"Flowcells",
			label			:	"Flowcells"				
		});
		
		var thisObject = this;
		setTimeout(function(thisObj) {
			// UPDATE GRID
			console.log("setInformation    INSIDE setTimeout");
	
			// 2 LANES
			var flowcellBarcode = "C0W7WACXX";	
			flowcellDetails.updateGrid(flowcellBarcode);
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
