dojo.provide("plugins.infusion.Controller");

// OBJECT:  plugins.infusion.Controller
// PURPOSE: GENERATE AND MANAGE Project PANES

// INHERITS
dojo.require("plugins.core.PluginController");

// HAS
dojo.require("plugins.infusion.Infusion");

dojo.declare( "plugins.infusion.Controller",
	[ plugins.core.PluginController ],
{
// PANE ID 
paneId : null,

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/templates/controller.html"),

// CSS FILES
cssFiles : [ require.toUrl("plugins/infusion/css/controller.css") ],

// ARRAY OF TAB PANES
tabPanes : [],

// TAB CLASS
tabClass : "plugins.infusion.Infusion",

////}}}}

startup : function () {
	//console.log("core.Controller.startup    plugins.core.Controller.startup()");
	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);
	
	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET ADMIN BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab", {});

	// CREATE TAB
    var thisObject = this;
    setTimeout(function(){
        thisObject.tabPanes.push(thisObject.createTab());
    },
    200);
}


}); // end of Controller


dojo.addOnLoad(
function()
{
	// CREATE TAB
//	Agua.controllers["infusion"].createTab();		
}
);