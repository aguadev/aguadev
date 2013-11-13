dojo.provide("plugins.login.LoginStatus");

// DISPLAY LOGIN STATUS AT RIGHT SIDE OF TOOLBAR

dojo.require("dijit._Widget");
dojo.require("dijit._Templated");

dojo.declare( "plugins.login.LoginStatus",
	[ dijit._Widget, dijit._Templated ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "login/templates/loginstatus.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

/////}}}}}

constructor: function () {
	console.log("LoginStatus.constructor    plugins.login.LoginStatus.constructor()");

	this.loadCSS();
},
postMixInProperties: function() {
	console.log("LoginStatus.postMixInProperties    plugins.login.LoginStatus.postMixInProperties()");
},
postCreate : function() {
	console.log("LoginStatus.postCreate    plugins.login.LoginStatus.postCreate()");

	this.startup();
},
startup : function () {
	console.log("LoginStatus.startup    plugins.login.LoginStatus.startup()");

	this.inherited(arguments);
},
loadCSS : function () {
	console.log("LoginStatus.loadCSS    plugins.login.LoginStatus.loadCSS()");
	var cssFiles = [
		dojo.moduleUrl("plugins") + "login/css/loginstatus.css",
		dojo.moduleUrl("plugins") + "login/css/login.css"
	];
	for ( var i in cssFiles )
	{
		var cssFile = cssFiles[i];
		console.log("LoginStatus.loadCSS    cssFile: " + cssFile);

		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		cssNode.media = 'screen';
		//cssNode.title = 'loginCSS';
		document.getElementsByTagName("head")[0].appendChild(cssNode);
	}
}

}); // end of plugins.login.LoginStatus
