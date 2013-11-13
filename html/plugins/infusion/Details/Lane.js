define([

    "dojo/_base/declare",
    "dojo/_base/lang",
    "dojo/_base/array",
    "dgrid/OnDemandGrid",
    "dgrid/Selection",
    "dgrid/Keyboard",
    "dgrid/extensions/ColumnHider",
    "dgrid/editor",
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
function(declare, lang, arrayUtil, Grid, Selection, Keyboard, Hider, editor, commonArray, TitlePane, DataStore, on, _Widget, _Templated, JSON, domClass, detailedUtil, Common, ready) {
////}}}}} 
return declare([_Widget, _Templated, detailedUtil, Common], {

// The top grid providing detailed information on the project
information : null,

// list : Detailed::Project::List
// The bottom grid displaying a list of samples belonging to the project
list : null,

// Path to the template of this widget
// templatePath : String
templatePath : require.toUrl("plugins/infusion/Details/templates/lane.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/Details/css/base.css"),
	require.toUrl("plugins/infusion/Details/css/lane.css")
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
    console.log("Details.Lane.constructor    caller: " + this.constructor.caller.nom);    
    console.log("Details.Lane.constructor    args:");
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
    this.setClusters();
	this.setComments();
	this.setHistory();
},
setInformation : function () {
	console.log("Lane.setInformation");
    var thisObject 	= 	this;
    var gridNode 	= 	document.createElement('div');
	var columns 	=	this.getInfoColumns();
    this.information = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
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
			label: "Lane",
			field: "lane_id",
		},
		{                   
			label: "Sample Barcode",
			field: "sample_barcode",
		},
		{                   
			label: "Project",
			field: "project_name",
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
			label: "insert_median; sd_low; sd_high",
			field: "insert_median",
		}
	];	
},
setClusters : function () {
	console.log("Lane.setClusters");
    var thisObject = this;
    var gridNode = document.createElement('div');
    this.clusters = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Lane",
                    field: "lane_id",
                },
                {                   
                    label: "Sample Barcode",
                    field: "sample_barcode",
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
         ]
        },
        gridNode
    );	

    this.clustersTitlePane.containerNode.appendChild(gridNode);
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
					field: "flowcell_lane_qc_comment_id",
				},
		
				{
					label: "Flowcell QC Lane ID",
					field: "flowcell_lane_qc_id",
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
updateGrid : function (laneBarcode) {
	console.log("Lane.updateGrid    laneBarcode: " + laneBarcode);

    // INSTANTIATE GRIDS IF NOT ALREADY EXISTING
    if ( ! this.information ) {
        this.setGrids();
    }
    //console.log("Details.Lane.updateGrid    this.information");
    //console.dir({this_information:this.information});

    // SET INFO
    var infoData = this.getInfoData(laneBarcode) || []; 
    console.log("Details.Lane.updateGrid    infoData");
    console.dir({infoData:infoData});
	
	// SET INFO
    this.information.refresh();
    this.information.renderArray(infoData);

    // SET CLUSTERS
    this.clusters.refresh();
    this.clusters.renderArray(infoData);

    // SET comment DATA
    var commentData = this.getCommentData(laneBarcode) || [];
    this.comments.refresh();
    this.comments.renderArray(commentData);

	// SET HISTORY
	var historyData = this.getHistoryData(laneBarcode) || [];
	this.history.refresh();
	this.history.renderArray(historyData);	
},
getInfoData : function (laneBarcode) {
    console.log("Details.Lane.getInfoData    laneBarcode: " + laneBarcode);

    var flowcellBarcode = laneBarcode.match(/^(.+)_(.+)$/)[1];
    var laneId = laneBarcode.match(/^(.+)_(.+)$/)[2];
    console.log("Details.Lane.getInfoData    flowcellBarcode: " + flowcellBarcode);
    console.log("Details.Lane.getInfoData    laneId: " + laneId);
    
    var hash = this.core.data.getHash("flowcell", "hash", "flowcell_barcode", "flowcell_id");
    console.log("Details.Lane.getInfoData    hash:");
    console.dir({hash:hash});
    var flowcellId = hash[flowcellBarcode];
    console.log("Details.Lane.getInfoData    flowcellId: " + flowcellId);

    // SET FLOWCELL ID AND LANE ID VS LANE OBJECT
    var hash2 = this.core.data.getHash("lane", "twoDHash", "flowcell_id", "lane_id");
    console.log("Details.Lane.getInfoData    hash2:");
    console.dir({hash2:hash2});
    var lane =
    hash2[flowcellId]
    && hash2[flowcellId][laneId]
    ?
    hash2[flowcellId][laneId]
    :
    null;
    console.log("Details.Lane.getInfoData    lane:");
    console.dir({lane:lane});

    var hash3 = this.core.data.getHash("lane", "hash", "flowcell_id", "sample_id");
    console.log("Details.Lane.getListData    hash3:");
    console.dir({hash3:hash3});
    var sampleId = hash3[flowcellId];
    console.log("Details.Lane.getListData    sampleId : " + sampleId );

    var hash4 = this.core.data.getHash("sample", "objectHash", "sample_id");
    console.log("Details.Lane.getListData    hash4:");
    console.dir({hash4:hash4});
    var sampleObject =  hash4[sampleId];
    console.log("Details.Lane.getListData    sampleObject:");
    console.dir({sampleObject:sampleObject});
    
    var hash5 = this.core.data.getHash("flowcellreporttrim", "objectHash", "flowcell_id");
    console.log("Details.Lane.getListData    hash5:");
    console.dir({hash5:hash5});
    var reportObject =  hash5[flowcellId];
    console.log("Details.Lane.getListData    reportObject:");
    console.dir({reportObject:reportObject});

    var projectName = this.core.data.getHash("project", "hash", "project_id", "project_name")[sampleObject.project_id];
    console.log("Details.Lane.getListData    projectName: " + projectName);
    
    lane = this.addHashes(lane, reportObject);
    lane.flowcell_id    =   flowcellId; 
    lane.sample_id      =   sampleId; 
    lane.sample_barcode =   sampleObject.sample_barcode; 
    lane.project_id     =   sampleObject.project_id; 
    lane.project_name   =   projectName; 
    
    var data = [lane];
    console.log("Details.Lane.getInfoData    data:");
    console.dir({data:data});
    
    return data;
},
getCommentData : function (laneBarcode) {
    console.log("Details.Lane.getCommentData    laneBarcode: " + laneBarcode);
	var comments = this.getCommentsTable();
	console.log("Details.Lane.getCommentData    comments:");
	console.dir({comments:comments});

    var flowcellBarcode = laneBarcode.match(/^(.+)_(.+)$/)[1];
	var hash = this.core.data.getHash("flowcell", "hash", "flowcell_barcode", "flowcell_id");
    var flowcellId = hash[flowcellBarcode];
	var laneId = laneBarcode.match(/^(.+)_(.+)$/)[2];
    console.log("Details.Lane.getCommentData    flowcellId: " + flowcellId);
    console.log("Details.Lane.getCommentData    laneId: " + laneId);

	var keys = ["flowcell_id", "lane_id"];
	comments = this.filterByKeyValues(comments, keys, [flowcellId, laneId]);

    console.log("Details.Lane.getInfoData    Returning " + comments.length + " comments:");
    console.dir({comments:comments});
    
    return comments;
},
getCommentsTable : function () {
	return this.core.data.getTable("flowcell_lane_qc_comment");
},
getHistoryData : function (laneBarcode) {
    return this.core.data.getHash("lane_history", "objectArrayHash", "lane_barcode")[laneBarcode];
}




});

});

