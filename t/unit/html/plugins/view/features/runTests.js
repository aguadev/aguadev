console.log("t.plugins.view.exchange    LOADING");

require(
[
	"doh/runner",
	"t/doh/util",
	"dojo/_base/lang",
	"dojo/json",
	"dojo/dom",
	"t/doh/Agua",
	"plugins/view/Features",
	"dojo/ready"
],
function(
	doh,
	util,
	lang,
	JSON,
	dom,
	Agua,
	Features,
	ready	
) {


window.Agua = Agua;
console.dir({Agua:Agua});


var data;
var view;
var responses = [];
var browsers;
var browser;

ready(function() {
	
doh.register("t/plugins/view/exchange/test", [	
{
	name: "startup",
	timeout: 70000,
	setUp : function () {
		Agua.data = new Object;
		Agua.data		= 	util.fetchJson("./test.json");
		Agua.cgiUrl		=	"../../../../../../cgi-bin/aguadev/";
		Agua.htmlUrl	=	"../../../../../../aguadev/";
		Agua.dataUrl	=	"test.json";
		Agua.token		=	"abcdefghijklmnop"

		console.log("runTests.onMessage.setUp    Agua:");
		console.dir({Agua:Agua});
	},	
	runTest: function() {

		console.log("# startup");
		
		// GET VIEW
		var features = new Features({
			attachPoint: dom.byId("attachPoint"),
			parent: null,
			url: Agua.cgiUrl
		});

		// CHECK STARTED
		console.log("runTests    startup");
		doh.assertTrue(true);

		//console.log("runTests.startup.runTest.runTest    features:");
		//console.dir({features:features});

		var featureobject	=	{
			mode			:	"addViewFeature",
			feature			:	"TESTFEATURE",
			sourceproject	:	"Project2",
			sourceworkflow	:	"Parkinsons",
			project			:	"Project1",
			view			:	"View2",
			species			:	"human",
			build			:	"hg19",
		};

		var hash 	= 	{
			username		:	"aguatest",
			sessionid		:	"9999999999.9999.999",
			sourceid 		:	"plugins_view_View_0",
			callback 		: 	"startupFeature",
			status   		:	"ready",
			token	 		:	"abcdefghijklmnop",
			module			:	"Agua::View",
			featureobject	:	featureobject
		};

		var query 	=	JSON.stringify(hash);

		// SET DEFERRED
		var deferred = new doh.Deferred();

		setTimeout(function(){
			try {
				var project = features.getProject();
				console.log("runTests.startup.runTest    project: " + project);
				var workflow = features.getWorkflow();
				console.log("runTests.startup.runTest    workflow: " + workflow);
				var species = features.getSpecies();
				console.log("runTests.startup.runTest    species: " + species);
				var build = features.getBuild();
				console.log("runTests.startup.runTest    build: " + build);
				var feature = features.getFeature();
				console.log("runTests.startup.runTest    feature: " + feature);
				
				var identical = project === "Project1"
								&& workflow	=== "Workflow9"
								&& species	=== "human"
								&& build	=== "hg19"
								&& feature	===	"control1";
				//console.log("runTests.startup.runTest    identical: " + identical);
		
				console.log("runTests    combo values");
				doh.assertTrue(identical);

				//if ( identical ) {
				//	deferred.callback(true);
				//}		
			} catch(e) {
			  deferred.errback(e);
			}
		}, 500);

		setTimeout(function(){
			try {
				console.log("runTests.startup.runTest    DOING setProjectCombo('Project2')");
				features.setProjectCombo("Project2");
		
				var project = features.getProject();
				console.log("runTests.startup.runTest    project: " + project);
				var workflow = features.getWorkflow();
				console.log("runTests.startup.runTest    workflow: " + workflow);
				var species = features.getSpecies();
				console.log("runTests.startup.runTest    species: " + species);
				var build = features.getBuild();
				console.log("runTests.startup.runTest    build: " + build);
				var feature = features.getFeature();
				console.log("runTests.startup.runTest    feature: " + feature);
				
				var identical = project === "Project2"
								&& workflow	=== "Workflow1"
								&& species	=== "human"
								&& build	=== "hg19"
								&& feature	===	"test1-2";
				console.log("runTests.startup.runTest    identical: " + identical);
		
				console.log("runTests    combo values AFTER setProjectCombo");
				doh.assertTrue(identical);
				//if ( identical ) {

					deferred.callback(true);

				//}		
			} catch(e) {
			  deferred.errback(e);
			}
		}, 1500);
		
		
		//deferred.callback(true);
		return deferred;
	}
}


]);	// doh.register



// RUN DOH
console.log("runTests    DOING doh.run()");
doh.run();

}); // ready

});


console.log("t.plugins.view.exchange    END");