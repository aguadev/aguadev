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
	
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"addSource";
	query.module = "Agua::Workflow";
	query.data 			= 	sourceObject;
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
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"removeSource";
	query.module = "Agua::Workflow";
	query.data 			= 	sourceObject;
	
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