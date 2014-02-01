dojo.provide("plugins.workflow.Apps.AdminPackages");

/* SUMMARY: DISPLAY ONE OR MORE PACKAGES SHARED BY THE ADMIN USER

	-	EACH PACKAGE IS DISPLAYED IN ITS OWN apps OBJECT
	
	-	ADMIN USER CREATES AND ADMINISTERS PACKAGE/APPS IN Apps PANE
*/

// INTERNAL MODULES
dojo.require("plugins.workflow.Apps.Packages");

dojo.declare("plugins.workflow.Apps.AdminPackages", [ plugins.workflow.Apps.Packages, plugins.core.Common ], {

/////}

// className : String
//		Name of this class
className : "plugins_workflow_Apps_AdminPackages",

// CORE WORKFLOW OBJECTS
core : null,

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachPoint : null,

// ARRAY OF plugins.workflow.Apps.Apps OBJECT
packageApps : [],

// UPDATE AFTER SUBSCRIPTIONS
updatePackages : function (args) {
	console.group("workflow.Packages.AdminPackages    " + this.id + "    updatePackages");
	console.log("workflow.Packages.AdminPackages.updatePackages    args:");
	console.dir(args);

	console.log("workflow.Apps.AdminPackages.updatePackages    DOING this.update()");
	this.update();	

	console.groupEnd("workflow.Packages.AdminPackages    " + this.id + "    updatePackages");
},
updateApps : function (args) {
	console.group("workflow.Packages.AdminPackages    " + this.id + "    updateApps");
	console.log("workflow.Packages.AdminPackages.updateApps    args:");
	console.dir(args);

	this.update();	

	console.groupEnd("workflow.Packages.AdminPackages    " + this.id + "    updateApps");
},
update : function () {
	console.log("workflow.Apps.AdminPackages.update    DOING this.clear()");
	this.clear();
	
	console.log("workflow.Apps.AdminPackages.update    DOING this.setPackages()");
	this.setPackages();
},

getAppsArray : function () {
	return Agua.getAdminApps();
}
	
}); // plugins.workflow.Apps.AdminPackages

