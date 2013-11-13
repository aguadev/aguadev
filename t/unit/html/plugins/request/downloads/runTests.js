require([
	"dojo/_base/declare",
	"dijit/registry",
	"dojo/dom",
	"dojo/parser",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/request/Downloads",
	"dojo/ready",
	"dojo/domReady!",
	"dojo/dnd/Source"
],

function (declare, registry, dom, parser, doh, util, Agua, Downloads, ready) {

window.Agua = Agua;
console.dir({Agua:Agua});

////}}}}}

doh.register("plugins.request.Downloads", [

////}}}}}

{

////}}}}}

	name: "new",
	setUp: function(){
	
		Agua.data = {};
		Agua.data.downloads = util.fetchJson("./downloads.json");
	},
	runTest : function(){
		console.log("# new");
		
		var object =	new Downloads({
			attachPoint : dom.byId("attachPoint")
		});
	
		console.log("new    instantiated");
		doh.assertTrue(true);
		

		var tests = [
			{
				slot		:	"fileSize",
				expected	:	"340.8 GB"	
			},
			{
				slot		:	"downloadCount",
				expected	:	4	
			}
		];
		
		for ( var i = 0; i < tests.length; i++ ) {
			var test	=	tests[i];
			console.log("new    " + test.slot + " is " + test.expected);
			doh.assertEqual(object[test.slot].innerHTML, test.expected);
		}
	},
	tearDown: function () {
	}
}
,
{

////}}}}}

	name: "new",
	setUp: function(){
	
		Agua.data = {};
		Agua.data.downloads = util.fetchJson("./downloads.json");
	},
	runTest : function(){
		console.log("# addDownload");
		
		var object	=	new Downloads({
			attachPoint : dom.byId("attachPoint")
		});
	
		var downloads	=	util.fetchJson("./adddownloads.json");

		object.addDownloads(downloads);
		
		console.log("new    instantiated");
		doh.assertTrue(true);
	},
	tearDown: function () {}
}

]);

	//Execute D.O.H. in this remote file.
	doh.run();
});
