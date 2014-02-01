dojo.provide("plugins.workflow.Apps.SharedPackages");

/* SUMMARY: DISPLAY ONE OR MORE PACKAGES SHARED BY THE ADMIN USER

	-	EACH PACKAGE IS DISPLAYED IN ITS OWN apps OBJECT
	
	-	ADMIN USER CREATES AND ADMINISTERS PACKAGE/APPS IN Apps PANE
*/

// INTERNAL MODULES
dojo.require("plugins.workflow.Apps.Packages");

dojo.declare("plugins.workflow.Apps.SharedPackages", [ plugins.workflow.Apps.Packages, plugins.core.Common ], {

/////}

// CORE WORKFLOW OBJECTS
core : null,

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachPoint : null,

// ARRAY OF plugins.workflow.Apps.Apps OBJECT
packageApps : [],

constructor : function (args) {
	console.log("SharedPackages.constructor    args: " + args);

	// GET INFO FROM ARGS
	this.core = args.core;
	this.parentWidget	= args.parentWidget;
	this.attachPoint 	= args.attachPoint;	
},
startup : function() {
	console.log("SharedPackages.startup    workflow.Apps.SharedPackages.startup()");

	this.setPackages();
},
getAppsArray : function () {
	return Agua.getSharedApps();
}
	
}); // plugins.workflow.Apps.SharedPackages

