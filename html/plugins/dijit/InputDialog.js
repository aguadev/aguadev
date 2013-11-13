define( "plugins/dijit/InputDialog",
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

return declare("plugins/dijit/InputDialog",
	[ _Widget, _Templated, Common ], {

//////}}
	
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/dijit/templates/inputdialog.html"),

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/dijit/css/inputdialog.css")
],

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.workflow.Apps WIDGET
parentWidget : null,

// APPLICATION OBJECT
application : null,

/* DIALOG VARIABLES
  
TITLE

MESSAGE

INPUT MESSAGE

CHECKBOX	CHECKBOX MESSAGE

ENTER CALLBACK				CANCEL CALLBACK
  
*/
// DIALOG TITLE
//title: null,
//message: null,
//inputMessage: null,
//parentWidget: null,
//enterCallback: null,
//cancelCallback: null,
//checkboxMessage: null,


// DISPLAYED MESSAGE 
message : null,

constructor : function(args) {
	////console.log("InputDialog.constructor    plugins.dijit.InputDialog.constructor()");

	//this.title 				=	args.title;
	//this.message 			=	args.message;
	//this.inputMessage 		=	args.inputMessage;
	//this.parentWidget 		=	args.parentWidget;
	//this.enterCallback 		=	args.enterCallback;
	//this.cancelCallback 	=	args.cancelCallback;
	//this.checkboxMessage 	=	args.checkboxMessage;
	
	// SET ENTER BUTTON AND CANCEL BUTTON LABELS
	this.setEnterLabel(args.enterLabel);
	this.setCancelLabel(args.cancelLabel);
		
	// LOAD CSS
	this.loadCSS();
},

postCreate : function() {
	//////console.log("InputDialog.postCreate    plugins.dijit.InputDialog.postCreate()");

	this.startup();
},

startup : function () {
	////console.log("InputDialog.startup    plugins.dijit.InputDialog.startup()");
	////console.log("InputDialog.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);

	// SET UP DIALOG
	this.setDialogue();

	// SHOW INPUT IF this.inputMessage IS DEFINED
	this.showInputbox(this.inputMessage);

	// SHOW CHECKBOX IF this.checkboxMessage IS DEFINED
	this.showCheckbox(this.checkboxMessage);
	
	// ADD CSS NAMESPACE CLASS FOR TITLE CSS STYLING
	this.setNamespaceClass("inputDialog");
},

setNamespaceClass : function (ccsClass) {
// ADD CSS NAMESPACE CLASS
	dojo.addClass(this.dialog.containerNode, ccsClass);
	dojo.addClass(this.dialog.titleNode, ccsClass);
	dojo.addClass(this.dialog.closeButtonNode, ccsClass);	
},

show: function () {
// SHOW THE DIALOGUE
	this.dialog.show();
	this.enterButton.focus();
},

hide: function () {
// HIDE THE DIALOGUE
	this.dialog.hide();
},

doEnter : function(type) {
// RUN ENTER CALLBACK IF 'ENTER' CLICKED
	//console.log("InputDialog.doEnter    plugins.dijit.InputDialog.doEnter()");
	var input = this.inputNode.value;
	var checked = this.checkbox.checked;
	if ( checked == true ) checked = 1;
	else checked = 0;
	
	// DO CALLBACK
	this.dialog.enterCallback(input, checked);	

	// REMOVE INPUT AND HIDE
	this.inputNode.value = '';
	this.dialog.hide();
},

doCancel : function() {
// RUN CANCEL CALLBACK IF 'CANCEL' CLICKED
	////console.log("InputDialog.doCancel    plugins.dijit.InputDialog.doCancel()");
	this.dialog.cancelCallback();
	this.dialog.hide();
},

setDialogue : function () {
	// APPEND DIALOG TO DOCUMENT
	document.body.appendChild(this.dialog.domNode);
	
	this.dialog.parentWidget = this;
	
	// AVOID this._fadeOutDeferred NOT DEFINED ERROR
	this._fadeOutDeferred = function () {};
},

load : function (args) {
// LOAD THE DIALOGUE VALUES
	//////console.log("InputDialog.load    plugins.dijit.InputDialog.load()");
	//////console.log("InputDialog.load    args: " + dojo.toJson(args));
	//////console.log("InputDialog.load    ////console.dir(this.dialog)");
	//////console.dir(this.dialog);

	// SET THE DIALOG
	if ( args.title == null )	{	args.title = "";	}
	this.dialog.titleNode.innerHTML	=	args.title;
	this.messageNode.innerHTML		=	args.message;
	this.dialog.enterCallback		=	args.enterCallback;
	this.dialog.cancelCallback		=	args.cancelCallback

	// SET CHECKBOX BOX IF CHECKBOX MESSAGE IS DEFINED
	this.showCheckbox(args.checkboxMessage);

	// SET ENTER BUTTON AND CANCEL BUTTON LABELS
	this.setEnterLabel(args.enterLabel);
	this.setCancelLabel(args.cancelLabel);

	this.show();
},

showInputbox : function (inputMessage) {
	//console.log("InputDialog.showInputbox    plugins.dijit.InputDialog.showInputbox(inputMessage)");
	//console.log("InputDialog.showInputbox    inputMessage: " + inputMessage);

	if ( inputMessage == null )
	{
		//console.log("InputDialog.showInputbox    Doing dojo.destroy(this.inputContainer)");
		dojo.destroy(this.inputContainer);
	}
	else {
		this.inputNode.style.visibility = "visible";
		this.checkbox.style.visibility = "visible";
		this.inputNode.innerHTML = inputMessage;
		
		// ACTIVATE 'YES' KEY ON PRESS 'RETURN'
		var thisObject = this;
		this.inputNode.onkeypress = function(evt){
			var key = evt.which;
			//console.log("dijit.InputDialog    inputNode._onKey	key: " + key);
			if ( key == 13 )
			{
				//console.log("dijit.InputDialog    inputNode._onKey	   Doing this.doEnter");
				evt.stopPropagation();
				thisObject.doEnter();
		
			}    
		};

	}
},

showCheckbox : function (message) {
	//console.log("InputDialog.showCheckbox    plugins.dijit.InputDialog.showCheckbox(message)");
	//console.log("InputDialog.showCheckbox    message: " + message);
	//console.log("InputDialog.showCheckbox    this.inputNode.style.visibility: " + this.inputNode.style.visibility);
	//console.log("InputDialog.showCheckbox    this.checkbox.style.visibility: " + this.checkbox.style.visibility);
	//console.log("InputDialog.showCheckbox    this.checkbox: " + this.checkbox);

	if ( message == null )
	{
		dojo.addClass(this.checkboxMessageNode, "hidden");
		dojo.addClass(this.checkbox, "hidden");
		//this.inputNode.style.visibility = "hidden";
		//this.checkbox.style.visibility = "hidden";
		//this.checkbox.style.height = "0px";
		//dojo.destroy(this.checkboxContainer);
	}
	else {
		dojo.removeClass(this.checkboxMessageNode, "hidden");
		dojo.removeClass(this.checkbox, "hidden");
		//this.inputNode.style.visibility = "visible";
		//this.checkbox.style.visibility = "visible";
		this.inputNode.innerHTML = message;
		//this.checkbox.style.height = "20px";
	}

	//////console.log("InputDialog.showCheckbox    END");
},

setEnterLabel : function (label) {

	////console.log("InputDialog.setEnterLabel    label: " + label);
	if ( label != null && this.enterButton != null )
		this.enterButton.set('label', label);	
},

setCancelLabel : function (label) {

	////console.log("InputDialog.setCancelLabel    label: " + label);
	if ( label != null && this.cancelButton != null )
		this.cancelButton.set('label', label);	
}



});
	
	
});
