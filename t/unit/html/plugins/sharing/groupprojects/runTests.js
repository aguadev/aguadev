require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/sharing/GroupProjects",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, GroupProjects, ready) {

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;
Agua.cookie('username', "admin");

// TESTED OBJECT
var object;
window.object = object;

// TEST NAME
var test = "unit.plugins.sharing.groupprojects";
console.log("# test: " + test);
dom.byId("pagetitle").innerHTML = test;
dom.byId("pageheader").innerHTML = test;

doh.register(test, [
{
	name: "new",
	setUp: function(){
		Agua.data = {};
		Agua.data.projects = util.fetchJson("projects.json");
		Agua.data.groups = util.fetchJson("groups.json");
		console.log("new    Agua.data: ");
		console.dir({Agua_data:Agua.data});
	},
	runTest : function(){
		console.log("# print");

		var attachPoint	=	dom.byId("attachPoint");
		console.log("new    attachPoint:");
		console.dir({attachPoint:attachPoint});
		
		object = new GroupProjects({
			attachPoint: dom.byId("attachPoint")
		});
		
		doh.assertTrue(true);
	},
	timeout: 10000 
}

]);	// doh.register

	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

