dojo.provide("plugins.core.Agua.Package");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	PACKAGE METHODS  
*/

dojo.declare( "plugins.core.Agua.Package",	[  ], {

/////}}}

// PACKAGE METHODS
getPackages : function () {
	console.log("Agua.Package.getPackages    plugins.core.Data.getPackages()");
	return this.cloneData("packages");
},
getPackageTypes : function (packages) {
// GET SORTED LIST OF ALL PACKAGE TYPES
	var typesHash = new Object;
	for ( var i = 0; i < packages.length; i++ )
	{
		typesHash[packages[i].type] = 1;
	}	
	var types = this.hashkeysToArray(typesHash)
	types = this.sortNoCase(types);
	
	return types;
},
getPackageType : function (packageName) {
// RETURN THE TYPE OF AN PACKAGE OWNED BY THE USER
	console.log("Agua.Package.getPackageType    plugins.core.Data.getPackageType(packageName)");
	//console.log("Agua.Package.getPackageType    packageName: *" + packageName + "*");
	var packages = this.cloneData("packages");
	for ( var i in packages )
	{
		var thisPackage = packages[i];
		if ( thisPackage["package"].toLowerCase() == packageName.toLowerCase() )
			return thisPackage.type;
	}
	
	return null;
},
hasPackages : function () {
	//console.log("Agua.Package.hasPackages    plugins.core.Data.hasPackages()");
	if ( this.getData("packages").length == 0 )	return false;	
	return true;
},
addPackage : function (packageObject) {
// ADD AN PACKAGE OBJECT TO packages
	console.log("Agua.Package.addPackage    packageObject: ");
	console.dir({packageObject:packageObject});

	var packages = this.getData("packages");
	console.log("Agua.Package.addPackage    packages.length: " + packages.length);
	console.log("Agua.Package.addPackage    packages: ");
	console.dir({packages:packages});

	var result = this.addData("packages", packageObject, ["package", "owner", "installdir"]);
	if ( result == true ) this.sortData("packages", "package");


	packages = this.getData("packages");
	console.log("Agua.Package.addPackage    packages.length: " + packages.length);
	console.log("Agua.Package.addPackage    packages: ");
	console.dir({packages:packages});
	
	// RETURN TRUE OR FALSE
	return result;
},
removePackage : function (packageObject) {
// REMOVE AN PACKAGE OBJECT FROM packages
	console.log("Agua.Package.removePackage    packageObject: ");
	console.dir({packageObject:packageObject});

	var packages = this.getData("packages");
	console.log("Agua.Package.removePackage    packages: ");
	console.dir({packages:packages});

	// REMOVE APPS
	this.removeData("apps", packageObject, ["package", "owner"]);

	// REMOVE PARAMETERS
	this.removeData("parameters", packageObject, ["package", "owner"]);

	console.log("Agua.Package.removePackage    packages.length: " + packages.length);
	var result = this.removeData("packages", packageObject, ["package", "owner"]);
	
	packages = this.getData("packages");
	console.log("Agua.Package.removePackage    FINAL packages.length: " + packages.length);
	
	return result;
},
isPackage : function (username, packageName) {
// RETURN true IF AN PACKAGE EXISTS IN packages
	console.log("Agua.Package.isPackage    username: *" + username + "*");
	console.log("Agua.Package.isPackage    packageName: *" + packageName + "*");
	
	var packages = this.getPackages();
	packages = this.filterByKeyValues(packages, ["owner"], username);
	for ( var i in packages ) {
		var thisPackage = packages[i];
		console.log("Agua.Package.isPackage    Checking package.package: *" + thisPackage["package"] + "*");
		if ( thisPackage["package"].toLowerCase() == packageName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
}

});