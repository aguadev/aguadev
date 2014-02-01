dojo.provide("plugins.core.Agua.App");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS APP METHODS */

dojo.declare( "plugins.core.Agua.App", [], {

/////}}}

getAppHeadings : function () {
	console.log("Agua.App.getAppHeadings    plugins.core.Data.getAppHeadings()");
	var headings = this.cloneData("appheadings");
	console.log("Agua.App.getAppHeadings    headings: " + dojo.toJson(headings));
	return headings;
},
getApps : function () {
	//console.log("Agua.App.getApps    plugins.core.Data.getApps()");
	return this.cloneData("apps");
},
getAguaApps : function () {
	console.log("Agua.App.getAguaApps");
	var apps = this.cloneData("apps");
	
	console.log("Agua.App.getAguaApps    Agua.conf:");
	console.dir({Agua_conf:Agua.conf});
	var aguauser =	Agua.conf.getKey("agua", "aguauser");
	console.log("Agua.App.getAguaApps    aguauser: " + aguauser);
	
	return this.filterByKeyValues(apps, ["owner"], [aguauser]);
},
getAdminApps : function () {
	var apps = this.cloneData("apps");
	var adminuser =	Agua.conf.getKey("agua", "adminuser");
	console.log("Agua.App.getAdminApps    adminuser: " + adminuser);
	
	return this.filterByKeyValues(apps, ["owner"], [adminuser]);
},
getAppTypes : function (apps) {
    console.log("Agua.App.getAppTypes    apps: ");
    console.dir({apps:apps});
    if ( ! apps ) {
        console.log("Agua.App.getAppTypes    apps is not defined. Returning");
        return;
    }

// GET SORTED LIST OF ALL APP TYPES
	var typesHash = new Object;
	for ( var i = 0; i < apps.length; i++ ) {
		typesHash[apps[i].type] = 1;
	}	
	var types = this.hashkeysToArray(typesHash)
	types = this.sortNoCase(types);
	
	return types;
},
getAppType : function (appName) {
// RETURN THE TYPE OF AN APP OWNED BY THE USER
	//console.log("Agua.App.getAppType    appName: *" + appName + "*");
	var apps = this.cloneData("apps");
	for ( var i in apps )
	{
		var app = apps[i];
		if ( app.name.toLowerCase() == appName.toLowerCase() )
			return app.type;
	}
	
	return null;
},
hasApps : function () {
	//console.log("Agua.App.hasApps    plugins.core.Data.hasApps()");
	if ( this.getData("apps").length == 0 )	return false;	
	return true;
},
addApp : function (appObject) {
// ADD AN APP OBJECT TO apps
	console.log("Agua.App.addApp    plugins.core.Data.addApp(appObject)");
	//console.log("Agua.App.addApp    appObject: " + dojo.toJson(appObject));
	var result = this.addData("apps", appObject, [ "name" ]);
	if ( result == true ) this.sortData("apps", "name");
	
	// RETURN TRUE OR FALSE
	return result;
},
removeApp : function (appObject) {
// REMOVE AN APP OBJECT FROM apps
	console.log("Agua.App.removeApp    plugins.core.Data.removeApp(appObject)");
	//console.log("Agua.App.removeApp    appObject: " + dojo.toJson(appObject));
	var result = this.removeData("apps", appObject, ["name"]);
	
	return result;
},
isApp : function (appName) {
// RETURN true IF AN APP EXISTS IN apps
	console.log("Agua.App.isApp    plugins.core.Data.isApp(appName, appObject)");
	console.log("Agua.App.isApp    appName: *" + appName + "*");
	
	var apps = this.getApps();
	for ( var i in apps )
	{
		var app = apps[i];
		console.log("Agua.App.isApp    Checking app.name: *" + app.name + "*");
		if ( app.name.toLowerCase() == appName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
}

});