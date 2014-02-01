require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/sharing/Access",
	"dojo/ready",
	"dojo/domReady!",
	"dijit/layout/TabContainer"
],

function (declare, registry, dom, parser, doh, util, Agua, Access, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

var test = "t.unit.plugins.sharing.access.test";
console.log("# test: " + test);
dom.byId("pagetitle").innerHTML = test;
dom.byId("pageheader").innerHTML = test;

////}}}}}

doh.register("plugins.sharing.Access", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
		// ENSURE attachPoint WIDGET IS INSTANTIATED
		parser.parse();
		
		Agua.data = new Object;
		Agua.data.headings = {
			leftPane : [ "Access" ],
			middlePane : [],
			rightPane : []
		};
		
		Agua.data.access = [
			{
			  'owner' : 'syoung',
			  'worldcopy' : '1',
			  'groupwrite' : '1',
			  'worldwrite' : '1',
			  'groupname' : 'mihg',
			  'groupcopy' : '1',
			  'groupview' : '1',
			  'worldview' : '1'
			},
			{
			  'owner' : 'syoung',
			  'worldcopy' : '1',
			  'groupwrite' : '1',
			  'worldwrite' : '1',
			  'groupname' : 'snp',
			  'groupcopy' : '1',
			  'groupview' : '1',
			  'worldview' : '1'
			}
		];
		
		Agua.getAccess = function () {
			return this.data.access;
		}
	},
	runTest : function(){
		console.log("# new");
	
		
		var access = new Access({
			attachPoint : dijit.byId("attachPoint")
		});
		//console.log("access: " + access);
		//console.dir({access:access});
		
		console.log("new    instantiated");
		doh.assertTrue(true);
	},
	tearDown: function () {}
}



]);

	//Execute D.O.H. in this remote file.
	doh.run();
});



////// REGISTER MODULE PATHS
////dojo.registerModulePath("doh","../../dojo/util/doh");	
////dojo.registerModulePath("plugins","../../plugins");	
////dojo.registerModulePath("t","../../t/unit");	
////
////// DOJO TEST MODULES
//////dojo.require("dijit.dijit");
////////dojo.require("dojox.robot.recorder");
////////dojo.require("dijit.robot");
////dojo.require("doh.runner");
////
////// Agua TEST MODULES
////dojo.require("t.doh.util");
////
////// TESTED MODULES
////console.log("BEFORE require(plugins.core.Agua)")
////dojo.require("plugins.core.Agua")
////console.log("BEFORE require(plugins.sharing.Access)")
////dojo.require("plugins.sharing.Access");
//
//var data = new Object;
//data.headings = {
//	leftPane : [ "Access" ],
//	middlePane : [],
//	rightPane : []
//};
//
//data.access = [
//	{
//	  'owner' : 'syoung',
//	  'worldcopy' : '1',
//	  'groupwrite' : '1',
//	  'worldwrite' : '1',
//	  'groupname' : 'mihg',
//	  'groupcopy' : '1',
//	  'groupview' : '1',
//	  'worldview' : '1'
//	},
//	{
//	  'owner' : 'syoung',
//	  'worldcopy' : '1',
//	  'groupwrite' : '1',
//	  'worldwrite' : '1',
//	  'groupname' : 'snp',
//	  'groupcopy' : '1',
//	  'groupview' : '1',
//	  'worldview' : '1'
//	}
//];
//
//
//// GLOBAL Agua VARIABLE
//var Agua;
//
//dojo.addOnLoad(function(){
//
//// GLOBAL Agua VARIABLE
//Agua = new plugins.core.Agua([]);
//Agua.stages = data.stages;
//console.log("Agua: " + Agua);
//console.dir({Agua:Agua});
//
//
////// OVERRIDE Agua METHODS TO SUPPLY TEST DATA
////Agua.getStageParameters = function(moniker) {
////	console.log("Agua.getStageParameters(" + moniker + ")");
////	if ( moniker == "current" )	return data.stageParameters;
////	else return data.previousStageParameters;
////};
//
//var access = new plugins.sharing.Access({
//	attachPoint : dojo.byId("attachPoint")
//});
//console.log("access: " + access);
//console.dir({access:access});
//
//	
//
//
//});

