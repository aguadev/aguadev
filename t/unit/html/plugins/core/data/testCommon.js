var stageObject = {"project":"Project1","workflow":"abacus","name":"TOPHAT","owner":"admin","number":"1","type":"aligner","username":"syoung","sessionid":"9999999999.9999.999","mode":"removeStage"};
var Workflow = Agua.controllers.workflow.tabPanes[0];
console.log("Workflow: " + Workflow);

var Stages = Workflow.stages
console.log("Stages: " + Stages);

console.log("BEFORE Agua.getStageParameters().length: " + Agua.getStageParameters().length);

Agua.removeStage(stageObject);

console.log("AFTER Agua.getStageParameters().length: " + Agua.getStageParameters().length);





var stageObject = {"project":"Project1","workflow":"abacus","name":"TOPHAT","owner":"admin","number":"1","type":"aligner","username":"syoung","sessionid":"9999999999.9999.999","mode":"removeStage"};
Agua.removeStage(stageObject);



var _getIndexInArray = function (hasharray, object, keys) {

// GET THE INDEX OF AN OBJECT IN AN ARRAY, IDENTIFY OBJECT USING SPECIFIED KEY VALUES



	//console.log("Common._getIndexInArray    plugins.core.Common._getIndexInArray(hasharray, object, keys)");

	//console.log("Common._getIndexInArray    hasharray: " + dojo.toJson(hasharray));

	//console.log("Common._getIndexInArray    object: " + dojo.toJson(object));

	//console.log("Common._getIndexInArray    keys: " + dojo.toJson(keys));

	

	if ( hasharray == null )

	{

		console.log("Common._getIndexInArray    hasharray is null. Returning null.");

		return null;

	}

	

	for ( var i = 0; i < hasharray.length; i++ )

	{

		var arrayObject = hasharray[i];

		//console.log("Common._getIndexInArray    arrayObject: " + dojo.toJson(arrayObject));

		var identified = true;

		for ( var j = 0; j < keys.length; j++ )

		{

			//console.log("Common._getIndexInArray    Checking value for keys[" + j + "]: " + keys[j] + ": " + arrayObject[keys[j]]);

			if ( arrayObject[keys[j]] != object[keys[j]] )

			{

				//console.log("Common._getIndexInArray    object[" + keys[j] + "] : " + object[keys[j]]);

				//console.log("Common._getIndexInArray    arrayObject[" + keys[j] + "] : " + arrayObject[keys[j]]);

				//console.log("Common._getIndexInArray    " + arrayObject[keys[j]] + "** != **" + object[keys[j]] + "**");

				identified = false;

				break;

			}

		}

		//console.log("Common._getIndexInArray    identified: " + identified);



		if ( identified == true )

		{

			//console.log("Common._getIndexInArray    Returning index: " + i);

			return i;

		}

	}

	

	return null;

};



var _removeObjectFromArray = function (array, object, keys) {

// REMOVE AN OBJECT FROM AN ARRAY, IDENTIFY OBJECT USING SPECIFIED KEY VALUES



	//console.log("Common._removeObjectFromArray    plugins.core.Common._removeObjectFromArray(array, object, keys)");

	//console.log("Common._removeObjectFromArray    array: " + dojo.toJson(array, true));

	//console.log("Common._removeObjectFromArray    object: " + dojo.toJson(object, true));

	//console.log("Common._removeObjectFromArray    keys: " + dojo.toJson(keys));



	// DEBUG splitace.pl

	var arrayCopy = dojo.clone(array);

	//console.log("Common._removeObjectFromArray    arrayCopy: " + dojo.toJson(arrayCopy, true));

	

	var index = _getIndexInArray(array, object, keys);

	//console.log("Common._removeObjectFromArray    index: " + index);



	if ( index == null )	return false;

	

	//console.log("Common._removeObjectFromArray    BEFORE SPLICE array.length: " + array.length);

	array.splice(index, 1);

	//console.log("Common._removeObjectFromArray    AFTER SPLICE array.length: " + array.length);



	return true;

};



var _removeArrayFromArray = function(hasharray, removeThis, uniqueKeys) {

// REMOVE AN ARRAY OF OBJECTS FROM A LARGER ARRAY CONTAINING IT,

// IDENTIFYING OBJECTS USING THE SPECIFIED KEY VALUES



	console.log("Agua.removeArrayFromArray    Removing parameters[" + j + "]");

	console.log("Agua.removeArrayFromArray    hasharray.length: " + hasharray.length);

	console.log("Agua.removeArrayFromArray    removeThis.length: " + removeThis.length);

	

	var success = true;

	for ( var j = 0; j < removeThis.length; j++ )

	{

		////console.log("Agua.removeArrayFromArray    Removing removeThis[" + j + "]");

		////console.log("Agua.removeArrayFromArray    Removing removeThis[" + j + "]: " + dojo.toJson(removeThis[j]));

		


		var removeSuccess = _removeObjectFromArray(hasharray, removeThis[j], uniqueKeys);

		////console.log("Agua.removeArrayFromArray    removeSuccess: " + dojo.toJson(removeSuccess));



		////////// ***** DEBUG ONLY *****

		////////if ( removeSuccess == false )

		////////{				

		////////	//console.log("Agua.removeArrayFromArray    Could not remove stage parameter from hasharray: " + dojo.toJson(removeThis[j], true));

		////////	success = false;

		////////}

	}

	console.log("Agua.removeArrayFromArray    FINAL hasharray.length: " + hasharray.length);

	

	return success;

};



var stageObject = {"owner":"admin","project":"Project1","workflow":"abacus","appname":"TOPHAT","appnumber":"1"};
console.log("stageobj: " + dojo.toJson(stageobj));

var stageParams = dojo.clone(Agua.getStageParameters());
//console.log("stageParams: " + dojo.toJson(stageParams));
console.log("stageParams.length: " + stageParams.length);

var keys = [ "owner", "project", "workflow", "appname", "appnumber" ];
	var values = [ stageObject.owner, stageObject.project, stageObject.workflow, stageObject.appname, stageObject.appnumber ];

var removeTheseStageParams = Agua.filterByKeyValues(dojo.clone(stageParams), keys, values);
console.log("removeTheseStageParams.length: " + removeTheseStageParams.length);

var uniqueKeys = [ "username", "project", "workflow", "appname", "appnumber", "name"];

console.log("Doing _removeArrayFromArray");
var removeOk = _removeArrayFromArray(stageParams, removeTheseStageParams, uniqueKeys);
console.log("removeOk: " + removeOk);
