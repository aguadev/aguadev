dojo.provide("plugins.core.Common.Toast");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	TOASTER METHODS  
*/

// DEPENDENCIES
dojo.require("plugins.dojox.widget.Toaster");

dojo.declare( "plugins.core.Common.Toast",	[  ], {

///////}}}

setToaster : function () {
	console.log("Common.Toast.setToaster    this.toaster: " + this.toaster);
	console.dir({this_toaster:this.toaster});
	
	var cssFiles = [
		dojo.moduleUrl("plugins", "core/css/toaster.css")
	];
	this.loadCSS(cssFiles);
	
	if ( ! this.toaster ) {
		this.toaster = new plugins.dojox.widget.Toaster({
			className: "toaster",
			positionDirection: "bl-right",
			duration: "500",
			messageTopic: "toastTopic"
		});
	}
	
	// SET WIDTH TO 100%
	if ( this.containerNode ) {
		this.containerNode.style.width = "100%";
	}
	
},
toastMessage : function (args) {
	console.log("Common.Toast.toastMessage    args.message: " + args.message);
	console.dir({args:args});
	////console.log("Common.Toast.toastMessage    caller: " + this.toastMessage.caller.nom);

	if ( ! args )	return;
	if ( ! this.toaster || ! this.toaster.containerNode ) {
		this.setToaster();
	}
	
	if ( args.doToast == false )	return;
	var message = args.message;
	if ( message == null || message == '' ) {
		return;
	}

	// type: 'error' or 'warning'
	var type = args.type;

	// duration: time before fade out (milliseconds)
	var duration = args.duration;

	if ( duration == null )	duration = 4000;
	if ( type != null
		&& (type != "warning" && type != "error" && type != "fatal") )
	{
		//console.log("Common.Toast.toastMessage    type not supported (must be warning|error|fatal): " + type);
		return;
	}
	
	var topic = "toastTopic";
	try {
			
		dojo.publish(topic, [ {
			message: message,
			type: type,
			duration: duration
		}]);
	}
	catch (error) {
		//console.log("Common.Toast.toastMessage    error: " + dojo.toJson(error));
	}

},
toast : function (response) {
	//console.log("Common.Toast.toast    response: ");
	//console.dir({response:response});

	if ( response.error ) {
		var args = {
			message: response.error,
			type: "error"
		};
		if ( response.duration != null )
			args.duration = response.duration;
		this.toastMessage(args);
	}
	else {
		var args = {
			message: response.status,
			type: "warning"
		};
		if ( response.duration != null )
			args.duration = response.duration;
		this.toastMessage(args);
	}
},
toastError : function (error) {
	this.toastMessage(
	{
		message: error,
		type: "error"
	});	
},
toastInfo : function (info) {
	this.toastMessage({
		message: info,
		type: "warning"
	});
},
error : function (error) {
	this.toastMessage(
	{
		message: error,
		type: "error"
	});
},
warning : function (warning) {
	this.toastMessage({
		message: warning,
		type: "warning"
	});
}


});