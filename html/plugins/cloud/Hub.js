define([
	"dojo/_base/declare",
	"dojo/_base/lang",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common",
	"dijit/form/Button",
	"dijit/form/ValidationTextBox",
	"dijit/layout/ContentPane",
	"dijit/form/TextBox",
	"dijit/form/NumberTextBox",
	"dijit/form/Textarea",
	"dojo/dnd/Source",
],
	
function (declare, lang, _Widget, _TemplatedMixin, _WidgetsInTemplateMixin, Common) {

return declare("plugins/cloud/Hub",
	[ _Widget, _TemplatedMixin, _WidgetsInTemplateMixin, Common ], {

/////}}}}}

// Template of this widget. 
templateString: dojo.cache("plugins", "cloud/templates/hub.html"),

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "cloud/css/hub.css"),
],

// PARENT WIDGET
parentWidget : null,

/////}}}}}
constructor : function(args)  {
	
	// MIXIN ARGS
	lang.mixin(args);

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	this.startup();
},
startup : function () {
	//console.log("Hub.startup    plugins.cloud.GroupHub.startup()");

	// ATTACH PANE
	var thisObj = this;
	setTimeout(function(){
		thisObj.attachPane();
	},
	2000,
	this)

	//// ADD ADMIN TAB TO TAB CONTAINER		
	//this.tabContainer.addChild(this.mainTab);
	//this.tabContainer.selectChild(this.mainTab);

	// SUBSCRIBE TO UPDATES
	if ( Agua.updater ) {
		Agua.updater.subscribe(this, "updateSyncWorkflows");
		Agua.updater.subscribe(this, "updateSyncApps");
	}

	// SET DRAG SOURCE - LIST OF USERS
	this.initialise();
},
updateSyncApps : function (args) {
	console.warn("Hub.updateSyncApps    args:");
	console.dir({args:args});

	// DO NOTHING
},
updateSyncWorkflows : function (args) {
	console.warn("Hub.updateSyncWorkflows    args:");
	console.dir({args:args});

	// DO NOTHING
},
initialise : function () {
	// INITIALISE AWS SETTINGS
	var hub = Agua.getHub();
	console.log("Hub.initialiseHub     hub: ");
	console.dir({hub:hub});
	console.log("Hub.initialiseHub     this.login: ");
	console.dir({this_login:this.login});
	
	//hub.login = hub.login || "";
	//this.login.set('value', hub.login);
	//hub.token = hub.token || "";
	//this.token.set('value', hub.token);
	//hub.publiccert = hub.publiccert || "";
	//this.publiccert.innerHTML = hub.publiccert;
},
// SAVE TO REMOTE
addHub : function (event) {
	console.log("Hub.addHub    plugins.cloud.Hub.addHub(event)");

	if ( this.addingHub == true ) {
		console.log("Hub.addHub    this.addingHub: " + this.addingHub + ". Returning.");
		return;
	}
	this.addingHub = true;
	
	// VALIDATE INPUTS
	var inputs = this.validateInputs(["login", "token"]);
	if ( ! inputs ) {
		this.addingHub = false;
		return;
	}
	
	var hub = {
		login: this.login.value,
		token: this.token.value,
		hubtype: "github"
	};
	
	console.log("Hub.addHub    Agua:");
	console.dir({Agua:Agua});

	var query = inputs;
	query.username 			= 	Agua.cookie('username');
	query.sessionid 		= 	Agua.cookie('sessionid');
	query.login				= 	this.login.value;
	query.token				= 	this.token.value;
	query.hubtype			= 	"github";
	query.mode 				= 	"addHub";
	query.module 		= 	"Agua::Workflow";
	console.log("Hub.addHub    query: ");
	console.dir({query:query});
	
	// SEND TO SERVER
	var url = Agua.cgiUrl + "agua.cgi?";
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "json",
			putData: dojo.toJson(query),
			timeout: 15000,
			load: function(response, ioArgs) {
				console.log("Hub.addHub    OK. response:")
				console.dir({response:response});

				thisObj.addingHub = false;
				
				// SET Agua.data.hub
				Agua.setHub(hub);

				// UPDATE SYNC WORKFLOWS
				Agua.updater.update("updateSyncWorkflows", { originator: thisObj, reload: false });
				Agua.updater.update("updateSyncWorkflows", { originator: thisObj, reload: false });
				
				// TOAST
				Agua.toast(response);
			},
			error: function(response, ioArgs) {
				thisObj.addingHub = false;
				console.log("Hub.addHub    ERROR. response:")
				console.dir({response:response});
				Agua.toast(response);
			}
		}
	);
},
// GENERATE PUBLIC CERTIFICATE FOR PRIVATE KEY USED TO ACCESS HUB
addHubCertificate : function () {
	console.log("Hub.addHubCertificate");
	if ( this.creatingCert ) {
		console.log("Hub.addHubCertificate    this.creatingCert: " + this.creatingCert + ". Returning.");
		return;
	}
	this.creatingCert = true;

	var aws = Agua.getAws();
	console.log("Hub.addHubCertificate    aws:");
	console.dir({aws:aws});
	if ( ! aws || ! aws.ec2privatekey ) {
		this.creatingToken = false;
		Agua.toastError("Please input EC2 Private Key in 'AWS' panel and press 'Save'");
		return;
	}

	var inputs = this.validateInputs(["login"]);
	if ( ! inputs ) {
		this.creatingCert = false;
		return;
	}
	
	var query = inputs;
	query.username 			= 	Agua.cookie('username');
	query.sessionid 		= 	Agua.cookie('sessionid');
	query.hubtype			= 	"github";
	query.mode 				= 	"addHubCertificate";
	query.module 		= 	"Agua::Workflow";
	console.log("Hub.addHubCertificate    query: ");
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
				thisObj.creatingCert = false;	

				console.log("Hub.addHubCertificate    response:");
				console.dir({response:response});
				
				var publiccert = response.data.publiccert;
				console.log("Hub.addHubCertificate    publiccert:");
				console.dir({publiccert:publiccert});

				// SET publiccert IN hub DATA
				Agua.setHubCertificate(publiccert);
				
				// DISPLAY publiccert
				thisObj.publiccert.innerHTML = publiccert;
			},
			error: function(response, ioArgs) {

				thisObj.creatingCert = false;	

				console.log("Hub.addHubCertificate    ERROR response:");
				console.dir({response:response});
			}
		}
	);
},
// GENERATE OAUTH TOKEN FOR ACCESSING USER'S HUB ACCOUNT
toggleAddToken : function () {
	console.log("Hub.showCreateToken    this.password:" + this.password)
	console.log("Hub.showCreateToken    dojo.hasClass:" + dojo.hasClass(this.password, "showCreateToken"))

	if ( ! dojo.hasClass(this.addToken, "showAddToken") ) {
		this.addTokenButton.innerHTML = "Hide Panel";
		dojo.addClass(this.addToken, "showAddToken");
	}
	else {
		this.addTokenButton.innerHTML = "Add GitHub Token";
		dojo.removeClass(this.addToken, "showAddToken");
	}
},
// GENERATE OAUTH TOKEN FOR ACCESSING USER'S HUB ACCOUNT
closeAddToken : function () {
	console.log("Hub.closeAddToken    Removing class 'showAddToken'");
	this.addTokenButton.innerHTML = "Add GitHub Token";
	dojo.removeClass(this.addToken, "showAddToken");
},
addHubToken : function () {
	console.log("Hub.addHubToken");

	if ( this.addingToken == true ) {
		console.log("Hub.addHubToken    this.addingToken: " + this.addingToken + ". Returning.");
		return;
	}
	this.addingToken = true;

	var inputs = this.validateInputs(["login", "password"]);
	if ( ! inputs ) {
		this.addingToken = false;
		return;
	}
	
	var query = inputs;
	query.username 			= 	Agua.cookie('username');
	query.sessionid 		= 	Agua.cookie('sessionid');
	query.hubtype			= 	"github";
	query.mode 				= 	"addHubToken";
	query.module 		= 	"Agua::Workflow";
	console.log("Hub.addHubToken    query: ");
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
				console.log("Hub.addHubToken    response:");
				console.dir({response:response});

				thisObj.addingToken = false;
				
				if ( response.error ) {
					Agua.toastError(response.error);
					return;
				}
				
				// CLOSE PANEL
				thisObj.closeAddToken();

				// DISPLAY PUBLIC CERT 
				var token = response.data.token;
				console.log("Hub.addHubToken    token:");
				console.dir({token:token});
				thisObj.token.set('value', token);
				
				// RELOAD RELEVANT DISPLAYS
				Agua.updater.update("updateSyncWorkflows");

			},
			error: function(response, ioArgs) {

				thisObj.addingToken = false;
	
				console.log("Hub.addHubToken    ERROR response:");
				console.dir({response:response});
				return response;
			}
		}
	);
},
// UTILS
validateInputs : function (keys) {
	console.log("Hub.validateInputs    keys: ");
	console.dir({keys:keys});
	var inputs = new Object;
	this.isValid = true;
	for ( var i = 0; i < keys.length; i++ ) {
		
		inputs[keys[i]] = this.verifyInput(keys[i]);
	}
	console.log("Hub.validateInputs    inputs: ");
	console.dir({inputs:inputs});

	if ( ! this.isValid ) 	return null;	
	return inputs;
},
verifyInput : function (input) {
	console.log("Hub.verifyInput    input: ");
	console.dir({this_input:this[input]});
	var value = this[input].value;
	value = this.cleanEdges(value);
	console.log("Hub.verifyInput    value: " + value);

	var className = this.getClassName(this[input]);
	console.log("Hub.verifyInput    className: " + className);
	if ( className ) {
		console.log("Hub.verifyInput    this[input].isValid(): " + this[input].isValid());
		if ( ! value || (this[input].isValid && ! this[input].isValid()) ) {
			console.log("Hub.verifyInput    input " + input + " value is empty. Adding class 'invalid'");
			if ( this[input].domNode ) {
				dojo.addClass(this[input].domNode, 'invalid');
			}
			this.isValid = false;
		}
		else {
			console.log("Hub.verifyInput    value is NOT empty. Removing class 'invalid'");
			dojo.removeClass(this[input].domNode, 'invalid');
			return value;
		}
	}
	else {
		if ( ! value ) {
			console.log("Hub.verifyInput    input " + input + " value is empty. Adding class 'invalid'");
			if ( this[input].domNode ) {
				dojo.addClass(this[input].domNode, 'invalid');
			}
			this.isValid = false;
			return null;
		}
		else {
			console.log("Hub.verifyInput    value is NOT empty. Removing class 'invalid'");
			dojo.removeClass(this[input], 'invalid');
			return value;
		}
	}
	
	return null;
},
clearInvalid : function () {
	var inputs = ["login", "token", ""]
	console.log("Hub.clearInvalid    input: ");
	console.dir({this_input:this[input]});
	var value = this[input].value;
	value = this.cleanEdges(value);
	console.log("Hub.clearInvalid    value: " + value);

	var className = this.getClassName(this[input]);
	console.log("Hub.clearInvalid    className: " + className);
	if ( className ) {
		if ( ! value || (this[input].isValid && ! this[input].isValid()) ) {
			console.log("Hub.clearInvalid    this[input].isValid(): " + this[input].isValid());
			console.log("Hub.clearInvalid    input " + input + " value is empty. Adding class 'invalid'");
			if ( this[input].domNode ) {
				dojo.addClass(this[input].domNode, 'invalid');
			}
			this.isValid = false;
		}
		else {
			console.log("Hub.clearInvalid    value is NOT empty. Removing class 'invalid'");
			if ( this[input].domNode ) {
				dojo.removeClass(this[input].domNode, 'invalid');
			}
			return value;
		}
	}
	else {
		if ( ! value ) {
			console.log("Hub.clearInvalid    input " + input + " value is empty. Adding class 'invalid'");
			dojo.addClass(this[input].domNode, 'invalid');
			this.isValid = false;
			return null;
		}
		else {
			console.log("Hub.clearInvalid    value is NOT empty. Removing class 'invalid'");
			dojo.removeClass(this[input], 'invalid');
			return value;
		}
	}
	
	return null;
},
cleanEdges : function (string ) {
// REMOVE WHITESPACE FROM EDGES OF TEXT
	string = string.toString();
	if ( string == null || ! string.replace)
		return null;
	string = string.replace(/^\s+/, '');
	string = string.replace(/\s+$/, '');

	return string;
}

}); // plugins.cloud.Hub

});
