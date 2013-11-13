require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"dojo/dom-class",
	"t/doh/util",
	"plugins/form/Status",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, domClass, util, Status, ready) {

console.log("# plugins.form.Status");

/////}}}}}}

var deferred = new doh.Deferred();

doh.register("plugins.form.Status", [

/////}}}}}}

{

/////}}}}}}
	name: "new",
	timeout : 2000,
	setUp: function(){
	},
	runTest : function(){
		console.log("# new");

		var status = new Status({
			loadingTitle	: 	"Loading",
			readyTitle 		:	"Ready",
			attachPoint 	: 	dom.byId("attachPoint")
		});

		console.log("new    instantiated is true: " + status);		
		doh.assertTrue(status);
		
		console.log("new    setStatus(loading)");		
		status.setStatus("loading");
		doh.assertTrue(domClass.contains(status.displayNode, "loading"));
		doh.assertTrue(domClass.contains(status.titleNode.innerHTML == "Loading"));


		console.log("new    setStatus(ready)");		
		status.setStatus("ready");
		doh.assertTrue(domClass.contains(status.displayNode, "ready"));
		doh.assertTrue(domClass.contains(status.titleNode.innerHTML == "Ready"));
	}
}

	
]);

// Execute D.O.H.
doh.run();


});
