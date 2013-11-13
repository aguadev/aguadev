require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"plugins/core/Util/ViewSize",
	"dojo/domReady!"
],

function (declare, dom, doh, util, ViewSize) {

console.log("# plugins.core.Util.viewsize");

/////}}}}}}

doh.register("plugins.core.Util.viewsize", [

/////}}}}}}

{
/////}}}}}}
	name: "# instantiate",
	setUp: function(){
	},
	runTest : function(){

		// CREATE INSTANCE OF Dialog.Manifest
		viewSize = new ViewSize({});
		console.log("instantiate    viewSize: " + viewSize);
		console.dir({viewSize:viewSize});
	}
}
	
]);

// Execute D.O.H.
doh.run();


});
