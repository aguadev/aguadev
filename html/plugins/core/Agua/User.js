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
	if ( index != null ) {
		return users[index];
	}
	
	return null;
},
getUsers : function () {
// RETURN A SORTED COPY OF users
	this.sortData("users", "username");
	return this.cloneData("users");
},
addUser : function (userObject) {
	console.log("Agua.User.addUser    plugins.core.Data.addUser(userObject)");
	//console.log("Agua.User.addUser    userObject: " + dojo.toJson(userObject));

	this._removeUser(userObject);
	if ( ! Agua._addUser(userObject) )	return;
	
	// CREATE JSON QUERY
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode = "addUser";
	query.module 		= 	"Agua::Workflow";
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
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username = this.cookie("username");
	query.sessionid = this.cookie("sessionid");
	query.mode = "removeUser";
	query.module = "Agua::Sharing";
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