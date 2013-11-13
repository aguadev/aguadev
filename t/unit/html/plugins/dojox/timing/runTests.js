// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
dojo.require("doh.runner");
//dojo.require("dojoc.util.loader");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.dojox.Timer");

var Agua;
var Data;
var data;
var runStatus;
dojo.addOnLoad(function(){

	
doh.registerGroup("plugins.dojox.timing",
[

// TEST attenuate
{
	name: "attenuate",
	timeout : 30000,
	runTest: function() {
		
		console.log("runTests    attenuate");
	
		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred({
			timeout: 40000});

		// FLAG
		var flag = false;
		var counter = 0;
		var checkFlag = function (object) {
			counter++;
			console.log("runTests    checkFlag " + counter + " onTick: " + new Date().toTimeString());
			return flag;
		};

		// SET TIMER
		var timer = new plugins.dojox.Timer({
			poll: checkFlag,
			interval: 1000,
			attenuate : true
		});
		timer.start();
		
		// TEST AFTER FIRST queryStatus
		setTimeout(function() {
			try {
				console.log("runTests    FIRST TIMEOUT");
				console.log("runTests    timer.completed IS FALSE");
				doh.assertFalse(timer.completed);
				console.log("runTests    flag NOT NULL");
				doh.assertFalse(flag == null);
				console.log("runTests    flag NOT TRUE");
				doh.assertFalse(flag == true);
				console.log("runTests    timer.polling IS TRUE");
				doh.assertTrue(timer.polling == true);
		
				//deferred.callback(true);
		
			} catch(e) {
			  deferred.errback(e);
			}
		}, 5000);
		
		// TEST AFTER FIRST queryStatus
		setTimeout(function() {
			try {
				console.log("runTests    SECOND TIMEOUT");
				console.log("runTests    timer.completed IS FALSE")
				doh.assertFalse(timer.completed);
				console.log("runTests    flag NOT NULL")
				doh.assertFalse(flag == null);
				console.log("runTests    flag NOT TRUE")
				doh.assertFalse(flag == true);
				flag = true;
				console.log("runTests    flag IS TRUE")
				doh.assertTrue(flag == true);
				console.log("runTests    timer.polling IS TRUE");
				doh.assertTrue(timer.polling == true);
				
				//deferred.callback(true);
				
			} catch(e) {}
		}, 10000);
		
		// TEST AFTER FIRST queryStatus
		setTimeout(function() {
			try {
				console.log("runTests    THIRD TIMEOUT");
				console.log("runTests    flag IS NOT FALSE")
				doh.assertFalse(flag == false);
				console.dir({timer:timer});
				console.log("runTests    timer.polling IS FALSE");
				doh.assertTrue(timer.polling == false);
				console.log("runTests    counter IS CORRECT");
				doh.assertTrue(counter == 4);
				
				
				deferred.callback(true);
				
				
			} catch(e) {
			  deferred.errback(e);
			}
		}, 18000);

		return deferred;
	}
}

//,
//// TEST interval
//{
//	name: "interval",
//	timeout: 30000,
//	runTest: function() {
//
//		// FLAG
//		var flag = false;
//		var counter = 0;
//		var checkFlag = function (object) {
//			counter++;
//			console.log("runTests    checkFlag " + counter + " onTick: " + new Date().toTimeString());
//			return flag;
//		};
//
//		// SET TIMER
//		var timer = new plugins.dojox.Timer({ poll: checkFlag, interval: 1000 });
//		timer.start();
//		
//		// SET DEFERRED OBJECT
//		var deferred = new doh.Deferred();
//		
//		// TEST AFTER FIRST queryStatus
//		setTimeout(function() {
//			try {
//				console.log("runTests    FIRST TIMEOUT");
//				console.log("runTests    timer.completed IS FALSE");
//				doh.assertFalse(timer.completed);
//				console.log("runTests    flag NOT NULL");
//				doh.assertFalse(flag == null);
//				console.log("runTests    flag NOT TRUE");
//				doh.assertFalse(flag == true);
//				console.log("runTests    timer.polling IS TRUE");
//				doh.assertTrue(timer.polling == true);
//			} catch(e) {
//			  deferred.errback(e);
//			}
//		}, 5000);
//
//		// TEST AFTER FIRST queryStatus
//		setTimeout(function() {
//			try {
//				console.log("runTests    SECOND TIMEOUT");
//				console.log("runTests    timer.completed IS FALSE")
//				doh.assertFalse(timer.completed);
//				console.log("runTests    flag NOT NULL")
//				doh.assertFalse(flag == null);
//				console.log("runTests    flag NOT TRUE")
//				doh.assertFalse(flag == true);
//				console.log("runTests    ***** SETTING flag TO TRUE *****")
//				flag = true;
//				console.log("runTests    flag IS TRUE")
//				doh.assertTrue(flag == true);
//				console.log("runTests    timer.polling IS TRUE");
//				doh.assertTrue(timer.polling == true);
//			} catch(e) {
//			}
//		}, 10000);
//
//		// TEST AFTER FIRST queryStatus
//		setTimeout(function() {
//			try {
//				console.log("runTests    THIRD TIMEOUT");
//				console.log("runTests    flag IS NOT FALSE")
//				doh.assertFalse(flag == false);
//				console.log("runTests    timer.polling IS FALSE");
//				doh.assertTrue(timer.polling == false);
//				console.log("runTests    counter IS CORRECT");
//				doh.assertTrue(counter == 10);
//
//				//deferred.callback(true);				
//
//			} catch(e) {
//			  deferred.errback(e);
//			}
//		}, 12000);
//
//				//deferred.callback(true);				
//		return deferred;
//	}
//}

//,
//
//// TEST arguments
//{
//	name: "arguments",
//	timeout: 30000,
//	runTest: function() {
//	
//		// FLAG
//		var flag = false;
//		var counter = 0 ;
//		var checkFlag = function (timerObject) {
//			timerObject.counter++;
//			counter++;
//			console.log("runTests    checkFlag " + timerObject.counter
//				+ " onTick: (counter: " + counter + "): "
//				+ new Date().toTimeString());
//			doh.assertTrue(timerObject.counter == counter);
//			return flag;
//		};
//	
//		// SET TIMER
//		var timer = new plugins.dojox.Timer({ poll: checkFlag, interval: 1000 });
//		timer.counter = 0;
//		timer.start();
//		
//		// SET DEFERRED OBJECT
//		var deferred = new doh.Deferred();
//		
//		// TEST AFTER FIRST queryStatus
//		setTimeout(function() {
//			try {
//				console.log("runTests    FIRST TIMEOUT");
//				console.log("runTests    timer.completed IS FALSE");
//				doh.assertFalse(timer.completed);
//				console.log("runTests    flag NOT NULL");
//				doh.assertFalse(flag == null);
//				console.log("runTests    flag NOT TRUE");
//				doh.assertFalse(flag == true);
//				console.log("runTests    timer.polling IS TRUE");
//				doh.assertTrue(timer.polling == true);
//	
//				timer.stop();
//				console.log("runTests    timer.counter: " + timer.counter);
//				console.log("runTests    counter: " + counter);
//	
//				doh.assertTrue(timer.counter == 4);
//				
//				deferred.callback(true);				
//	
//			} catch(e) {
//			  deferred.errback(e);
//			}
//		}, 5000);
//			
//		return deferred;
//	}
//}


]);	// doh.register


////]}}



//Execute D.O.H. in this remote file.
doh.run();

}); // dojo.addOnLoad

	
