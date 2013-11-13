define( "plugins.dojox.layout.ExpandoPane", [
	"dojo/_base/declare",
	"dojo/_base/lang",
	"dojo/on",
	"dojo/dom-class",
	"dojo/_base/array",
	"dojo/aspect",
	"dojox/layout/ExpandoPane",
	"plugins/core/Common",
	"dojo/text!plugins/dojox/layout/templates/ExpandoPane.html",
	"dojo/ready",
	"dojo/domReady!"
],
function(
	declare,
	lang,
	on,
	domClass,
	array,
	aspect,
	dojoxExpandoPane,
	Common,
	template,
	ready
) {

return declare("plugins.dojox.layout.ExpandoPane",
	[ dojoxExpandoPane, Common ], {
	
// summary: An adaptation of dojox.layout.ExpandoPane to allow the middle
// 			pane to be shown/hidden, with corresponding adjustments to the
//			width of the right pane
//
width : null,
minWidth : 15,
height : null,
minHeight : 15,
expand : false,

templateString : template,

cssFiles : [
	require.toUrl("plugins/dojox/layout/css/expandopane.css"),
],

postCreate : function () {
	console.log("ExpandoPane.postCreate    plugins.dojox.layout.ExpandoPane.postCreate");

	this.inherited(arguments);
	
	this.loadCSS();	

	var thisObject = this;
	//ready(function() {
		thisObject.setVerticalTitle();	
	//});
},
setVerticalTitle : function () {
	console.log("ExpandoPane.setVerticalTitle    this.title: " + this.title);
	console.log("ExpandoPane.setVerticalTitle    this.verticalTitle: " + this.verticalTitle);
	console.log("ExpandoPane.setVerticalTitle    this.startExpanded: " + this.startExpanded);
	
	this.verticalTitle.innerHTML = this.title;
	aspect.after(this, "toggle", this.toggleVerticalTitle);	

	// SET verticalTitle TO VISIBLE IF NOT this.startExpanded
	if ( ! this.startExpanded ) {
		domClass.remove(this.verticalTitle, "hidden");
	}
},
toggleVerticalTitle : function () {
	console.log("ExpandoPane.toggleVerticalTitle    this.title: " + this.title);
	console.log("ExpandoPane.toggleVerticalTitle    this._showing: " + this._showing);
	if ( ! this._showing ) {
		domClass.remove(this.verticalTitle, "hidden");
	}
	else {
		domClass.add(this.verticalTitle, "hidden");
	}	
}



});

});
