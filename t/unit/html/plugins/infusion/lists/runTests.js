require([
	"dojo/_base/declare",
	"dijit/registry",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Lists",
	"plugins/infusion/Data",
	"plugins/infusion/DataStore",
	"plugins/infusion/Dialogs",
	"dojo/ready",
	"dojo/domReady!",
	"dijit/layout/TabContainer"
],

function (declare, registry, doh, util, Agua, Lists, Data, DataStore, Dialogs, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.infusion.Lists", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
		Agua.data = util.fetchJson("getData.json");
	},
	runTest : function(){
		console.log("# new");
	
		ready(function() {
			// CREATE INSTANCE OF Data
			var attachPoint = dojo.byId("attachPoint");
			//attachPoint.appendChild(lists.containerNode);
			
			// SET DIALOGS
			var dialogs = new Dialogs();
			
			// SET DATA
			var dataObject = new Data();
			dataObject.initialiseData();
			console.log("new    dataObject:");
			console.dir({dataObject:dataObject});

			// SET DATASTORE
			var dataStore = new DataStore({core:core});
			console.log("new    dataStore: " + dataStore);		
			console.dir({dataStore:dataStore});
			dataStore.startup();

			// SET CORE
			var core = new Object();
			core.dialogs = dialogs;
			core.data = dataObject;
			core.dataStore = dataStore;
			
			// INSTANTIATED LISTS 
			//ready(function() {
			
				var lists = new Lists({
					core : core,
					attachPoint: attachPoint
				});
			
			//});

		
			//attachPoint.appendChild(projectDetails.containerNode)
	
		})

	},
	tearDown: function () {}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

