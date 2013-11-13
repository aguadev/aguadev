define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/core/Common",
],
function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, Common) {
////}}}}}
return declare("plugins.infusion.Data", [Common], {

// storedHashes : Hash
// 		Hash with keys 'table::mode::id1::id2'. Contains hashes for quick lookup
storedHashes : {},

// dataKeys : Array
//		Default list of keys for this.storedHashes
dataKeys : [
	
	"build_report::objectHash::sample_id",
	"flowcell::hash::flowcell_id::flowcell_barcode",	
	"flowcelllaneqc::twoDHash::flowcell_id::lane_id",
	"flowcellreporttrim::twoDHash::flowcell_id::lane_id",
	"lane::objectArrayHash::sample_id",
	"project::hash::project_id::project_name",
	"project::objectHash::project_id::project_name",	
	"requeuereport::objectHash::sample_id",
	"sample::hash::sample_id::project_id",
	"sample::hash::sample_id::sample_name",
	"sample::hash::sample_barcode::sample_id",
	"sample::hash::sample_id::sample_barcode",
	"sample::objectArrayHash::project_id",
	"trimreport::objectHash::flowcell_id::lane_id",

],

/////}}}}

// STORED HASHES
initialiseData : function () {
	this.generateData(this.dataKeys);
},
generateData : function (keys) {
	console.log("Data.generateData    keys: " + keys);
	//console.dir({keys:keys});
	
	// SET REGEX
	var regex = new RegExp(/^([^:])+::([^:]+)::([^:]+)::([^:]*)$/);

	for ( var i = 0; i < keys.length; i++ ) {
		if ( ! keys[i].match(regex) ) {
			continue;
		}
		var array 	= 	keys[i].split(/::/g);
		//console.log("Data.generateData    array: ");
		//console.dir({array:array});
		var table 	= 	array[0];
		var mode 	= 	array[1];
		var id1		= 	array[2];
		var id2		= 	array[3];
		
		this.generateHash(table, mode, id1, id2);
	}
},
getHash : function (table, mode, id1, id2) {
// summary: Get a particular hash for a specific table from this.storedHashes, a
//		kind of DATA CLEARING HOUSE - a collection of hashes and arrays stored in
//		memory for fast lookups.
//		Retrieval of data from the return hash/array is based the provided key(s).
//		Hash is simply retrieved if already generated.
//		Otherwise, the hash is generated and added to this.storedHashes,
//		
// table: String
//		Name of table to be retrieved
// mode: String
//		Type of retrieval
//		Values: hash, arrayHash, objectHash, objectArrayHash, twoDHash, objectArray
// id1: String
//		Name of first hash field to use for retrieval
// id2: String
//		Name of second hash field to use for retrieval
// Returns: A hash, empty if no data available

	if ( mode != "hash" && mode != "") {
		//code
	}
	if ( ! id2 ) {
		id2 = '';
	}
	var key = table + "::" + mode + "::" + id1 + "::" + id2;
	if ( this.storedHashes[key]) {
		return this.storedHashes[key];
	}

	return this.generateHash(table, mode, id1, id2);
},
generateHash : function (table, mode, id1, id2) {
	var hash = this[mode](table, id1, id2) || {};	

	var key = table + "::" + mode + "::" + id1 + "::" + id2;
	this.storedHashes[key] = hash;
	
	return hash;
},
refreshData : function () {
// Summary: Delete and generate anew all hashes in this.storedHashes

	// DELETE
	var keys = this.flushData();
	
	// GENERATE ANEW
	this.generateData(keys);
},
flushData : function () {
// Summary: Delete all data in this.storedHashes
	var keys = [];
	for ( var key in this.storedHashes ) {
		keys.push(key);
		delete this.storedHashes[key]; 
	}
	
	return keys;
},
// HASH UTILITY METHODS
twoDHash : function (table, id1, id2) {
    var data = this.getTable(table);
	var hash = {};
	arrayUtil.forEach(data, function(item, i) {
		if ( item[id1] && item[id2] ) {
            if ( ! hash[item[id1]] ) {
                hash[item[id1]] = {};
            }
            hash[item[id1]][item[id2]] = item;
        }
	});
    
    return hash;    
},
arrayHash : function (table, id1, id2) {
	var data = this.getTable(table);
	var hash = {};
	arrayUtil.forEach(data, function(item, i) {
		if( ! hash[item[id1]] ) {
			hash[item[id1]] = new Array;
		}
		hash[item[id1]].push(item[id2]);
	});

	return hash;
},
objectHash : function (table, id) {
    //console.log("Data.objectHash    table : " + table);
    //console.log("Data.objectHash    id : " + id);
	
	var data = this.getTable(table);
	var hash = {};
	arrayUtil.forEach(data, function(item, i) {
		hash[item[id]] = item;
	});

	//console.log("Data.objectHash    hash: ");
	//console.dir({hash:hash});
	
	return hash;
},
objectArrayHash : function (table, id) {
	//console.log("Data.objectArrayHash    name: " + name);
	//console.log("Data.objectArrayHash    table: " + table);
	//console.log("Data.objectArrayHash    id: " + id);

	var data = this.getTable(table);
	if ( ! data ) return;
	
	////console.log("Data.objectArrayHash    data:" + JSON.stringify(data));
	//console.log("Data.objectArrayHash    data: ");
    //console.dir({data:data});

	var hash = {};
	arrayUtil.forEach(data, function(item, i) {
		if( ! hash[item[id]] ) {
			hash[item[id]] = new Array;
		}
		hash[item[id]].push(item);
	});
//	console.log("Data.objectArrayHash    hash: ");
//    console.dir({hash:hash});
    
    return hash;
},
hash : function (table, id1, id2) {
    //console.log("Data.setHash    table: " + table);
    //console.log("Data.setHash    BEFORE this.getTable(" + table + ")");    
	var data = this.getTable(table);
    //console.log("Data.setHash    AFTER this.getTable(" + table + ")");

	var hash = {};
	arrayUtil.forEach(data, function(item, i) {
		hash[item[id1]] = item[id2];
	});
//	console.log("Data.hash    hash: ");
//    console.dir({hash:hash});

    return hash;
},
// OBJECTS
getProjectObject : function (projectName) {
	console.log("Data.getProjectObject    projectName: " + projectName);

    var projects = this.getTable("project");
	console.log("Data.getProjectObject    projects:");
	console.dir({projects:projects});
	
	var object = this._getObjectByKeyValue(projects, "project_name", projectName);
	console.log("Data.getProjectObject    object:");
	console.dir({object:object});
	
	return object;
},
getFlowcellObject : function (flowcellBarcode) {
	console.log("Data.getFlowcellObject    flowcellBarcode: " + flowcellBarcode);

    var flowcells = this.getTable("flowcell");
	console.log("Data.getFlowcellObject    flowcells:");
	console.dir({flowcells:flowcells});
	
	var object = this._getObjectByKeyValue(flowcells, "flowcell_barcode", flowcellBarcode);
	console.log("Data.getFlowcellObject    object:");
	console.dir({object:object});
	
	return object;
},
getSampleObject : function (sampleBarcode) {
	console.log("Data.getSampleObject    sampleBarcode: " + sampleBarcode);

    var samples = this.getTable("sample");
	console.log("Data.getSampleObject    samples:");
	console.dir({samples:samples});
	
	var object = this._getObjectByKeyValue(samples, "sample_barcode", sampleBarcode);
	console.log("Data.getSampleObject    object:");
	console.dir({object:object});
	
	return object;
},
getLaneObject : function (laneBarcode) {
	console.log("Data.getLaneObject    laneBarcode: " + laneBarcode);

	var laneId = laneBarcode.match(/_(\d+)$/)[1];
	console.log("Data.getLaneObject    laneId: " + laneId);
	
	var flowcellBarcode = laneBarcode.match(/^(.+)_\d+$/)[1];
	console.log("Data.getLaneObject    flowcellBarcode: " + flowcellBarcode);

	var hash = this.getHash("flowcell", "hash", "flowcell_barcode", "flowcell_id");
	var flowcellId = hash[flowcellBarcode];
	console.log("Data.getLaneObject    flowcellId: " + flowcellId);
	
    var lanes = this.getTable("lane");
	console.log("Data.getLaneObject    lanes.length: " + lanes.length);
	console.log("Data.getLaneObject    lanes[0]: " );
	console.dir({lanes_0:lanes[0]});
	console.log("Data.getLaneObject    lanes:");
	console.dir({lanes:lanes});
	
	var objects = this.filterByKeyValues(lanes, ["flowcell_id", "lane_id"], [flowcellId, laneId]);
	console.log("Data.getLaneObject    objects:");
	console.dir({objects:objects});
	
	return objects[0];
},
// TABLE
getTable : function (table) {
	//console.log("Data.getTable    table: " + table);
	//console.log("Data.getTable    Agua.data: ");
	//console.dir({Agua_data:Agua.data});
	if ( Agua.data ) {
		return Agua.cloneData(table);
	}
	return window.Agua.cloneData(table);
},
updateTable : function (table, data) {
	console.log("Data.updateTable    table: " + table);
	console.log("Data.updateTable    data:");
	console.dir({data:data});

	// SET KEYS	TO UNIQUELY IDENTIFY DATA OBJECT IN TABLE
	var keys = [];
	if ( table == "project" ) 	keys = ["project_id"];
	if ( table == "sample" ) 	keys = ["sample_id"];
	if ( table == "flowcell" )	keys = ["flowcell_id"];
	if ( table == "lane" ) 		keys = ["lane_id"];

	// REMOVE IF EXISTS	
	var removed = Agua.removeData(table, data, keys);
	//console.log("Data.updateTable    removed:");
	//console.dir({removed:removed});
	
	// ADD TO TABLE
	if ( ! Agua.addData(table, data, keys) ) {
		console.log("Data.updateTable    Can't update table '" + table + "' with data: " + JSON.stringify(data))
		return false;
	}

	// SORT TABLE
	Agua.sortData(table, keys[0]);
	
	var subscription = "update" + table.substring(0,1).toUpperCase() + table.substring(1) + "s";
	//console.log("Data.updateTable    BEFORE Infusion.updater.update(" + subscription + ")");
	if ( Infusion.updater ) {
		console.log("Data.updateTable    DOING Infusion.updater.update(" + subscription + ")");
		console.log("Data.updateTable    DISABLED FOR NOW");
		//Infusion.updater.update(subscription, { originator : this });
	}
	//console.log("Data.updateTable    AFTER Infusion.updater.update(" + subscription + ")");
	
	console.log("Data.updateTable    Returning true");
	return true;
},
updateProject : function () {

	// UPDATE WIDGETS WITH Observe DATA STORES
	console.log("Data.updateProject    DOING this.initialiseData()");
	this.initialiseData();

	// UPDATE PARENT WIDGET DATA STORE
	console.log("Data.updateProjects    DOING this.getDataStore()");
	var dataStore = this.getDataStore();
	//console.log("Project.handleSave    dataStore:");
	//console.dir({dataStore:dataStore});
	console.log("Data.updateProjects    DOING this.refreshLists(dataStore)");
	this.refreshLists(dataStore);
	
},
loadTable : function (table) {
// LOAD ALL DATA, INCLUDING SHARED PROJECT DATA
	console.log("Data.loadTable    plugins.Data.loadTable()");		
	console.log("Data.loadTable    Agua.dataUrl: " + Agua.dataUrl);
	
	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var url = Agua.cgiUrl + "infusion.cgi";
	var query = new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.mode 			= 	"getTable";
	query.table			= 	table;
	query.module 		= 	"Infusion::Base";
    if ( Agua.database )
        query.database 	= Agua.database;
	
	console.log("Data.loadTable    query: ");
	console.dir({query:query});

	var thisObject = this;
	dojo.xhrPut(
		{
			url: url,
			putData: dojo.toJson(query),
			handleAs: "json",
			preventCache : true,
			sync: true,
			load: function(response, ioArgs) {
				console.log("Data.loadTable    response:");
				console.dir({response:response});

				if ( response.error ) {
					//Agua.error(response.error);
				}
				else {
					Agua.data[table] = response;
				}
			},
			error: function(response, ioArgs) {
				console.log("Error with JSON Post, response: " + dojo.toJson(response) + ", ioArgs: " + dojo.toJson(ioArgs));
			}
		}
	);
	return null;	
},
addProject : function (project) {
	this.updateTable("project", project);	
},
addSamples : function (samples) {
	//console.log("Data.addSamples    Agua.data:");
	//console.dir({Agua_data:Agua.data});
	//console.log("Data.addSamples    samples:");
	//console.dir({samples:samples});

	// REMOVE FROM TABLE
	var keys = ["sample_id"];
	//Agua._removeObjectsFromArray(Agua.data.sample, samples, keys);
	
	// ADD ARRAY OF SAMPLES
	var table = "sample";
	for ( var i = 0; i < samples.length; i++ ) {
		var data = samples[i];
		// REMOVE IF EXISTS	
		var removed = Agua.removeData(table, data, keys);
		//console.log("Data.addSamples    removed:");
		//console.dir({removed:removed});
		
		// ADD TO TABLE
		if ( ! Agua.addData(table, data, keys) ) {
			console.log("Data.addSamples    Can't update table '" + table + "' with data: " + JSON.stringify(data))
			return [];
		}
	
		//Agua.addArrayToData("sample", samples, ["sample_id"]);
	}

	// UPDATE TABLE
	return samples;	
}

//getFlowcellObject : function (flowcellId) {
//	console.log("Data.getFlowcellObject    flowcellId: " + flowcellId);
//
//    var flowcells = this.getTable("flowcell");
//	console.log("Data.getFlowcellObject    flowcells:");
//	console.dir({flowcells:flowcells});
//	
//	var object = this._getObjectByKeyValue(flowcells, "flowcell_id", flowcellId);
//	console.log("Data.getFlowcellObject    object:");
//	console.dir({object:object});
//	
//	return object;
//},

//getLaneObject : function (flowcellId, laneId) {
//	console.log("Data.getLaneObject    flowcellId: " + flowcellId);
//	console.log("Data.getLaneObject    laneId: " + laneId);
//
//    var lanes = this.getTable("lane");
//	console.log("Data.getLaneObject    lanes:");
//	console.dir({lanes:lanes});
//	
//	var object = this.filterByKeyValues(lanes, ["flowcell_id", "lane_id"], [flowcellId, laneId]);
//	console.log("Data.getLaneObject    object:");
//	console.dir({object:object});
//	
//	return object;
//},

}); 	//	end declare

});	//	end define
