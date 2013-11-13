dojo.provide("t.plugins.core.bookmark.runTests");

//// REGISTER module path FOR PLUGINS
//dojo.registerModulePath("plugins","../../plugins");	
//dojo.registerModulePath("t","../../t/unit");	
//
//// DOJO TEST MODULES
//dojo.require("doh.runner");
////dojo.require("dojoc.util.loader");
//
//// Agua TEST MODULES
//dojo.require("t.doh.util");

// TESTED MODULES
//dojo.require("plugins.dojox.Timer");

//
//var Agua;
//var Data;
//var data;
//var runStatus;

dojo.require("t.plugins.core.bookmark.StackTrace");

dojo.declare("runTests", null, {



});


dojo.addOnLoad(function(){

console.log("INSIDE dojo.addOnLoad");

console.log("stackTrace: " + dojo.toJson(stackTrace));

//doh.register("plugins.core.bookmarklet",
//[
//
//
//// TEST basic
//	{
//		name: "basic",
//		runTest: function() {
            console.log("STARTING TEST");
            
            //	var test = 1;
            //    if ( test) {
            //
            //		console.log("dOING IT");
            //
            //         var trace = printStackTrace();
            //         console.log(trace.join('\n\n'));
            //         //Output however you want!
            //    }
            //console.log("unknown variable: " + unknown)


        //    var lastError;
        //    try {
        //        // error producing code
        //        console.log("unknown variable: " + unknown)
        //            
        //    } catch(e) {
        //       lastError = e;
        //       // do something else with error
        //        console.log("lastError: " + lastError);
        //    }
        //
        ////    // Returns stacktrace from lastError!
        //    //console.dir({stacktrace:printStackTrace({e: lastError})});
        //    var stacktrace = printStackTrace({e: lastError});
        //    for ( var i = 0; i < stacktrace.length; i++ ) {
        //        console.error(stacktrace[i]);
        //    }
        //



            
            //console.log("unknown variable: " + unknown)
            //var lastError;
            //try {
            //    // error producing code
            //    console.log("unknown variable: " + unknown)
            //        
            //} catch(e) {
            //   lastError = e;
            //   // do something else with error
            //    console.log("lastError: " + lastError);
            //}

        //    // Returns stacktrace from lastError!
            //console.dir({stacktrace:printStackTrace({e: lastError})});
            //var stacktrace = printStackTrace();
            //for ( var i = 0; i < stacktrace.length; i++ ) {
            //    console.error(stacktrace[i]);
            //}


            console.log("END OF TEST");
//        }
//	}
//]);	// doh.register


////]}}
 
 
 
////Execute D.O.H. in this remote file.
//doh.run();



}); // dojo.addOnLoad


