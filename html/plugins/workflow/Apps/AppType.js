dojo.provide("plugins.workflow.Apps.AppType");

dojo.require("dijit.TitlePane");

dojo.declare( "plugins.workflow.Apps.AppType",
	[ dijit._Widget, dijit._Templated ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/Apps/templates/apptype.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.workflow.Apps WIDGET
parentWidget : null,

constructor : function(args) {
	////console.log("AppType.constructor    plugins.workflow.AppType.constructor()");
	this.parentWidget = args.parentWidget;
},
postCreate : function() {
	////console.log("AppType.postCreate    plugins.workflow.AppType.postCreate()");
	this.startup();
},
startup : function () {
	////console.log("AppType.startup    plugins.workflow.AppType.startup()");
	////console.log("AppType.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);
}

});
