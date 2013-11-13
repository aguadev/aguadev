dojo.provide("plugins.form.UploadDialog");

// UPLOADER
dojo.require("plugins.dojox.form.Uploader");
dojo.require("dojox.form.uploader.FileList");
//dojo.require("dojox.form.uploader.plugins.Flash");
dojo.require("dojox.form.uploader.plugins.HTML5");
//dojo.require("dojox.form.uploader.plugins.IFrame");

// LAYOUT
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");
dojo.require("plugins.core.Common");

dojo.require("dijit._Widget");
dojo.require("dijit._Templated");

// REGISTRY
dojo.require("dijit.registry");


dojo.declare( "plugins.form.UploadDialog",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "form/templates/uploaddialog.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT WIDGET
parentWidget : null,

uploaderId : dijit.getUniqueId("plugins.form.UploadDialog"),

// username : String
//		Login authentication username
username : null,

// sessionid : String
//		Login authentication session ID
sessionid : null,

// token : String
//		Token used for callback disambiguation
token : "",

// path : String
//		Hash containing 

// action : String
// CGI URL to send data
action : "../../../../../../cgi-bin/aguadev/upload.cgi",

// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins", "form/css/uploaddialog.css"),
	dojo.moduleUrl("dojox", "form/resources/UploaderFileList.css"),
	dojo.moduleUrl("dijit", "themes/dijit.css")
],

////}}}}
constructor : function(args) {
	console.log("UploadDialog.constructor    args: ");
	console.dir({args:args});

	// SET ARGS
	if ( args != null ) {
        this.url = args.url;
    	this.parentWidget = args.parentWidget;
    	this.username = args.username;
    	this.sessionid = args.sessionid;
		if ( args.path ) {
	    	this.path = args.path;
		}
    }

	// SET AUTHENTICATION
	this.setAuthentication();
	
	// LOAD CSS
	this.loadCSS(this.cssFiles);
},
postCreate: function() {
// RUN STARTUP
	console.log("UploadDialog.postCreate    plugins.form.UploadDialog.postCreate()");
	this.startup();
},
startup : function () {
	console.log("UploadDialog.startup    plugins.form.UploadDialog.startup()");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
    
	this.username = Agua.cookie('username');
	this.sessionid=	Agua.cookie('sessionid');
	
    // SET UP UPLOADER
    this.setUploader();
},
clear : function () {
	console.log("UploadDialog.clear    this.fileList:");
	console.dir({fileList:this.fileList});
	this.fileList.reset();
},
setAuthentication : function () {
	console.log("UploadDialog.setAuthentication    Agua:");
	console.dir({Agua:Agua});
	
	this.username = Agua.cookie('username')
	this.sessionid = Agua.cookie('sessionid')
},
setUploader : function () {
	console.log("UploadDialog.setUploader    plugins.form.UploadDialog.setUploader()");
	console.log("UploadDialog.setUploader    this.token: " + this.token);
	
	// SET UPLOAD ID INFO
	this.uploader.username = this.username;
	this.uploader.sessionid = this.sessionid;
	this.uploader.token = this.token;
	this.uploader.mode = this.mode;
	console.log("UploadDialog.setUploader    this.uploader: " + this.uploader);
	console.dir({this_uploader:this.uploader});	
	
	// SET HANDLE UPLOAD
	this.handleUpload(this.uploader, this.images);

	// CONNECT UPLOADER onComplete TO THIS onComplete	
	dojo.connect(this.uploader, "onComplete", this, "onComplete");

	var thisObject = this;
    this.uploader.onComplete = function(/* Object */customEvent){
	// 		Fires when all files have uploaded
	// 		Event is an array of all files
        console.log("UploadDialog.setUploader    INSIDE this.uploader.onComplete");
        console.log("UploadDialog.setUploader    customEvent: ");
		console.dir({customEvent:customEvent});

        thisObject.onComplete(customEvent);

    	//this.reset();
    }

	this.uploader.createXhr = function(){
		
		console.log("UploadDialog.setUploader    OVERRIDE plugins.dojox.form.Uploader.HTML5.createXhr()");

		var xhr = new XMLHttpRequest();
		var timer;
        xhr.upload.addEventListener("progress", dojo.hitch(this, "_xhrProgress"), false);
        xhr.addEventListener("load", dojo.hitch(this, "_xhrProgress"), false);
        xhr.addEventListener("error", dojo.hitch(this, function(evt){
			this.onError(evt);
			clearInterval(timer);
		}), false);
        xhr.addEventListener("abort", dojo.hitch(this, function(evt){
			this.onAbort(evt);
			clearInterval(timer);
		}), false);
        xhr.onreadystatechange = dojo.hitch(this, function() {
			if (xhr.readyState === 4) {
				console.info("plugins.dojox.form.uploader.plugins.HTML5    COMPLETE")
				clearInterval(timer);
				//this.onComplete(dojo.eval(xhr.responseText));
				this.onComplete({});
			}
		});
        xhr.open("POST", this.getUrl());

		timer = setInterval(dojo.hitch(this, function(){
			try{
				if(typeof(xhr.statusText)){} // accessing this error throws an error. Awesomeness.
			}catch(e){
				//this.onError("Error uploading file."); // not always an error.
				clearInterval(timer);
			}
		}),250);

		return xhr;
	};
},
handleUpload : function(upl, node){

	dojo.connect(upl, "onComplete", function(dataArray){

        console.log("UploadDialog.handleUpload    INSIDE dojo.connect");
		
		dojo.forEach(dataArray, function(file){
			console.log("display:", file)

			var div = dojo.create('div', {className:'thumb'});
			var span = dojo.create('span', {className:'thumbbk'}, div);
			var img = dojo.create('img', {src:file.file}, span);
			node.appendChild(div);
		});
	});
},
onComplete : function (customEvent) {
// 		Fires when all files have uploaded
// 		Event is an array of all files
    console.log("UploadDialog.onComplete    form.Uploader.onComplete(customEvent)");
    console.info("UploadDialog.onComplete    FILL ME IN");
},
fixInputNode : function () {

    var inputnode = this.uploader._inputs[0];
    console.log("UploadDialog.setInputNode     inputnode: " + inputnode);
    console.dir(inputnode);

    var style = dojo.attr(inputnode, 'style');
    console.log("UploadDialog.setInputNode     style: " + dojo.toJson(style));
    style += " left: 0px !important;";
    dojo.attr(inputnode, 'style',  style);    
},
setPath : function (value) {
	console.log("UploadDialog.setPath     plugins.form.UploadDialog.setPath(value)");
	console.log("UploadDialog.setPath     this.path: " + this.path);		
	console.dir({this_path:this.path});	
	console.log("UploadDialog.setPath     value: " + value);		
	if ( value == null )    return;
    this.path = value;
	this.dialog.set('title', "Upload to: " + value);
},
getPath : function () {
	return this.dialog.get('title');
},
show: function () {
// SHOW THE DIALOGUE
	this.dialog.show();
},
hide: function () {
// HIDE THE DIALOGUE

	this.dialog.onHide = function() {
		console.log("UploadDialog.hide   onHide FIRED");
		console.log("UploadDialog.hide   this:");
		console.dir({this:this});

		var underlayNode = dojo.query(".dijitDialogUnderlay")[0];
		console.log("UploadDialog.hide   underlayNode:");
		console.dir({underlayNode:underlayNode});

	    var underlay = dijit.registry.getEnclosingWidget(underlayNode);
		//var underlay = dijit.byNode(underlayNode);	
		console.log("UploadDialog.hide   underlay:");
		console.dir({underlay:underlay});
		underlay.hide();
	};

	var promise = this.dialog.hide();
	
}


});

