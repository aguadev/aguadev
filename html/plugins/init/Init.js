dojo.provide("plugins.init.Init");

// INITIALISE AGUA - MOUNT DATA VOLUMES AND STORE ADMIN KEYS

// INHERITS
dojo.require("plugins.core.Common");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dojo.parser");	// scan page for widgets and instantiate them
dojo.require("dijit.form.NumberTextBox");
dojo.require("dijit.form.HorizontalSlider");

// FORM VALIDATION
dojo.require("plugins.dijit.form.ValidationTextBox");
dojo.require("plugins.form.TextArea");

dojo.declare("plugins.init.Init",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "init/templates/init.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ "plugins/init/css/init.css" ],

// PARENT WIDGET
parentWidget : null,

// DEFAULT DATA VOLUME
defaultDataVolume : null,

/////}}
constructor : function(args) {
	// LOAD CSS
	this.loadCSS();		

	this.defaultDataVolume = args.dataVolume;
	console.log("Init.constructor    this.defaultDataVolume: " + this.defaultDataVolume);
},
postCreate : function() {
	console.log("Controller.postCreate    plugins.init.Controller.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Init.startup    plugins.init.GroupInit.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);

	console.log("Init.startup    this.defaultDataVolume: " + this.defaultDataVolume);
	this.datavolume.set("value", this.defaultDataVolume);

	dijit.Tooltip.defaultPosition = ['above', 'below'];
	
	// ADD ADMIN TAB TO TAB CONTAINER		
	console.log("Init.startup    BEFORE appendChild(this.initTab.domNode)");
	dojo.byId("attachPoint").appendChild(this.initTab.domNode);
	console.log("Init.startup    AFTER appendChild(this.initTab.domNode)");

	// DISABLE PROGRESS BUTTON
	this.disableProgressButton();
	
	// SET SAVE BUTTON
	dojo.connect(this.saveButton, "onClick", dojo.hitch(this, "save"));

	// SET SLIDERS
	this.setDataVolumeSlider();
	this.setUserVolumeSlider();
	
	// SET RANDOM ADMIN PASSWORD
	this.setPasswordMatcher();

	// SET TOASTER
	this.setToaster();
},
// SAVE
save : function (event) {
	console.log("Init.save    event: " + event);
	
	if ( this.saving == true ) {
		console.log("Init.save    this.saving: " + this.saving + ". Returning.");
		return;
	}
	this.saving = true;
	
	var parameters = ["confirmPassword", "amazonuserid", "datavolume", "uservolume", "datavolumesize", "uservolumesize", "awsaccesskeyid", "awssecretaccesskey", "ec2publiccert", "ec2privatekey" ];
	var isValid = true;
	for ( var i = 0; i < parameters.length; i++ ) {
		var parameter = parameters[i];
		console.log("Init.save    parameter: " + parameter);
		console.log("Init.save    this[" + parameter + "]: ");
		console.dir({this_parameter:this[parameter]});
		var valid = this[parameter].isValid(this[parameter].textbox.value);
		console.log("Init.save    this[" + parameter + "] valid: " + valid);
		if ( valid ) {
			console.log("Init.save    VALID!!");
			this[parameter].state = "Incomplete";
			this[parameter]._setStateClass();
		}
		else {
			// SET ERROR STATE AND CSS CLASSES IF NOT VALID
			console.log("Init.save    NOT VALID. Setting 'Error' state");
			this[parameter].state = "Error";
			this[parameter]._setStateClass();
			isValid = false;
		}
		
		// SET password ERROR STATE TO SAME AS confirmPassword
		if ( parameter == "confirmPassword" ) {
			if ( valid ) {
				console.log("Init.save    DOING _setStateClass 'Incomplete' for 'password'");
				this["password"].state = "Incomplete";
				this["password"]._setStateClass();
			}
			else {
				console.log("Init.save    DOING _setStateClass 'Error' for 'password'");
				this["password"].state = "Error";
				this["password"]._setStateClass();
			}
		}
	}
	if ( ! valid )	{
		console.log("Init.save    One or more inputs not valid. Returning");
		this.saving = false;
		return;
	}

	var uservolume = this.uservolume.value;
	if ( uservolume.match(/New volume/) )	uservolume = '';
	
	// CLEAN UP WHITESPACE AND SUBSTITUTE NON-JSON SAFE CHARACTERS
	var aws = new Object;
	aws.username 		= this.adminuser.value;
	aws.password 		= this.password.value;
	aws.amazonuserid 	= this.cleanEdges(this.amazonuserid.value);
	aws.datavolume 		= this.datavolume.value;
	aws.uservolume 		= uservolume;
	aws.datavolumesize 	= this.datavolumesize.value;
	aws.uservolumesize 	= this.uservolumesize.value;
	aws.ec2publiccert 	= this.cleanEdges(this.ec2publiccert.value);
	aws.ec2privatekey 	= this.cleanEdges(this.ec2privatekey.value);
	aws.awsaccesskeyid 	= this.cleanEdges(this.awsaccesskeyid.value);
	aws.awssecretaccesskey = this.cleanEdges(this.awssecretaccesskey.value);

	var url = this.cgiUrl + "/init.cgi?";
	console.log("Init.saveStore     url: " + url);		

	// CREATE JSON QUERY
	var query 			= 	new Object;
	query.username 		= 	"agua";
	query.mode 			= 	"init";
	query.data 			= 	aws;
	console.log("Init.save    query: " + dojo.toJson(query));
	console.dir({query:query});


	this.enableProgressButton();
	
	// SEND TO SERVER
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			load: function(response, ioArgs) {
				console.log("Init.save    response:");
				console.dir({response:response});
				thisObj.handleSave(response);
			},
			error: function(response, ioArgs) {
				console.log("Init.save    Error with JSON Post, response: ");
				console.dir({response:response});
			}
		}
	);

	this.saving = false;
},
handleSave : function (response) {
	console.log("Init.handleSave    response: ");
	console.dir({response:response});
	if ( ! response ) {
		this.toast({error:"No response from server. If problem persists, restart instance"})
		return;
	}
	this.toast(response);
},
openProgressLog : function () {
	if ( dojo.hasClass(this.progressButton, 'disabled') ) {
		console.log("Init.openProgressLog    DISABLED. returning");
		return;
	}
	
	window.open('log/initlog.html',
		'_blank',
		'toolbar=1,location=0,directories=0,status=0,menubar=1,scrollbars=1,resizable=1,navigation=0');
},
disableProgressButton : function () {
	dojo.addClass(this.progressButton, 'disabled');
},
enableProgressButton : function () {
	dojo.removeClass(this.progressButton, 'disabled');
},
// SETTERS
setTable : function () {
	console.log("Init.setTable     plugins.init.GroupInit.setTable()");

	// DELETE EXISTING TABLE CONTENT
	while ( this.initTable.firstChild )
	{
		this.initTable.removeChild(this.initTable.firstChild);
	}
},
setDataVolumeSlider : function () {
// INITIALISE SLIDER TO SELECT BOUNDARIES OF RESULTS RANGE
	console.log("Init.setDataVolumeSlider     plugins.init.Init.setDataVolumeSlider()");

	// ONMOUSEUP
	var thisObject = this;
	dojo.connect(this.datavolumeslider, "onMouseUp", dojo.hitch(this, function(e) {
		console.log("Init.setDataVolumeSlider    onMouseUp fired");
		var size = parseInt(this.datavolumeslider.getValue());
		console.log("Init.setDataVolumeSlider    size: " + size);
		thisObject.datavolumesize.set('value', size);
	}));
},
setUserVolumeSlider : function () {
// INITIALISE SLIDER TO SELECT BOUNDARIES OF RESULTS RANGE
	console.log("Init.setUserVolumeSlider     plugins.init.Init.setUserVolumeSlider()");

	// ONMOUSEUP
	var thisObject = this;
	dojo.connect(this.uservolumeslider, "onMouseUp", dojo.hitch(this, function(e) {
		console.log("Init.setUserVolumeSlider    onMouseUp fired");
		var size = parseInt(this.uservolumeslider.getValue());
		console.log("Init.setUserVolumeSlider    size: " + size);
		thisObject.uservolumesize.set('value', size);
	}));
},
setPasswordMatcher : function () {
	console.log("Init.setPasswordMatcher    this.confirmPassword: " + this.confirmPassword);
	this.confirmPassword.parentWidget = this;
	this.password.parentWidget = this;
	this.password.target = this.confirmPassword;	
	this.confirmPassword.source = this.password;
},
// PASSWORD
passwordsMatch : function () {
	var password = this.password.textbox.value;
	console.log("Settings.confirmPassword    password: " + password);
	var confirmPassword = this.confirmPassword.textbox.value;
	console.log("Settings.confirmPassword    confirmPassword: " + confirmPassword);
	
	if ( ! password ) return false;
	
	return password == confirmPassword;
},
setAdminPassword : function () {
	var length = 9;
	var password = this.createRandomHexString(length);
	console.log("Init.setAdminPassword    password: " + password);
	//this.	
	
},
createRandomHexString : function (length) {
var string = '';
	for ( var i = 0; i < length; i++ ) {
		var random = parseInt(Math.random()*16);    
		var hex = this.decimalToHex(random);
		if ( hex == 10 )    hex = 0;
		//console.log("random " +  i + ": " + random);
		//console.log("hex " +  hex);
		string += hex;
	}

	return string;
},
decimalToHex : function (decimal) {
	return Number(decimal).toString(16);
},
cleanEdges : function (string) {
// REMOVE WHITESPACE FROM EDGES OF TEXT
	if ( string == null )	{ 	return null; }
	string = string.replace(/^\s+/, '');
	string = string.replace(/\s+$/, '');
	return string;
},
// TOGGLE
toggleUserVolume : function (event) {
	console.log("Init.toggleUserVolume    this.userVolumeToggled: " + this.userVolumeToggled);
	if ( this.userVolumeToggled ) 	return;
	this.userVolumeToggled = true;

	this.uservolume.set("disabled", false);
	dojo.addClass(this.uservolume.textbox, "enabled");
	this.uservolume.textbox.value = "";
	//this.uservolume.textbox.focus();
},
toggleDataVolume : function (event) {
	console.log("Init.toggleUserVolume    this.dataVolumeToggled: " + this.dataVolumeToggled);
	if ( this.dataVolumeToggled ) 	return;
	this.dataVolumeToggled = true;

	this.datavolume.set("disabled", false);
	dojo.addClass(this.datavolume.textbox, "enabled");
	//this.datavolume.textbox.value = "";
	//this.datavolume.textbox.focus();
}

}); // end of Init

