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
	
	if ( object == null ) {
		//console.log("  Common.Array._addObjectToArray    Empty object. Returning true");
		return true;
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

	if ( object == null ) {
		//console.log("  Common.Array._removeObjectFromArray    Empty object. Returning true");
		return true;
	}
	
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
_removeObjectsFromArray : function (hasharray, objects, keys) {
// REMOVE AN OBJECT FROM AN ARRAY, IDENTIFY OBJECT USING SPECIFIED KEY VALUES
	////console.log("  Common.Array._removeObjectsFromArray    hasharray: " + dojo.toJson(hasharray, true));
	//console.log("  Common.Array._removeObjectsFromArray    objects: ");
	console.dir({objects:objects});
	//console.log("  Common.Array._removeObjectsFromArray    keys: " + dojo.toJson(keys));
	if ( hasharray == null )	return;	

	var removed = [];
	for ( var i = 0; i < hasharray.length; i++ ) {
		var arrayObject = hasharray[i];
		for ( var objectIndex = 0; objectIndex < objects.length; objectIndex++ ) {
			var object = objects[objectIndex];

			var identified = true;
			for ( var j = 0; j < keys.length; j++ ) {
				if ( ! arrayObject[keys[j]] && object[keys[j]]
					|| arrayObject[keys[j]] && ! object[keys[j]]
				) {
					identified = false;
					break;
				}
				if ( arrayObject[keys[j]].toString() != object[keys[j]].toString() ) {
					identified = false;
					break;
				}
			}
	
			if ( identified == true ) {
				removed.push(hasharray.splice(i, 1));
				i--;
			}
		}
	}
	
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

	console.log("  Common.Array._addArrayToArray    Returning success: " + success);
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
_identicalHashes : function (hashA, hashB) {
	//console.log("t.doh.util.identicalHashes    hashA:");
	//console.dir({hashA:hashA});
	//console.log("t.doh.util.identicalHashes    hashB:");
	//console.dir({hashB:hashB});

	if ( ! hashA && ! hashB)	return 1;
	if ( ! hashA ) return 0;
	if ( ! hashB )	return 0;
	if ( hashA.length != hashB.length )	return 0;
	for ( var key in hashA) {
		//console.log("t.doh.util.identicalHashes    typeof hashA[" + key + "]: " + typeof hashA[key]);

		if ( typeof hashA[key] == "object" ) {
			if ( ! this._identicalHashes(hashA[key], hashB[key]) ) return 0;
		}
		else {
			if (  hashA[key] != hashB[key] )	return 0;
		}
		
	}

	//console.log("t.doh.util.identicalHashes    Returning 1");
	return 1;
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
			//console.log("  Common.Array.filterByKeyValues    removed name: " + hasharray[i][keyarray[j]] + ", value : " + valuearray[j]);
			hasharray.splice(i, 1);
			i--;
		}
	}
	
	//console.log("  Common.Array.filterByKeyValues    Returning hasharray: " + dojo.toJson(hasharray));
	return hasharray;
},
// two-D ARRAY
_addArrayToTwoDArray : function (twoDArray, array, requiredKeys) {
// ADD AN ARRAY TO A TWO-D ARRAY, CHECK REQUIRED KEY VALUES ARE NOT NULL
	//console.log("  Common.Array._addArrayToTwoDArray    twoDArray: " + dojo.toJson(twoDArray));
	//console.log("  Common.Array._addArrayToTwoDArray    array: " + dojo.toJson(array, true));
	//console.log("  Common.Array._addArrayToTwoDArray    requiredKeys: " + dojo.toJson(requiredKeys));
	
	if ( twoDArray == null )
	{
		//console.log("  Common.Array._addArrayToTwoDArray    twoDArray is null. Creating new Array.");
		twoDArray = new Array;
	}
	
	var notDefined = this.notDefined(array, requiredKeys);
	if ( notDefined.length > 0 )
	{
		console.log("  Common.Array._addArrayToTwoDArray    notDefined: " + dojo.toJson(notDefined));
		return false;
	}
	//console.log("  Common.Array._addArrayToTwoDArray    Doing twoDArray.push(array)");
	twoDArray.push(array);
	//console.log("  Common.Array._addArrayToTwoDArray    AFTER twoDArray.push(array). twoDArray: " + dojo.toJson(twoDArray));

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
	//console.log("  Common.Array.getEntry    Returning null");

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