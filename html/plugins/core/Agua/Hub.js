dojo.provide("plugins.core.Agua.Hub");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS HUB METHODS */

dojo.declare( "plugins.core.Agua.Hub",	[  ], {

/////}}}

getHub : function () {
// RETURN CLONE OF this.hub
	return this.cloneData("hub");
},

setHub : function (hub) {
// RETURN ENTRY FOR username IN this.hub
	console.log("Agua.Hub.setHub    plugins.core.Data.setHub(hub)");
	console.log("Agua.Hub.setHub    hub: " + dojo.toJson(hub));
	if ( hub == null ) {
		console.log("Agua.Hub.setHub    hub is null. Returning");
		return;
	}
	if ( hub.login == null ) {
		console.log("Agua.Hub.setHub    hub.login is null. Returning");
		return;
	}
	this.setData("hub", hub);
	
	return hub;
},
setHubCertificate : function (publiccert) {
// RETURN ENTRY FOR username IN this.hub
	console.log("Agua.Hub.setHubCertificate    publiccert: " + publiccert);
	if ( ! publiccert ) {
		console.log("Agua.Hub.setHubCertificate    publiccert is null. Returning");
		return;
	}
	var hub = this.getData("hub");
	console.log("Agua.Hub.setHubCertificate    hub: ");
	console.dir({hub:hub});
	if ( ! hub ) {
		console.log("Agua.Hub.setHubCertificate    hub is null. Returning");
		return;
	}
	if ( ! hub.login ) {
		console.log("Agua.Hub.setHubCertificate    hub.login is null. Returning");
		return;
	}

	hub.publiccert = publiccert;	
	this.setData("hub", hub);
	
	return hub;
}



});