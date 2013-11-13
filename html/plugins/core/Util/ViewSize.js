define([
    "dojo/_base/declare",
    "dojo/dom",
    "dojo/on",
	"dojo/dom-construct",
    "dojo/ready",
	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/core/Common/Util"
],

function(declare, dom, on, domConstruct, ready, _Widget, _Templated, CommonUtil) {

return declare("ViewSize", [_Widget, _Templated, CommonUtil], {

// templatePath : String
//		Path to template file
templatePath : require.toUrl("plugins/core/Util/templates/viewsize.html"),

widgetsInTemplate : true,

// cssFiles : String[]
// 		Load these CSS files in constructor
cssFiles : [
	require.toUrl("plugins/core/Util/css/viewsize.css")
],

constructor : function () {
    console.log("ViewSize.constructor");

	this.loadCSS();
},
postCreate: function () {
    this.startup();
},
startup: function () {
	this.inherited(arguments);
	
	// ATTACH GRID TO PAGE
	var attachPoint = dom.byId("attachPoint");
	attachPoint.appendChild(this.domNode);

	// CONNECT TO WINDOW resize    
    var thisObject = this;	
	on(window, "resize" ,function() {
		thisObject.updateSizes();
	});
    
	this.updateSizes();
},
updateSizes : function () {
	
	var variables = [
		"innerWidth", "innerHeight",
		"outerWidth", "outerHeight",
		"pageXOffset", "pageYOffset",
		"screenLeft", "screenTop",
		"screenX", "screenY",
		"scrollX", "scrollY"
	];
	
	var data = [];    
	for ( var i = 0; i < variables.length; i++ ) {
		var variable = window[variables[i]];
		this[variables[i]].innerHTML = variable;
	}	
}


}); // declare

}); // define