dojo.provide("plugins.workflow.Apps.AguaPackages");

/* SUMMARY: DISPLAY ONE OR MORE PACKAGES SHARED BY THE AGUA USER

	-	EACH PACKAGE IS DISPLAYED IN ITS OWN apps OBJECT
	
	-	PACKAGES ARE LOADED WHEN INSTALLING/UPDATING bioapps PACKAGE
*/

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.workflow.Apps.Apps");
dojo.require("plugins.workflow.Apps.Packages");

dojo.declare("plugins.workflow.Apps.AguaPackages", [ plugins.core.Common, plugins.workflow.Apps.Packages ], {

/////}}}

// CORE WORKFLOW OBJECTS
core : null,

// className : String
//		Name of this class
className : "plugins_workflow_Apps_AguaPackages",

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachNode : null,

// ARRAY OF plugins.workflow.Apps.Apps OBJECT
packageApps : [],

setPackages : function () {
	console.group("Packages    " + this.id + "    constructor");

	console.log("AguaPackages.setPackages    caller: " + this.setPackages.caller.nom);

	console.log("AguaPackages.setPackages    className: " + this.getClassName(this));
	var apps = this.getAppsArray();
	console.log("AguaPackages.setPackages    apps: ");
	console.dir({apps:apps});

	var packages = this.hashArrayKeyToArray(apps, "package");
    packages = this.uniqueValues(packages);
	console.log("AguaPackages.setPackages    packages: ");
	console.dir({packages:packages});
	console.log("AguaPackages.setPackages    packages.length: " + packages.length);
	
	if ( ! packages || packages.length < 1 )	return;
	
	for ( var i = 0; i < packages.length; i++ ) {
		var packageName = packages[i];
		console.log("AguaPackages.setPackages    packageName " + packageName);
		var applications = dojo.clone(apps);
		applications = this.filterByKeyValues(applications, ["package"], [packageName]);
		console.log("AguaPackages.setPackages    applications: ");
		console.dir({applications:applications});
		
		console.log("AguaPackages.setPackages    applications.length: " + applications.length);
		if ( applications.length < 1 )    continue;

		// CREATE APPS OBJECT		
		var appsObject = this.createAppsObject(applications);
		console.log("AguaPackages.setPackages    appsObject: " + appsObject);
		console.dir({appsObject:appsObject});
        
        // PUSH TO this.packageApps
        this.packageApps.push(appsObject);		
	}

	console.log("workflow.Apps.AguaPackages.setPackages    FINAL this.packageApps:");
	console.dir({this_packageapps:this.packageApps});

	console.groupEnd("Packages    " + this.id + "    constructor");
},
createAppsObject : function (applications) {
	console.log("AguaPackages.createAppsObject    this.attachNode: ");
	console.dir({this_attachNode:this.attachNode});
	
	return new plugins.workflow.Apps.Apps({
		apps: applications,
		core: this.core,
		parentWidget: this.parentWidget,
		attachNode: this.attachNode
	});
},
// UPDATE AFTER SUBSCRIPTIONS
updatePackages : function (args) {
	console.group("workflow.Packages.AguaPackages    " + this.id + "    updatePackages");
	console.log("workflow.Packages.AguaPackages.updatePackages    args:");
	console.dir(args);

	console.log("workflow.Apps.AguaPackages.updatePackages    DOING this.update()");
	this.update();	

	console.groupEnd("workflow.Packages.AguaPackages    " + this.id + "    updatePackages");
},
updateApps : function (args) {
	console.group("workflow.Packages.AguaPackages    " + this.id + "    updateApps");
	console.log("workflow.Packages.AguaPackages.updateApps    args:");
	console.dir(args);

	this.update();	

	console.groupEnd("workflow.Packages.AguaPackages    " + this.id + "    updateApps");
},
update : function () {
	console.log("workflow.Apps.AguaPackages.update    DOING this.clear()");
	this.clear();
	
	console.log("workflow.Apps.AguaPackages.update    DOING this.setPackages()");
	this.setPackages();
},
getAppsArray : function () {
	return Agua.getAguaApps();
}

	
}); // plugins.workflow.Apps.Packages

