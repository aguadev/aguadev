console.log("plugins.request.Controller    LOADING");

/* SUMMARY: GENERATE AND MANAGE Request PANES */

define("plugins/request/Controller", [
	"dojo/_base/declare",
	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/core/Common",
	"plugins/request/Request",
	"dijit/form/Button"
],
	   
function (
	declare,
	_Widget,
	_Templated,
	Common,
	Request
) {

////}}}}}

return declare("plugins/request/Controller",

////}}}}}

[
	_Widget,
	_Templated,
	Common	
], {

// templateString : String
//		The template of this widget
templateString: dojo.cache("plugins", "request/templates/controller.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CSS FILE FOR BUTTON STYLING
cssFiles : [
	require.toUrl("plugins/request/css/controller.css")
],

// ARRAY OF TAB PANES
tabPanes : [],

////}}}

// CONSTRUCTOR	
constructor : function(args) {
	console.log("Controller.constructor     plugins.request.Controller.constructor");

	// LOAD CSS FOR BUTTON
	this.loadCSS();	
},
postCreate : function() {
	console.log("Controller.postCreate    plugins.request.Controller.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Controller.startup    plugins.request.Controller.startup()");

	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);

	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab");


// DEBUG: CREATE TAB
this.createTab();

},
createTab : function (args) {
	console.log("Controller.createTab    args: ");
	console.dir({args:args});

	// CLEAR ANNOYING ALL-SELECTED
	window.getSelection().removeAllRanges();
	
	if ( args == null ) args = new Object;
	args.attachPoint = Agua.tabs;

	// CREATE WIDGET	
	var widget = new Request(args);
	this.tabPanes.push(widget);

	// ADD TO _supportingWidgets FOR INCLUSION IN DESTROY	
	this._supportingWidgets.push(widget);
}

}); 

}); 


console.log("plugins.request.Controller    END");