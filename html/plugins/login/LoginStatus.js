console.log("plugins.login.LoginStatus    LOADING");

/* DISPLAY LOGIN STATUS AT RIGHT SIDE OF TOOLBAR */

define([
	"dojo/_base/declare",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin"
	//,
	//"dojo/domReady!"
],

function (
	declare,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate
) {

/////}}}}}

return declare("plugins.login.LoginStatus",
	[
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate
], {

// templateString : String
//		The template of this widget. 
templateString: dojo.cache("plugins", "login/templates/loginstatus.html"),


/////}}}}}

constructor: function () {
	console.log("LoginStatus.constructor    plugins.login.LoginStatus.constructor()");

	this.loadCSS();
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
		require.toUrl("plugins/login/css/loginstatus.css"),
		require.toUrl("plugins/login/css/login.css")
	];
	for ( var i in cssFiles )
	{
		var cssFile = cssFiles[i];
		//console.log("LoginStatus.loadCSS    cssFile: " + cssFile);

		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		cssNode.media = 'screen';
		//cssNode.title = 'loginCSS';
		document.getElementsByTagName("head")[0].appendChild(cssNode);
	}
}

}); //	end declare

});	//	end define
