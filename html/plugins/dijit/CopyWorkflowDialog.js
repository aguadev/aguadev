dojo.provide("plugins.core.CopyWorkflowDialog");

/* CLASS SUMMARY: AN INTERACTIVE DIALOG FOR COPYING WORKFLOWS
  
	LIKE ITS INHERITED CLASS, InteractiveDialog, CopyWorkflowDialog
	
	HANGS AROUND UNTIL THE enterCallback METHOD CLOSES IT. IN
	
	ADDITION, CopyWorkflowDialog ALLOWS THE USER TO SELECT THE
	
	DESTINATION PROJECT AND THE NAME OF THE NEW WORKFLOW.
*/

// HAS A
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");

// INHERITS
dojo.require("plugins.core.Common");
dojo.require("plugins.dijit.InteractiveDialog");


dojo.declare( "plugins.core.CopyWorkflowDialog",
	[ plugins.dijit.InteractiveDialog ],
{
	//////}}
	
// SHOW THE DIALOGUE
show: function () {
	this.dialog.show();
},

// HIDE THE DIALOGUE
hide: function () {
	this.dialog.hide();
},

constructor : function(args) {
	console.log("InteractiveDialog.constructor    plugins.dijit.InteractiveDialog.constructor()");

	this.title 				=	args.title;
	this.message 			=	args.message;
	this.selectValues 		=	args.selectValues;
	this.parentWidget 		=	args.parentWidget;
	this.enterCallback 		=	args.enterCallback;
	this.cancelCallback 	=	args.cancelCallback;
	
	// LOAD CSS
	this.loadCSS();
},

postCreate : function() {
	//console.log("InteractiveDialog.postCreate    plugins.dijit.InteractiveDialog.postCreate()");

	this.startup();
},

startup : function () {
	console.log("InteractiveDialog.startup    plugins.dijit.InteractiveDialog.startup()");
	console.log("InteractiveDialog.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);

	// SET UP DIALOG
	this.setDialogue();
	
	// ADD CSS NAMESPACE CLASS
	dojo.addClass(this.dialog.containerNode, "inputDialog");
	dojo.addClass(this.dialog.titleNode, "inputDialog");
	dojo.addClass(this.dialog.closeButtonNode, "inputDialog");
},


doEnter : function(type) {
	console.log("CopyWorkflowDialog.doEnter    plugins.core.CopyWorkflowDialog.doEnter()");
	
	var input = this.inputNode.value;
	//console.log("CopyWorkflowDialog.doEnter    input: " + input);		
	//console.log("CopyWorkflowDialog.doEnter    this.enterCallback: " + this.enterCallback.toString());
	// DO CALLBACK
	this.dialog.enterCallback(input, this);
	
},

// RUN CANCEL CALLBACK IF 'CANCEL' CLICKED
doCancel : function() {
	console.log("CopyWorkflowDialog.doCancel    plugins.core.CopyWorkflowDialog.doCancel()");
	this.dialog.cancelCallback();
	this.dialog.hide();
},

close : function () {
		// REMOVE INPUT AND HIDE
	this.inputNode.value = '';
	this.dialog.hide();
}



});
	
