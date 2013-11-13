define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dgrid/List",
	"dgrid/OnDemandGrid",
	"dgrid/Selection",
	"dgrid/Keyboard",
	"dgrid/extensions/ColumnHider",
	"dojo/store/Memory",
	"plugins/core/Common",
	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/infusion/SelectList",
	"plugins/infusion/Menu/Project",
	"plugins/infusion/Menu/Sample",
	"plugins/infusion/Menu/Flowcell",
	"plugins/infusion/Menu/Lane",
	"plugins/infusion/Dialog/Project",
	"plugins/form/UploadDialog",
	"dojo/ready",
	"dojo/domReady!",
	"dijit/layout/ContentPane",
	"dijit/form/TextBox",
	"dijit/form/Select",
	"dijit/form/Button"


],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, List, Grid, Selection, Keyboard, Hider, Memory, Common, _Widget, _Templated, SelectList, ProjectMenu, SampleMenu, FlowcellMenu, LaneMenu, DialogProject, UploadDialog, ready) {

//////}}}}}

return declare("plugins.infusion.Filter", [_Widget, _Templated, Common], {

// Path to the template of this widget. 
// templatePath : String
templatePath : require.toUrl("plugins/infusion/templates/filter.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// core: Storage point for references to all related class instances
// 		Storage point for references to all related class instances
core : null,

// doneTypingInterval : Integer
// Run 'setTimeout' when this timing interval ends
doneTypingInterval : 500,

// core: Hash
// 		Holder for major components, e.g., core.data, core.dataStore
core : null,

// cssFiles : Array
// CSS FILES
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/css/infusion.css"),
	require.toUrl("dojox/layout/resources/ExpandoPane.css"),
	require.toUrl("plugins/infusion/images/elusive/css/elusive-webfont.css")
	
	//,
	//dojo.moduleUrl("https://da1s119xsxmu0.cloudfront.net/libraries/bootstrap/1.3.3/bootstrap.min.css")
],

////}}}}}

//////}}
constructor : function(args) {		
	console.log("Infusion.constructor    args:");
	console.dir({args:args});
	
    // MIXIN ARGS
    lang.mixin(this, args);

	// SET CORE
	this.core.filter = this;

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	//console.log("Infusion.postCreate    plugins.infusion.Infusion.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Infusion.startup    plugins.infusion.Infusion.startup()");
	if ( ! this.attachWidget ) {
		console.log("Infusion.startup    this.attachWidget is null. Returning");
		return;
	}
	
	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// CREATE LISTS
	this.projectList 	= 	new SelectList({ selectionMode: "single" }, "projects");
	this.sampleList 	= 	new SelectList({ selectionMode: "single" }, "samples");
	this.flowcellList 	= 	new SelectList({ selectionMode: "single" }, "flowcells");
	this.laneList 		=	new SelectList({ selectionMode: "single" }, "lanes");
},
// SET SELECT LISTENERS
setProjectSelect : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	var data = [
        {
			label: "&nbsp;",
			value: ""
		},
        {
			label: "Active",
			value: "active"
		},
        {
			label: "Hold",
			value: "hold"
		},
        {
			label: "Complete",
			value: "complete"
		},
        {
			label: "Cancelled",
			value: "cancelled"
		}
	];	
	this.projectSelect.options = data;
	//console.log("Filter.setProjectSelect    this.projectSelect.options:");
	//console.dir({this_projectSelect_options:this.projectSelect.options});
	//console.log("Filter.setProjectSelect    DOING this.projectSelect.startup()");
	
	var thisObject = this;
	this.projectSelect.on("change", function (selectedValue) {
		console.log("Filter.setProjectSelect    this.projectSelect.on('onChange') FIRED    selectedValue: " + selectedValue);

		thisObject.runSelectProject(selectedValue, dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	});
	
	this.projectSelect.startup();
},
setSampleSelect : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
// summary: Provide the following SAMPLE options:
//		LINKS
//		Undelivered Samples NOT QC'ed
//		Undelivered Samples Pass QC
//		Samples missing yield
//		Samples missing GT information
//		
//		COMBOBOX
//		active
//		delivered
//		pending_archive
//		qc_pass
//		qc_fail
//		cancelled
//		hold
//		loading_to_hd
//		loaded_to_hd
//		pm_hold

	var data = [
        {
			label: "&nbsp;",
			value: ""
		},
        {
			label: "Undelivered, No QC",
			value: "undeliveredNoQc"
		},
        {
			label: "Undelivered, QC Pass",
			value: "undeliveredQcPass"
		},
        {
			label: "Missing Yield",
			value: "missingYield"
		},
        {
			label: "Missing GT Info",
			value: "MissingGtInfo"
		},
        {
			label: "Active",
			value: "active"
		},
        {
			label: "Delivered",
			value: "delivered"
		},
        {
			label: "Pending Archive",
			value: "pendingArchive"
		},
        {
			label: "QC Pass",
			value: "qcPass"
		},
        {
			label: "QC Fail",
			value: "qcFail"
		},
        {
			label: "Cancelled",
			value: "cancelled"
		},
        {
			label: "Held",
			value: "held"
		},
        {
			label: "Loading Drive",
			value: "Loaded Drive"
		},
        {
			label: "P.M. Hold",
			value: "pmHold"
		}
	];	

	this.sampleSelect.options = data;
	console.log("Filter.setSampleSelect    this.sampleSelect.options:");
	console.dir({this_sampleSelect_options:this.sampleSelect.options});
	console.log("Filter.setSampleSelect    DOING this.sampleSelect.startup()");
	this.sampleSelect.startup();
},
setFlowcellSelect : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	var data = [
        {
			label: "&nbsp;"
			,
			value: ""
		},
        {
			label: "Active"
			,
			value: "active"
		},
        {
			label: "Finished"
			,
			value: "finished"
		},
        {
			label: "Failed"
			,
			value: "failed"
		},
        {
			label: "To Rehyb"
			,
			value: "toRehyb"
		}
	];	
	this.flowcellSelect.options = data;
	console.log("Filter.setFlowcellSelect    this.flowcellSelect.options:");
	console.dir({this_flowcellSelect_options:this.flowcellSelect.options});
	console.log("Filter.setFlowcellSelect    DOING this.flowcellSelect.startup()");
	this.flowcellSelect.startup();
},
setLaneSelect : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	var data = [
        {
			label: "&nbsp;"
			,
			value: ""
		},
        {
			label: "Active"
			,
			value: "active"
		},
        {
			label: "Finished"
			,
			value: "finished"
		},
        {
			label: "Failed"
			,
			value: "failed"
		},
        {
			label: "To Rehyb"
			,
			value: "toRehyb"
		}
	];	
	this.laneSelect.options = data;
	console.log("Filter.setLaneSelect    this.laneSelect.options:");
	console.dir({this_laneSelect_options:this.laneSelect.options});
	console.log("Filter.setLaneSelect    DOING this.laneSelect.startup()");
	this.laneSelect.startup();
},
runSelectProject : function (selectedValue, dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	console.log("Filter.runSelectProject    ONCHANGE FIRED    selectedValue:");
	console.dir({selectedValue:selectedValue});
	console.log("Filter.setProjectSelect    this.projectSelectOverlay: " + this.projectSelectOverlay);

	if ( selectedValue == "" ) {
		console.log("Filter.setProjectSelect    DOING domClass.remove(this.projectSelectOverlay, 'hidden')");
		domClass.remove(this.projectSelectOverlay, "hidden");
	}
	else {
		console.log("Filter.setProjectSelect    DOING domClass.add(this.projectSelectOverlay, 'hidden')");
		domClass.add(this.projectSelectOverlay, "hidden");
	}
	
	var filteredProjectsArray = this.filterByStatus("project", "project_name", projectsArray, selectedValue);
	var projectString = "^" + projectsArray.join("|") + "$";
	console.log("Filter.setProjectSelect    projectString: " + projectString);
	var projectRegex = new RegExp(projectString, "i");
	console.log("Filter.setProjectSelect    projectRegex: " + projectRegex);
	console.dir({projectRegex:projectRegex});
	
	// DISPLAY PROJECTS AND THEIR SAMPLES, ETC.
	this.displayProjects(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectRegex);
},
filterByStatus : function (table, fieldname, array, status) {
	console.log("Filter.filterByStatus    table: " + table);
	console.log("Filter.filterByStatus    array: " + array);
	console.dir({array:array});
	console.log("Filter.filterByStatus    status: " + status);
	console.log("Filter.filterByStatus    this.core: " + this.core);
	console.dir({this_core:this.core});

	// CALL getHash FROM Data.js
	var idStatusHash = this.core.data.getHash("status", "hash", "status_id", "status");
	var fieldObjectHash = this.core.data.getHash(table, "objectHash", fieldname);
	console.log("Filter.filterByStatus    idStatusHash: " + idStatusHash);
	console.dir({idStatusHash:idStatusHash});
	console.log("Filter.filterByStatus    fieldObjectHash: " + fieldObjectHash);
	console.dir({fieldObjectHash:fieldObjectHash});
	
	var data = this.getTable("status");
	var dataJson = JSON.stringify(data);
	console.log("Filter.filterByStatus    status dataJson: " + dataJson);	
	
	var filteredArray = [];
	for ( var i = 0; i < array.length; i++ ) {
		var fieldValue = array[i];
		//console.log("Filter.filterByStatus    fieldValue: " + fieldValue);
		
		// SKIP 'All ...'
		if ( fieldValue.match('All \()') ) {
			continue;
		}

		var object = fieldObjectHash[fieldValue];
		//console.log("Filter.filterByStatus    object: " + object);
		//console.dir({object:object});
		
		var statusid = object.status_id;
		//console.log("Filter.filterByStatus    statusid: " + statusid);
		
		var actualStatus = idStatusHash[statusid];
		//console.log("Filter.filterByStatus    actualStatus: " + actualStatus);
		
		if ( actualStatus.toLowerCase() == status.toLowerCase() ) {
			//console.log("Filter.filterByStatus    STATUS MATCH. DOING filteredArray.push(fieldvalue)");
			filteredArray.push(fieldValue);
		}
	}
	//console.log("Filter.filterByStatus    filteredArray.length: " + filteredArray.length);
	//console.dir({filteredArray:filteredArray});

	return filteredArray;	
},
runSelectSample : function (event) {
	console.log("Filter.runSampleSelect    ONCHANGE FIRED    event:");
	console.dir({event:event});
	
},
runSelectFlowcell : function (event) {
	console.log("Filter.runFlowcellSelect    ONCHANGE FIRED    event:");
	console.dir({event:event});
	
},
runSelectLane : function (event) {
	console.log("Filter.runLaneSelect    ONCHANGE FIRED    event:");
	console.dir({event:event});
},
// SET CLICK LISTENERS
setProjectClick : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {	
	//	start listening for selections on the lists.
	var thisObject = this;

	//projects.on("dgrid-select", function(e) {
	this.projectList.on(".dgrid-row:click", function(event) {
		console.log("Filter.setProjectClick    event: ");
		console.dir({event:event});

		// GET PROJECT FILTER IF EXISTS
		console.log("Filter.setProjectClick    thisObject.projectFilter: ");
		console.dir({this_projectFilter:thisObject.projectFilter});
		var projectFilter = thisObject.projectFilter.value;

		// CLEAR SAMPLE, FLOWCELL AND LANE FILTERS
		domAttr.set(thisObject.sampleFilter, 'value', "");
		domAttr.set(thisObject.flowcellFilter, 'value', "");
		domAttr.set(thisObject.laneFilter, 'value', "");
		domAttr.set(window.sampleFilter, 'value', "");
		domAttr.set(window.flowcellFilter, 'value', "");
		domAttr.set(window.laneFilter, 'value', "");
		
		//	GET FILTER (I.E., SELECTED PROJECT) FROM ROW
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedProject = row.data;

		// IF PROJECT FILTER HAS VALUE AND USER CLICKED 'All ...' ENTRY IN PROJECT LIST,
		// REDO PROJECT FILTER TO REFRESH ALL LISTS
		if ( projectFilter != "" && selectedProject.match(/All \(/) ) {
			thisObject.runProjectFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilter);
			return;
		}

		// GET SAMPLES FOR THIS PROJECT
		samplesArray = thisObject.getProjectSamples(dataStore, selectedProject);

		//console.log("Filter.setProjectClick    BEFORE thisObject.sampleList.refresh");
		thisObject.sampleList.refresh();	//	clear contents
		thisObject.sampleList.renderArray(samplesArray);
		thisObject.sampleList.select(0); //	reselect "all", triggering flowcells + lanes refresh
		console.log("Filter.setProjectClick    AFTER thisObject.sampleList.select(0)");

		// UPDATE BOTTOM PANE
		thisObject.showDetails("project", selectedProject);
	});
},
getProjectSamples : function (dataStore, selectedProject) {
	//console.log("Filter.getProjectSamples    selectedProject: " + selectedProject);

	//console.log("Filter.getProjectSamples    BEFORE dataStore.data: ");
	//console.dir({dataStore_data:dataStore.data});
	
	var samplesArray = [];
	//var samplesData = [];
	for ( var i = 0; i < dataStore.data.length; i++ ) {
		if ( selectedProject.match(/^All \(/ ) ) {
			samplesArray.push(dataStore.data[i].samplebarcode);
			//samplesData.push(dataStore.data[i]);
		}
		else if ( dataStore.data[i].projectname == selectedProject ) {
			samplesArray.push(dataStore.data[i].samplebarcode);
			//samplesData.push(dataStore.data[i]);
		}
	}
	//console.log("Filter.setProjectFilter   selectedProject: " + selectedProject);
	//console.log("Filter.setProjectFilter   samplesData: " + JSON.stringify(samplesData));
	
	// GET UNIQUE SAMPLES 
	samplesArray = this.unique(samplesArray);
	
	// ADD 'All ...' ENTRY
	samplesArray.unshift("All (" + samplesArray.length + " Sample" + (samplesArray.length != 1 ? "s" : "") + ")");
	
	//console.log("Filter.getProjectSamples    AFTER samplesArray: ");
	//console.dir({samplesArray:samplesArray});

	return samplesArray;
},
setSampleClick : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {	
	//console.log("Filter.setSampleClick    window.projects: ");
	//console.dir({window_projects:window.projects});
	
	var thisObject = this;

	this.sampleList.on("dgrid-select", function(event) {
		console.log("Filter.setSampleClick    event: ");
		console.dir({event:event});
		console.log("Filter.setSampleClick    thisObject.projects: ");
		console.dir({thisObject_projects:thisObject.projects});

		// CLEAR FLOWCELL AND LANE FILTERS
		domAttr.set(thisObject.flowcellFilter, 'value', "");
		domAttr.set(thisObject.laneFilter, 'value', "");
		domAttr.set(window.flowcellFilter, 'value', "");
		domAttr.set(window.laneFilter, 'value', "");

		// GET SELECTED SAMPLE AND SELECT PROJECT (IF AVAILABLE)
		var selectedProject = thisObject.projectList.getSelected();
		var selectedSample = event.rows[0].data;
		console.log("Filter.setSampleClick    selectedProject: " + selectedProject);
		console.log("Filter.setSampleClick    selectedSample: " + selectedSample);

		// CLEAR LANE FILTER
		domAttr.set(window.laneFilter, 'value', "");

		var projectFilter = thisObject.projectFilter.value;
		var sampleFilter = thisObject.sampleFilter.value;

		// IF SAMPLE FILTER HAS VALUE AND USER CLICKED 'All ...' ENTRY IN SAMPLE LIST,
		// REDO SAMPLE FILTER TO REFRESH LANE LIST WITH ALL ENTRIES MATCHING SAMPLE FILTER
		if ( sampleFilter != "" && selectedSample.match(/All \(/) ) {
			thisObject.runSampleFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilter, sampleFilter);
			return;
		}

		
		var flowcellsArray = thisObject.getSampleFlowcells(dataStore, selectedProject, selectedSample);

		thisObject.flowcellList.refresh(); //	clear contents
		thisObject.flowcellList.renderArray(flowcellsArray);
		thisObject.flowcellList.select(0); //	reselect "all" item, triggering grid refresh

		//var lanesArray = thisObject.getSampleLanes(dataStore, selectedProject, selectedSample);
		//
		//thisObject.laneList.refresh(); //	clear contents
		//thisObject.laneList.renderArray(lanesArray);
		//thisObject.laneList.select(0); //	reselect "all" item, triggering grid refresh

		// UPDATE BOTTOM PANE
		if ( ! selectedSample.match(/^All \(/) ) {
			thisObject.showDetails("sample", selectedSample);
		}
	});
},
getSampleLanes : function (dataStore, selectedProject, selectedSample) {
	console.log("Filter.getSampleLanes    selectedSample: " + selectedSample);

	//console.log("Filter.getSampleLanes    BEFORE dataStore.data: ");
	//console.dir({dataStore_data:dataStore.data});

	var lanesArray = [];
	for ( var i = 0; i < dataStore.data.length; i++ ) {
		// FILTER BY PROJECT IF SELECTED SAMPLE IS 'All ...'
		if ( selectedSample.match(/^All \(/) ) {

			// PUSH ALL IF SELECTED PROJECT IS 'All ...'
			if ( selectedProject.match(/^All \(/) ) {
				lanesArray.push(dataStore.data[i].lanebarcode);
			}
			else if ( dataStore.data[i].projectname == selectedProject ) {
				//console.log("Filter.getSampleLanes    MATCHED selectedProject: " + selectedProject);
				//console.log("Filter.getSampleLanes    dataStore.data[" + i + "]: ");
				//console.dir({dataStore_data_i:dataStore.data[i]});
				lanesArray.push(dataStore.data[i].lanebarcode);
			}
		}
		else if ( dataStore.data[i].samplebarcode == selectedSample ) {
			//console.log("Filter.getSampleLanes    MATCH AT dataStore.data[" + i + "]:");
			//console.dir({data_i:dataStore.data[i]});
			lanesArray.push(dataStore.data[i].lanebarcode);
		}
	}

	// GET UNIQUE LANES
	lanesArray = this.unique(lanesArray);	

	// ADD 'All ...' ENTRY
	lanesArray.unshift("All (" + lanesArray.length + " Lane" + (lanesArray.length != 1 ? "s" : "") + ")");

	console.log("Filter.getSampleLanes    AFTER lanesArray: ");
	console.dir({lanesArray:lanesArray});

	return lanesArray;
},
getSampleFlowcells : function (dataStore, selectedProject, selectedSample) {
	//console.log("Filter.getSampleFlowcells    selectedProject: " + selectedProject);
	//console.log("Filter.getSampleFlowcells    selectedSample: " + selectedSample);
	//console.log("Filter.getSampleFlowcells    BEFORE dataStore.data: ");
	//console.dir({dataStore_data:dataStore.data});
	
	var flowcellsArray = [];
	for ( var i = 0; i < dataStore.data.length; i++ ) {

		// FILTER BY PROJECT IF SELECTED SAMPLE IS 'All ...'
		if ( selectedSample.match(/^All \(/) ) {
			
			if ( selectedProject ) {
				// PUSH ALL IF SELECTED PROJECT IS 'All ...'
				if ( selectedProject.match(/^All \(/) ) {
					flowcellsArray.push(dataStore.data[i].flowcellbarcode);
				}
				else if ( dataStore.data[i].projectname == selectedProject ) {
					//console.log("Filter.getSampleFlowcells    MATCHED selectedProject: " + selectedProject);
					//console.log("Filter.getSampleFlowcells    dataStore.data[" + i + "]: ");
					//console.dir({dataStore_data_i:dataStore.data[i]});
					if ( dataStore.data[i].flowcellbarcode ) {
						flowcellsArray.push(dataStore.data[i].flowcellbarcode);
					}
				}
			}
			else {
				if ( dataStore.data[i].flowcellbarcode ) {
					flowcellsArray.push(dataStore.data[i].flowcellbarcode);
				}
			}
		}
		else if ( dataStore.data[i].samplebarcode == selectedSample ) {
			//console.log("Filter.getSampleFlowcells    MATCH AT dataStore.data[" + i + "]:");
			//console.dir({data_i:dataStore.data[i]});
			if ( dataStore.data[i].flowcellbarcode ) {
				flowcellsArray.push(dataStore.data[i].flowcellbarcode);
			}
		}
	}
	
	// GET UNIQUE LANES
	//console.log("Filter.getSampleFlowcells    BEFORE unique, flowcellsArray: ");
	//console.dir({flowcellsArray:flowcellsArray});

	flowcellsArray = this.unique(flowcellsArray);	

	// ADD 'All ...' ENTRY
	flowcellsArray.unshift("All (" + flowcellsArray.length + " Flowcell" + (flowcellsArray.length != 1 ? "s" : "") + ")");

	//console.log("Filter.getSampleFlowcells    AFTER unique, flowcellsArray: ");
	//console.dir({flowcellsArray:flowcellsArray});

	return flowcellsArray;
},
setFlowcellClick : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {	
	//console.log("Filter.setFlowcellClick    window.projects: ");
	//console.dir({window_projects:window.projects});
	
	var thisObject = this;

	this.flowcellList.on("dgrid-select", function(event) {
		//console.log("Filter.setFlowcellClick    event: ");
		//console.dir({event:event});
		//console.log("Filter.setFlowcellClick    thisObject.projects: ");
		//console.dir({thisObject_projects:thisObject.projects});

		// CLEAR LANE FILTER
		domAttr.set(thisObject.laneFilter, 'value', "");
		domAttr.set(window.laneFilter, 'value', "");

		// GET SELECTED SAMPLE AND SELECT PROJECT (IF AVAILABLE)
		var selectedProject = thisObject.projectList.getSelected();
		var selectedSample = thisObject.sampleList.getSelected();
		var selectedFlowcell = event.rows[0].data;
		//console.log("Filter.setFlowcellClick    selectedProject: " + selectedProject);
		//console.log("Filter.setFlowcellClick    selectedSample: " + selectedSample);
		//console.log("Filter.setFlowcellClick    selectedFlowcell: " + selectedFlowcell);

		// CLEAR LANE FILTER
		domAttr.set(window.laneFilter, 'value', "");

		var projectFilter 	= thisObject.projectFilter.value;
		var sampleFilter 	= thisObject.sampleFilter.value;
		var flowcellFilter 	= thisObject.flowcellFilter.value;

		// IF FLOWCELL FILTER HAS VALUE AND USER CLICKED 'All ...' ENTRY IN FLOWCELL LIST,
		// REDO FLOWCELL FILTER TO REFRESH LANE LIST WITH ALL ENTRIES MATCHING FLOWCELL FILTER.
		// OTHERWISE, IF SAMPLE FILTER HAS VALUE DO runFlowcellFilter
		// LIKEWISE, IF PROJECT FILTER HAS VALUE DO runFlowcellFilter
		if ( (flowcellFilter != "" && selectedFlowcell.match(/All \(/))
			|| sampleFilter != ""
			|| projectFilter != "" ) {
			thisObject.runFlowcellFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilter, sampleFilter, flowcellFilter);
			return;
		}

		var lanesArray = thisObject.getFlowcellLanes(dataStore, selectedProject, selectedSample, selectedFlowcell);

		thisObject.laneList.refresh(); //	clear contents
		thisObject.laneList.renderArray(lanesArray);
		//thisObject.laneList.select(0); //	reselect "all" item, triggering grid refresh

		// UPDATE BOTTOM PANE
		if ( ! selectedFlowcell.match(/^All \(/) ) {
			thisObject.showDetails("flowcell", selectedFlowcell);
		}
	});
},
getFlowcellLanes : function (dataStore, selectedProject, selectedSample, selectedFlowcell) {
	console.log("Filter.getFlowcellLanes    selectedFlowcell: " + selectedFlowcell);

	var lanesArray = [];
	for ( var i = 0; i < dataStore.data.length; i++ ) {

		// FILTER BY PROJECT AND SAMPLE IF SELECTED FLOWCELL IS 'All ...'
		if ( selectedFlowcell.match(/^All \(/) ) {
			
			if ( ! selectedSample || selectedSample.match(/^All \(/) ) {
				
				// PUSH ALL IF SELECTED PROJECT IS 'All ...'
				if ( ! selectedProject || selectedProject.match(/^All \(/) ) {
					lanesArray.push(dataStore.data[i].lanebarcode);
				}
				else if ( dataStore.data[i].projectname == selectedProject ) {
					//console.log("Filter.getFlowcellLanes    MATCHED selectedProject: " + selectedProject);
					//console.log("Filter.getFlowcellLanes    dataStore.data[" + i + "]: ");
					//console.dir({dataStore_data_i:dataStore.data[i]});

					if ( dataStore.data[i].lanebarcode ) {
						lanesArray.push(dataStore.data[i].lanebarcode);
					}
				}
			}
			else if ( dataStore.data[i].samplebarcode == selectedSample ) {

				// PUSH ALL IF SELECTED PROJECT IS 'All ...'
				if ( ! selectedProject || selectedProject.match(/^All \(/) ) {
					if ( dataStore.data[i].lanebarcode ) {
						lanesArray.push(dataStore.data[i].lanebarcode);
					}
				}
				else if ( dataStore.data[i].projectname == selectedProject ) {
					//console.log("Filter.getSampleLanes    MATCHED selectedProject: " + selectedProject);
					//console.log("Filter.getSampleLanes    dataStore.data[" + i + "]: ");
					//console.dir({dataStore_data_i:dataStore.data[i]});
					if ( dataStore.data[i].lanebarcode ) {
						lanesArray.push(dataStore.data[i].lanebarcode);
					}
				}
			}
		}
		// OTHERWISE, FILTER BY PROJECT IF SELECTED SAMPLE IS 'All ...'
		else if ( dataStore.data[i].flowcellbarcode == selectedFlowcell ) {
			if ( ! selectedSample || selectedSample.match(/^All \(/) ) {
	
				// PUSH ALL IF SELECTED PROJECT IS 'All ...'
				if ( ! selectedProject || selectedProject.match(/^All \(/) ) {
					if ( dataStore.data[i].lanebarcode ) {
						lanesArray.push(dataStore.data[i].lanebarcode);
					}
				}
				else if ( dataStore.data[i].projectname == selectedProject ) {
					//console.log("Filter.getSampleLanes    MATCHED selectedProject: " + selectedProject);
					//console.log("Filter.getSampleLanes    dataStore.data[" + i + "]: ");
					//console.dir({dataStore_data_i:dataStore.data[i]});
					if ( dataStore.data[i].lanebarcode ) {
						lanesArray.push(dataStore.data[i].lanebarcode);
					}
				}
			}
			else if ( dataStore.data[i].samplebarcode == selectedSample ) {
				// PUSH ALL IF SELECTED PROJECT IS 'All ...'
				if ( ! selectedProject || selectedProject.match(/^All \(/) ) {
					if ( dataStore.data[i].lanebarcode ) {
						lanesArray.push(dataStore.data[i].lanebarcode);
					}
				}
				else if ( dataStore.data[i].projectname == selectedProject ) {
					//console.log("Filter.getSampleLanes    MATCHED selectedProject: " + selectedProject);
					//console.log("Filter.getSampleLanes    dataStore.data[" + i + "]: ");
					//console.dir({dataStore_data_i:dataStore.data[i]});
					if ( dataStore.data[i].lanebarcode ) {
						lanesArray.push(dataStore.data[i].lanebarcode);
					}
				}
			}
		}
	}
	
	// GET UNIQUE LANES
	lanesArray = this.unique(lanesArray);	

	// ADD 'All ...' ENTRY
	lanesArray.unshift("All (" + lanesArray.length + " Lane" + (lanesArray.length != 1 ? "s" : "") + ")");

	console.log("Filter.getFlowcellLanes    AFTER lanesArray: ");
	console.dir({lanesArray:lanesArray});

	return lanesArray;
},
setLaneClick : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {	

	var thisObject = this;
	this.laneList.on("dgrid-select", function(e){
		
		console.log("DOING this.laneList.on");

		//	filter the grid
		var row = e.rows[0];
		console.log("Filter.setLaneClick    e.rows: ");
		console.dir({e_rows:e.rows});
		
		var selectedLane = row.data;
		console.log("Filter.setLaneClick    selectedLane: " + selectedLane);
		console.log("Filter.setLaneClick    row.id: " + row.id);
		if(row.id == "0"){
			console.log("Filter.setLaneClick    DOING delete grid.query.lanebarcode");
			// show all lanes


//			delete grid.query.lanebarcode;


		} else {


//			grid.query.lanebarcode = selectedLane;


		}

		//console.log("Filter.setLaneClick    AFTER grid.query = ...,  grid: " + grid);
		//console.dir({grid:grid});
		
		//console.log("Filter.setLaneClick    DOING grid.refresh");


//		grid.refresh();

		// UPDATE BOTTOM PANE
		if ( ! selectedLane.match(/^All \(/) ) {
			thisObject.showDetails("lane", selectedLane);
		}

		console.log("Filter.setLaneClick    AFTER grid.refresh");
	});

	//	set the initial selections on the lists.
	this.projectList.select(0);

	
},	//	end "main" function
// SET FILTER LISTENERS
setProjectFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	console.log("Filter.setProjectFilter   projectFilter:");
	console.dir({projectFilter:projectFilter});
	console.log("Filter.setProjectFilter    projectsArray.length: " + projectsArray.length);
	//console.dir({projectsArray:projectsArray});

	// SET TYPING INTERVAL
	var typingTimer;
	var doneTypingInterval = this.doneTypingInterval;
	console.log("Filter.setProjectFilter    doneTypingInterval: " + doneTypingInterval);

	var thisObject = this;
	//this.projectFilter.on("keyup", function(event){
	on(this.projectFilter, "keyup", function(event){
		console.log("Filter.setProjectFilter   KEYUP event: " + event);
		console.dir({event:event});
		event.stopPropagation();

		var projectFilterValue = projectFilter.value;
		console.log("Filter.setProjectFilter   KEYUP projectFilterValue: " + projectFilterValue);

		clearTimeout(typingTimer);
		
		// NB: RUN PROJECT FILTER EVEN IF PROJECT FILTER VALUE (KEYWORD) IS EMPTY
		// TO CLEAR LIST OF ANY EARLIER FILTER RESULTS
		if ( projectFilterValue == "" ) {
			console.log("Filter.setProjectFilter   EMPTY FILTER. DOING domClass.remove(..., 'dijitTextBoxFocused')");
			domClass.remove(thisObject.projectFilter.domNode, "dijitTextBoxFocused");
		}
		else {
			console.log("Filter.setProjectFilter   FILTER NOT EMPTY. DOING domClass.add(..., 'dijitTextBoxFocused')");
			domClass.add(thisObject.projectFilter.domNode, "dijitTextBoxFocused");
		}
		
        typingTimer = setTimeout(
			function() {
				thisObject.runProjectFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue);
			},
			doneTypingInterval
		);
    });

	console.log("Filter.setProjectFilter    AFTER this.projectFilter KEYUP");

},
runProjectFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue) {
	console.log("Filter.runProjectFilter    caller: " + this.runProjectFilter.caller.nom);
	console.log("Filter.runProjectFilter    projectFilterValue: " + projectFilterValue);
	console.log("Filter.runProjectFilter    projectsArray:");
	console.dir({projectsArray:projectsArray});

	// CLEAR DOWNSTREAM FILTERS IF FILTER VALUE
	if ( projectFilterValue ) {
		this.sampleFilter.set("value", "");
		this.sampleFilter.set("displayedValue", "");
		this.flowcellFilter.set("value", "");
		this.flowcellFilter.set("displayedValue", "");
		this.laneFilter.set("value", "");
		this.laneFilter.set("displayedValue", "");
	}

	// SET REGEX
	var projectRegex = new RegExp(projectFilterValue, "i")
	
	// FILTER PROJECTS
	var filteredProjectsArray = [];
	arrayUtil.forEach(projectsArray, function(projectName, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}
		
		if (projectName.match(projectRegex)) {
			filteredProjectsArray.push(projectName);
		}
	});
	
	// RUN SELECT FILTER IF SELECTED
	var statusValue = this.projectSelect.value;
	if ( statusValue != "" ) {
		console.log("Filter.runProjectFilter    DOING filterByStatus    status: " + this.projectSelect.value);
		
		filteredProjectsArray = this.filterByStatus("project", "project_name", filteredProjectsArray, statusValue);
	}
	
	this.displayProjects(dataStore, filteredProjectsArray, samplesArray, flowcellsArray, lanesArray, projectRegex);

},

displayProjects : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectRegex) {
	projectsArray.unshift("All (" + projectsArray.length + " Project" + (projectsArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.displayProjects   projectsArray.length: " + projectsArray.length);
	//console.dir({projectsArray:projectsArray});

	// UPDATE PROJECTS LIST
	this.projectList.refresh(); //	clear contents
	this.projectList.renderArray(projectsArray);
	//this.projectList.select(0); //	reselect "all" item, triggering grid refresh

	// FILTER SAMPLES
	var samplesData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( item.projectname.match(projectRegex) ) {
			samplesData.push(item);
		}
	});	

	var filteredSamplesArray = this.unique(
		arrayUtil.map(
			samplesData,
			function(item){
				return item.samplebarcode;
			}
		)
	);

	filteredSamplesArray.unshift("All (" + filteredSamplesArray.length + " Sample" + (filteredSamplesArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.displayProjects   filteredSamplesArray:");
	console.dir({filteredSamplesArray:filteredSamplesArray});
	
	// UPDATE SAMPLES LIST
	this.sampleList.refresh(); //	clear contents
	this.sampleList.renderArray(filteredSamplesArray);
	
	// FILTER LANES
	var lanesData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( item.projectname.match(projectRegex)) {
			lanesData.push(item);
		}
	});
	
	var filteredLanesArray = this.unique(
		arrayUtil.map(
			lanesData,
			function(item){
				return item.lanebarcode;
			}
		)
	);
	filteredLanesArray.unshift("All (" + filteredLanesArray.length + " Lane" + (filteredLanesArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.displayProjects   filteredLanesArray:");
	console.dir({filteredLanesArray:filteredLanesArray});
	
	// UPDATE LANES LIST
	this.laneList.refresh(); //	clear contents
	this.laneList.renderArray(filteredLanesArray);
},
setSampleFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {

	// SET TYPING INTERVAL
	var typingTimer;
	var doneTypingInterval = this.doneTypingInterval;

	var thisObject = this;
	on(this.sampleFilter, "keyup", function(event){
		event.stopPropagation();

		var projectFilterValue 	= 	thisObject.projectFilter.value;
		var sampleFilterValue 	=	thisObject.sampleFilter.value;

		console.log("Filter.setSampleFilter    projectFilterValue: " + projectFilterValue);
		console.log("Filter.setSampleFilter    sampleFilterValue: " + sampleFilterValue);
		console.log("Filter.setSampleFilter    thisObject.sampleFilter:");
		console.dir({thisObject_sampleFilter:thisObject.sampleFilter});

		console.log("Filter.setSampleFilter    thisObject.projects:");
		console.dir({thisObject_projects:thisObject.projects});

		var selectedProject = thisObject.projectList.getSelected();
		console.log("Filter.setSampleFilter    selectedProject: " + selectedProject);
		if ( selectedProject ) {
			projectFilterValue = selectedProject;
		}
		
		clearTimeout(typingTimer);

		// RUN PROJECT FILTER IF SAMPLE FILTER VALUE (KEYWORD) IS EMPTY
		// TO CLEAR LIST OF ANY EARLIER FILTER RESULTS
		//if ( sampleFilterValue == "" ) {
		//	console.log("Filter.setSampleFilter   EMPTY FILTER. DOING runProjectFilter");
		//	thisObject.runProjectFilter(dataStore, projectsArray, samplesArray, lanesArray, projectFilterValue);
		//	return;
		//}
		
        typingTimer = setTimeout(
			function() {
				thisObject.runSampleFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue, sampleFilterValue);
			},
			doneTypingInterval
		);
    });
},
runSampleFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue, sampleFilterValue) {
	console.log("Filter.runSampleFilter    projectFilterValue: " + projectFilterValue);
	console.log("Filter.runSampleFilter    sampleFilterValue: " + sampleFilterValue);
	//console.log("Filter.runSampleFilter    projectsArray:");
	//console.dir({projectsArray:projectsArray});

	// CLEAR DOWNSTREAM FILTERS IF FILTER VALUE
	if ( sampleFilterValue ) {
		this.flowcellFilter.set("value", "");
		this.flowcellFilter.set("displayedValue", "");
		this.laneFilter.set("value", "");
		this.laneFilter.set("displayedValue", "");
	}

	// SET REGEXES
	var projectRegex = new RegExp(projectFilterValue, "i")
	var sampleRegex = new RegExp(sampleFilterValue, "i")

	// FILTER SAMPLES
	var samplesData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( item.samplebarcode.match(sampleRegex) ) {
			if ( projectFilterValue ) {
				if ( item.projectname.match(projectRegex)) {
					samplesData.push(item);
				}
			}
			else {
				samplesData.push(item);
			}
		}
	});

	var filteredSamplesArray = this.getUniqueArray(samplesData,"samplebarcode");
	filteredSamplesArray.unshift("All (" + filteredSamplesArray.length + " Sample" + (filteredSamplesArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.setSampleFilter   filteredSamplesArray:");
	console.dir({filteredSamplesArray:filteredSamplesArray});
	
	// UPDATE SAMPLES LIST
	this.sampleList.refresh(); //	clear contents
	this.sampleList.renderArray(filteredSamplesArray);
	//sampleList.select(1); //	reselect "all" item, triggering grid refresh	


	// FILTER FLOWCELLS
	var flowcellsData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( i == 1 ) {	
			console.log("Filter.setProjectFilter   item :");
			console.dir({item :item });
		}
		
		if ( item.samplebarcode.match(sampleRegex) ) {
			if ( projectFilterValue ) {
				if ( item.projectname.match(projectRegex)) {
					flowcellsData.push(item);
				}
			}
			else {
				flowcellsData.push(item);
			}
		}
	});
	
	var filteredFlowcellsArray = this.getUniqueArray(flowcellsData, "flowcellbarcode");
	filteredFlowcellsArray.unshift("All (" + filteredFlowcellsArray.length + " Flowcell" + (filteredFlowcellsArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.setProjectFilter   filteredFlowcellsArray:");
	console.dir({filteredFlowcellsArray:filteredFlowcellsArray});
	
	// UPDATE FLOWCELLS LIST
	this.flowcellList.refresh(); //	clear contents
	this.flowcellList.renderArray(filteredFlowcellsArray);

	// FILTER LANES
	var lanesData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( i == 1 ) {	
			console.log("Filter.setProjectFilter   item :");
			console.dir({item :item });
		}
		
		if ( item.samplebarcode.match(sampleRegex) ) {
			if ( projectFilterValue ) {
				if ( item.projectname.match(projectRegex)) {
					lanesData.push(item);
				}
			}
			else {
				lanesData.push(item);
			}
		}
	});
	
	var filteredLanesArray = this.unique(
		arrayUtil.map(
			lanesData,
			function(item){
				return item.lanebarcode;
			}
		)
	);
	filteredLanesArray.unshift("All (" + filteredLanesArray.length + " Lane" + (filteredLanesArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.setProjectFilter   filteredLanesArray:");
	console.dir({filteredLanesArray:filteredLanesArray});
	
	// UPDATE LANES LIST
	this.laneList.refresh(); //	clear contents
	this.laneList.renderArray(filteredLanesArray);
},
setFlowcellFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	// SET TYPING INTERVAL
	var typingTimer;
	var doneTypingInterval = this.doneTypingInterval;

	var thisObject = this;
	on(this.flowcellFilter, "keyup", function(event){
		event.stopPropagation();

		clearTimeout(typingTimer);

		// RUN LANE FILTER EVEN IF LANE FILTER VALUE (KEYWORD) IS EMPTY
		// TO CLEAR LIST OF ANY EARLIER FILTER RESULTS.
		// PAUSE SLIGHTLY TO ENSURE THE NEW INPUT IS AVAILABLE AS THE value
		// ATTRIBUTE OF THE FILTER
        typingTimer = setTimeout(
			function() {
				setTimeout(function() {
					console.log("Filter.setFlowcellFilter    KEYUP FIRED");

					thisObject.handleFlowcellFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
				},
				50);
			},
			doneTypingInterval
		);
    });
},
handleFlowcellFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	console.log("Filter.handleFlowcellFilter    ");
	var projectFilterValue 	= 	this.projectFilter.value;
	var sampleFilterValue 	=	this.sampleFilter.value;
	var flowcellFilterValue =	this.flowcellFilter.value;

	console.log("Filter.handleFlowcellFilter    projectFilterValue: " + projectFilterValue);
	console.log("Filter.handleFlowcellFilter    sampleFilterValue: " + sampleFilterValue);
	console.log("Filter.handleFlowcellFilter    flowcellFilterValue: " + flowcellFilterValue);
	
	this.runFlowcellFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue, sampleFilterValue, flowcellFilterValue);
},
runFlowcellFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue, sampleFilterValue, flowcellFilterValue) {
	console.log("Filter.runFlowcellFilter    projectFilterValue: " + projectFilterValue);
	console.log("Filter.runFlowcellFilter    sampleFilterValue: " + sampleFilterValue);
	console.log("Filter.runFlowcellFilter    flowcellFilterValue: " + flowcellFilterValue);
	
	//projectFilterValue = this.projectList.getSelected() || projectFilterValue;
	//sampleFilterValue = this.sampleList.getSelected() || sampleFilterValue;
	//flowcellFilterValue = this.flowcellList.getSelected() || flowcellFilterValue;
	//console.log("Filter.runFlowcellFilter    FINAL projectFilterValue: " + projectFilterValue);
	//console.log("Filter.runFlowcellFilter    FINAL sampleFilterValue: " + sampleFilterValue);
	//console.log("Filter.runFlowcellFilter    FINAL flowcellFilterValue: " + flowcellFilterValue);
	
	// CLEAR DOWNSTREAM FILTERS IF FILTER VALUE
	if ( flowcellFilterValue ) {
		this.laneFilter.set("value", "");
		this.laneFilter.set("displayedValue", "");
		//console.log("Filter.runFlowcellFilter    AFTER CLEARED DOWNSTREAM this.laneFilter: " + this.laneFilter);
		//console.dir({this_laneFilter:this.laneFilter});
	}

	// SET REGEXES
	var projectRegex = new RegExp(projectFilterValue, "i")
	var sampleRegex = new RegExp(sampleFilterValue, "i")
	var flowcellRegex = new RegExp(flowcellFilterValue, "i")

	// FILTER SAMPLES
	var flowcellsData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( ! item.flowcellbarcode ) {
			//console.log("Filter.runFlowcellFilter    item: ");
			//console.dir({item:item});
			return;
		}

		if ( item.flowcellbarcode.match(flowcellRegex) ) {
			if ( sampleFilterValue ) {
				if ( item.samplebarcode.match(sampleRegex) ) {
					if ( projectFilterValue ) {
						if ( item.projectname.match(projectRegex) ) {
							flowcellsData.push(item);
						}
					}
					else {
						flowcellsData.push(item);
					}
				}
			}
			else if ( projectFilterValue ) {
				if ( item.projectname.match(projectRegex) ) {
					flowcellsData.push(item);
				}
			}
			else {
				flowcellsData.push(item);
			}

		}	
	});

	if ( this.projectList.getSelected() ) {
		
	}
	
	var filteredFlowcellsArray = this.getUniqueArray(flowcellsData,"flowcellbarcode");
	filteredFlowcellsArray.unshift("All (" + filteredFlowcellsArray.length + " Sample" + (filteredFlowcellsArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.runFlowcellFilter   filteredFlowcellsArray:");
	console.dir({filteredFlowcellsArray:filteredFlowcellsArray});
	
	
	// HANDLE SELECTED STATUS
	
	
	
	// UPDATE FLOWCELLS LIST
	this.flowcellList.refresh();
	this.flowcellList.renderArray(filteredFlowcellsArray);
	
	// FILTER LANES
	var lanesData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( ! item.flowcellbarcode ) {
			//console.log("Filter.runFlowcellFilter    item: ");
			//console.dir({item:item});
			return;
		}

		if ( item.flowcellbarcode.match(flowcellRegex) ) {
			if ( sampleFilterValue ) {
				if ( item.samplebarcode.match(sampleRegex) ) {
					if ( projectFilterValue ) {
						if ( item.projectname.match(projectRegex) ) {
							lanesData.push(item);
						}
					}
					else {
						lanesData.push(item);
					}
				}
			}
			else if ( projectFilterValue ) {
				if ( item.projectname.match(projectRegex) ) {
					lanesData.push(item);
				}
			}
			else {
				lanesData.push(item);
			}
		}
	});
	
	var filteredLanesArray = this.getUniqueArray(lanesData, "lanebarcode");
	filteredLanesArray.unshift("All (" + filteredLanesArray.length + " Lane" + (filteredLanesArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.runFlowcellFilter   filteredLanesArray:");
	console.dir({filteredLanesArray:filteredLanesArray});
	
	// UPDATE LANES LIST
	this.laneList.refresh(); //	clear contents
	this.laneList.renderArray(filteredLanesArray);
},
setLaneFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	// SET TYPING INTERVAL
	var typingTimer;
	var doneTypingInterval = this.doneTypingInterval;

	var thisObject = this;
	on(this.laneFilter, "keyup", function(event){
		event.stopPropagation();

		clearTimeout(typingTimer);

		// RUN LANE FILTER EVEN IF LANE FILTER VALUE (KEYWORD) IS EMPTY
		// TO CLEAR LIST OF ANY EARLIER FILTER RESULTS.
		// PAUSE SLIGHTLY TO ENSURE THE NEW INPUT IS AVAILABLE AS THE value
		// ATTRIBUTE OF THE FILTER
        typingTimer = setTimeout(
			function() {
				setTimeout(function() {
					console.log("Filter.setLaneFilter    KEYUP FIRED");
					thisObject.handleLaneFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
				},
				50);
			},
			doneTypingInterval
		);
    });
},
handleLaneFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	console.log("Filter.handleFlowcellFilter    ");
	var projectFilterValue 	= 	this.projectFilter.value;
	var sampleFilterValue 	=	this.sampleFilter.value;
	var flowcellFilterValue =	this.flowcellFilter.value;
	var laneFilterValue 	=	this.laneFilter.value;

	console.log("Filter.handleFlowcellFilter    projectFilterValue: " + projectFilterValue);
	console.log("Filter.handleFlowcellFilter    sampleFilterValue: " + sampleFilterValue);
	console.log("Filter.handleFlowcellFilter    flowcellFilterValue: " + flowcellFilterValue);
	console.log("Filter.handleFlowcellFilter    laneFilterValue: " + laneFilterValue);

	console.log("Filter.handleFlowcellFilter    this.laneFilter: " + this.laneFilter);
	console.dir({this_laneFilter:this.laneFilter});

	this.runLaneFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue, sampleFilterValue, flowcellFilterValue, laneFilterValue);
},
runLaneFilter : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray, projectFilterValue, sampleFilterValue, flowcellFilterValue, laneFilterValue) {

	console.log("Filter.runLaneFilter    projectFilterValue: " + projectFilterValue);
	console.log("Filter.runLaneFilter    sampleFilterValue: " + sampleFilterValue);
	console.log("Filter.runLaneFilter    flowcellFilterValue: " + flowcellFilterValue);
	console.log("Filter.runLaneFilter    laneFilterValue: " + laneFilterValue);
	
	// SET REGEXES
	var projectRegex = new RegExp(projectFilterValue, "i")
	var sampleRegex = new RegExp(sampleFilterValue, "i")
	var flowcellRegex = new RegExp(flowcellFilterValue, "i")
	var laneRegex = new RegExp(laneFilterValue, "i")

	// FILTER SAMPLES
	var lanesData = [];
	arrayUtil.forEach(dataStore.data, function(item, i) {
		// SKIP 'All ...' LABEL
		if ( i == 0 ) {	return;	}

		if ( ! item.lanebarcode ) {
			return;
		}
		
		// LATER: REFACTOR INTO RECURSIVE FUNCTION
		if ( item.lanebarcode.match(laneRegex) ) {
			if ( flowcellFilterValue ) {				
				if ( item.flowcellbarcode.match(flowcellRegex) ) {
					if ( sampleFilterValue ) {
						if ( item.samplebarcode.match(sampleRegex) ) {
							if ( projectFilterValue ) {
								if ( item.projectname.match(projectRegex)) {
									lanesData.push(item);
								}
							}
							else {
								lanesData.push(item);
							}
						}
					}
					else if ( projectFilterValue ) {
						if ( item.projectname.match(projectRegex) ) {
							lanesData.push(item);
						}
					}
					else {
						lanesData.push(item);
					}
				}
			}
			else {
				if ( sampleFilterValue ) {
					if ( item.samplebarcode.match(sampleRegex) ) {
						if ( projectFilterValue ) {
							if ( item.projectname.match(projectRegex)) {
								lanesData.push(item);
							}
						}
						else {
							lanesData.push(item);
						}
					}
				}
				else if ( projectFilterValue ) {
					if ( item.projectname.match(projectRegex) ) {
						lanesData.push(item);
					}
				}
				else {
					lanesData.push(item);
				}
			}
		}	
	});

	var filteredLanesArray = this.unique(
		arrayUtil.map(
			lanesData,
			function(item){
				return item.lanebarcode;
			}
		)
	);

	filteredLanesArray.unshift("All (" + filteredLanesArray.length + " Sample" + (filteredLanesArray.length != 1 ? "s" : "") + ")");
	console.log("Filter.setLaneFilter   filteredLanesArray:");
	console.dir({filteredLanesArray:filteredLanesArray});
	
	// UPDATE SAMPLES LIST
	this.laneList.refresh();
	this.laneList.renderArray(filteredLanesArray);
},
// UTILS
cowCase : function (string) {
	return string.substring(0,1) + string.substring(1);
},
unique : function (arr){
	//	create a unique list of items from the passed array
	//	(removing duplicates).  This is quick and dirty.

	//	first, set up a hashtable for unique objects.
	var obj = {};
	for(var i=0,l=arr.length; i<l; i++){
		if(!(arr[i] in obj)){
			obj[arr[i]] = true;
		}
	}

	//	now push the unique objects back into an array, and return it.
	var ret = [];
	for(var p in obj){
		ret.push(p);
	}
	ret.sort();
	
	//console.log("unique    returning ret:" + JSON.stringify(ret));
	//console.dir({ret:ret});
	return ret;
},
getUniqueArray : function (dataArray, field) {
	return this.unique(
		arrayUtil.map(
			dataArray,
			function(item){
				return item[field];
			}
		)
	);	
},
destroyRecursive : function () {
	console.log("Filter.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}

}); 	//	end declare

});	//	end define

/* SUMMARY: 

LAYOUT

1. TWO PANES, ONE ON TOP OF THE OTHER WITH A DRAGGABLE SPLITTER FOR SIZE ADJUSTMENT

2. TOP PANE: THREE PANES (LEFT, MIDDLE, RIGHT) WITH LISTS (PROJECT, SAMPLE, FLOWCELL):

    -   CASCADING LISTS (dGrid)
    
        -   PROJECT SELECTS SAMPLE
        
        -   SAMPLE SELECTS FLOWCELL
    
    -   TWO FILTER OPTIONS ABOVE EACH LIST BOX REFINE THE LIST
    
        -   KEYWORD FILTERS
    
        -   COMBOBOX CATEGORIES

    -   PROJECT LIST PROPERTIES:
        
        -   CLICK ON PROJECT--> DISPLAY PROJECT INFORMATION IN BOTTOM PANE
        
                            --> SAMPLE LIST IS FILTERED BY PROJECT
        
                            --> FLOWCELL LIST IS FILTERED BY PROJECT AND FIRST SAMPLE
        
        -   CONTEXT MENU: 'MARK PROJECT AS COMPLETED', ETC. (DEPENDS ON USER'S PRIVILEGES)

    -   SAMPLE LIST PROPERTIES:
        
        -   CLICK ON SAMPLE --> DISPLAY SAMPLE INFORMATION IN BOTTOM PANE
        
                            --> FLOWCELL LIST IS FILTERED BY PROJECT AND FIRST SAMPLE
                            
        -   CONTEXT MENU: 'MARK SAMPLE AS COMPLETED', 'REQUEST MORE LANES'
                                                            (DEPENDS ON USER'S PRIVILEGES)

    -   SAMPLE LIST PROPERTIES:
        
        -   CLICK ON SAMPLE --> FLOWCELL LIST IS FILTERED BY PROJECT AND FIRST SAMPLE
        
        -   CONTEXT MENU: 'MARK SAMPLE AS COMPLETED', 'REQUEST MORE LANES'
                                                            (DEPENDS ON USER'S PRIVILEGES)

2. BOTTOM PANE: A SINGLE PANE (dGrid)

    -   DISPLAYS THREE DIFFERENT KINDS OF RESULTS

        -   PROJECT INFO
        
        -   SAMPLE INFO
        
        -   FLOWCELL INFO


REQUIREMENTS

1. USER CAN EASILY SEARCH THROUGH LIST OF PROJECT NAMES TO FIND A PARTICULAR PROJECT

    http://ussd-prd-lnwb01.illumina.com/saffronDB/cgi-bin/project.cgi?project=Genentech&rm=search

    -   FILTER BY KEYWORD
    
    -   FILTER BY CATEGORY (Status: Active, Hold, Complete)

2. USER WILL SEE THE FOLLOWING INFORMATION ABOUT THE PROJECT
    
    http://ussd-prd-lnwb01.illumina.com/saffronDB/cgi-bin/project.cgi?rm=details&nolayout=1&project_id=122
    
    -   PROJECT STATISTICS - # OF SAMPLES, ETC. (sample_history TABLE SUMMARY FOR PROJECT?)
    
    -   LIST OF SAMPLES IN THE PROJECT WHICH LINK TO LIST OF FLOWCELLS

    -   LIST OF SAMPLE BUILD INFORMATION (NB: DECOMPOSE VIEW INSTEAD OF GENERATING IN DATABASE)
    
    
3. USER CAN EASILY SEARCH THROUGH LIST OF SAMPLES TO FIND A PARTICULAR SAMPLE

    -   FILTER BY KEYWORD
    
    -   FILTER BY CATEGORY
 
    <EXAMPLE>       
        LINKS
        Undelivered Samples NOT QC'ed
        Undelivered Samples Pass QC
        Samples missing yield
        Samples missing GT information
        
        COMBOBOX
        active
        delivered
        pending_archive
        qc_pass
        qc_fail
        cancelled
        hold
        loading_to_hd
        loaded_to_hd
        pm_hold
    </EXAMPLE>


4. USER WILL SEE THE FOLLOWING INFORMATION ABOUT THE SAMPLE

    -   PROJECT, SAMPLE ID, STATUS, ETC. ??CURRENT ESTIMATED YIELD IN Gb?? (sample_overview_3 TABLES)

    -   LIST OF FLOWCELLS IN THE SAMPLE WHICH LINK TO FLOWCELL INFORMATION


    CURRENT FILTER BY KEYWORD
    http://ussd-prd-lnwb01.illumina.com/saffronDB/cgi-bin/sample.cgi?sample_barcode=LP6002121-DNA_A01&rm=search

    CURRENT FILTER BY COMBOBOX OR LINK CATEGORY
        COMBOBOX
        http://ussd-prd-lnwb01.illumina.com/saffronDB/cgi-bin/sample.cgi?sample_status=delivered&rm=search
        
        LINK
        http://ussd-prd-lnwb01.illumina.com/saffronDB/cgi-bin/sample.cgi?rm=search&undelivered=1


    
5. USER CAN EASILY SEARCH THROUGH LIST OF FLOWCELLS TO FIND A PARTICULAR FLOWCELL

    -   FILTER BY KEYWORD
    
    -   FILTER BY CATEGORY (Status: Active, Finished, Failed, To_Rehyb)

    
6. USER WILL SEE THE FOLLOWING INFORMATION ABOUT THE FLOWCELL

    http://ussd-prd-lnwb01.illumina.com/saffronDB/cgi-bin/flowcell.cgi?fc_name=120707_SN1231_0102_BD18MWACXX_CRUK_JHUB_8&rm=search

    -   PROJECT ID, SAMPLE ID, FLOWCELL ID, STATUS, MACHINE, POSITION (flowcell, flowcell_samplesheet TABLES)


7. USER CAN CLICK ON A PROJECT AND SELECT FROM A LIST OF ACTIONS (DEPENDING ON USER'S PRIVILEGES)    
 
   
8. USER CAN CLICK ON SAMPLE AND SELECT FROM A LIST OF ACTIONS (DEPENDING ON USER'S PRIVILEGES)
    
    - FAIL SAMPLE (mixed up samples, mismatch with genotype, no yield)
    
    - CANCEL SAMPLE
    
    - MARK SAMPLE AS COMPLETED (E.G., YIELD = 110Gb)
    
    - REQUEUE ALL LANES
    
    - ADDITIONAL QC (?)
    
    - ADDITIONAL ANALYSIS    

9. USER CAN CLICK ON FLOWCELL AND SELECT FROM A LIST OF ACTIONS (DEPENDING ON USER'S PRIVILEGES)

    - FAIL LANE (mixed up samples, mismatch with genotype, no yield)
    
    - CANCEL LANE
    
    - MARK LANE AS COMPLETED
    
    - REQUEUE LANE
    
    - ADDITIONAL QC (?)
    
    - ADDITIONAL ANALYSIS

*/
