require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/query",
	"dojo/json",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/Grid",
	"dojo/ready",
	"dojo/domReady!"
],

function (
	declare,
	registry,
	dom,
	query,
	JSON,
	parser,
	doh,
	util,
	Agua,
	Grid,
	ready
) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.Grid", [

////}}}}}

{	name: "new",
	setUp: function(){
	},
	runTest : function(){
		console.log("# new");
	
		ready(function() {
			var data = util.fetchJson("./data.json");

			// INSTANTIATE
			var grid = new Grid({
				attachPoint : dom.byId("attachPoint"),
				data : data
			});
			console.log("new    instantiated");
			doh.assertTrue(true);
		});
	},
	tearDown: function () {}
}
//,
//{	name: "setGrid",
//	setUp: function(){
//	},
//	runTest : function(){
//		console.log("# setGrid");
//	
//		ready(function() {
//			var data = util.fetchJson("./data.json");
//
//			// INSTANTIATE
//			var grid = new Grid({
//				attachPoint : dom.byId("attachPoint"),
//				data : data
//			});
//
//			// SET GRID
//			grid.setGrid(data); 		
//			console.log("setGrid    setGrid");
//			doh.assertTrue(true);
//
//		});
//	},
//	tearDown: function () {}
//},
//{	name: "updateGrid",
//	setUp: function(){
//		Agua.cgiUrl = "HERE";
//	},
//	runTest : function(){
//		console.log("# updateGrid");
//	
//		ready(function() {
//			console.log("updateGrid    INSIDE ready");
//
//			var data = util.fetchJson("./data.json");
//			var fields = util.fetchJson("./fields.json");
//			var object = new Grid({
//				attachPoint : 	dom.byId("attachPoint"),
//				data		: 	data,
//				fields		:	fields
//			});
//
//			var tests = [
//				//// IS / IS NOT
//				{
//					name		:	"is CGHUB1",
//					datafile	:	"data.json",
//					filterfile	:	"is-CGHUB1.json",
//					expected	:	["CGHUB1","CGHUB1","CGHUB1"],
//					field		:	"Source"
//				},
//				{
//					name		:	"is 'CGHUB1' AND 'CGHUB2'",
//					datafile	:	"data.json",
//					filterfile	:	"is-CGHUB1-and-CGHUB2.json",
//					expected	:	[],
//					field		:	"Source"
//				},
//				{
//					name		:	"is 'CGHUB1' OR 'CGHUB2'",
//					datafile	:	"data.json",
//					filterfile	:	"is-CGHUB1-or-CGHUB2.json",
//					expected	:	["CGHUB1","CGHUB1","CGHUB1","CGHUB2","CGHUB2","CGHUB2"],
//					field		:	"Source"
//				},
//				{
//					name		:	"is not 'CGHUB'",
//					datafile	:	"data.json",
//					filterfile	:	"is-not-CGHUB.json",
//					expected	:	["CGHUB1","CGHUB1","CGHUB1","CGHUB2","CGHUB2","CGHUB2","CGHUB3","CGHUB3","CGHUB4","CGHUB4"],
//					field		:	"Source"
//				},
//				{
//					name		:	"is not 'CGHUB1'",
//					datafile	:	"data.json",
//					filterfile	:	"is-not-CGHUB1.json",
//					expected	:	["CGHUB2","CGHUB2","CGHUB2","CGHUB3","CGHUB3","CGHUB4","CGHUB4"],
//					field		:	"Source"
//				},
//				
//				
//				//// CONTAINS / NOT CONTAINS
//				{
//					name		:	"contains 'CGHUB'",
//					datafile	:	"data.json",
//					filterfile	:	"contains-CGHUB.json",
//					expected	:	["CGHUB1","CGHUB1","CGHUB1","CGHUB2","CGHUB2","CGHUB2","CGHUB3","CGHUB3","CGHUB4","CGHUB4"],
//					field		:	"Source"
//				},
//				{
//					name		:	"not contains 'CGHUB'",
//					datafile	:	"data.json",
//					filterfile	:	"not-contains-CGHUB.json",
//					expected	:	[],
//					field		:	"Source"
//				},
//				{
//					name		:	"not contains 'CGHUB1'",
//					datafile	:	"data.json",
//					filterfile	:	"not-contains-CGHUB1.json",
//					expected	:	["CGHUB2","CGHUB2","CGHUB2","CGHUB3","CGHUB3","CGHUB4","CGHUB4"],
//					field		:	"Source"
//				},
//				{
//					name		:	"not contains 'CGHUB2'",
//					datafile	:	"data.json",
//					filterfile	:	"not-contains-CGHUB2.json",
//					expected	:	["CGHUB1","CGHUB1","CGHUB1","CGHUB3","CGHUB3","CGHUB4","CGHUB4"],
//					field		:	"Source"
//				},
//				
//				
//				//// BEFORE / AFTER / ON
//				{
//					name		:	"before '2013-03-03'",
//					datafile	:	"data.json",
//					filterfile	:	"before-2013-03-03.json",
//					expected	:	["2013-03-02T17:06:01Z","2013-03-02T17:06:01Z"],
//					field		:	"Published Date"
//				},
//				{
//					name		:	"after '2013-03-03'",
//					datafile	:	"data.json",
//					filterfile	:	"after-2013-03-03.json",
//					expected	:	["2013-03-04T19:48:01Z","2013-03-04T23:15:01Z","2013-03-05T19:48:01Z","2013-03-05T23:15:01Z"],
//					field		:	"Published Date"
//				},
//				{
//					name		:	"on '2013-03-03'",
//					datafile	:	"data.json",
//					filterfile	:	"on-2013-03-03.json",
//					expected	:	["2013-03-02T17:06:01Z","2013-03-02T17:06:01Z","2013-03-04T19:48:01Z","2013-03-04T23:15:01Z","2013-03-05T19:48:01Z","2013-03-05T23:15:01Z"],
//					field		:	"Published Date"
//				},
//				
//				//// EQUALS / NOT EQUALS 
//				{
//					name		:	"equals '88888888'",
//					datafile	:	"data.json",
//					filterfile	:	"equals-88888888.json",
//					expected	:	["88888888"],
//					field		:	"filesize"
//				},
//				{
//					name		:	"not equals '88888888'",
//					datafile	:	"data.json",
//					filterfile	:	"not-equals-88888888.json",
//					expected	:	["1069195331","1263283796","1641075823","1827629987","5928704","5980720","5988848","6043704","6095360"],
//					field		:	"filesize"
//				},
//				
//				//// GREATER THAN / LESS THAN
//				{
//					name		:	"greater than '88888888'",
//					datafile	:	"data.json",
//					filterfile	:	"greater-than-88888888.json",
//					expected	:	["1069195331","1263283796","1641075823","1827629987"],
//					field		:	"filesize"
//				},
//				{
//					name		:	"less than '88888888'",
//					datafile	:	"data.json",
//					filterfile	:	"less-than-88888888.json",
//					expected	:	["5928704","5980720","5988848","6043704","6095360"],
//					field		:	"filesize"
//				},
//				
//				
//				//// GREATER THAN OR EQUAL TO / LESS THAN OR EQUAL TO
//				{
//					name		:	"greater than or equal '88888888'",
//					datafile	:	"data.json",
//					filterfile	:	"greater-than-or-equal-88888888.json",
//					expected	:	["1069195331","1263283796","1641075823","1827629987","88888888"],
//					field		:	"filesize"
//				},
//				{	name		:	"less than or equal '88888888'",
//					datafile	:	"data.json",
//					filterfile	:	"less-than-or-equal-88888888.json",
//					expected	:	["5928704","5980720","5988848","6043704","6095360","88888888"],
//					field		:	"filesize"
//				},
//				{	name		:	"all-washington",
//					datafile	:	"data.json",
//					filterfile	:	"all-washington.json",
//					field		:	"Center Name",
//					expected : [
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center",
//					]
//				},
//				{	name		:	"all-university",
//					datafile	:	"data.json",
//					filterfile	:	"all-university.json",
//					field		:	"Center Name",
//					expected : [
//						"Harvard University",
//						"Princeton University, Genome Sequencing Center",
//						"Seattle University",
//						"Seattle University, Genome Sequencing Center",
//						"Stanford University",
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center",
//						"Washington University, Genome Sequencing Center"
//					]
//				},
//				{	name		:	"all-carcinoma",
//					datafile	:	"data.json",
//					filterfile	:	"all-carcinoma.json",
//					field		:	"Disease",
//					expected : [
//						"Uterine Corpus Endometrioid Carcinoma",
//						"Uterine Corpus Endometrioid Carcinoma"
//					] 
//				},
//				{	name		:	"all-oropharyngeal-cancer",
//					datafile	:	"data.json",
//					filterfile	:	"all-oropharyngeal-cancer.json",
//					field		:	"Disease",
//					expected : [
//						"Endometrial Cancer",
//						"Oropharyngeal Cancer",
//						"Thyroid Cancer"
//					] 
//				},
//			];
//
//			for ( var i = 0; i < tests.length; i++ ) {
//				var test	=	tests[i];
//
//				// SET GRID DATA
//				object.data 	= 	util.fetchJson(test.datafile);
//				
//				// RUN FILTERS
//				var filters	=	util.fetchJson(test.filterfile);
//				object.updateGrid(filters);
//				
//				// VERIFY FILTER
//				var filteredData = object.getItems();
//				
//				var expected = test.expected;
//				var actual = [];
//				for ( var j = 0; j < filteredData.length; j++ ) {
//					actual.push(filteredData[j][test.field]);
//				}
//				actual = actual.sort();
//				//console.log("updateGrid    expected: " + JSON.stringify(expected));
//				//console.log("updateGrid    actual: " + JSON.stringify(actual));
//				
//				console.log("updateGrid    " + test.name);
//				doh.assertTrue(util.identicalArrays(expected, actual));
//			}
//			
//		});
//	},
//	tearDown: function () {}
//}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});


