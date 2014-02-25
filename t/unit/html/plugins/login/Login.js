define([
	"dojo/_base/declare",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"plugins/login/Login",
	"dojo/ready",
],

function (
	declare,
	JSON,
	on,
	lang,
	Login,
	ready
) {

////}}}}}

return declare("t.unit.plugins.login.Login", [Login], {

//////}}
startup : function(args) {		
	// SET INPUT
	console.log("login.Login.startup    DOING this.setInput()");
	//this.setInput();
	
	//// SET SUBMIT
	//console.log("login.Login.startup    DOING this.setSubmitOnClick()");
	//this.setSubmitOnClick();
},

setProgress : function(percent) {
	
},
testProgress : function (data) {
	console.log("routing.Exchange.openProjectDialog   data:");
	console.dir({data:data});

	console.log("routing.Exchange.openProjectDialog   DOING Agua.getData()");
	this.getTable();
}



}); 	//	end declare

});		//	end define

