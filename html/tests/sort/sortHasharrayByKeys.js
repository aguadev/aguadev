var sortHasharrayByKeys = function (hashArray, keys, types) {

	if ( hashArray == null )	return;
	if ( keys == null )	return;
	if ( ! typeof hashArray == "ARRAY" || hashArray == null ) return;
	if ( ! typeof keys == "ARRAY" || keys == null ) return;

	return hashArray.sort(function (a,b) {

    //console.log("  Common.sortHasharray    a[" + key + "]: " + a[key]);

    //console.log("  Common.sortHasharray    b[" + key + "]: " + b[key]);

        var result = 1;
        for ( var i = 0; i < keys.length; i++ )
        {
            var key = keys[i];
            console.log("Doing key '" + key);
            if ( a[key] == null || b[key] == null )
            {
                console.log("No value for a['" + key + "']: " + a[key] + " or  b['" + key + "']: " + b[key] + " in hashArray items a: " + dojo.toJson(a) + " or b: " + dojo.toJson(b));
                continue;
            }
    
            if ( a[key].toUpperCase && b[key].toUpperCase )
            {

                var aString = a[key].toUpperCase(); 
                var bString = b[key].toUpperCase(); 
                console.log("aString: " + aString);
                console.log("bString: " + bString);
    
                result =  aString == bString ?
                ( a[key] < b[key] ? -1 : (a[key] > b[key] ? 1 : 0) )
                    : ( aString < bString ? -1 : (aString > bString ? 1 : 0) );
    
                console.log("result for key '" + key + "': " + result);
                if ( result != 0 )    break;
            }
            else
            {
                console.log("Comparing ints a['" + key + "']: " + a[key] + " and  b['" + key + "']: " + b[key]);
                result = a[key] < b[key] ? -1 :
                         ( a[key] > b[key] ? 1 : 0 );

                console.log("result for key '" + key + "': " + result);
                if ( result != 0 )    break;
            }  
        }
        
        return result;
    });

};
var hasharray = [ {"name":"xfile","ordinal":0},{"name":"afile","ordinal":1},{"name":"xfile","ordinal":2} ];
//var keys = ["name","ordinal"];
// var sorted = sortHasharrayByKeys(hasharray, keys);
// console.log("sorted: " + dojo.toJson(sorted));
// RESULT:
// sorted: [{"name":"afile","ordinal":1},{"name":"xfile","ordinal":0},{"name":"xfile","ordinal":2}]


var keys = ["ordinal","name"];
var sorted = sortHasharrayByKeys(hasharray, keys);
console.log("sorted: " + dojo.toJson(sorted));
// RESULT:
// sorted: [{"name":"xfile","ordinal":0},{"name":"afile","ordinal":1},{"name":"xfile","ordinal":2}]

