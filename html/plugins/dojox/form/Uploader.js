define([
	"dojo/_base/declare",
	"dojox/form/Uploader",
	"dojo/i18n!./nls/Uploader",
	"dojo/text!./templates/uploader.html"
],
function (declare, Uploader, res, template) {

return declare("plugins.dojox.form.Uploader", [Uploader], {

templateString: template,
label:	res.label,
uploadOnSelect : true,
multiple : false,

// username : String
//		Login authentication username
username : "",

// sessionid : String
//		Login authentication session ID
sessionid : "",

// token : String
//		Token used for callback disambiguation
token : "",

onBegin : function () {
	console.log("plugins.dojox.form.Uploader.onBegin    XXXXXXXXXX");
},

upload: function(/*Object?*/ formData){				
	// summary:
	//		When called, begins file upload. Only supported with plugins.
	console.log("plugins.dojox.form.Uploader.upload    caller: " + this.upload.caller.nom);

	console.log("plugins.dojox.form.Uploader.upload    PASSED formData.username: " + formData.username);
	console.log("plugins.dojox.form.Uploader.upload    PASSED formData.sessionid: " + formData.sessionid);
	console.log("plugins.dojox.form.Uploader.upload    PASSED formData:");
	console.dir({formData:formData});

	formData = formData || {};
	//formData.username = Agua.cookie('username');
	//formData.sessionid = Agua.cookie('sessionid');
	formData.username = this.username;
	formData.sessionid = this.sessionid;
	formData.token = this.token;
	formData.mode = this.mode;
	formData.uploadType = this.uploadType;
	console.log("plugins.dojox.form.Uploader.upload    formData.uploadType: " + formData.uploadType);

	console.log("plugins.dojox.form.Uploader.upload    formData:");
	console.dir({formData:formData});

	this.inherited(arguments);
},

submit: function(/*form Node?*/ form){
	// summary:
	//		If Uploader is in a form, and other data should be sent along with the files, use
	//		this instead of form submit.
	console.log("plugins.dojox.form.Uploader.submit    form:");
	console.dir({form:form});

	form = !!form ? form.tagName ? form : this.getForm() : this.getForm();
	var data = domForm.toObject(form);
	data.uploadType = this.uploadType;

	console.log("plugins.dojox.form.Uploader.submit    DOING this.upload(data), data:");
	console.dir({data:data});
	
	this.upload(data);
}

});

	

});
