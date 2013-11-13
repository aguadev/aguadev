define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/when",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/infusion/Data",
	"plugins/core/Common",
	"dojo/ready",
	"dojo/domReady!",
	
	"dijit/TitlePane",
	"dijit/form/TextBox",
	"dijit/form/Button",
	"dijit/_Widget",
	"dijit/_Templated",
	"dijit/layout/AccordionContainer",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojox/layout/ContentPane",
	"dijit/Tree"
],

function (declare, arrayUtil, JSON, on, when, lang, domAttr, domClass, Data, Common, ready) {

////}}}}}

return declare("plugins.infusion.Search",[dijit._Widget, dijit._Templated, Data], {

// Path to the template of this widget. 
// templatePath : String
templatePath : require.toUrl("plugins/infusion/templates/search.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// parentWidget : Object
// PARENT WIDGET TO WHICH THIS BELONGS
parentWidget : null,

// core: Hash
// 		Holder for major components, e.g., core.data, core.dataStore
core : null,

// dataStore : Store of class Observable(Memory)
//		Watches changes in the data and reacts accordingly
dataStore : null,

// cssFiles : Array
// CSS FILES
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/css/infusion.css"),
	require.toUrl("dojox/layout/resources/ExpandoPane.css"),
	require.toUrl("plugins/infusion/images/elusive/css/elusive-webfont.css")
],

// <type>ListId : String
//		ID for SelectList object displaying <type> data
//		where type: project, sample, flowcell, lane
projectListId : dijit.getUniqueId("plugins.infusion.SelectList"),
sampleListId : dijit.getUniqueId("plugins.infusion.SelectList"),
flowcellListId : dijit.getUniqueId("plugins.infusion.SelectList"),
laneListId : dijit.getUniqueId("plugins.infusion.SelectList"),

// callback : Function reference
// Call this after module has loaded
callback : null,

// url: String
// URL FOR REMOTE DATABASE
url: null,

// doneTypingInterval : Integer
// Run 'setTimeout' when this timing interval ends
doneTypingInterval : 1000,

// refreshing : Boolean
//		Set to true if still loading data, false when load is completed
refreshing : false,

// attachPoint : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

//////}}
constructor : function(args) {		
	console.log("Search.constructor    args:");
	console.dir({args:args});
	
	if ( ! args )	return;
	
    // MIXIN ARGS
    lang.mixin(this, args);

	// SET core.lists
	if ( ! this.core ) 	this.core = new Object;
	this.core.lists = this;

	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "agua.cgi";

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Search.postCreate    plugins.infusion.Infusion.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Search.startup    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
	
	if ( ! this.attachPoint ) {
		console.log("Search.startup    this.attachPoint is null. Returning");
		return;
	}
	
	if ( ! this.core ) {
		console.log("Search.startup    this.core is null. Returning");
		return;
	}

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// ADD THE PANE TO THE TAB CONTAINER
	this.attachPane();
	
	//// SET ADD PROJECT BUTTON
	//this.setButtons();
	//
	//// CREATE TOP GRIDS
	//this.startLists();
},
attachPane : function () {
	//console.log("Folders.startup    this.mainTab: " + this.mainTab);
	if ( this.attachPoint.addChild ) {
		console.log("oooooooooooooooooooooooooooooooooo Lists.attachPane    DOING this.attachPoint.addChild(this.mainTab)");
		this.attachPoint.addChild(this.mainTab);
		this.attachPoint.selectChild(this.mainTab);
	}
	if ( this.attachPoint.appendChild ) {
		console.log("oooooooooooooooooooooooooooooooooo Lists.attachPane    DOING this.appendWidget.addChild(this.mainTab)");
		this.attachPoint.appendChild(this.mainTab.domNode);
	}	
},
setButtons : function () {
	var thisObject = this;
	on(this.addProjectButton, 'click', function() {
		console.log("Search.setAddProjectButton    addProjectButton ONCLICK FIRED");
		thisObject.showUploadDialog();
	});

	var thisObject = this;
	on(this.editSampleButton, 'click', function() {
		console.log("Search.setButtons    editSampleButton click FIRED");
		thisObject.openSampleDialog();
	});
	var thisObject = this;
	on(this.editSampleButton, 'onmouseover', function() {
		console.log("Search.setButtons    editSampleButton onmouseover FIRED");
		thisObject.openSampleDialog();
	});
	on(this.editSampleButton, 'onmouseout', function() {
		console.log("Search.setButtons    editSampleButton onmouseout FIRED");
		thisObject.openSampleDialog();
	});
	on(this.editSampleButton, 'onmousedown', function() {
		console.log("Search.setButtons    editSampleButton onmousedown FIRED");
		thisObject.openSampleDialog();
	});
	on(this.editSampleButton, 'onmouseup', function() {
		console.log("Search.setButtons    editSampleButton onmouseup FIRED");
		thisObject.openSampleDialog();
	});
},
showUploadDialog : function () {
	console.log("Search.showUploadDialog");
	this.core.uploadDialog.dialog.set('title', "Upload Manifest File");
	this.core.uploadDialog.alert.innerHTML = "";
	this.core.uploadDialog.show();
},
showDetails : function (type, name) {
	console.log("Search.showDetails    type: " + type);
	console.log("Search.showDetails    name: " + name);

	console.log("Search.showDetails    centerPane: ");
	console.dir({this_centerPane:this.centerPane});
	console.log("Search.showDetails.iconNode    centerPane.iconNode: ");
	console.dir({this_centerPane_iconNode:this.centerPane.iconNode});
	
	// SET TAB NAME
	var moduleName = type.substring(0,1).toUpperCase() + type.substring(1);
	console.log("Search.showDetails    moduleName: " + moduleName);
	var tabPane = "detailed" + moduleName + "Tab";
	console.log("Search.showDetails    tabPane: " + tabPane);
	
	// SELECT TAB
	console.log("Search.centerTabContainer    this.centerTabContainer: " );
	console.dir({this_centerTabContainer:this.centerTabContainer});
	console.log("Search.showDetails    this[tabPane]: " );
	console.dir({this_tabPane:this[tabPane]});
	this.centerTabContainer.selectChild(this[tabPane]);

	// UPDATE GRID
	this["detailed" + moduleName].updateGrid(name);
},
showResult : function (type, name) {
	console.log("Search.showResult    type: " + type);
	console.log("Search.showResult    name: " + name);
	console.log("Search.showResult    bottomPane: ");
	console.dir({this_bottomPane:this.bottomPane});
	console.log("Search.showResult.iconNode    bottomPane.iconNode: ");
	console.dir({this_bottomPane_iconNode:this.bottomPane.iconNode});

	// OPEN IF CLOSED
	if ( ! this.bottomPane._showing ) {
		this.bottomPane.iconNode.click();
	}
	
	// SET TAB NAME
	var moduleName = type.substring(0,1).toUpperCase() + type.substring(1);
	console.log("Search.showResult    moduleName: " + moduleName);
	var tabPane = "detailed" + moduleName + "Tab";
	console.log("Search.showResult    tabPane: " + tabPane);
	
	// SELECT TAB
	console.log("Search.bottomTabContainer    this.bottomTabContainer: " );
	console.dir({this_bottomTabContainer:this.bottomTabContainer});
	console.log("Search.showResult    this[tabPane]: " );
	console.dir({this_tabPane:this[tabPane]});
	this.bottomTabContainer.selectChild(this[tabPane]);

	// UPDATE GRID
	this.core["detailed" + moduleName].updateGrid(name);
},
// TOP PANE
startLists : function () {

	var dataStore = this.core.dataStore;
	console.log("Search.startLists    dataStore:");
	console.dir({dataStore:dataStore});
	
	// THREE TOP LISTS
	//this.projects 	= 	window.projects	= new SelectList({ selectionMode: "single" }, "projects");
	//this.sample 	= 	window.samples	= new SelectList({ selectionMode: "single" }, "samples");
	//this.flowcells 	= 	window.flowcells= new SelectList({ selectionMode: "single" }, "flowcells");
	//this.lanes 		=	window.lanes	= new SelectList({ selectionMode: "single" }, "lanes");

	this.projectList 	= 	new SelectList({ selectionMode: "single" }, "projects");
	this.sampleList 	= 	new SelectList({ selectionMode: "single" }, "samples");
	this.flowcellList 	= 	new SelectList({ selectionMode: "single" }, "flowcells");
	this.laneList 		=	new SelectList({ selectionMode: "single" }, "lanes");

	this.refreshLists(dataStore);
},
refreshLists : function (dataStore) {
	//	create the unique lists and render them
	console.log("Search.refreshLists    dataStore.data:");
	console.dir({dataStore_data:dataStore.data});
	var projectsArray = this.unique(arrayUtil.map(dataStore.data, function(item){ return item.projectname; }));
	var samplesArray = this.unique(arrayUtil.map(dataStore.data, function(item){ return item.samplebarcode; }));
	var flowcellsArray = this.unique(arrayUtil.map(dataStore.data, function(item){ return item.flowcellbarcode; }));
	var lanesArray = this.unique(arrayUtil.map(dataStore.data, function(item){ return item.lanebarcode; }));

	// RENDER LISTS
	this.renderLists(projectsArray, samplesArray, flowcellsArray, lanesArray);
	
	// SET GRID LISTENERS
	this.setGridListeners(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
},
renderLists : function (projectsArray, samplesArray, flowcellsArray, lanesArray) {
	// DEBUG
	console.log("Search.renderLists    projects, projectsArray:")
	console.dir({projectsArray:projectsArray});
	console.log("Search.renderLists    samples, samplesArray:")
	console.dir({samplesArray:samplesArray});
	console.log("Search.renderLists    flowcells, flowcellsArray:")
	console.dir({flowcellsArray:flowcellsArray});
	console.log("Search.renderLists    lanes, lanesArray:")
	console.dir({lanesArray:lanesArray});

	// GENERATE 'All ...' TITLES
	projectsArray.unshift("All (" + projectsArray.length + " Project" + (projectsArray.length != 1 ? "s" : "") + ")");
	samplesArray.unshift("All (" + samplesArray.length + " Sample" + (samplesArray.length != 1 ? "s" : "") + ")");
	flowcellsArray.unshift("All (" + flowcellsArray.length + " Flowcell" + (flowcellsArray.length != 1 ? "s" : "") + ")");
	lanesArray.unshift("All (" + lanesArray.length + " Lane" + (lanesArray.length != 1 ? "s" : "") + ")");

	// RENDER LISTS WITH ARRAYS
	console.log("Search.renderLists    BEFORE this.projectList.renderArray(projectsArray)");
	this.projectList.renderArray(projectsArray);
	console.log("Search.renderLists    AFTER this.projectList.renderArray(projectsArray)");

	// DELAY TO GIVE TIME FOR LISTS TO BE GENERATED
	var thisObject = this;
	setTimeout(function(thisObj) {
		console.log("Search.renderLists    INSIDE setTimeout     DOING thisObject.sampleList.renderArray(samplesArray)");
		thisObject.sampleList.renderArray(samplesArray);
		console.log("Search.renderLists    AFTER thisObject.sampleList.renderArray(samplesArray)");
		console.log("Search.renderLists    thisObject.sampleList:");
		console.dir({thisObject_sampleList:thisObject.sampleList});
	}, 2000, this);
	
	// SECOND DELAY TO GIVE TIME FOR LISTS TO BE GENERATED
	console.log("Search.renderLists    BEFORE thisObject.flowcellList.renderArray(flowcellsArray)");
	setTimeout(function(thisObj) {
		console.log("Search.renderLists    INSIDE setTimeout     DOING thisObject.thisObject.flowcellList.renderArray(flowcellsArray)");
		thisObject.flowcellList.renderArray(flowcellsArray);
		console.log("Search.renderLists    AFTER thisObject.flowcellList.renderArray(flowcellsArray)");
	}, 3000, this);
	console.log("Search.renderLists    AFTER thisObject.flowcellList.renderArray(flowcellsArray)");

	// SECOND DELAY TO GIVE TIME FOR LISTS TO BE GENERATED
	console.log("Search.renderLists    BEFORE thisObject.laneList.renderArray(lanesArray)");
	setTimeout(function(thisObj) {
		console.log("Search.renderLists    INSIDE setTimeout     DOING thisObject.thisObject.laneList.renderArray(lanesArray)");
		thisObject.laneList.renderArray(lanesArray);
		console.log("Search.renderLists    AFTER thisObject.laneList.renderArray(lanesArray)");
	}, 4000, this);
	console.log("Search.renderLists    AFTER thisObject.laneList.renderArray(lanesArray)");

},
setGridListeners : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	console.log("Search.setGridListeners    dataStore:");
	console.dir({dataStore:dataStore});
	
	// SET MENUS
	this.setMenus();
	
	// SET SELECTS
	this.setProjectSelect(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setSampleClick(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setFlowcellClick(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setLaneClick(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);

	
	// SET FILTERS
	this.setProjectFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setSampleFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setFlowcellFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setLaneFilter(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);

	// SET ONCLICK LISTENERS
	this.setProjectClick(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setSampleClick(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setFlowcellClick(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);
	this.setLaneClick(dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray);

},
// SET MENU LISTENERS
setMenus : function () {
	this.setMenu(ProjectMenu, "ProjectMenu", this.projectList, "currentProject");
	this.setMenu(SampleMenu, "SampleMenu", this.sampleList, "currentSample");
	this.setMenu(FlowcellMenu, "FlowcellMenu", this.flowcellList, "currentFlowcell");
	this.setMenu(LaneMenu, "LaneMenu", this.laneList, "currentLane");

	//this.setSampleMenu();
	//this.setFlowcellMenu();	
	//this.setLaneMenu();	
},
setMenu : function (module, moduleName, target, currentItem) {
	//console.log("Search.setMenu    module: " + module); 
	//console.dir({module:module});
	//var moduleName = module.toString();
	console.log("Search.setMenu    moduleName: " + moduleName);
	var instance = moduleName.substring(0,1).toLowerCase() + moduleName.substring(1);
	console.log("Search.setMenu    instance: " + instance);

	//var module = dojo.getObject(moduleName);
	this[instance] = new module({parentWidget : this});
	console.log("Search.setMenu    this[" + instance + "]: ");
	console.dir({this_instance:this[instance]});

	// BIND MENU TO NODE
	this[instance].menu.bindDomNode(target.domNode);
	//this.projectMenu.menu.bindDomNode(this.projectList.domNode);
	//console.log("Search.setMenu    AFTER bindDomNode");

	console.log("Search.setMenu    this[target]: " + this[target]); 
	console.dir({this_target:this[target]});
	this[target].on(".dgrid-row:contextmenu", function(event){
		//console.log("Search.setMenu    " + instance + " FIRED");
		//console.log("Search.setMenu    event: ");
		//console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedItem = row.data;
		//console.log("Search.setMenu    CONTEXT MENU FIRED. selectedItem: " + selectedItem);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject[instance][currentItem] = selectedItem;
	});
},
setProjectMenu : function () {
	console.log("Search.setProjectMenu    DOING this.projectMenu = new ProjectMenu({ ... })");

	var thisObject = this;
	this.projectMenu = new ProjectMenu({parentWidget : this});
	console.log("Search.setProjectMenu    this.projectMenu:");
	console.dir({this_projectMenu:this.projectMenu});

	// BIND MENU TO NODE
	this.projectMenu.menu.bindDomNode(this.projectList.domNode);
	console.log("Search.setProjectMenu    AFTER bindDomNode");

	this.projectList.on(".dgrid-row:contextmenu", function(event){
		console.log("Search.setProjectMenu    CONTEXT MENU FIRED");
		console.log("Search.setProjectMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedProject = row.data;
		console.log("Search.setProjectMenu    CONTEXT MENU FIRED. selectedProject: " + selectedProject);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.projectMenu.currentProject = selectedProject;
	});
},
setSampleMenu : function () {
	console.log("Search.setSampleMenu    DOING this.sampleMenu = new SampleMenu({ ... })");

	var thisObject = this;
	this.sampleMenu = new SampleMenu({parentWidget : this});
	console.log("Search.setSampleMenu    this.sampleMenu:");
	console.dir({this_sampleMenu:this.sampleMenu});

	// BIND MENU TO NODE
	this.sampleMenu.menu.bindDomNode(this.sampleList.domNode);
	console.log("Search.setSampleMenu    AFTER bindDomNode");

	this.sampleList.on(".dgrid-row:contextmenu", function(event){
		console.log("Search.setSampleMenu    CONTEXT MENU FIRED");
		console.log("Search.setSampleMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedSample = row.data;
		console.log("Search.setSampleMenu    CONTEXT MENU FIRED. selectedSample: " + selectedSample);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.sampleMenu.currentSample = selectedSample;

		// item is the store item
	});
},
setFlowcellMenu : function () {
	console.log("Search.setFlowcellMenu    DOING this.flowcellMenu = new FlowcellMenu({ ... })");

	var thisObject = this;
	this.flowcellMenu = new FlowcellMenu({parentWidget : this});
	console.log("Search.setFlowcellMenu    this.flowcellMenu:");
	console.dir({this_flowcellMenu:this.flowcellMenu});

	// BIND MENU TO NODE
	this.flowcellMenu.menu.bindDomNode(this.flowcellList.domNode);
	console.log("Search.setFlowcellMenu    AFTER bindDomNode");

	this.flowcellList.on(".dgrid-row:contextmenu", function(event){
		console.log("Search.setFlowcellMenu    CONTEXT MENU FIRED");
		console.log("Search.setFlowcellMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedFlowcell = row.data;
		console.log("Search.setFlowcellMenu    CONTEXT MENU FIRED. selectedFlowcell: " + selectedFlowcell);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.flowcellMenu.currentFlowcell = selectedFlowcell;

		// item is the store item
	});
},
setLaneMenu : function () {
	console.log("Search.setLaneMenu    DOING this.laneMenu = new LaneMenu({ ... })");

	var thisObject = this;
	this.laneMenu = new LaneMenu({parentWidget : this});
	console.log("Search.setLaneMenu    this.laneMenu:");
	console.dir({this_laneMenu:this.laneMenu});

	// BIND MENU TO NODE
	this.laneMenu.menu.bindDomNode(this.laneList.domNode);
	console.log("Search.setLaneMenu    AFTER bindDomNode");

	this.laneList.on(".dgrid-row:contextmenu", function(event){
		console.log("Search.setLaneMenu    CONTEXT MENU FIRED");
		console.log("Search.setLaneMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedLane = row.data;
		console.log("Search.setLaneMenu    CONTEXT MENU FIRED. selectedLane: " + selectedLane);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.laneMenu.currentLane = selectedLane;

		// item is the store item
	});
},
refreshData : function (type) {
	console.log("Search.refreshData    type: " + type);

	if ( this.refreshing == true )	return;
	this.refreshing = true;

	var thisObject = this;
	var deferred = setTimeout(function() {
		console.log("Search.refreshData    setTimeout 1000");
		thisObject.refreshing = false;
	},
	1000);
	
	return deferred;
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
