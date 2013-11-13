dojo.provide("plugins.login.Controller");

// HAS
dojo.require("plugins.login.Login");
dojo.require("plugins.login.LoginStatus");

dojo.declare( "plugins.login.Controller",  [], {		
	login : null,
////}}}}}
// CONSTRUCTOR	
constructor : function(args) {
	console.log("Controller.constructor     plugins.login.Controller.constructor");
	this.loadCSS();
},
loadCSS : function() {
	console.log("Controller.loadCSS    Loading CSS FILES");
	// LOAD CSS
	var cssFiles = [
		dojo.moduleUrl("plugins") + "login/css/login.css"
	];
	for ( var i in cssFiles )
	{
		var cssFile = cssFiles[i];
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		cssNode.media = 'screen';
		document.getElementsByTagName("head")[0].appendChild(cssNode);
	}
}
}); // end of Controller

dojo.addOnLoad(
function()
{
//		console.log("Controller.addOnLoad    plugins.login.Controller.addOnLoad");
}

);
