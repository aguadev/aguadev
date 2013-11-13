dojo.provide("plugins.cloud.Settings");

// ALLOW THE ADMIN USER TO ADD, REMOVE AND MODIFY USERS

// NEW USERS MUST HAVE username AND email

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.NumberTextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");
dojo.require("dijit.form.ValidationTextBox");
dojo.require("plugins.core.Common");
dojo.require("plugins.dijit.form.ValidationTextBox")


// HAS A
dojo.require("plugins.cloud.UserRow");

//dojo.declare("plugins.cloud.ValidationTextBox",
//	[ dijit.form.ValidationTextBox ], {
//
//validate: function(/*Boolean*/ isFocused){
//	// summary:
//	//		Called by oninit, onblur, and onkeypress.
//	// description:
//	//		Show missing or invalid messages if appropriate, and highlight textbox field.
//	// tags:
//	//		protected
//
//	console.log("plugins.cloud.ValidationTextBox.validate    plugins.cloud.ValidationTextBox.validate(isFocused)");
//	console.log("plugins.cloud.ValidationTextBox.validate    this.target: " + this.target);
//	// SKIP VALIDATE WHEN LOADING WIDGET
//	if ( this.parentWidget == null )	return;
//
//	// IF this IS THE newPassword WIDGET, RUN VALIDATE ON
//	// ITS TARGET: THE confirmPassword WIDGET
//	if ( this.target != null ) {
//		return this.target.validate(isFocused);
//	}
//	var message = "";
//	var isValid = this.parentWidget.passwordsMatch();
//	console.log("plugins.cloud.ValidationTextBox.validate    isValid: " + isValid);
//
//	if(isValid){ this._maskValidSubsetError = true; }
//	var isEmpty = this._isEmpty(this.textbox.value);
//	var isValidSubset = !isValid && !isEmpty && isFocused && this._isValidSubset();
//	this.state = ((isValid || ((!this._hasBeenBlurred || isFocused) && isEmpty) || isValidSubset) && this._maskValidSubsetError) ? "" : "Error";
//	console.log("plugins.cloud.ValidationTextBox.validate    this.state: " + this.state);
//	if(this.state == "Error"){ this._maskValidSubsetError = isFocused; } // we want the error to show up afer a blur and refocus
//	
//	this._setStateClass();
//	dijit.setWaiState(this.focusNode, "invalid", isValid ? "false" : "true");
//	if(isFocused) {
//		if(this.state == "Error"){
//			message = this.getErrorMessage(true);
//		}else{
//			message = this.getPromptMessage(true); // show the prompt whever there's no error
//		}
//		this._maskValidSubsetError = true; // since we're focused, always mask warnings
//	}
//	this.displayMessage(message);
//
//	return isValid;
//}	
//
//});
//
dojo.declare("plugins.cloud.Settings",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "cloud/templates/settings.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "cloud/css/settings.css"),
	//dojo.moduleUrl("dojo", "/tests/dnd/dndDefault.css")
],

// PARENT WIDGET
parentWidget : null,


/////}}} 
constructor : function(args)  {
	console.log("Settings.constructor     plugins.cloud.Settings.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.settings = args.parentWidget.settings;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	console.log("Controller.postCreate    plugins.cloud.Controller.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Settings.startup    plugins.cloud.GroupSettings.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	console.log("Settings.startup    BEFORE inherited(arguments)");
	this.inherited(arguments);	 
	console.log("Settings.startup    AFTER inherited(arguments)");

	// ADD ADMIN TAB TO TAB CONTAINER		
	this.tabContainer.addChild(this.mainTab);
	this.tabContainer.selectChild(this.mainTab);

	// SET ADD SOURCE ONCLICK
	console.log("Settings.startup    BEFORE dojo.connect");
	dojo.connect(this.updateUserButton, "onClick", dojo.hitch(this, "updateUser"));
	console.log("Settings.startup    AFTER dojo.connect");

	//// ADD password CLASS TO PASSWORD INPUTS
	//dojo.addClass(this.newPassword.focusNode, "password");

	console.log("Settings.startup    this.confirmPassword: " + this.confirmPassword);
	this.confirmPassword.parentWidget = this;
	this.newPassword.parentWidget = this;
	this.newPassword.target = this.confirmPassword;
	
	// SET DRAG SOURCE - LIST OF USERS
	this.initialiseSettings();
},
passwordsMatch : function () {
	console.log("Settings.confirmPassword    plugins.cloud.GroupSettings.confirmPassword()");
	var newPassword = this.newPassword.textbox.value;
	console.log("Settings.confirmPassword    newPassword: " + newPassword);
	var confirmPassword = this.confirmPassword.textbox.value;
	console.log("Settings.confirmPassword    confirmPassword: " + confirmPassword);
	
	return newPassword == confirmPassword;
},
getInputValue : function (name) {
	console.log("Settings.getInputValue    name: " + name);
	var widget = this[name];
	var value = widget.get ? widget.get('value') : widget; 
	console.log("Settings.getInputValue    value: " + value);
	value = this.cleanEdges(value);

	//if ( value.match("OMITTED") )	return;
	return value;
},
getTextAreaValue : function (name) {
	console.log("Settings.getTextAreaValue    name: " + name);
	var value = this[name].value;
	value = this.cleanEdges(value);	
	//if ( value.match("OMITTED") )	value = '';
    this[name].value = value;

	return value;
},
// SAVE TO REMOTE
updateUser : function (event) {
	console.log("Settings.updateUser    plugins.cloud.Settings.updateUser(event)");
	console.log("Settings.updateUser    event: " + event);

	console.log("Settings.updateUser    this.savingUser: " + this.savingUser + ". Returning.");
	if ( this.savingUser == true )	return;
	this.savingUser = true;

	// GET PASSWORDS
	var oldPassword = this.cleanEdges(this.oldPassword.value);
	var newPassword = this.cleanEdges(this.newPassword.value);
	var confirmPassword = this.cleanEdges(this.confirmPassword.value);
	
	// RETURN IF ONLY SOME OF THE PASSWORDS ARE FILLED IN
	if ( ! (oldPassword  == '' && newPassword == '' && confirmPassword == '') )
	{
		if ( oldPassword  == '' ) { dojo.addClass(this.oldPassword, 'invalid'); }
		else { dojo.removeClass(this.oldPassword, 'invalid'); }
		if ( newPassword  == '' ) { dojo.addClass(this.newPassword, 'invalid'); }
		else { dojo.removeClass(this.newPassword, 'invalid'); }
		if ( confirmPassword  == '' ) { dojo.addClass(this.confirmPassword, 'invalid'); }
		else { dojo.removeClass(this.confirmPassword, 'invalid'); }		
		if ( oldPassword  == '' || newPassword == '' || confirmPassword == '' ) return;
	}

	// ALERT IF PASSWORDS DO NOT MATCH
	if ( newPassword != confirmPassword ) {
		console.log("Users.updateUser    passwords do not match. Adding class 'invalid'");
		dojo.addClass(this.newPassword, 'invalid');
		dojo.addClass(this.confirmPassword, 'invalid');
		console.log("Users.updateUser    Finished adding class 'invalid'");

		this.savingUser = false;
		return;
	}
	else {
		console.log("Users.updateUser    passwords match. Removing class 'invalid'");
		dojo.removeClass(this.newPassword, 'invalid');
		dojo.removeClass(this.confirmPassword, 'invalid');
	}

	// CLEAN UP WHITESPACE
	var user = new Object;
	user.username = Agua.cookie('username');
	user.firstname = this.cleanEdges(this.firstname.value);
	user.lastname = this.cleanEdges(this.lastname.value);
	user.email = this.cleanEdges(this.email.value);
	user.oldpassword = oldPassword;
	user.newpassword = newPassword;
	console.log("Settings.updateUser    user: " + dojo.toJson(user));
	
	var url = Agua.cgiUrl + "agua.cgi?";

	// CREATE JSON QUERY
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.mode 			= 	"updateUser";
	query.module 		= 	"Agua::Workflow";
	query.data 			= 	user;
	
	// SEND TO SERVER
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			handleAs: "json",
			putData: dojo.toJson(query),
			timeout: 15000,
			load: function(response, ioArgs) {
		
				console.log("Settings.updateUser    response: " + response);			
				if ( response.error != null ) {
					dojo.addClass(thisObj.oldPassword, 'invalid');
				}
			},
			error: function(response, ioArgs) {
			}
		}
	);

	this.savingUser = false;

}, // Settings.updateUser
cleanEdges : function (string ) {
// REMOVE WHITESPACE FROM EDGES OF TEXT
	string = string.toString();
	if ( string == null || ! string.replace)
		return null;
	string = string.replace(/^\s+/, '');
	string = string.replace(/\s+$/, '');

	return string;
},
// UTILS
initialiseSettings : function () {
	console.log("Settings.initialiseSettings     plugins.cloud.GroupSettings.initialiseSettings()");
	
	// DISPLAY USERNAME
	var username = Agua.cookie('username');
	console.log("Settings.initialiseSettings     username: " + username);
	this.username.innerHTML = username;

	// INITIALISE USER INFO
	var user = Agua.getUser(username);
	console.log("Settings.initialiseSettings     user: " + dojo.toJson(user));
	this.firstname.value = user["firstname"] || '';
	this.lastname.value = user["lastname"];
	this.email.value = user["email"];
},
reloadSettingsTabs : function () {
// RELOAD RELEVANT DISPLAYS
	console.log("Settings.reloadSettingsTabs    plugins.cloud.Settings.reloadSettingsTabs()");
	console.log("Settings.reloadSettingsTabs    this.parentWidget: " + this.parentWidget);
	console.log("Settings.reloadSettingsTabs    this.parentWidget.paneWidgets: " + this.parentWidget.paneWidgets);

	var tabPaneNames = ["plugins.cloud.GroupSettings"];
	for ( var i in tabPaneNames )
	{
		if ( this.parentWidget.paneWidgets[tabPaneNames[i]] != null )
		{
			console.log("Settings.reloadSettingsTabs    this.parentWidget.paneWidgets['" + tabPaneNames[i] + "']: " + this.parentWidget.paneWidgets[tabPaneNames[i]]);
			this.parentWidget.paneWidgets[tabPaneNames[i]].reload();
		}
	}
},
setTable : function () {
	console.log("Settings.setTable     plugins.cloud.GroupSettings.setTable()");

	// DELETE EXISTING TABLE CONTENT
	while ( this.mainTable.firstChild )
	{
		this.mainTable.removeChild(this.mainTable.firstChild);
	}
},

}); // plugins.cloud.Settings


