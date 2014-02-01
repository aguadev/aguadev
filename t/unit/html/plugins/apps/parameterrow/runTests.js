require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/apps/ParameterRow",
	"plugins/form/DndSource",
	"dojo/ready",
	"dojo/domReady!",
	"dojo/dnd/Source"
],

function (declare, registry, dom, parser, doh, util, Agua, ParameterRow, DndSource, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

var test = "t.unit.plugins.apps.parameterrow.test";
console.log("# test: " + test);
dom.byId("pagetitle").innerHTML = test;
dom.byId("pageheader").innerHTML = test;

////}}}}}

doh.register("plugins.apps.ParameterRow", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
		// ENSURE attachPoint __WIDGET__ IS INSTANTIATED
		parser.parse();
		
		//Agua.data = new Object;
		//Agua.data.parameters = util.fetchJson("./parameters.json");
	},
	runTest : function(){
		console.log("# new");
		
		var dndSource = new DndSource({});

		var node 	=	dom.byId("attachPoint");
		console.log("new    node: " + node);
		console.dir({node:node});

		dndSource.initialiseDragSource(node);
		dndSource.rowClass 	=	"plugins.apps.ParameterRow";		
		dndSource.formInputs = {
		// FORM INPUTS AND TYPES (word|phrase)
			locked: "",
			name: "word",
			argument: "word",
			valuetype: "word",
			category: "word",
			value: "word",
			ordinal: "word",
			discretion: "word",
			description: "phrase",
			paramtype: "paramtype",
			format: "word",
			args: "word",
			inputParams: "phrase",
			paramFunction: "phrase"
		};
		console.log("new    dndSource:");
		console.dir({dndSource:dndSource});

		var itemArray = util.fetchJson("./sleep.json");
		console.log("new    itemArray:");
		console.dir({itemArray:itemArray});

		console.log("new    BEFORE dndSource.loadDragItems(itemArray)");
		dndSource.loadDragItems(itemArray);
		console.log("new    AFTER dndSource.loadDragItems(itemArray)");

		console.log("new    instantiated");
		//doh.assertTrue(true);
	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});



//var modules = {
//// LEFT PANE
//	"apps"			: "Apps",
//	"groupprojects"	:	"GroupProjects",
//	"settings"		:	"Settings",
//	"clusters"		:	"Clusters",
//	
//	// MIDDLE PANE
//	"parameters"	:	"ParameterRow",
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
