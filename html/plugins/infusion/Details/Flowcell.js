define([
    "dojo/_base/declare",
    "dojo/_base/lang",
    "dojo/_base/array",
    "dgrid/OnDemandGrid",
    "dgrid/Selection",
    "dgrid/Keyboard",
    "dgrid/extensions/ColumnHider",
    "plugins/core/Common/Array",
    "dijit/TitlePane",
    "plugins/infusion/DataStore",
    "dojo/on",
    "dijit/_Widget",
    "dijit/_Templated",
    "dojo/json",
    "dojo/dom-class",
    "plugins/infusion/Details/Base",
	"plugins/core/Common",
    "dojo/ready"
    //"dojo/domReady!"
],
function(declare, lang, arrayUtil, Grid, Selection, Keyboard, Hider, commonArray, TitlePane, DataStore, on, _Widget, _Templated, JSON, domClass, BaseDetails, Common, ready) {
////}}}}} 
return declare([_Widget, _Templated, BaseDetails, Common], {

// The top grid providing detailed information on the project
information : null,

// list : Detailed::Project::List
// The bottom grid displaying a list of samples belonging to the project
list : null,

// Path to the template of this widget
// templatePath : String
templatePath : require.toUrl("plugins/infusion/Details/templates/flowcell.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/Details/css/base.css"),
	require.toUrl("plugins/infusion/Details/css/flowcell.css")
],

// Ratio used to convert coverage from fold coverage to Gbases
// coverageRatio : Float
coverageRatio: 105/30,

// Expected yield per lane (Gigabases)
// yieldPerLane : Integer
yieldPerLane : 37,

// Required total yield (Gigabases)
// targetYield : Integer
targetYield : 105,

// parent : Infusion object
// Parent widget
parent : null, 

////}}}}
constructor : function (args) {
    console.log("Detailed.Flowcell.constructor    caller: " + this.constructor.caller.nom);    
    console.log("Detailed.Flowcell.constructor    args:");
    console.dir({args:args});
    
    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
},
postCreate : function () {
    this.startup();
},
startup : function () {
	this.attachPane();
	this.setGrids();
},
// SET GRIDS
setGrids : function () {
    this.setInformation();
    this.setLifeCycle();
    this.setList();
	this.setAllLanes();
	this.setComments();
	this.setHistory();
},
setInformation : function () {
    var thisObject 	= 	this;
    var gridNode 	= 	document.createElement('div');
    var columns 	=	this.getInfoColumns();
	this.information = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
			selectable: "true",
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: columns
        },
        gridNode
    );

    this.informationTitlePane.containerNode.appendChild(gridNode);
},
getInfoColumns : function () {
	return [
		{
			label: "Flowcell ID",
			field: "flowcell_id",
		},
		{
			label: "Flowcell Barcode",
			field: "flowcell_barcode",
		},
		{
			label: "Update Timestamp",
			field: "update_timestamp",
		},
		{
			label: "FPGA Version",
			field: "fpga_version",
		},
		{
			label: "RTA Version",
			field: "rta_version",
		},
		{
			label: "Run Length",
			field: "run_length",
		},
		{
			label: "Indexed",
			field: "indexed",
		},
		{
			label: "Status",
			field: "status",
		},
		{
			label: "Description",
			field: "description",
		},
		{
			label: "Recipe",
			field: "recipe",
		},
		{
			label: "Machine Name",
			field: "machine_name",
		},
		{
			label: "Location",
			field: "location",
		},
		{
			label: "Comments",
			field: "comments",
		}
	];
},
setLifeCycle : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
    this.lifeCycle = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
			selectable: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Flowcell ID",
                    field: "flowcell_id",
                },
                {
                    label: "Flowcell Barcode",
                    field: "flowcell_barcode",
                },
                {
                    label: "Fail Code",
                    field: "fail_code",
                },
                {
                    label: "User & IP",
                    field: "user_code_and_ip",
                },
                {
                    label: "Attempting Rehyb",
                    field: "attempting_rehyb",
                },
                {
                    label: "LCM Broad Cause",
                    field: "lcm_broad_cause",
                },
                {
                    label: "LCM Specific Cause",
                    field: "lcm_specific_cause",
                },
                {
                    label: "LCM Status",
                    field: "lcm_status",
                },
                {
                    label: "LCM Equipment Related",
                    field: "lcm_equipment_related",
                },
                {
                    label: "LCM Comments",
                    field: "lcm_comments",
                },
                {
                    label: "QC Lanes",
                    field: "qc_lanes",
                }
            ]
        },
        gridNode
    );
    this.lifeCycleTitlePane.containerNode.appendChild(gridNode);
},
setList : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
   
	var columns = this.listColumns();
	
    this.list = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
			selectable: "true",
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: columns
        },
        gridNode
    );

		var thisObject = this;
	this.list.on(".dgrid-cell:click", function(evt){
		console.log("Flowcell.setList    CELL click EVENT FIRED"); 
		var row         =   thisObject.list.row(event); 
		var data        =   row.data;
		console.log("Flowcell.setList    data:");
		console.dir({data:data});
		
		console.log("Flowcell.setList    DOING thisObject.core.details.showDetails(lane, " + data.lane_barcode + ")");
		if ( thisObject.core.details ) {
			thisObject.core.details.showDetails("lane", data.lane_barcode);
		}
	});

    this.listTitlePane.containerNode.appendChild(gridNode);
},
setAllLanes : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
   
	var columns = this.listColumns();
	
    this.allLanes = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
			selectable: true,
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: columns
        },
        gridNode
    );

	var thisObject = this;
	this.list.on(".dgrid-cell:click", function(evt){
		console.log("Flowcell.setAllLanes    CELL click EVENT FIRED"); 
		var row         =   thisObject.list.row(event); 
		var data        =   row.data;
		console.log("Flowcell.setAllLanes    data:");
		console.dir({data:data});
		
		console.log("Flowcell.setAllLanes    DOING thisObject.core.details.showDetails(lane, " + data.lane_barcode + ")");
		if ( thisObject.core.details ) {
			thisObject.core.details.showDetails("lane", data.lane_barcode);
		}
	});

    this.allLanesTitlePane.containerNode.appendChild(gridNode);
},
listColumns : function () {
	return [
		{
			label: "Lane",
			field: "lane_id",
		},
		{                   
			label: "Extract Cycle",
			field: "extract_cycle",
		},
		{                   
			label: "QScore Cycle",
			field: "qscore_cycle",
		},
		{                   
			label: "cluster density raw",
			field: "cluster_density_raw",
		},
		{                   
			label: "cluster density pf",
			field: "cluster_density_pf",
		},
		{                   
			label: "clusters raw",
			field: "clusters_raw",
		},
		{                   
			label: "clusters per_pf",
			field: "clusters_per_pf",
		},
		{                   
			label: "phiX error_rate", 
			field: "r1;r2 : phiX_error_rate",
		},
		{                   
			label: "phasing_r1 prephasing_r1",
			field: "phasing_r1",
		},
		{                   
			label: "phasing_r2 prephasing_r2",
			field: "phasing_r2",
		},
		{                   
			label: "insert_median; sd_low; sd_high",
			field: "insert_median",
		}
	];
},
setComments : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');   
    this.comments = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
			selectable: true,
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [

				{
					label: "Comment ID",
					field: "flowcell_comment_id",
				},
		
				{
					label: "Flowcell ID",
					field: "flowcell_id",
				},
		
				{
					label: "Comment",
					field: "comment_content",
				},
		
				{
					label: "Date Added",
					field: "date_inserted",
				},
		
				{
					label: "Username",
					field: "user",
				}
			]
        },
        gridNode
    );

    this.commentsTitlePane.containerNode.appendChild(gridNode);
},
setHistory : function () {
    var thisObject 	= 	this;
    var gridNode 	= 	document.createElement('div');
    var columns 	=	this.getInfoColumns();
	this.history = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
			selectable: "true",
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: columns
        },
        gridNode
    );

    this.historyTitlePane.containerNode.appendChild(gridNode);
},
// UPDATE GRIDS
updateGrid : function (flowcellBarcode) {
    // INSTANTIATE GRIDS IF NOT ALREADY EXISTING
    if ( ! this.information ) {
        this.setGrids();
    }
    console.log("Detailed.Flowcell.updateGrid    this.information");
    console.dir({this_information:this.information});

    // SET INFO
    var infoData = this.getInfoData(flowcellBarcode) || []; 
    this.information.refresh();
    this.information.renderArray(infoData);
    
	// SET LIFECYCLE

    // GET LANES
    var lanes = this.getListData(flowcellBarcode);

    // SET LIST
    this.list.refresh();
    this.list.renderArray(lanes);

	// SET ALL LANES
	var allLanes = this.getAllLanesData(flowcellBarcode) || [];
	this.allLanes.refresh();
    this.allLanes.renderArray(allLanes);

	// SET COMMENTS
	var commentData = this.getCommentData(flowcellBarcode) || [];
	this.comments.refresh();
	this.comments.renderArray(commentData);	

	// SET HISTORY
	var historyData = this.getHistoryData(flowcellBarcode) || [];
	this.history.refresh();
	this.history.renderArray(historyData);	
},
getInfoData : function (flowcellBarcode) {
    var flowcell = this.core.data.getHash("flowcell", "objectHash", "flowcell_barcode")[flowcellBarcode];
    //console.log("Detailed.Flowcell.getInfoData    flowcell:");
    //console.dir({flowcell:flowcell});

    var data = [flowcell];
    console.log("Detailed.Flowcell.getInfoData    data:");
    console.dir({data:data});
    
    return data;
},
getListData : function (flowcellBarcode) {
// GET ARRAY OF LANES FOR THIS SAMPLE
    var hash = this.core.data.getHash("flowcell", "hash", "flowcell_barcode", "flowcell_id");
    var flowcellId = hash[flowcellBarcode];
    var hash2 = this.core.data.getHash("lane", "hash", "flowcell_id", "sample_id");
    var sampleId = hash2[flowcellId];
    var hash3 = this.core.data.getHash("sample", "objectHash", "sample_id");
    var sampleObject =  hash3[sampleId];
    var hash4 = this.core.data.getHash("flowcellreporttrim", "objectHash", "flowcell_id");
    var reportObject =  hash4[flowcellId];
    var lanes = this.getLanes(sampleId);
    console.log("Detailed.Flowcell.getInfoData    lanes:");
    console.dir({lanes:lanes});

    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i) {
        lane = thisObject.addHashes(lane, reportObject);
        lane.flowcell_id    =   flowcellId; 
        lane.sample_id      =   sampleId; 
        lane.sample_barcode =   sampleObject.sample_barcode; 
        lane.project_id     =   sampleObject.project_id; 
    });
    
    return lanes;
},
getAllLanesData : function (flowcellBarcode) {
// GET ARRAY OF LANES FOR THIS SAMPLE
    var hash = this.core.data.getHash("flowcell", "hash", "flowcell_barcode", "flowcell_id");
    var flowcellId = hash[flowcellBarcode];
    var hash2 = this.core.data.getHash("lane", "hash", "flowcell_id", "sample_id");
    var sampleId = hash2[flowcellId];
    var hash3 = this.core.data.getHash("sample", "objectHash", "sample_id");
    var sampleObject =  hash3[sampleId];
    var hash4 = this.core.data.getHash("flowcellreporttrim", "objectHash", "flowcell_id");
    var reportObject =  hash4[flowcellId];

    var lanes = this.getAllLanes(flowcellBarcode);
    //console.log("Detailed.Flowcell.getInfoData    lanes:");
    //console.dir({lanes:lanes});

    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i) {
        lane = thisObject.addHashes(lane, reportObject);
        lane.flowcell_id    =   flowcellId; 
        lane.sample_id      =   sampleId; 
        lane.sample_barcode =   sampleObject.sample_barcode; 
        lane.project_id     =   sampleObject.project_id; 
    });
    console.log("Detailed.Flowcell.getInfoData    Returning " + lanes.length + " lanes:");
    console.dir({lanes:lanes});
    
    return lanes;
},
getCommentData : function (flowcellBarcode) {
	var comments = this.getCommentsTable();
	console.log("Details.Flowcell.getCommentData    comments:");
	console.dir({comments:comments});

    var hash = this.core.data.getHash("flowcell", "hash", "flowcell_barcode", "flowcell_id");
    var flowcellId = hash[flowcellBarcode];

	var keys = ["flowcell_id"];
	comments = this.filterByKeyValues(comments, keys, [flowcellId]);

    console.log("Detailed.Flowcell.getInfoData    Returning " + comments.length + " comments:");
    console.dir({comments:comments});
    
    return comments;
},
getCommentsTable : function () {
	return this.core.data.getTable("flowcell_comment");
},
getHistoryData : function (flowcellBarcode) {
    var history = this.core.data.getHash("flowcell_history", "objectArrayHash", "flowcell_barcode")[flowcellBarcode] || [];

	return history;
}


  
});

});

