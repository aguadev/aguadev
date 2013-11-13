dojo.provide("plugins.dijit.Confirm");

// HAS A
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");

// INHERITS
dojo.require("plugins.core.Common");


dojo.declare( "plugins.dijit.Confirm",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
	//Path to the template of this widget. 
	templatePath: dojo.moduleUrl("plugins", "dijit/templates/confirmdialog.html"),

	// OR USE @import IN HTML TEMPLATE
	cssFiles : [ dojo.moduleUrl("plugins") + "/dijit/css/confirmdialog.css" ],

	// Calls dijit._Templated.widgetsInTemplate
	widgetsInTemplate : true,
	
	// PARENT plugins.workflow.Apps WIDGET
	parentWidget : null,
	
	// APPLICATION OBJECT
	application : null,
	
	// DIALOG TITLE
	title: null,
	
	// DISPLAYED MESSAGE 
	message : null,
	
	constructor : function(args)
	{
		//console.log("ConfirmDialog.constructor    plugins.dijit.Confirm.constructor()");

		this.title 				=	args.title;
		this.message 			=	args.message;
		this.parentWidget 		=	args.parentWidget;
		this.yesCallback 		=	args.yesCallback;
		this.noCallback 		=	args.noCallback;
		
		// LOAD CSS
        this.loadCSS();
	},

	getApplication : function ()
	{
		return this.application;
	},

	postCreate : function()
	{
		////console.log("ConfirmDialog.postCreate    plugins.dijit.Confirm.postCreate()");

		this.startup();
	},
	
	startup : function ()
	{
		//console.log("ConfirmDialog.startup    plugins.dijit.Confirm.startup()");
		//console.log("ConfirmDialog.startup    this.parentWidget: " + this.parentWidget);

		this.inherited(arguments);

		this.setDialogue();
		
		// ADD CSS NAMESPACE CLASS
		dojo.addClass(this.dialog.containerNode, "confirmDialog");
		dojo.addClass(this.dialog.titleNode, "confirmDialog");
		dojo.addClass(this.dialog.closeButtonNode, "confirmDialog");

		//console.log("ConfirmDialog.startup    END of startup()");
	},

	// SHOW THE DIALOGUE
	show: function ()
	{
		this.dialog.show();
	},

	// HIDE THE DIALOGUE
	hide: function ()
	{
		this.dialog.hide();
	},

	doYes : function(type)
	{
		//console.log("ConfirmDialog.doYes    plugins.dijit.Confirm.doYes()");
		
		this.yesCallback();
		this.dialog.hide();
	},

	doNo : function()
	{
		//console.log("ConfirmDialog.doNo    plugins.dijit.Confirm.doNo()");
		this.noCallback();
		this.dialog.hide();
	},


	// LOAD THE DIALOGUE VALUES
	load : function (args)
	{
		//console.log("Confirm.load    plugins.dijit.InputDialog.load()");
		//console.log("Confirm.load    args: " + dojo.toJson(args));

		if ( args.title == null )	{	args.title = "Input dialogue";	}
		this.dialog.titleNode.innerHTML	=	args.title;
		this.dialog.messageNode.innerHTML	=	args.message;
		this.dialog.yesCallback		=	args.yesCallback;
		this.dialog.noCallback		=	args.noCallback

		//console.log("Confirm.load    this.yesCallback: " + this.yesCallback.toString());

		this.show();
	},


	// APPEND TO DOCUMENT BODY
	setDialogue : function () {
		
		// APPEND DIALOG TO DOCUMENT
		//this.dialog.title = title;
		document.body.appendChild(this.dialog.domNode);
		//this.dialog.show();
	}

});
	
