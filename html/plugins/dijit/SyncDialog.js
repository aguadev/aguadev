dojo.provide("plugins.dijit.SyncDialog");

// HAS A
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");
dojo.require("dijit.form.ValidationTextBox");

// INHERITS
dojo.require("plugins.core.Common");

dojo.declare( "plugins.dijit.SyncDialog",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
	
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "dijit/templates/syncdialog.html"),

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "dijit/css/syncdialog.css")
],

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.workflow.Apps WIDGET
parentWidget : null,

// DISPLAYED MESSAGE 
message : null,

//////}}
constructor : function(args) {
	console.log("SyncDialog.constructor    args:");
	console.dir({args:args});

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	//////console.log("SyncDialog.postCreate    plugins.dijit.SyncDialog.postCreate()");

	this.startup();
},
startup : function () {
	////console.log("SyncDialog.startup    plugins.dijit.SyncDialog.startup()");
	////console.log("SyncDialog.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);

	// SET UP DIALOG
	this.setDialogue();

	// SET KEY LISTENER		
	this.setKeyListener();
	
	// ADD CSS NAMESPACE CLASS FOR TITLE CSS STYLING
	this.setNamespaceClass("syncDialog");
},
setKeyListener : function () {
	dojo.connect(this.dialog, "onkeypress", dojo.hitch(this, "handleOnKeyPress"));
},
handleOnKeyPress: function (event) {
	var key = event.keyCode;
	console.log("SyncDialog.handleOnKeyPress    key: " + key);
	if ( key == null )	return;
	event.stopPropagation();
	
	if ( key == dojo.keys.ESCAPE )	this.hide();
},
setNamespaceClass : function (ccsClass) {
// ADD CSS NAMESPACE CLASS
	dojo.addClass(this.dialog.domNode, ccsClass);
	dojo.addClass(this.dialog.titleNode, ccsClass);
	dojo.addClass(this.dialog.closeButtonNode, ccsClass);	
},
show: function () {
// SHOW THE DIALOGUE
	this.dialog.show();
	this.message.focus();
},
hide: function () {
// HIDE THE DIALOGUE
	this.dialog.hide();
},
doEnter : function(type) {
// RUN ENTER CALLBACK IF 'ENTER' CLICKED
	console.log("SyncDialog.doEnter    plugins.dijit.SyncDialog.doEnter()");

	var inputs = this.validateInputs(["message", "details"]);
	console.log("SyncDialog.doEnter    inputs:");
	console.dir({inputs:inputs});
	if ( ! inputs ) {
		console.log("SyncDialog.doEnter    inputs is null. Returning");
		return;
	}

	// RESET
	this.message.set('value', "");
	this.details.value = "";

    // HIDE
    this.hide();
	
	// DO CALLBACK
	this.dialog.enterCallback(inputs);	
},
validateInputs : function (keys) {
	console.log("Hub.validateInputs    keys: ");
	console.dir({keys:keys});

	var inputs = new Object;
	this.isValid = true;
	for ( var i = 0; i < keys.length; i++ ) {
		console.log("Hub.validateInputs    Doing keys[" + i + "]: " + keys[i]);
		inputs[keys[i]] = this.verifyInput(keys[i]);
	}
	console.log("Hub.validateInputs    inputs: ");
	console.dir({inputs:inputs});

	if ( ! this.isValid ) 	return null;	
	return inputs;
},
verifyInput : function (input) {
	console.log("Aws.verifyInput    input: ");
	console.dir({this_input:this[input]});
	var value = this[input].value;
	console.log("Aws.verifyInput    value: " + value);

	var className = this.getClassName(this[input]);
	console.log("Aws.verifyInput    className: " + className);
	if ( className ) {
		if ( ! value || (this[input].isValid && ! this[input].isValid()) ) {
			console.log("Aws.verifyInput    this[input].isValid: " + this[input].isValid);

			console.log("Aws.verifyInput    input " + input + " value is empty. Adding class 'invalid'");
			if ( this[input].domNode ) {
				dojo.addClass(this[input].domNode, 'invalid');
			}
			this.isValid = false;
		}
		else {
			console.log("SyncDialog.verifyInput    value is NOT empty. Removing class 'invalid'");
			if ( this[input].domNode ) {
				dojo.removeClass(this[input].domNode, 'invalid');
			}
			return value;
		}
	}
	else {
		if ( input.match(/;/) || input.match(/`/) ) {
			console.log("SyncDialog.verifyInput    value is INVALID. Adding class 'invalid'");
			dojo.addClass(this[input], 'invalid');
			this.isValid = false;
			return null;
		}
		else {
			console.log("SyncDialog.verifyInput    value is VALID. Removing class 'invalid'");
			dojo.removeClass(this[input], 'invalid');
			return value;
		}
	}
	
	return null;
},
doCancel : function() {
// RUN CANCEL CALLBACK IF 'CANCEL' CLICKED
	////console.log("SyncDialog.doCancel    plugins.dijit.SyncDialog.doCancel()");
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
	console.log("SyncDialog.load    args:");
	console.dir({args:args});

    if ( args.title ) {
        console.log("SyncDialog.load    SETTING TITLE: " + args.title);
    	this.dialog.set('title', args.title);
    }
    
	this.headerNode.innerHTML		=	args.header;
	if (args.message)	this.message.set('value', args.message);
	if (args.details) 	this.details.value = args.details;
	//if (args.details) 	this.details.innerHTML(args.details);
	this.dialog.enterCallback		=	args.enterCallback;

	this.show();
}


});
	
