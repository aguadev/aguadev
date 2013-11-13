define([
    "dojo/_base/declare",
    "dojo/_base/lang",
    "dojo/_base/array",
    "dgrid/OnDemandGrid",
    "dgrid/Selection",
    "dgrid/Keyboard",
    "dgrid/extensions/ColumnHider",
    "plugins/core/Common/Array",
    "plugins/dijit/TitlePane",
    "plugins/infusion/DataStore",
    "dojo/on",
    "dijit/_Widget",
    "dijit/_Templated",
    "dojo/json",
    "dojo/dom-class",
    "plugins/infusion/Details/Base",
	"plugins/core/Common",
    "dojo/ready",
	"dijit/layout/ContentPane",
	"dijit/layout/AccordionContainer",
	
],
function(declare, lang, arrayUtil, Grid, Selection, Keyboard, Hider, commonArray, TitlePane, DataStore, on, _Widget, _Templated, JSON, domClass, BaseDetails, Common, ready) {
////}}}}} 
return declare([_Widget, _Templated, BaseDetails, Common], {

// information : Grid object
// Grid providing detailed information on the project
information : null,

// Path to the template of this widget
// templatePath : String
templatePath : require.toUrl("plugins/infusion/Details/templates/project.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/Details/css/base.css"),
	require.toUrl("plugins/infusion/Details/css/project.css")
],

// Expected yield per lane (Gigabases)
// yieldPerLane : Integer
yieldPerLane : 37,

// Ratio used to convert coverage from fold coverage to Gbases
// coverageRatio : Float
coverageRatio: 105/30,

////}}}}
constructor : function (args) {

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
setGrids : function () {
    this.setInformation();
    this.setList();   
    this.setComments();   
},
// SET LIST TABLES
// SET INFORMATION TABLE
setInformation : function (dataStore) {
    //console.log("Infusion.Detailed.Project.setInformation    dataStore");
    //console.dir({dataStore:dataStore});

    var thisObject = this;
    var gridNode = document.createElement('div');
    this.information = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Name",
                    field: "project_name",
                },
                {
                    label: "ID",
                    field: "project_id",
                },
                {
                    label: "Status",
                    field: "status",
                },
                {
                    label: "Build",
                    field: "build_version",
                },
                {
                    label: "Analyst",
                    field: "data_analyst",
                    hidden: true,
                },
                {
                    label: "Manager",
                    field: "project_manager",
                    hidden: true,
                },
                {
                    label: "Location",
                    field: "build_location",
                    hidden: true,
                },
                {
                    label: "Include NPF",
                    field: "include_NPF",
                },
                {
                    label: "Policy",
                    field: "project_policy",
                }
            ]
        },
        gridNode
    );

    this.informationTitlePane.containerNode.appendChild(gridNode);
},
setList : function (dataStore) {
    console.log("Details.Project.setList    dataStore");
    console.dir({dataStore:dataStore});

    var thisObject = this;
    var gridNode = document.createElement('div');
    this.list = new(declare([Grid, Selection, Keyboard, Hider]))(
        {
            minRowsPerPage: 25,
            maxRowsPerPage: 25,
            columns: [
                {
                    label: "Sample",
                    field: "sample_barcode",
                },
                {
                    label: "Cancer",
                    field: "cancer",
                },
                {
                    label: "Status",
                    field: "status",
                },
                {
                    label: "GT Gender",
                    field: "gt_gender",
                },
                {
                    label: "Target Covg",
                    field: "target_fold_coverage",
                },
                {
                    label: "Total Lanes",
                    field: "total_lanes",
                },
                {
                    label: "Good Lanes",
                    field: "good_lanes",
                },
                {
                    label: "Bad Lanes",
                    field: "bad_lanes",
                    hidden: true,
                },
                {
                    label: "Sequencing Lanes",
                    field: "sequencing_lanes",
                    hidden: true,
                },
                {
                    label: "Requeued Lanes",
                    field: "requeued_lanes",
                    hidden: true,
                },
                {
                    label: "Need Lanes",
                    field: "need_lanes",
                    hidden: true,
                },
                {
                    label: "Yield Trimmed",
                    field: "trimmed_yield",
                },
                {
                    label: "Yield Aligned",
                    field: "aligned_yield",
                },
                {
                    label: "Estimated Yield",
                    field: "estimated_yield",
                },
                {
                    label: "Missing yield",
                    field: "missing_yield",
                    hidden: true,
                },
                {
                    label: "Coverage",
                    field: "coverage",
                },
                {
                    label: "GT Concordance",
                    field: "gt_concordance",
                },
                {
                    label: "Contam Hom Fraction",
                    field: "contam_hom_fraction",
                }
            ]
        },
        gridNode
    );

	var thisObject = this;
	this.list.on(".dgrid-cell:click", function(evt){
		console.log("Details.Project.setList    CELL click EVENT FIRED"); 
		var row         =   thisObject.list.row(event); 
		var data        =   row.data;
		console.log("Details.Project.setList    row:");
		console.dir({row:row});
		console.log("Details.Project.setList    data:");
		console.dir({data:data});
		
		console.log("Details.Project.setList    DOING thisObject.core.details.showDetails(sample, " + data.sample_barcode + ")");
		if ( thisObject.core.details ) {
			thisObject.core.details.showDetails("sample", data.sample_barcode);
		}
	});
	
    this.listTitlePane.containerNode.appendChild(gridNode);
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
					field: "project_comment_id",
				},
		
				{
					label: "Flowcell ID",
					field: "project_id",
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
// UPDATE GRIDS
updateGrid : function (projectName) {
    console.log("Infusion.Detailed.Project.updateGrid    this.information");
    console.dir({this_information:this.information});
    if ( ! this.information ) {
        this.setGrids();
    }

    // SET information DATA
    var infoData = this.getInfoData(projectName); 
    console.log("Infusion.Detailed.Project.updateGrid    this.infoData");
    console.dir({this_infoData:this.infoData});

    this.information.refresh();
    this.information.renderArray(infoData);
    
    // SET list DATA
    var listData = this.getListData(projectName);
    this.list.refresh();
    this.list.renderArray(listData);

    // SET comment DATA
    var commentData = this.getCommentData(projectName);
    this.comments.refresh();
    this.comments.renderArray(commentData);
},
getInfoData : function (projectName) {

    var item = this.core.data.getHash("project", "objectHash", "project_name")[projectName];
	
	// SET STATUS
	var statusIdStatusHash	=	this.core.data.getHash("status", "hash", "status_id", "status");
	if ( item.status_id ) {
		item.status = statusIdStatusHash[item.status_id];
	}

    var data = [item];
    //console.log("Infusion.Detailed.Project.getInfoData    data:");
    //console.dir({data:data});
    
    return data;
},
resetHashes : function () {
    
},
getListData : function (projectName) {

// summary:
//      Return the trimmed yield for the sample
//
//		SHOW:
//		Sample
//		Cancer
//		Sample_Status
//		GT Gender
//		Target Coverage
//		total lanes
//		good lanes
//		yield trimmed
//		yield aligned
//		estimated yield
//		Coverage
//		? GT Concordance -- build_report
//		Contam Hom Fraction

//		HIDE:
//		bad_lanes
//		seq'ing lanes
//		requeued lanes
//		need lanes
//		missing yield

//		REMOVE:
//		Project
//		started_building

//      Corresponds to the original view query:
//      
//      VIEW sample_overview_3 AS select p.project_name AS project_name,
//      p.project_id AS project_id,
//      (SELECT qz.status
//		    FROM status qz
//		    WHERE (qz.status_id = p.status_id)) AS project_status,
//		    s.sample_barcode AS sample_barcode,
//		    s.sample_name AS sample_name,
//		    (SELECT qz.status
//		        FROM status qz
//		        WHERE (qz.status_id = s.status_id)) AS sample_status,
//		    s.update_date AS sample_last_update,
//		    s.target_fold_coverage AS target_fold_coverage,
//		    s.cancer AS cancer,
//		    s.gt_gender AS gt_gender,
//		    s.genotype_report AS genotype_report,
//		    s.gt_deliv_src AS gt_deliv_src,
//		    s.gt_call_rate AS gt_call_rate,
//		    s.gt_p99_cr AS gt_p99_cr,
//		    s.gender AS gender,
//		    s.species AS species,
//		    s.tissue_source AS tissue_source,
//		    s.ethnicity AS ethnicity,
//		    s.match_sample_ids AS match_sample_ids,
//		    s.comment AS comment,
//		    s.delivered_date AS delivered_date,
//		    s.due_date AS due_date,
//		    s.sample_id AS sample_id,
//		    
//		
//		    /* TOTAL LANES */
//		    (SELECT count(fz.status_id)
//		        FROM (lane xz join flowcell fz)
//		        WHERE ((fz.flowcell_id = xz.flowcell_id)
//		        AND (xz.sample_id = s.sample_id))) AS total_lanes,
//		        
//		    /* GOOD LANES */
//		    (SELECT count(zc.status_id)
//		        FROM ((lane xz join flowcell_lane_qc zc) join flowcell fz)
//		        WHERE ((fz.flowcell_id = xz.flowcell_id)
//		        AND (xz.flowcell_id = zc.flowcell_id)
//		        AND (xz.sample_id = s.sample_id)
//		        AND (zc.lane_id = xz.lane_id)
//		        AND (fz.status_id = 2)
//		        AND (zc.status_id = 61))) AS good_lanes,
//		        
//		    /* SEQ LANES */
//		    (SELECT count(xz.status_id)
//		        FROM (lane xz join flowcell fz)
//		        WHERE ((fz.flowcell_id = xz.flowcell_id)
//		        AND (xz.sample_id = s.sample_id)
//		        AND (fz.status_id in (1,75)))) AS seq_lanes,
//		
//		    /* BAD LANES */
//		    (SELECT count(fz.flowcell_id)
//		        FROM ((lane xz
//		        LEFT JOIN flowcell_lane_qc zc on(((zc.flowcell_id = xz.flowcell_id)
//		        AND (zc.lane_id = xz.lane_id)))) join flowcell fz)
//		        WHERE ((fz.flowcell_id = xz.flowcell_id)
//		        AND ((fz.status_id NOT IN (1,2,75))
//		        OR (zc.status_id <> 61))
//		        AND (xz.sample_id = s.sample_id))) AS bad_lanes,
//		
//		    /* REQUEUED LANES */
//		    (SELECT coalesce(sum(rq.lanes_requested),0)
//		        FROM requeue_report rq
//		        WHERE ((rq.status_id in (59,71,73))
//		        AND (rq.sample_id = s.sample_id))) AS requeued_lanes,
//		
//		    /* YIELD TRIMMED (Gb) */
//		    (SELECT coalesce(sum(tr.pass_yield_gb),0)
//		        FROM (((lane xz join flowcell_lane_qc zc) join flowcell fz) join trim_report tr)
//		        WHERE ((fz.flowcell_id = xz.flowcell_id)
//		        AND (xz.flowcell_id = zc.flowcell_id)
//		        AND (xz.sample_id = s.sample_id)
//		        AND (zc.lane_id = xz.lane_id)
//		        AND (fz.status_id = 2)
//		        AND (zc.status_id = 61)
//		        AND (tr.flowcell_id = zc.flowcell_id)
//		        AND (tr.lane_id = zc.lane_id))) AS yield_trimmed_gb,
//		
//		    /* YIELD ALIGNED (Gb) */
//		    (SELECT round(sum((((r2.read1_per_align + r2.read2_per_align) / 200) * tr.pass_yield_gb)),2)
//		        FROM ((((lane xz join flowcell_lane_qc zc) join flowcell fz) join trim_report tr) join flowcell_report_trim r2)
//		        WHERE ((fz.flowcell_id = xz.flowcell_id)
//		        AND (xz.flowcell_id = zc.flowcell_id)
//		        AND (xz.sample_id = s.sample_id)
//		        AND (zc.lane_id = xz.lane_id)
//		        AND (fz.status_id = 2)
//		        AND (zc.status_id = 61)
//		        AND (tr.flowcell_id = zc.flowcell_id)
//		        AND (tr.lane_id = zc.lane_id)
//		        AND (r2.flowcell_id = tr.flowcell_id)
//		        AND (r2.lane_id = tr.lane_id))) AS yield_align_gb,
//		        
//		    /* TOTAL ESTIMATED YIELD */
//		    (SELECT (yield_trimmed_gb + ((requeued_lanes + seq_lanes) * 37))) AS total_estimated_yield_gb,
//		
//		    /* NEEDED YIELD */
//		    (SELECT coverageToyield(s.target_fold_coverage)) AS needed_yield,
//		
//		    /* MISSING YIELD */
//		    (SELECT (coverageToyield(s.target_fold_coverage) - total_estimated_yield_gb)) AS missing_yield,
//		
//		    /* NEED LANES */
//		    (SELECT if((missing_yield > 0), ceiling((missing_yield / 37)),0)) AS need_lanes
//		        FROM (sample s join project p)
//		        WHERE (s.project_id = p.project_id)
//		        GROUP BY s.sample_barcode
//		        ORDER BY
//		        
//		        (SELECT coalesce(sum(rq.lanes_requested),0)
//		        FROM requeue_report rq
//		        WHERE ((rq.status_id in (59,73))
//		        AND (rq.sample_id = s.sample_id))) DESC
//
// lanes: Array
//            Lane object hashes
// flowcellIdLaneIdTrimReportObjectHash: Hash
//            TwoD hash of flowcell_id and lane_id vs trim_report object
// returns:
//            A floating point (2 decimal places)

    var sampleIdBuildObjectHash = this.core.data.getHash("build_report", "objectHash", "sample_id");

    // SAMPLE ID VS LANE OBJECTS ARRAY HASH
    var sampleIdLanesObjectArrayHash = this.core.data.getHash("lane", "objectArrayHash", "sample_id");

    // FLOWCELL ID AND LANE ID VS QC OBJECT HASH
    var flowcellIdLaneIdQcObjectHash = this.core.data.getHash("flowcelllaneqc", "twoDHash", "flowcell_id", "lane_id");

    // FLOWCELL ID AND LANE ID VS TRIM REPORT OBJECT HASH
    var flowcellIdLaneIdTrimReportObjectHash = this.core.data.getHash("trimreport", "objectHash", "flowcell_id", "lane_id");

    // FLOWCELL ID AND LANE ID VS TRIM REPORT OBJECT HASH
    var flowcellIdLaneIdFlowcellReportTrimObjectHash = this.core.data.getHash("flowcellreporttrim", "twoDHash", "flowcell_id", "lane_id");

    // SAMPLE IFD VS REQUEUE REPORT OBJECT HASH
    var sampleIdRequeueReportObjectHash = this.core.data.getHash("requeuereport", "objectHash", "sample_id");

	// STATUS ID VS STATUS HASH
	var statusIdStatusHash	=	this.core.data.getHash("status", "hash", "status_id", "status");	
	
    // GET ARRAY OF SAMPLES FOR THIS PROJECT
    var samples = this.getSamples(projectName);
    
    var thisObject = this;
    arrayUtil.forEach(samples, function(sample, i) {
        var buildreport = sampleIdBuildObjectHash[sample.sample_id];
        
        // GET BUILD REPORT STATS
        sample = thisObject.getBuildStats(sample);
        
        // GET LANES
        var lanes = sampleIdLanesObjectArrayHash[sample.sample_id];

        // GET LANE STATS
        sample = thisObject.getLaneStats(sample, lanes, flowcellIdLaneIdQcObjectHash, sampleIdRequeueReportObjectHash);
        
        // GET YIELD STATS
        sample = thisObject.getYieldStats(sample, lanes, flowcellIdLaneIdTrimReportObjectHash, flowcellIdLaneIdFlowcellReportTrimObjectHash);

		if ( sample.status_id ) {
			sample.status = statusIdStatusHash[sample.status_id];
		}
    });

    return samples;
},
getCommentData : function (projectName) {
	console.log("Details.Flowcell.getCommentData    this:");
	console.dir({this:this});
	var comments = this.getCommentsTable();
	console.log("Details.Flowcell.getCommentData    comments:");
	console.dir({comments:comments});

    var hash = this.core.data.getHash("project", "hash", "project_name", "project_id");
    var projectId = hash[projectName];

	var keys = ["project_id"];
	comments = this.filterByKeyValues(comments, keys, [projectId]);

    console.log("Detailed.Flowcell.getInfoData    Returning " + comments.length + " comments:");
    console.dir({comments:comments});
    
    return comments;
},
getCommentsTable : function () {
	return this.core.data.getTable("project_comment");
}



});

});
