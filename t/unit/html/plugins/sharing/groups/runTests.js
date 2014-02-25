require([
	"dojo/_base/declare",
	"dojo/dom",
	"dojo/dom-style",
	"dojo/dom-class",
	"dojo/dom-geometry",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	"plugins/sharing/Groups",
	"dojo/domReady!"
],

function (declare,
	dom,
	domStyle,
	domClass,
	domGeom,
	doh,
	util,
	Agua,
	Groups,
	ready
) {

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;
Agua.cookie('username', "admin");

// TESTED OBJECT
var object;
window.object = object;

// TEST NAME
var test = "unit.plugins.sharing.groups";
console.log("# test: " + test);
dom.byId("pagetitle").innerHTML = test;
dom.byId("pageheader").innerHTML = test;

doh.register(test, [
{
	name: "new",
	setUp: function(){
		Agua.data = {};
		Agua.data.groups = util.fetchJson("groups.json");
		console.log("new    Agua.data: ");
		console.dir({Agua_data:Agua.data});

		domClass.add(dom.byId("attachPoint"), "sharing");
		domClass.add(document.body, "dojoDndCopy");
	},
	runTest : function(){
		console.log("# print");

		var attachPoint	=	dom.byId("attachPoint");
		console.log("new    attachPoint:");
		console.dir({attachPoint:attachPoint});
		
		object = new Groups({
			attachPoint: dom.byId("attachPoint")
		});

		console.log("new    object.dragSource: "+ object.dragSource);
		console.dir({object_dragSource:object.dragSource});
		var nodes = object.dragSource.getAllNodes();
		console.log("new    nodes");
		console.dir({nodes:nodes});

		var avatar1	=	object.dragSource.creator(nodes[0]);
		console.log("new    avatar1");
		console.dir({avatar1:avatar1});
		document.body.appendChild(avatar1.node);
		domClass.add(avatar1.node.firstChild, "dojoDndAvatar dojoDndAvatarCanDrop");
		
			// LATER: DELETE
			//var geom = domGeom.position(avatar1.node, true);
			//console.log("new    geom:");
			//console.dir({geom:geom});
			//domStyle.set(avatar1.node, { visibility: "visible", "left": '400px !important', "top": '400px' });
			
			////domGeom.position(avatar1.node, true);
			//domStyle.set(avatar1.node, "left", "400px");
			//domStyle.set(avatar1.node, "top", "400px");
		
		
		var avatar2	=	object.dragSource.creator(nodes[1]);
		console.log("new    avatar2");
		console.dir({avatar2:avatar2});
		document.body.appendChild(avatar2.node);
		domClass.add(avatar2.node.firstChild, "dojoDndAvatar");
		
		doh.assertTrue(true);
	},
	timeout: 10000 
}

]);	// doh.register

	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

