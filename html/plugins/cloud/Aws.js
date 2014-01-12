dojo.provide("plugins.cloud.Aws");

// ADD USER'S AWS INFORMATION

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dijit.form.Button");
//dojo.require("dijit.form.TextBox");
//dojo.require("dijit.form.NumberTextBox");
//dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dijit.form.ValidationTextBox");
dojo.require("plugins.core.Common");

dojo.declare("plugins.cloud.Aws",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "cloud/templates/aws.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "cloud/css/aws.css"),
	//dojo.moduleUrl("dojo", "/tests/dnd/dndDefault.css")
],

requiredInputs : {
	amazonuserid 		: 1,
	awsaccesskeyid 		: 1,
	awssecretaccesskey 	: 1,
	ec2privatekey 		: 1,
	ec2publiccert 		: 1
},

// PARENT WIDGET
parentWidget : null,

/////}}}

constructor : function(args)  {
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.core = args.parentWidget.core;

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	//console.log("Aws.startup    plugins.cloud.GroupAws.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);

	// ATTACH PANE
	this.attachPane();

	// SET DRAG SOURCE - LIST OF USERS
	this.initialiseAws();
},
// SAVE TO REMOTE
addAws : function (event) {

console.clear();

	console.log("Aws.addAws    plugins.cloud.Aws.addAws(event)");
	console.log("Aws.addAws    event: " + event);
	
	if ( this.savingAws == true ) {
		console.log("Aws.addAws    this.savingAws: " + this.savingAws + ". Returning.");
		return;
	}
	this.savingAws = true;
	
	// VALIDATE INPUTS
	var inputs = this.validateInputs();
	if ( ! inputs ) {
		this.savingAws = false;
		return;
	}
	
	var query = inputs;
	query.username 			= 	Agua.cookie('username');
	query.sessionid 		= 	Agua.cookie('sessionid');
	query.repotype			= 	"github";
	query.mode 				= 	"addAws";
	query.module 		= 	"Agua::Workflow";
	
	console.log("Aws.addAws    query: ");
	console.dir({query:query});

	var url = Agua.cgiUrl + "agua.cgi?";
	
	// SEND TO SERVER
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "json",
			putData: dojo.toJson(query),
			handleAs: "json",
			load: function(response, ioArgs) {
				console.log("Aws.addAws    STATUS response:");
				console.dir({response:response});

				if ( ! response ) {
					Agua.toast({error:"No response from server on 'addAws'"});
					return;
				}
				
				if ( ! response.error ) {
					console.log("Aws.addAWS    DOING Agua.setAws(inputs)");
					Agua.setAws(inputs);
				}


				Agua.toast(response);
				
			},
			error: function(response, ioArgs) {
				console.log("Aws.addAws    ERROR response:");
				console.dir({response:response});
				Agua.toast(response);
			}
		}
	);

	this.savingAws = false;
},
validateInputs : function () {
	var inputs = new Object;
	this.isValid = true;
	for ( var input in this.requiredInputs ) {
		inputs[input] = this.verifyInput(input);
	}
	console.log("Aws.validateInputs    inputs: ");
	console.dir({inputs:inputs});

	if ( ! this.isValid ) 	return null;	
	return inputs;
},
verifyInput : function (input) {
	console.log("Aws.verifyInput    input: ");
	console.dir({this_input:this[input]});
	var value = this.getWidgetValue(this[input]);
	value = this.cleanEdges(value);
	console.log("Aws.verifyInput    value: " + value);

	var className = this.getClassName(this[input]);
	console.log("Aws.verifyInput    className: " + className);
	if ( className ) {
		if ( ! value || (this[input].isValid && ! this[input].isValid()) ) {
			console.log("Aws.verifyInput    this[input].isValid(): " + this[input].isValid());
			console.log("Aws.verifyInput    input " + input + " value is empty. Adding class 'invalid'");
			if ( this[input].domNode ) {
				dojo.addClass(this[input].domNode, 'invalid');
			}
			this.isValid = false;
		}
		else {
			console.log("Aws.verifyInput    value is NOT empty. Removing class 'invalid'");
			if ( this[input].domNode ) {
				dojo.removeClass(this[input].domNode, 'invalid');
			}
			return value;
		}
	}
	else {
		if ( ! value ) {
			console.log("Aws.verifyInput    input " + input + " value is EMPTY. Adding class 'invalid'");
			dojo.addClass(this[input], 'invalid');
			this.isValid = false;
			return null;
		}
		else if ( input == "ec2privatekey" ) {
			if ( ! value.match(/^\s*-----BEGIN PRIVATE KEY-----[\s\S]+-----END PRIVATE KEY-----\S*$/) ) {
				console.log("Aws.verifyInput    value is INVALID. Adding class 'invalid'");
				dojo.addClass(this[input], 'invalid');
				this.isValid = false;
				return null;
			}
			
				console.log("Aws.verifyInput    value is VALID. Removing class 'invalid'");
			dojo.removeClass(this[input], 'invalid');
			return value;
		}
		else if ( input == "ec2publiccert" ) {
			if ( ! value.match(/^\s*-----BEGIN CERTIFICATE-----[\s\S]+-----END CERTIFICATE-----\S*$/) ) {
				console.log("Aws.verifyInput    value is INVALID. Adding class 'invalid'");
				dojo.addClass(this[input], 'invalid');
				this.isValid = false;
				return null;
			}
			
				console.log("Aws.verifyInput    value is VALID. Removing class 'invalid'");
			dojo.removeClass(this[input], 'invalid');
			return value;
		}
	}
	
	return null;
},
getWidgetValue : function (widget) {
	var value;
	////////console.log("Aws.getWidgetValue    (widget: " + widget);
	////////console.log("Aws.getWidgetValue    widget: ");
	//////console.dir({widget:widget});
	if ( ! widget )	return;
	
	// NUMBER TEXT BOX
	if ( widget.id != null && widget.id.match(/^dijit_form_NumberTextBox/) )
	{
		////////console.log("Aws.getWidgetValue    DOING NumberTextBox widget");
		value = String(widget);
		//value = String(widget.getValue());
	}
	// WIDGET COMBO BOX
	else if ( widget.get && widget.get('value') )
	{
		////////console.log("Aws.getWidgetValue    DOING widget.get('value')");
		value = widget.get('value');
	}
	else if ( widget.getValue )
	{
		value = widget.getValue();
	}
	// HTML TEXT INPUT OR HTML COMBO BOX
	else if ( widget.value )
	{
		////////console.log("Aws.getWidgetValue    DOING widget.value");
		value = String(widget.value.toString());
	}
	// HTML DIV	
	else if ( widget.innerHTML )
	{
	    ////////console.log("Aws.getWidgetValue    DOING widget.innerHTML");

	    // CHECKBOX
		if ( widget.innerHTML == "<input type=\"checkbox\">" )
	    {
			////////console.log("Aws.getWidgetValue    CHECKBOX - GETTING VALUE");
			value = widget.childNodes[0].checked;
			////////console.log("Aws.getWidgetValue    value: " + value);
	    }
		else {
			value = widget.innerHTML;
		}
	}
	////////console.log("Aws.getWidgetValue    XXXX value: " + dojo.toJson(value));
	if ( value == null )    value = '';
	return value;
},
initialiseAws : function () {
	// INITIALISE AWS SETTINGS
	var aws = Agua.getAws();
	console.log("Aws.initialiseAws     aws: ");
	console.dir({aws:aws});

	this.amazonuserid.set('value', aws.amazonuserid);
	this.awsaccesskeyid.set('value', aws.awsaccesskeyid);
	this.awssecretaccesskey.set('value', aws.awssecretaccesskey);
	this.ec2privatekey.value = aws.ec2privatekey || "";
	this.ec2publiccert.value = aws.ec2publiccert || "";
},
cleanEdges : function (string ) {
// REMOVE WHITESPACE FROM EDGES OF TEXT
	console.log("Aws.cleanEdges    caller: " + this.cleanEdges.caller.nom);

	console.log("Aws.cleanEdges    string: " + string);
	if ( ! string.toString ) {
		return string;
	}
	
	string = string.toString();
	if ( string == null || ! string.replace)
		return null;
	string = string.replace(/^\s+/, '');
	string = string.replace(/\s+$/, '');

	return string;
}
}); // plugins.cloud.Aws

