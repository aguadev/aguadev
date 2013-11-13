if(!dojo._hasResource["plugins.core.Common.Array"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Common.Array"] = true;
dojo.provide("plugins.core.Common.Array");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	ARRAY METHODS  
*/

dojo.declare( "plugins.core.Common.Array",	[  ], {

///////}}}
// HASHARRAY METHODS
_getIndex : function (array, key) {
	//console.log("  Common.Array._getIndex    array: ");
	//console.dir({array:array});
	//console.log("  Common.Array._getIndex    key: " + key);
	
	for ( var i = 0; i < array.length; i++ ) {
		//console.log("  Common.Array._getIndex    array[i]: " + array[i]);
		if ( array[i] == key ) {
			//console.log("  Common.Array._getIndex    RETURNING " + i);
			return i;
		}
	}
	
	return -1;
},
_getObjectByKeyValue : function (hasharray, key, value) {
// RETRIEVE AN OBJECT FROM AN ARRAY, IDENTIFED BY A KEY:VALUE PAIR
	//console.log("  Common.Array._getObjectByKeyValue    plugins.core.Common._getObjectByKeyValue(hasharray, key, value)");
	//console.log("  Common.Array._getObjectByKeyValue    hasharray: ");
	//console.dir({hasharray:hasharray});
	//console.log("  Common.Array._getObjectByKeyValue    key: " + key);
	//console.log("  Common.Array._getObjectByKeyValue    value: " + value);
	if ( hasharray == null )	return;
	for ( var i = 0; i < hasharray.length; i++ )
	{
		//console.log("  Common.Array._getObjectByKeyValue    hasharray[" + i + "]: ");
		//console.dir({hasharray_entry:hasharray[i]});
		//console.log("  Common.Array._getObjectByKeyValue    hasharray[" + i + "][" + key + "]: " + hasharray[i][key]);
		//console.log("  Common.Array._getObjectByKeyValue    BEFORE");
		if ( hasharray[i][key] == value )
			return hasharray[i];
		//console.log("  Common.Array._getObjectByKeyValue    AFTER");
	}
	
	return;
},
_addObjectToArray : function (array, object, requiredKeys) {
// ADD AN OBJECT TO AN ARRAY, CHECK REQUIRED KEY VALUES ARE NOT NULL

	//console.log("  Common.Array._addObjectToArray    plugins.core.Common._addObjectToArray(array, object, requiredKeys)");
	//console.log("  Common.Array._addObjectToArray    array.length: " + array.length);
	//console.log("  Common.Array._addObjectToArray    array: " + dojo.toJson(array));
	//console.log("  Common.Array._addObjectToArray    object: " + dojo.toJson(object, true));
	//console.log("  Common.Array._addObjectToArray    requiredKeys: " + dojo.toJson(requiredKeys));
	
	if ( array == null )
	{
		//console.log("  Common.Array._addObjectToArray    array is null. Creating new Array.");
		array = new Array;
	}
	
	var notDefined = this.notDefined(object, requiredKeys);
	if ( notDefined.length > 0 )
	{
		console.log("  Common.Array._addObjectToArray    notDefined: " + dojo.toJson(notDefined));
		return false;
	}
	
	//console.log("  Common.Array._addObjectToArray    Doing array.push(object)");
	array.push(object);

	return true;
},
_removeObjectFromArray : function (array, object, keys) {
// REMOVE AN OBJECT FROM AN ARRAY, IDENTIFY OBJECT USING SPECIFIED KEY VALUES

	//console.log("  Common.Array._removeObjectFromArray    BEFORE getIndexInArray, array: " + dojo.toJson(array));
	//console.dir({array:array});
	//console.dir({object:object});
	//console.dir({keys:keys});
	
	var index = this._getIndexInArray(array, object, keys);
	//console.log("  Common.Array._removeObjectFromArray    index: " + index);

	if ( index == null )	return false;
	
	//console.log("  Common.Array._removeObjectFromArray    AFTER this._getIndexInArray    array: " + dojo.toJson(array));

	//console.log("  Common.Array._removeObjectFromArray    BEFORE SPLICE array.length: " + array.length);
	array.splice(index, 1);
	//console.log("  Common.Array._removeObjectFromArray    AFTER SPLICE array.length: " + array.length);

	//console.log("  Common.Array._removeObjectFromArray    AFTER array: " + dojo.toJson(array));

	return true;
},
_removeArrayFromArray : function(hasharray, removeThis, uniqueKeys) {
// REMOVE AN ARRAY OF OBJECTS FROM A LARGER ARRAY CONTAINING IT,
// IDENTIFYING OBJECTS USING THE SPECIFIED KEY VALUES

	//console.log("  Common.Array.removeArrayFromArray    hasharray.length: " + hasharray.length);
	//console.log("  Common.Array.removeArrayFromArray    removeThis.length: " + removeThis.length);
	
	var success = true;
	for ( var j = 0; j < removeThis.length; j++ )
	{
		////console.log("  Common.Array.removeArrayFromArray    Removing removeThis[" + j + "]");
		////console.log("  Common.Array.removeArrayFromArray    Removing removeThis[" + j + "]: " + dojo.toJson(removeThis[j]));
		
		var notDefined = this.notDefined (removeThis[j], uniqueKeys);
		if ( notDefined.length > 0 )
		{
			////console.log("  Common.Array.removeArrayFromArray    SKIPPING removeArrayFromArray FOR removeThis[" + j + "] BECAUSE IT HAS notDefined VALUES: " + dojo.toJson(removeThis[j]));
			console.log("  Common.Array.removeArrayFromArray    object has notDefined keys: " + dojo.toJson(notDefined));
			success = false;
			continue;
		}
		////console.log("  Common.Array.removeArrayFromArray    notDefined: " + dojo.toJson(notDefined));
		var thisSuccess = this._removeObjectFromArray(hasharray, removeThis[j], uniqueKeys);
		if ( thisSuccess == false ) success = thisSuccess;
		////console.log("  Common.Array.removeArrayFromArray    removeSuccess: " + dojo.toJson(removeSuccess));
	}
	//console.log("  Common.Array.removeArrayFromArray    FINAL hasharray.length: " + hasharray.length);
	
	return success;
},
_getIndexInArray : function (hasharray, object, keys) {
// GET THE INDEX OF AN OBJECT IN AN ARRAY, IDENTIFY OBJECT USING SPECIFIED KEY VALUES
	//console.dir({hasharray:hasharray});
	//console.dir({object:object});
	//console.dir({keys:keys});
		
	if ( hasharray == null )
	{
		//console.log("  Common.Array._getIndexInArray    hasharray is null. Returning null.");
		return null;
	}
	
	for ( var i = 0; i < hasharray.length; i++ )
	{
		var arrayObject = hasharray[i];
		//console.dir({arrayObject:arrayObject});
		
		var identified = true;
		for ( var j = 0; j < keys.length; j++ )
		{
			//console.log("  Common.Array._getIndexInArray    Checking value for keys[" + j + "]: " + keys[j] + ": " + arrayObject[keys[j]]);
			if ( arrayObject[keys[j]] != object[keys[j]] )
			{
				//console.log("  Common.Array._getIndexInArray    object[" + keys[j] + "] : " + object[keys[j]]);
				//console.log("  Common.Array._getIndexInArray    arrayObject[" + keys[j] + "] : " + arrayObject[keys[j]]);
				//console.log("  Common.Array._getIndexInArray    " + arrayObject[keys[j]] + "** != **" + object[keys[j]] + "**");
				identified = false;
				break;
			}
		}
		//console.log("  Common.Array._getIndexInArray    identified: " + identified);

		if ( identified == true )
		{
			//console.log("  Common.Array._getIndexInArray    Returning index: " + i);
			return i;
		}
	}
	
	return null;
},
_objectInArray : function (array, object, keys) {
// RETURN true IF AN OBJECT ALREADY BELONGS TO A GROUP

	//console.log("  Common.Array._objectInArray    Agua._objectInArray(array, object, keys)");
	
	if ( array == null )	return false;
	if ( object == null )	return false;
	
	var index = this._getIndexInArray(array, object, keys);

	if ( index == null )	return false;

	//console.log("  Common.Array._objectInArray    Returning true");
	return true;
},
_removeObjectsFromArray : function (hasharray, object, keys) {
// REMOVE AN OBJECT FROM AN ARRAY, IDENTIFY OBJECT USING SPECIFIED KEY VALUES
	//console.log("  Common.Array._removeObjectFromArray    plugins.core.Common._removeObjectFromArray(array, object, keys)");
	//console.log("  Common.Array._removeObjectFromArray    hasharray: " + dojo.toJson(hasharray, true));
	//console.log("  Common.Array._removeObjectFromArray    object: " + dojo.toJson(object, true));
	//console.log("  Common.Array._removeObjectFromArray    keys: " + dojo.toJson(keys));
	if ( hasharray == null )	return;	

	var removed = new Array;
	for ( var i = 0; i < hasharray.length; i++ )
	{
		var arrayObject = hasharray[i];
		//console.log("  Common.Array._getIndexInArray    arrayObject: " + dojo.toJson(arrayObject));
		var identified = true;
		for ( var j = 0; j < keys.length; j++ )
		{
			//console.log("  Common.Array._getIndexInArray    Checking value for keys[" + j + "]: " + keys[j] + ": " + arrayObject[keys[j]]);
			if ( arrayObject[keys[j]] != object[keys[j]] )
			{
				//console.log("  Common.Array._getIndexInArray    object[" + keys[j] + "] : " + object[keys[j]]);
				//console.log("  Common.Array._getIndexInArray    arrayObject[" + keys[j] + "] : " + arrayObject[keys[j]]);
				//console.log("  Common.Array._getIndexInArray    " + arrayObject[keys[j]] + "** != **" + object[keys[j]] + "**");
				identified = false;
				break;
			}
		}
		//console.log("  Common.Array._getIndexInArray    identified: " + identified);

		if ( identified == true )
		{
			removed.push(hasharray.splice(i, 1));
			i--;
		}
	}
	
	//console.log("  Common.Array._removeObjectFromArray    BEFORE SPLICE array.length: " + array.length);
	//console.log("  Common.Array._removeObjectFromArray    AFTER SPLICE array.length: " + array.length);

	return removed;
},
_addArrayToArray : function (hasharray, array, keys) {
// REMOVE AN OBJECT FROM AN ARRAY, IDENTIFY OBJECT USING SPECIFIED KEY VALUES
	//console.log("  Common.Array._addArrayToArray    plugins.core.Common._addArrayToArray(array, object, keys)");
	//console.log("  Common.Array._addArrayToArray    hasharray: " + dojo.toJson(hasharray, true));
	//console.log("  Common.Array._addArrayToArray    object: " + dojo.toJson(object, true));
	//console.log("  Common.Array._addArrayToArray    keys: " + dojo.toJson(keys));
	if ( hasharray == null )	return;	

	var success = true;
	for ( var i = 0; i < array.length; i++ )
	{
		if ( ! this._addObjectToArray(hasharray, array[i], keys) )
			success = false;
	}

	return success;
},
_objectsMatchByKey : function (object1, object2, keys) {
	console.log("    Common._objectsMatchByKey object1:");
	console.dir({object1:object1});
	console.log("    Common._objectsMatchByKey object2:");
	console.dir({object2:object2});
	
	if ( ! object1 || ! object2 )	return;

	if ( object1 == null || object1 == null || keys == null )	return false;
	for ( var i = 0; i < keys.length; i++ ){
		if ( object1[keys[i]] != object2[keys[i]] )	return false;
	}
	
	return true;
},
hashArrayKeyToArray : function (hasharray, key) {
// RETURN AN ARRAY CONTAINING ONLY OBJECTS WHICH HAVE
// A DEFINED VALUE FOR THE SPECIFIED key 

	//console.log("  Common.Array.hashArrayKeyToArray    hasharray: ");
	//console.dir({hasharray:hasharray});
	//console.log("  Common.Array.hashArrayKeyToArray    key: " + key);
	//
	var outputArray = new Array;
	dojo.forEach(hasharray, function(entry) {
		//console.log("  Common.Array.hashArrayKeyToArray    entry[" + key + "]: " + entry[key]);
		if ( entry[key] )
			outputArray.push(entry[key]);
	});
	//console.log("  Common.Array.hashArrayKeyToArray    outputArray: ");
	//console.dir({outputArray:outputArray});

	return outputArray;
},
hashkeysToArray : function (hash) {
// RETURN AN ARRAY CONTAINING ONLY THE KEYS OF A HASH

	//console.log("  Common.Array.hashkeysToArray    plugins.core.Common.hashkeysToArray(hash)");
	//console.log("  Common.Array.hashkeysToArray    hash: " + dojo.toJson(hash));
	var array = new Array;
	for ( var key in hash )
	{
		if ( key != null && key != '' )   array.push(key);
	}
	//console.log("  Common.Array.hashkeysToArray    array: " + dojo.toJson(array));

	return array;
},
filterHasharray : function (hasharray, key) {
// RETURN A HASHARRAY CONTAINING THE SPECIFIED key VALUE
// IN EACH HASH IN A HASHARRAY

	var outputHasharray = new Array;
	dojo.forEach(hasharray, function(entry) {
		if ( entry[key] != null )
		{
			outputHasharray.push(entry);
		}
	});
	
	return outputHasharray;
},
filterByKeyValues : function (hasharray, keyarray, valuearray ) {
// RETURN AN ARRAY OF OBJECTS THAT ALL POSSESS GIVEN KEY VALUE
// NB: THIS SPLICES OUT THE ENTRIES FROM THE ACTUAL INPUT ARRAY
// REFERENCE I.E., THE PASSED ARRAY WILL SHRINK IN SIZE

	//console.log("  Common.Array.filterByKeyValues    plugins.core.Common.filterByKeyValues(hasharrray, keyarray, valuearray)");
	//console.log("  Common.Array.filterByKeyValues    hasharray: " + dojo.toJson(hasharray));
	//console.log("  Common.Array.filterByKeyValues    keyarray: " + dojo.toJson(keyarray));
	//console.log("  Common.Array.filterByKeyValues    valuearray: " + dojo.toJson(valuearray));
	if ( hasharray == null )	return;
	if ( keyarray == null )	return;
	if ( valuearray == null )	return;
	
	for ( var i = 0; i < hasharray.length; i++ )
	{
		var isMatched = true;
		for ( var j = 0; j < keyarray.length; j++ )
		{
			//console.log("  Common.Array.filterByKeyValues    hasharray[" + i + "][" + keyarray[j] + "]: " + hasharray[i][keyarray[j]]);
			//console.log("  Common.Array.filterByKeyValues    valuearray[" + j + "]: " + valuearray[j]);
			if ( hasharray[i][keyarray[j]] != valuearray[j] )
			{
				isMatched = false;
				break;
			}
		}
		if ( isMatched == false )	{
			var removed = hasharray[i];
			//console.log("  Common.Array.filterByKeyValues    removed name: " + removed.name + ", paramtype: " + removed.parametype);
			hasharray.splice(i, 1);
			i--;
		}
	}
	
	//console.log("  Common.Array.filterByKeyValues    Returning hasharray: " + dojo.toJson(hasharray));
	return hasharray;
},
// two-D ARRAY
_addArrayToArray : function (twoDArray, array, requiredKeys) {
// ADD AN ARRAY TO A TWO-D ARRAY, CHECK REQUIRED KEY VALUES ARE NOT NULL
	//console.log("  Common.Array._addArrayToArray    twoDArray: " + dojo.toJson(twoDArray));
	//console.log("  Common.Array._addArrayToArray    array: " + dojo.toJson(array, true));
	//console.log("  Common.Array._addArrayToArray    requiredKeys: " + dojo.toJson(requiredKeys));
	
	if ( twoDArray == null )
	{
		//console.log("  Common.Array._addArrayToArray    twoDArray is null. Creating new Array.");
		twoDArray = new Array;
	}
	
	var notDefined = this.notDefined(array, requiredKeys);
	if ( notDefined.length > 0 )
	{
		console.log("  Common.Array._addArrayToArray    notDefined: " + dojo.toJson(notDefined));
		return false;
	}
	console.log("  Common.Array._addArrayToArray    Doing twoDArray.push(array)");
	twoDArray.push(array);
	console.log("  Common.Array._addArrayToArray    AFTER twoDArray.push(array). twoDArray: " + dojo.toJson(twoDArray));

	return true;
},
// DATA METHODS
notDefined : function (hasharray, keys) {
// RETURN AN ARRAY OF THE UNDEFINED FIELDS IN A HASH

	//console.log("  Common.Array.notDefined    plugins.core.Common.notDefined(hasharray, order)");
	if ( hasharray == null )	return;
	var notDefined = new Array;
	for ( var i = 0; i < keys.length; i++ )
	{
		if ( hasharray[keys[i]] == null )	notDefined.push(keys[i]);
	}
	
	return notDefined;
},
getEntry : function (hasharray, keyarray, valuearray ) {
// RETURN AN ENTRY IN A HASH ARRAY IDENTIFIED BY ITS UNIQUE KEYS
	//console.log("  Common.Array.getEntry    plugins.core.Common.getEntry(hasharrray, keyarray, valuearray)");
	//console.log("  Common.Array.getEntry    hasharray: " + dojo.toJson(hasharray));
	//console.log("  Common.Array.getEntry    keyarray: " + dojo.toJson(keyarray));
	//console.log("  Common.Array.getEntry    valuearray: " + dojo.toJson(valuearray));
	if ( hasharray == null )	return;
	if ( keyarray == null )	return;
	if ( valuearray == null )	return;
	
	for ( var i = 0; i < hasharray.length; i++ )
	{
		var isMatched = true;
		for ( var j = 0; j < keyarray.length; j++ )
		{
			//console.log("  Common.Array.getEntry    hasharray[" + i + "][" + keyarray[j] + "]: " + hasharray[i][keyarray[j]]);
			//console.log("  Common.Array.getEntry    valuearray[" + j + "]: " + valuearray[j]);
			if ( hasharray[i][keyarray[j]] != valuearray[j] )
			{
				isMatched = false;
				break;
			}
		}

		//console.log("  Common.Array.getEntry    isMatched: " + isMatched);
		if ( isMatched == true )
		{
			//console.log("  Common.Array.getEntry    isMatched is true. valueArray: " + dojo.toJson(valuearray));
			//console.log("  Common.Array.getEntry    Returning hasharray[" + i + "]: " + dojo.toJson( hasharray[i]));
			return hasharray[i];
		}
	}
	console.log("  Common.Array.getEntry    Returning null");

	return null;
},
uniqueValues : function(array) {
	//console.log("  Common.Array.uniqueValues    plugins.core.Common.uniqueValues(array)");

	if ( array.length == 1 )	return array;

	array = array.sort();		
	for ( var i = 1; i < array.length; i++ )
	{
		if ( array[i-1] == array[i] )
		{
			array.splice(i, 1);
			i--;
			
		}
	}
	//console.log("  Common.Array.uniqueValues    array: " + dojo.toJson(array));
	
	return array;
}

});

}

if(!dojo._hasResource["plugins.core.Common.ComboBox"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Common.ComboBox"] = true;
dojo.provide("plugins.core.Common.ComboBox");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	COMBOBOX METHODS  
*/

dojo.declare( "plugins.core.Common.ComboBox",	[  ], {

///////}}}
// COMBOBOX METHODS
setUsernameCombo : function () {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: Agua.sharedprojects DATA OBJECT
//	OUTPUTS:	ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedProjectCombo
	//console.log("  Common.ComboBox.setUsernameCombo    plugins.core.Common.setUsernameCombo()");
	var usernames = Agua.getSharedUsernames();
	//console.log("  Common.ComboBox.setUsernameCombo    usernames: " + dojo.toJson(usernames));

	// RETURN IF projects NOT DEFINED
	if ( usernames == null || usernames.length == 0 )
	{
		//console.log("  Common.ComboBox.setUsernameCombo    usernames not defined. Returning.");
		return;
	}

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in usernames )
	{
		data.items[i] = { name: usernames[i]	};
	}
	//console.log("  Common.ComboBox.setUsernameCombo    store data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );
	//console.log("   Common.setUsernameCombo    store: " + dojo.toJson(store));

	// ADD STORE TO USERNAMES COMBO
	this.usernameCombo.store = store;	
	
	// START UP AND SET VALUE
	this.usernameCombo.startup();
	this.usernameCombo.set('value', usernames[0]);			
},
setSharedProjectCombo : function (username, projectName, workflowName) {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: USERNAME, OPTIONAL PROJECT NAME AND WORKFLOW NAME
//	OUTPUTS: ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedWorkflowCombo

	//console.log("  Common.ComboBox.setSharedProjectCombo    plugins.report.Workflow.setSharedProjectCombo(username, project, workflow)");

	var projects = Agua.getSharedProjectsByUsername(username);
	if ( projects == null )
	{
		//console.log("   Common.setSharedProjectCombo    projects is null. Returning");
		return;
	}
	//console.log("  Common.ComboBox.setSharedProjectCombo    projects: " + dojo.toJson(projects));
	
	var projectNames = this.hashArrayKeyToArray(projects, "name");
	projectNames = this.uniqueValues(projectNames);
	//console.log("  Common.ComboBox.setSharedProjectCombo    projectNames: " + dojo.toJson(projectNames));
	
	// RETURN IF projects NOT DEFINED
	if ( projectNames == null || projectNames.length == 0 )
	{
		//console.log("  Common.ComboBox.setSharedProjectCombo    projectNames not defined. Returning.");
		return;
	}

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in projectNames )
	{
		data.items[i] = { name: projectNames[i]	};
	}
	//console.log("  Common.ComboBox.setSharedProjectCombo    store data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );
	//console.log("  Common.ComboBox.setSharedProjectCombo    store: " + dojo.toJson(store));

	// ADD STORE TO USERNAMES COMBO
	this.projectCombo.store = store;	
	
	// START UP AND SET VALUE
	this.projectCombo.startup();
	this.projectCombo.set('value', projectNames[0]);	
},
setSharedWorkflowCombo : function (username, projectName, workflowName) {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: USERNAME, OPTIONAL PROJECT NAME AND WORKFLOW NAME
//	OUTPUTS: ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedWorkflowCombo

	console.log("  Common.ComboBox.setSharedWorkflowCombo    plugins.report.Workflow.setSharedWorkflowCombo(username, project, workflow)");
	console.log("  Common.ComboBox.setSharedWorkflowCombo    projectName: " + projectName);
				
	if ( projectName == null )	projectName = this.projectCombo.get('value');
	console.log("  Common.ComboBox.setSharedWorkflowCombo    AFTER projectName: " + projectName);

	var workflows = Agua.getSharedWorkflowsByProject(username, projectName);
	if ( workflows == null )
	{
		console.log("  Common.ComboBox.setSharedWorkflowCombo    workflows is null. Returning");
		return;
	}
	console.log("  Common.ComboBox.setSharedWorkflowCombo    workflows: ");
	console.dir({workflows:workflows});
	
	var workflowNames = this.hashArrayKeyToArray(workflows, "name");
	workflowNames = this.uniqueValues(workflowNames);
	console.log("  Common.ComboBox.setSharedWorkflowCombo    workflowNames: " + dojo.toJson(workflowNames));
	
	// RETURN IF workflows NOT DEFINED
	if ( workflowNames == null || workflowNames.length == 0 )
	{
		console.log("  Common.ComboBox.setSharedWorkflowCombo    workflowNames not defined. Returning.");
		return;
	}

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in workflowNames )
	{
		data.items[i] = { name: workflowNames[i]	};
	}

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );

	// ADD STORE TO USERNAMES COMBO
	this.workflowCombo.store = store;	
	
	// START UP AND SET VALUE
	this.workflowCombo.startup();
	this.workflowCombo.set('value', workflowNames[0]);
},
setProjectCombo : function (project, workflow) {
//	INPUT: (OPTIONAL) project, workflow NAMES
//	OUTPUT:	POPULATE COMBOBOX AND SET SELECTED ITEM

	////console.log("  Common.ComboBox.setProjectCombo    plugins.report.Template.Common.setProjectCombo(project,workflow)");
	////console.log("  Common.ComboBox.setProjectCombo    project: " + project);
	////console.log("  Common.ComboBox.setProjectCombo    workflow: " + workflow);

	var projectNames = Agua.getProjectNames();
	////console.log("  Common.ComboBox.setProjectCombo    projectNames: " + dojo.toJson(projectNames));

	// RETURN IF projects NOT DEFINED
	if ( ! projectNames )
	{
		//console.log("  Common.ComboBox.setProjectCombo    projectNames not defined. Returning.");
		return;
	}
	////console.log("  Common.ComboBox.setProjectCombo    projects: " + dojo.toJson(projects));

	// SET PROJECT IF NOT DEFINED TO FIRST ENTRY IN projects
	if ( project == null || ! project)	project = projectNames[0];
	
	// DO DATA ARRAY
	var data = {identifier: "name", items: []};
	for ( var i in projectNames )
	{
		data.items[i] = { name: projectNames[i]	};
	}
	////console.log("  Common.ComboBox.setProjectCombo    store data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );

	//// GET PROJECT COMBO WIDGET
	var projectCombo = this.projectCombo;
	if ( projectCombo == null )
	{
		//console.log("  Common.ComboBox.setProjectCombo    projectCombo is null. Returning.");
		return;
	}
			
	projectCombo.store = store;	
	////console.log("  Common.ComboBox.setProjectCombo    project: " + project);
	
	// START UP AND SET VALUE
	//projectCombo.startup();
	//console.log("  Common.ComboBox.setProjectCombo    projectCombo.set('value', " + project + ")");
	projectCombo.set('value', project);			
},
setWorkflowCombo : function (project, workflow) {
// SET THE workflow COMBOBOX

	//console.log("  Common.ComboBox.setWorkflowCombo    plugins.workflow.Common.setWorkflowCombo(project, workflow)");

	if ( project == null || ! project )
	{
		//console.log("  Common.ComboBox.setWorkflowCombo    Project not defined. Returning.");
		return;
	}
	//console.log("  Common.ComboBox.setWorkflowCombo    project: " + project);
	//console.log("  Common.ComboBox.setWorkflowCombo    workflow: " + workflow);

	// CREATE THE DATA FOR A STORE		
	var workflows = Agua.getWorkflowsByProject(project);
	//console.log("  Common.ComboBox.setWorkflowCombo    project '" + project + "' workflows: " + dojo.toJson(workflows));

	console.log("  Common.ComboBox.setWorkflowCombo    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX DOING SORT workflows");
	workflows = this.sortHasharrayByKeys(workflows, ["number"]);
	console.log("  Common.ComboBox.setWorkflowCombo    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AFTER SORT workflows:");
	console.dir({XXXXXXXXXXXXXXXXXworkflows:workflows});
	
	var workflowNames = this.hashArrayKeyToArray(workflows, "name");
	
	
	// RETURN IF workflows NOT DEFINED
	if ( ! workflowNames )
	{
		console.log("  Common.ComboBox.setWorkflowCombo    workflowNames not defined. Returning.");
		return;
	}		

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in workflowNames )
	{
		data.items[i] = { name: workflowNames[i]	};
	}
	console.log("  Common.ComboBox.setWorkflowCombo    data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( { data: data } );

	// GET WORKFLOW COMBO
	var workflowCombo = this.workflowCombo;
	if ( workflowCombo == null )
	{
		console.log("  Common.ComboBox.setworkflowCombo    workflowCombo is null. Returning.");
		return;
	}

	//console.log("  Common.ComboBox.setWorkflowCombo    workflowCombo: " + workflowCombo);
	workflowCombo.store = store;

	// START UP COMBO AND SET SELECTED VALUE TO FIRST ENTRY IN workflowNames IF NOT DEFINED 
	if ( workflow == null || ! workflow )	workflow = workflowNames[0];
	//console.log("  Common.ComboBox.setWorkflowCombo    workflow: " + workflow);

	workflowCombo.startup();
	workflowCombo.set('value', workflow);			
},
setReportCombo : function (project, workflow, report) {
// SET THE report COMBOBOX

	//console.log("  Common.ComboBox.setReportCombo    plugins.report.Common.setReportCombo(project, workflow, report)");
	//console.log("  Common.ComboBox.setReportCombo    project: " + project);
	//console.log("  Common.ComboBox.setReportCombo    workflow: " + workflow);
	//console.log("  Common.ComboBox.setReportCombo    report: " + report);

	if ( project == null || ! project )
	{
		console.log("  Common.ComboBox.setReportCombo    project not defined. Returning.");
		return;
	}
	if ( workflow == null || ! workflow )
	{
		console.log("  Common.ComboBox.setReportCombo    workflow not defined. Returning.");
		return;
	}
	//console.log("  Common.ComboBox.setReportCombo    project: " + project);
	//console.log("  Common.ComboBox.setReportCombo    workflow: " + workflow);
	//console.log("  Common.ComboBox.setReportCombo    report: " + report);

	var reports = Agua.getReportsByWorkflow(project, workflow);
	if ( reports == null )	reports = [];
	console.log("  Common.ComboBox.setReportCombo    project " + project + " reports: " + dojo.toJson(reports));

	var reportNames = this.hashArrayKeyToArray(reports, "name");
	console.log("  Common.ComboBox.setReportCombo    reportNames: " + dojo.toJson(reportNames));
	
	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in reports )
	{
		data.items[i] = { name: reportNames[i]	};
	}
	console.log("  Common.ComboBox.setReportCombo    data: " + dojo.toJson(data));

	// CREATE store
	// http://docs.dojocampus.org/dojo/data/ItemFileWriteStore
	var store = new dojo.data.ItemFileReadStore( { data: data } );

	// GET WORKFLOW COMBO
	var reportCombo = this.reportCombo;
	if ( reportCombo == null )
	{
		console.log("  Common.ComboBox.setreportCombo    reportCombo is null. Returning.");
		return;
	}

	console.log("  Common.ComboBox.setReportCombo    reportCombo: " + reportCombo);
	reportCombo.store = store;

	// GET USER INPUT WORKFLOW
	var snpReport = this;

	// START UP COMBO (?? NEEDED ??)
	reportCombo.startup();
	reportCombo.set('value', report);			
},
setViewCombo : function (projectName, viewName) {
// SET THE view COMBOBOX
	console.log("  Common.ComboBox.setViewCombo    projectName: " + projectName);
	console.log("  Common.ComboBox.setViewCombo    viewName: " + viewName);

	// SANITY CHECK
	if ( ! this.viewCombo )	return;
	if ( ! projectName )	return;

	var views = Agua.getViewNames(projectName);

	console.log("  Common.ComboBox.setViewCombo    BEFORE SORT views: ");
	console.dir({views: views});
	
	views.sort(this.sortNaturally);

	console.log("View.setViewCombo    AFTER SORT views: ");
	console.dir({views:views});

	//console.log("  Common.ComboBox.setViewCombo    projectName '" + projectName + "' views: " + dojo.toJson(views));
	
	// RETURN IF views NOT DEFINED
	if ( ! views || views.length == 0 )	views = [];
	//{
		//console.log("  Common.ComboBox.setViewCombo    views not defined. Returning.");
		//return;
		//Agua.addView({ project: projectName, name: "View1" });
		//views = Agua.getViewNames(projectName);
	//}		
	//console.log("  Common.ComboBox.setViewCombo    views: " + dojo.toJson(views));

	// SET view IF NOT DEFINED TO FIRST ENTRY IN views
	if ( viewName == null || ! viewName)
	{
		viewName = views[0];
	}
	//console.log("  Common.ComboBox.setViewCombo    viewName: " + viewName);
	
	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in views )
	{
		data.items[i] = { name: views[i]	};
	}
	//console.log("  Common.ComboBox.setViewCombo    data: " + dojo.toJson(data));

	// CREATE store
	// http://docs.dojocampus.org/dojo/data/ItemFileWriteStore
	var store = new dojo.data.ItemFileReadStore( { data: data } );

	//console.log("  Common.ComboBox.setViewCombo    this.viewCombo: " + this.viewCombo);
	this.viewCombo.store = store;

	// START UP COMBO (?? NEEDED ??)
	this.viewCombo.startup();
	this.viewCombo.set('value', viewName);			
},
getSelectedValue : function (element) {
	var index = element.selectedIndex;
	//console.log("  Common.ComboBox.getSelectedValue    index: " + index);
	var value = element.options[index].text;
	//console.log("  Common.ComboBox.getSelectedValue    value: " + value);
	
	return value;
}



});

}

if(!dojo._hasResource["plugins.core.Common.Date"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Common.Date"] = true;
dojo.provide("plugins.core.Common.Date");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	DATE METHODS  
*/

dojo.declare( "plugins.core.Common.Date",	[  ], {

///////}}}

// DATES
currentDate : function () {
	var date = new Date;
	var string = date.toString();

	return string;
},
currentMysqlDate : function () {
	var date = new Date;
	date = this.dateToMysql(date);	
	
	return date;
},
dateToMysql : function (date) {

  return date.getFullYear()
	+ '-'
	+ (date.getMonth() < 9 ? '0' : '') + (date.getMonth()+1)
	+ '-'
	+ (date.getDate() < 10 ? '0' : '') + date.getDate()
	+ ' '
	+ (date.getHours() < 10 ? '0' : '' ) + date.getHours()
	+ ':'
	+ (date.getMinutes() < 10 ? '0' : '' ) + date.getMinutes() 
	+ ':'
	+ (date.getSeconds() < 10 ? '0' : '' ) + date.getSeconds();
},
mysqlToDate : function (timestamp) {
	// FORMAT: 2007-06-05 15:26:03
	var regex=/^([0-9]{2,4})-([0-1][0-9])-([0-3][0-9]) (?:([0-2][0-9]):([0-5][0-9]):([0-5][0-9]))?$/;
	var elements = timestamp.replace(regex,"$1 $2 $3 $4 $5 $6").split(' ');

	return new Date(elements[0],elements[1]-1,elements[2],elements[3],elements[4],elements[5]);
}



});

}

if(!dojo._hasResource["plugins.core.Common.Sort"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Common.Sort"] = true;
dojo.provide("plugins.core.Common.Sort");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	SORT METHODS  
*/

dojo.declare( "plugins.core.Common.Sort",	[  ], {

///////}}}
sortHasharrayByOrder : function (hasharray, order) {
// SORT A HASHARRAY BY THE GIVEN ORDER OF KEYS, EXCLUDING ENTRIES
// THAT DO NOT HAVE VALUES FOR ANY OF THE GIVEN KEYS

	//console.log("  Common.Sort.sortHasharrayByOrder    hasharray: " + dojo.toJson(hasharray));
	//console.log("  Common.Sort.sortHasharrayByOrder    order: " + dojo.toJson(order));

	var orderedArray = new Array;	
	for ( var i = 0; i < order.length; i++ )
	{
		var orderedType = order[i];
		//console.log("  Common.Sort.sortHasharrayByOrder    orderedType: " + orderedType);
		
		for ( var j = 0; j < hasharray.length; j++ )
		{
			//console.log("  Common.Sort.sortHasharrayByOrder    applicationsList[" + j + "]: " + applicationsList[i]);
			var applicationHash = hasharray[j];
			var applicationType;
			for ( var applicationType in applicationHash )
			{
				if ( applicationType == orderedType ) {
					//console.log("  Common.Sort.sortHasharrayByOrder     applicationType: " + applicationType);
					orderedArray.push(applicationHash);
					break;
				}
			}
		}
	}
	
	return orderedArray;		
},
sortNoCase : function (array) {
// DO A NON-CASE SPECIFIC SORT OF AN ARRAY

	//console.log("  Common.Sort.sortNoCase    plugins.core.Common.sortNoCase(array)");
	//console.log("  Common.Sort.sortNoCase    array: " + dojo.toJson(array));
	
	return array.sort( function (a,b)
		{
			return a.toUpperCase() == b.toUpperCase() ?
			(a < b ? -1 : a > b) : (a.toUpperCase() < b.toUpperCase() ? -1 : a.toUpperCase() > b.toUpperCase());
		}
	);
},
sortHasharrayByKeys : function (hashArray, keys) {

	if ( hashArray == null )	return;
	if ( keys == null )	return;
	if ( ! typeof hashArray == "ARRAY" || hashArray == null ) return;
	if ( ! typeof keys == "ARRAY" || keys == null ) return;

	return hashArray.sort(function (a,b) {
    //console.log("  Common.Sort.sortHasharray    a[" + key + "]: " + a[key]);
    //console.log("  Common.Sort.sortHasharray    b[" + key + "]: " + b[key]);

        var result = 1;
        for ( var i = 0; i < keys.length; i++ )
        {
            var key = keys[i];
            //console.log("Doing key '" + key + "'");
            if ( a[key] == null || b[key] == null )
            {
                //console.log("No value for a['" + key + "']: " + a[key] + " or  b['" + key + "']: " + b[key] + " in hashArray items a: " + dojo.toJson(a) + " or b: " + dojo.toJson(b));
                continue;
            }
    
            if ( a[key].toUpperCase && b[key].toUpperCase )
            {

                var aString = a[key].toUpperCase(); 
                var bString = b[key].toUpperCase(); 
                //console.log("aString: " + aString);
                //console.log("bString: " + bString);
    
                result =  aString == bString ?
                ( a[key] < b[key] ? -1 : (a[key] > b[key] ? 1 : 0) )
                    : ( aString < bString ? -1 : (aString > bString ? 1 : 0) );
    
                //console.log("result for key '" + key + "': " + result);
                if ( result != 0 )    break;
            }
            else
            {
                //console.log("Comparing ints a['" + key + "']: " + a[key] + " and  b['" + key + "']: " + b[key]);
                result = a[key] < b[key] ? -1 :
                         ( a[key] > b[key] ? 1 : 0 );

                //console.log("result for key '" + key + "': " + result);
                if ( result != 0 )    break;
            }  
        }
        
        return result;
    });
},
sortHasharray : function (hashArray, key) {
// SORT AN ARRAY OF HASHES BY A SPECIFIED HASH FIELD
// NB: IF THE FIELD IS NULL OR EMPTY IN AN ARRAY ENTRY
// IT WILL BE DISCARDED.

	//console.log("  Common.Sort.sortHasharray    hashArray: " + dojo.toJson(hashArray));
	//console.log("  Common.Sort.sortHasharray    key: " + key);
	if ( hashArray == null )	return;
	if ( key == null )	return;
	if ( ! typeof hashArray == "ARRAY" ) return;
	
	return hashArray.sort(function (a,b) {
		if ( a[key] == null )
		{
			//console.log("No value for key '" + key + "' in hashArray item: " + dojo.toJson(a));
			return;
		}
		if ( b[key] == null )
		{
			//console.log("No value for key '" + key + "' in hashArray item: " + dojo.toJson(b));
			return;
		}

		return a[key].toUpperCase() == b[key].toUpperCase() ?
			(a[key] < b[key] ? -1
			: a[key] > b[key])
			: (a[key].toUpperCase() < b[key].toUpperCase() ? -1
			: a[key].toUpperCase() > b[key].toUpperCase());
		}
	);
},
sortNumericHasharray : function (hashArray, key) {
// SORT AN ARRAY OF HASHES BY A SPECIFIED *NUMERIC* HASH FIELD
// NB: IF THE FIELD IS NULL OR EMPTY IN AN ARRAY ENTRY
// IT WILL BE DISCARDED.

//        console.log("  Common.Sort.sortNumericHasharray    plugins.core.Common.sortNumericHasharray(hashArray, key)");
//		if ( hashArray == null )	return;
//		if ( key == null )	return;
//        console.log("  Common.Sort.sortNumericHasharray    hashArray: " + dojo.toJson(hashArray));
//		console.log("  Common.Sort.sortNumericHasharray    key: " + key);

	if ( hashArray == null )
	{
		console.log("  Common.Sort.sortNumericHasharray    hashArray is null. Returning");
		return;
	}
	
	if ( key == null )
	{
		console.log("  Common.Sort.sortNumericHasharray    key is null. Returning.");
		return;
	}

	// REMOVE NON-NUMERIC ENTRIES FOR SORT KEY
	for ( var i = 0; i < hashArray.length; i++ )
	{
		if ( parseInt(hashArray[i]) == "NaN" )
		{
			hashArray.splice(i, 1);
			i--;
		}
	}

	return hashArray.sort(function (a,b) {
		//console.log("  Common.Sort.sortNumericHasharray    a[" + key + "]: " + a[key]);
		//console.log("  Common.Sort.sortNumericHasharray    b[" + key + "]: " + b[key]);
		return parseInt(a[key]) == parseInt(b[key]) ?
			(  parseInt(a[key]) < parseInt(b[key]) ? -1
			: parseInt(a[key]) > parseInt(b[key])  )
			: (  parseInt(a[key]) < parseInt(b[key]) ? -1
			: parseInt(a[key]) > parseInt(b[key]) );
		}
	);

},
sortNaturally : function (a, b) {
// SORT BY LEFTMOST STRING THEN RIGHTMOST NUMBER
	//console.log("  Common.Sort.sortNaturally    a: " + a);
	//console.log("  Common.Sort.sortNaturally    b: " + b);

	var stringA = a.match(/^(\d*\D+)/);
	var stringB = b.match(/^(\d*\D+)/);
	
	//console.log("  Common.Sort.sortNaturally    stringA: " + stringA);
	//console.log("  Common.Sort.sortNaturally    stringB: " + stringB);
	
	if ( stringA && stringB ) {
		if ( stringA < stringB ) return -1;
		if ( stringA > stringB ) return 1;
	}
	if ( stringA && ! stringB )	return -1;
	if ( ! stringA && stringB )	return 1;
	
	var numberA = a.match(/(\d+)[^\/^\d]*$/);
	var numberB = b.match(/(\d+)[^\/^\d]*$/);
	
	//console.log("  Common.Sort.sortNaturally    numberA: " + numberA);
	//console.log("  Common.Sort.sortNaturally    numberB: " + numberB);
	
	if ( parseInt(numberA) && parseInt(numberB) ) {
		if ( parseInt(numberA) < parseInt(numberB) ) return -1;
		if ( parseInt(numberA) > parseInt(numberB) ) return 1;
		return 0;
	}
	if ( parseInt(numberA) && ! parseInt(numberB) )	return -1;
	if ( ! parseInt(numberA) && parseInt(numberB) )	return 1;

	return 0;	
},	
sortObjectsNaturally : function (a, b, key) {
// SORT BY LEFTMOST STRING THEN RIGHTMOST NUMBER
	//console.log("  Common.Sort.sortObjectsNaturally    a: " + a);
	//console.log("  Common.Sort.sortObjectsNaturally    b: " + b);
	//console.log("  Common.Sort.sortObjectsNaturally    key: " + key);

	if ( a[key] && ! b[key] )	return -1;
	if ( ! a[key] && b[key] )	return 1;
	if ( ! a[key] && ! b[key] )	return 0;

	var stringA = a[key].match(/^(\d*\D+)/);
	if ( stringA )	stringA = stringA[1];
	var stringB = b[key].match(/^(\d*\D+)/);
	if ( stringB )	stringB = stringB[1];
	
	//console.log("  Common.Sort.sortObjectsNaturally    stringA: " + stringA);
	//console.log("  Common.Sort.sortObjectsNaturally    stringB: " + stringB);
	
	if ( stringA && stringB ) {
		if ( stringA < stringB ) return -1;
		if ( stringA > stringB ) return 1;
	}
	if ( stringA && ! stringB )	return -1;
	if ( ! stringA && stringB )	return 1;
	
	var numberA = a[key].match(/(\d+)[^\/^\d]*$/);
	if ( numberA )	numberA = parseInt(numberA[1]);
	var numberB = b[key].match(/(\d+)[^\/^\d]*$/);
	if ( numberB )	numberB = parseInt(numberB[1]);
	
	//console.log("  Common.Sort.sortObjectsNaturally    numberA: " + numberA);
	//console.log("  Common.Sort.sortObjectsNaturally    numberB: " + numberB);
	
	if ( numberA && numberB ) {
		if ( numberA < numberB ) {
			//console.log("  Common.Sort.sortObjectsNaturally    Returning -1");
			return -1;
		}
		if ( numberA > numberB ) {
			//console.log("  Common.Sort.sortObjectsNaturally    Returning 1");
			return 1;
		}
		//console.log("  Common.Sort.sortObjectsNaturally    Returning 0");
		return 0;
	}
	if ( numberA && ! numberB )	return -1;
	if ( ! numberA && numberB )	return 1;

	return 0;	
},	
sortTwoDArray : function (twoDArray, index) {
// SORT AN ARRAY OF HASHES BY A SPECIFIED HASH FIELD
// NB: IF THE FIELD IS NULL OR EMPTY IN AN ARRAY ENTRY
// IT WILL BE DISCARDED.

	console.log("  Common.Sort.sortTwoDArray    plugins.core.Common.sortTwoDArray(twoDArray, key)");
	if ( twoDArray == null )	return;
	if ( index == null )	return;
	console.log("  Common.Sort.sortTwoDArray    twoDArray: " + dojo.toJson(twoDArray));
	console.log("  Common.Sort.sortTwoDArray    index: " + index);

	return twoDArray.sort(function (a,b) {
		console.log("  Common.Sort.sortTwoDArray    a[" + index + "]: " + a[index]);
		console.log("  Common.Sort.sortTwoDArray    b[" + index + "]: " + b[index]);
		
		if ( a[index] == null )
		{
			console.log("No value for index '" + index + "' in twoDArray item: " + dojo.toJson(a));
			return;
		}
		if ( b[index] == null )
		{
			console.log("No value for index '" + index + "' in twoDArray item: " + dojo.toJson(b));
			return;
		}

		return a[index].toUpperCase() == b[index].toUpperCase() ?
			(a[index] < b[index] ? -1
			: a[index] > b[index])
			: (a[index].toUpperCase() < b[index].toUpperCase() ? -1
			: a[index].toUpperCase() > b[index].toUpperCase());
		}
	);
}



});

}

if(!dojo._hasResource["plugins.core.Common.Text"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Common.Text"] = true;
dojo.provide("plugins.core.Common.Text");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	DATE METHODS  
*/

dojo.declare( "plugins.core.Common.Text",	[  ], {

///////}}}

repeatChar : function(character, length) {
    var string = '';
    for ( var i = 0; i < length; i++ ) {
        string += character;
    }
    
    return string;
},
xor : function (option1, option2) {
	//console.log("  Common.Text.xor    plugins.core.Common.xor(option1, option2)");
	//console.log("  Common.Text.xor    option1: " + option1);
	//console.log("  Common.Text.xor    option2: " + option2);
	if ( (option1 && ! option2)
		|| (! option1 && option2) )	return true;
	return false;
},
systemVariables : function (value, object) {
// PARSE THE SYSTEM VARIABLES. I.E., REPLACE %<STRING>% TERMS
	if ( object == null )	object = this;
	if ( value == null || value == true || value == false )	return value;
	if ( value.replace == null )	return value;
	
	//console.log("  Common.Text.systemVariables    plugins.core.Common.systemVariables(value)");
	//console.log("  Common.Text.systemVariables    value: " + dojo.toJson(value));
	
	value = value.replace(/%username%/g, Agua.cookie('username'));
	value = value.replace(/%project%/g, object.project);
	value = value.replace(/%workflow%/g, object.workflow);
	
	return value;
},
insertTextBreaks : function (text, width) {
// INSERT INVISIBLE UNICODE CHARACTER &#8203; AT INTERVALS OF
// LENGTH width IN THE TEXT
	//console.log("  Common.Text.insertTextBreaks    plugins.workflow.Workflow.insertTextBreaks(text, width)");
	//console.log("  Common.Text.insertTextBreaks    text: " + text);	
	//console.log("  Common.Text.insertTextBreaks    text.length: " + text.length);	
	//console.log("  Common.Text.insertTextBreaks    width: " + width);

	if ( this.textBreakWidth != null )	width = this.textBreakWidth;
	if ( width == null )	return;

	// SET INSERT CHARACTERS
	var insert = "\n";

	// FIRST, REMOVE ANY EXISTING INVISIBLE LINE BREAKS IN THE TEXT
	text = this.removeTextBreaks(text);

	// SECOND, INSERT A "&#8203;" CHARACTER AT REGULAR INTERVALS
	var insertedText = '';
	var offset = 0;
	while ( offset < text.length )
	{
		var temp = text.substring(offset, offset + width);
		offset += width;
		
		insertedText += temp;
		//insertedText += "&#8203;"
		insertedText += insert;
	}

	//console.log("  Common.Text.insertTextBreaks    Returning insertedText: " + insertedText);
	return insertedText;
},
removeTextBreaks : function (text) {
// REMOVE ANY LINE BREAK CHARACTERS IN THE TEXT
	//console.log("  Common.removeTextBreaks    plugins.workflow.Common.removeTextBreaks(text)");
	//console.log("  Common.removeTextBreaks    text: " + text);	
	text = text.replace(/\n/g, '');
	return text;
},
jsonSafe : function (string, mode) {
// CONVERT FROM JSON SAFE TO ORDINARY TEXT OR THE REVERSE
	//console.log("ApplicationTemplate.jsonSafe plugins.admin.ApplicationTemplate.jsonSafe(string, mode)");
	//console.log("ApplicationTemplate.jsonSafe string: " + string);
	//console.log("ApplicationTemplate.jsonSafe mode: " + mode);
	
	// SANITY CHECKS
	if ( string == null || ! string )
	{
		return '';
	}
	if ( string == true || string == false )
	{
		return string;
	}
	
	// CLEAN UP WHITESPACE
	string = String(string).replace(/\s+$/g,'');
	string = String(string).replace(/^\s+/g,'');
	string = String(string).replace(/"/g,"'");

	var specialChars = [
		[ '&quot;',	"'" ],	
		//[ '&quot;',	'"' ],	
		[ '&#35;', '#' ],	
		[ '&#36;', '$' ],	
		[ '&#37;', '%' ],	
		[ '&amp;', '&' ],	
		//[ '&#39;', "'" ],	
		[ '&#40;', '(' ],	
		[ '&#41;', ')' ],	
		[ '&frasl;', '/' ],	
		[ '&#91;', '\[' ],	
		[ '&#92;', '\\' ],	
		[ '&#93;', '\]' ],	
		[ '&#96;', '`' ],	
		[ '&#123;', '\{' ],	
		[ '&#124;', '|' ],	
		[ '&#125;', '\}' ]	
	];
	
	for ( var i = 0; i < specialChars.length; i++)
	{
		if ( mode == 'toJson' )
		{
			var sRegExInput = new RegExp(specialChars[i][1], "g");
			return string.replace(sRegExInput, specialChars[i][0]);
		}
		else if ( mode == 'fromJson' )
		{
			var sRegExInput = new RegExp(specialChars[i][0], "g");
			return string.replace(sRegExInput, specialChars[i][1]);
		}
	}
	
	return string;
},
autoHeight : function(textarea) {
	//console.log("  Common.Text.autoHeight    plugins.workflow.Workflow.autoHeight(event)");
	//console.log("  Common.Text.autoHeight    textarea: " + textarea);

	var rows = parseInt(textarea.rows);
	console.log("  Common.Text.autoHeight    textarea.rows: " + textarea.rows);

	while ( textarea.rows * textarea.cols < textarea.value.length )
	{
		textarea.rows = ++rows;
	}
	
	// REMOVE ONE LINE TO FIT SNUGLY
	//textarea.rows--; 
	
////    // THIS ALSO WORKS OKAY
////    console.log("  Common.Text.autoHeight    event.target.scrollHeight: " + event.target.scrollHeight );
////    
////    var height = event.target.scrollHeight;
////    var rows = parseInt((height / 15) - 2);
////
////    console.log("  Common.Text.autoHeight    height: " + height);
////    console.log("  Common.Text.autoHeight    rows: " + rows);
////
//////<textarea id="value" class="autosize" rows="3" cols="10">    
////    
////    console.log("  Common.Text.autoHeight    BEFORE event.target.setAttribute('rows', " + rows + "): " +  event.target.getAttribute('rows'));
////    
////    event.target.setAttribute('rows', rows);
////    
////
////    console.log("  Common.Text.autoHeight    AFTER event.target.setAttribute('rows', " + rows + "): " + event.target.getAttribute('rows'));}
},
firstLetterUpperCase : function (word) {
	if ( word == null || word == '' ) return word;
	if ( word.substring == null )	return null;
	return word.substring(0,1).toUpperCase() + word.substring(1);
},
cleanEnds : function (words) {
	if ( words == null )	return '';

	words = words.replace(/^[\s\n]+/, '');
	words = words.replace(/[\s\n]+$/, '');
	
	return words;
},
cleanWord : function (word) {
	//console.log("  Common.cleanWord    plugins.core.Common.cleanWord(word)");
	//console.log("  Common.cleanWord    word: " + word);

	if ( word == null )	return '';

	return word.replace(/[\s\n]+/, '');
},
clearValue : function (widget, value) {
	//console.log("  Common.clearValue    plugins.core.Common.clearValue(widget, value)");
	//console.log("  Common.clearValue    widget: " + widget);
	//console.log("  Common.clearValue    value: " + value);
	if ( widget == null )	return;

	if ( widget.get && widget.get('value') == value )
	{
		widget.set('value', '');
	}
	else if ( widget.value && widget.value.match(value) )
	{
		widget.value = '';
	}
},
cleanNumber : function (number) {
	//console.log("  Common.cleanNumber    plugins.core.Common.cleanNumber(number)");
	////console.log("Clusters.cleanNumber    BEFORE number: " + number);
	if ( number == null )	return '';
	number = number.toString().replace(/[\s\n]+/, '');
	////console.log("Clusters.cleanNumber    AFTER number: " + number);

	return number.toString().replace(/[\s\n]+/, '');
},
convertString : function (string, type) {
	if ( string == null )	return '';
	//console.log("  Common.Text.convertString    plugins.form.EditForm.convertString(string)");
	//console.log("  Common.Text.convertString    type: " + type);
	//console.log("  Common.Text.convertString    string: " + dojo.toJson(string));

	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;

	var before = string;
	string = this.convertAngleBrackets(string, type);
	string = this.convertAmpersand(string, type);
	string = this.convertQuote(string, type);

	//console.log("  Common.Text.convertString    converted " + dojo.toJson(before) + " to " + dojo.toJson(string));
	
	return string
},
convertBackslash : function (string, type) {
	//console.log("  Common.Text.convertBackslash    plugins.core.Common.convertBackslash(string, type)");	
//    console.log("  Common.Text.convertBackslash    string:" + dojo.toJson(string));
//	console.log("  Common.Text.convertBackslash    type: " + type);
	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	
	try {
		
		var multiplyString = function (string, num) {
			if (!num) return "";
			var newString = string;
			while (--num) newString += string;
			return newString;
		};
	
		var compress = function(match) {
			return multiplyString("\\", (match.length / 2));
		};
		
		var expand = function(match) {
			return multiplyString("\\", (match.length * 2));
		};
	
		if ( type == "compress" ) { 
			string = string.replace(/\\+/g, compress);
		}
		if ( type == "expand" ) { 
			string = string.replace(/\\+/g, expand);
		}
		//console.log("  Common.Text.convertBackslash    returning string:" + dojo.toJson(string));
		
	}
	catch (error) {
		//console.log("  Common.Text.convertBackslash    error:" + error);
		return "";
	}	
	
    return string;
},
convertAmpersand : function (string, type) {
	//console.log("  Common.Text.convertAmpersand    plugins.form.EditForm.convertAmpersand(string)");
	//console.log("  Common.Text.convertAmpersand    string: " + string);
	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	if ( type == "textToHtml")
		string = string.replace(/&/g, "&amp;");
	else
		string = string.replace(/&amp;/g, "&");
	return string;
},
convertQuote : function (string, type) {
	//console.log("  Common.Text.convertQuote    plugins.form.EditForm.convertQuote(string)");
	//console.log("  Common.Text.convertQuote    string: " + string);
	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	if ( type == "textToHtml")
		string = string.replace(/"/g, "&quot;");
	else
		string = string.replace(/&quot;/g, '"');
	return string;
},
convertAngleBrackets : function (string, type) {
	//console.log("  Common.Text.convertAngleBrackets    plugins.form.EditForm.convertAngleBrackets(string)");
	//console.log("  Common.Text.convertAngleBrackets    string: " + string);

	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	
	var specialChars = [
		[ '&lt;',	"<" ],
		[ '&gt;',	'>' ]
	];

	var from = 0;
	var to = 1;
	if ( type == "textToHtml")
	{
		from = 1;
		to = 0;
	}
	
	for ( var i = 0; i < specialChars.length; i++)
	{
		////console.log("  Common.Text.converString    converting from " +specialChars[i][from] + " to " + specialChars[i][to]);
		var sRegExInput = new RegExp(specialChars[i][from], "g");
		string = string.replace(sRegExInput, specialChars[i][to]);
	}

	return string;	
},
printObjectKeys : function (hasharray, key, label) {
	if ( label == null )	label = "key";
	for ( var i = 0; i < hasharray.length; i++ )
	{
		console.log(label + " " + i + ": " + hasharray[i][key]);
	}
},


});

}

if(!dojo._hasResource["plugins.core.Common.Util"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Common.Util"] = true;
dojo.provide("plugins.core.Common.Util");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	UTIL METHODS  
*/

dojo.declare( "plugins.core.Common.Util",	[  ], {

///////}}}

doPut : function (inputs) {
	console.log("    Common.Util.doPut    inputs: ");
	console.dir({inputs:inputs});
	var callback = function (){}
	if ( inputs.callback != null )	callback = inputs.callback;
	//console.log("    Common.Util.doPut    inputs.callback: " + inputs.callback);
	var doToast = true;
	if ( inputs.doToast != null )	doToast = inputs.doToast;
	var url = inputs.url;
	url += "?";
	url += Math.floor(Math.random()*100000);
	var query = inputs.query;
	var timeout = inputs.timeout ? inputs.timeout : null;
	var handleAs = inputs.handleAs ? inputs.handleAs : "json";
	var sync = inputs.sync ? inputs.sync : false;
	//console.log("    Common.Util.doPut     doToast: " + doToast);
	
	// SEND TO SERVER
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			preventCache : true,
			sync: sync,
			handleAs: handleAs,
			putData: dojo.toJson(query),
			timeout: timeout,
			load: function(response, ioArgs) {
				console.log("    Common.Util.doPut    response: ");
				console.dir({response:response});

				if ( response.error ) {
					if ( doToast ) {
						console.log("    Common.Util.doPut    DOING Agua.toastMessage ERROR");
						Agua.toastMessage({
							message: response.error,
							type: "error",
							duration: 10000
						});
					}
				}
				else {
					if ( response.status ) {
						if ( doToast ) {
						console.log("    Common.Util.doPut    DOING Agua.toastMessage STATUS");
							Agua.toastMessage({
								message: response.status,
								type: "warning",
								duration: 10000
							})
							if ( Agua.loader != null )	Agua.loader._hide();
						}
					}
					
					//console.log("    Common.Util.doPut    callback: " + callback);
					console.log("    Common.Util.doPut    DOING callback(response, inputs)");
					callback(response, inputs);
				}
			},
			error: function(response, ioArgs) {
				console.log("    Common.Util.doPut    Error with put. Response: " + response);
				return response;
			}
		}
	);	
},
getClassName : function (object) {
	//console.log("    Common.Util.getClassName    object: " + object);
	//console.dir({object:object});
	var className = new String(object);
	var name;
	if ( className.match(/^\[Widget\s+(\S+),/) )
		name = className.match(/^\[Widget\s+(\S+),/)[1];
	//console.log("    Common.Util.getClassName    name: " + name);

	return name;
},	
showMessage : function (message, putData) {
	console.log("    Common.Util.showMessage    Polling message: " + message)	
},
downloadFile : function (filepath, username) {
	//console.log("ParameterRow.downloadFile     plugins.workflow.ParameterRow.downloadFile(filepath, shared)");
	//console.log("ParameterRow.downloadFile     filepath: " + filepath);
	var query = "?mode=downloadFile";

	// SET requestor = THIS_USER IF PROVIDED
	if ( username != null )
	{
		query += "&username=" + username;
		query += "&requestor=" + Agua.cookie('username');
	}
	else
	{
		query += "&username=" + Agua.cookie('username');
	}

	query += "&sessionId=" + Agua.cookie('sessionId');
	query += "&filepath=" + filepath;
	//console.log("ParameterRow.downloadFile     query: " + query);
	
	var url = Agua.cgiUrl + "download.cgi";
	//console.log("ParameterRow.downloadFile     url: " + url);
	
	var args = {
		method: "GET",
		url: url + query,
		handleAs: "json",
		timeout: 10000,
		load: this.handleDownload
	};
	console.log("ParameterRow.downloadFile     args: ", args);

	console.log("ParameterRow.downloadFile     Doing dojo.io.iframe.send(args))");
	var value = dojo.io.iframe.send(args);
},
loadCSS : function (cssFiles) {
// LOAD EITHER this.cssFiles OR A SUPPLIED ccsFiles ARRAY OF FILES ARGUMENT

	//console.log("    Common.Util.loadCSS     plugins.admin.GroupUsers.loadCSS()");
	
	if ( cssFiles == null )
	{
		cssFiles = this.cssFiles;
	}
	//console.log("    Common.Util.loadCSS     cssFiles: " +  dojo.toJson(cssFiles, true));
	
	// LOAD CSS
	for ( var i in cssFiles )
	{
		//console.log("    Common.Util.loadCSS     Loading CSS file: " + this.cssFiles[i]);
		
		this.loadCSSFile(cssFiles[i]);
	}
},
loadCSSFile : function (cssFile) {
// LOAD A CSS FILE IF NOT ALREADY LOADED, REGISTER IN this.loadedCssFiles

	//console.log("    Common.Util.loadCSSFile    *******************");
	//console.log("    Common.Util.loadCSSFile    plugins.core.Common.loadCSSFile(cssFile)");
	//console.log("    Common.Util.loadCSSFile    cssFile: " + cssFile);
	//console.log("    Common.Util.loadCSSFile    this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));

	if ( Agua.loadedCssFiles == null || ! Agua.loadedCssFiles )
	{
		//console.log("    Common.Util.loadCSSFile    Creating Agua.loadedCssFiles = new Object");
		Agua.loadedCssFiles = new Object;
	}
	
	if ( ! Agua.loadedCssFiles[cssFile] )
	{
		console.log("    Common.Util.loadCSSFile    Loading cssFile: " + cssFile);
		
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		document.getElementsByTagName("head")[0].appendChild(cssNode);

		Agua.loadedCssFiles[cssFile] = 1;
	}
	else
	{
		//console.log("    Common.Util.loadCSSFile    No load. cssFile already exists: " + cssFile);
	}

	//console.log("    Common.Util.loadCSSFile    Returning Agua.loadedCssFiles: " + dojo.toJson(Agua.loadedCssFiles));
	
	return Agua.loadedCssFiles;
},
randomiseUrl : function (url) {
	url += "?dojo.preventCache=1266358799763";
	url += Math.floor(Math.random()*1000000000000);
	
	return url;
},
killPopup : function (combo) {
	//console.log("    Common.Util.killPopup    core.Common.killPopup(combo)");
	var popupId = "widget_" + combo.id + "_dropdown";
	var popup = dojo.byId(popupId);
	if ( popup != null )
	{
		var popupWidget = dijit.byNode(popup.childNodes[0]);
		dijit.popup.close(popupWidget);
	}	
},

});

}

if(!dojo._hasResource["plugins.core.Common"]){ //_hasResource checks added by build. Do not use _hasResource directly in your code.
dojo._hasResource["plugins.core.Common"] = true;
dojo.provide("plugins.core.Common");

/* 	CLASS SUMMARY: PROVIDE COMMONLY USED METHODS FOR ALL CLASSES.

	ALSO PROVIDE LOW-LEVEL METHODS THAT ACCOMPLISH GENERIC TASKS WHICH
	
	ARE WRAPPED AROUND BY CONTEXT-SPECIFIC METHODS
*/








dojo.declare( "plugins.core.Common", [
	plugins.core.Common.Array,
	plugins.core.Common.ComboBox,
	plugins.core.Common.Date,
	plugins.core.Common.Sort,
	plugins.core.Common.Text,
	plugins.core.Common.Util
], {

// HASH OF LOADED CSS FILES
loadedCssFiles : null,

});


}

