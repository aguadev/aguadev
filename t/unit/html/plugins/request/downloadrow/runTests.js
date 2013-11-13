require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/DownloadRow",
	"plugins/form/DndSource",
	"dojo/ready",
	"dojo/domReady!",
	"dojo/dnd/Source"
],

function (
	declare,
	registry,
	dom,
	domAttr,
	domClass,
	parser,
	doh,
	util,
	Agua,
	DownloadRow,
	DndSource,
	ready
) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.DownloadRow", [

////}}}}}

{

////}}}}}
	name: "new",
	setUp: function(){
	},
	runTest : function(){
		console.log("# new");
		
		var dndSource = new DndSource({});
		console.log("new    dndSource: " + dndSource);
		console.dir({dndSource:dndSource});
		
		// SET FORM INPUTS (TO SET ROW DATA)
		dndSource.formInputs = {
			filename 	: 	1,
			filesize	:	1
		};

		// SET ROW CLASS
		dndSource.rowClass 	=	"plugins.request.DownloadRow";		

		var node 	=	dom.byId("attachPoint");
		console.log("new    node: " + node);
		console.dir({node:node});

		dndSource.initialiseDragSource(node);
		
		domAttr.set(node, 'style', 'width: 380px !important');
		domClass.add(node, "query");
		

		console.log("new    dndSource:");
		console.dir({dndSource:dndSource});

		var itemArray = util.fetchJson("./downloads.json");
		console.log("new    itemArray:");
		console.dir({itemArray:itemArray});
		dndSource.loadDragItems(itemArray);

		console.log("new    instantiated");
		//doh.assertTrue(true);
	},
	tearDown: function () {}
}
,
{

////}}}}}
	name: "addCommas",
	setUp: function(){
	},
	runTest : function(){
		console.log("# addCommas");
		
		var object = new DownloadRow({});
		console.log("new    object: " + object);
		console.dir({object:object});
		
		var tests = [
			{
				filesize	:	2143185086,
				expected	:	"2,143,185,086"	
			},
			{
				filesize	:	5846360,
				expected	:	"5,846,360"	
			},
			{
				filesize	:	5947062931,
				expected	:	"5,947,062,931"	
			},
			{
				filesize	:	332745314004,
				expected	:	"332,745,314,004"	
			}
		];
		
		for ( var i = 0; i < tests.length; i++ ) {
			var test	=	tests[i];
			var filesize 	=	object.addCommas(test.filesize);
			console.log("shortenFilename    Converted " + test.filesize + " --> " + filesize);
			doh.assertTrue(filesize === test.expected);
		}
		
		console.log("new    instantiated");
		//doh.assertTrue(true);
	},
	tearDown: function () {}
}
,
{

////}}}}}
	name: "shortenFilename",
	setUp: function(){
	},
	runTest : function(){
		console.log("# shortenFilename");
		
		var object = new DownloadRow({});
		console.log("new    object: " + object);
		console.dir({object:object});
		
		var tests = [
			{
				filename	:	"UNCID_2211553.d13cde5b-7e54-46fb-b416-e6c2f5687b8e.110309_UNC3-RDR300156_00080_FC_62J42AAXX_7.tar.gz",
				expected	:	"UNCID_2211..._FC_62J42AAXX_7.tar.gz"	
			},
			{
				filename	:	"C495.TCGA-CR-6470-01A-11D-1870-08.3.bam.bai",
				expected	:	"C495.TCGA-...-11D-1870-08.3.bam.bai"	
			},
			{
				filename	:	"C499.TCGA-BJ-A4O8-10A-01D-A25A-08.5.bam",
				expected	:	"C499.TCGA-...-10A-01D-A25A-08.5.bam"	
			},
			{
				filename	:	"TCGA-KO-8417-01A-11D-2310-10_wgs_Illumina.bam",
				expected	:	"TCGA-KO-84...10-10_wgs_Illumina.bam"	
			}
		];
		
		for ( var i = 0; i < tests.length; i++ ) {
			var test	=	tests[i];
			var filename 	=	object.shortenFilename(test.filename, 10, 22);

			console.log("shortenFilename    Converted " + test.filename + " --> " + filename);
			doh.assertTrue(filename === test.expected);
		}
		
		console.log("new    instantiated");
		//doh.assertTrue(true);
	},
	tearDown: function () {}
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
