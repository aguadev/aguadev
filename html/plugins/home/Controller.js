dojo.provide("plugins.home.Controller");

// OBJECT:  plugins.home.Controller
// PURPOSE: GENERATE AND MANAGE Home PANES

// INHERITS
dojo.require("plugins.core.Common");

// HAS
dojo.require("plugins.home.Home");

dojo.declare( "plugins.home.Controller",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "home/templates/controller.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CSS FILE FOR BUTTON STYLING
cssFiles : [ "plugins/home/css/controller.css" ],

// ARRAY OF TAB PANES
tabPanes : [],

////}}}
// CONSTRUCTOR	
constructor : function(args) {
	console.log("Controller.constructor     plugins.home.Controller.constructor");
	//console.log("Controller.args: " + dojo.toJson(args));

	// LOAD CSS FOR BUTTON
	this.loadCSS();
},
postCreate : function() {
	console.log("Controller.postCreate    plugins.home.Controller.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Controller.startup    plugins.home.Controller.startup()");

	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);

	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET ADMIN BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab");
},
createTab : function (args) {
	console.log("Controller.createTab    plugins.home.Controller.createTab");
	
	if ( args == null ) args = new Object;
	args.attachWidget 	= 	Agua.tabs;
	args.controller		= 	this;

	// CREATE WIDGET	
	var widget = new plugins.home.Home(args);
	this.tabPanes.push(widget);

	// ADD TO _supportingWidgets FOR INCLUSION IN DESTROY	
	this._supportingWidgets.push(widget);
	
	return widget;
},
removeTab : function (tab) {
	console.log("Controller.removeTab    tab: ");
	console.dir({tab:tab});

	for ( var i = 0; i < this.tabPanes.length; i++ ) {
		var currentTab = this.tabPanes[i];
		console.log("Controller.removeTab    currentTab at i: " + i);
		console.dir({currentTab:currentTab});
		
		if ( tab == currentTab ) {
			console.log("Controller.removeTab    MATCHED at i: " + i);
			
			this.tabPanes.splice(i, 1);

			console.log("Controller.removeTab    DOING tab.destroy()");
			tab.destroyRecursive();
			return;
		}
	}
}

}); // end of Controller

dojo.addOnLoad( function() {
		// CREATE TAB
		//console.log("plugins.home.Controller    Doing Agua.controllers['home'].createTab()");
		//Agua.controllers["home"].createTab();		
	}
);