require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/graph/Graph",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Graph, ready) {

console.log("# plugins.graph.Graph");

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;


// DATA URL
var url 	= "./getData.json";	

doh.register("plugins.graph.Graph", [

//{
//	name: "parseUSDate",
//	setUp: function(){
//		Agua.data = util.fetchJson(url);
//	},
//	runTest : function(){
//		console.log("# parseUSDate");
//
//		var graph = new Graph();
//		var tests = [
//			{
//				date:	"2012-03-21",
//				expected: ["2012", "02", "21"]
//			}
//			,
//			{
//				date:	"2013-04-23",
//				expected: ["2013", "03", "23"]
//			}
//		];
//		
//		for ( var i in tests ) {
//			var test = tests[i];
//			var date = test.date;
//			var expected = test.expected;
//			var result = graph.parseUSDate(date);
//
//			doh.assertEqual(result, expected, "parseUSDate");		
//		}
//		
//	}
//}
//,
//{
//	name: "dateToUnixTime",
//	setUp: function(){
//		Agua.data = util.fetchJson(url);
//	},
//	runTest : function(){
//		console.log("# dateToUnixTime");
//		var graph = new Graph();
//		var tests = [
//			{
//				date:	"2012-03-21",
//				expected: 1332313200
//			}
//			,
//			{
//				date:	"2013-04-23",
//				expected: 1366700400 
//			}
//		];
//		
//		for ( var i in tests ) {
//			var test = tests[i];
//			var date = test.date;
//			var expected = test.expected;
//			//console.log("dateToUnixTime    date: " + date);
//			//console.log("expectedToUnixTime    expected: " + expected);
//			var array 	= date.split("-");
//			var unixTime = graph.dateToUnixTime(array[0], parseInt(array[1] - 1), array[2]);
//			//console.log("dateToUnixTime    unixTime: " + unixTime);
//
//			doh.assertEqual(unixTime, expected, "dateToUnixTime");		
//		}
//		
//	}
//}
	//,
{
	name: "print",
	setUp: function(){
		Agua.data = util.fetchJson(url);
	},
	runTest : function(){
		console.log("# print");
		
		// ATTACH POINT
		var attachPoint = dom.byId("attachPoint");
		
		var graph = new Graph();
		

		console.log("print    graph: " + graph);
		console.dir({graph:graph});
		//var data = util.fetchJson("print-data.json");

		var location = window.location;
		console.log("print    location: " + location);
		console.dir({location:location});
		location = location.toString().match(/^(.+\/infusiondev\/)/)[0];
		
		var text = graph.fetchSyncText(location + "t/plugins/graph/test1.csv");
		//var text = graph.fetchSyncText("http://localhost/infusiondev/t/plugins/graph/test1.csv");
		//console.log("print    text: " + text);
		//console.dir({text:text});
		var csv = text.split("\n");
		//console.log("print    csv: ");
		//console.dir({csv:csv});
		var headers = csv.shift();
		//console.log("print    headers: " + headers);

		var index1 = 1;
		var index2 = 2;
		
		var xLabel;
		var yLabel;

		// IF THE xLabel AND yLabel ARE NOT PROVIDED AS ARGUMENTS,
		// GET THEM FROM THE CSV HEADER LINE BASED ON THEIR INDEXES
		var xLabel = headers[index1];
		var yLabel = headers[index2];
		
		// SET COLUMNS TO BE EXTRACTED FROM THE FILE BASED ON THEIR INDEXES
		var columns = [index1, index2];
		var values = graph.csvToValues(csv, columns)
		console.log("print    values: ");
		console.dir({values:values});

		// CONVERT DATE TO UNIX TIME
		for ( var i = 0; i < values.length; i++ ) {
			if ( ! values[i][0] )	continue;
			var array = graph.parseUSDate(values[i][0]);
			
			values[i][0] = ( graph.dateToUnixTime(array[0], array[1], array[2]) ) * 1000;
		}
		
		var values2 = [];
		for ( var i = 0; i < values.length; i++ ) {
			values2[values.length - (i + 1)] = values[i];
		}
		
		var data = [
			{
				key 	: 	"Freq1",
				bar		:	true,
				values	:	values
			}
			,
			{
				key 	: 	"Freq2",
				bar		:	false,
				values	:	values2
			}
		];
		//console.log("print    data: ");
		//console.dir({data:data});

		var series = graph.dataToSeries(data);
		//console.log("print    series: ");
		//console.dir({series:series});
		
		graph.print(attachPoint, series, "linePlusBarWithFocusChart", "Date", "Freq", "Change in Frequency over Time");

		

	}
}

]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
