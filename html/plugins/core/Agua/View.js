dojo.provide("plugins.core.Agua.View");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	VIEW METHODS  
*/

dojo.declare( "plugins.core.Agua.View",	[  ], {

/////}}}}
getViewObject : function (projectName, viewName) {
// RETURN AN ARRAY OF VIEW HASHES FOR THE SPECIFIED PROJECT AND WORKFLOW
	console.log("Agua.View.getViewObject    plugins.core.Data.getViewObject(projectName, viewName)");
	console.log("Agua.View.getViewObject    projectName: " + projectName);
	console.log("Agua.View.getViewObject    viewName: " + viewName);

	var views = this.getViews();
	console.log("Agua.View.getViewObject    views: " + dojo.toJson(views, false));
	if ( views == null )	return [];
	var keyArray = ["project", "view"];
	var valueArray = [projectName, viewName];
	var views = this.filterByKeyValues(views, keyArray, valueArray);
	console.log("Agua.View.getViewObject    FILTERED views");
	console.dir({views:views})

	if ( views == null || views.length == 0 )	return null;

	console.log("Agua.View.getViewObject    RETURNING views[0]:");
	console.dir({viewObject:views[0]});
	
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
	this._removeView(viewObject);
	
	// REMOVE ANY EXISTING FEATURES
	this._removeViewFeatures(viewObject);
	
	return true;
},
_removeView : function (viewObject) {
// REMOVE A VIEW OBJECT FROM THE views ARRAY
	console.log("Agua.View._removeView    viewObject: " + dojo.toJson(viewObject));

	// REMOVE VIEW FROM views
	var requiredKeys = ["project", "view"];
	if ( ! this.removeData("views", viewObject, requiredKeys) ) {
		console.log("Agua.View.removeView    Could not remove view from views table: " + viewObject.name);
		return false;
	}

	return true;
},
_removeViewFeatures : function (viewObject) {
// REMOVE A VIEW OBJECT FROM THE views ARRAY
	//console.log("Agua.View.removeView    viewObject: " + dojo.toJson(viewObject));

	// REMOVE ANY EXISTING FEATURES
	var requiredKeys = ["project", "view"];
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
_addView : function (viewObject) {
// ADD A VIEW TO views AND SAVE ON REMOTE SERVER
	//console.log("Agua.View.addView    plugins.core.Data._addView(viewObject)");
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
	console.log("Agua.View.getViewsByProject    projectName: " + projectName);
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

	var viewfeatures = this.getViewFeaturesByView(projectName, viewName);
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