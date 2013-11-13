require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"plugins/form/UploadDialog",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, UploadDialog, ready) {

// SET GLOBAL
window.Agua = Agua;
console.log("# plugins.form.uploaddialog    AFTER Agua:");
console.dir({Agua:Agua});

// SET COOKIE
Agua.cookie("username", "admin");
Agua.cookie("sessionid", "0000000000.0000.000");


doh.register("plugins.form.uploader",
[
	
{
	name: "getYieldStats",
	setUp: function(){
	},
	runTest : function(){
		var uploaderId = dijit.getUniqueId("plugins.form.UploadDialog");
		var username = "admin";
		var sessionid = "9999999999.9999.999";
		var uploader = new UploadDialog({
			uploaderId: uploaderId,
			username: 	username,
			sessionid: 	sessionid
		});
		//uploader.setPath("Project1/Workflow2");
		uploader.dialog.set('title', "Upload Manifest File");
		
		uploader.show();
	}
}


]);	// doh.register

////]}}

//Execute D.O.H. in this remote file.
doh.run();

}); // require