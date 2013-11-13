require([
	"dojo/_base/declare",
	"dijit/registry",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/infusion/Infusion",
	"dojo/ready",
	"dojo/domReady!",
	"dijit/layout/TabContainer"
],

function (declare, registry, doh, util, Agua, Infusion, Data, DataStore, ready) {

window.Agua = Agua 

////}}}}}

doh.register("plugins.infusion.Infusion", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
		Agua.data = util.fetchJson("getData.json");
	},
	runTest : function(){
		console.log("# new");
	
		//ready(function() {

		setTimeout( function () {
			// CREATE INSTANCE OF Data
			var infusion = new Infusion({
				attachPoint: dojo.byId("attachPoint")
			});
			
			console.log("new    instantiated");
			doh.assertTrue(true);
	
		},
		300);

		//});

	},
	tearDown: function () {}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});

