define([

    "dojo/_base/declare",
    "dojo/_base/array",
    "plugins/core/Common/Array",
    "dojo/json",
	"plugins/core/Common",
    "dojo/domReady!"

],
function(declare, arrayUtil, commonArray, JSON, Common) {
////}}}}} 
return declare([Common], {
////}}}}

// core: Hash
// 		Holder for major components, e.g., core.data, core.dataStore
core : null,

// attachPoint : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

attachPane : function () {
	if ( ! this.attachPoint ) {
		console.log("Base.attachPane    this.attachPoint is not defined. Returning");
		return;
	}
	
	console.log("Base.attachPane    this.tabNode: " + this.tabNode);
	console.log("Base.attachPane    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});

	//if ( this.attachPoint.addChild ) {
		console.log("Base.attachPane    DOING this.attachPoint.addChild");
		this.attachPoint.addChild(this.tabNode);
		this.attachPoint.selectChild(this.tabNode);
	
	//}
	//if ( this.attachPoint.appendChild ) {
	//	console.log("Base.attachPane    DOING this.attachPoint.appendChild");
	//	this.attachPoint.appendChild(this.tabNode);
	//}	
	
	console.log("Base.attachPane    AFTER this.attachPoint.addChild");
},

// GET HASH DATA
getHash : function (table, mode, id1, id2) {
    return this.core.data.getHash(table, mode, id1, id2);  
},
getSamples : function (projectName) {
    console.log("Infusion.Detailed.Project.getSamples    projectName: " + projectName);
    var projectIdSamplesObjectArrayHash = this.core.data.getHash("sample", "objectArrayHash", "project_id");
    var projectNameIdHash = this.core.data.getHash("project", "hash", "project_name", "project_id");

    var projectId = projectNameIdHash[projectName];
    var samples = projectIdSamplesObjectArrayHash[projectId];
    //console.log("Infusion.Detailed.Project.getSamples    projectId: " + projectId);
    //console.log("Infusion.Detailed.Project.getSamples    BEFORE samples:");
    //console.dir({samples:samples});
    
    return samples;
},
// BUILD STATS
getBuildStats : function (sample) {
    var sampleIdBuildObjectHash = this.core.data.getHash("build_report", "objectHash", "sample_id");
    
    sample.gt_concordance = sampleIdBuildObjectHash[sample.sample_id] ? sampleIdBuildObjectHash[sample.sample_id].gt_gen_concordance : '';
    sample.contam_hom_fraction = sampleIdBuildObjectHash[sample.sample_id] ? sampleIdBuildObjectHash[sample.sample_id].contam_hom_fraction_bad : '';

    return sample    
},
// YIELD STATS
getYieldStats : function (sample, lanes) {    
    if ( ! lanes )  return sample;

  var flowcellIdLaneIdTrimReportObjectHash  =   this.core.data.getHash("trimreport", "twoDHash", "flowcell_id", "lane_id");
  var flowcellIdLaneIdFlowcellReportTrimObjectHash  =   this.core.data.getHash("flowcellreporttrim", "twoDHash", "flowcell_id", "lane_id");
    
    // SHOW:
    sample.trimmed_yield    =   this.getTrimmedYield(lanes, flowcellIdLaneIdTrimReportObjectHash);
    sample.aligned_yield    =   this.getAlignedYield(lanes, flowcellIdLaneIdTrimReportObjectHash, flowcellIdLaneIdFlowcellReportTrimObjectHash);
    sample.estimated_yield    =   this.getEstimatedYield(sample);

    // HIDE:
    sample.missing_yield    =   this.getMissingYield(sample);
    sample.need_lanes    =   this.getNeedLanes(sample);
    
    return sample;
},
getLanes : function (sampleId) {
    //console.log("Detailed.Project.getLanes    sampleId: " + sampleId);
    var sampleIdLanesObjectArrayHash = this.core.data.getHash("lane", "objectArrayHash", "sample_id");
    var lanes = sampleIdLanesObjectArrayHash[sampleId];
    //console.log("Detailed.Project.getLanes    lanes:");
    //console.dir({lanes:lanes});

    return lanes;    
},
getAllLanes : function (flowcellBarcode) {
    console.log("Detailed.Project.getAllLanes    flowcellBarcode: " + flowcellBarcode);
    var flowcellIdLanesObjectArrayHash = this.core.data.getHash("lane", "objectArrayHash", "flowcell_id");
    var flowcellBarcodeIdHash = this.core.data.getHash("flowcell", "hash", "flowcell_barcode", "flowcell_id");
	var flowcellId = flowcellBarcodeIdHash[flowcellBarcode];
	console.log("Detailed.Project.getAllLanes    flowcellId: " + flowcellId);
	
	var lanes = flowcellIdLanesObjectArrayHash[flowcellId];
    console.log("Detailed.Project.getAllLanes    lanes:");
    console.dir({lanes:lanes});

    return lanes;    
},
getTrimmedYield : function (lanes, flowcellIdLaneIdTrimReportObjectHash) {
// summary:
//      Return the trimmed yield for the sample
//      Corresponds to the original view query:
//      /* YIELD TRIMMED (Gb) */
//      (SELECT coalesce(sum(tr.pass_yield_gb),0)
//        FROM (((lane xz join flowcell_lane_qc zc) join flowcell fz) join trim_report tr)
//        WHERE ((fz.flowcell_id = xz.flowcell_id)
//        AND (xz.flowcell_id = zc.flowcell_id)
//        AND (xz.sample_id = s.sample_id)
//        AND (zc.lane_id = xz.lane_id)
//        AND (fz.status_id = 2)
//        AND (zc.status_id = 61)
//        AND (tr.flowcell_id = zc.flowcell_id)
//        AND (tr.lane_id = zc.lane_id))) AS yield_trimmed_gb,
//
// lanes: Array
//            Lane object hashes
// flowcellIdLaneIdTrimReportObjectHash: Hash
//            TwoD hash of flowcell_id and lane_id vs trim_report object
// returns:
//            A floating point (2 decimal places)
    
     var trimmedYield = parseFloat(0);
    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i) {
        //console.log("Detailed.Sample.getTrimmedYield    lane:");
        //console.dir({lane:lane});
        trimmedYield += thisObject.laneTrimmedYield(lane, flowcellIdLaneIdTrimReportObjectHash);
    });
    trimmedYield = parseFloat(trimmedYield).toFixed(2)
    
    //console.log("Detailed.Sample.getTrimmedYield    trimmedYield: " + trimmedYield);
    //console.dir({trimmedYield:trimmedYield});
    
    return trimmedYield;
},
laneTrimmedYield : function (lane, flowcellIdLaneIdTrimReportObjectHash) {
    var trimmedYield = 0;
    
    // GET LANE QC IF AVAILABLE
    var laneTrimReport = flowcellIdLaneIdTrimReportObjectHash[lane.flowcell_id]
        && flowcellIdLaneIdTrimReportObjectHash[lane.flowcell_id][lane.lane_id] ?
        flowcellIdLaneIdTrimReportObjectHash[lane.flowcell_id][lane.lane_id] : null;
    //console.log("Detailed.Sample.getTrimmedYield    laneTrimReport: ");
    //console.dir({laneTrimReport:laneTrimReport});
    
    if ( laneTrimReport && laneTrimReport.pass_yield_gb ) {
        trimmedYield += (trimmedYield + parseFloat(laneTrimReport.pass_yield_gb));
        //console.log("Detailed.Sample.getTrimmedYield    ADDING lane " + lane.lane_id + " laneTrimReport.pass_yield_gb: " + laneTrimReport.pass_yield_gb);
        //console.log("Detailed.Sample.getTrimmedYield    CURRENT trimmedYield: " + trimmedYield);
    }    

    return trimmedYield;
},
getAlignedYield : function (lanes, flowcellIdLaneIdTrimReportObjectHash, flowcellIdLaneIdFlowcellReportTrimObjectHash) {
// summary:
//		Return the aligned yield for the sample
//		Corresponds to the original view query:
//		/* YIELD ALIGNED (Gb) */
//		(SELECT round(sum((((r2.read1_per_align + r2.read2_per_align) / 200) * tr.pass_yield_gb)),2)
//		FROM ((((lane xz join flowcell_lane_qc zc) join flowcell fz) join trim_report tr) join flowcell_report_trim r2)
//      WHERE ((fz.flowcell_id = xz.flowcell_id)
//		AND (xz.flowcell_id = zc.flowcell_id)
//		AND (xz.sample_id = s.sample_id)
//		AND (zc.lane_id = xz.lane_id)
//		AND (fz.status_id = 2)
//		AND (zc.status_id = 61)
//		AND (tr.flowcell_id = zc.flowcell_id)
//		AND (tr.lane_id = zc.lane_id)
//		AND (r2.flowcell_id = tr.flowcell_id)
//		AND (r2.lane_id = tr.lane_id))) AS yield_align_gb,
//
// lanes: Array
//            Lane object hashes
// flowcellIdLaneIdTrimReportObjectHash: Hash
//            TwoD hash of flowcell_id and lane_id vs trim_report object
// flowcellIdLaneIdFlowcellReportTrimObjectHash: Hash
//            TwoD hash of flowcell_id and lane_id vs flowcell_report_trim object
// returns:
//            A floating point (2 decimal places)

    var alignedYield = parseFloat(0);
    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i) {
        ////console.log("Infusion.Detailed.Project.getAlignedYield    lane:");
        ////console.dir({lane:lane});

        alignedYield += thisObject.laneAlignedYield(lane, flowcellIdLaneIdTrimReportObjectHash, flowcellIdLaneIdFlowcellReportTrimObjectHash);
        ////console.log("Infusion.Detailed.Project.getAlignedYield    CURRENT alignedYield: " + alignedYield);
        
        return true;
    });

    alignedYield = parseFloat(alignedYield).toFixed(2)
    
    ////console.log("Infusion.Detailed.Project.getAlignedYield    alignedYield: " + alignedYield);
    ////console.dir({alignedYield:alignedYield});
    
    return alignedYield;
},
laneAlignedYield : function (lane, flowcellIdLaneIdTrimReportObjectHash, flowcellIdLaneIdFlowcellReportTrimObjectHash) {
    var alignedYield = 0;

    // GET LANE QC IF AVAILABLE
    var trimReport = flowcellIdLaneIdTrimReportObjectHash[lane.flowcell_id]
        && flowcellIdLaneIdTrimReportObjectHash[lane.flowcell_id][lane.lane_id] ?
        flowcellIdLaneIdTrimReportObjectHash[lane.flowcell_id][lane.lane_id] : null;
    //console.log("Infusion.Detailed.Project.laneAlignedYield    trimReport: ");
    //console.dir({trimReport:trimReport});
    
    var flowcellTrimReport = flowcellIdLaneIdFlowcellReportTrimObjectHash[lane.flowcell_id]
        && flowcellIdLaneIdFlowcellReportTrimObjectHash[lane.flowcell_id][lane.lane_id] ?
        flowcellIdLaneIdFlowcellReportTrimObjectHash[lane.flowcell_id][lane.lane_id] : null;
    //console.log("Infusion.Detailed.Project.laneAlignedYield    flowcellTrimReport: ");
    //console.dir({flowcellTrimReport:flowcellTrimReport});
    
    if ( ! trimReport ) return alignedYield;
    if ( ! flowcellTrimReport ) return alignedYield;
    
    var passYield = trimReport.pass_yield_gb;
    var readOneAligned = flowcellTrimReport.read1_per_align;
    var readTwoAligned = flowcellTrimReport.read2_per_align;
    if ( ! passYield ) return alignedYield;
    if ( ! readOneAligned ) return alignedYield;
    if ( ! readTwoAligned ) return alignedYield;
    
    //console.log("Infusion.Detailed.Project.laneAlignedYield    ADDING lane " + lane.lane_id);
    //console.log("Infusion.Detailed.Project.laneAlignedYield    passYield: " + passYield);
    //console.log("Infusion.Detailed.Project.laneAlignedYield    readOneAligned: " + readOneAligned);
    //console.log("Infusion.Detailed.Project.laneAlignedYield    readTwoAligned: " + readTwoAligned);

    alignedYield = (
        ( ( parseFloat(readOneAligned) + parseFloat(readTwoAligned) ) / 200 )
        * parseFloat(passYield)
    );

    return alignedYield;
},
getEstimatedYield : function (sample) {
// summary:
//		Return the estimated yield for the sample
//		Corresponds to the original view query:
//      /* TOTAL ESTIMATED YIELD */
//      (SELECT (yield_trimmed_gb + ((requeued_lanes + seq_lanes) * 37))) AS total_estimated_yield_gb,
//
// sample: Hash
//      Hash of sample object
// returns:
//      A floating point (2 decimal places)

    //console.log("Infusion.Detailed.Project.getEstimatedYield    sample:");
    //console.dir({sample:sample});

    var yieldPerLane = this.yieldPerLane;
    //console.log("Infusion.Detailed.Project.getEstimatedYield    yieldPerLane: " + yieldPerLane);

    var estimatedYield = sample.requeued_lanes && sample.sequencing_lanes
        ? 
        parseFloat(sample.trimmed_yield)
        + parseFloat(
            ( parseFloat(sample.requeued_lanes) + parseFloat(sample.sequencing_lanes) )
            * yieldPerLane
        )
        :
        parseFloat(sample.trimmed_yield);

    //console.log("Infusion.Detailed.Project.getEstimatedYield    estimatedYield: " + estimatedYield);
    
    return estimatedYield;
},
getMissingYield : function (sample) {
// summary:
//		Return the missing yield for the sample
//		Corresponds to the original view query:
//    /* MISSING YIELD */
//    (SELECT (coverageToyield(s.target_fold_coverage) - total_estimated_yield_gb)) AS missing_yield,
// sample: Hash
//      Hash of sample object
// returns:
//      A floating point (2 decimal places)
    ////console.log("Infusion.Detailed.Project.getMissingYield    sample:");
    ////console.dir({sample:sample});

    var targetCoverage = this.getTargetCoverage(sample.target_fold_coverage);
    if ( ! targetCoverage ) return null;
    ////console.log("Infusion.Detailed.Project.getMissingYield    targetCoverage: " + targetCoverage);
    
    var estimatedYield = sample.estimated_yield;
    if ( ! estimatedYield ) estimatedYield = 0;
    ////console.log("Infusion.Detailed.Project.getMissingYield    estimatedYield: " + estimatedYield);

    var missingYield = targetCoverage - estimatedYield;
    missingYield = missingYield.toFixed(2);
    ////console.log("Infusion.Detailed.Project.getEstimatedYield    missingYield: " + missingYield);

    return missingYield;    
},
getTargetCoverage : function (foldCoverage) {
    if ( !foldCoverage )  return null;
    if ( foldCoverage.match(/G$/i) )    return foldCoverage;
    
    // IF NO 'G' AT END OF foldCoverage, IT IS IN MULTIPLES
    // SO CONVERT INTO Gbases
    var coverageRatio = this.coverageRatio;
    
    var targetCoverage = ( parseFloat(foldCoverage) * parseFloat(coverageRatio) );
    
    return targetCoverage;
},
getNeedLanes : function (sample) {
// summary:
//		Return the needed lanes for the sample
//		Corresponds to the original view query:
//		/* NEED LANES */
//		(SELECT if((missing_yield > 0), ceiling((missing_yield / 37)),0)) AS need_lanes
//		FROM (sample s join project p)
//		WHERE (s.project_id = p.project_id)
//		GROUP BY s.sample_barcode
//		ORDER BY
//		//		(SELECT coalesce(sum(rq.lanes_requested),0)
//		FROM requeue_report rq
//		WHERE ((rq.status_id in (59,73))
//		AND (rq.sample_id = s.sample_id))) DESC
// sample: Hash
//      Hash of sample object
// returns:
//      An integer
    var yieldPerLane = this.yieldPerLane;
    ////console.log("Infusion.Detailed.Project.getNeedLanes    yieldPerLane: " + yieldPerLane);

    var missingYield = sample.missing_yield;
    if ( ! missingYield ) return null;
    ////console.log("Infusion.Detailed.Project.getNeedLanes    missingYield: " + missingYield);
    if ( missingYield < 0 ) return 0;
    
    var needLanes = Math.ceil(missingYield / yieldPerLane);
    ////console.log("Infusion.Detailed.Project.getNeedLanes    needLanes: " + needLanes);
    
    return needLanes;  
},
// LANE STATS
getLaneStats : function (sample, lanes) {
    //console.log("Infusion.Detailed.Project.getLaneStats    sample:");
    //console.dir({sample:sample});
    //console.log("Infusion.Detailed.Project.getLaneStats    lanes:");
    //console.dir({lanes:lanes});

    if ( ! lanes )  return sample;

    var flowcellIdLaneIdQcObjectHash    =   this.core.data.getHash("flowcelllaneqc", "twoDHash", "flowcell_id", "lane_id");
    var sampleIdRequeueReportObjectHash =   this.core.data.getHash("requeuereport", "objectHash", "sample_id");
    //console.log("Infusion.Detailed.Project.getLaneStats    flowcellIdLaneIdQcObjectHash:");
    //console.dir({flowcellIdLaneIdQcObjectHash:flowcellIdLaneIdQcObjectHash});
    //console.log("Infusion.Detailed.Project.getLaneStats    sampleIdRequeueReportObjectHash:");
    //console.dir({sampleIdRequeueReportObjectHash:sampleIdRequeueReportObjectHash});

    var requeueReport = sampleIdRequeueReportObjectHash[sample.sample_id];
    //console.log("Infusion.Detailed.Project.getLaneStats    requeueReport:");
    //console.dir({requeueReport:requeueReport});
    
    // SHOW:
    sample.total_lanes      =   lanes.length;
    sample.good_lanes       =   (this.getGoodLanes(lanes, flowcellIdLaneIdQcObjectHash)).length;

    // HIDE:
    sample.bad_lanes        =   (this.getBadLanes(lanes, flowcellIdLaneIdQcObjectHash)).length;
    sample.sequencing_lanes =   (this.getSequencingLanes(lanes, requeueReport)).length;
    sample.requeued_lanes   =   (this.getRequeuedLanes(lanes, sampleIdRequeueReportObjectHash)).length;

    //console.log("Infusion.Detailed.Project.getLaneStats    sample.total_lanes: " + sample.total_lanes);
    //console.log("Infusion.Detailed.Project.getLaneStats    sample.good_lanes: " + sample.good_lanes);
    //console.log("Infusion.Detailed.Project.getLaneStats    sample.bad_lanes: " + sample.bad_lanes);
    //console.log("Infusion.Detailed.Project.getLaneStats    sample.sequencing_lanes: " + sample.sequencing_lanes);
    
    return sample;
},
getBadLanes : function (lanes, flowcellIdLaneIdQcObjectHash) {
// summary:
//      Return the array of bad lanes among the supplied lanes
//      Corresponds to the original view query:
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
//      Status IDs:
//      |         1 | run_started             | flow cell registered for a run started        |
//      |         2 | run_finished            | flow cell data files are all present          |
//      |        51 | bcl_deleted             | sample was delivered and bcls deleted         |
//      |        61 | lane_qc_pass            | pass qc metrics                               |
//      |        75 | to_rehyb                | the flowcell with be attempted to rehyb       |
// lanes: Array
//      Lane object hashes
// flowcellIdLaneIdQcObjectHash: Hash
//      TwoD hash of flowcell_id and lane_id vs flowcell_lane_qc object
// returns:
//      An array of lane object hashes
    var badLanes = [];
    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i) {
        ////console.log("Infusion.Detailed.Project.getBadLanes    lane.status_id: " + lane.status_id);

        // GET LANE QC IF AVAILABLE
        var laneQc = thisObject.getLaneQc(lane, flowcellIdLaneIdQcObjectHash);
        //console.log("Infusion.Detailed.Project.getBadLanes    laneQc: " + laneQc);
        //console.log("Infusion.Detailed.Project.getBadLanes    lane: ");
        ////console.dir({lane:lane});
    
        var statusId = lane.status_id;
        //console.log("Infusion.Detailed.Project.getBadLanes    statusId: " + statusId);

        if (
            ( statusId != 1
            && statusId != 2
            && statusId != 51
            && statusId != 75 ) 
            ||
            ( laneQc != 61 )
        ) {
            badLanes.push(lane);
        }
    });
    ////console.log("Infusion.Detailed.Project.getBadLanes    badLanes:");
    ////console.dir({badLanes:badLanes});
    
    return badLanes;
},
getLaneQc : function (lane, flowcellIdLaneIdQcObjectHash) {
    var laneQcObject = flowcellIdLaneIdQcObjectHash[lane.flowcell_id]
        && flowcellIdLaneIdQcObjectHash[lane.flowcell_id][lane.lane_id] ?
        flowcellIdLaneIdQcObjectHash[lane.flowcell_id][lane.lane_id] : null;
    
    //console.log("Infusion.Detailed.Project.getLaneQc    laneQcObject: ");
    //console.dir({laneQcObject:laneQcObject});
    var laneQc = laneQcObject ? laneQcObject.status_id : 0;

    return laneQc;
},
getGoodLanes : function (lanes, flowcellIdLaneIdQcObjectHash) {
// summary:
//      Return the array of good lanes among the supplied lanes
//      Corresponds to the original view query:
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
//      Status IDs:
//      |         2 | run_finished            | flow cell data files are all present          |
//      |        51 | bcl_deleted             | sample was delivered and bcls deleted         |
//      |        61 | lane_qc_pass            | pass qc metrics                               |
// lanes: Array
//      Lane object hashes
// flowcellIdLaneIdQcObjectHash: Hash
//      TwoD hash of flowcell_id and lane_id vs flowcell_lane_qc object
// returns:
//      An array of lane object hashes

    //console.log("Infusion.Detailed.Project.getGoodLanes    flowcellIdLaneIdQcObjectHash: ");
    //console.dir({flowcellIdLaneIdQcObjectHash:flowcellIdLaneIdQcObjectHash});
    //console.log("Infusion.Detailed.Project.getGoodLanes    lanes: ");
    //console.dir({lanes:lanes});

    var goodLanes = [];
    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i) {
        //console.log("Infusion.Detailed.Project.getGoodLanes    lane: ");
        //console.dir({lane:lane});
        //console.log("Infusion.Detailed.Project.getGoodLanes    lane.status_id: " + lane.status_id);

        var laneQc = thisObject.getLaneQc(lane, flowcellIdLaneIdQcObjectHash);
        if ( !laneQc )  laneQc = 0;
        //console.log("Infusion.Detailed.Project.getGoodLanes    laneQc: " + laneQc);
        
        var statusId = lane.status_id;
        //console.log("Infusion.Detailed.Project.getGoodLanes    statusId: " + statusId);
        
        if (
            ( statusId == 2 || statusId == 51 )
            && laneQc == 61
        ) {
            goodLanes.push(lane);
        }
    });
    //console.log("Infusion.Detailed.Project.getGoodLanes    goodLanes:");
    //console.dir({goodLanes:goodLanes});
    
    return goodLanes;
},
getSequencingLanes : function (lanes, requeueReport) {
    var sequencingLanes = [];
    arrayUtil.forEach(lanes, function(lane, i) {
        ////console.log("Infusion.Detailed.Project.getSequencingLanes    lane.status_id: " + lane.status_id);
        
        if ( lane.status_id == 1 || lane.status_id == 75 ) {
            sequencingLanes.push(lane);
        }
    });
    ////console.log("Infusion.Detailed.Project.getSequencingLanes    sequencingLanes:");
    ////console.dir({sequencingLanes:sequencingLanes});
    
    return sequencingLanes;
},
getRequeuedLanes : function ( lanes, sampleIdRequeueReportObjectHash) {
// summary:
//      Return the array of queued lanes among the supplied lanes
//      Corresponds to the original view query:
//          /* REQUEUED LANES */
//          (SELECT coalesce(sum(rq.lanes_requested),0)
//          FROM requeue_report rq
//          WHERE ((rq.status_id in (59,71,73))
//          AND (rq.sample_id = s.sample_id))) AS requeued_lanes,
// lanes: Array
//            Lane object hashes
// sampleIdRequeueReportObjectHash: Hash
//            Hash of sample_id vs requeue_report object
// returns:
//            An array of lane object hashes
    var requeuedLanes = [];
    var thisObject = this;
    arrayUtil.forEach(lanes, function(lane, i) {
        var sampleId = lane.sample_id;
        ////console.log("Infusion.Detailed.Project.getRequeuedLanes    sampleId: " + sampleId);
        if ( ! sampleId ) {
            return true;
        }
        var requeueReport = sampleIdRequeueReportObjectHash[sampleId];
        ////console.log("Infusion.Detailed.Project.getRequeuedLanes    requeueReport: ");
        ////console.dir({requeueReport:requeueReport});
        if ( ! requeueReport ) {
            return true;
        }

        var requeueStatusId = requeueReport.status_id;
        ////console.log("Infusion.Detailed.Project.getRequeuedLanes    requeueStatusId: " + requeueStatusId);

        if ( requeueStatusId == 59
            || requeueStatusId == 71
            || requeueStatusId == 73 ) {
            requeuedLanes.push(lane);
        }
        
        return true;
    });
    ////console.log("Infusion.Detailed.Project.getRequeuedLanes    requeuedLanes:");
    ////console.dir({requeuedLanes:requeuedLanes});
    
    return requeuedLanes;
},
// HASH UTILITY METHODS
addHashes : function (hash1, hash2) {
    for (var key in hash2 ) {
        hash1[key] = hash2[key];
    }
    
    return hash1;
},
getTable : function (table) {
    return Agua.cloneData(table);
},
updateTable : function (data, field, oldValue, newValue) {
    // xhrPut TO BACKEND
    
    console.log("Detailed.Sample.updateTable    data:");
    console.dir({data:data});
    console.log("Detailed.Sample.updateTable    field: " + field);
    console.log("Detailed.Sample.updateTable    oldValue: " + oldValue);
    console.log("Detailed.Sample.updateTable    newValue: " + newValue);
    
    //  mode     :   String  updateTable
    //  username :   String
    //  data     :   Hash
    //  table    :   String project
    //  field    :   String
    //  oldValue    :   String
    //  newValue    :   String    
    
}
//,
//// SHOW AND HIDE PARENT WIDGET (I.E., TAB CONTAINER)
//show : function () {
//    this.core.infusionWidget.details.setContents(this.containerNode);
//    domClass.remove(this.containerNode, "hidden");
//},
//hide : function () {
//    domClass.add(this.containerNode, "hidden");
//}


});

});
