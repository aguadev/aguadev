if(!dojo._hasResource["plugins.core.Agua.Data"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.

dojo._hasResource["plugins.core.Agua.Data"] = true;
dojo.provide("plugins.core.Agua.Data");

/* SUMMARY: THIS CLASS IS INHERITED BY  Agua.js AND CONTAINS THE MAJORITY
  
  OF THE DATA MANIPULATION METHODS (SUPPLEMENTED BY Common.js WHICH Agua.js
  
  ALSO INHERITS).
  
  THE "MUTATORS AND ACCESSORS" METHODS JUST BELOW ARE PRIVATE - THEY SHOULD
  
  NOT BE CALLED DIRECTLY OR OVERRIDDEN.

*/

dojo.declare( "plugins.core.Agua.Data",	[  ], {

/////}}}

// MUTATORS AND ACCESSORS (GET, SET, CLONE, ETC.)
cloneData : function (name) {
	var caller = this.cloneData.caller.nom;
	////console.log("Data.cloneData    caller: " + caller);
	//console.log("Data.cloneData    this.data:");
	//console.dir({this_data:this.data});
	if ( this.data[name] != null )
	    return dojo.clone(this.data[name]);
	else return [];
},
getData : function(name) {
	////console.log("Data.getData    core.Data.getData()");		
	//console.log("Data.getData    this.data:");
	//console.dir({this_data:this.data});
	if ( this.data[name] == null )
		this.data[name] = [];
	return this.data[name];
},
setData : function(name, value) {
	////console.log("Data.setData    core.Data.setData()");		
	//console.log("Data.setData    this.data:");
	//console.dir({this_data:this.data});
    this.data[name] = value;
},
addData : function(name, object, keys) {
	////console.log("Data.addData    name: " + name);		
	////console.log("Data.addData    object: " + dojo.toJson(object));		
	////console.log("Data.addData    keys: " + dojo.toJson(keys));		
	//console.log("Data.addData    this.data:");
	//console.dir({this_data:this.data});
	return this._addObjectToArray(this.data[name], object, keys);	
},
removeData : function(name, object, keys) {
	////console.log("Data.removeData    name: " + name);		
	//console.log("Data.removeData    this.data:");
	//console.dir({this_data:this.data});
	return this._removeObjectFromArray(this.data[name], object, keys);	
},
removeArrayFromData : function (name, array, keys) {
	//console.log("Data.removeArrayFromData    this.data:");
	//console.dir({this_data:this.data});
	return this._removeArrayFromArray(this.data[name], array, keys);
},
addArrayToData : function (name, array, keys) {
	//console.log("Data.addArrayToData    this.data:");
	//console.dir({this_data:this.data});
	return this._addArrayToArray(this.data[name], array, keys);
},
removeObjectsFromData : function (name, array, keys) {
	console.log("Data.removeObjectsFromData    BEFORE REMOVE, this.data[" + name + "]");
	console.dir({this_data:this.data[name]});
	return this._removeObjectsFromArray(this.data[name], array, keys);
},
sortData : function (name, key) {
	this.sortHasharray(this.getData(name), key);
},
loadData : function (data) {
	////console.log("Data.loadData    Agua.loadData(data)");
	////console.log("Data.loadData    data: " + data);
	Agua.data = dojo.clone(data);	
},
}); // end of Agua

}


if(!dojo._hasResource["plugins.core.Agua.Admin"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Admin"] = true;
dojo.provide("plugins.core.Agua.Admin");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	ADMIN METHODS  
*/

dojo.declare( "plugins.core.Agua.Admin",	[  ], {

///////}}}

// ADMIN METHODS
getAdminHeadings : function () {
	console.log("Agua.Admin.getAdminHeadings    plugins.core.Data.getAdminHeadings()");
	var headings = this.cloneData("adminheadings");
	console.log("Agua.Admin.getAdminHeadings    headings: " + dojo.toJson(headings));
	return headings;
},
getAccess : function () {
	//console.log("Agua.Admin.getAccess    plugins.core.Data.getAccess()");
	return this.cloneData("access");
}

});

}

if(!dojo._hasResource["plugins.core.Agua.App"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.App"] = true;
dojo.provide("plugins.core.Agua.App");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	APP METHODS  
*/

dojo.declare( "plugins.core.Agua.App",	[  ], {

/////}}}

// APP METHODS
getApps : function () {
	//console.log("Agua.App.getApps    plugins.core.Data.getApps()");
	return this.cloneData("apps");
},
getAppTypes : function (apps) {
// GET SORTED LIST OF ALL APP TYPES
	var typesHash = new Object;
	for ( var i = 0; i < apps.length; i++ )
	{
		typesHash[apps[i].type] = 1;
	}	
	var types = this.hashkeysToArray(typesHash)
	types = this.sortNoCase(types);
	
	return types;
},
getAppType : function (appName) {
// RETURN THE TYPE OF AN APP OWNED BY THE USER
	console.log("Agua.App.getAppType    plugins.core.Data.getAppType(appName)");
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

}

if(!dojo._hasResource["plugins.core.Agua.Aws"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Aws"] = true;
dojo.provide("plugins.core.Agua.Aws");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	AWS METHODS  
*/

dojo.declare( "plugins.core.Agua.Aws",	[  ], {

/////}}}

getAws : function () {
// RETURN CLONE OF this.aws
	//console.log("Agua.Aws.getAws    plugins.core.Data.getAws(username)");
	//console.log("Agua.Aws.getAws    username: " + username);
	return this.cloneData("aws");
},
setAws : function (aws) {
// RETURN ENTRY FOR username IN this.aws
	console.log("Agua.Aws.setAws    plugins.core.Data.setAws(aws)");
	console.log("Agua.Aws.setAws    aws: " + dojo.toJson(aws));
	if ( aws == null )
	{
		console.log("Agua.Aws.setAws    aws is null. Returning");
		return;
	}
	if ( aws.amazonuserid == null )
	{
		console.log("Agua.Aws.setAws    aws.amazonuserid is null. Returning");
		return;
	}
	this.setData("aws", aws);
	
	return aws;
},

getAvailzonesByRegion : function (region) {
	if ( region == null )	return;
	var regionzones = this.cloneData("regionzones");
	if ( regionzones[region] != null )
		return regionzones[region];
	
	return [];
}


});

}

if(!dojo._hasResource["plugins.core.Agua.Cluster"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Cluster"] = true;
dojo.provide("plugins.core.Agua.Cluster");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	CLUSTER METHODS  
*/

dojo.declare( "plugins.core.Agua.Cluster",	[  ], {

/////}}}

getClusterObject : function (clusterName) {
	console.log("Agua.Cluster.getClusterObject    plugins.core.Data.getClusterObject(clusterName)");
	console.log("Agua.Cluster.getClusterObject    clusterName: " + clusterName);
	var clusters = this.getClusters();
	console.log("Agua.Cluster.getClusterObject    clusters: " + dojo.toJson(clusters));
	if ( clusters == null )	return [];
	var keyArray = ["cluster"];
	var valueArray = [clusterName];
	clusters = this.filterByKeyValues(clusters, keyArray, valueArray);
	console.log("Agua.Cluster.getClusterObject    FILTERED clusters: " + dojo.toJson(clusters));
	
	if ( clusters != null && clusters.length != 0 )
		return clusters[0];
	return null;
},
getClusters : function () {
// RETURN A COPY OF THE clusters ARRAY
	//console.log("Agua.Cluster.getClusters    plugins.core.Data.getClusters()");
	return this.cloneData("clusters");
},
getClusterByWorkflow : function (projectName, workflowName) {
// RETURN THE CLUSTER FOR THIS WORKFLOW, OR "" IF NO CLUSTER ASSIGNED
	//console.log("Agua.Cluster.getClusterByWorkflow    plugins.core.Data.getClusterByWorkflow(projectName, workflowName)");
	//console.log("Agua.Cluster.getClusterByWorkflow    projectName: " + projectName);
	//console.log("Agua.Cluster.getClusterByWorkflow    workflowName: " + workflowName);

	var clusterworkflows = this.cloneData("clusterworkflows");
	//console.log("Agua.Cluster.getClusterObjectByWorkflow   clusterworkflows: " + dojo.toJson(clusterworkflows));
    clusterworkflows = this.filterByKeyValues(clusterworkflows, ["project", "workflow"], [projectName, workflowName]);
	//console.log("Agua.Cluster.getClusterObjectByWorkflow   clusterworkflows: " + dojo.toJson(clusterworkflows));
    
	if ( clusterworkflows != null && clusterworkflows.length > 0 )
        return clusterworkflows[0].cluster;
		
    return null;
},
isClusterWorkflow : function (clusterObject) {
// RETURN 1 IF THE ENTRY ALREADY EXISTS IN clusterworkflows, 0 OTHERWISE
	//console.log("Agua.Cluster.isClusterWorkflow    plugins.core.Data.isClusterWorkflow(clusterObject)");
	//console.log("Agua.Cluster.isClusterWorkflow    clusterObject: " + dojo.toJson(clusterObject));

	var clusterworkflows = this.cloneData("clusterworkflows");
	//console.log("Agua.Cluster.isClusterWorkflow    BEFORE clusterworkflows: " + dojo.toJson(clusterworkflows));
    clusterworkflows = this.filterByKeyValues(clusterworkflows, ["project", "workflow", "cluster"], [clusterObject.project, clusterObject.workflow, clusterObject.cluster]);
	//console.log("Agua.Cluster.isClusterWorkflow    AFTER clusterworkflows: " + dojo.toJson(clusterworkflows));
    
	if ( clusterworkflows != null && clusterworkflows.length > 0 )
        return 1;
		
    return 0;
},
getClusterObjectByWorkflow : function (projectName, workflowName) {

	var clusterName = this.getClusterByWorkflow(projectName, workflowName);
	if ( clusterName == null || ! clusterName) 	return null;
	console.log("Agua.Cluster.getClusterObjectByWorkflow    clusterName: " + clusterName);
	
	return this.getClusterObject(clusterName);
},
getClusterLongName : function (cluster) {
	var username = this.cookie("username");
	var clusterName = "";
	if ( cluster != null && cluster ) clusterName = username + "-" + cluster;
	
	return clusterName;
},
isCluster : function (clusterName) {
// RETURN true IF A CLUSTER EXISTS
	//console.log("Agua.Cluster.isCluster    plugins.core.Data.isCluster(clusterName)");
	//console.log("Agua.Cluster.isCluster    clusterName: *" + clusterName + "*");

	var clusterObjects = this.getClusters();
	var inArray = this._objectInArray(clusterObjects, { cluster: clusterName }, ["cluster"]);	
	//console.log("Agua.Cluster.isCluster    inArray: " + inArray);
	//console.log("Agua.Cluster.isCluster    clusterObjects: " + dojo.toJson(clusterObjects));

	return inArray;
},
addCluster : function (clusterObject) {
	this._removeCluster(clusterObject);
	this._addCluster(clusterObject);

	// SAVE ON REMOTE DATABASE
	var url = this.cgiUrl + "workflow.cgi?";
	clusterObject.username = this.cookie("username");	
	clusterObject.sessionId = this.cookie("sessionId");	
	clusterObject.mode = "addCluster";
	console.log("Agua.Cluster.addCluster    clusterObject: " + dojo.toJson(clusterObject));
	
	this.doPut({ url: url, query: clusterObject, sync: false, timeout: 15000 });
},
newCluster : function (clusterObject) {
	console.log("Agua.Cluster.newCluster    core.Data.newCluster(clusterObject)");
	console.log("Agua.Cluster.newCluster    clusterObject: " + dojo.toJson(clusterObject));

	this._removeCluster(clusterObject);
	this._addCluster(clusterObject);

	// SAVE ON REMOTE DATABASE
	var url = this.cgiUrl + "workflow.cgi?";
	clusterObject.username = this.cookie("username");	
	clusterObject.sessionId = this.cookie("sessionId");	
	clusterObject.mode = "newCluster";
	console.log("Agua.Cluster.newCluster    clusterObject: " + dojo.toJson(clusterObject));
	
	this.doPut({
		url: url,
		query: clusterObject,
		sync: false,
		timeout: 15000,
		callback: dojo.hitch(this, "toast")
	});
},
removeCluster : function (clusterObject) {
	//console.log("Agua.Cluster.removeCluster    Agua.removeCluster(clusterObject)");
	//console.log("Agua.Cluster.removeCluster    clusterObject: " + dojo.toJson(clusterObject));

	var success = this._removeCluster(clusterObject)
	if ( success == false ) {
		console.log("this.removeCluster    this._removeCluster(clusterObject) returned false for cluster: " + clusterObject.cluster);
		return;
	}
	
	var url = this.cgiUrl + "workflow.cgi?";
	clusterObject.username = this.cookie("username");
	clusterObject.sessionId = this.cookie("sessionId");
	clusterObject.mode = "removeCluster";
	console.log("this.removeCluster    clusterObject: " + dojo.toJson(clusterObject));

	this.doPut({ url: url, query: clusterObject, sync: false, timeout: 15000 });	
},
_removeCluster : function (clusterObject) {
// REMOVE A CLUSTER OBJECT FROM THE clusters ARRAY
	console.log("Agua.Cluster._removeCluster    plugins.core.Data._removeCluster(clusterObject)");
	console.log("Agua.Cluster._removeCluster    clusterObject: " + dojo.toJson(clusterObject));
	var requiredKeys = ["cluster"];
	return this.removeData("clusters", clusterObject, requiredKeys);
},
_addCluster : function (clusterObject) {
// ADD A CLUSTER TO clusters AND SAVE ON REMOTE SERVER
	console.log("Agua.Cluster._addCluster    plugins.core.Data._addCluster(clusterObject)");
	//console.log("Agua.Cluster._addCluster    clusterObject: " + dojo.toJson(clusterObject));

	// DO THE ADD
	var requiredKeys = ["cluster"];
	return this.addData("clusters", clusterObject, requiredKeys);
},
_removeClusterWorkflow : function (clusterObject) {
// REMOVE A CLUSTER OBJECT FROM THE clusters ARRAY
	console.log("Agua.Cluster._removeClusterWorkflow    plugins.core.Data._removeClusterWorkflow(clusterObject)");
	var requiredKeys = ["project", "workflow"];
	return this.removeData("clusterworkflows", clusterObject, requiredKeys);
},
_addClusterWorkflow : function (clusterObject) {
// ADD A CLUSTER TO clusters AND SAVE ON REMOTE SERVER
	console.log("Agua.Cluster._addClusterWorkflow    plugins.core.Data._addClusterWorkflow(clusterObject)");
	console.log("Agua.Cluster._addClusterWorkflow    clusterObject: " + dojo.toJson(clusterObject));

	// DO THE ADD
	var requiredKeys = ["cluster", "project", "workflow"];
	return this.addData("clusterworkflows", clusterObject, requiredKeys);
},
getAmis : function () {
// RETURN A COPY OF THE amis ARRAY
	//console.log("Agua.Cluster.getAmis    plugins.core.Data.getAmis()");
	return this.cloneData("amis");
},
getAmiObjectById : function (amiid) {
	//console.log("Agua.Cluster.getAmiObjectById    plugins.core.Data.getAmiObjectById()");
	var amis = this.getAmis();	
	//console.log("Agua.Cluster.getAmiObjectById    amis: " + dojo.toJson(amis));
	return this._getObjectByKeyValue(amis, ["amiid"], amiid);	
},
addAmi : function (amiObject) {
	this._removeAmi(amiObject);
	this._addAmi(amiObject);

	// SAVE ON REMOTE DATABASE
	var url = this.cgiUrl + "workflow.cgi?";
	amiObject.username = this.cookie("username");	
	amiObject.sessionId = this.cookie("sessionId");	
	amiObject.mode = "addAmi";
	console.log("Agua.Cluster.addAmi    amiObject: " + dojo.toJson(amiObject));
	
	this.doPut({ url: url, query: amiObject, sync: false, timeout: 15000 });
},
removeAmi : function (amiObject) {
	console.log("Agua.Cluster.removeAmi    Agua.removeAmi(amiObject)");
	//console.log("Agua.Cluster.removeAmi    amiObject: " + dojo.toJson(amiObject));

	var success = this._removeAmi(amiObject)
	if ( success == false ) {
		console.log("this.removeAmi    this._removeAmi(amiObject) returned false for ami: " + amiObject.ami);
		return;
	}
	
	var url = this.cgiUrl + "sharing.cgi?";
	amiObject.username = this.cookie("username");
	amiObject.sessionId = this.cookie("sessionId");
	amiObject.mode = "removeAmi";
	//console.log("this.removeAmi    amiObject: " + dojo.toJson(amiObject));

	this.doPut({ url: url, query: amiObject, sync: false, timeout: 15000 });	
},
_removeAmi : function (amiObject) {
// REMOVE A CLUSTER OBJECT FROM THE amis ARRAY
	console.log("Agua.Cluster._removeAmi    plugins.core.Data._removeAmi(amiObject)");
	//console.log("Agua.Cluster._removeAmi    amiObject: " + dojo.toJson(amiObject));
	var requiredKeys = ["amiid"];
	return this.removeData("amis", amiObject, requiredKeys);
},
_addAmi : function (amiObject) {
// ADD A CLUSTER TO amis AND SAVE ON REMOTE SERVER
	console.log("Agua.Cluster._addAmi    plugins.core.Data._addAmi(amiObject)");
	//console.log("Agua.Cluster._addAmi    amiObject: " + dojo.toJson(amiObject));

	// DO THE ADD
	var requiredKeys = ["amiid"];
	return this.addData("amis", amiObject, requiredKeys);
}


});

}

if(!dojo._hasResource["plugins.core.Agua.Feature"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Feature"] = true;
dojo.provide("plugins.core.Agua.Feature");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	FEATURE METHODS  
*/
dojo.declare( "plugins.core.Agua.Feature",	[  ], {

/////}}}

getViewFeatures : function (projectName, viewName) {
// GET THE UNIQUE SPECIES (AND BUILD) FOR A GIVEN VIEW
	//console.log("Agua.View.getViewFeatures     plugins.core.Data.getViewFeatures(projectName, viewName)");
	//console.log("Agua.View.getViewFeatures    projectName: " + projectName);
	//console.log("Agua.View.getViewFeatures    viewName: " + viewName);
	if ( projectName == null || ! projectName )
	{
		//console.log("Agua.View.getViewFeatures     projectName is null or empty. Returning");
		return;
	}

	var viewfeatures = this.cloneData("viewfeatures");
	////console.log("Agua.View.getViewFeatures    viewfeatures: " + dojo.toJson(viewfeatures));
	var keyArray = ["project", "view"];
	var valueArray = [projectName, viewName];
	viewfeatures = this.filterByKeyValues(viewfeatures, keyArray, valueArray);

	//console.log("Agua.View.getViewFeatures    Returning viewfeatures: " + dojo.toJson(viewfeatures));
	return viewfeatures;
},
hasViewFeature : function (projectName, viewName, featureName) {
	//console.log("Agua.View.hasViewFeature    projectName: " + projectName);
	//console.log("Agua.View.hasViewFeature    viewName: " + viewName);
	//console.log("Agua.View.hasViewFeature    featureName: " + featureName);
	var features = this.getViewFeatures(projectName, viewName);
	//console.log("Agua.View.hasViewFeature    features: ");
	//console.dir({features:features});

	if ( features == null || features == [] )	return;
	
	var featureObject = {
		project: 	projectName,
		view:		viewName,
		feature:	featureName
	};
	var keys = ["project", "view", "feature"];
	return this._objectInArray(features, featureObject, keys);
},
getFeatureProjects : function () {
	//console.log("Agua.Feature.getFeatureProjects     plugins.core.Data.getFeatureProjects()");
	var features = this.cloneData("features");
	//console.log("Agua.Feature.getFeatureProjects     features: ");
	//console.dir({features:features});
	
	var projects = this.hashArrayKeyToArray(features, "project");
	console.log("Agua.Feature.getFeatureProjects     projects: ");
	console.dir({projects:projects});
	
	projects = this.uniqueValues(projects);
	
	return projects;
},
getViewProjectWorkflows : function (projectName) {
	//console.log("Agua.Feature.getViewProjectWorkflows     plugins.core.Data.getViewProjectWorkflows(projectName)");
	if ( projectName == null || ! projectName )
	{
		console.log("Agua.Feature.getViewProjectWorkflows     projectName is null or empty. Returning");
		return;
	}
	var features = this.cloneData("features");
	//console.log("Agua.Feature.getViewProjectWorkflows    features: " + dojo.toJson(features));
	var keyArray = ["project"];
	var valueArray = [projectName];
	features = this.filterByKeyValues(features, keyArray, valueArray);
	//console.log("Agua.Feature.getViewProjectWorkflows    FILTERED features: " + dojo.toJson(features));
	var workflows = new Array;
	for ( var i = 0; i < features.length; i++ )
		workflows.push(features[i].workflow);
	
	workflows = this.uniqueValues(workflows);
	//console.log("Agua.Feature.getViewProjectWorkflows    Returning workflows: " + dojo.toJson(workflows));
	
	return workflows;
},
getViewWorkflowFeatures : function (projectName, workflowName) {
	//console.log("Agua.Feature.getViewWorkflowFeatures     plugins.core.Data.getViewWorkflowFeatures(projectName, workflowName, speciesName, buildName)");
	//console.log("Agua.Feature.getViewWorkflowFeatures    projectName: " + projectName);
	//console.log("Agua.Feature.getViewWorkflowFeatures    workflowName: " + workflowName);
	var features = this.cloneData("features");
	//console.log("Agua.Feature.getViewWorkflowFeatures    features: " + dojo.toJson(features));
	var keyArray = ["project", "workflow"];
	var valueArray = [projectName, workflowName];
	features = this.filterByKeyValues(features, keyArray, valueArray);
	//console.log("Agua.Feature.getViewWorkflowFeatures    workflow features: " + dojo.toJson(features));

	return features;
},
getViewSpeciesFeatureNames : function (projectName, workflowName, speciesName, buildName) {
	// GET THE FEATURE NAMES FOR A GIVEN PROJECT, WORKFLOW AND SPECIES BUILD
	//console.log("Agua.Feature.getViewSpeciesFeatureNames    projectName: " + projectName);
	//console.log("Agua.Feature.getViewSpeciesFeatureNames    workflowName: " + workflowName);
	//console.log("Agua.Feature.getViewSpeciesFeatureNames    speciesName: " + speciesName);
	//console.log("Agua.Feature.getViewSpeciesFeatureNames    buildName: " + buildName);
	var features = this.getViewSpeciesFeatures(projectName, workflowName, speciesName, buildName);
	//console.log("Agua.Feature.getViewSpeciesFeatureNames    features: ");
	//console.dir({features:features});
	
	var featureNames = new Array;
	for ( var i = 0; i < features.length; i++ )
		featureNames.push(features[i].feature);
	
	featureNames = this.uniqueValues(featureNames);
	//console.log("Agua.Feature.getViewSpeciesFeatureNames    featureNames: ");
	//console.dir({featureNames:featureNames});	
	
	return featureNames;
},
getViewSpeciesFeatures : function (projectName, workflowName, speciesName, buildName) {
	// GET THE FEATURES FOR A GIVEN PROJECT, WORKFLOW AND SPECIES BUILD
	//console.log("Agua.Feature.getViewSpeciesFeatures     plugins.core.Data.getViewSpeciesFeatures(projectName, workflowName, speciesName, buildName)");
	//console.log("Agua.Feature.getViewSpeciesFeatures    projectName: " + projectName);
	//console.log("Agua.Feature.getViewSpeciesFeatures    workflowName: " + workflowName);
	//console.log("Agua.Feature.getViewSpeciesFeatures    speciesName: " + speciesName);
	//console.log("Agua.Feature.getViewSpeciesFeatures    buildName: " + buildName);

	if ( projectName == null || ! projectName
		|| workflowName == null || ! workflowName
		|| speciesName == null || ! speciesName )
	{
		console.log("Agua.Feature.getViewSpeciesFeatures     projectName is null or empty. Returning");
		return;
	}
	var features = this.cloneData("features");
	//console.log("Agua.Feature.getViewSpeciesFeatures    features: " + dojo.toJson(features));
	var keyArray = ["project", "workflow", "species", "build"];
	var valueArray = [projectName, workflowName, speciesName, buildName];
	features = this.filterByKeyValues(features, keyArray, valueArray);
	//console.log("Agua.Feature.getViewSpeciesFeatures    workflow features: " + dojo.toJson(features));

	return features;
},
_removeViewFeature : function (featureObject) {
	//console.log("Agua.Feature.removeViewFeature    plugins.core.Data.removeViewFeature(featureObject)");
	//console.log("Agua.Feature.removeViewFeature    featureObject: " + dojo.toJson(featureObject));

	// REMOVE LOCALLY AND THEN ON THE REMOTE
	var requiredKeys = ["project", "view", "feature"];

	var removeSuccess = Agua.removeData("viewfeatures", featureObject, requiredKeys);
	//console.log("Agua.Feature.removeViewFeature    removeSuccess: " + dojo.toJson(removeSuccess));
	if ( ! removeSuccess ) return;

	var viewObject = Agua.getViewObject(featureObject.project, featureObject.view);
	//console.log("Agua.Feature.removeViewFeature    viewObject: " + dojo.toJson(viewObject));

	// REMOVE TRACK IF PRESENT IN DISPLAYED TRACKS (tracklist)
	var tracklist = viewObject.tracklist;
	console.log("Agua.Feature.removeViewFeature    BEFORE tracklist: " + dojo.toJson(tracklist));
    var array = tracklist.split(/,/);
	//console.dir({array:array});
    for ( var i = 0; i < array.length; i++ ) {
        if ( array[i] == featureObject.feature ) {
            console.log("matched feature in array[" + i + "]: " + array[i]);
            array.splice(i, 1);
        }
    }
	tracklist = array.join(",");
	viewObject.tracklist = tracklist;
	console.log("Agua.Feature.removeViewFeature    AFTER tracklist: " + dojo.toJson(tracklist));

	// REMOVE VIEW OBJECT FROM VIEWS
	Agua.removeData("views", viewObject, ["project", "view"]);
	Agua.addData("views", viewObject, ["project", "view"]);

	views = Agua.getData("views");
	console.dir({views:views});
	
	return true;
},
isFeature : function (featureObject) {
// RETURN true IF THE FEATURE ALREADY EXISTS IN THE VIEW

	//console.log("Agua.Feature.isFeature    plugins.core.Data.isFeature(projectName, viewName)");
	//console.log("Agua.Feature.isFeature    featureObject: " + dojo.toJson(featureObject));
	
	var viewfeatures = this.getViewFeatures(featureObject.project, featureObject.view);
	//console.log("Agua.Feature.isFeature    viewfeatures: " + dojo.toJson(viewfeatures));
	if ( this._objectInArray(viewfeatures, featureObject, ["project", "view", "feature", "species", "build"]))
	{
		//console.log("Agua.Feature.isFeature    feature is in viewfeatures for this project/view. Returning true.");
		return true;
	}
	
	return false;
},
_addViewFeature : function (featureObject) {
	//console.log("Agua.Feature._addViewFeature    plugins.core.Data._addViewFeature(featureObject)");
	//console.log("Agua.Feature._addViewFeature    featureObject: " + dojo.toJson(featureObject));
	
	// RETURN IF FEATURE ALREADY EXISTS
	if ( this.isFeature(featureObject) )	return;

	// ADD LOCALLY 
	var requiredKeys = ["project", "view", "feature", "species", "build"];
	return this.addData("viewfeatures", featureObject, requiredKeys);
}

});

}

if(!dojo._hasResource["plugins.core.Agua.File"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.File"] = true;
dojo.provide("plugins.core.Agua.File");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS FILE CACHE 
  
	AND FILE MANIPULATION METHODS  
*/

dojo.declare( "plugins.core.Agua.File",	[  ], {

/////}}}

// FILECACHE METHODS
getFoldersUrl : function () {
	return Agua.cgiUrl + "folders.cgi?";
},
setFileCaches : function (url) {
	console.log("Agua.File.setFileCache    url: " + url);
	var callback = dojo.hitch(this, function (data) {
		//console.log("Agua.File.setFileCache    BEFORE setData, data: ");
		//console.dir({data:data});
		this.setData("filecaches", data);
	});

	//console.log("Agua.File.setFileCache    Doing this.fetchJson(url, callback)");
	this.fetchJson(url, callback);
},
fetchJson : function (url, callback) {
	console.log("Agua.File.fetchJson    url: " + url);
    var thisObject = this;
    dojo.xhrGet({
        url: url,
		sync: false,
        handleAs: "json",
        handle: function(data) {
			//console.log("Agua.File.fetchJson    data: ");
			//console.dir({data:data});
			callback(data);
        },
        error: function(response) {
            console.log("Agua.File.fetchJson    Error with JSON Post, response: " + response);
        }
    });
},
getFileCache : function (username, location) {
	console.log("Agua.File.getFileCache    username: " + username);
	console.log("Agua.File.getFileCache    location: " + location);
	
	var fileCaches = this.cloneData("filecaches");
	console.log("Agua.File.getFileCache    fileCaches: ");
	console.dir({fileCaches:fileCaches});
	
	// RETURN IF NO ENTRIES FOR USER
	if ( ! fileCaches[username] )	return null;
	
	return fileCaches[username][location];
},
setFileCache : function (username, location, item) {
	console.log("Agua.File.setFileCache    username: " + username);
	console.log("Agua.File.setFileCache    location: " + location);
	console.log("Agua.File.setFileCache    item: ");
	console.dir({item:item});
	
	var fileCaches = this.getData("filecaches");
	if ( ! fileCaches )	fileCaches = {};
	if ( ! fileCaches[username] )	fileCaches[username] = {};
	fileCaches[username][location] = item;

	var parentDir = this.getParentDir(location);
	console.log("Agua.File.setFileCache    parentDir: " + parentDir);
	if ( ! parentDir )	return;
	
	var parent = fileCaches[username][parentDir];
	if ( ! parent )	return;
	console.log("Agua.File.setFileCache    parent: " + parent);
	this.addItemToParent(parent, item);

	console.log("Agua.File.setFileCache    parent: " + parent);
	console.dir({parent:parent});	
},
addItemToParent : function (parent, item) {
	parent.items.push(item);
},
getFileSystem : function (putData, callback, request) {
	console.log("Agua.File.getFileSystem    caller: " + this.getFileSystem.caller.nom);
	
	console.log("Agua.File.getFileSystem    putData:");
	console.dir({putData:putData});
	console.log("Agua.File.getFileSystem    callback: " + callback);
	console.dir({callback:callback});
	console.log("Agua.File.getFileSystem    request:");
	console.dir({request:request});
	
	// SET DEFAULT ARGS EMPTY ARRAY
	if ( ! request )
		request = new Array;
	
	// SET LOCATION
	var location = '';
	if ( putData.location || putData.query )
		location = putData.query || putData.location;
	console.log("Agua.File.getFileSystem    location: " + location);
	
	var username = putData.username;
	console.log("Agua.File.getFileSystem    username: " + username);
	
	// USE IF CACHED
	var fileCache = this.getFileCache(username, location);
	console.log("Agua.File.getFileSystem    fileCache:");
	console.dir({fileCache:fileCache});
	if ( fileCache ) {
		console.log("Agua.File.getFileSystem    fileCache IS DEFINED. Doing setTimeout callback(fileCache, request)");
		
		// DELAY TO AVOID node is undefined ERROR
		setTimeout( function() {
			callback(fileCache, request);
		},
		10,
		this);

		return;
	}
	else {
		console.log("Agua.File.getFileSystem    fileCache NOT DEFINED. Doing remote query");
		this.queryFileSystem(putData, callback, request);
	}
},
queryFileSystem : function (putData, callback, request) {
	console.log("Agua.File.queryFileSystem    putData:");
	console.dir({putData:putData});
	console.log("Agua.File.queryFileSystem    callback:");
	console.dir({callback:callback});
	console.log("Agua.File.queryFileSystem    request:");
	console.dir({request:request});
	
	// SET LOCATION
	var location = '';
	if ( putData.location || putData.query )
		location = putData.query;
	if ( ! putData.path && location )	putData.path = location;
	console.log("Agua.File.queryFileSystem    location: " + location);

	// SET USERNAME
	var username = putData.username;
	
	var url = this.cgiUrl + "folders.cgi";
	
	// QUERY REMOTE
	var thisObject = this;
	var putArgs = {
		url			: 	url,
		//url			: 	putData.url,
		contentType	: 	"text",
		sync		: 	false,
		preventCache: 	true,
		handleAs	: 	"json-comment-optional",
		putData		: 	dojo.toJson(putData),
		handle		:	function(response) {
			console.log("Agua.File.queryFileSystem    handle response:");
			console.dir({response:response});
			
			thisObject.setFileCache(username, location, dojo.clone(response));
			
			callback(response, request);
		}
	};

	var deferred = dojo.xhrPut(putArgs);
	deferred.addCallback(callback);
	var scope = request.scope || dojo.global;
	deferred.addErrback(function(error){
		if(request.onError){
			request.onError.call(scope, error, request);
		}
	});
},
removeFileTree : function (username, location) {
	console.log("Agua.File.removeFileTree    username: " + username);
	console.log("Agua.File.removeFileTree    location: " + location);

	var fileCaches = this.getData("filecaches");
	console.log("Agua.File.removeFileTree    fileCaches: ");
	console.dir({fileCaches:fileCaches});

	if ( ! fileCaches )	{
		console.log("Agua.File.removeFileTree    fileCaches is null. Returning");
		return;
	}
	
	var rootTree = fileCaches[username];
	console.log("Agua.File.removeFileTree    rootTree: ");
	console.dir({rootTree:rootTree});

	if ( ! rootTree ) {
		console.log("Agua.File.removeFileTree    rootTree is null. Returning");
		return;
	}

	for ( var fileRoot in fileCaches[username] ) {
		if ( fileRoot.match('^' + location +'$')
                    || fileRoot.match('^' + location +'\/') ) {
			console.log("Agua.File.removeFileTree    DELETING fileRoot: " + fileRoot);
//			delete fileCaches[username][fileRoot];
		}		
	}
	
	if ( ! location.match(/^(.+)\/[^\/]+$/) )	{
		console.log("Agua.File.removeFileTree    No parentDir. Returning");
		return;
	}
	var parentDir = location.match(/^(.+)\/[^\/]+$/)[1];
	var child = location.match(/^.+\/([^\/]+)$/)[1];
	console.log("Agua.File.removeFileTree    parentDir: " + parentDir);
	console.log("Agua.File.removeFileTree    child: " + child);
	
	this.removeItemFromParent(fileCaches[username][parentDir], child);
	
	var project1 = fileCaches[username][parentDir];
	console.log("Agua.File.removeFileTree    project1: " + project1);
	console.dir({project1:project1});	

	console.log("Agua.File.removeFileTree    END");
},
removeItemFromParent : function (parent, childName) {
	for ( i = 0; i < parent.items.length; i++ ) {
		var childObject = parent.items[i];
		if ( childObject.name == childName ) {
			parent.items.splice(i, 1);
			break;
		}
	}
},
removeRemoteFile : function (username, location, callback) {
	console.log("Agua.File.removeRemoteFile    username: " + username);
	console.log("Agua.File.removeRemoteFile    location: " + location);
	console.log("Agua.File.removeRemoteFile    callback: " + callback);

	// DELETE ON REMOTE
	var url 			= 	this.getFoldersUrl();
	var putData 		= 	new Object;
	putData.mode		=	"removeFile";
	putData.sessionId	=	Agua.cookie('sessionId');
	putData.username	=	Agua.cookie('username');
	putData.file		=	location;

	var thisObject = this;
	dojo.xhrPut(
		{
			url			: 	url,
			putData		:	dojo.toJson(putData),
			handleAs	: 	"json",
			sync		: 	false,
			handle		: 	function(response) {
				if ( callback )	callback(response);
			}
		}
	);
},
renameFileTree : function (username, oldLocation, newLocation) {
	console.log("Agua.File.renameFileTree    username: " + username);
	console.log("Agua.File.renameFileTree    oldLocation: " + oldLocation);
	console.log("Agua.File.renameFileTree    newLocation: " + newLocation);

	var fileCaches = this.getData("filecaches");
	console.log("Agua.File.renameFileTree    fileCaches: ");
	console.dir({fileCaches:fileCaches});

	if ( ! fileCaches )	{
		console.log("Agua.File.renameFileTree    fileCaches is null. Returning");
		return;
	}
	
	var rootTree = fileCaches[username];
	console.log("Agua.File.renameFileTree    rootTree: ");
	console.dir({rootTree:rootTree});

	if ( ! rootTree ) {
		console.log("Agua.File.renameFileTree    rootTree is null. Returning");
		return;
	}

	for ( var fileRoot in fileCaches[username] ) {
		if ( fileRoot.match('^' + oldLocation +'$')
                    || fileRoot.match('^' + oldLocation +'\/') ) {
			console.log("Agua.File.renameFileTree    DELETING fileRoot: " + fileRoot);
			var value = fileCaches[username][fileRoot];
			var re = new RegExp('^' + oldLocation);
			var newRoot = fileRoot.replace(re, newLocation);
			console.log("Agua.File.renameFileTree    ADDING newRoot: " + newRoot);
			delete fileCaches[username][fileRoot];
			fileCaches[username][newRoot] = value;
		}		
	}

		
	var parentDir = this.getParentDir(oldLocation);
	if ( ! parentDir ) 	return;
	console.log("Agua.File.renameFileTree    Doing this.renameItemInParent()");
	var child = this.getChild(oldLocation);
	var newChild = newLocation.match(/^.+\/([^\/]+)$/)[1];
	console.log("Agua.File.renameFileTree    parentDir: " + parentDir);
	console.log("Agua.File.renameFileTree    child: " + child);
	console.log("Agua.File.renameFileTree    newChild: " + newChild);
	var parent = fileCaches[username][parentDir];
	this.renameItemInParent(parent, child, newChild);
	
	console.log("Agua.File.renameFileTree    parent: " + parent);
	console.dir({parent:parent});	

	console.log("Agua.File.renameFileTree    END");
},
renameItemInParent : function (parent, childName, newChildName) {
	for ( i = 0; i < parent.items.length; i++ ) {
		var childObject = parent.items[i];
		if ( childObject.name == childName ) {
			var re = new RegExp(childName + "$");
			parent.items[i].name= parent.items[i].name.replace(re, newChildName);
			console.log("Agua.File.renameItemInParent    NEW parent.items[" + i + "].name: " + parent.items[i].name);
			parent.items[i].path= parent.items[i].path.replace(re, newChildName);
			console.log("Agua.File.repathItemInParent    NEW parent.items[" + i + "].path: " + parent.items[i].path);
			break;
		}
	}
},
getParentDir : function (location) {
	if ( ! location.match(/^(.+)\/[^\/]+$/) )	return null;
	return location.match(/^(.+)\/[^\/]+$/)[1];
},
getChild : function (location) {
	if ( ! location.match(/^.+\/([^\/]+)$/) )	return null;
	return location.match(/^.+\/([^\/]+)$/)[1];
},
isDirectory : function (username, location) {
	// USE IF CACHED
	var fileCache = this.getFileCache(username, location);
	console.log("Agua.File.isDirectory    username: " + username);
	console.log("Agua.File.isDirectory    location: " + location);
	console.log("Agua.File.isDirectory    fileCache: ");
	console.dir({fileCache:fileCache});

	if ( fileCache )	return fileCache.directory;
	return null;
},
isFileCacheItem : function (username, directory, itemName) {
	console.log("Agua.isFileCacheItem     username: " + username);
	console.log("Agua.isFileCacheItem     directory: " + directory);
	console.log("Agua.isFileCacheItem     itemName: " + itemName);

	var fileCache = this.getFileCache(username, directory);
	console.log("Agua.isFileCacheItem     fileCache: " + fileCache);
	console.dir({fileCache:fileCache});
	
	if ( ! fileCache || ! fileCache.items )	return false;
	
	for ( var i = 0; i < fileCache.items.length; i++ ) {
		if ( fileCache.items[i].name == itemName)	return true;
	}
	
	return false;

},

// FILE METHODS
renameFile : function (oldFilePath, newFilePath) {
// RENAME FILE OR FOLDER ON SERVER	
	var url 			= 	this.getFoldersUrl();
	var query 			= 	new Object;
	query.mode			=	"renameFile";
	query.sessionId		=	Agua.cookie('sessionId');
	query.username		=	Agua.cookie('username');
	query.oldpath		=	oldFilePath;
	query.newpath		=	newFilePath;
	
	this.doPut({ url: url, query: query, sync: false });
},
createFolder : function (folderPath) {
	// CREATE FOLDER ON SERVER	
	var url 		= 	this.getFoldersUrl();
	var query 		= 	new Object;
	query.mode		=	"newFolder";
	query.sessionId	=	Agua.cookie('sessionId');
	query.username	=	Agua.cookie('username');
	query.folderpath=	folderPath;
	
	this.doPut({ url: url, query: query, sync: false });
},
// FILEINFO METHODS
getFileInfo : function (stageParameterObject, fileinfo) {
// GET THE BOOLEAN fileInfo VALUE FOR A STAGE PARAMETER
	if ( fileinfo != null )
	{
		console.log("Agua.File.getFileInfo    fileinfo parameter is present. Should you be using setFileInfo instead?. Returning null.");
		return null;
	}
	
	return this._fileInfo(stageParameterObject, fileinfo);
},
setFileInfo : function (stageParameterObject, fileinfo) {
// SET THE BOOLEAN fileInfo VALUE FOR A STAGE PARAMETER
	if ( ! stageParameterObject	)	return;
	
	if ( fileinfo == null )
	{
		console.log("Agua.File.setFileInfo    fileinfo is null. Returning null.");
		return null;
	}

	return this._fileInfo(stageParameterObject, fileinfo);
},
_fileInfo : function (stageParameterObject, fileinfo) {
// RETURN THE fileInfo BOOLEAN FOR A STAGE PARAMETER
// OR SET IT IF A VALUE IS SUPPLIED: RETURN NULL IF
// UNSUCCESSFUL, TRUE OTHERWISE

	console.log("Agua.File._fileInfo    plugins.core.Data._fileInfo()");
	console.log("Agua.File._fileInfo    stageParameterObject: ");
	console.dir({stageParameterObject:stageParameterObject});
	console.log("Agua.File._fileInfo    fileinfo: ");
	console.dir({fileinfo:fileinfo});

	var uniqueKeys = ["username", "project", "workflow", "appname", "appnumber", "name", "paramtype"];
	var valueArray = new Array;
	for ( var i = 0; i < uniqueKeys.length; i++ ) {
		valueArray.push(stageParameterObject[uniqueKeys[i]]);
	}
	var stageParameter = this.getEntry(this.cloneData("stageparameters"), uniqueKeys, valueArray);
	console.log("Agua.File._fileInfo    stageParameter found: ");
	console.dir({stageParameter:stageParameter});
	if ( stageParameter == null ) {
		console.log("Agua.File._fileInfo    stageParameter is null. Returning null");
		return null;
	}

	// RETURN FOR GETTER	
	if ( fileinfo == null ) {
		console.log("Agua.File._fileInfo    DOING the GETTER. Returning stageParameter.exists: " + stageParameter.fileinfo.exists);
		return stageParameter.fileinfo.exists;
	}

	console.log("Agua.File._fileInfo    DOING the SETTER");

	// ELSE, DO THE SETTER
	stageParameter.fileinfo = fileinfo;
	var success = this._removeStageParameter(stageParameter);
	if ( success == false ) {
		console.log("Agua.File._fileInfo    Could not remove stage parameter. Returning null");
		return null;
	}
	console.log("Agua.File._fileInfo    	BEFORE success = this._addStageParameter(stageParameter)");
		
	success = this._addStageParameter(stageParameter);			
	if ( success == false ) {
		console.log("Agua.File._fileInfo    Could not add stage parameter. Returning null");
		return null;
	}

	return true;
},
// VALIDITY METHODS
getParameterValidity : function (stageParameterObject, booleanValue) {
// GET THE BOOLEAN parameterValidity VALUE FOR A STAGE PARAMETER
	//console.log("Agua.File.getParameterValidity    plugins.core.Data.getParameterValidity()");
	////console.log("Agua.File.getParameterValidity    stageParameterObject: " + dojo.toJson(stageParameterObject));
	////console.log("Agua.File.getParameterValidity    booleanValue: " + booleanValue);

	if ( booleanValue != null )
	{
		//console.log("Agua.File.getParameterValidity    booleanValue parameter is present. Should you be using "setParameterValidity" instead?. Returning null.");
		return null;
	}
	
	var isValid = this._parameterValidity(stageParameterObject, booleanValue);
	//console.log("Agua.File.getParameterValidity   '" + stageParameterObject.name + "' isValid: " + isValid);
	
	return isValid;
},
setParameterValidity : function (stageParameterObject, booleanValue) {
// SET THE BOOLEAN parameterValidity VALUE FOR A STAGE PARAMETER
	////console.log("Agua.File.setParameterValidity    plugins.core.Data.setParameterValidity()");
	////console.log("Agua.File.setParameterValidity    stageParameterObject: " + dojo.toJson(stageParameterObject));
	////console.log("Agua.File.setParameterValidity    " + stageParameterObject.name + " booleanValue: " + booleanValue);
	if ( booleanValue == null )
	{
		//console.log("Agua.File.setParameterValidity    booleanValue is null. Returning null.");
		return null;
	}

	var isValid = this._parameterValidity(stageParameterObject, booleanValue);
	//console.log("Agua.File.setParameterValidity   '" + stageParameterObject.name + "' isValid: " + isValid);

	return isValid;
},
_parameterValidity : function (stageParameterObject, booleanValue) {
// RETURN THE parameterValidity BOOLEAN FOR A STAGE PARAMETER
// OR SET IT IF A VALUE IS SUPPLIED
	////console.log("Agua.File._parameterValidity    plugins.core.Data._parameterValidity()");
	//console.log("Agua.File._parameterValidity    stageParameterObject: " + dojo.toJson(stageParameterObject, true));
	////console.log("Agua.File._parameterValidity    booleanValue: " + booleanValue);

	//////var filtered = this._getStageParameters();
	//////var keys = ["appname"];
	//////var values = ["image2eland.pl"];
	//////filtered = this.filterByKeyValues(filtered, keys, values);
	////////console.log("Agua.File._parameterValidity    filtered: " + dojo.toJson(filtered, true));
	var uniqueKeys = ["project", "workflow", "appname", "appnumber", "name", "paramtype"];
	var valueArray = new Array;
	for ( var i = 0; i < uniqueKeys.length; i++ )
	{
		valueArray.push(stageParameterObject[uniqueKeys[i]]);
	}
	var stageParameter = this.getEntry(this._getStageParameters(), uniqueKeys, valueArray);
	//console.log("Agua.File._parameterValidity    stageParameter found: " + dojo.toJson(stageParameter, true));
	if ( stageParameter == null )
	{
		//console.log("Agua.File._parameterValidity    stageParameter is null. Returning null");
		return null;
	}
	
	if ( booleanValue == null )
		return stageParameter.isValid;

	//console.log("Agua.File._parameterValidity    stageParameter: " + dojo.toJson(stageParameter, true));
	//console.log("Agua.File._parameterValidity    booleanValue: " + booleanValue);
	// SET isValid BOOLEAN VALUE
	stageParameter.isValid = booleanValue;		
	var success = this._removeStageParameter(stageParameter);
	if ( success == false )
	{
		//console.log("Agua.File._parameterValidity    Could not remove stage parameter. Returning null");
		return null;
	}
	////console.log("Agua.File._parameterValidity    	BEFORE success = this._addStageParameter(stageParameter)");
		
	success = this._addStageParameter(stageParameter);			
	if ( success == false )
	{
		//console.log("Agua.File._parameterValidity    Could not add stage parameter. Returning null");
		return null;
	}

	return true;
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Group"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Group"] = true;
dojo.provide("plugins.core.Agua.Group");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	GROUP METHODS  
*/

dojo.declare( "plugins.core.Agua.Group",	[  ], {

/////}}}

// GROUP METHODS
getGroups : function () {
// RETURN THE groups ARRAY FOR THIS USER
	console.log("Agua.Group.getGroups    plugins.core.Data.getGroups()");

	return this.cloneData("groups");
},
addGroup : function (groupObject) {
// ADD A GROUP OBJECT TO THE groups ARRAY

	console.log("Agua.Group.addGroup    plugins.core.Data.addGroup(groupObject)");
	console.log("Agua.Group.addGroup    groupObject: " + dojo.toJson(groupObject));
	
	this.removeData("groups", groupObject, ["groupname"]);
	if ( ! this.addData("groups", groupObject, [ "groupname" ]) )	return;
	this.sortData("groups", "groupname");

	// CLEAN UP WHITESPACE AND SUBSTITUTE NON-JSON SAFE CHARACTERS
	groupObject.groupname = this.jsonSafe(groupObject.groupname, "toJson");
	groupObject.description = this.jsonSafe(groupObject.description, "toJson");
	groupObject.notes = this.jsonSafe(groupObject.notes, "toJson");
	
	// CREATE JSON QUERY
	var url = Agua.cgiUrl + "sharing.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addGroup";
	query.data = groupObject;
	////console.log("Groups.addItem    query: " + dojo.toJson(query));
	
	this.doPut({ url: url, query: query });

	if ( Agua.isAccess(groupObject) )	return;
	
	// ADD TO access	
	var accessObject = new Object;
	accessObject.groupname = groupObject.groupname;
	accessObject.owner		=	this.cookie("username");
	accessObject.groupwrite	=	0;
	accessObject.groupcopy	=	1;
	accessObject.groupview	=	1;
	accessObject.worldwrite	=	0;
	accessObject.worldcopy	=	0;
	accessObject.worldview	=	0

	console.log("Agua.Group.addGroup    Adding accessObject: " + dojo.toJson(accessObject));
	this.addData("access", accessObject, ["groupname"]);	
	this.sortData("access", "groupname");
},
removeGroup : function (groupObject) {
// REMOVE A GROUP OBJECT FROM THE groups ARRAY
// AND RELATED: groupmembers, access

	console.log("Agua.Group.removeGroup    plugins.core.Data.removeGroup(groupObject)");
	console.log("Agua.Group.removeGroup    groupObject: " + dojo.toJson(groupObject));

	if ( ! this._removeGroup(groupObject) )	return;
	this.sortData("groups", "groupname");
	
	// REMOVE FROM access
	this._removeAccess(groupObject);

	// REMOVE FROM groupmembers 
	this._removeGroupMembers(groupObject);

	// CREATE JSON QUERY
	var url = Agua.cgiUrl + "sharing.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "removeGroup";
	query.data = groupObject;
	//console.log("Groups.deleteItem    query: " + dojo.toJson(query));
	
	this.doPut({ url: url, query: query, sync: false });	
},
_removeGroup : function ( groupObject) {
	return this.removeData("groups", groupObject, ["groupname"]);
},
_removeGroupMembers : function (groupObject) {
// REMOVE A GROUP OBJECT FROM groupmembers
	console.log("Agua.Group._removeGroupMembers    plugins.core.Data._removeGroupMembers(groupObject)");
	console.log("Agua.Group._removeGroupMembers    groupObject: " + dojo.toJson(groupObject));

	return this._removeObjectsFromData("groupmembers", groupObject, ["groupname"]);
},
_removeAccess : function (groupObject) {
	// REMOVE FROM access
	this.removeData("access", groupObject, ["groupname"]);		
},
isAccess : function (groupObject) {
	var access = this.cloneData(access);
	return this._objectInArray(access, groupObject, ["groupname"]);		
},
isGroup : function (groupObject) {
// RETURN true IF A GROUP EXISTS IN groups
	console.log("Agua.Group.isGroup    plugins.core.Data.isGroup(groupObject, groupObject)");
	console.log("Agua.Group.isGroup    groupObject: " + dojo.toJson(groupObject));
	var groups = this.getGroups();
	if ( this._getIndexInArray(groups, groupObject, ["groupname"]) )	return true;
	
	return false;
},
getGroupNames : function () {
// PARSE NAMES OF ALL GROUPS IN groups INTO AN ARRAY
	console.log("Agua.Group.getGroupNames    plugins.core.Data.getGroupNames()");
	var groups = this.getGroups();	
	var groupNames = new Array;
	var groups = this.getGroups();
	for ( var i in groups  )
	{
		groupNames.push(groups[i].groupname);
	}
	//console.log("Agua.Group.getGroupNames    groupNames: " +  dojo.toJson(groupNames));
	
	return groupNames;
},
getGroupMembers : function (memberType) {
// PARSE groups ENTRIES INTO HASH OF ARRAYS groupName: [ source1, source2 ]
	//console.log("Agua.Group.getGroupMembers    plugins.core.Data.getGroupMembers(memberType)");
	//console.log("Agua.Group.getGroupMembers    memberType: " + memberType);
	
	var groupMembers = this.cloneData("groupmembers");
	var keyArray = ["type"];
	var valueArray = [memberType];
	return this.filterByKeyValues(groupMembers, keyArray, valueArray);
},
getGroupMembersHash : function (memberType) {
// PARSE groups ENTRIES INTO HASH OF ARRAYS { groupName: [ source1, source2 ] }

	console.log("Agua.Group.getGroupMembersHash    plugins.core.Data.getGroupMembersHash(memberType)");
	console.log("Agua.Group.getGroupMembersHash    memberType" + memberType);
	
	var groupMembers = this.cloneData("groupmembers");
	for ( var groupName in groupMembers )
	{
		for ( var j = 0; j < groupMembers[groupName].length; j++ )
		{
			if ( groupMembers[groupName][j].type != memberType )
			{
				groupMembers[groupName].splice(j,1);
				j--;
			}
		} 
	}
	
	return groupMembers;
},
getGroupSources : function () {
// GET ALL SOURCE MEMBERS OF groupmembers

	//console.log("Agua.Group.getGroupUsers    plugins.core.Data.getGroupUsers()");
	return this.getGroupMembers("source");
},
getGroupUsers : function () {
// GET ALL USER MEMBERS OF groupmembers
	//console.log("Agua.Group.getGroupUsers    plugins.core.Data.getGroupUsers()");
	return this.getGroupMembers("user");
},
getGroupProjects : function () {
// GET ALL PROJECT MEMBERS OF groupmembers

	//console.log("Agua.Group.getGroupProjects    plugins.core.Data.getGroupProjects()");
	return this.getGroupMembers("project");
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Hub"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Hub"] = true;
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
	if ( hub.amazonuserid == null ) {
		console.log("Agua.Hub.setHub    hub.amazonuserid is null. Returning");
		return;
	}
	this.setData("hub", hub);
	
	return hub;
}


});

}

if(!dojo._hasResource["plugins.core.Agua.Package"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Package"] = true;
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
	//console.log("Agua.Package.addPackage    packageObject: " + dojo.toJson(packageObject));

	var packages = this.getData("packages");
	//console.log("Agua.Package.removePackage    packages.length: " + packages.length);
	//console.log("Agua.Package.removePackage    packages: " + dojo.toJson(packages, true));

	var result = this.addData("packages", packageObject, ["package", "owner", "installdir"]);
	if ( result == true ) this.sortData("packages", "package");


	packages = this.getData("packages");
	//console.log("Agua.Package.removePackage    packages.length: " + packages.length);
	//console.log("Agua.Package.removePackage    packages: " + dojo.toJson(packages, true));
	
	// RETURN TRUE OR FALSE
	return result;
},
removePackage : function (packageObject) {
// REMOVE AN PACKAGE OBJECT FROM packages
	//console.log("Agua.Package.removePackage    packageObject: " + dojo.toJson(packageObject));
	var packages = this.getData("packages");
	//console.log("Agua.Package.removePackage    packages: " + dojo.toJson(packages, true));
	//console.log("Agua.Package.removePackage    packages.length: " + packages.length);
	var result = this.removeData("packages", packageObject, ["package", "owner", "installdir"]);
	
	packages = this.getData("packages");
	//console.log("Agua.Package.removePackage    packages.length: " + packages.length);
	
	return result;
},
isPackage : function (packageName) {
// RETURN true IF AN PACKAGE EXISTS IN packages
	console.log("Agua.Package.isPackage    packageName: *" + packageName + "*");
	
	var packages = this.getPackages();
	for ( var i in packages )
	{
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

}

if(!dojo._hasResource["plugins.core.Agua.Parameter"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Parameter"] = true;
dojo.provide("plugins.core.Agua.Parameter");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	PARAMETER METHODS  
*/

dojo.declare( "plugins.core.Agua.Parameter",	[  ], {

/////}}}

// PARAMETER METHODS
addParameter : function (parameterObject) {
// ADD A PARAMETER OBJECT TO THE parameters ARRAY

	console.log("Agua.Parameter.addParameter    plugins.core.Data.addParameter(parameterObject)");
	//console.log("Agua.Parameter.addParameter    parameterObject: " + dojo.toJson(parameterObject));

	// REMOVE THE PARAMETER OBJECT IF IT EXISTS ALREADY
	var result = this.removeData("parameters", parameterObject, ["appname", "name", "paramtype"]);

	// DO THE ADD
	var requiredKeys = [ "appname", "name", "paramtype" ];
	return result = this.addData("parameters", parameterObject, requiredKeys);
},
removeParameter : function (parameterObject) {
// REMOVE AN PARAMETER OBJECT FROM THE parameters ARRAY.
// RETURN TRUE OR FALSE.
	console.log("Agua.Parameter.removeParameter    plugins.core.Data.removeParameter(parameterObject)");
	console.log("Agua.Parameter.removeParameter    parameterObject: " + dojo.toJson(parameterObject));

	if ( ! this._removeParameter(parameterObject) ) 	return false;

	// PUT JSON QUERY
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "deleteParameter";
	query.data = parameterObject;
	//console.log("Parameter.deleteItem    query: " + dojo.toJson(query));
	this.doPut({ url: url, query: query });

	return true;
},
_removeParameter : function (parameterObject) {
	return this.removeData("parameters", parameterObject, ["appname", "name", "paramtype"]);
},
isParameter : function (appName, parameterName) {
// RETURN true IF AN PARAMETER EXISTS IN parameters

	console.log("Agua.Parameter.isParameter    plugins.core.Data.isParameter(parameterName, parameterObject)");
	console.log("Agua.Parameter.isParameter    parameterName: *" + parameterName + "*");
	
	var parameters = getParametersByAppname(appName);
	if ( parameters == null )	return false;

	for ( var i in parameters )
	{
		if ( parameters[i].name.toLowerCase() == parameterName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
},
getParametersByAppname : function (appname) {
// RETURN AN ARRAY OF PARAMETERS FOR THE GIVEN APPLICATION
	//console.log("Agua.Parameter.getParametersByAppname    core.Agua.getParametersByAppname(appname)");
	//console.log("Agua.Parameter.getParametersByAppname    appname: " + appname);
	if ( appname == null )	return null;	
	var parameters = new Array;
	var params = this.cloneData("parameters");
	for ( var i = 0; i < params.length; i++ )
	{
		var parameter = params[i];
		//console.log("Agua.Parameter.getParametersByAppname    parameter " + parameter.name + ": " + parameter.value);
		if ( parameter.appname == appname ){
			//console.log("Agua.Parameter.getParametersByAppname    PUSHING parameter " + parameter.name + ": " + dojo.toJson(parameter));

			parameters.push(parameter);
		}
	}
	//console.log("Agua.Parameter.getParametersByAppname    Returning parameters : " + dojo.toJson(parameters));
	
	return parameters;
},
getParameter : function (appName, parameterName) {
// RETURN A NAMED PARAMETER FOR A GIVEN APPLICATION
// E.G., WHEN RETURNING VALUE TO DEFAULT

	//console.log("Agua.Parameter.getParameter    plugins.core.Data.getParameter(appName)");
	//console.log("Agua.Parameter.getParameter    appName: " + appName);
	//console.log("Agua.Parameter.getParameter    parameterName: " + parameterName);

	if ( appName == null )	return null;
	if ( parameterName == null )	return null;
	
	var parameters = getParametersByAppname(appName);
	if ( parameters == null )	return false;

	for ( var i in parameters )
	{
		if ( parameters[i].name.toLowerCase() == parameterName.toLowerCase() )
		{
			return parameters[i];
		}
	}
	
	return null;
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Project"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Project"] = true;
dojo.provide("plugins.core.Agua.Project");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	PROJECT METHODS  
*/

dojo.declare( "plugins.core.Agua.Project",	[  ], {

/////}}}

// PROJECT METHODS
getProjects : function () {
// RETURN A SORTED COPY OF 
	//console.log("Agua.Project.getProjects    plugins.core.Data.getProjects(projectObject)");
	var projects = this.cloneData("projects");
	return this.sortHasharray(projects, "name");
},
getProjectNames : function (projects) {
// RETURN AN ARRAY OF ALL PROJECT NAMES IN projects
	console.log("Agua.Project.getProjectNames    plugins.core.Data.getProjectNames()");
	if ( projects == null )	projects = this.getProjects();
	return this.hashArrayKeyToArray(projects, "name");
},
addProject : function (projectObject) {
// ADD A PROJECT OBJECT TO THE projects ARRAY

	console.log("Agua.Project.addProject    plugins.core.Data.addProject(projectName)");
	console.log("Agua.Project.addProject    projectObject: " + dojo.toJson(projectObject));
	projectObject.description = projectObject.description || "";
	projectObject.notes = projectObject.notes || "";

	console.log("Agua.Project.addProject    this.addingProject: " + this.addingProject);
	if ( this.addingProject == true )	return;
	this.addingProject == true;
	
	this.removeData("projects", projectObject, ["name"]);
	
	if ( ! this.addData("projects", projectObject, ["name" ]) )
	{
		console.log("Agua.Project.addProject    Could not add project to projects: " + projectName);
		this.addingProject == false;
		return;
	}
	this.sortData("projects", "name");
	this.addingProject == false;
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	
	// SET QUERY
	var query = dojo.clone(projectObject);
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addProject";
	console.log("Agua.Project.addProject    query: " + dojo.toJson(query, true));
	
	this.doPut({ url: url, query: query, sync: false });
},
copyProject : function (sourceUser, sourceProject, targetUser, targetProject, copyFiles) {
// ADD AN EMPTY NEW WORKFLOW OBJECT TO A PROJECT OBJECT

	console.log("Agua.Project.copyProject    plugins.folders.Agua.copyProject(sourceUser, sourceProject, sourceProject, targetUser, targetProject, targetProject)");
	console.log("Agua.Project.copyProject    sourceUser: " + sourceUser);
	console.log("Agua.Project.copyProject    sourceProject: " + sourceProject);
	console.log("Agua.Project.copyProject    targetUser: " + targetUser);
	console.log("Agua.Project.copyProject    targetProject: " + targetProject);
	console.log("Agua.Project.copyProject    copyFiles: " + copyFiles);

	if ( this.isProject(targetProject) == true )
	{
		console.log("Agua.Project.copyProject    Project '" + targetProject + "' already exists. Returning.");
		return;
	}

	// GET PROJECT
	var projects = this.getSharedProjectsByUsername(sourceUser);
	console.log("Agua.Project.copyProject    projects: " + dojo.toJson(projects));
	projects = this.filterByKeyValues(projects, ["project"], [sourceProject]);
	if ( ! projects || projects.length == 0 ) {
		console.log("Agua.Project.copyProject    Returning becacuse  projects is null or empty: " + dojo.toJson(projects));
	}
	var projectObject = projects[0];
	
	// SET PROVENANCE
	var date = this.currentMysqlDate();
	projectObject = this.setProvenance(projectObject, date);
	
	// SET TARGET VARIABLES
	projectObject.name = targetProject;
	projectObject.project  = targetProject;
	projectObject.username = targetUser;
	console.dir({projectObject:projectObject});
	var keys = ["name"];
	var copied = this.addData("projects", projectObject, keys);
	if ( copied == false )
	{
		console.log("Agua.Project.copyProject    Could not copy project " + projectObject.name + " to projects");
		return;
	}
	
	// COPY WORKFLOWS
	var workflows = this.getSharedWorkflowsByProject(sourceUser, sourceProject);
	for ( var i = 0; i < workflows.length; i++ ) {
		var sourceWorkflow = workflows[i].name;
		console.log("Agua.Project.copyProject    workflows[" + i + "]: " + dojo.toJson(workflows[i]));
		this._copyWorkflow(workflows[i], targetUser, targetProject, sourceWorkflow, date);
	}

	// COMMIT CHANGES TO REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = new Object;
	query.sourceuser 	= sourceUser;
	query.targetuser 	= targetUser;
	query.sourceproject = sourceProject;
	query.targetproject = targetProject;
	query.copyfiles 	= copyFiles;
	query.date			= date;
	query.provenance 	= projectObject.provenance;
	query.username 		= this.cookie("username");
	query.sessionId 	= this.cookie("sessionId");
	query.mode 			= "copyProject";
	console.log("Agua.Project.copyProject    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });
},
removeProject : function (projectObject) {
// REMOVE A PROJECT OBJECT FROM: projects, workflows, groupmembers
// stages AND stageparameters
	console.log("Agua.Project.removeProject    plugins.core.Data.removeProject(projectObject)");
	console.log("Agua.Project.removeProject    projectObject: " + dojo.toJson(projectObject));
	
	// SET ADDITIONAL FIELDS
	projectObject.project = projectObject.name;
	projectObject.owner = this.cookie("username");
	projectObject.type = "project";

	// REMOVE PROJECT FROM projects
	var success = this.removeData("projects", projectObject, ["name"]);
	if ( success == true )	console.log("Agua.Project.removeProject    Removed project from projects: " + projectObject.name);
	else	console.log("Agua.Project.removeProject    Could not remove project from projects: " + projectObject.name);
	
	// REMOVE FROM workflows
	this.removeData("workflows", projectObject, ["project"]);

	// REMOVE FROM groupmembers 
	var keys = ["owner", "name", "type"];
	this.removeData("groupmembers", projectObject, keys);

	// REMOVE FROM stages AND stageparameters
	var keys = ["project"];
	this.removeData("stages", projectObject, keys);

	// REMOVE FROM stageparameters
	var keys = ["project"];
	this.removeData("stageparameters", projectObject, keys);
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = projectObject;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "removeProject";
	console.log("Agua.Project.removeProject    query: " + dojo.toJson(query, true));
	
	this.doPut({ url: url, query: query, sync: false });
},
isProject : function (projectName) {
// RETURN true IF A PROJECT EXISTS IN projects
	//console.log("Agua.Project.isProject    core.Data.isProject(projectName)");
	//console.log("Agua.Project.isProject    projectName: " + projectName);

	var projects = this.getProjects();
	for ( var i in projects )
	{
		var project = projects[i];
		if ( project.name.toLowerCase() == projectName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
},
isGroupProject : function (groupName, projectObject) {
// RETURN true IF A PROJECT BELONGS TO THE SPECIFIED GROUP

	console.log("Agua.Project.isGroupProject    plugins.core.Data.isGroupProject(groupName, projectObject)");
	console.log("Agua.Project.isGroupProject    groupName: " + groupName);
	console.log("Agua.Project.isGroupProject    projectObject: " + dojo.toJson(projectObject));
	
	var groupProjects = this.getGroupProjects();
	if ( groupProjects == null )	return false;
	
	groupProjects = this.filterByKeyValues(groupProjects, ["groupname"], [groupName]);
	
	return this._objectInArray(groupProjects, projectObject, ["groupname", "name"]);
},
addProjectToGroup : function (groupName, projectObject) {
// ADD A PROJECT OBJECT TO A GROUP ARRAY IF IT DOESN"T EXIST THERE ALREADY 

	console.log("Agua.Project.addProjectToGroup    caller: " + this.addProjectToGroup.caller.nom);
	console.log("Agua.Project.addProjectToGroup    groupName: " + groupName);
	console.log("Agua.Project.addProjectToGroup    projectObject: " + dojo.toJson(projectObject));

	if ( this.isGroupProject(groupName, projectObject) == true )
	{
		console.log("Agua.Project.addProjectToGroup     project already exists in projects: " + projectObject.name + ". Returning.");
		return false;
	}
	
	projectObject.owner = projectObject.username;
	projectObject.groupname = groupName;
	projectObject.type = "project";

	var groups = this.getGroups();
	console.log("Agua.Project.addProjectToGroup    groups: " + dojo.toJson(groups));
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	if ( group == null )	return false;
	console.log("Agua.Project.addProjectToGroup    group: " + dojo.toJson(group));
	projectObject.groupdesc = group.description;

	console.log("Agua.Project.addProjectToGroup    New projectObject: " + dojo.toJson(projectObject));

	var requiredKeys = ["owner", "groupname", "name", "type"];
	return this.addData("groupmembers", projectObject, requiredKeys);
},
removeProjectFromGroup : function (groupName, projectObject) {
// REMOVE A PROJECT OBJECT FROM A GROUP ARRAY, IDENTIFY OBJECT BY "name" KEY VALUE

	console.log("Agua.Project.removeProjectFromGroup     caller: " + this.removeProjectFromGroup.caller.nom);
	console.log("Agua.Project.removeProjectFromGroup     groupName: " + groupName);
	console.log("Agua.Project.removeProjectFromGroup     projectObject: " + dojo.toJson(projectObject));
	
	projectObject.owner = projectObject.username;
	projectObject.groupname = groupName;
	projectObject.type = "project";

	// REMOVE THIS LATER		
	var groups = this.getGroups();
	console.log("Agua.Project.removeProjectFromGroup    groups: " + dojo.toJson(groups));
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	if ( group == null )	return false;
	console.log("Agua.Project.removeProjectFromGroup    group: " + dojo.toJson(group));
	projectObject.groupdesc = group.description;

	var requiredKeys = [ "owner", "groupname", "name", "type"];
	return this.removeData("groupmembers", projectObject, requiredKeys);
},
getProjectsByGroup : function (groupName) {
// RETURN THE ARRAY OF PROJECTS THAT BELONG TO A GROUP

	var groupProjects = this.getGroupProjects();
	if ( groupProjects == null )	return null;

	var keyArray = ["groupname"];
	var valueArray = [groupName];
	var projects = this.filterByKeyValues(groupProjects, keyArray, valueArray);

	return this.sortHasharray(projects, "name");
},
getGroupsByProject : function (projectName) {
// RETURN THE ARRAY OF PROJECTS THAT BELONG TO A GROUP

	var groupProjects = this.getGroupProjects();
	if ( groupProjects == null )	return null;

	var keyArray = ["type", "name"];
	var valueArray = ["project", projectName];
	return this.filterByKeyValues(groupProjects, keyArray, valueArray);
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Report"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Report"] = true;
dojo.provide("plugins.core.Agua.Report");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	REPORT METHODS  
*/

dojo.declare( "plugins.core.Agua.Report",	[  ], {

/////}}}

getReports : function () {
// RETURN A COPY OF THE this.reports ARRAY

	console.log("Agua.Report.getReports    plugins.core.Data.getReports()");

	var stages = this.getStages();
	if ( stages == null )	return;
	//console.log("Agua.Report.getReports    stages: " + dojo.toJson(stages, true));

	var keys = [ "type" ];
	var values = [ "report" ];
	var reports = this.filterByKeyValues(stages, keys, values);
	//console.log("Agua.Report.getReports    reports: " + dojo.toJson(reports, true));

	return reports;
},
getReportsByWorkflow : function (projectName, workflowName) {
// RETURN AN ARRAY OF REPORT HASHES FOR THE SPECIFIED PROJECT AND WORKFLOW

	var reports = this.getReports();
	if ( reports == null )	return null;

	var keyArray = ["project", "workflow"];
	var valueArray = [projectName, workflowName];
	return this.filterByKeyValues(reports, keyArray, valueArray);
},
removeReport : function (reportObject) {
// REMOVE A REPORT OBJECT FROM THE this.reports ARRAY

	console.log("Agua.Report.removeReport    plugins.core.Data.removeReport(reportObject)");
	console.log("Agua.Report.removeReport    reportObject: " + dojo.toJson(reportObject));

	// REMOVE REPORT FROM this.reports
	var requiredKeys = ["project", "workflow", "name"];
	var success = this.removeData("reports", reportObject, requiredKeys);
	if ( success == true )	console.log("Agua.Report.removeReport    Removed report from this.reports: " + reportObject.name);
	else	console.log("Agua.Report.removeReport    Could not remove report from this.reports: " + reportObject.name);
	
	// REMOVE REPORT FROM groupmembers IF PRESENT
	var groupNames = this.getGroupsByReport(reportObject.name);
	console.log("Agua.Report.removeReport    groupNames: " + dojo.toJson(groupNames));
	for ( var i = 0; i < groupNames.length; i++ )
	{
		if ( this.removeReportFromGroup(groupNames[i], reportObject) == false )
			success = false;
	}

	return success;
},
isReport : function (reportName) {
// RETURN true IF A REPORT EXISTS IN this.reports
	console.log("Agua.Report.isReport    plugins.core.Data.isReport(reportName)");
	console.log("Agua.Report.isReport    reportName: *" + reportName + "*");
	//console.log("Agua.Report.isReport    this.reports: " + dojo.toJson(this.reports));

	var reports = this.getReports();	
	for ( var i in reports )
	{
		var report = reports[i];
		if ( report.name.toLowerCase() == reportName.toLowerCase() )
		{
			console.log("Agua.Report.isReport    report.name is a report: *" + report.name + "*");
			return true;
		}
	}
	
	return false;
},
addReport : function (reportObject) {
// ADD A REPORT 
	console.log("Agua.Report.addReport+     plugins.core.Data.addReport(projectName)");
	console.log("Agua.Report.addReport    reportObject: " + dojo.toJson(reportObject));

	// DO THE ADD
	var requiredKeys = ["project", "workflow", "name"];
	var success = this.addData("reports", reportObject, requiredKeys);
	
	if ( success == true ) console.log("Agua.Report.addReport    Added report to this.reports[" + reportObject.name);
	else console.log("Agua.Report.addReport    Could not add report to this.reports[" + reportObject.name);
	return success;
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Shared"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Shared"] = true;
dojo.provide("plugins.core.Agua.Shared");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	SHARED METHODS  
*/

dojo.declare( "plugins.core.Agua.Shared",	[  ], {

/////}}}

getSharedSources : function () {
// RETURN A COPY OF sharedsources
	//console.log("Agua.Shared.getSharedSources    plugins.core.Data.getSharedSources()");
	return this.cloneData("sharedsources");
},
getSharedSourcesByUsername : function(username) {
/// RETURN ALL SHARED PROJECTS PROVIDED BY THE SPECIFIED USER
	//console.log("Agua.Shared.getSharedSourcesByUsername    username: " + username);
	
	var sharedSources = this.cloneData("sharedsources");
	//console.log("Agua.Shared.getSharedSourcesByUsername    BEFORE sharedSources: " + dojo.toJson(sharedSources));

	if ( ! sharedSources || ! sharedSources[username] )	return [];
	else return sharedSources[username];
},
getSharedUsernames : function() {
// RETURN AN ARRAY OF ALL OF THE NAMES OF USERS WHO HAVE SHARED PROJECTS
// WITH THE LOGGED ON USER
	console.log("Agua.Shared.getSharedUsernames    plugins.core.Data.getSharedUsernames()");

	var sharedProjects = this.getSharedProjects();	
	var usernames = new Array;
	for ( var name in sharedProjects ) {
		usernames.push(name);
	}
	usernames = usernames.sort();
	console.log("Agua.Shared.getSharedUsernames    usernames: " + dojo.toJson(usernames));

	return usernames;
},
getSharedProjects : function() {
	console.log("Agua.Shared.getSharedProjects    plugins.core.Data.getSharedProjects()");	
	var sharedProjects = this.cloneData("sharedprojects");
	console.log("Agua.Shared.getSharedProjects    sharedProjects: ");
	console.dir({sharedProjects:sharedProjects});

	return sharedProjects;
},
getSharedProjectsByUsername : function(username) {
/// RETURN ALL SHARED PROJECTS PROVIDED BY THE SPECIFIED USER
	//console.log("Agua.Shared.getSharedProjectsByUsername    username: " + username);
	
	var sharedProjects = this.cloneData("sharedprojects");
	//console.log("Agua.Shared.getSharedProjectsByUsername    BEFORE sharedProjects: " + dojo.toJson(sharedProjects));

	if ( ! sharedProjects || ! sharedProjects[username] )	return [];
	else return sharedProjects[username];
},
getSharedStagesByUsername : function(username) {
// RETURN AN ARRAY OF STAGES SHARED BY THE USER
	var sharedStages = this.cloneData("sharedstages");
	if ( sharedStages == null || sharedStages[username] == null )	return [];
	else return sharedStages[username];
},
getSharedWorkflowsByProject : function(username, project) {
// RETURN AN ARRAY OF ALL OF THE NAMES OF USERS WHO HAVE SHARED PROJECTS
// WITH THE LOGGED ON USER

	console.log("Agua.Shared.getSharedWorkflowsByProject    plugins.core.Data.getSharedWorkflowsByProject(username, project)");		
	console.log("Agua.Shared.getSharedWorkflowsByProject    username: " + username);
	console.log("Agua.Shared.getSharedWorkflowsByProject    project: " + project);

	var sharedWorkflows = this.cloneData("sharedworkflows") || [];
	sharedWorkflows = sharedWorkflows[username] || [];
	console.dir({sharedWorkflows:sharedWorkflows});
	sharedWorkflows = this.filterByKeyValues(sharedWorkflows, ["project"], [project]);
	console.log("Agua.Shared.getSharedWorkflowsByProject    sharedWorkflows: ");
	console.dir({sharedWorkflows:sharedWorkflows});

	return sharedWorkflows;
},
getSharedStagesByWorkflow : function(username, project, workflow) {
// RETURN AN ARRAY OF ALL OF THE NAMES OF USERS WHO HAVE SHARED PROJECTS
// WITH THE LOGGED ON USER

	console.log("Agua.Shared.getSharedStagesByWorkflow    plugins.core.Data.getSharedStagesByWorkflow(username, project, workflow)");		
	console.log("Agua.Shared.getSharedStagesByWorkflow    username: " + username);
	console.log("Agua.Shared.getSharedStagesByWorkflow    project: " + project);
	console.log("Agua.Shared.getSharedStagesByWorkflow    workflow: " + workflow);
	
	var sharedStages = this.getSharedStagesByUsername(username);
	console.log("Agua.Shared.getSharedStagesByWorkflow    BEFORE FILTER PROJECT, sharedStages: ");
	console.dir({sharedStages:sharedStages});
	sharedStages = this.filterByKeyValues(sharedStages, ["project"], [project]);

	console.log("Agua.Shared.getSharedStagesByWorkflow    BEFORE FILTER WORKFLOW, sharedStages: ");
	console.dir({sharedStages:sharedStages});

	sharedStages = this.filterByKeyValues(sharedStages, ["workflow"], [workflow]);
	console.log("Agua.Shared.getSharedStagesByWorkflow    AFTER sharedStages: ");
	console.dir({sharedStages:sharedStages});

	return sharedStages;
},
getSharedParametersByAppname : function (appname, owner) {
// RETURN AN ARRAY OF PARAMETERS FOR THE GIVEN APPLICATION
// OWNED BY ANOTHER USER
	//console.log("Agua.Shared.getSharedParametersByAppname    plugins.core.Data.getSharedParametersByAppname(appname,)");
	//console.log("Agua.Shared.getSharedParametersByAppname    owner: " + owner);
	//console.log("Agua.Shared.getSharedParametersByAppname    appname: " + appname);
	if ( appname == null )	return null;	
	var params = this.cloneData("sharedparameters");
	////console.log("Agua.Shared.getSharedParametersByAppname    params : " + dojo.toJson(params));
	var keys = [ "owner", "appname" ];
	var values = [ owner, appname ];
	var parameters = this.filterByKeyValues(params, keys, values);
	////console.log("Agua.Shared.getSharedParametersByAppname    Returning parameters : " + dojo.toJson(parameters));
	
	return parameters;
},
getSharedStageParameters : function (stageObject) {
// RETURN AN ARRAY OF STAGE PARAMETER HASHARRAYS FOR A STAGE
	//console.log("Agua.Shared.getSharedStageParameters    plugins.core.Data.getSharedStageParameters(stageObject)");
	//console.log("Agua.Shared.getSharedStageParameters    stageObject: " + dojo.toJson(stageObject));
	
	var keys = ["username", "project", "workflow", "name", "number"];
	var notDefined = this.notDefined (stageObject, keys);
	console.log("Agua.Shared.getSharedStageParameters    notDefined: " + dojo.toJson(notDefined));
	if ( notDefined.length != 0 )
	{
		console.log("Agua.Shared.getSharedStageParameters    not defined: " + dojo.toJson(notDefined));
		return;
	}
	var username = stageObject.username;
	var sharedStageParameters = this.cloneData("sharedstageparameters");
	if ( sharedStageParameters == null || sharedStageParameters[username] == null )	return [];
	var stageParameters = sharedStageParameters[username];
	//console.log("Agua.Shared.getSharedStageParameters    BEFORE stageParameters: " + dojo.toJson(stageParameters, true));
	
	// ADD appname AND appnumber FOR STAGE PARAMETER IDENTIFICATION
	stageObject.appname = stageObject.name;
	stageObject.appnumber = stageObject.number;
	
	var keyArray = ["username", "project", "workflow", "appname", "appnumber"];
	var valueArray = [stageObject.username, stageObject.project, stageObject.workflow, stageObject.name, stageObject.number];
	stageParameters = this.filterByKeyValues(stageParameters, keyArray, valueArray);
	
	//console.log("Agua.Shared.getSharedStageParameters    AFTER  stageParameters: " + dojo.toJson(stageParameters));

	return stageParameters;
},
getSharedViews : function (viewObject) {
// RETURN AN ARRAY OF VIEWS IN THE SHARED PROJECT
	console.log("Agua.Shared.getSharedViews    plugins.core.Data.getSharedViews(viewObject)");
	console.log("Agua.Shared.getSharedViews    viewObject: " + dojo.toJson(viewObject));
	
	var keys = ["project", "username"];
	var notDefined = this.notDefined (viewObject, keys);
	console.log("Agua.Shared.getSharedViews    notDefined: " + dojo.toJson(notDefined));
	if ( notDefined.length != 0 )
	{
		console.log("Agua.Shared.getSharedViews    not defined: " + dojo.toJson(notDefined));
		return;
	}

	var username = viewObject.username;
	var sharedViews = this.cloneData("sharedsharedViews");
	if ( sharedViews == null || sharedViews[username] == null )	return [];
	var views = sharedViews[username];
	console.log("Agua.Shared.getSharedViews    BEFORE views: " + dojo.toJson(views, true));	
	
	var keyArray = ["project", "username"];
	var valueArray = [viewObject.username, viewObject.project, viewObject.workflow, viewObject.name, viewObject.number];
	views = this.filterByKeyValues(views, keyArray, valueArray);
	
	console.log("Agua.Shared.getSharedViews    AFTER  views: " + dojo.toJson(views));

	return views;
},
getSharedApps : function () {
	//console.log("Agua.Shared.getSharedApps    plugins.core.Data.getSharedApps()");
	return this.cloneData("sharedapps");
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Sharing"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Sharing"] = true;
dojo.provide("plugins.core.Agua.Sharing");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	ADMIN METHODS  
*/

dojo.declare( "plugins.core.Agua.Sharing",	[  ], {

///////}}}

// ADMIN METHODS
getSharingHeadings : function () {
	console.log("Agua.Sharing.getSharingHeadings    plugins.core.Data.getSharingHeadings()");
	var headings = this.cloneData("sharingheadings");
	console.log("Agua.Sharing.getSharingHeadings    headings: " + dojo.toJson(headings));
	return headings;
},
getAccess : function () {
	//console.log("Agua.Sharing.getAccess    plugins.core.Data.getAccess()");
	return this.cloneData("access");
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Source"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Source"] = true;
dojo.provide("plugins.core.Agua.Source");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	SOURCE METHODS  
*/

dojo.declare( "plugins.core.Agua.Source",	[  ], {

/////}}}

getSources : function () {
// RETURN A SORTED COPY OF sources
	//console.log("Agua.Source.getSources    plugins.core.Data.getSources()");

	var sources = this.cloneData("sources");
	return this.sortHasharray(sources, "name");
},
isSource : function (sourceObject) {
// RETURN TRUE IF SOURCE NAME ALREADY EXISTS

	console.log("Agua.Source.isSource    plugins.core.Data.isSource(sourceObject)");
	console.log("Agua.Source.isSource    sourceObject: " + dojo.toJson(sourceObject));
	
	var sources = this.getSources();
	if ( sources == null )	return false;
	
	return this._objectInArray(sources, sourceObject, ["name"]);
},
addSource : function (sourceObject) {
// ADD A SOURCE OBJECT TO THE sources ARRAY
	console.log("Agua.Source.addSource    plugins.core.Data.addSource(sourceObject)");
	console.log("Agua.Source.addSource    sourceObject: " + dojo.toJson(sourceObject));	

	this._removeSource(sourceObject);
	if ( ! this._addSource(sourceObject) )	return false;
	
	var url = Agua.cgiUrl + "sharing.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addSource";
	query.data = sourceObject;
	////console.log("Sources.addItem    query: " + dojo.toJson(query));
	this.doPut({ url: url, query: query, sync: false });
},
_addSource : function (sourceObject) {
// ADD A SOURCE OBJECT TO THE sources ARRAY
	console.log("Agua.Source._addSource    plugins.core.Data._addSource(sourceObject)");
	console.log("Agua.Source._addSource    sourceObject: " + dojo.toJson(sourceObject));
	return this.addData("sources", sourceObject, [ "name", "description", "location" ]);
},
removeSource : function (sourceObject) {
// REMOVE A SOURCE OBJECT FROM sources AND groupmembers
	//console.log("Agua.Source.removeSource    plugins.core.Data.removeSource(sourceObject)");
	//console.log("Agua.Source.removeSource    sourceObject: " + dojo.toJson(sourceObject));	
	if ( ! this._removeSource(sourceObject) )
	{
		console.log("Agua.Source.removeSource    FAILED TO REMOVE sourceObject: " + dojo.toJson(sourceObject));
		return false;
	}

	// REMOVE FROM GROUPMEMBER
	sourceObject.username = this.cookie("username");
	sourceObject.type = "source";
	var requiredKeys = [ "username", "name", "type"];
	this.removeData("groupmembers", sourceObject, requiredKeys);

	// SEND TO SERVER
	var url = Agua.cgiUrl + "sharing.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "removeSource";
	query.data = sourceObject;
	
	////console.log("Sources.deleteItem    sourceObject: " + dojo.toJson(sourceObject));
	this.doPut({ url: url, query: query, sync: false });
},
_removeSource : function (sourceObject) {
// _remove A SOURCE OBJECT FROM sources AND groupmembers
	//console.log("Agua.Source._removeSource    plugins.core.Data._removeSource(sourceObject)");
	//console.log("Agua.Source._removeSource    sourceObject: " + dojo.toJson(sourceObject));
	return this.removeData("sources", sourceObject, ["name"]);
},
isGroupSource : function (groupName, sourceObject) {
// RETURN true IF A SOURCE ALREADY BELONGS TO A GROUP
	console.log("Agua.Source.isGroupSource    plugins.core.Data.isGroupSource(groupName, sourceObject)");
	//console.log("Agua.Source.isGroupSource    groupName: " + groupName);
	//console.log("Agua.Source.isGroupSource    sourceObject: " + dojo.toJson(sourceObject));
	
	var groupSources = this.getGroupSources();
	if ( groupSources == null )	return false;

	groupSources = this.filterByKeyValues(groupSources, ["groupname"], [groupName]);
	
	return this._objectInArray(groupSources, sourceObject, ["name"]);
},
addSourceToGroup : function (groupName, sourceObject) {
// ADD A SOURCE OBJECT TO A GROUP ARRAY IF IT DOESN"T EXIST THERE ALREADY 
	console.log("Agua.Source.addSourceToGroup     plugins.core.Data.addSourceToGroup");

	if ( this.isGroupSource(groupName, sourceObject) == true )
	{
		console.log("Agua.Source.addSourceToGroup     source already exists in sources: " + sourceObject.name + ". Returning.");
		return false;
	}

	var groups = this.getGroups();
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	if ( group == null )	return null;
	
	sourceObject.username = group.username;
	sourceObject.groupname = groupName;
	sourceObject.groupdesc = group.description;
	sourceObject.type = "source";

	var requiredKeys = [ "username", "groupname", "name", "type"];
	return this.addData("groupmembers", sourceObject, requiredKeys);
},
removeSourceFromGroup : function (groupName, sourceObject) {
// REMOVE A SOURCE OBJECT FROM A GROUP ARRAY, IDENTIFY OBJECT BY "name" KEY VALUE
	console.log("Agua.Source.removeSourceFromGroup     groupName: " + groupName);
	console.log("Agua.Source.removeSourceFromGroup     sourceObject: ");
	console.dir({sourceObject:sourceObject});

	var groups = this.getGroups();
	console.log("Agua.Source.removeSourceFromGroup     groups: ");
	console.dir({groups:groups});
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	console.log("Agua.Source.removeSourceFromGroup     group: ");
	console.dir({group:group});

	if ( group == null )	{
		console.log("Agua.Source.removeSourceFromGroup     group is null. Returning.");
		return null;
	}
	
	sourceObject.owner 		= group.username;
	sourceObject.groupname 	= groupName;
	sourceObject.groupdesc	= group.description;
	sourceObject.type 		= "source";
	console.log("Agua.Source.removeSourceFromGroup     BEFORE removeData, sourceObject: ");
	console.dir({sourceObject:sourceObject});

	var requiredKeys = [ "username", "groupname", "name", "type"];
	return this.removeData("groupmembers", sourceObject, requiredKeys);
},
getSourcesByGroup : function (groupName) {
// RETURN THE ARRAY OF SOURCES THAT BELONG TO A GROUP

	var groupSources = this.getGroupSources();
	var keyArray = ["groupname"];
	var valueArray = [groupName];
	return this.filterByKeyValues(groupSources, keyArray, valueArray);
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Stage"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Stage"] = true;
dojo.provide("plugins.core.Agua.Stage");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	STAGE METHODS  
*/

dojo.declare( "plugins.core.Agua.Stage",	[  ], {

/////}}}

// STAGE METHODS
addStage : function (stageObject) {
// ADD AN APP OBJECT TO stages AND COPY ITS PARAMETERS
// INTO parameters. RETURN TRUE OR FALSE.
// ALSO UPDATE THE REMOTE DATABASE.
	console.log("Agua.Stage.addStage    stageObject: ");
	console.dir({stageObject:stageObject});
	
	var result = this._addStage(stageObject);
	
	// ADD PARAMETERS FOR THIS STAGE TO stageparameters
	if ( result == true )	result = this.addStageParametersForStage(stageObject);
	if ( result == false )
	{
		//console.log("Agua.Stage.removeStage    Problem adding stage or stageparameters. Returning.");
		return;
	}
	
	// ADD STAGE ON REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = stageObject;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addStage";
	//console.log("Agua.Stage.addStage    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query });
	
	return result;
},
_addStage : function (stageObject) {
// ADD A STAGE TO stages 
	//console.log("Agua.Stage._addStage    plugins.core.Data._addStage(stageObject)");
	//console.log("Agua.Stage._addStage    stageObject: " + dojo.toJson(stageObject));	
	var requiredKeys = ["project", "workflow", "name", "number"];
	var result = this.addData("stages", stageObject, requiredKeys);
	if ( result == false )
	{
		//console.log("Agua.Stage._addStage    Failed to add stage to stages");
		return false;
	}

	return result;
},
insertStage : function (stageObject) {
// INSERT AN APP OBJECT INTO THE stages ARRAY,
// INCREMENTING THE number OF ALL DOWNSTREAM STAGES
// BEFOREHAND. DO THE SAME FOR THE stageparameters
// ENTRIES FOR THIS APP.
// THEN, MIRROR ON THE REMOTE DATABASE.

	console.log("Agua.Stage.insertStage    plugins.core.Data.insertStage(stageObject)");
	delete stageObject.avatarType;
	console.log("Agua.Stage.insertStage    stageObject: ");
	console.dir({stageObject:stageObject});
	
    // SET THE WORKFLOW NUMBER IN THE STAGE OBJECT
    var workflowNumber = Agua.getWorkflowNumber(stageObject.project, stageObject.workflow);
    stageObject.workflownumber = workflowNumber;    

	// SANITY CHECK
	if ( stageObject == null )	return;
	
	// GET THE STAGES FOR THIS PROJECT AND WORKFLOW
	// ORDERED BY number
	var stages = this.getStagesByWorkflow(stageObject.project, stageObject.workflow);
	//console.log("Agua.Stage.insertStage    pre-insert unsorted stages: " + dojo.toJson(stages, true));
	stages = this.sortHasharray(stages, "number");
	//console.log("Agua.Stage.insertStage    pre-insert sorted stages: ");
	//console.dir({pre_insert_sorted_stages:stages});

	// GET THE INSERTION INDEX OF THE STAGE
	var index = stageObject.number - 1;
	
	var sourceUser = stageObject.owner;
	var targetUser = stageObject.username;
	
	// INCREMENT THE appnumber IN ALL DOWNSTREAM STAGES IN stageparameters
	var result = true;
	for ( var i = stages.length - 1; i > index - 1; i-- )
	{
		// GET THE STAGE PARAMETERS FOR THIS STAGE
		var stageParameters = this.getStageParameters(stages[i]);

		//console.log("Agua.Stage.insertStage    Stage parameters for stages[" + i + "]: ");
		//console.dir({stageParameters:stageParameters});

		if ( stageParameters == null )
		{
			console.log("Agua.Stage.insertStage    Result = false because no stage parameters for stage: " + dojo.toJson(stages[i], true));
			result = false;
		}

		// REMOVE EACH STAGE PARAMETER AND RE-ADD ITS UPDATED VERSION
		var thisObject = this;
		for ( var j = 0; j < stageParameters.length; j++ )
		{
			// REMOVE EXISTING STAGE
			if ( thisObject._removeStageParameter(stageParameters[j]) == false )
			{
				console.log("Agua.Stage.insertStage    Result = false because there was a problem removing stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}

			// INCREMENT STAGE NUMBER
			stageParameters[j].appnumber = (i + 2).toString();

			// ADD BACK STAGE
			if ( thisObject._addStageParameter(stageParameters[j]) == false )
			{
				console.log("Agua.Stage.insertStage    Result = false because there was a problem adding stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}				
		}

		//  ******** DEBUG ONLY ************
		//  ******** DEBUG ONLY ************
		//var updatedStageParameters = this.getStageParameters(stages[i]);
		////console.log("Agua.Stage.insertStage    updatedStageParameters for stages[" + i + "]: " + dojo.toJson(updatedStageParameters));
		//  ******** DEBUG ONLY ************
		//  ******** DEBUG ONLY ************
	}
	if ( result == false )
	{
		console.log("Agua.Stage.insertStage    Returning because there was a problem updating the stage parameters");
		return false;
	}

	// INCREMENT THE number OF ALL DOWNSTREAM STAGES IN stages
	// NB: THE SERVER SIDE UPDATES ARE DONE AUTOMATICALLY
	for ( var i = stages.length - 1; i > index - 1; i-- )
	{
		// REMOVE FROM stages
		if ( this._removeStage(stages[i]) == false )
		{
			console.log("Agua.Stage.spliceStage    Returning because there was a problem removing stages[" + i + "]: " + dojo.toJson(stages[i]));
			return false;
		}

		// INCREMENT STAGE NUMBER
		stages[i].number = (i + 2).toString();

		// ADD BACK TO stages
		if ( this._addStage(stages[i]) == false )
		{
			console.log("Agua.Stage.spliceStage    Returning because there was a problem adding back stages[" + i + "]: " + dojo.toJson(stages[i]));
			return false;
		}
	}
	
	// INSERT THE NEW STAGE (NO EXISTING STAGES WILL HAVE ITS number)
	// (NB: this._addStage CHECKS FOR REQUIRED FIELDS)
	result = this._addStage(stageObject);
	if ( result == false )
	{
		console.log("Agua.Stage.insertStage    Returning FALSE because there was a problem adding the stage to stages: " + dojo.toJson(stageObject));
		return false;
	}
	//console.log("Agua.Stage.insertStage    this._addStage(...) result: " + result);
	
	// ADD PARAMETERS FOR THIS STAGE TO stageparameters
	if ( result == true ) result = this.addStageParametersForStage(stageObject);
	if ( result == false )
	{
		console.log("Agua.Stage.insertStage    Returning because there was a problem copying parameters for the stage:" + dojo.toJson(stageObject));
		return false;
	}

	// ADD STAGE IN REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = stageObject;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "insertStage";
	this.doPut({ url: url, query: query });
	
	// RETURN TRUE OR FALSE
	return true;
},
removeStage : function (stageObject) {
// REMOVE AN APP OBJECT FROM THE stages ARRAY
// AND SIMULTANEOUSLY REMOVE CORRESPONDING ENTRIES IN
// parameters FOR THIS STAGE.
// ALSO, MAKE removeStage CALL TO REMOTE DATABASE.

	console.log("Agua.Stage.removeStage    plugins.core.Data.removeStage(stageObject)");
	console.log("Agua.Stage.removeStage    stageObject: " + stageObject);
	
	// DO THE ADD
	var result = this._removeStage(stageObject);

	// ADD PARAMETERS FOR THIS STAGE TO stageparameters
	console.log("Agua.Stage.removeStage    Doing this.removeStageParameters(stageObject)");
	if( result == true ) 	result = this.removeStageParameters(stageObject);

	if ( result == false )
	{
		console.log("Agua.Stage.removeStage    Problem removing stage or stageparameters. Returning.");
		return;
	}
	
	// ADD STAGE TO stage TABLE IN REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = stageObject;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "removeStage";
	//console.log("Agua.Stage.removeStage    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query });
	
	// RETURN TRUE OR FALSE
	return result;
},
_removeStage : function (stageObject) {
// REMOVE AN APP OBJECT FROM THE stages ARRAY
// AND SIMULTANEOUSLY REMOVE CORRESPONDING ENTRIES IN
// parameters FOR THIS STAGE
	//console.log("Agua.Stage._removeStage    plugins.core.Data._removeStage(stageObject)");
	//console.log("Agua.Stage._removeStage    stageObject: " + dojo.toJson(stageObject));

	var uniqueKeys = ["project", "workflow", "name", "number"];
	var result = this.removeData("stages", stageObject, uniqueKeys);
	if ( result == false )
	{
		//console.log("Agua.Stage._removeStage    Failed to remove stage from stages");
		return false;
	}
	return result;
},
updateStagesStatus : function (stageList) {
// UPDATE STAGE status, started AND completed
	//console.log("Agua.Stage.updateStagesStatus    stageList: " + dojo.toJson(stageList, true));	
	if ( stageList == null || stageList.length == 0 )	return;
	//console.log("Agua.Stage.updateStagesStatus     stageList.length: " + stageList.length);
	
	// GET ACTUAL stages DATA
	var stages = this.getData("stages");
	
	// ORDER BY STAGE NUMBER -- NB: REMOVES ENTRIES WITH NO NUMBER
	stages = this.sortNumericHasharray(stages, "number");
	//console.log("Agua.Stage.updateStagesStatus     stages.length: " + stages.length);

	var projectName = stages[0].project;
	var workflowName = stages[0].workflow;
	var counter = 0;
	for ( var i = 0; i < stages.length; i++ )
	{
		if ( stages[i].project != projectName )	continue;
		if ( stages[i].workflow != workflowName )	continue;
		counter++;
		//console.log("Agua.Stage.updateStagesStatus     stage " + counter + ": " + dojo.toJson(stages[i], true));
		//console.log("Agua.Stage.updateStagesStatus     stages " + counter + " number: " + stages[i].number + ", status: " + stages[i].status + ", started: " + stages[i].started + ", completed: " + stages[i].completed);
	}
	
	// UPDATE STAGES
	for ( var i = 0; i < stages.length; i++ )
	{
		if ( stages[i].project != projectName )	continue;
		if ( stages[i].workflow != workflowName )	continue;

		for ( var k = 0; k < stageList.length; k++ )
		{
			//console.log("Agua.Stage.updateStagesStatus     stageList " + k);
			if ( stages[i].number == stageList[k].number )
			{
				stages[i].status = stageList[k].status;
				stages[i].started = stageList[k].started;
				stages[i].completed = stageList[k].completed;
				continue;
			}
		}
	}
	
	// DEBUG -- CONFIRM CHANGES
	stages = this.getData("stages");
	stages = this.sortNumericHasharray(stages, "number");
	counter = 0;
	for ( var i = 0; i < stages.length; i++ )
	{
		if ( stages[i].project != projectName )	continue;
		if ( stages[i].workflow != workflowName )	continue;
		counter++;
		//console.log("Agua.Stage.updateStagesStatus     stage " + counter + ": " + dojo.toJson(stages[i], true));
		//console.log("Agua.Stage.updateStagesStatus     stage " + counter + " number: " + stages[i].number + ", status: " + stages[i].status + ", started: " + stages[i].started + ", completed: " + stages[i].completed);
	}
},	
updateStageSubmit : function (stageObject) {
// ADD AN APP OBJECT TO stages AND COPY ITS PARAMETERS
// INTO parameters. RETURN TRUE OR FALSE.
// ALSO UPDATE THE REMOTE DATABASE.
	//console.log("Agua.Stage.updateStageSubmit    plugins.core.Data.updateStageSubmit(stageObject)");
	//console.log("Agua.Stage.updateStageSubmit    stageObject: " + dojo.toJson(stageObject));

	var stages = this.getData("stages");
	var index = this._getIndexInArray(stages, stageObject, ["project", "workflow", "number"]);
	//console.log("Agua.Stage.updateStageSubmit    index: " + index);	
	if ( index == null )	return 0;
	
	//console.log("Agua.Stage.updateStageSubmit    stages[index]: " + dojo.toJson(stages[index]));
	stages[index].submit = stageObject.submit;

	// ADD STAGE ON REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	stageObject.username = this.cookie("username");
	stageObject.sessionId = this.cookie("sessionId");
	stageObject.mode = "updateStageSubmit";
	//console.log("Agua.Stage.updateStageSubmit    stageObject: " + dojo.toJson(stageObject, true));
	this.doPut({ url: url, query: stageObject });

	return 1;
},
spliceStage : function (stageObject) {
// SPLICE OUT A STAGE FROM stages AND DECREMENT THE
// number OF ALL DOWNSTREAM STAGES.
// DO THE SAME FOR THE CORRESPONDING ENTRIES IN stageparameters
	//console.log("Agua.Stage.spliceStage    plugins.core.Data.updateStage(stageObject)");
	//console.log("Agua.Stage.spliceStage    stageObject: " + dojo.toJson(stageObject, true));
	
	// SANITY CHECK
	if ( stageObject == null )	return;
	
	// GET THE STAGES FOR THIS PROJECT AND WORKFLOW
	var stages = this.getStagesByWorkflow(stageObject.project, stageObject.workflow);
	//////console.log("Agua.Stage.spliceStage    pre-splice unsorted stages: " + dojo.toJson(stages, true));

	// ORDER BY number AND SPLICE OUT THE STAGE 
	stages = this.sortHasharray(stages, "number");
	//////console.log("Agua.Stage.spliceStage    pre-splice sorted stages: " + dojo.toJson(stages, true));
	var index = stageObject.number - 1;
	stages.splice(index, 1);
	
	
	// REMOVE THE STAGE FROM THE stages
	var result = this._removeStage(stageObject);
	if ( result == false )
	{
		////console.log("Agua.Stage.spliceStage    Returning because there was a problem removing the stage from stages: " + dojo.toJson(stageObject));
		return false;
	}

	// REMOVE THE STAGE FROM stageparameters
	//console.log("Agua.Stage.spliceStage    Doing this.removeStageParameters(stageObject)");
	result = this.removeStageParameters(stageObject);
	if ( result == false )
	{
		console.log("Agua.Stage.spliceStage    Returning because there was a problem removing parameters for the stage:" + dojo.toJson(stageObject));
		return false;
	}

	// DECREMENT THE number OF ALL DOWNSTREAM STAGES IN stages
	// NB: THE SERVER SIDE UPDATES ARE DONE AUTOMATICALLY
	for ( var i = index; i < stages.length; i++ )
	{
		// REMOVE IT FROM THE stages ARRAY
		////console.log("Agua.Stage.spliceStage    Replacing stage " + i + " to decrement number to " + (i + 1) );
		this._removeStage(stages[i]);
		stages[i].number = (i + 1).toString();
		this._addStage(stages[i]);
	}

	//  ******** DEBUG ONLY ************
	//  ******** DEBUG ONLY ************
	var newStages = this.getStagesByWorkflow(stageObject.project, stageObject.workflow);
	//////console.log("Agua.Stage.spliceStage    post-splice stages: " + dojo.toJson(newStages, true));
	for ( var i = 0; i < newStages.length; i++ )
	{
		////console.log("Agua.Stage.spliceStage    newStages[" + i + "]:" + newStages[i].name + "\t" + newStages[i].number);
	}
	
	//  ******** DEBUG ONLY ************
	//  ******** DEBUG ONLY ************


	// DECREMENT THE appnumber IN ALL DOWNSTREAM STAGES IN stageparameters
	////console.log("Agua.Stage.spliceStage    Doing from " + (stages.length - 1) + " to " + index);
	for ( var i = stages.length - 1; i > index - 1; i-- )
	{
		// REINCREMENT STAGE NUMBER TO GET ITS STAGE
		// PARAMETERS, WHICH HAVE NOT BEEN DECREMENTED YET
		stages[i].number = (i + 2).toString();
		////console.log("Agua.Stage.spliceStage    Reincremented stage[" + i + "].number to: " + stages[i].number);

		// GET THE STAGE PARAMETERS FOR THIS STAGE
		var stageParameters = this.getStageParameters(stages[i]);
		//////console.log("Agua.Stage.spliceStage    stages[" + i + "]: " + dojo.toJson(stages[i], true));
		//////console.log("Agua.Stage.spliceStage    Stage parameters for stages[" + i + "]: " + dojo.toJson(stageParameters, true));
		if ( stageParameters == null )
		{
			////console.log("Agua.Stage.spliceStage    Returning because no stage parameters for stage: " + dojo.toJson(stages[i], true));
			return false;
		}

		// REMOVE EACH STAGE PARAMETER AND RE-ADD ITS UPDATED VERSION
		var thisObject = this;
		//dojo.forEach( stageParameters, function(stageParameter, i)
		for ( var j = 0; j < stageParameters.length; j++ )
		{
			// REMOVE EXISTING STAGE
			if ( thisObject._removeStageParameter(stageParameters[j]) == false )
			{
				////console.log("Agua.Stage.spliceStage    Result = false because there was a problem removing stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}

			// DECREMENT STAGE NUMBER
			stageParameters[j].appnumber = (i + 1).toString();

			// ADD BACK STAGE
			if ( thisObject._addStageParameter(stageParameters[j]) == false )
			{
				////console.log("Agua.Stage.spliceStage    Result = false because there was a problem adding stageParameter: " + dojo.toJson(stageParameters[j], true));
				result = false;
			}
		}

		// REDECREMENT STAGE NUMBER
		stages[i].number = (i + 1).toString();
		////console.log("Agua.Stage.spliceStage    Redecremented stage[" + i + "].number to: " + stages[i].number);
	}
	if ( result == false )	return false;

	// REMOVE FROM REMOTE DATABASE DATABASE:
	var url = Agua.cgiUrl + "workflow.cgi";

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query = stageObject;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "removeStage";
	////console.log("Agua.Stage.spliceStage    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query});
},
isStage : function (stageName) {
// RETURN true IF AN APP EXISTS IN stages
	//console.log("Agua.Stage.isStage    plugins.core.Data.isStage(stageName, stageObject)");
	//console.log("Agua.Stage.isStage    stageName: *" + stageName + "*");
	var stages = this.getStages();
	for ( var i in stages )
	{
		var stage = stages[i];
		//console.log("Agua.Stage.isStage    Checking stage.name: *" + stage.name + "*");
		if ( stage.name.toLowerCase() == stageName.toLowerCase() )
		{
			return true;
		}
	}
	
	return false;
},
getStageType : function (stageName) {
// RETURN true IF AN APP EXISTS IN stages
	//console.log("Agua.Stage.getStageType    plugins.core.Data.getStageType(stageName, stageObject)");
	////console.log("Agua.Stage.getStageType    stageName: *" + stageName + "*");
	var stages = this.getStages();
	for ( var i in stages )
	{
		var stage = stages[i];
		////console.log("Agua.Stage.getStageType    Checking stage.name: *" + stage.name + "*");
		if ( stage.name.toLowerCase() == stageName.toLowerCase() )
		{
			return stage.type;
		}
	}
	
	return null;
},
getStages : function () {
	//console.log("Agua.Stage.getStages    plugins.core.Data.getStages()");
	
	return this.cloneData("stages");
},
getStagesByWorkflow : function (project, workflow) {
// RETURN AN ARRAY OF STAGE HASHES FOR THIS PROJECT AND WORKFLOW

	////console.log("Agua.Stage.getStagesByWorkflow    plugins.core.Data.getStagesByWorkflow(project, workflow)");
	////console.log("Agua.Stage.getStagesByWorkflow    project: " + project);
	////console.log("Agua.Stage.getStagesByWorkflow    workflow: " + workflow);
	if ( project == null )	return;
	if ( workflow == null )	return;
	var stages = this.cloneData("stages");
	var keyArray = ["project", "workflow"];
	var valueArray = [project, workflow];
	stages = this.filterByKeyValues(stages, keyArray, valueArray);
	
	////console.log("Agua.Stage.getStagesByWorkflow    Returning stages: " + dojo.toJson(stages));

	return stages;
}

});

}

if(!dojo._hasResource["plugins.core.Agua.StageParameter"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.StageParameter"] = true;
dojo.provide("plugins.core.Agua.StageParameter");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	STAGEPARAMETER METHODS  
*/

dojo.declare( "plugins.core.Agua.StageParameter",	[  ], {

/////}}}

// STAGEPARAMETER METHODS
addStageParameter : function (stageParameterObject) {
// 1. REMOVE ANY EXISTING STAGE PARAMETER (UNIQUE KEYS: appname, appnumber, name)
// 		(I.E., THE SAME AS UPDATING AN EXISTING STAGE PARAMETER)
// 2. ADD A STAGE PARAMETER OBJECT TO THE stageparameters ARRAY
//   
// 3. ADD TO stageparameter TABLE IN REMOTE DATABASE

	//console.log("Agua.StageParameteraddStageParameter    plugins.core.Data.addStageParameter(stageParameterObject)");
	//console.log("Agua.StageParameteraddStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	// DO THE REMOVE
	this._removeStageParameter(stageParameterObject);
	
	// DO THE ADD
	var result = this._addStageParameter(stageParameterObject);
	if ( result == false )
    {
        console.log("Agua.StageParameteraddStageParameter    result of _addStageParameter is " + result + ". Returning");
        return result;
    }
    
	// REMOVE FROM REMOTE DATABASE DATABASE:
	// SET URL, ADD RANDOM NUMBER TO DISAMBIGUATE BETWEEN CALLS BY DIFFERENT
	// METHODS TO THE SERVER
	var url = this.cgiUrl + "workflow.cgi";

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query = stageParameterObject;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addStageParameter";
	//console.log("Agua.StageParameteraddStageParameter     query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query});

	// RETURN TRUE OR FALSE
	return result;
},
_addStageParameter : function (stageParameterObject) {
// ADD A STAGE PARAMETER OBJECT TO THE stageparameters ARRAY,
// REQUIRE THAT UNIQUE KEYS ARE DEFINED

	if ( stageParameterObject.chained == null )
		stageParameterObject.chained = "0";
	//console.log("Agua.StageParameter_addStageParameter    plugins.core.Data._addStageParameter(stageParameterObject)");
	//console.log("Agua.StageParameter_addStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	// DO THE ADD
	var uniqueKeys = ["project", "workflow", "appname", "appnumber", "name", "paramtype"];
	return this.addData("stageparameters", stageParameterObject, uniqueKeys);
},
removeStageParameter : function (stageParameterObject) {
// 1. REMOVE A stage PARAMETER OBJECT FROM THE stageparameters ARRAY
// 2. REMOVE FROM stageparameter TABLE IN REMOTE DATABASE

	////console.log("Agua.StageParameterremoveStageParameter    plugins.core.Data.removeStageParameter(stageParameterObject)");
	////console.log("Agua.StageParameterremoveStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	var result = this._removeStageParameter(stageParameterObject);
	if ( result == false )	return result;

	// REMOVE FROM REMOTE DATABASE:
	// SET URL, ADD RANDOM NUMBER TO DISAMBIGUATE BETWEEN CALLS BY DIFFERENT
	// METHODS TO THE SERVER
	var url = this.cgiUrl + "workflow.cgi";
	
	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query = stageParameterObject;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addStageParameter";
	//console.log("Agua.StageParameteraddStageParameter     query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query, timeout : 15000 });

	// RETURN TRUE OR FALSE
	return result;
},
_removeStageParameter : function (stageParameterObject) {
// REMOVE A stage PARAMETER OBJECT FROM THE stageparameters ARRAY,
// IDENTIFY OBJECT USING UNIQUE KEYS
	////console.log("Agua.StageParameter_removeStageParameter    plugins.core.Data._removeStageParameter(stageParameterObject)");
	////console.log("Agua.StageParameter_removeStageParameter    stageParameterObject: " + dojo.toJson(stageParameterObject));

	var uniqueKeys = ["project", "workflow", "appname", "appnumber", "name", "paramtype"];
	return this.removeData("stageparameters", stageParameterObject, uniqueKeys);
},
getStageParameters : function (stageObject) {
// RETURN AN ARRAY OF STAGE PARAMETER HASHARRAYS FOR THE GIVEN STAGE
	//console.log("Agua.StageParametergetStageParameters    plugins.core.Data.getStageParameters(stageObject)");
	//console.log("Agua.StageParametergetStageParameters    stageObject: " + dojo.toJson(stageObject));
	if ( stageObject == null )	return;
	
	var keys = ["project", "workflow", "name", "number"];
	var notDefined = this.notDefined (stageObject, keys);
	//console.log("Agua.StageParametergetStageParameters    notDefined: " + dojo.toJson(notDefined));
	if ( notDefined.length != 0 )
	{
		console.log("Agua.StageParametergetStageParameters    not defined: " + dojo.toJson(notDefined));
		return;
	}
	
	// CONVERT STAGE number TO appnumber
	stageObject.appnumber = stageObject.number;
	stageObject.appname = stageObject.name;

	var stageParameters = this._getStageParameters();
	//console.log("Agua.StageParametergetStageParameters    INITIAL stageParameters.length: " + stageParameters.length);	
	var keyArray = ["project", "workflow", "appname", "appnumber"];
	var valueArray = [stageObject.project, stageObject.workflow, stageObject.name, stageObject.number];
	stageParameters = this.filterByKeyValues(stageParameters, keyArray, valueArray);
	//console.log("Agua.StageParametergetStageParameters    Returning stageParameters.length: " + stageParameters.length);	

	return stageParameters;
},
_getStageParameters : function () {
    return this.cloneData("stageparameters");
},
addStageParametersForStage : function (stageObject) {
// ADD parameters ENTRIES FOR A STAGE TO stageparameters
	//console.log("Agua.StageParameteraddStageParametersForStage    plugins.core.Data.addStageParametersForStage(stageObject)");
	//console.log("Agua.StageParameteraddStageParametersForStage    stageObject: " + dojo.toJson(stageObject));
	if ( stageObject.name == null )	return null;
	if ( stageObject.number == null )	return null;

	// GET APP PARAMETERS	
	var parameters;
	//console.log("Agua.StageParameteraddStageParametersForStage    this.cookie("username"): " + this.cookie("username"));
	if ( stageObject.owner == this.cookie("username") )
	{
		//console.log("Agua.StageParameteraddStageParametersForStage    Doing this.getParametersByAppname(stageObject.name)");
		parameters = dojo.clone(this.getParametersByAppname(stageObject.name));
	}
	else {
		//console.log("Agua.StageParameteraddStageParametersForStage    Doing this.getSHAREDParametersByAppname(stageObject.name)");
		parameters = dojo.clone(this.getSharedParametersByAppname(stageObject.name, stageObject.owner));
	}
	//console.log("Agua.StageParameteraddStageParametersForStage    parameters.length: " + parameters.length);	
	//console.log("Agua.StageParameteraddStageParametersForStage    BEFORE parameters: " + dojo.toJson(parameters, true));

	// ADD STAGE project, workflow, AND number TO PARAMETERS
	dojo.forEach(parameters, function(parameter)
	{
		parameter.project = stageObject.project;
		parameter.workflow = stageObject.workflow;
		parameter.appnumber = stageObject.number;
		parameter.appname = stageObject.name;
	});
	//console.log("Agua.StageParameteraddStageParametersForStage    AFTER parameters: " + dojo.toJson(parameters));
	//console.log("Agua.StageParameteraddStageParametersForStage    parameters.length: " + parameters.length);

	var stageParameters = Agua.cloneData("stageparameters");
	//console.log("Agua.StageParameteraddStageParametersForStage    stageParameters.length: " + stageParameters.length);


	// ADD PARAMETERS TO stageparameters ARRAY
	var uniqueKeys = ["owner", "project", "workflow", "appname", "appnumber", "name", "paramtype"];
	var addOk = true;
	var thisObject = this;
	dojo.forEach(parameters, function(parameter)
	{
		//console.log("Agua.StageParameteraddStageParametersForStage    Adding parameter: " + dojo.toJson(parameter));

		if ( thisObject.addData("stageparameters", parameter, uniqueKeys) == false)
		{
			addOk = false;
		}

		stageParameters = Agua.cloneData("stageparameters");
		//console.log("Agua.StageParameteraddStageParametersForStage    stageParameters.length: " + stageParameters.length);

	});
	//console.log("Agua.StageParameteraddStageParametersForStage    addOk: " + addOk);
	if ( ! addOk )
	{
		//console.log("Agua.StageParameteraddStageParametersForStage    Could not add one or more parameters to stageparameters");
		return;
	}

	return addOk;
},
removeStageParameters : function (stageObject) {
// REMOVE STAGE PARAMETERS FOR A STAGE FROM stageparameters 
	//console.log("Agua.StageParameterremoveStageParameters    plugins.core.Data.removeStageParameters(stageObject)");
	//console.log("Agua.StageParameterremoveStageParameters    stageObject: " + dojo.toJson(stageObject, true));

	if ( stageObject.name == null )
	{
		console.log("Agua.StageParameterremoveStageParameters    stageObject.name is null. Returning.");
		return null;
	}
	if ( stageObject.number == null )
	{
		console.log("Agua.StageParameterremoveStageParameters    stageObject.number is null. Returning.");
		return null;
	}

	// GET STAGE PARAMETERS BELONGING TO THIS STAGE
	var keys = [ "owner", "project", "workflow", "appname", "appnumber" ];
	var values = [ stageObject.owner, stageObject.project, stageObject.workflow, stageObject.name, stageObject.number ];
	var removeTheseStageParameters = this.filterByKeyValues(this._getStageParameters(), keys, values);
	//console.log("Agua.StageParameterremoveStageParameters    removeTheseStageParameters.length: " + removeTheseStageParameters.length);

	// REMOVE PARAMETERS FROM stageparameters
	var uniqueKeys = [ "project", "workflow", "appname", "appnumber", "name"];
	var removeOk = this.removeArrayFromData("stageparameters", removeTheseStageParameters, uniqueKeys);
	console.log("Agua.StageParameterremoveStageParameters    removeOk: " + removeOk);
	if ( removeOk == false )
	{
		console.log("Agua.StageParameterremoveStageParameters    Could not remove one or more parameters from stageparameters");
		return false;
	}

	return true;
},
getStageParametersByApp : function (appname) {
// RETURN AN ARRAY OF PARAMETER HASHARRAYS FOR THE GIVEN APPLICATION
	//console.log("Agua.StageParametergetStageParametersByApp    plugins.core.Data.getStageParametersByApp(appname)");
	//console.log("Agua.StageParametergetStageParametersByApp    appname: " + appname);

	var stageParameters = new Array;
	dojo.forEach(this.getStageParameters(), function(stageparameter)
	{
		if ( stageparameter.appname == appname )	stageParameters.push(stageparameter);
	});
	
	//console.log("Agua.StageParametergetStageParametersByApp    Returning stageParameters: " + dojo.toJson(stageParameters));

	return stageParameters;
}

});

}

if(!dojo._hasResource["plugins.core.Agua.User"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.User"] = true;
dojo.provide("plugins.core.Agua.User");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	USER METHODS  
*/

dojo.declare( "plugins.core.Agua.User",	[  ], {

/////}}}

getUser : function (username) {
// RETURN ENTRY FOR username IN users
	console.log("Agua.User.getUser    plugins.core.Data.getUser(username)");
	console.log("Agua.User.getUser    username: " + username);
	var users = this.getUsers();
	console.log("Agua.User.getUser    users: " + dojo.toJson(users));
	var index = this._getIndexInArray(users, {"username":username}, ["username"]);
	console.log("Agua.User.getUser    index: " + index);
	if ( index != null )
	{
		return users[index];
	}
	
	return null;
},
getUsers : function () {
// RETURN A SORTED COPY OF users
	console.log("Agua.User.getUsers    plugins.core.Data.getUsers(userObject)");
	this.sortData("users", "username");
	return this.cloneData("users");
},
addUser : function (userObject) {
	console.log("Agua.User.addUser    plugins.core.Data.addUser(userObject)");
	//console.log("Agua.User.addUser    userObject: " + dojo.toJson(userObject));

	this._removeUser(userObject);
	if ( ! Agua._addUser(userObject) )	return;
	
	// CREATE JSON QUERY
	var url = Agua.cgiUrl + "workflow.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addUser";
	query.data = userObject;
	console.log("query: ");
	console.dir(query);
	console.log("Users.saveUser    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query, sync: false });
},
_addUser : function (userObject) {
// ADD A USER OBJECT TO THE users ARRAY
	console.log("Agua.User._addUser    plugins.core.Data._addUser(userObject)");
	//console.log("Agua.User._addUser    userObject: " + dojo.toJson(userObject));
	if ( ! this.addData("users", userObject, ["username"]) )	return false;
	this.sortData("users", "username");
	
	return true;
},
isUser : function (userObject) {
// ADD A USER OBJECT TO THE users ARRAY
	//console.log("Agua.User.isUser    plugins.core.Data.isUser(userObject)");
	//console.log("Agua.User.isUser    userObject: " + dojo.toJson(userObject));
	var users = this.getUsers();
	if ( this._getIndexInArray(users, userObject, ["username"]) )	return true;
	
	return false;
},
removeUser : function (userObject) {
	console.log("Agua.User.removeUser    plugins.core.Data.removeUser(userObject)");
	//console.log("Agua.User.removeUser    userObject: " + dojo.toJson(userObject));

	// REMOVING SOURCE FROM Agua.users
	if ( ! this._removeUser(userObject) )	return;

	// CREATE JSON QUERY
	var url = Agua.cgiUrl + "sharing.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "removeUser";
	query.data = userObject;
	////console.log("Users.deleteItem    query: " + dojo.toJson(query));

	this.doPut({ url: url, query: query, sync: false });	
},
_removeUser : function (userObject) {
// REMOVE A USER OBJECT FROM THE users ARRAY
	console.log("Agua.User._removeUser    plugins.core.Data._removeUser(userObject)");
	//console.log("Agua.User._removeUser    userObject: " + dojo.toJson(userObject));

	// MOTHBALLED TWO-D ARRAYS
	//// ARRAY FORMAT:
	//// userArray[0]: ["aabate","a","abate","aabate@med.miami.edu",""]
	//var userArray = new Array;
	//userArray[0] = userObject.username;
	//userArray[1] = userObject.firstname || "";
	//userArray[2] = userObject.lastname || "";
	//userArray[3] = userObject.email || "";
	//
	//// DELETED USER MUST HAVE username
	if ( ! this.removeData("users", userObject, ["username"]) ) return false;

	// REMOVE USER FROM groupmember TABLE
	this._removeUserFromGroups(userObject);

	return true;
},
_removeUserFromGroups : function (userObject) {
// REMOVE USER FROM ALL GROUPS CREATED BY THIS (ADMIN) USER

	console.log("Agua.User._removeUserFromGroups    plugins.core.Data._removeUserFromGroups");
	userObject.type = "user";
	userObject.name = userObject.username;
	return this._removeObjectsFromData("groupmembers", userObject, ["name", "type"]);
},
isGroupUser : function (groupName, userObject) {
// RETURN true IF A USER ALREADY BELONGS TO A GROUP

	//console.log("Agua.User.isGroupUser    plugins.core.Data.isGroupUser(groupName, userObject)");
	//console.log("Agua.User.isGroupUser    groupName: " + groupName);
	//console.log("Agua.User.isGroupUser    userObject: " + dojo.toJson(userObject));
	
	var groupUsers = this.getGroupUsers();
	if ( groupUsers == null )	return false;
	//console.log("Agua.User.isGroupUser    groupUsers: " + dojo.toJson(groupUsers));

	groupUsers = this.filterByKeyValues(groupUsers, ["groupname"], [groupName]);
	//console.log("Agua.User.isGroupUser    AFTER filter groupUsers: " + dojo.toJson(groupUsers));
	
	return this._objectInArray(groupUsers, userObject, ["name"]);
},
addUserToGroup : function (groupName, userObject) {
// ADD A USER OBJECT TO A GROUP ARRAY IF IT DOESN"T EXIST THERE ALREADY 
	//console.log("Agua.User.addUserToGroup     Agua.addUserToGroup(groupName, userObject)");
	//console.log("Agua.User.addUserToGroup     groupName: " + groupName);
	//console.log("Agua.User.addUserToGroup     userObject: " + dojo.toJson(userObject));
	
	if ( this.isGroupUser(groupName, userObject) == true )
	{
		//console.log("Agua.User.addUserToGroup     user already exists in group: " + userObject.name + ". Returning.");
		return false;
	}

	var groups = this.getGroups();
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	if ( group == null )	return false;
	
	userObject.username = group.username;
	userObject.groupname = groupName;
	userObject.groupdesc = group.description;
	userObject.type = "user";

	var requiredKeys = [ "username", "groupname", "name", "type"];
	return this.addData("groupmembers", userObject, requiredKeys);
},
removeUserFromGroup : function (groupName, userObject) {
// REMOVE A USER FROM A GROUP, IDENTIFY USER OBJECT BY "name" KEY VALUE
	//console.log("Agua.User.removeUserFromGroup    plugins.core.Data.addUserToGroup");
	var groups = this.getGroups();
	//console.log("Agua.User.removeUserFromGroup    groups: " + groups);
	var group = this._getObjectByKeyValue(groups, "groupname", groupName);
	if ( group == null )	return false;
	//console.log("Agua.User.removeUserFromGroup    group: " + dojo.toJson(group));

	userObject.owner = group.username;
	userObject.groupname = groupName;
	userObject.groupdesc = group.description;
	userObject.type = "user";

	var requiredKeys = [ "username", "groupname", "name", "type"];
	return this.removeData("groupmembers", userObject, requiredKeys);
}

});

}

if(!dojo._hasResource["plugins.core.Agua.View"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.View"] = true;
dojo.provide("plugins.core.Agua.View");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	VIEW METHODS  
*/

dojo.declare( "plugins.core.Agua.View",	[  ], {

/////}}}}
getViewObject : function (projectName, viewName) {
// RETURN AN ARRAY OF VIEW HASHES FOR THE SPECIFIED PROJECT AND WORKFLOW
	//console.log("Agua.View.getViewObject    plugins.core.Data.getViewObject(projectName, viewName)");
	//console.log("Agua.View.getViewObject    projectName: " + projectName);
	//console.log("Agua.View.getViewObject    viewName: " + viewName);

	var views = this.getViews();
	//console.log("Agua.View.getViewObject    views: " + dojo.toJson(views, true));
	if ( views == null )	return [];
	var keyArray = ["project", "view"];
	var valueArray = [projectName, viewName];
	var views = this.filterByKeyValues(views, keyArray, valueArray);
	//console.log("Agua.View.getViewObject    AFTER Agua.getViewObject");
	//console.dir({views:Agua.data.views})

	if ( views == null || views.length == 0 )	return null;
	return views[0];
},
getViews : function () {
// RETURN A COPY OF THE views ARRAY
	//console.log("Agua.View.getViews    plugins.core.Data.getViews()");	
	return this.cloneData("views");
},
getPreviousView : function (viewObject) {
	//console.log("Agua.View.getPreviousView    viewObject XXX: ");
	//console.dir({viewObject:viewObject});	

	var views = this.getViews();
	if ( ! views || views.length == 0 ) {
		//console.log("Agua.View.getPreviousView    views is null or empty. Returning");
		return;
	}

	var viewsCopy = dojo.clone(views);
	var projectViews = this.filterByKeyValues(viewsCopy, ["project"], [viewObject.project]);
	//console.log("Agua.View.getPreviousView    projectViews: ");
	//console.dir({projectViews:projectViews});	

	// GET PREVIOUS OR NEXT PROJECT IF NO VIEWS LEFT IN PROJECT
	if ( ! projectViews || projectViews.length == 0 ) {
	
		// ADD VIEW OBJECT BACK TO VIEWS AND SORT BY PROJECT
		views.push(viewObject);
		var thisObject = this;
		views.sort(
			function(a,b) {
				return thisObject.sortObjectsNaturally(a, b, "project");
			}
		);
		
		var projectNames = this.hashArrayKeyToArray(dojo.clone(views), "project");
		projectNames = this.uniqueValues(projectNames);
		if ( projectNames.length == 1 ) {
			//console.log("Agua.View.getPreviousView    projectNames.length == 1. Returning");
			return;
		}
		//console.log("Agua.View.getPreviousView    projectNames: ");
		//console.dir({projectNames:projectNames});
		
		var index = this._getIndex(projectNames, viewObject.project);
		//console.log("Agua.View.getPreviousView    index: " + index);
		
		var previousProject;
		if ( index == 0 )	{
			previousProject = projectNames[1];
			//console.log("Agua.View.getPreviousView    previousProject: " + previousProject);
			var projectViews = this.filterByKeyValues(views, ["project"], [previousProject]);

			projectViews.sort(
				function(a,b) {
					return thisObject.sortObjectsNaturally(a, b, "view");
				}
			);
			//console.log("Agua.View.getPreviousView    FINAL projectViews: ");
			//console.dir({projectViews:projectViews});
			//console.log("Agua.View.getPreviousView    RETURNING projectViews[0]");
		
			
			return projectViews[0];
		}
		else {
			previousProject = projectNames[index - 1];
			//console.log("Agua.View.getPreviousView    previousProject: " + previousProject);
			var projectViews = this.filterByKeyValues(views, ["project"], [previousProject]);
			projectViews.sort(
				function(a,b) {
					return thisObject.sortObjectsNaturally(a, b, "view");
				}
			);
			//console.log("Agua.View.getPreviousView    FINAL projectViews: ");
			//console.dir({projectViews:projectViews});
			//console.log("Agua.View.getPreviousView    RETURNING projectViews[(projectViews.length - 1)]");
		
			return projectViews[(projectViews.length - 1)];
		}		
	}
	else {
		// ADD VIEW OBJECT BACK TO VIEWS AND SORT
		views.push(viewObject);
		var thisObject = this;
		views.sort(
			function(a,b) {
				return thisObject.sortObjectsNaturally(a, b, "view");
			}
		);

		var index = this._getIndexInArray(views, viewObject, ["project", "view"]);
		//console.log("Agua.View.getPreviousView    index: " + index);
		
		if ( index == 0 )	return views[1];
		else return views[index - 1];
	}
},
removeView : function (viewObject) {
// REMOVE A VIEW OBJECT FROM THE views ARRAY
	//console.log("Agua.View.removeView    viewObject: " + dojo.toJson(viewObject));

	// REMOVE VIEW FROM views
	var requiredKeys = ["project", "view"];
	if ( ! this.removeData("views", viewObject, requiredKeys) ) {
		console.log("Agua.View.removeView    Could not remove view from views table: " + viewObject.name);
		return false;
	}
	
	// REMOVE ANY EXISTING FEATURES
	this.removeObjectsFromData("viewfeatures", viewObject, requiredKeys);
	
	return true;
},
isView : function (projectName, viewName) {
// RETURN true IF A VIEW EXISTS FOR THE PARTICULAR PROJECT AND WORKFLOW
	//console.log("Agua.View.isView    projectName: *" + projectName + "*");
	//console.log("Agua.View.isView    viewName: *" + viewName + "*");
	
	var viewObjects = this.getViewsByProject(projectName);
	//console.log("Agua.View.isView    viewObjects: ");
	//console.dir({viewObjects:viewObjects});
	
	for ( var i in viewObjects )
	{
		var viewObject = viewObjects[i];
		if ( viewObject.view.toLowerCase() == viewName.toLowerCase() )
		{
			console.log("Agua.View.isView    Match found for view: *" + viewObject.view + "*");
			return true;
		}
	}
	
	return false;
},
addView : function (viewObject) {
// ADD A VIEW TO views AND SAVE ON REMOTE SERVER
	//console.log("Agua.View.addView    plugins.core.Data.addView(viewObject)");
	//console.log("Agua.View.addView    viewObject: " + dojo.toJson(viewObject));

	// DO THE ADD
	var requiredKeys = ["project", "view"];
	return this.addData("views", viewObject, requiredKeys);
},
getViewNames : function (projectName) {
// RETURN AN ARRAY OF ALL VIEW NAMES IN views
	//console.log("Agua.View.viewNames    projectName: " + projectName);

	var views = this.getViewsByProject(projectName);
	//console.log("Agua.View.viewNames views: ");
	//console.dir({views:views});

	return this.hashArrayKeyToArray(views, "view");
},
getViewsByProject : function (projectName) {
// RETURN AN ARRAY OF VIEW HASHES FOR THE SPECIFIED PROJECT AND WORKFLOW
	//console.log("Agua.View.getViewsByProject    projectName: " + projectName);
	var views = this.getViews();
	if ( views == null )	return [];

	var keyArray = ["project"];
	var valueArray = [projectName];
	var views = this.filterByKeyValues(views, keyArray, valueArray);
	//console.log("Agua.View.getViewsByProject    AFTER FILTER views: " + dojo.toJson(views));

	return views;
},
getViewSpecies : function (projectName, viewName) {
// GET THE UNIQUE SPECIES (AND BUILD) FOR A GIVEN VIEW
	////console.log("Agua.View.getViewSpecies     plugins.core.Data.getViewSpecies(projectName, viewName)");
	////console.log("Agua.View.getViewSpecies    projectName: " + projectName);
	////console.log("Agua.View.getViewSpecies    viewName: " + viewName);
	if ( projectName == null || ! projectName )
	{
		//console.log("Agua.View.getViewSpecies     projectName is null or empty. Returning");
		return;
	}

	var viewfeatures = this.getViewFeatures(projectName, viewName);
	if ( viewfeatures == null || viewfeatures.length == 0 )	return new Array;

	var speciesHash = new Object;
	speciesHash.species = viewfeatures[0].species;
	speciesHash.build = viewfeatures[0].build;

	return speciesHash;
},
getViewProjects : function () {
	//console.log("Agua.View.getViewProjects     plugins.core.Data.getViewProjects()");
	//console.log("Agua.View.getViewProjects     CAUTION -- ONLY PROJECTS WITH FEATURES");
	var viewfeatures = this.cloneData("viewfeatures");
	var projects = this.hashArrayKeyToArray(viewfeatures, "project");
	projects = this.uniqueValues(projects);
	
	return projects;
},
getSpeciesBuilds : function () {
// GET THE UNIQUE SPECIES/BUILD COMBINATIONS FOR ALL FEATURES
	//console.log("Agua.View.getSpeciesBuilds     plugins.core.Data.getSpeciesBuilds()");
	var features = this.cloneData("features");
	var speciesBuilds = new Array;
	for ( var i = 1; i < features.length; i++ )
	{
		speciesBuilds.push(	features[i].species + "(" + features[i].build + ")");
	}
	speciesBuilds = this.uniqueValues(speciesBuilds);
	//console.log("Agua.View.getSpeciesBuilds     speciesBuilds: " + dojo.toJson(speciesBuilds));
	
	return speciesBuilds;
},
getSpecies : function (projectName, viewName) {
	//console.log("Agua.View.getSpecies     plugins.core.Data.getSpecies(projectName, viewName)");
	//console.log("Agua.View.getSpecies     projectName: " + projectName);
	//console.log("Agua.View.getSpecies     viewName: " + viewName);
	var views = this.cloneData("views");
	views = this.filterByKeyValues(views, ["project", "view"], [projectName, viewName]);
	//console.log("Agua.View.getSpeciesBuilds     views: " + dojo.toJson(views));
	
	if ( views == null || views.length == 0 )	return;
	return views[0].species;
},
getBuild : function (projectName, viewName) {
	//console.log("Agua.View.getBuild     plugins.core.Data.getBuild(projectName, viewName)");
	//console.log("Agua.View.getBuild     projectName: " + projectName);
	//console.log("Agua.View.getBuild     viewName: " + viewName);
	var views = this.cloneData("views");	
	views = this.filterByKeyValues(views, ["project", "view"], [projectName, viewName]);
	//console.log("Agua.View.getBuildBuilds     views: " + dojo.toJson(views));
	
	if ( views == null || views.length == 0 )	return;
	return views[0].build;
}

});

}

if(!dojo._hasResource["plugins.core.Agua.Workflow"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua.Workflow"] = true;
dojo.provide("plugins.core.Agua.Workflow");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	WORKFLOW METHODS  
*/

dojo.declare( "plugins.core.Agua.Workflow",	[  ], {

/////}}}

// 	WORKFLOW METHODS
getWorkflows : function () {
// RETURN A SORTED COPY OF workflows
	//console.log("Agua.Workflow.getWorkflows    plugins.core.Data.getWorkflows(workflowObject)");
	var workflows = this.cloneData("workflows");
	return this.sortHasharray(workflows, "name");
},
getWorkflowNamesByProject : function (projectName) {
// RETURN AN ARRAY OF NAMES OF WORKFLOWS IN THE SPECIFIED PROJECT
	//console.log("Agua.Workflow.getWorkflowNamesByProject    plugins.core.Data.getWorkflowNamesByProject(projectName)");
	//console.log("Agua.Workflow.getWorkflowNamesByProject    projectName: " + projectName);
	var workflows = this.getWorkflowsByProject(projectName);
	//console.log("Agua.Workflow.getWorkflowNamesByProject    workflows: " + dojo.toJson(workflows));

	// ORDER BY WORKFLOW NUMBER -- NB: REMOVES ENTRIES WITH NO WORKFLOW NUMBER
	workflows = this.sortNumericHasharray(workflows, "number");	

	return this.hashArrayKeyToArray(workflows, "name");
},
getWorkflowsByProject : function (projectName) {
// RETURN AN ARRAY OF WORKFLOWS IN THE SPECIFIED PROJECT
	//console.log("Agua.Workflow.getWorkflowsByProject    plugins.core.Data.getWorkflowsByProject(projectName)");
	//console.log("Agua.Workflow.getWorkflowsByProject    projectName: " + projectName);
	var workflows = this.cloneData("workflows");
	return this.filterByKeyValues(workflows, ["project"], [projectName]);
},
getWorkflow : function (workflowObject) {
// RETURN FULL workflow OBJECT IF WORKFLOW IN PROJECT
	console.log("Agua.Workflow.getWorkflow     plugins.core.Data.getWorkflow(workflowObject)");
	console.log("Agua.Workflow.getWorkflow     workflowObject: ");
	console.dir({workflowObject:workflowObject});
	
	var object = this._getWorkflow(workflowObject);
	if ( ! object )
	{
		console.log("Agua.Workflow.getWorkflow     No workflowObject.name " + workflowObject.name + " found. Returning");
		return null;
	}
	console.log("Agua.Workflow.getWorkflow     object.name: " + object.name);
	console.log("Agua.Workflow.getWorkflow     object: ");
	console.dir({object:object});

	return object;
},
_getWorkflow : function (workflowObject) {
// RETURN WORKFLOW IN workflows IDENTIFIED BY PROJECT AND WORKFLOW NAMES
	console.log("Agua.Workflow._getWorkflow     plugins.core.Data._getWorkflow(workflowObject)");
	console.log("Agua.Workflow._getWorkflow     workflowObject: " + dojo.toJson(workflowObject));
	
	if ( ! this.isProject(workflowObject.project) )
	{
		console.log("Agua.Workflow._getWorkflow     No project found in workflowObject. Returning false.");
		return false;
	}
	
	// GET ALL WORKFLOWS
	var workflows = this.getWorkflows();
	//console.log("Agua.Workflow._getWorkflow     workflows: " + dojo.toJson(workflows));		
	if ( workflows == null ) 
	{
		console.log("Agua.Workflow._getWorkflow     workflows is null. Returning false.");
		return false;
	}
	
	// CHECK FOR OUR PROJECT AND WORKFLOW NAME AMONG WORKFLOWS
	var keyArray = ["project", "name"];
	var valueArray = [ workflowObject.project, workflowObject.name ];
	var workflows = this.filterByKeyValues(workflows, keyArray, valueArray);
	
	if ( ! workflows || workflows.length == 0 )	return;

	return workflows[0];
},
isWorkflow : function (workflowObject) {
// RETURN TRUE IF WORKFLOW NAME IS FOUND IN PROJECT IN workflows
	console.log("Agua.Workflow.isWorkflow     caller: " + this.isWorkflow.caller.nom);
	//console.log("Agua.Workflow.isWorkflow     workflowObject: ");
	//console.dir({workflowObject:workflowObject});
	var object = this._getWorkflow(workflowObject);
	if ( ! object ) {
		console.log("Agua.Workflow.isWorkflow     Returning false");
		return false;
	}
	
	console.log("Agua.Workflow.isWorkflow     Returning true");
	return true;		
},
getWorkflowNumber : function (projectName, workflowName) {
// WORKFLOW NUMBER GIVEN PROJECT AND WORKFLOW IN workflows
	//console.log("Agua.Workflow.getWorkflowNumber     plugins.core.Data.getWorkflowNumber(projectName, workflowName)");
	//console.log("Agua.Workflow.getWorkflowNumber     projectName: " + projectName);
	//console.log("Agua.Workflow.getWorkflowNumber     workflowName: " + workflowName);
	var workflowObject = this._getWorkflow({ project: projectName, name: workflowName });
	if ( ! workflowObject ) return null;
	console.log("Agua.Workflow.getWorkflowNumber    workflowObject:");
	console.dir({workflowObject:workflowObject});

	return workflowObject.number;
},
getMaxWorkflowNumber : function (projectName) {
// WORKFLOW NUMBER GIVEN PROJECT AND WORKFLOW IN workflows
	console.log("Agua.Workflow.getMaxWorkflowNumber     plugins.core.Data.getMaxWorkflowNumber(projectName)");
	console.log("Agua.Workflow.getMaxWorkflowNumber     projectName: " + projectName);
	
	var workflowObjects = this.getWorkflowsByProject(projectName);
	//console.log("Agua.Workflow.getMaxWorkflowNumber     workflowObject: " + dojo.toJson(workflowObjects));		
	if ( workflowObjects == null ) return null;
	if ( workflowObjects.length == 0 ) return null;

	console.log("Agua.Workflow.getMaxWorkflowNumber     Returning workflowObjects.length: " + workflowObjects.length);
	return workflowObjects.length;
},
moveWorkflow : function (workflowObject, newNumber) {
// MOVE A WORKFLOW WITHIN A PROJECT
	console.log("Agua.Workflow.moveWorkflow    workflowObject: " + dojo.toJson(workflowObject, true));	
	//console.log("Agua.Workflow.moveWorkflow    newNumber: " + newNumber);

	var oldNumber = workflowObject.number;
	if ( oldNumber == null )	return false;
	if ( oldNumber == newNumber )	return false;
	//console.log("Agua.Workflow.moveWorkflow    oldNumber: " + oldNumber);
	
	// GET ACTUAL WORKFLOWS DATA
	var workflows = this.getData("workflows");
	//console.log("Agua.Workflow.moveWorkflow     UNSORTED workflows: " + dojo.toJson(workflows));

	// ORDER BY WORKFLOW NUMBER -- NB: REMOVES ENTRIES WITH NO WORKFLOW NUMBER
	workflows = this.sortNumericHasharray(workflows, "number");	
	for ( var i = 0; i < workflows.length; i++ )
	{
		if ( workflows[i].project != projectName )	continue;
		counter++;
	}

	// DO RENUMBER
	var projectName = workflowObject.project;
	var counter = 0;
	for ( var i = 0; i < workflows.length; i++ )
	{
		if ( workflows[i].project != projectName )	continue;
		counter++;

		// SKIP IF BEFORE REORDERED WORKFLOWS
		if ( counter < oldNumber && counter < newNumber )
		{
			workflows[i].number = counter;
		}
		// IF WORKFLOW HAS BEEN MOVED DOWNWARDS, GIVE IT THE NEW INDEX
		// AND DECREMENT COUNTER FOR SUBSEQUENT WORKFLOWS
		else if ( oldNumber < newNumber ) {
			if ( counter == oldNumber ) {
				workflows[i].number = newNumber;
			}
			else if ( counter <= newNumber ) {
				workflows[i].number = counter - 1;
			}
			else {
				workflows[i].number = counter;
			}
		}
		// OTHERWISE, THE WORKFLOW HAS BEEN MOVED UPWARDS SO GIVE IT
		// THE NEW INDEX AND INCREMENT COUNTER FOR SUBSEQUENT WORKFLOWS
		else {
			if ( counter < oldNumber ) {
				workflows[i].number = counter + 1;
			}
			else if ( oldNumber == counter ) {
				workflows[i].number = newNumber;
			}
			else {
				workflows[i].number = counter;
			}
		}
	}
	
	var query = workflowObject;
	query.newnumber = newNumber;
	query.mode = "moveWorkflow";
	query.username = Agua.cookie("username");
	query.sessionId = Agua.cookie("sessionId");
	var url = Agua.cgiUrl + "workflow.cgi";
	this.doPut({ url: url, query: query, sync: false });
},
renumberWorkflows : function(projectName) {
	console.log("Agua.Workflow.renumberWorkflows     plugins.core.Data.renumberWorkflows(projectName)");
	console.log("Agua.Workflow.renumberWorkflows     projectName: " + projectName);
	var workflows = this.getWorkflowsByProject(projectName);
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);

	this.printObjectKeys(workflows, "number", "UNSORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);
	this.printObjectKeys(workflows, "name", "UNSORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);

	workflows = this.sortHasharrayByKeys(workflows, ["number"]);
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);		

	this.printObjectKeys(workflows, "number", "SORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);
	this.printObjectKeys(workflows, "name", "SORTED workflows");
	console.log("Agua.Workflow.renumberWorkflows     workflows.length: " + workflows.length);

	// DO RENUMBER
	console.log("Agua.Workflow.renumberWorkflows     RENUMBERING workflows");
	var number = 0;
	for ( var i = 0; i < workflows.length; i++ )
	{
		console.log("Agua.Workflow.renumberWorkflows     REMOVING workflow [" + i + "].number: " + workflows[i].number);
		this._removeWorkflow(workflows[i]);
		number++;
		workflows[i].number = number;
		console.log("Agua.Workflow.renumberWorkflows     ADDING workflows [" + i + "].number: " + workflows[i].number);
		this._addWorkflow(workflows[i]);
	}

	workflows = this.getWorkflowsByProject(projectName);
	console.log("Agua.Workflow.renumberWorkflows     BEFORE FILTER workflows.length: " + workflows.length);
	workflows = this.filterByKeyValues(workflows, ["project"], [projectName]);
	console.log("Agua.Workflow.renumberWorkflows     AFTER FILTER workflows.length: " + workflows.length);

},
addWorkflow : function (workflowObject) {
// ADD AN EMPTY NEW WORKFLOW OBJECT TO A PROJECT OBJECT
	console.log("Agua.Workflow.addWorkflow    plugins.workflow.Agua.addWorkflow(workflowObject)");
	console.log("Agua.Workflow.addWorkflow    workflowObject: " + dojo.toJson(workflowObject));
	
	var projectName = workflowObject.project;
	var workflowName = workflowObject.name;
	if ( this.isWorkflow(workflowObject)== true )
	{
		console.log("Agua.Workflow.addWorkflow    Workflow '" + workflowName + "' already exists in project '" + projectName + "'. Returning.");
		return;
	}

    // SET THE WORKFLOW NUMBER
	var maxNumber = this.getMaxWorkflowNumber(projectName);
    console.log("Agua.Workflow.addWorkflow    maxNumber: " + maxNumber);

	var number;
	if ( maxNumber == null )
		number = 1;
	else
		number = maxNumber + 1;
	workflowObject.number = number;
    console.log("Agua.Workflow.addWorkflow    workflowObject.number: " + workflowObject.number);

	var added = this._addWorkflow(workflowObject);
	if ( added == false )
	{
		console.log("Agua.Workflow.addWorkflow    Could not add workflow " + workflowName + " to workflows");
		return;
	}
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = new Object;
	query.project = projectName;
	query.name = workflowName;
	query.number = number;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "addWorkflow";
	console.log("Agua.Workflow.addWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });
},
_addWorkflow : function(workflowObject) {
	var keys = ["project", "name", "number"];
	var added = this.addData("workflows", workflowObject, keys);
},
removeWorkflow : function (workflowObject) {
// REMOVE A WORKFLOW FROM workflows, stages AND stageparameters

	console.log("Agua.Workflow.removeWorkflow    caller: " + this.removeWorkflow.caller.nom);
	console.log("Agua.Workflow.removeWorkflow    workflowObject: " + dojo.toJson(workflowObject));

	// REMOVE WORKFLOW
	this._removeWorkflow(workflowObject);
	
	// RENUMBER WORKFLOWS
	this.renumberWorkflows(workflowObject.project);
	
	// COMMIT CHANGES IN REMOTE DATABASE
	var url 		= Agua.cgiUrl + "workflow.cgi";
	var query 		= new Object;
	query.project 	= workflowObject.project;
	query.name 		= workflowObject.name;
	query.number 	= workflowObject.number;
	query.username 	= this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode 		= "removeWorkflow";
	console.log("Agua.Workflow.removeWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });
},
_removeWorkflow : function(workflowObject) {
// REMOVE FROM workflows, stages, ETC.
	console.log("Agua.Workflow._removeWorkflow    BEFORE delete workflows.length: " + this.getWorkflows().length);

	var keys = ["project", "number", "name"];
	var result = this.removeData("workflows", workflowObject, keys);

	console.log("Agua.Workflow._removeWorkflow    delete result: " + result);
	console.log("Agua.Workflow._removeWorkflow    AFTER delete workflows.length: " + this.getWorkflows().length);
	
	// REMOVE FROM stages, stageparameters AND views
	workflowObject.workflow = workflowObject.name;
	keys = ["project", "workflow"];
	this.removeObjectsFromData("stages", workflowObject, keys);
	this.removeObjectsFromData("stageparameters", workflowObject, keys);

},
renameWorkflow : function (workflowObject, newName, callback, standby) {
// RENAME A WORKFLOW FROM workflows, stages AND stageparameters
	console.log("Agua.Workflow.renameWorkflow    plugins.core.Data.renameWorkflow(workflowObject, newName)");
	console.log("Agua.Workflow.renameWorkflow    workflowObject: " + dojo.toJson(workflowObject));
	console.log("Agua.Workflow.renameWorkflow    newName: " + newName);
	console.log("Agua.Workflow.renameWorkflow    callback: " + callback);

	if ( workflowObject.name == null )	return;
	if ( workflowObject.project == null )	return;
	if ( newName == null )	return;

	// COPY WORKFLOW DATA TO NEW WORKFLOW NAMES
	var username = this.cookie("username");
	var date = this.currentMysqlDate();
	this._copyWorkflow(workflowObject, username, workflowObject.project, newName, date, workflowObject.number);
	
	// DELETE OLD WORKFLOW
	this._removeWorkflow(workflowObject);

	// COMMIT CHANGES IN REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = new Object;
	query.project = workflowObject.project;
	query.name = workflowObject.name;
	query.newname = newName;
	query.username = this.cookie("username");
	query.sessionId = this.cookie("sessionId");
	query.mode = "renameWorkflow";
	console.log("Agua.Workflow.renameWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false, callback: callback });
},
copyWorkflow : function (sourceUser, sourceProject, sourceWorkflow, targetUser, targetProject, targetWorkflow, copyFiles) {
// ADD AN EMPTY NEW WORKFLOW OBJECT TO A PROJECT OBJECT
	console.log("Agua.Workflow.copyWorkflow    plugins.workflow.Agua.copyWorkflow(sourceUser, sourceProject, sourceWorkflow, targetUser, targetProject, targetWorkflow)");
	console.log("Agua.Workflow.copyWorkflow    sourceUser: " + sourceUser);
	console.log("Agua.Workflow.copyWorkflow    sourceProject: " + sourceProject);
	console.log("Agua.Workflow.copyWorkflow    sourceWorkflow: " + sourceWorkflow);
	console.log("Agua.Workflow.copyWorkflow    targetUser: " + targetUser);
	console.log("Agua.Workflow.copyWorkflow    targetProject: " + targetProject);
	console.log("Agua.Workflow.copyWorkflow    targetWorkflow: " + targetWorkflow);
	console.log("Agua.Workflow.copyWorkflow    copyFiles: " + copyFiles);

	if ( this.isWorkflow({ project: targetProject, name: targetWorkflow })== true )
	{
		console.log("Agua.Workflow.copyWorkflow    Workflow " + targetWorkflow + " already exists in project " + targetProject + ". Returning FALSE.");
		return false;
	}

	var workflows = this.getSharedWorkflowsByProject(sourceUser, sourceProject);
	workflows = this.filterByKeyValues(workflows, ["name"], [sourceWorkflow]);
	if ( ! workflows || workflows.length == 0 ) {
		console.log("Agua.Workflow.copyWorkflow    Returning because workflows is not defined or empty");
		return;
	}
	var workflowObject = workflows[0];
	
	// ADD STAGES, STAGEPARAMETERS, REPORTS AND VIEWS	
	var date = this.currentMysqlDate();
	var success = this._copyWorkflow(workflowObject, targetUser, targetProject, targetWorkflow, date);
	if ( success == false )	{
		console.log("Agua.Workflow.copyWorkflow    Failed to copy workflow: " + dojo.toJson(workflowObject));
		return false;
	}	

	// SET PROVENANCE
	workflowObject = this.setProvenance(workflowObject, date);

	// COMMIT CHANGES TO REMOTE DATABASE
	var url = Agua.cgiUrl + "workflow.cgi";
	var query = new Object;
	query.sourceuser 		= sourceUser;
	query.targetuser 		= targetUser;
	query.sourceworkflow 	= sourceWorkflow;
	query.sourceproject 	= sourceProject;
	query.targetworkflow 	= targetWorkflow;
	query.targetproject 	= targetProject;
	query.copyfiles 		= copyFiles;
	query.date				= date;
	query.provenance 		= workflowObject.provenance;
	query.username 			= this.cookie("username");
	query.sessionId 		= this.cookie("sessionId");
	query.mode 				= "copyWorkflow";
	console.log("Agua.Workflow.copyWorkflow    query: " + dojo.toJson(query, true));

	this.doPut({ url: url, query: query, sync: false });

	return success;
},
_copyWorkflow : function (workflowObject, targetUser, targetProject, targetWorkflow, date, workflowNumber) {
// COPY WORKFLOW AND THEN ADD STAGES, STAGEPARAMETERS, REPORTS AND VIEWS	
	console.log("XXXXXXXXXXXX Data._copyWorkflow    Data._copyWorkflow(sourceUser, sourceProject, sourceWorkflow, targetUser, targetProject, targetWorkflow, copyFiles, workflowNumber)");
	console.log("Agua.Workflow._copyWorkflow    BEFORE workflowObject: " + dojo.toJson(workflowObject));
	console.dir({workflowObject:workflowObject});
	console.log("Agua.Workflow._copyWorkflow    BEFORE workflowObject.name: " + workflowObject.name);
	console.log("Agua.Workflow._copyWorkflow    targetUser: " + targetUser);
	console.log("Agua.Workflow._copyWorkflow    targetProject: " + targetProject);
	console.log("Agua.Workflow._copyWorkflow    targetWorkflow: " + targetWorkflow);
	console.log("Agua.Workflow._copyWorkflow    date: " + date);

	// GET SOURCE DATA
	var sourceUser = workflowObject.username;
	var sourceWorkflow = workflowObject.name;
	var sourceProject = workflowObject.project;
	console.log("Agua.Workflow._copyWorkflow    sourceWorkflow: " + sourceWorkflow);
	
	// SET PROVENANCE
	workflowObject = this.setProvenance(workflowObject, date);
	
	// SET TARGET DATA
	var maxNumber = this.getMaxWorkflowNumber(targetProject);
	var number;
	if ( workflowNumber ) {
		number = workflowNumber;
	}
	else {
		if ( ! maxNumber )
			number = 1;
		else
			number = maxNumber + 1;
	}
	
	var newObject = dojo.clone(workflowObject);
	newObject.name = targetWorkflow;
	newObject.project = targetProject;
	newObject.username = targetUser;
	newObject.number = number;
	console.log("Agua.Workflow._copyWorkflow    AFTER newObject: ");
	console.dir({newObject:newObject});
	console.dir({workflowObject:workflowObject});
	
	// COPY WORKFLOW
	var keys = ["project", "name", "number"];
	var copied = this.addData("workflows", newObject, keys);
	if ( copied == false ) {
		console.log("Agua.Workflow._copyWorkflow    Could not copy workflow to targetWorkflow: " + targetWorkflow);
		return false;
	}

	// COPY STAGES AND STAGE PARAMETERS
	var stages;
	if ( sourceUser != targetUser )
		stages = this.getSharedStagesByWorkflow(sourceUser, sourceProject, sourceWorkflow);
	else stages = this.getStagesByWorkflow(sourceProject, sourceWorkflow);
	console.log("Agua.Workflow._copyWorkflow    stages.length: " + stages.length);

	for ( var i = 0; i < stages.length; i++ )
	{
	 	console.log("Agua.Workflow._copyWorkflow    stages[" + i + "]: " + stages[i]);
		var newStage = dojo.clone(stages[i]);
		newStage.project = targetProject;
		newStage.workflow = targetWorkflow;
		
		this._addStage(newStage);

		// ADD STAGE PARAMETERS
		var stageparams;
		if ( sourceUser != targetUser )
			stageparams = this.getSharedStageParameters(stages[i]);
		else stageparams = this.getStageParameters(stages[i]);
		
		console.log("Agua.Workflow._copyWorkflow    stageparams.length: " + stageparams.length);
		var thisObject = this;
		var oldPath = sourceProject + "/" + sourceWorkflow;
		var newPath = targetProject + "/" + targetWorkflow;
		dojo.forEach(stageparams, function(stageparam, j){
			stageparams[j].project = targetProject;
			stageparams[j].workflow = targetWorkflow;
		
			// REPLACE FILE PATH WITH NEW Project/Workflow
			if ( stageparams[j].value != null
				&& stageparams[j].value.replace )
				stageparams[j].value = stageparams[j].value.replace(oldPath, newPath);
			
			thisObject._addStageParameter(stageparams[j]);
		})
	}

	// COPY VIEWS
	var views = this.getSharedViews({ username: sourceUser, project: sourceProject } );
    if ( views == null )
        views = [];
	//console.log("Agua.Workflow._copyWorkflow    view: " + dojo.toJson(views));
	for ( var i = 0; i < views.length; i++ )
	{
		this._addStage(views[i]);
	}

	//console.log("Agua.Workflow._copyWorkflow    views: " + dojo.toJson(views));
	return true;
},
getWorkflowSubmit : function (workflowObject) {
	if ( ! workflowObject )	return;

	var submit = 0;	
	var stages = this.getStagesByWorkflow(workflowObject.project, workflowObject.workflow);
	if ( ! stages )	return 1;
	
	for ( var i = 0; i < stages.length; i++ ) {
		if ( stages[i].submit == 1 )	return 1;
	}
	
	return 0;
},
// PROVENANCE METHODS
setProvenance : function (object, date) {
	var provenanceString = object.provenance;
	var provenance;
	if ( ! provenanceString )
		provenance = [];
	else
		provenance = dojo.fromJson(provenanceString);
	
	if ( ! date ) date = this.currentMysqlDate();
	var item = {
		copiedby : Agua.cookie("username"),
		original: dojo.clone(object),
		date: date
	};
	
	provenance.push(item);
	provenanceString = dojo.toJson(provenance);
	
	object.provenance = provenanceString;
	
	return object;
}

});

}

if(!dojo._hasResource["plugins.core.Plugin"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Plugin"] = true;
dojo.provide("plugins.core.Plugin");

/**
 * PLUGIN FRAMEWORK, Version 0.1
 * Copyright (c) 2012 Stuart Young youngstuart@hotmail.com
 * This code is freely distributable under the terms of an MIT-style license.
 * 
 *  This code provides the following functions
 *
 *    Plugin.isInstalled(String name)           // RETURN Boolean PLUGIN INSTALL STATUS
 *    Plugin.getVersion(String name)            // RETURN PLUGIN VERSION
 *    Plugin.getDescription(String name)        // RETURN PLUGIN DESCRIPTION
 *    Plugin.getPluginPage(String name)         // RETURN PLUGIN URL
 *    Plugin.getInfo(String name)               // RETURN PLUGIN INFO (NAME, VERSION, DESCRIPTION, IS INSTALLED)
 *
 *        Boolean isInstalled
 *        String  version
 *        String  description
 *        String  pluginPage   URL to download the plugin
 *
 * CHANGELOG:
 * Sat 18th October 2008: Version 0.1
 *   load plugins
 *   load plugins
 *   added license
 * 
 * you may remove the comments section, but please leave the copyright
/*--------------------------------------------------------------------*/

// OBJECT:  Plugin
// PURPOSE: ATTEMPT TO LOAD A PLUGIN USING dojo.require AND STORE
//			WHETHER THE LOAD WAS SUCCESSFUL OR NOT AS installed=BOOLEAN

dojo.declare( "plugins.core.Plugin", null, {

installed : false,

////}}}}

setInstalled : function () {
	if ( this.installed != false && installed != true )
		return 0;
	this.installed = true;

	return 1;
},

getInstalled : function () {
	return this.installed;    
},

getVersion : function () {
	return this.version;
},

getDescription : function () {
	return this.description;
},

getPluginUrl : function () {
	return this.pluginUrl;
},

getInfo : function () {
	var info = '';
	info += 'Status: ';
	info += this.getInstalled();
	info += '\n';
	info += 'Version: ';
	info += this.version();
	info += '\n';
	info += 'Description: ';
	info += this.description();
	info += '\n';
	info += 'Plugin Url: ';
	info += this.pluginUrl();
	info += '\n';
	
	return info;
}

});    
    

}

if(!dojo._hasResource["plugins.core.PluginManager"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.PluginManager"] = true;
/**
 * CLASS  	PluginManager
 * Version 	0.01
 * PURPOSE 	MANAGE EXTERNAL PLUGINS ON TOP OF dojo FRAMEWORK
 * LICENCE 	Copyright (c) 2012 Stuart Young youngstuart@hotmail.com
 *          This code is freely distributable under the terms of an MIT-style license.
*/

dojo.provide("plugins.core.PluginManager");



// OBJECT:  PluginManager
// PURPOSE: LOAD ALL PLUGINS

dojo.declare( "plugins.core.PluginManager", null,
{
// HASH OF INSTALLED PLUGINS
_installedPlugins : {},
plugins : [],

parentWidget : null,

////}}}}
	
constructor : function(args) {
	//console.log("PluginManager.constructor      plugins.core.PluginManager.constructor(args)");
	
	// SET INPUT PLUGINS LIST IF PROVIDED
	if ( args.pluginsList != null && args.pluginsList )
		this.pluginsList = args.pluginsList;

	// SET PARENT WIDGET IF PROVIDED
	if ( args.parentWidget != null && args.parentWidget )
		this.parentWidget = args.parentWidget;
	
	// SAVE TO controllers
	Agua.controllers["core"] = Agua;

	// LOAD PLUGINS
	this.loadPlugins();
},
loadPlugins : function ()   {
	console.group("PluginManager.loadPlugins    this.pluginsList: ");
	console.dir({this_pluginsList:this.pluginsList});
	
	var length = this.pluginsList.length;
	if ( ! length )	return;
	var doubleLength = 2 * length;
	
	for ( var i = 0; i < this.pluginsList.length; i++ )
	{
		var number = parseInt( (i * 2) + 1);
		this.percentProgress(doubleLength, number);
		console.log("PluginManager.loadPlugins    ******* plugin number" + number);
	
		var pluginName = this.pluginsList[i];
		console.log("PluginManager.loadPlugins     this.pluginsList[" + i + "]:  " + pluginName);

		var moduleName = pluginName.match(/^plugins\.([^\.]+)\./)[1];
		//console.log("PluginManager.loadPlugins    moduleName: " + dojo.toJson(moduleName));
		//console.log("PluginManager.loadPlugins    pluginName: " + dojo.toJson(pluginName));
 
		// LOAD MODULE
		dojo["require"](pluginName);
		
		// INSTANTIATE WIDGET
		var newPlugin = eval ("new " + pluginName + "()");

		// SAVE TO controllers
		Agua.controllers[moduleName] = newPlugin;
		
		//// CHECK DEPENDENCIES
		var verified = this.checkDependencies(newPlugin.dependencies);
		//console.log("PluginManager.loadPlugins    verified: " + verified);
		
		var number = parseInt( (i * 2) + 2);
		//console.log("PluginManager.loadPlugins    ooooooooooooooooo plugin number" + number);
		this.percentProgress(doubleLength, number);
	}

	console.log("PluginManager.loadPlugins    	FINAL Agua.data: " + Agua.data);
},
percentProgress : function (total, current) {
	//console.log("PluginManager.percentProgress    	" + current + " out of " + total);
	
	var percent = 0;
	if ( total == current )
		percent = 100;
	else
		percent = parseInt((current/total) * 100);

	console.log("PluginManager.percentProgress    percent: " + percent);
	//console.log("PluginManager.percentProgress    Agua.login:");
	//console.dir({agua_loginController:Agua.login});
	if ( ! Agua.login )	return;
	
	Agua.login.progressBar.set({value:percent, progress:percent})
},
checkDependencies : function (dependencies) {
	// CHECK DEPENDENCIES ARE ALREADY LOADED AND CORRECT VERSION
	//console.log("PluginManager.checkDependencies    plugins.core.PluginManager.checkDependencies");
	//console.dir({installedPlugins:this._installedPlugins});
	//console.log("PluginManager.checkDependencies    this._installedPlugins: " + dojo.toJson(this._installedPlugins));
	
	// DEBUG
	return 1;
	
	if ( ! dependencies )	{	return 1;	}
	
	//console.log("PluginManager.checkDependencies     dependencies is defined");
	//console.log("PluginManager.checkDependencies     dependencies: " + dojo.toJson(dependencies));	
	
	for ( var i = 0; i < dependencies.length; i++ )
	{
		//console.log("PluginManager.checking dependencies[" + i + "]: " + dojo.toJson(dependencies[i]));
		var requiredName = dependencies[i].name;
		var requiredVersion = dependencies[i].version;
		//console.log("PluginManager.requiredName: " + requiredName);

		// CHECK DEPENDENCY CLASS IS LOADED
		if ( requiredName )
		{
			////console.log("PluginManager.Dependency is loaded: " + requiredName);                
			////console.log("PluginManager.this._installedPlugins.length: " + this._installedPlugins.length);
			//console.dir({installedPlugins:this.installedPlugins});


			var dependency = Agua.controllers[requiredName];


			//var dependency = this._installedPlugins[requiredName];

			////console.log("PluginManager.dependency: " + dojo.toJson(dependency));
			
			// CHECK VERSION IS MINIMUM OR GREATER
			if ( dependency.version >= requiredVersion  )    
			{        
				// CHECK THAT THE DEPENDENCY ACTUALLY INSTALLED OKAY
				if ( ! dependency.installed )
				{
					//console.log("PluginManager.checkDependencies     Required dependency is not installed: " + requiredName + ". Dependency is present but dependency.installed is false");
					return 0;
				}
				else
				{
					////console.log("PluginManager.Required dependency is installed: " + requiredName);
				}
			}
			else
			{
				//console.log("PluginManager.checkDependencies     Actual dependency '" + requiredName + "' version (" + dependency.version + ") < required version (" + requiredVersion + ")");
				return 0;
			}
		}
		else
		{
			//console.log("PluginManager.checkDependencies     Required dependency is not loaded:" + requiredName);
			return 0;
		}
	}
	
	//console.log("PluginManager.checkDependencies     Dependencies satisfied"); 
	return 1;        
},

getInstalledPlugins : function ()   {
// RETURN HASH OF INSTALLED PLUGINS
	return this._installedPlugins;
}

});

// end of PluginManager

}



if(!dojo._hasResource["plugins.core.Agua"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Agua"] = true;
dojo.provide("plugins.core.Agua");

/*	PURPOSE

		1. PROVIDE INTERFACE WITH Agua DATA OBJECT REPRESENTATION
	
			OF THE DATA MODEL ON THE REMOTE SERVER

		2. PROVIDE METHODS TO CHANGE/INTERROGATE THE DATA OBJECT

		3. CALLS TO REMOTE SERVER TO REFLECT CHANGES ARE MOSTLY THE

			RESPONSIBILITY OF THE OBJECT USING THE Agua CLASS
	
	NOTES
	
		LOAD DATA WITH getData()
			
		LOAD PLUGINS WITH loadPlugins()
			- new pluginsManager
				- new Plugin PER MODULE
					- Plugin.loadPlugin CHECKS DEPENDENCIES AND LOADS MODULE
	
*/
if ( 1 ) {
// EXTERNAL MODULES






// INTERNAL MODULES
// INHERITS


//dojo.require("plugins.core.loadAgua");

//dojo.require("plugins.core.Agua.Data");
//dojo.require("plugins.core.Agua.Admin");
//dojo.require("plugins.core.Agua.App");
//dojo.require("plugins.core.Agua.Aws");
//dojo.require("plugins.core.Agua.Cluster");
//dojo.require("plugins.core.Agua.Feature");
//dojo.require("plugins.core.Agua.File");
//dojo.require("plugins.core.Agua.Group");
//dojo.require("plugins.core.Agua.Hub");
//dojo.require("plugins.core.Agua.Package");
//dojo.require("plugins.core.Agua.Parameter");
//dojo.require("plugins.core.Agua.Project");
//dojo.require("plugins.core.Agua.Report");
//dojo.require("plugins.core.Agua.Shared");
//dojo.require("plugins.core.Agua.Sharing");
//dojo.require("plugins.core.Agua.Source");
//dojo.require("plugins.core.Agua.Stage");
//dojo.require("plugins.core.Agua.StageParameter");
//dojo.require("plugins.core.Agua.User");
//dojo.require("plugins.core.Agua.View");
//dojo.require("plugins.core.Agua.Workflow");	
//


}
dojo.declare( "plugins.core.Agua",
[
	dijit._Widget,
	dijit._Templated
	,
	plugins.core.Common
	,
	plugins.core.Agua.Data
	,
	plugins.core.Agua.Admin,
	plugins.core.Agua.App,
	plugins.core.Agua.Aws,
	plugins.core.Agua.Cluster,
	plugins.core.Agua.Feature,
	plugins.core.Agua.File,
	plugins.core.Agua.Group,
	plugins.core.Agua.Hub,
	plugins.core.Agua.Package,
	plugins.core.Agua.Parameter,
	plugins.core.Agua.Project,
	plugins.core.Agua.Report,
	plugins.core.Agua.Shared,
	plugins.core.Agua.Sharing,
	plugins.core.Agua.Source,
	plugins.core.Agua.Stage,
	plugins.core.Agua.StageParameter,
	plugins.core.Agua.User,
	plugins.core.Agua.View,
	plugins.core.Agua.Workflow
], {
name : "plugins.core.Agua",
version : "0.01",
description : "Create widget for positioning Plugin buttons and tab container for displaying Plugin tabs",
url : '',
dependencies : [],

// PLUGINS TO LOAD (NB: ORDER IS IMPORTANT FOR CORRECT LAYOUT)
pluginsList : [
	"plugins.data.Controller"
	, "plugins.files.Controller"
	, "plugins.admin.Controller"
	, "plugins.sharing.Controller"
	, "plugins.folders.Controller"
	, "plugins.workflow.Controller"
	, "plugins.view.Controller"
	, "plugins.home.Controller"
],

//Path to the template of this widget. 
templateString:"<div dojoAttachPoint=\"containerNode\">\n\n\t<div\n\t\tdojoAttachPoint=\"controls\"\n\t\tclass=\"controls\"\n\t\tstyle=\"min-height: 100% !important; min-width: 100% !important;\"\t\t\n\t>\n\n\t\t<div\n            dojoAttachPoint=\"toolbar\"\n            dojoType=\"dijit.Toolbar\"\n            class=\"toolbar\"\n        >\n        </div>\n\n\t\t<div\n\t\t\tdojoAttachPoint=\"tabs\"\n\t\t\tdojoType=\"dijit.layout.TabContainer\"\n\t\t\tclass=\"tabs\"\n\t\t\tuseSlider=\"false\"\n\t\t\ttabPosition=\"top\"\n\t\t\ttabStrip=\"false\"\n\t\t\tstyle=\"position: relative; top: 0px; left: 0px; height: 100% !important; min-height: 850px !important; width: 1200px !important; min-width: 100% !important; right: auto; bottom: auto;\"\n\t\t>\n\t\t</div>\n\t\n<!--\t\t<div\n\t\t\tdojoAttachPoint=\"toaster\"\n\t\t\tdojoType=\"dojox.widget.Toaster\"\n\t\t\tclass=\"toaster\" \n\t\t\tpositionDirection=\"bl-right\"\n\t\t\tduration=\"500\" \n\t\t\tmessageTopic=\"toastTopic\"\n\t\t></div> \n-->\t\t\n\t</div>\n\t\n\t<div dojoAttachPoint=\"fileManagerNode\"></div>\n\n</div>\n",	

// CSS files
cssFiles : [
	dojo.moduleUrl("plugins", "core/css/agua.css"),
	dojo.moduleUrl("plugins", "core/css/controls.css"),
	//dojo.moduleUrl("plugins", "core/css/toolbar.css")
],

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CONTROLLERS
controllers : new Object(),

// DIV FOR PRELOAD SCREEN
splashNode : null,

// DIV TO DISPLAY PRELOAD MESSAGE BEFORE MODULES ARE LOADED
messageNode : null,

// PLUGIN MANAGER LOADS THE PLUGINS
pluginManager: null,

// COOKIES CONTAINS STORED USER ID AND SESSION ID
cookies : new Object,

// CONTAINS ALL LOADED CSS FILES
css : new Object,

// WEB URLs
cgiUrl : null,
htmlUrl : null,

// CHILD WIDGETS
widgets : new Object,

// TESTING - DON'T getData IF TRUE
testing: false,

////}}}}}}
// CONSTRUCTOR
constructor : function(args) {
	console.log("Agua.constructor     plugins.core.Agua.constructor    args:");
	console.dir({args:args});

	this.cgiUrl = args.cgiUrl;
	this.htmlUrl = args.htmlUrl;
	if ( args.pluginsList != null )	this.pluginsList = args.pluginsList;
    this.database = args.database;
    this.dataUrl = args.dataUrl;
	console.log("Agua.constructor     this.database: " + this.database);
	console.log("Agua.constructor     this.testing: " + this.testing);
	console.log("Agua.constructor     this.dataUrl: " + this.dataUrl); 
},
postCreate : function() {
	this.startup();
},
startup : function () {
// CHECK IF DEBUGGING AND LOAD PLUGINS
	console.log("Agua.startup    plugins.core.Agua.startup()");

	console.log("Agua.startup    BEFORE loadCSS()");
	this.loadCSS();
	console.log("Agua.startup    AFTER loadCSS()");
	
	// ATTACH THIS TEMPLATE TO attachPoint DIV ON HTML PAGE
	var attachPoint = dojo.byId("attachPoint");
	attachPoint.appendChild(this.containerNode);

	// SET BUTTON LISTENER
	var listener = dojo.connect(this.aguaButton, "onClick", this, "reload");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// INITIALISE ELECTIVE UPDATER
	this.updater = new plugins.core.Updater();

	// SET LOADING PROGRESS STANDBY
	this.setStandby();

	// SET POPUP MESSAGE TOASTER
	this.setToaster();
	
	console.log("Agua.startup    AFTER this.setToaster()");
/*
	 GET DATA
	if ( this.dataUrl != null )	{
		console.log("Agua.startup   Doing this.fetchJsonData()");
		this.fetchJsonData();
	}
	else if ( Data != null && Data.data != null ) {
		console.log("Agua.startup   Doing this.loadData(Data.data)");
		this.loadData(Data.data);
	}
*/

},
displayVersion : function () {
	console.log("Agua.displayVersion     plugins.core.Agua.displayVersion()");
	
	// GET AGUA PACKAGE
	var packages = this.getPackages();
	console.log("Agua.displayVersion    packages: ");
	console.dir({packages:packages});
	var packageObject = this._getObjectByKeyValue(packages, "package", "agua");
	console.log("Agua.displayVersion    packageObject:");
	console.dir({packageObject:packageObject});
	if ( ! packageObject )	return;
	
	// DISPLAY VERSION
	var version = packageObject.version;
	console.log("Agua.displayVersion     version: " + version);
},
// START PLUGINS
startPlugins : function () {
	console.log("Agua.startPlugins     plugins.core.Agua.startPlugins()");
	return this.loadPlugins(this.pluginsList);
},
loadPlugins : function (pluginsList) {
	console.log("Agua.loadPlugins    pluginsList: " + dojo.toJson(pluginsList));

	

	if ( pluginsList == null )	pluginsList = this.pluginsList;
	
	this.setStandby();
	console.dir({standby:this.standby});

	console.log("DOING this.standby.show()");
	this.standby.show();
	
	// LOAD PLUGINS
	console.log("Agua.loadPlugins    Creating pluginsManager...");
	this.pluginManager = new plugins.core.PluginManager({
		parentWidget : this,
		pluginsList : pluginsList
	})
	console.log("Agua.loadPlugins    After load PluginManager");

	if ( this.controllers["home"] )	{
		console.log("Agua.loadPlugins    this.controllers[home].createTab()");
		this.controllers["home"].createTab();
	}
},
setStandby : function () {
	console.log("Agua.setStandby    _GroupDragPane.setStandby()");
	if ( this.standby != null )	return this.standby;
	
	var id = dijit.getUniqueId("dojox_widget_Standby");
	this.standby = new dojox.widget.Standby (
		{
			target: this.containerNode,
			//onClick: "reload",
			centerIndicator : "text",
			text: "Waiting for remote featureName",
			id : id,
			url: "plugins/core/images/agua-biwave-24.png"
		}
	);
	document.body.appendChild(this.standby.domNode);
	dojo.addClass(this.standby.domNode, "view");
	dojo.addClass(this.standby.domNode, "standby");
	console.log("Agua.setStandby    this.standby: " + this.standby);

	return this.standby;
},
addWidget : function (type, widget) {
    //console.log("Agua.addWidget    core.Agua.addWidget(type, widget)");
    //console.log("Agua.addWidget    type: " + type);
    //console.log("Agua.addWidget    widget: " + widget);
    if ( Agua.widgets[type] == null ) {
        Agua.widgets[type] = new Array;
    }
    //console.log("Agua.addWidget    BEFORE Agua.widgets[type].length: " + Agua.widgets[type].length);
    Agua.widgets[type].push(widget);
    //console.log("Agua.addWidget    AFTER Agua.widgets[type].length: " + Agua.widgets[type].length);
},
removeWidget : function (type, widget) {
    console.log("Agua.removeWidget    core.Agua.removeWidget(type, widget)");
    console.log("Agua.removeWidget    type: " + type);
    console.log("Agua.removeWidget    widget: " + widget);
        
    if ( Agua.widgets[type] == null )
    {
        console.log("Agua.removeWidget    No widgets of type: " + type);
        return;
    }

    console.log("Agua.removeWidget    BEFORE Agua.widgets[type].length: " + Agua.widgets[type].length);
    for ( var i = 0; i < Agua.widgets[type].length; i++ )
    {
        if ( Agua.widgets[type][i].id == widget.id )
        {
            Agua.widgets[type].splice(i, 1);
        }
    }
    console.log("Agua.removeWidget    AFTER Agua.widgets[type].length: " + Agua.widgets[type].length);
},
addToolbarButton: function (label) {
// ADD MODULE BUTTON TO TOOLBAR
	//console.log("Agua.addToolbarButton    plugins.core.Agua.addToolbarButton(label)");
	console.log("Agua.addToolbarButton    label: " + label);
	console.log("Agua.addToolbarButton    this.toolbar: " + this.toolbar);
	
	if ( this.toolbar == null )
	{
		//console.log("Agua.addToolbarButton    this.toolbar is null. Returning");
		return;
	}
	
	var button = new dijit.form.Button({
		
		label: label,
		showLabel: true,
		//className: label,
		iconClass: "dijitEditorIcon dijitEditorIcon" + label
	});
	//console.log("Agua.addToolbarButton    button: " + button);
	this.toolbar.addChild(button);
	
	return button;
},
cookie : function (name, value) {
// SET OR GET COOKIE-CONTAINED USER ID AND SESSION ID

	//console.log("Agua.cookie     plugins.core.Agua.cookie(name, value)");
	//console.log("Agua.cookie     name: " + name);
	//console.log("Agua.cookie     value: " + value);		

	if ( value != null )
	{
		this.cookies[name] = value;
	}
	else if ( name != null )
	{
		return this.cookies[name];
	}

	//console.log("Agua.cookie     this.cookies: " + dojo.toJson(this.cookies));

	return 0;
},
loadCSSFile : function (cssFile) {
// LOAD A CSS FILE IF NOT ALREADY LOADED, REGISTER IN this.loadedCssFiles
	//console.log("Agua.loadCSSFile    cssFile: " + cssFile);
	//console.log("Agua.loadCSSFile    this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));
	if ( this.loadedCssFiles == null || ! this.loadedCssFiles )
	{
		//console.log("Agua.loadCSSFile    Creating this.loadedCssFiles = new Object");
		this.loadedCssFiles = new Object;
	}
	
	if ( ! this.loadedCssFiles[cssFile] )
	{
		console.log("Agua.loadCSSFile    Loading cssFile: " + cssFile);
		
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		document.getElementsByTagName("head")[0].appendChild(cssNode);

		this.loadedCssFiles[cssFile] = 1;
	}
	else
	{
		//console.log("Agua.loadCSSFile    No load. cssFile already exists: " + cssFile);
	}
	//console.log("Agua.loadCSSFile    Returning this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));
	
	return this.loadedCssFiles;
},
// DATA METHODS
fetchJsonData : function() {
	console.log("Agua.fetchJsonData    plugins.core.Agua.fetchJsonData()")	
	// GET URL 
    var url = this.dataUrl 
	console.log("Agua.fetchJsonData    url: " + url);

    var thisObject = this;
    dojo.xhrGet({
        // The URL of the request
        url: url,
		sync: true,
        // Handle as JSON Data
        handleAs: "json",
        // The success callback with result from server
        handle: function(data) {
			console.log("Agua.fetchJsonData    Setting this.data: " + data);
			thisObject.data = data;
        },
        // The error handler
        error: function() {
            console.log("Agua.Error with JSON Post, response: " + response);
        }
    });
},
reload : function () {
// RELOAD AGUA
	//console.log("Agua.constructor    plugins.core.Controls.reload()");
	var url = window.location;
	window.open(location, '_blank', 'toolbar=1,location=0,directories=0,status=0,menubar=1,scrollbars=1,resizable=1,navigation=0'); 

	//window.location.reload();
},
// TOASTER METHODS
setToaster : function () {
	console.log("Agua.setToaster    this.toaster: " + this.toaster);
	console.dir({this_toaster:this.toaster});
	
	if ( ! this.toaster ) {
		this.toaster = new dojox.widget.Toaster({
			className: "toaster",
			positionDirection: "bl-right",
			duration: "500",
			messageTopic: "toastTopic"
		});
	}
},
toastMessage : function (args) {
	console.log("Agua.toastMessage    args:");
	console.dir({args:args});
	console.log("Agua.toastMessage    this.toaster: " + this.toaster);
	console.dir({this_toaster:this.toaster});
	if ( ! args )	return;
	if ( ! this.toaster || ! this.toaster.containerNode ) {
		this.setToaster();
	}
	
	if ( args.doToast == false )	return;
	var message = args.message;
	if ( message == null || message == '' ) {
		
		console.log("Agua.toastMessage    message is empty or not defined. Returning");
		return;
	}
	console.log("Agua.toastMessage    args: ");
	console.dir({args:args});
	//console.log("Agua.toastMessage    caller: " + this.toastMessage.caller.nom);

	// type: 'error' or 'warning'
	var type = args.type;
	//console.log("Agua.toastMessage    type: " + type);

	// duration: time before fade out (milliseconds)
	var duration = args.duration;

	if ( duration == null )	duration = 4000;
	if ( type != null
		&& (type != "warning" && type != "error" && type != "fatal") )
	{
		console.log("Agua.toastMessage    type not supported (must be warning|error|fatal): " + type);
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
		console.log("Agua.toastMessage    error: " + dojo.toJson(error));
	}

},
toast : function (response) {
	console.log("Agua.toast    response: ");
	console.dir({response:response});

	if ( response.error ) {
		var args = {
			message: response.error,
			type: "error"
		};
		if ( response.duration != null )
			args.duration = response.duration;
		Agua.toastMessage(args);
	}
	else
	{
		var args = {
			message: response.status,
			type: "warning"
		};
		if ( response.duration != null )
			args.duration = response.duration;
		Agua.toastMessage(args);
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
},
// LOGOUT
logout : function () {
	console.clear();
	var buttons = Agua.toolbar.getChildren();
	if ( ! buttons )	return;
	for ( var i = 0; i < buttons.length; i++ ) {
		var button = buttons[i];
		controller = button.parentWidget;
		console.log("Agua.logout    controller " + i);
		console.dir({controller:controller});

		var name = controller.id.match(/plugins_([^_]+)/)[1]; 
		console.log("Agua.logout    Doing delete Agua.controllers[" + name + "]");
		delete Agua.controllers[name];
		
		console.log("Agua.logout    Doing controllers.destroyRecursive()");
		controller.destroyRecursive();
	}
	
	delete this.data;
}

}); // end of Agua

}

