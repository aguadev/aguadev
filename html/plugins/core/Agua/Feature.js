dojo.provide("plugins.core.Agua.Feature");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	FEATURE METHODS  
*/
dojo.declare( "plugins.core.Agua.Feature",	[  ], {

/////}}}

getFeatures : function () {
// GET THE UNIQUE SPECIES (AND BUILD) FOR A GIVEN VIEW
	console.log("Agua.Feature.getViewFeatures     GETTING viewfeatures");

	var features = this.cloneData("features");
	console.log("Agua.Feature.getViewFeatures    features: ");
	console.dir({features:features});

	return features;
},

getViewFeaturesByView : function (projectName, viewName) {
// GET THE UNIQUE SPECIES (AND BUILD) FOR A GIVEN VIEW
	console.log("Agua.Feature.getViewFeaturesByView     plugins.core.Data.getViewFeaturesByView(projectName, viewName)");
	console.log("Agua.Feature.getViewFeaturesByView    projectName: " + projectName);
	console.log("Agua.Feature.getViewFeaturesByView    viewName: " + viewName);
	if ( projectName == null || ! projectName )
	{
		//console.log("Agua.Feature.getViewFeaturesByView     projectName is null or empty. Returning");
		return;
	}

	var viewfeatures = this.cloneData("viewfeatures");
	console.log("Agua.Feature.getViewFeaturesByView    viewfeatures: ");
	console.dir({viewfeatures:viewfeatures});
	var keyArray = ["project", "view"];
	var valueArray = [projectName, viewName];
	viewfeatures = this.filterByKeyValues(viewfeatures, keyArray, valueArray);

	//console.log("Agua.Feature.getViewFeaturesByView    Returning viewfeatures: " + dojo.toJson(viewfeatures));
	return viewfeatures;
},
hasViewFeature : function (projectName, viewName, featureName) {
	console.log("Agua.Feature.hasViewFeature    projectName: " + projectName);
	console.log("Agua.Feature.hasViewFeature    viewName: " + viewName);
	console.log("Agua.Feature.hasViewFeature    featureName: " + featureName);
	var features = this.getViewFeaturesByView(projectName, viewName);
	console.log("Agua.Feature.hasViewFeature    features: ");
	console.dir({features:features});

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
	if ( projectName == null || ! projectName ) {
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
	
	var viewfeatures = this.getViewFeaturesByView(featureObject.project, featureObject.view);
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