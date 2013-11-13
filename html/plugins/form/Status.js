/* SIMPLE WIDGET TO DISPLAY 'loading' AND 'ready' STATUS */

define( "plugins/form/Status", [
	"dojo/_base/declare",
	"dojo/_base/lang",
	"dojo/on",
	"dojo/dom-class",
	"dojo/_base/array",
	"dojo/aspect",
	"dojo/text!plugins/form/templates/status.html",
	"dojo/ready",
	"dijit/_WidgetBase",
	"dijit/_TemplatedMixin",
	"plugins/core/Common",
	"dojo/domReady!"
],

function(
	declare,
	lang,
	on,
	domClass,
	array,
	aspect,
	template,
	ready,
	WidgetBase,
	TemplatedMixin,
	Common
) {

/////}}}}}

return declare("plugins/form/Status",
	[ WidgetBase, TemplatedMixin, Common ], {

// title : String
//		Text title, default is none
title : "",

// loadingTitle : String
//		Text title, default is none
loadingTitle : "Loading ...",

// readyTitle : String
//		Text title, default is none
readyTitle : "",

// templateString : String
//		Template for widget
templateString : template,

// status : String
//		Status values - none, ready or loading 
status : "none",


cssFiles : [
	require.toUrl("plugins/form/css/status.css"),
],

/////}}}}}

constructor : function (args) {
	console.log("Status.constructor    args: ");
	console.dir({args:args});
	
	lang.mixin(this, args);	
},
postCreate : function () {
	console.log("Status.postCreate    this.attachPoint: " + this.attachPoint);

	this.inherited(arguments);
	
	this.loadCSS();	

	var thisObject = this;
	ready(function() {
		thisObject.setListeners();	
	});

	this.attachPane();	

	console.log("Status.postCreate    END");
},
attachPane : function () {
	if ( this.attachPoint ) {
		console.log("Status.attachPane    DOING this.attachPoint.appendChild(this.containerNode)");
		this.attachPoint.appendChild(this.containerNode);
	}	
},
setListeners : function () {
	console.log("Status.setListeners     ");
	
	on(this.containerNode, "click", this.onClick);	
	console.log("Status.setListeners     END");
},
onClick : function () {
	console.log("Status.onClick");
},
setStatus : function (status) {
	console.log("Status.setStatus    status: " + status);
	
	switch (status) {
		case "none": {
			console.log("Status.setStatus    SETTING status to 'none'");
			domClass.remove(this.displayNode, "ready");
			domClass.remove(this.displayNode, "loading");
			domClass.add(this.displayNode, "none");
			
			this.titleNode.innerHTML = this.title;
			
			break;
		}
		case "loading": {
			console.log("Status.setStatus    SETTING status to 'loading'");
			domClass.remove(this.displayNode, "ready");
			domClass.add(this.displayNode, "loading");
			domClass.remove(this.displayNode, "none");

			this.titleNode.innerHTML = this.loadingTitle;

			break;
		}
		case "ready": {
			console.log("Status.setStatus    SETTING status to 'ready'");
			domClass.add(this.displayNode, "ready");
			domClass.remove(this.displayNode, "loading");
			domClass.remove(this.displayNode, "none");

			this.titleNode.innerHTML = this.readyTitle;

			break;
		}
	}
}



});

});
