dojo.provide("plugins.workflow.Apps.SharedApps");

// ALLOW THE USER TO SELECT APPLICATIONS BELONGING TO OTHER USERS AND DRAG THEM INTO WORKFLOWS

// NB: USERS CAN MANAGE THEIR APPS IN THE 'ADMIN' TAB

// INTERNAL MODULES
dojo.require("plugins.workflow.Apps.Apps");

dojo.declare("plugins.workflow.Apps.SharedApps",
	[ plugins.workflow.Apps.Apps ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/Apps/templates/adminapps.html"),

/////}

startup : function() {
	console.log("SharedApps.startup    workflow.SharedApps.startup()");

	this.inherited(arguments);
},

setRefreshButton : function () {
	dojo.connect(this.refreshButton, "onclick", this, "refresh");	
},

refresh : function () {
	////console.log("SharedApps.refresh     plugins.workflow.SharedApps.refresh()");

	this.updateApps();
},

updateApps : function (args) {
	////console.log("SharedApps.refresh     plugins.workflow.SharedApps.refresh()");
	console.log("SharedApps.updateApps    Doing Agua.getTable(adminapps)");
	this.closePanes();

	// ALLOW TIME FOR PANES TO CLOSE THEN GET TABLE DATA	
	setTimeout(function(thisObj) {
		Data.getTable("sharedApps,sharedParameters");
		//Agua.warning("Completed reloading shared applications");
		thisObj.loadAppSources();
	}, 500, this);
},

getApps : function () {
	return Agua.getAdminApps();
}
	
}); // plugins.workflow.SharedApps

