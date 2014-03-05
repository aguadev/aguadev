test( "hello test", function() {
  ok( 1 == "1", "Passed!" );
});


//require([
//	"dojo/_base/declare",
//	"dijit/registry",
//	"dojo/dom",
//	"dojo/parser",
//	"doh/runner",
//	"t/unit/doh/util",
//	"t/unit/doh/Agua",
//	"plugins/apps/Packages",
//	"dojo/ready",
//	"dojo/domReady!"
//],
//
//function (declare, registry, dom, parser, doh, util, Agua, Packages, ready) {
//
//window.Agua = Agua;
//console.dir({Agua:Agua});
//
//// TEST NAME
//var test = "unit.plugins.apps.packages";
//console.log("# test: " + test);
//dom.byId("pagetitle").innerHTML = test;
//dom.byId("pageheader").innerHTML = test;
//
//// TESTED OBJECT
//var object;
//window.object = object;
//
//////}}}}}
//
//doh.register("plugins.apps.Packages", [
//
//////}}}}}
//
//{
//
//////}}}}}
//
//	name: "new",
//	setUp: function(){
//		Agua.data = new Object;
//		Agua.data.packages = util.fetchJson("./packages.json");
//		Agua.cookie("username", "admin");
//		
//		Agua.getApps = function () {
//			console.log("new    DOING Agua.getApps()");
//			console.log("new    this.data.apps:");
//			console.dir({this_data:this.data});
//			console.dir({this_data_apps:this.data.apps});
//			return this.data.apps;
//		}
//	},
//	runTest : function(){
//		console.log("# new");
//	
//		ready(function() {
//			console.log("new    INSIDE ready");
//	
//			var object = new Packages({
//				attachPoint : dom.byId("attachPoint")
//			});
//			console.log("new    object: " + object);
//			console.dir({object:object});
//			
//			console.log("new    instantiated");
//			doh.assertTrue(true);
//		});
//
//	},
//	tearDown: function () {}
//}
//
//
//
//]);
//
//	//Execute D.O.H. in this remote file.
//	doh.run();
//});
//
//

//var modules = {
//// LEFT PANE
//	"apps"			: "Apps",
//	"groupprojects"	:	"GroupProjects",
//	"settings"		:	"Settings",
//	"clusters"		:	"Clusters",
//	
//	// MIDDLE PANE
//	"packages"	:	"Packages",
//	"groups"		:	"Groups",
//	"projects"		:	"Projects",
//	"access"		:	"Access",
//	
//	// RIGHT PANE
//	"groupsources"	:	"GroupSources",
//	"groupusers"	:	"GroupUsers",
//	"sources"		:	"Sources",
//	"users"			:	"Users"
//};
//
//var getUsername = function () {
//	if ( ! url.match(/(.+?)\?([^\?]+),([^,]+)/) )
//		return false;
//	return url.match(/(.+?)\?([^\?]+?),([^,]+)/)[2];
//};
//
//var getSessionId = function () {
//	if ( ! url.match(/(.+?)\?([^\?]+),([^,]+)/) )
//		return false;
//	return url.match(/(.+?)\?([^\?]+?),([^,]+)/)[3];
//};
//
//var getHeadings = function () {
//// GET USERNAME, SESSIONID AND MODULES INFO FROM URL 
//	console.log("getHeadings    plugins.core.getHeadings()");
//	var url = window.location.href;
//	console.log("getHeadings    url: " + url);
//
//	if ( ! url.match(/(.+?)\?([^\?]+),([^,]+),([^,]+)$/) )
//		return false;
//
//	var plugins = url.match(/(.+?)\?([^\?]+),([^,]+),([^,]+)$/)[4];
//	console.log("getHeadings    plugins: " + dojo.toJson(plugins));
//
//	var headings = new Object;
//	var array = plugins.split(/\./);
//	console.log("getHeadings    array: " + dojo.toJson(array));
//	for ( var i = 0; i < array.length; i++ )
//	{
//		var info = array[i].split(/:/);
//		var side = info[0];
//		var name = info[1];
//		console.log("getHeadings    side: " + dojo.toJson(side));
//		console.log("getHeadings    name: " + dojo.toJson(name));
//		var pane = side + "Pane";
//		if ( headings[pane] == null )
//			headings[pane] = new Array;
//		
//		var module = modules[name];
//		console.log("getHeadings    module: " + dojo.toJson(module));
//		headings[pane].push(module);
//	}
//	console.log("getHeadings    headings: " + dojo.toJson(headings));
//
//	return headings;
//};
//
//	
//dojo.addOnLoad(function(){
//
//	Agua = new plugins.core.Agua( {
//		cgiUrl : "../../../../../../cgi-bin/agua/",
//		htmlUrl : "../../../../agua/",
//		dataUrl: "../../../t/json/getData.json"
//	});
//
//	data = t.doh.util.fetchJson("../../../../t/json/getData-110804-admin.json");
//	Agua.loadData(data);	
//
//	console.log("Doing getHeadings()");
//	Agua.data.headings = getHeadings();
//
//}); // dojo.addOnLoad
//
