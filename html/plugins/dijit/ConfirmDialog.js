define( "plugins/dijit/ConfirmDialog",
[
	"dojo/_base/declare",
	"dijit/Dialog",
	"dijit/form/Button",
	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/core/Common"
]
,
function (declare, Dialog, Button, _Widget, _Templated, Common) {

return declare("plugins/dijit/ConfirmDialog",
	[ _Widget, _Templated, Common ], {

	//Path to the template of this widget. 
	templatePath: require.toUrl("plugins/dijit/templates/confirmdialog.html"),

	// OR USE @import IN HTML TEMPLATE
	cssFiles : [
		require.toUrl("plugins/dijit/css/confirmdialog.css")
	],

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
		//console.log("Confirm.constructor    plugins.dijit.ConfirmDialog.constructor()");

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
		////console.log("Confirm.postCreate    plugins.dijit.ConfirmDialog.postCreate()");

		this.startup();
	},
	
	startup : function ()
	{
		//console.log("Confirm.startup    plugins.dijit.ConfirmDialog.startup()");
		//console.log("Confirm.startup    this.parentWidget: " + this.parentWidget);

		this.inherited(arguments);

		// SET UP DIALOG
		this.setDialogue();
		
		// ADD CSS NAMESPACE CLASS
		dojo.addClass(this.dialog.containerNode, "confirmDialog");
		dojo.addClass(this.dialog.titleNode, "confirmDialog");
		dojo.addClass(this.dialog.closeButtonNode, "confirmDialog");
		
		// REMOVE CLOSE BUTTON NODE
		this.dialog.closeButtonNode.setAttribute('display', 'none');
		this.dialog.closeButtonNode.setAttribute('visibility', 'hidden');
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
		//console.log("Confirm.doYes    plugins.dijit.ConfirmDialog.doYes()");
		
		// DO CALLBACK
		this.dialog.yesCallback();
		
		// HIDE
		this.dialog.hide();
	},

	doNo : function()
	{
		//console.log("Confirm.doNo    plugins.dijit.ConfirmDialog.doNo()");

		// DO CALLBACK
		this.dialog.noCallback();
	
		// HIDE
		this.dialog.hide();
	},


	// LOAD THE DIALOGUE VALUES
	load : function (args)
	{
		//console.log("ConfirmDialog.load    plugins.dijit.InputDialog.load()");
		//console.log("ConfirmDialog.load    args: " + dojo.toJson(args));

		if ( args.title == null )	{	args.title = "";	}
		this.dialog.titleNode.innerHTML	=	args.title;
		this.messageNode.innerHTML	=	args.message;
		this.dialog.yesCallback		=	args.yesCallback;
		this.dialog.noCallback		=	args.noCallback

		//console.log("ConfirmDialog.load    this.yesCallback: " + this.yesCallback.toString());

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
	
});
