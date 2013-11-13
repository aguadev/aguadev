dojo.provide("plugins.dijit.SelectiveDialog");

/* CLASS SUMMARY: AN INTERACTIVE DIALOG WITH AN OPTIONAL COMBOBOX 
  
	AND OPTIONAL CHECKBOX.
  
	LIKE ITS INHERITED CLASS, InteractiveDialog, SelectiveDialog
	
	WAITS UNTIL THE enterCallback METHOD CLOSES IT, SO THE 
	
	enterCallback METHOD CAN VALIDATE THE INPUT AND CLOSE
	
	THE DIALOG WHEN THE CORRECT INPUT IS PRESENT.
	
*/

// HAS A
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");

// INHERITS
dojo.require("plugins.core.Common");
dojo.require("plugins.dijit.InteractiveDialog");


dojo.declare( "plugins.dijit.SelectiveDialog",
	[ plugins.dijit.InteractiveDialog ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "dijit/templates/selectivedialog.html"),

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins.dijit") + "/css/selectivedialog.css" ],

//////}}
constructor : function(args) {
	////console.log("SelectiveDialog.constructor    plugins.dijit.SelectiveDialog.constructor()");

	//this.title 				=	args.title;
	//this.message 			=	args.message;
	//this.parentWidget 		=	args.parentWidget;
	//this.enterCallback 		=	args.enterCallback;
	//this.cancelCallback 	=	args.cancelCallback;
	
	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	////console.log("SelectiveDialog.startup    plugins.dijit.SelectiveDialog.startup()");
	////console.log("SelectiveDialog.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);

	// SHOW INPUT IF this.comboMessage IS DEFINED
	this.showComboMessage(this.comboMessage);

	// SET UP DIALOG
	this.setDialogue();
	
	// SET LISTENERS
	this.setListeners();
	
	// ADD CSS NAMESPACE CLASS FOR TITLE CSS STYLING
	this.setNamespaceClass("selectiveDialog");	
},
setListeners : function () {
	// DO LOGIN IF 'RETURN' KEY PRESSED WHILE IN PASSWORD INPUT
	var thisObject = this;
	dojo.connect(this.combo, "onkeypress", function(event) {
		var key = event.keyCode;
		console.log("SelectiveDialog.set    this.combo onKeyPress FIRED");
		
		// STOP EVENT BUBBLING
		event.stopPropagation();   

		// LOGIN IF 'RETURN' KEY PRESSED
		if ( key == 13 )
		{
			thisObject.doEnter();
		}

		// QUIT LOGIN WINDOW IF 'ESCAPE' KEY IS PRESSED
		if (key == dojo.keys.ESCAPE)
		{
			// FADE OUT LOGIN WINDOW
			thisObject.doCancel();
		}
	});	
	
},
setCombo : function () {
	////console.log("SelectiveDialog.setCombo    plugins.dijit.SelectiveDialog.setCombo()");
	////console.log("SelectiveDialog.setCombo    this.comboValues: " + dojo.toJson(this.comboValues));
	////console.log("SelectiveDialog.setCombo    this.combo: " + this.combo);

	while ( this.combo.length )
	{
		this.combo.options[this.combo.length - 1] = null;
	}

	for ( var i = 0; i < this.comboValues.length; i++ )
	{
		var option = document.createElement("OPTION");
		option.text = this.comboValues[i];
		option.value = this.comboValues[i];
		this.combo.options.add(option);
	}
},
// SHOW CHECKBOX
showComboMessage : function (comboMessage) {
	////console.log("SelectiveDialog.showComboMessage    plugins.dijit.SelectiveDialog.showComboMessage(comboMessage)");
	////console.log("SelectiveDialog.showComboMessage    comboMessage: " + comboMessage);

	if ( comboMessage == null )
	{
		dojo.attr(this.combo.parentNode, 'colspan', 2);
		dojo.destroy(this.comboMessageNode);
	}
},
// LOAD THE DIALOGUE VALUES
load : function (args) {
	////console.log("SelectiveDialog.load    plugins.dijit.SelectiveDialog.load()");
	//////console.log("SelectiveDialog.load    args: " + dojo.toJson(args));

	this.title 				=	args.title || '';
	this.message 			=	args.message;
	this.comboValues 		=	args.comboValues;
	this.parentWidget 		=	args.parentWidget;
	this.enterCallback 		=	args.enterCallback;
	this.cancelCallback 	=	args.cancelCallback;

	// SET THE DIALOG
	this.dialog.titleNode.innerHTML	=	args.title;
	this.messageNode.innerHTML		=	args.message;
	this.inputMessageNode.innerHTML		=	args.inputMessage || '';
	this.comboMessageNode.innerHTML		=	args.comboMessage || '';
	this.checkboxMessageNode.innerHTML	=	args.checkboxMessage || '';
	this.dialog.enterCallback		=	args.enterCallback;
	this.dialog.cancelCallback		=	args.cancelCallback

	// SET CHECKBOX BOX IF CHECKBOX MESSAGE IS DEFINED
	this.showCheckbox(args.checkboxMessage);

	// SET ENTER BUTTON AND CANCEL BUTTON LABELS
	this.setEnterLabel(args.enterLabel);
	this.setCancelLabel(args.cancelLabel);

	// SET COMBO BOX
	this.setCombo();

	this.show();
},
doEnter : function(type) {
	////console.log("SelectiveDialog.doEnter    plugins.dijit.SelectiveDialog.doEnter()");	
	var input = '';
	if ( this.inputNode != null ) input = this.inputNode.value;

	var checked;
	if ( this.checkbox.checked == true ) checked = 1;
	else checked = 0;

	var selected = this.combo.value;

	// DO CALLBACK
	this.dialog.enterCallback(input, selected, checked, this);	
}
});
