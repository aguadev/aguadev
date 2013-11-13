require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"dojo/json",
	"plugins/dijit/Version",
	"dojo/ready"
],

function (declare,
	registry,
	dom,
	parser,
	doh,
	util,
	JSON,
	Version,
	ready) {

window.Agua = Agua;

////}}}}}

doh.register("t.unit.plugins.dijit.Version", [

//}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
	},
	runTest : function(){
		console.log("# new");

		ready( function() {
		
			var tests = [
				{
					options	: {
						version		: 	"0.0.2",
						locked		:	"true",
						attachPoint	:	dom.byId("attachPoint")
					}
					,
					expected :	"none"
				}
			];
			
			for ( var i in tests ) {
				var test = tests[i];

				var version = new Version(test.options);
				console.log("instantiate    version:");
				console.dir({version:version});
				
				
				doh.assertTrue(true);

			}
		});
		
	},
	tearDown: function () {}
}
,
{

////}}}}}

	name: "parseVersion",
	setUp: function(){
	},
	runTest : function(){
		console.log("# parseVersion");

		ready( function() {
		
			var tests = [
				{
					version		: 	"0.0.2",
					expected :	{
						major 	: 	"0",
						minor 	: 	"0",
						patch 	: 	"2",
						build 	: 	"",
						release	:	""
					}						
				}
				,
				{
					version		: 	"0.0.2-rc.2+build.1",
					expected :	{
						major 	: 	"0",
						minor 	: 	"0",
						patch 	: 	"2",
						build 	: 	"+build.1",
						release	:	"-rc.2"
					}						
				}
			];
			
			// LINE BREAK
			var hr = document.createElement("HR");
			document.body.appendChild(hr);

			var divContainer = document.createElement("DIV");
			document.body.appendChild(divContainer);
			divContainer.style.position = "relative";

			var divTop = -40;
			for ( var i in tests ) {
				var test = tests[i];

				var div = document.createElement("DIV");
				divContainer.appendChild(div);
				div.style.position = "relative";
				divTop += 40;
				div.style.top = divTop + "px";
				
				var object = new Version({
					attachPoint : div
				});
				//console.log("parseVersion    object:");
				//console.dir({object:object});
				var version = object.parseVersion(test.version);
				//console.log("parseVersion    version:");
				//console.dir({version:version});
				//console.log("parseVersion    test.expected:");
				//console.dir({test_expected:test.expected});

				console.log("parseVersion    doh.assertEqual(version, expected), expected: " + JSON.stringify(test.expected));
				doh.assertEqual(version, test.expected);

			}
		});
		
	},
	tearDown: function () {}
}
,
{

////}}}}}

	name: "setVersion",
	setUp: function(){
	},
	runTest : function(){
		console.log("# setVersion");

		ready( function() {
		
			var tests = [
				{
					version		: 	"0.0.2",
					expected :	{
						major 	: 	"0",
						minor 	: 	"0",
						patch 	: 	"2",
						build 	: 	"",
						release	:	""
					}						
				}
				,
				{
					version		: 	"0.0.2-rc.2+build.1",
					expected :	{
						major 	: 	"0",
						minor 	: 	"0",
						patch 	: 	"2",
						build 	: 	"+build.1",
						release	:	"-rc.2"
					}						
				}
			];
			
			// LINE BREAK
			var hr = document.createElement("HR");
			document.body.appendChild(hr);

			var table = document.createElement("TABLE");
			document.body.appendChild(table);

			for ( var i in tests ) {
				var test = tests[i];

				var tableRow = document.createElement("TR");
				table.appendChild(tableRow);

				var tableData = document.createElement("TD");
				tableRow.appendChild(tableData);
				
				var object = new Version({
					attachPoint : tableData
				});
				//console.log("setVersion    object:");
				//console.dir({object:object});
				var version = test.expected;

				object.setVersion(version.major, version.minor, version.patch, version.release + version.build);
				var expected = test.expected.release + test.expected.build;
				var suffix = object.suffixInput.value;
				//console.log("setVersion    expected: " + expected);
				//console.log("setVersion    suffix: " + suffix);
				
				console.log("setVersion    doh.assertEqual(version, expected), expected: " + expected);
				doh.assertEqual(suffix, expected);
			}
		});
		
	},
	tearDown: function () {}
}
,
{

////}}}}}

	name: "higherSemVer",
	setUp: function () {},
	runTest : function () {
		console.log("# higherSemVer");

		ready( function() {
		
			var tests = [
				{
					first:	"0.7.2",
					second:	"0.6.0",
					expected: 1,
					description: "compare 0.7.2 and 0.6.0"
				}
				,
				{
					first: "0.6.0",
					second:	"0.6.1",
					expected:	-1,
					description: "compare 0.6.0 and 0.6.1"
				}
				,
				{
					first:	"0.6.0",
					second:	"0.6.0+build.1",
					expected:	-1,
					description: "compare 0.6.0 and 0.6.0+build.1"
				}
				,
				{
					first:	"0.6.0",
					second:	"0.6.0-alpha.1",
					expected:	1,
					description:	"compare 0.6.0 and 0.6.0-alpha.1"
				}
			];
			
			// LINE BREAK
			var hr = document.createElement("HR");
			document.body.appendChild(hr);

			var table = document.createElement("TABLE");
			document.body.appendChild(table);

			for ( var i in tests ) {
				var test = tests[i];

				var tableRow = document.createElement("TR");
				table.appendChild(tableRow);

				var tableData = document.createElement("TD");
				tableRow.appendChild(tableData);
				
				var object = new Version({
				});
				
				var comparison = object.higherSemVer(test.first, test.second);
				var expected = test.expected;
				console.log("setVersion    expected: " + expected);
				console.log("setVersion    comparison: " + comparison);
				
				console.log("setVersion    doh.assertEqual(comparison, expected), expected: " + expected);
				var text	=	document.createTextNode("Testing " + test.description);
				tableData.appendChild(text);
				doh.assertEqual(comparison, expected);
			}
		});
		
	},
	tearDown: function () {}
}
,
{

////}}}}}

	name: "versionSort",
	setUp: function () {},
	runTest : function () {
		console.log("# versionSort");

		ready( function() {
		
			var tests = [
				{
					versions	:	[ "1.0.0", "0.8.0", "0.9.1", "0.11.0" ],
					expected	:	[ "0.8.0", "0.9.1", "0.11.0", "1.0.0" ],
					description	:	"MINOR ASCII SORTING"
				}
				,
				{
					versions	:	[ "1.0.0", "0.8.0", "0.9.1", "0.11.0", "12.0.0", "2.0.0" ],
					expected	:	[ "0.8.0", "0.9.1", "0.11.0", "1.0.0", "2.0.0", "12.0.0" ],
					description	:	"MAJOR AND MINOR ASCII SORTING"
				}
				,
				{
					versions	:	[
						"2.0.0",
						"1.0.0+build1",
						'1.3.7+build.1',
						'1.3.7+build.11.e0f985a',
						'1.3.7+build.2.b8f12d7',
						"1.0.0"
					],
					expected	:	[	
						"1.0.0",
						"1.0.0+build1",
						'1.3.7+build.1',
						'1.3.7+build.2.b8f12d7',
						'1.3.7+build.11.e0f985a',
						"2.0.0"
					],
					description	:	"BUILDS WITH SUFFIXES, NON-STANDARD ENDINGS"
				}
				,
				{
					versions	:	[ "0.8.0+build11", "0.8.0+build1", "0.8.0+build2" ],
					expected	:	[ "0.8.0+build1", "0.8.0+build2", "0.8.0+build11" ],
					description	:	"BUILDS"
				}
				,
				{
					versions	:	[ "0.8.0+build1", "0.8.0+build2",  "0.8.0+build11" ],
					expected	:	[ "0.8.0+build1", "0.8.0+build2", "0.8.0+build11" ],
					description	:	"BUILDS"
				}
				,
				{
					versions	:	[ "0.8.0+build1", "0.8.0+build11", "0.8.0+build2" ],
					expected	:	[ "0.8.0+build1", "0.8.0+build2", "0.8.0+build11" ],
					description	:	"BUILDS"
				}
				,
				{
					versions	:	[ "0.8.0+build11", "0.8.0-rc2" ],
					expected	:	[ "0.8.0-rc2", "0.8.0+build11" ],
					description	:	"BUILD VERSUS RELEASE"
				}
				,
				{
					versions	:	[ "0.8.0-beta.1+build.1", "0.8.0-beta.1", "0.8.0-alpha.1+build.1", "0.8.0-alpha.1" ],
					expected	:	[ "0.8.0-alpha.1", "0.8.0-alpha.1+build.1", "0.8.0-beta.1", "0.8.0-beta.1+build.1" ],
					description	:	"BUILD VERSUS RELEASE"	
				}
				,
				{
					versions	:	[ "1.0.0", "0.8.0", "0.9.1", "0.11.0", "12.0.0", "2.0.0", "0.8.0-alpha", "0.8.0-alpha.1", "0.8.0-beta", "0.8.0-rc2", "0.8.0+build11", "0.8.0+build1" ],
					expected	:	["0.8.0-alpha","0.8.0-alpha.1","0.8.0-beta","0.8.0-rc2", "0.8.0","0.8.0+build1","0.8.0+build11", "0.9.1","0.11.0","1.0.0","2.0.0","12.0.0"],
					description	:	"COMPOSITE: MIXTURE OF VERSIONS, RELEASES AND BUILDS IN 3 PERMUTATIONS"
				}
				,
				{
					versions	:	[ "2.0.0",  "0.8.0+build11", "0.8.0+build1", "0.8.0-alpha", "0.8.0-alpha.1", "0.8.0-beta", "0.8.0-rc2", "1.0.0", "0.8.0", "0.9.1", "0.11.0", "12.0.0" ],
					expected	:	["0.8.0-alpha","0.8.0-alpha.1","0.8.0-beta","0.8.0-rc2","0.8.0","0.8.0+build1","0.8.0+build11","0.9.1","0.11.0","1.0.0","2.0.0","12.0.0"],
					description	:	"COMPOSITE: MIXTURE OF VERSIONS, RELEASES AND BUILDS IN 3 PERMUTATIONS"
				}
				,
				{
					versions	:	[ "0.8.0-alpha", "0.8.0-alpha.1",  "0.8.0-alpha.12",  "0.8.0-alpha.2",  "0.8.0-beta", "0.8.0-rc2", "0.8.0+build11", "0.8.0+build1", "0.8.0+build2" ],
					expected	:	["0.8.0-alpha","0.8.0-alpha.1","0.8.0-alpha.2","0.8.0-alpha.12","0.8.0-beta","0.8.0-rc2", "0.8.0+build1","0.8.0+build2","0.8.0+build11"],
					description	:	"COMPOSITE: MIXTURE OF VERSIONS, RELEASES AND BUILDS IN 3 PERMUTATIONS"
				}

			];
			
			// LINE BREAK
			var hr = document.createElement("HR");
			document.body.appendChild(hr);
			
			// TABLE
			var table = document.createElement("TABLE");
			document.body.appendChild(table);

			for ( var i in tests ) {
				var test = tests[i];

				var tableRow = document.createElement("TR");
				table.appendChild(tableRow);

				var tableData = document.createElement("TD");
				tableRow.appendChild(tableData);
				
				var object = new Version({});
				
				var sorted = object.sortVersions(dojo.clone(test.versions));
				var expected = test.expected;
				console.log("setVersion    sorted: " + JSON.stringify(sorted));
				console.log("setVersion    expected: " + JSON.stringify(expected));
				console.log("setVersion    doh.assertEqual(comparison, expected), expected: " + expected);
				// REPORT TEST
				var text	=	document.createTextNode("versionSort " + test.description + ": " + JSON.stringify(test.versions) + " --> " + JSON.stringify(expected));
				tableData.appendChild(text);
				doh.assertTrue(object.arraysHaveSameOrder(sorted, expected));
			}
		});
		
	},
	tearDown: function () {}
}
,
{

////}}}}}

	name: "parseVersion",
	setUp: function () {},
	runTest : function () {
		console.log("# parseVersion");

		ready( function() {

			var tests = [
				{
					version		:	"1.0.0-alpha",
					expected	:	[1, 0, 0, "alpha", ""]
				},
				{
					version		:	"1.0.0-alpha.1",
					expected	:	[1, 0, 0, "alpha.1", ""]
				},
				{
					version		:	"1.0.0-beta.2",
					expected	:	[1, 0, 0, "beta.2", ""]
				},
				{
					version		:	"1.0.0-beta.11",
					expected	:	[1, 0, 0, "beta.11", ""]
				},
				{
					version		:	"1.0.0-rc.1",
					expected	:	[1, 0, 0, "rc.1", ""]
				},
				{
					version		:	"1.0.0-rc.1+build.1",
					expected	:	[1, 0, 0, "rc.1", "build.1"]
				},
				{
					version		:	"1.0.0",
					expected	:	[1, 0, 0, "", ""]
				},
				{
					version		:	"1.0.0+0.3.7",
					expected	:	[1, 0, 0, "", "0.3.7"]
				},
				{
					version		:	"1.3.7+build",
					expected	:	[1, 3, 7, "", "build"]
				},
				{
					version		:	"1.3.7+build.2.b8f12d7",
					expected	:	[1, 3, 7, "", "build.2"]
				},
				{
					version		:	"1.3.7+build.11.e0f985a",
					expected	:	[1, 3, 7, "", "build.11"]
				}
			];
			
			// LINE BREAK
			var hr = document.createElement("HR");
			document.body.appendChild(hr);
			
			// TABLE
			var table = document.createElement("TABLE");
			document.body.appendChild(table);

			for ( var i in tests ) {
				var test = tests[i];

				var tableRow = document.createElement("TR");
				table.appendChild(tableRow);

				var tableData = document.createElement("TD");
				tableRow.appendChild(tableData);
				
				var object = new Version({});
				
				// REPORT TEST
				var text	=	document.createTextNode("parseVersion: " + JSON.stringify(test.version) + " --> " + JSON.stringify(test.expected));
				tableData.appendChild(text);

				console.log("setVersion    test.expected: " + JSON.stringify(test.expected));
				var version = object.parseVersion(test.version);
				console.log("setVersion    version: " + JSON.stringify(version));
		
				var matched = 0;
				if (
					version.major === test.expected[0]
					&& version.minor === test.expected[1]
					&& version.patch === test.expected[2]
					&& version.release === test.expected[3]
					&& version.build === test.expected[4]
				) { matched = 1; }
				console.log("setVersion    matched: " + matched);
				doh.assertEqual(matched, 1);
			}
		});
		
	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
