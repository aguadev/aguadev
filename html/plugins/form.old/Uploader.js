dojo.provide("plugins.form.UploadDialog");

// UPLOADER
dojo.require("dojox.form.Uploader");
dojo.require("dojox.form.uploader.FileList");
//dojo.require("dojox.form.uploader.plugins.Flash");
dojo.require("dojox.form.uploader.plugins.HTML5");
//dojo.require("dojox.form.uploader.plugins.IFrame");

// LAYOUT
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");
dojo.require("plugins.core.Common");


dojo.declare( "plugins.form.UploadDialog",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "form/templates/uploader.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT WIDGET
parentWidget : null,

// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins", "form/css/uploader.css"),
	dojo.moduleUrl("dojox", "form/resources/UploaderFileList.css"),
	dojo.moduleUrl("dijit", "themes/dijit.css"),
	//dojo.moduleUrl("dijit", "themes/claro/Common.css"),
	//dojo.moduleUrl("dijit", "themes/claro/form/Common.css"),
	//dojo.moduleUrl("dijit", "themes/claro/Dialog.css"),
	//dojo.moduleUrl("dijit", "themes/claro/form/Button.css"),
	//dojo.moduleUrl("dijit", "themes/claro/layout/TabContainer.css"),
	//dojo.moduleUrl("dijit", "themes/claro/Dialog.css"),
],

////}}}}
constructor : function(args) {
	console.log("Uploader.constructor    args: ");
	console.dir({args:args});

	// SET ARGS
	if ( args != null ) {
        this.url = args.url;
    	this.parentWidget = args.parentWidget;
    	this.username = args.username;
    	this.sessionid = args.sessionid;
    	this.path = args.path;
    }
	
	// LOAD CSS
	this.loadCSS(this.cssFiles);
},
postCreate: function() {
// RUN STARTUP
	console.log("Uploader.postCreate    plugins.form.UploadDialog.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Uploader.startup    plugins.form.UploadDialog.startup()");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
    
    // SET UP UPLOADER
    this.setUploader();
},
clear : function () {
	console.log("Uploader.clear    this.fileList:");
	console.dir({fileList:this.fileList});
	this.fileList.reset();
},
setUploader : function () {
	console.log("Uploader.setUploader    plugins.form.UploadDialog.setUploader()");
	console.log("Uploader.setUploader    this.dialog: " + this.dialog);

	//this.dialog.show();
	this.handleUpload(this.uploader, this.images);

	console.log("Uploader.setUploader    this.dialog: " + this.dialog);

	var thisObject = this;
	
	dojo.connect(this.uploader, "onComplete", this, "onComplete");

    this.uploader.onComplete = function(/* Object */customEvent){
	// 		Fires when all files have uploaded
	// 		Event is an array of all files
        console.log("Uploader.onComplete    dojox.form.plugins.Uploader.onComplete(data)");
        console.log("Uploader.onComplete    customEvent: ");
		console.dir({customEvent:customEvent});
        thisObject.onComplete(customEvent);
    	//this.reset();
    }

	this.uploader.createXhr = function(){
		
		console.log("Uploader.setUploader    OVERRIDE plugins.dojox.form.Uploader.HTML5.createXhr()");

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

        console.log("Uploader.handleUpload    INSIDE dojo.connect");
		
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
    console.log("Uploader.onComplete    form.Uploader.onComplete(customEvent)");
    console.info("Uploader.onComplete    FILL ME IN");
},
fixInputNode : function () {

    var inputnode = this.uploader._inputs[0];
    console.log("Uploader.setInputNode     inputnode: " + inputnode);
    console.dir(inputnode);

    var style = dojo.attr(inputnode, 'style');
    console.log("Uploader.setInputNode     style: " + dojo.toJson(style));
    style += " left: 0px !important;";
    dojo.attr(inputnode, 'style',  style);    
},
setPath : function (value) {
	console.log("Uploader.setPath     plugins.form.UploadDialog.setPath(value)");
	console.log("Uploader.setPath     value: " + value);		
	if ( value == null )    return;
    this.path.value = value;
	this.dialog.set('title', "Upload to: " + value);
},
getPath : function () {
	return this.path.innerHTML;
},
show: function () {
// SHOW THE DIALOGUE
	this.dialog.show();
},
hide: function () {
// HIDE THE DIALOGUE
	this.dialog.hide();
}
});

