console.log("plugins.login.Controller    LOADING");

define([
	"dojo/_base/declare",
	"plugins/login/Login",
	"plugins/login/LoginStatus"
],

function (
	declare,
	Login,
	LoginStatus
) {

///////}}}}}

return declare("plugins.login.Controller",
	[], {

// login : Boolean
//		True if logged in, false otherwise
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
		require.toUrl("plugins/login/css/login.css")
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

}); //	end declare

});	//	end define

