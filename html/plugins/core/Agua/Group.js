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
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"addGroup";
	query.module = "Agua::Sharing";
	query.data 			= 	groupObject;
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
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"removeGroup";
	query.module = "Agua::Sharing";
	query.data 			= 	groupObject;
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