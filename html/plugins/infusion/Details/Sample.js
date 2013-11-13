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
function(declare, lang, arrayUtil, Grid, Selection, Keyboard, Hider, editor, commonArray, TitlePane, DataStore, on, _Widget, _Templated, JSON, domClass, BaseDetails, Common, ready) {
////}}}}} 
// information : Detailed::Project::Information object
return declare([_Widget, _Templated, BaseDetails, Common], {
//return declare([_WidgetBase, _OnDijitClickMixin, _TemplatedMixin], {

// The top grid providing detailed information on the project
information : null,

// list : Detailed::Project::List
// The bottom grid displaying a list of samples belonging to the project
list : null,

// Path to the template of this widget
// templatePath : String
templatePath : require.toUrl("plugins/infusion/Details/templates/sample.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/Details/css/base.css"),
	require.toUrl("plugins/infusion/Details/css/sample.css")
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
    console.log("Detailed.Sample.constructor    caller: " + this.constructor.caller.nom);    
    console.log("Detailed.Sample.constructor    args:");
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

	console.log("Details.Sample.startup    this: " + this);        
	console.dir({this:this});
	
	var thisObject = this;
	ready( function() {

		// CONNECT TO TAB NODE
		console.log("Details.Sample.startup    thisObject.tabNode: " + thisObject.tabNode);        
		on(thisObject.tabNode, "onClick", function() {
			console.log("Details.Sample.startup    tabNode onClick FIRED");        
	
		});

		// CONNECT TO TAB NODE
		console.log("Details.Sample.startup    thisObject.tabNode: " + thisObject.tabNode);        
		on(thisObject.tabNode, "Click", function() {
			console.log("Details.Sample.startup    tabNode Click FIRED");        
	
		});


		// CONNECT TO TAB NODE
		console.log("Details.Sample.startup    thisObject.tabNode: " + thisObject.tabNode);        
		on(thisObject.tabNode, "onclick", function() {
			console.log("Details.Sample.startup    tabNode onclick FIRED");        
	
		});

		
		// CONNECT TO TAB NODE
		console.log("Details.Sample.startup    thisObject.tabNode: " + thisObject.tabNode);        
		on(thisObject.tabNode, "click", function() {
			console.log("Details.Sample.startup    tabNode click FIRED");        
	
		});

	});

},
// SET GRIDS
setGrids : function () {
    this.setInformation();
    this.setList();
    this.setSummary();
    this.setRequeued();
    this.setCurrentRequeues();    
    this.setWorkflows();    
	this.setComments();
	this.setHistory();
},
setInformation : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
    var columns 	=	this.getInfoColumns();
    this.information = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
            autoWidth: true,
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
			label: "Project Name",
			field: "project_name"
		},
		{
			label: "Sample Barcode",
			field: "sample_barcode"
		},
		{
			label: "Status",
			field: "status_id",
		},
		{
			label: "Sample Name",
			field: "sample_name",
		},
		{
			label: "Target Covg",
			field: "target_fold_coverage",
		},
		{
			label: "Species",
			field: "species",
		},
		{
			label: "Gender",
			field: "gender",
		},
		{
			label: "GT Gender",
			field: "gt_gender",
		},
		{
			label: "GT Call Rate",
			field: "gt_call_rate",
		},
		{
			label: "GT p99 Call Rate",
			field: "gt_p99_cr",
		},
		{
			label: "Cancer",
			field: "cancer",
		},
		{
			label: "Ethnicity",
			field: "ethnicity",
		},
		{
			label: "Loaded Date",
			field: "loaded_date",
		},
		{
			label: "Due date",
			field: "due_date",
		},
		{
			label: "Delivered date",
			field: "delivered_date",
		},
		{
			label: "Tissue Source",
			field: "tissue_source",
		},
		{
			label: "Match Sample IDs",
			field: "match_sample_ids",
		},
		{
			label: "Comment",
			field: "comment",
		},
		{
			label: "History",
			field: "history",
		}
	];	
},
setList : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
    this.list = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Date Updated",
                    field: "date_updated",
                },
                {
                    label: "Flowcell Barcode",
                    field: "flowcell_barcode",
                },
                {
                    label: "Flowcell Status",
                    field: "flowcell_status",
                },
                {
                    label: "Lane",
                    field: "lane_id",
                },
                {
                    label: "Lane Status",
                    field: "lane_status",
                },
                {
                    label: "Align Status",
                    field: "align_status",
                },
                {
                    label: "Yield Trimmed (Gb",
                    field: "yield_trimmed",
                },
                {
                    label: "Yield Aligned (Gb",
                    field: "yield_aligned",
                },
                {
                    label: "Lib Insert (median; low; high",
                    field: "lib_insert",
                },
                {
                    label: "Align Per r1r2",
                    field: "align_per_r1r2",
                    //hidden: true,
                },
                {
                    label: "Error Rate r1r2",
                    field: "error_per_r1r2",
                    //hidden: true,
                },
                {
                    label: "Per Good Tiles",
                    field: "per_good_tiles",
                    //hidden: true,
                },
                {
                    label: "Per Q30 r1r2",
                    field: "per_q30_r1r2",
                },
                {
                    label: "Fingerprint Analysis",
                    field: "fingerprint_analysis",
                },
                {
                    label: "Change Status",
                    field: "change_status",
                },
                {
                    label: "Comments",
                    field: "comments",
                }
            ]
        },
        gridNode
    );

	var thisObject = this;
	this.list.on(".dgrid-cell:click", function(evt){
		console.log("Sample.setList    CELL click EVENT FIRED"); 
		var row         =   thisObject.list.row(event); 
		var data        =   row.data;
		console.log("Sample.setList    data:");
		console.dir({data:data});
		
		console.log("Sample.setList    DOING thisObject.core.details.showDetails(flowcell, " + data.flowcell_barcode + ")");
		if ( thisObject.core.details ) {
			thisObject.core.details.showDetails("flowcell", data.flowcell_barcode);
		}
	});

    this.listTitlePane.containerNode.appendChild(gridNode);
},
setSummary : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
    this.summary = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Trimmed Yield",
                    field: "trimmed_yield",
                },
                {
                    label: "Aligned Yield ",
                    field: "aligned_yield",
                },
                {
                    label: "Total lanes",
                    field: "total_lanes",
                },
                {
                    label: "Good Lanes",
                    field: "good_lanes",
                },
                {
                    label: "Bad Lanes",
                    field: "bad_lanes",
                },
                {
                    label: "Sequencing Lanes",
                    field: "sequencing_lanes",
                },
                {
                    label: "Requeued Lanes",
                    field: "requeued_lanes",
                }
            ]
        },
        gridNode
    );
    this.summary.resize();

    this.summaryTitlePane.containerNode.appendChild(gridNode);
},
setRequeued : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
    this.requeued = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Target Trimmed Yield (Gb)",
                    field: "target_yield",
                },
                {
                    label: "Estimated Yield (Gb",
                    field: "estimated_yield",
                },
                {
                    label: "Missing Yield (Gb",
                    field: "missing_yield",
                },
                {
                    label: "Need Lanes",
                    field: "need_lanes",
                },
                {
                    label: "Requeue Type",
                    field: "requeue_type",
                },
                {
                    label: "Requeue Reason",
                    field: "requeue_reason",
                },
                {
                    label: "User",
                    field: "user",
                }
            ]
        },
        gridNode
    );

    //console.log("Detailed.Sample.setRequeued    this.requeued");
    //console.dir({this_list:this.requeued});


		//<select name=requeue_type>
		//<option value=DTP selected=selected >DTP</option>
		//<option value=UCT>UCT</option>
		//<option value=libraryPrep>LibraryPrep</option>
		//<option value=libraryPrep>LibraryPrep_qPCRFailure</option>
		//</select>
		//      

//    <td>
//		<select name=requeue_reason>
//		<option value=yield_missing selected=selected >yield_missing</option>
//		<option value=sample_mixup>sample_mixup</option>
//		<option value=fail_library-contamination>fail_library-contamination</option>
//		<option value=fail_library-diversity>fail_library-diversity</option>
//		<option value=fail_library-diversity>fail_library-other</option>
//		<option value=failed-qPCR>failed-qPCR</option>
//		<option value=No_UCT_left>No_UCT_left</option>
//		<option value=failed_LQC>failed_LQC</option>
//		<option value=failed_FC_instrument>failed_FC_instrument</option>
//		<option value=failed_FC_user_error>failed_FC_user_error</option>
//		<option value=Failed_FC_Cluster_Density>Failed_FC_Cluster_Density</option>
//		</select>
//	</td>
    
    this.requeuedTitlePane.containerNode.appendChild(gridNode);
},
setCurrentRequeues : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
    this.currentRequeues = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
            open: false,
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Requeue ID",
                    field: "requeue_report_id",
                },
                {
                    label: "Status",
                    field: "status",
                },
                {
                    label: "Date Created",
                    field: "date_created",
                },
                {
                    label: "Last Updated",
                    field: "update_timestamp",
                },
                {
                    label: "Requeue Type",
                    field: "requeue_type",
                },
                {
                    label: "Requeue Reason",
                    field: "comments_text",
                },
                {
                    label: "Lanes Requested",
                    field: "lanes_requested",
                },
                {
                    label: "Match Samplesheets",
                    field: "match_sample_ids",
                }
            ]
        },
        gridNode
    );

    this.currentRequeuesTitlePane.containerNode.appendChild(gridNode);
},
setWorkflows : function () {
    var thisObject = this;
    var gridNode = document.createElement('div');
    this.workflows = new(declare([Grid, Selection, Keyboard, Hider, editor]))(
        {
            autoWidth: true,
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Workflow Name",
                    field: "workflow_name",
                },
                {
                    label: "Workflow Version",
                    field: "workflow_version",
                },
                {
                    label: "Workflow ID",
                    field: "workflow_id",
                },
                {
                    label: "Workflow Queue ID",
                    field: "workflow_queue_id",
                },
                {
                    label: "Working Server",
                    field: "working_server",
                },
                {
                    label: "Flowcell Barcode",
                    field: "flowcell_barcode",
                },
                {
                    label: "Lane ID",
                    field: "lane_id",
                }
            ]
        },
        gridNode
    );

    this.workflowsTitlePane.containerNode.appendChild(gridNode);
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
					field: "sample_comment_id",
				},
		
				{
					label: "Flowcell ID",
					field: "sample_id",
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
updateGrid : function (sampleBarcode) {
	console.log("Sample.updateGrid    sampleBarcode: " + sampleBarcode);
    // INSTANTIATE GRIDS IF NOT ALREADY EXISTING
    if ( ! this.information ) {
	    console.log("Detailed.Sample.updateGrid    this.information not defined. DOING this.setGrids()");
        this.setGrids();
    }
    console.log("Detailed.Sample.updateGrid    this.information");
    console.dir({this_information:this.information});

    // SET INFO
    var infoData = this.getInfoData(sampleBarcode); 
    console.log("Detailed.Sample.updateGrid    this.infoData");
    console.dir({this_infoData:this.infoData});
    this.information.refresh();
    this.information.renderArray(infoData);
    
    // GET LANES
    var lanes = this.getListData(sampleBarcode) || [];

    // SET LIST
    this.list.refresh();
    this.list.renderArray(lanes);

    //// SET SUMMARY
    var sample = this.getSummaryData(sampleBarcode, lanes);
    //console.log("Detailed.Sample.updateGrid    sample");
    //console.dir({sample:sample});
    this.summary.refresh();
    this.summary.renderArray([sample]);

    // SET REQUEUES
    sample = this.getRequeuedData(sample);
    this.requeued.refresh();
    this.requeued.renderArray([sample]);
    
    // SET CURRENT REQUEUES
    sample = this.getCurrentRequeuesData(sample);
    if ( sample.requeue_report_id ) {
        this.currentRequeues.refresh();
        this.currentRequeues.renderArray([sample]);
    }
    
    // SET WORKFLOWS
    lanes = this.getWorkflowsData(sample, lanes) || [];
    this.workflows.refresh();
    this.workflows.renderArray(lanes);    

    // SET comment DATA
    var commentData = this.getCommentData(sampleBarcode) || [];
    this.comments.refresh();
    this.comments.renderArray(commentData);

	// SET HISTORY
	var historyData = this.getHistoryData(sampleBarcode) || [];
	this.history.refresh();
	this.history.renderArray(historyData);	
},
getInfoData : function (sampleBarcode) {
    var sample = this.core.data.getHash("sample", "objectHash", "sample_barcode")[sampleBarcode];
    var projectIdNameHash = this.core.data.getHash("project", "hash", "project_id", "project_name");
    var projectId = sample.project_id;
    console.log("Detailed.Sample.getInfoData    projectId: " + projectId);
    var projectName = projectIdNameHash[projectId];
    console.log("Detailed.Sample.getInfoData    projectName: " + projectName);
    sample.project_name = projectName;
    
    var data = [sample];
    console.log("Detailed.Sample.getInfoData    data:");
    console.dir({data:data});
    
    return data;
},
getListData : function (sampleBarcode) {
// GET ARRAY OF LANES FOR THIS SAMPLE
    console.log("Detailed.Sample.getListData    sampleBarcode: " + sampleBarcode);
    var hash = this.core.data.getHash("sample", "hash", "sample_barcode", "sample_id");
    //console.log("Detailed.Sample.getListData    hash:");
    //console.dir({hash:hash});
    var sampleId = hash[sampleBarcode];
    console.log("Detailed.Sample.getListData    sampleId : " + sampleId );

    var lanes = this.getLanes(sampleId);
    console.log("Detailed.Sample.getListData    lanes:");
    console.dir({lanes:lanes});
    
    return lanes;
},
getSummaryData : function (sampleBarcode, lanes) {
    var sample = this.core.data.getHash("sample", "objectHash", "sample_barcode")[sampleBarcode];
    
    sample = this.getYieldStats(sample, lanes);
    //console.log("Detailed.Sample.getListData    sample:");
    //console.dir({sample:sample});
        
    sample = this.getLaneStats(sample, lanes);
    //console.log("Detailed.Sample.getListData    sample:");
    //console.dir({sample:sample});
    
    return sample;
},
getRequeuedData : function (sample) {
    sample.target_yield = this.targetYield;

    //sample = this.getYieldStats(sample, lanes);
    ////console.log("Detailed.Sample.getListData    sample:");
    ////console.dir({sample:sample});
    //    
    //sample = this.getLaneStats(sample, lanes);
    //console.log("Detailed.Sample.getRequeuedData    sample:");
    //console.dir({sample:sample});
    
    return sample;
},
getCurrentRequeuesData : function (sample) {
    var hash = this.core.data.getHash("requeuereport", "objectHash", "sample_id");
    //console.log("Detailed.Sample.getCurrentRequeuesData    hash:");
    //console.dir({hash:hash});

    var requeuesData = hash[sample.sample_id];
    //console.log("Detailed.Sample.getCurrentRequeuesData    requeuesData:");
    //console.dir({requeuesData:requeuesData});
    
    sample = this.addHashes(sample, requeuesData);
    //console.log("Detailed.Sample.getCurrentRequeuesData    sample:");
    //console.dir({sample:sample});
    
    return sample;
},
getWorkflowsData : function (sample, lanes) {
    //console.log("Detailed.Sample.getWorkflowsData    lanes:");
    //console.dir({lanes:lanes});

    // LOOKUP:
    // workflow:workflow_id
    //-> workflow_queue:workflow_queue_id
    //-> workflow_queue_samplesheet:lane_id
    //-> lane:lane_id
    
    var workflowIdObjectHash = this.core.data.getHash("workflow", "objectHash", "workflow_id");
    //console.log("Detailed.Sample.getWorkflowsData    workflowIdObjectHash:");
    //console.dir({workflowIdObjectHash:workflowIdObjectHash});

    var workflowQueueIdObjectHash = this.core.data.getHash("workflowqueue", "objectHash", "workflow_queue_id");
    //console.log("Detailed.Sample.getWorkflowsData    workflowQueueIdObjectHash:");
    //console.dir({workflowQueueIdObjectHash:workflowQueueIdObjectHash});

    var workflowQueueIdWorkflowIdHash = this.core.data.getHash("workflowqueue", "hash", "workflow_queue_id", "workflow_id");

    var flowcellSamplesheetIdWorkflowQueueIdHash = this.core.data.getHash("workflowqueuesamplesheet", "hash", "flowcell_samplesheet_id", "workflow_queue_id");
    
    var flowcellIdBarcodeHash = this.core.data.getHash("flowcell", "hash", "flowcell_id", "flowcell_barcode");
    
    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i){
        //console.log("Detailed.Sample.getWorkflowsData    lane.flowcell_samplesheet_id: " + lane.flowcell_samplesheet_id);
        var workflowQueueId = flowcellSamplesheetIdWorkflowQueueIdHash[lane.flowcell_samplesheet_id];
        //console.log("Detailed.Sample.getWorkflowsData    workflowQueueId: " + workflowQueueId);
        var workflowId = workflowQueueIdWorkflowIdHash[workflowQueueId];
        //console.log("Detailed.Sample.getWorkflowsData    workflowId: " + workflowId);
        var workflowObject = workflowIdObjectHash[workflowId];
        //console.log("Detailed.Sample.getWorkflowsData    workflowObject:");
        //console.dir({workflowObject:workflowObject});

        var workflowQueueObject = workflowQueueIdObjectHash[workflowQueueId];
        //console.log("Detailed.Sample.getWorkflowsData    workflowQueueObject:");
        //console.dir({workflowQueueObject:workflowQueueObject});
        
        lane = thisObject.addHashes(lane, workflowObject);
        lane.workflow_queue_id = workflowQueueId;
        if ( workflowQueueObject ) {
            lane.working_server     =   workflowQueueObject.working_server;
        }
        lane.flowcell_barcode   =   flowcellIdBarcodeHash[lane.flowcell_id];  
        
        //console.log("Detailed.Sample.getWorkflowsData    lane:");
        //console.dir({lane:lane});
    });
    
    return lanes;
},
getFingerprint : function (lane, flowcellIdLaneIdQcObjectHash) {
    //console.log("Detailed.Sample.getFingerprint    lane:");
    //console.dir({lane:lane});
    //console.log("Detailed.Sample.getFingerprint    flowcellIdLaneIdQcObjectHash:");
    //console.dir({flowcellIdLaneIdQcObjectHash:flowcellIdLaneIdQcObjectHash});
    var qcObject = flowcellIdLaneIdQcObjectHash
        && flowcellIdLaneIdQcObjectHash[lane.flowcell_id]
        && flowcellIdLaneIdQcObjectHash[lane.flowcell_id][lane.lane_id]
        ? flowcellIdLaneIdQcObjectHash[lane.flowcell_id][lane.lane_id]
        : null;
    
    if ( ! qcObject ) {
        return lane;
    }
    
    lane.fingerprint_analysis = qcObject.fingerprint_status_id;    
    
    return lane;
},
laneBuildStats : function(lane, flowcellIdLaneIdFlowcellReportTrimObjectHash) {
    //console.log("Detailed.Sample.laneBuildStats    flowcellIdLaneIdFlowcellReportTrimObjectHash:");
    //console.dir({flowcellIdLaneIdFlowcellReportTrimObjectHash:flowcellIdLaneIdFlowcellReportTrimObjectHash});

    var buildStats = flowcellIdLaneIdFlowcellReportTrimObjectHash[lane.flowcell_id] && flowcellIdLaneIdFlowcellReportTrimObjectHash[lane.flowcell_id][lane.lane_id] ? flowcellIdLaneIdFlowcellReportTrimObjectHash[lane.flowcell_id][lane.lane_id] : null;
    //console.log("Detailed.Sample.laneBuildStats    buildStats:");
    //console.dir({buildStats:buildStats});
    
    if ( ! buildStats ) {
        return lane;
    }
    var insert_median   =   buildStats.insert_median    || "";
    var insert_sd_low   =   buildStats.insert_sd_low    || "";
    var insert_sd_high  =   buildStats.insert_sd_high   || "";
    lane.lib_insert = insert_median + ";" + insert_sd_low + ";" + insert_sd_high;
    
    
    return lane;
},
getCommentData : function (sampleBarcode) {
	console.log("Details.Sample.getCommentData    this:");
	console.dir({this:this});
	var comments = this.getCommentsTable();
	console.log("Details.Sample.getCommentData    comments:");
	console.dir({comments:comments});

    var hash = this.core.data.getHash("sample", "hash", "sample_barcode", "sample_id");
    var sampleId = hash[sampleBarcode];

	var keys = ["sample_id"];
	comments = this.filterByKeyValues(comments, keys, [sampleId]);

    console.log("Details.Sample.getInfoData    Returning " + comments.length + " comments:");
    console.dir({comments:comments});
    
    return comments;
},
getCommentsTable : function () {
	return this.core.data.getTable("sample_comment");
},
getHistoryData : function (sampleBarcode) {
    return this.core.data.getHash("sample_history", "objectArrayHash", "sample_barcode")[sampleBarcode];
}



    
});

});

