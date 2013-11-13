dojo.provide("t.unit.doh.util");

t.unit.doh.util.identicalFields = function (hashA, hashB, fields) {
	if ( ! hashA && ! hashB)	return 1;
	if ( ! hashA ) return 0;
	if ( ! hashB )	return 0;
	if ( ! fields )	return 0;
	for ( var i = 0; i < fields.length; i++ ) {
		if ( hashA[fields[i]] != hashB[fields[i]] )	return 0;
	}
	
	return 1;
}
t.unit.doh.util.randomizeArray = function (array) {
	array.sort(function() {return 0.5 - Math.random()}) 
	return array;
}
t.unit.doh.util.identicalHashes = function (hashA, hashB) {
	//console.log("t.unit.doh.util.identicalHashes    hashA:");
	//console.dir({hashA:hashA});
	//console.log("t.unit.doh.util.identicalHashes    hashB:");
	//console.dir({hashB:hashB});

	if ( ! hashA && ! hashB)	return 1;
	if ( ! hashA ) return 0;
	if ( ! hashB )	return 0;
	if ( hashA.length != hashB.length )	return 0;
	for ( var key in hashA) {
		if (  hashA[key] != hashB[key] )	return 0;
	}

	//console.log("t.unit.doh.util.identicalHashes    Returning 1");
	return 1;
}
t.unit.doh.util.identicalObjectArrays = function (actuals, expecteds, key) {
	//console.log("t.unit.doh.util.identicalObjectArrays    actuals:");
	//console.dir({actuals:actuals});
	//console.log("t.unit.doh.util.identicalObjectArrays    expecteds:");
	//console.dir({expecteds:expecteds});

	if ( ! actuals && ! expecteds)	return 1;
	if ( ! actuals ) return 0;
	if ( ! expecteds )	return 0;
	if ( actuals.length != expecteds.length )	return 0;
	for ( var i = 0; i < actuals.length; i++ ) {
		if (  actuals[i][key] != expecteds[i][key] )	return 0;
	}

	//console.log("t.unit.doh.util.identicalObjectArrays    Returning 1");
	return 1;
}
t.unit.doh.util.identicalOrderHashArrays = function (actuals, expecteds) {
	//console.log("t.unit.doh.util.identicalObjectArrays    actuals:");
	//console.dir({actuals:actuals});
	//console.log("t.unit.doh.util.identicalObjectArrays    expecteds:");
	//console.dir({expecteds:expecteds});

	if ( ! actuals && ! expecteds)	return 1;
	if ( ! actuals ) return 0;
	if ( ! expecteds )	return 0;
	if ( actuals.length != expecteds.length )	return 0;
	for ( var i = 0; i < actuals.length; i++ ) {
		if ( ! this.identicalHashes(actuals[i], expecteds[i]) )	return 0;
	}

	//console.log("t.unit.doh.util.identicalObjectArrays    Returning 1");
	return 1;
}
t.unit.doh.util.identicalArrays = function (actuals, expecteds) {
	//console.log("t.unit.doh.util.identicalArrays    actuals:");
	//console.dir({actuals:actuals});
	//console.log("t.unit.doh.util.identicalArrays    expecteds:");
	//console.dir({expecteds:expecteds});

	if ( ! actuals && ! expecteds)	return 1;
	if ( ! actuals ) return 0;
	if ( ! expecteds )	return 0;
	if ( actuals.length != expecteds.length )	return 0;
	for ( var i = 0; i < actuals.length; i++ ) {
		if (  actuals[i] != expecteds[i] )	return 0;
	}

	//console.log("t.unit.doh.util.identicalArrays    Returning 1");
	return 1;
}
t.unit.doh.util.identicalArrayHashes = function (actuals, expecteds) {
	//console.log("t.unit.doh.util.identicalArrays    actuals:");
	//console.dir({actuals:actuals});
	//console.log("t.unit.doh.util.identicalArrays    expecteds:");
	//console.dir({expecteds:expecteds});

	if ( ! actuals && ! expecteds)	return 1;
	if ( ! actuals ) return 0;
	if ( ! expecteds )	return 0;
	if ( actuals.length != expecteds.length )	return 0;
	for ( var i = 0; i < actuals.length; i++ ) {
		if ( ! this.identicalArrays(actuals[i], expecteds[i]) )	return 0;
	}

	//console.log("t.unit.doh.util.identicalArrays    Returning 1");
	return 1;
}
t.unit.doh.util.fetchJson = function(url) {
	//console.log("t.unit.doh.util.fetchJson    t.unit.doh.util.fetchJson()");

    var jsonObject;
    dojo.xhrGet({
        // The URL of the request
        url: url,
		// Make synchronous so we wait for the data
		sync: true,
		// Long timeout
		timeout: 5000,
        // Handle as JSON Data
        handleAs: "json",
        // The success callback with result from server
        load: function(response) {
			jsonObject = response;
	    },
        // The error handler
        error: function() {
            console.log("t.unit.doh.util.fetchJson    Error, response: " + dojo.toJson(response));
        }
    });

	return jsonObject;
}
t.unit.doh.util.fetchText = function(url) {
	console.log("t.unit.doh.util.fetchJson    t.unit.doh.util.fetchText()");		

    var text;
    dojo.xhrGet({
        // The URL of the request
        url: url,
		// Make synchronous so we wait for the data
		sync: true,
		// Long timeout
		timeout: 5000,
        // Handle as JSON Data
        handleAs: "text",
        // The success callback with result from server
        load: function(response) {
			text = response;
	    },
        // The error handler
        error: function() {
            console.log("t.unit.doh.util.fetchJson    Error, response: " + dojo.toJson(response));
        }
    });

	return text;
}
t.unit.doh.util.getHashKeys = function(hash) {
	//console.log("t.unit.doh.util.getHashKeys    hash:");
	//console.dir({hash:hash});
	var keys = [];
	for ( var key in hash ) {
		keys.push(key);
	}
	
	return keys;
}


t.unit.doh.util.getClassName = function (object) {
	var className = new String(object);
	var name;
	if ( className.match(/^\[Widget\s+(\S+),/) )
		name = className.match(/^\[Widget\s+(\S+),/)[1];
	//console.log("    Common.Util.getClassName    name: " + name);

	return name;
}	


