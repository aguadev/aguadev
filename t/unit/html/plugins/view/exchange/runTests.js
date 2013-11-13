console.log("t.plugins.view.exchange    LOADING");

require(
[
	"doh/runner",
	"t/doh/util",
	"dojo/json",
	"plugins/core/Agua",
	"plugins/view/View",
	"dojo/ready"
],
function(
	doh,
	util,
	JSON,
	coreAgua,
	View,
	ready	
) {


var data;
var view;
var responses = [];
var browsers;
var browser;

// SET DEFERRED
var deferred = new doh.Deferred();



ready(function() {
	
doh.register("t/plugins/view/exchange/test", [	
{
	name: "setFeatures",
	timeout: 10000,
	setUp : function () {
		Agua = new coreAgua({
			cgiUrl : "../../../../../../cgi-bin/aguadev/"
			, htmlUrl : "../../../../../../aguadev/"
			, dataUrl: "test.json"
			, token : "abcdefghijklmnop"
		});
		
		Agua.cookie('username', 'aguatest');
		Agua.cookie('sessionid', '9999999999.9999.999');
		Agua.database = "aguatest";
		Agua.loadPlugins([
			"plugins.data.Controller",
			"plugins.view.Controller"
		]);
		
		var controllers = Agua.controllers;
		Agua.controllers["view"].createTab({
			baseUrl: "../../../../t/plugins/view/exchange"
			, browserRoot: ""
			, loadOnStartup : false
		});

		// GET VIEW
		view = Agua.controllers["view"].tabPanes[0];
	},	
	runTest: function() {
		console.log("# setFeatures");
		
		var projectName	=	"Project1";
		var viewName	=	"View2";
		var hash 	= 	{
			sourceid :	view.id,
			callback : 	"setFeatures",
			status   :	"ready",
			token	 :	"abcdefghijklmnop",
			viewobject:	{
				project	:	projectName,
				view 	:	viewName
			}
		};

		setTimeout(function(){
			try {
				var ready = view.features && view.features.ready;
				console.log("runTests    setFeatures");
				doh.assertTrue(ready);
				//deferred.callback(true);

			} catch(e) {
			  deferred.errback(e);
			}
		}, 1000);
		
		//return deferred;
	},
	teardown : function () {
		//console.log("***************************** DOING TEARDOWN ");
	}	
}
,
{
	name: "_handleAddView",
	timeout: 20000,
	setUp : function () {
	},	
	runTest: function() {
		console.log("# _handleAddView");

		var projectName	=	"Project1";
		var viewName	=	"View2";
		var hash 	= 	{
			sourceid :	view.id,
			callback : 	"_handleAddView",
			status   :	"ready",
			token	 :	"abcdefghijklmnop",
			viewobject:	{
				project	:	projectName,
				view 	:	viewName
			}
		};

		var query 	=	JSON.stringify(hash);

		//// SET DEFERRED
		//var deferred = new doh.Deferred();

		setTimeout(function(){
			try {
				// SHOW STANDBY TO MAKE SURE IT IS CANCELLED LATER
				view.standby.show();

				// RUN onMessage
				console.log("runTests._handleAddView.runTest    DOING Agua.exchange.onMessage(query)    query: " + query);
				Agua.exchange.onMessage(query);

			} catch(e) {
			  deferred.errback(e);
			}
		}, 3000);

		setTimeout(function(){
			try {
				var browser = view.browsers[0];
				var identical = browser.project === projectName
								&& browser.view	=== viewName;
				//console.log("runTests._handleAddView.runTest    identical: " + identical);

				console.log("runTests    _handleAddView");
				doh.assertTrue(identical);

				//if ( identical ) {
				//	deferred.callback(true);
				//}		
				
				// LATER: MAKE SURE STANDBY IS HIDDEN

			} catch(e) {
			  deferred.errback(e);
			}
		}, 4000);
		
		//deferred.callback(true);
		//return deferred;
	}
}
,
{
	name: "_handleAddViewFeature",
	timeout: 30000,
	setUp : function () {
	},	
	runTest: function() {
		console.log("# _handleAddViewFeature");
		
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
			//sourceid		:	"plugins_view_View_0",
			sourceid 		:	view.id,
			callback 		: 	"_handleAddViewFeature",
			status   		:	"ready",
			token	 		:	"abcdefghijklmnop",
			module			:	"Agua::View",
			featureobject	:	featureobject
		};

		var query 	=	JSON.stringify(hash);

		//// SET DEFERRED
		//var deferred = new doh.Deferred();

		setTimeout(function(){
			try {

				// RUN onMessage
				console.log("runTests._handleUpdateViewLocation.runTest    DOING Agua.exchange.onMessage(query)    query: " + query);
				Agua.exchange.onMessage(query);

			} catch(e) {
			  deferred.errback(e);
			}
		}, 3000);

		setTimeout(function(){
			try {
				console.log("runTests._handleUpdateViewLocation.runTest    view.browsers: ");
				
				//console.dir({view_browsers:view.browsers});

				//var browser = view.browsers[0];
				//var identical = browser.project === featureobject.project
				//				&& browser.view	=== featureobject.view;
				//console.log("runTests._handleUpdateViewLocation.runTest    identical: " + identical);
				//
				//if ( identical ) {
					deferred.callback(true);
				//}		
			} catch(e) {
			  deferred.errback(e);
			}
		}, 4000);
		
		//deferred.callback(true);
		return deferred;
	}
}


]);	// doh.register


console.log("runTests    DOING doh.run()");

// RUN DOH
doh.run();



	//doh.register("doh/async", [{
	//	name: "deferredSuccess",
	//	runTest: function(t){
	//		var d = new doh.Deferred();
	//		setTimeout(d.getTestCallback(function(){
	//			t.assertTrue(true);
	//			t.assertFalse(false);
	//		}), 50);
	//		return d;
	//	}
	//},{
	//	name: "deferredFailure--SHOULD FAIL",
	//	runTest: function(t){
	//		console.log("running test that SHOULD FAIL");
	//		var d = new doh.Deferred();
	//		setTimeout(function(){
	//			d.errback(new Error("hrm..."));
	//		}, 50);
	//		return d;
	//	}
	//},{
	//	name: "timeoutFailure--SHOULD FAIL",
	//	timeout: 50,
	//	runTest: function(t){
	//		console.log("running test that SHOULD FAIL");
	//		// timeout of 50
	//		var d = new doh.Deferred();
	//		setTimeout(function(){
	//			d.callback(true);
	//		}, 100);
	//		return d;
	//	}
	//}]);

//});



}); // ready

});





//// DOJO TEST MODULE
////dojo.require("dijit.dijit");
////dojo.require("dojox.robot.recorder");
//////dojo.require("dijit.robot");
//dojo.require("doh.runner");
//
//// Agua TEST MODULES
//dojo.require("t.doh.util");
//
//// DEBUG LOADER
////dojo.require("dojoc.util.loader");
//
//// TESTED MODULES
//dojo.require("plugins.core.Agua");
//dojo.require("plugins.view.View");
//
//var Agua;
//var data;
//var view;
//
//dojo.addOnLoad( function() {
//
//console.log("FIRST dojo.addOnLoad()");
//
//Agua = new plugins.core.Agua({
//	cgiUrl : "../../../../../../cgi-bin/aguadev/",
//	htmlUrl : "../../../../../../aguadev/"
//	//, dataUrl: dojo.moduleUrl("plugins", "getData.120507.json")
//	, dataUrl: "test.json"
//});
//
//Agua.cookie('username', 'aguatest');
//Agua.cookie('sessionid', '9999999999.9999.999');
//Agua.database = "aguatest";
//Agua.loadPlugins([
//	"plugins.data.Controller",
//	"plugins.view.Controller"
//]);
//
//var controllers = Agua.controllers;
//console.log("runTests.js    controllers: " + controllers);
//console.dir({controllers:controllers});
//
//Agua.controllers["view"].createTab({
//	baseUrl: "../../../../t/plugins/view/browser"
//	, browserRoot: ""
//});
//
//var view;
//var browsers;
//var browser;
//
//doh.register("t.plugins.view.views.test",
//[	
//	{
//		name: "getters",
//		timeout: 70000,
//		runTest: function() {
//
//			//// CLEAR CONSOLE 
//			//console.clear();
//			//console.log("After console.clear()");
//
//			// GET VIEW
//			view = Agua.controllers["view"].tabPanes[0];
//			console.log("runTests.js    view:");
//			console.dir({view:view});
//
//			// SET DEFERRED
//			var deferred = new doh.Deferred();
//
//			setTimeout(function(){
//				try {
//					console.log("runTests.js    SET view.url: " + view.url);
//
//					console.log("runTests.onMessage    io: ");
//					console.dir({io:io});
//					console.log("runTests.onMessage    io.version: " + io.version);
//			  
//					var conn = io.connect('http://localhost:8080');
//					
//					var 
//			  
//					conn.send(val);
//			  
//
//					view.url = Agua.cgiUrl + "t/test.cgi?response={'status':'running'}&";
//
//					// ADD VIEW
//					view.viewCombo.set('value', 'View4');
//					view.addView('Project1', 'View4', 'human(hg19)');
//
//
//
//
//			
//				} catch(e) {
//				  deferred.errback(e);
//				}
//			}, 1000);
//		//
//		//	setTimeout(function(){
//		//		try {
//		//			// GET BROWSER
//		//			browsers = view.exchanges;
//		//			browser = browsers[0].browser;
//		//			console.log("runTests.js    browser: ");
//		//			console.dir({browser:browser});
//		//			
//		//			console.log("runTests.js    className: " + doh.assertEqual("plugins.view.jbrowse.js.Browser", Agua.getClassName(browser), "plugins.view.jbrowse.js.Browser"));
//		//			console.log("runTests.js    isBrowser: " + doh.assertEqual(view.isBrowser(browser.params.viewObject.project, browser.params.viewObject.view), 1));
//		//
//		//			console.log("runTests.js    SET response TO running");
//		//			view.url = Agua.cgiUrl + "t/test.cgi?response={'status':'running'}&";
//		//		} catch(e) { deferred.errback(e); }
//		//	}, 12000);
//		//
//		//	setTimeout(function(){
//		//		try {
//		//			console.log("runTests.js    SET response TO ready");
//		//			view.url = Agua.cgiUrl + "t/test.cgi?response={'status':'ready'}&";
//		//		} catch(e) {
//		//		  deferred.errback(e);
//		//		}
//		//	}, 15000);
//		//
//		//	setTimeout(function(){
//		//		try {
//		//			console.log("runTests.js    STARTING getters");
//		//			console.log("runTests.js    project is correct (Project1): " + doh.assertEqual(view.getProject(), "Project1"));
//		//			console.log("runTests.js    workflow is correct (Workflow1): " + doh.assertEqual(view.getWorkflow(), "Workflow1"));
//		//			
//		//			console.log("runTests.js    BEFORE view.getView()");
//		//			var view = view.getView();
//		//			console.log("runTests.js    view: " + view);
//		//			
//		//			console.log("runTests.js    view is correct (View1): " + doh.assertEqual(view.getView(), "View1"));
//		//			console.log("runTests.js    AFTER view.getView()");
//		//			
//		//			console.log("runTests.js    viewFeature is correct (control1): " + doh.assertEqual(view.getViewFeature(), "control1"));
//		//			console.log("runTests.js    species is correct (human): " + doh.assertEqual(view.getFeatureSpecies(), "human"));
//		//			console.log("runTests.js    build is correct (hg19): " + doh.assertEqual(view.getFeatureBuild(), "hg19"));
//		//			console.log("runTests.js    feature is correct (tophat-1): " + doh.assertEqual(view.getFeature(), "tophat-1"));
//		//	
//		//			deferred.callback(true);
//		//	
//		//		} catch(e) {
//		//		  deferred.errback(e);
//		//		}
//		//	}, 25000);
//		//
//			deferred.callback(true);
//		
//			return deferred;
//
//		}
//	}
//
//
//]);	// doh.register
//
////Execute D.O.H. in this remote file.
//doh.run();
//
//
//}); // FIRST dojo.addOnLoad


console.log("t.plugins.view.exchange    END");