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

		return a[key].toString().toUpperCase() == b[key].toString().toUpperCase() ?
			(a[key] < b[key] ? -1
			: a[key] > b[key])
			: (a[key].toString().toUpperCase() < b[key].toString().toUpperCase() ? -1
			: a[key].toString().toUpperCase() > b[key].toString().toUpperCase());
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