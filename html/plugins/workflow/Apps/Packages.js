define([
	"dojo/_base/declare",
	"dojo/_base/lang",
	"plugins/core/Common",
	"plugins/workflow/Apps/Apps"
],

function (
	declare,
	lang,
	Common,
	Apps
) {

return declare("plugins.workflow.Apps.Packages",
	[ Common ], {


//dojo.provide("plugins.workflow.Apps.Packages");
//
///* SUMMARY: DISPLAY ONE OR MORE PACKAGES SHARED BY THE ADMIN USER
//
//	-	EACH PACKAGE IS DISPLAYED IN ITS OWN apps OBJECT
//	
//	-	ADMIN USER CREATES AND ADMINISTERS PACKAGE/APPS IN Apps PANE
//*/
//
//// INTERNAL MODULES
//dojo.require("plugins.core.Common");
//dojo.require("plugins.workflow.Apps.Apps");
//
//dojo.declare("plugins.workflow.Apps.Packages", [ plugins.core.Common ], {

/////}}}}}

// CORE WORKFLOW OBJECTS
core : null,

// className : String
//		Name of this class
className : "plugins_workflow_Apps_Packages",

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachPoint : null,

// ARRAY OF plugins.workflow.Apps.Apps OBJECTS
packageApps : [],

constructor : function (args) {
	this.id = dijit.getUniqueId(this.className);
	console.group("Packages    " + this.id + "    constructor");
	console.log("Packages.constructor    args: ");
	console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	this.core = args.core;
	this.parentWidget = args.parentWidget;
	this.attachPoint = args.attachPoint;
	
	this.startup();
	console.groupEnd("Packages    " + this.id + "    constructor");
},
startup : function() {
	console.log("Packages.startup    workflow.Apps.Packages.startup()");
	
	this.setPackages();

	this.setSubscriptions();
},
clear : function () {
	console.log("workflow.Apps.AguaPackages.clear    this.packageApps:");
	console.dir({this_packageapps:this.packageApps});
	console.log("workflow.Apps.AguaPackages.clear    this.packageApps.length: " + this.packageApps.length);
	
	for ( var i = 0; i < this.packageApps.length; i++ ) {
		console.log("workflow.Apps.AguaPackages.clear    i:" + i);
		console.log("workflow.Apps.AguaPackages.clear    DOING this.packageApps[" + i + "].destroy()");
		console.log("workflow.Apps.AguaPackages.clear    this.packageApps[" + i + "]:");
		console.dir({this_packageapps:this.packageApps[i]});
		
		this.packageApps[i].destroy();
		//this.packageApps[i].destroyRecursive();

		console.log("workflow.Apps.AguaPackages.clear    AFTER this.packageApps[" + i + "].destroy()");
		console.log("workflow.Apps.AguaPackages.clear    this.packageApps.length: " + this.packageApps.length);
		console.log("workflow.Apps.AguaPackages.clear    this.packageApps:");
		console.dir({this_packageapps:this.packageApps});
	}

	this.packageApps = [];
},
setSubscriptions : function () {
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updatePackages");
	Agua.updater.subscribe(this, "updateApps");
},
setPackages : function () {
	console.log("Packages.setPackages    ");

	console.log("Packages.setPackages    className: " + this.getClassName(this));
	var apps = this.getAppsArray();
	console.log("Packages.setPackages    apps: ");
	console.dir({apps:apps});

	var packages = this.hashArrayKeyToArray(apps, "package");
    packages = this.uniqueValues(packages);
	console.log("Packages.setPackages    packages: ");
	console.dir({packages:packages});
	console.log("Packages.setPackages    packages.length: " + packages.length);
	
	if ( ! packages || packages.length < 1 )	return;
	
	for ( var i = 0; i < packages.length; i++ ) {
		var packageName = packages[i];
		var applications = dojo.clone(apps);
		applications = this.filterByKeyValues(applications, ["package"], [packageName]);
		console.log("Packages.setPackages    packageName " + packageName + " applications: ");
		console.dir({applications:applications});
		
		console.log("Packages.setPackages    applications.length: " + applications.length);
		if ( applications.length < 1 )    continue;

		// CREATE APPS OBJECT		
		var appsObject = this.createAppsObject(applications);
		console.log("Packages.setPackages    appsObject: " + appsObject);
        
        // PUSH TO this.packageApps
        this.packageApps.push(appsObject);		
	}
},
createAppsObject : function (applications) {
	return new Apps({
		apps: applications,
		core: this.core,
		parentWidget: this.parentWidget,
		attachPoint: this.attachPoint
	});
},
getAppsArray : function () {
	// OVERRIDE THIS
}


}); 	//	end declare

});	//	end define
