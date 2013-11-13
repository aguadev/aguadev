define(
	[
		"dojo/_base/declare",
		"dojo/store/Memory",
		"plugins/infusion/Data",
		"dojo/_base/array",
	],
///////}}}}}}}

function(declare, Memory, Data, arrayUtil){	
///////}}}}}
///////}}}}}}}

return declare("plugins.infusion.Infusion",[Memory], {
///////}}}}}
///////}}}}}}}

startup : function () {
	console.log("DataStore.startup    DOING this.getData()");
	if ( ! this.core ) {
		this.core = new Object();
	}
	if ( ! this.core.data ) {
		this.core.data = new Data();
	}
	var data = this.getData();
	console.log("DataStore.startup    data: ");
	console.dir({data:data});
	
	this.setData(data);
	
	return data;
},
getData : function () {
// GET DATA FOR dataStore
	console.log("DataStore.getData");
	var items = this.getItems();	
	var data = {
		identifier	: 	"projectname",
		label		:	"projectname",
		items		:	items
	};	
	this.data = data;
	
	return data;
},
getItems : function () {
	console.log("DataStore.getItems");

	// GET LANES	
	var lanes = this.core.data.getTable("lane");
	console.log("DataStore.setData    lanes:");
	console.dir({lanes:lanes});

	// ADD SAMPLES WITHOUT LANES
	lanes = this.addSamplesWithoutLanes(lanes);
	console.log("DataStore.getItems    lanes: ");
	console.dir({lanes:lanes});
   
   // GET STORED HASHES
	var sampleIdNameHash	=	this.core.data.getHash("sample", "hash", "sample_id", "sample_name");
	var sampleIdBarcodeHash	=	this.core.data.getHash("sample", "hash", "sample_id", "sample_barcode");
	var sampleIdProjectIdHash=	this.core.data.getHash("sample", "hash", "sample_id", "project_id");
	var projectIdNameHash	= 	this.core.data.getHash("project", "hash", "project_id", "project_name");
	var flowcellIdBarcodeHash = this.core.data.getHash("flowcell", "hash", "flowcell_id", "flowcell_barcode");

	// STATUS HASHES
	var statusIdStatusHash		=	this.core.data.getHash("status", "hash", "status_id", "status");
	var projectIdStatusIdHash	= 	this.core.data.getHash("project", "hash", "project_id", "status_id");
	var sampleIdStatusIdHash	= 	this.core.data.getHash("sample", "hash", "sample_id", "status_id");
	var flowcellIdStatusIdHash	= 	this.core.data.getHash("flowcell", "hash", "flowcell_id", "status_id");
	var laneIdStatusIdHash		= 	this.core.data.getHash("lane", "hash", "lane_id", "status_id");
   
   
	// BUILD HASHARRAY: [{project:project_id,sample:sample_id,lane:lane_id}, ...]
	var thisObject = this;
	var items = [];
	arrayUtil.forEach(lanes, function(lane, i) {
		var flowcellId		=	lane.flowcell_id;
		var sampleId		=	lane.sample_id;
		var projectId		=	sampleIdProjectIdHash[sampleId];
		
		var item 			=	{};
		item.projectid		=	projectId;
		item.projectname 	= 	projectIdNameHash[projectId];
		item.sampleid		=	sampleId;
		item.samplename		=	sampleIdNameHash[sampleId];
		item.samplebarcode	=	sampleIdBarcodeHash[sampleId];

		// STATUS
		if ( lane.status_id ) {
			item.status = statusIdStatusHash[lane.status_id];
		}

		var projectStatusId = projectIdStatusIdHash[projectId];
		if ( projectStatusId ) {
			item.projectstatus = statusIdStatusHash[projectStatusId];
		}
		var sampleStatusId = sampleIdStatusIdHash[sampleId];
		if ( sampleStatusId ) {
			item.samplestatus = statusIdStatusHash[sampleStatusId];
		}
		var flowcellStatusId = flowcellIdStatusIdHash[flowcellId];
		if ( flowcellStatusId ) {
			item.flowcellstatus = statusIdStatusHash[flowcellStatusId];
		}
		
		if ( lane.lane_id ) {
			item.laneid				=	lane.lane_id;
			item.flowcellid			=	lane.flowcell_id;
			item.flowcellbarcode	=	flowcellIdBarcodeHash[lane.flowcell_id];
			item.lanebarcode		=	item.flowcellbarcode + "_" + lane.lane_id;
		}

		items.push(item);
	});
	
	return items;	
},
addSamplesWithoutLanes : function (lanes) {
	console.log("DataStore.addSamplesWithoutLanes    lanes: ");
	console.dir({lanes:lanes});

	// GET NEW PROJECTS WITHOUT FLOWCELLS BUT WITH SAMPLES
	var samples = this.core.data.getTable("sample");
	//console.log("DataStore.addSamplesWithoutLanes    samples: ");
	//console.dir({samples:samples});

	var sampleIdLaneIdHash	=	this.core.data.getHash("lane", "hash", "sample_id", "lane_id");
	//console.log("DataStore.addSamplesWithoutLanes    sampleIdLaneIdHash: ");
	//console.dir({sampleIdLaneIdHash:sampleIdLaneIdHash});
	
	for ( var i = 0; i < samples.length; i++ ) {
		var sample		=	samples[i];
		var sampleid 	= 	sample.sample_id;
		if ( sampleIdLaneIdHash[sampleid] )	continue;

		lanes.push(sample);
	}

	//console.log("DataStore.addSamplesWithoutLanes    lanes: ");
	//console.dir({lanes:lanes});

	return lanes;
}



}); 	//	end declare

});	//	end define

	
