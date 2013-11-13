define([
	"dgrid/List",
	"dgrid/OnDemandGrid",
	"dgrid/Selection",
	"dgrid/Keyboard",
	"dgrid/extensions/ColumnHider",
	"dojo/_base/declare",
	"dojo/_base/array",
	"plugins/infusion/Data",
	"plugins/infusion/Filter",
	"plugins/infusion/SelectList",
	"plugins/infusion/Menu/Project",
	"plugins/infusion/Menu/Sample",
	"plugins/infusion/Menu/Flowcell",
	"plugins/infusion/Menu/Lane",
	"plugins/infusion/Dialog/Project",
	"dojo/json",
	"dojo/on",
	"dojo/when",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/core/Common",
	"plugins/exchange/Exchange",
	"dojox/io/windowName",
	//"plugins/graph/Graph",
	"plugins/form/UploadDialog",
	"dojo/ready",
	"dojo/domReady!",
	
	"plugins/dojox/layout/ExpandoPane",
	"dijit/TitlePane",
	"dijit/form/TextBox",
	"dijit/form/Button",
	"dijit/_Widget",
	"dijit/_Templated",

	"dojox/layout/ExpandoPane",
	"dojo/data/ItemFileReadStore",
	"dojo/store/Memory",
	"dijit/form/Select",
	"dijit/layout/AccordionContainer",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojox/layout/ContentPane",
	"dojox/layout/FloatingPane",
	"dijit/layout/BorderContainer",
	"dijit/form/Button"
],

function (List, Grid, Selection, Keyboard, Hider, declare, arrayUtil, Data, Filter, SelectList, ProjectMenu, SampleMenu, FlowcellMenu, LaneMenu, DialogProject, JSON, on, when, lang, domAttr, domClass, Common, Exchange, windowName, Graph, UploadDialog, ready) {

////}}}}}

return declare("plugins.infusion.Lists",[dijit._Widget, dijit._Templated, Data, Filter, Common, Exchange], {

// Path to the template of this widget. 
// templatePath : String
templatePath : require.toUrl("plugins/infusion/templates/lists.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

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
	require.toUrl("plugins/infusion/css/lists.css"),
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
	console.log("Lists.constructor    args:");
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
	console.log("Lists.postCreate    plugins.infusion.Infusion.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Lists.startup    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
	
	if ( ! this.attachPoint ) {
		console.log("Lists.startup    this.attachPoint is null. Returning");
		return;
	}
	
	if ( ! this.core ) {
		console.log("Lists.startup    this.core is null. Returning");
		return;
	}

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// ADD THE PANE TO THE TAB CONTAINER
	this.attachPane();
	
	// SET ADD PROJECT BUTTON
	this.setButtons();
	
	// CREATE TOP GRIDS
	this.startLists();
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

	// ADD PROJECT BUTTON --> UPLOAD DIALOG
	var thisObject = this;
	on(this.addProjectButton, 'click', function() {
		console.log("Lists.setAddProjectButton    addProjectButton ONCLICK FIRED");
		thisObject.core.dialogs.showUploadDialog();
	});
	this.setButtonStyle("addProjectButton");
	
	// EDIT BUTTONS
	var types = [ "project", "sample", "flowcell", "lane" ];
	for ( var i = 0; i < types.length; i++ ) {
		var type = types[i];
		var cowType = type.substring(0,1).toUpperCase() + type.substring(1);
		console.log("Lists.setButtons    type: " + type);
		console.log("Lists.setButtons    cowType: " + cowType);

		var button = "edit" + cowType + "Button";
		
		this.setButtonAction(button, type);

		this.setButtonStyle(button);
	}
},
setButtonAction : function (button, type) {	
// ONCLICK ACTION
	var thisObject = this;
	on(this[button], 'click', function() {
		console.log("Lists.setButtons   [" + button + "] click FIRED");
		thisObject.showDialog(type);
	});	
},
setButtonStyle : function (button) {
	// CSS STYLING
	on(this[button], 'mouseover', function() {
		domClass.add(this,"hover");
	});
	on(this[button], 'mouseout', function() {
		domClass.remove(this,"hover");
	});
	on(this[button], 'mousedown', function() {
		domClass.add(this,"active");
	});
	on(this[button], 'mouseup', function() {
		domClass.remove(this,"active");
	});	
},
showDialog : function (type) {
	console.log("Lists.showDialog    type: " + type);
	
	var name = this.getSelectedName(type);
	console.log("Lists.showDialog    name: " + name);
	if (! name )	return;
	
	this.core.dialogs.showDialog(type, name);
},
getFlowcellId : function () {
	console.log("Lists.getSelectedValue    this.flowcellList]: " + this.flowcellList);
	console.dir({this_flowcellList:this.flowcellList});
	var value = this.flowcellList._lastSelected
		? this.flowcellList._lastSelected.innerText
		: "";
	console.log("Lists.getSelectedValue    value: " + value);
	
},
getSelectedName : function (type) {
	console.log("Lists.getSelectedName    type: " + type);
	var listName = type + "List";
	console.log("Lists.getSelectedName    listName: " + listName);
	console.log("Lists.getSelectedName    this[listName]: " + this[listName]);
	console.dir({this_listName:this[listName]});
	if ( ! this[listName]._lastSelected )	return null;
	
	return this[listName]._lastSelected.innerText;
},
showDetails : function (type, name) {
	console.log("Lists.showDetails    type: " + type);
	console.log("Lists.showDetails    name: " + name);

	if (this.core && this.core.details ) {
		return this.core.details.showDetails(type, name);
	}
	
	return false;
},
showResult : function (type, name) {
	//console.log("Lists.showResult    type: " + type);
	//console.log("Lists.showResult    name: " + name);
	//console.log("Lists.showResult    bottomPane: ");
	//console.dir({this_bottomPane:this.bottomPane});
	//console.log("Lists.showResult.iconNode    bottomPane.iconNode: ");
	//console.dir({this_bottomPane_iconNode:this.bottomPane.iconNode});

	// OPEN IF CLOSED
	if ( ! this.bottomPane._showing ) {
		this.bottomPane.iconNode.click();
	}
	
	// SET TAB NAME
	var moduleName = type.substring(0,1).toUpperCase() + type.substring(1);
	console.log("Lists.showResult    moduleName: " + moduleName);
	var tabPane = "detailed" + moduleName + "Tab";
	console.log("Lists.showResult    tabPane: " + tabPane);
	
	// SELECT TAB
	//console.log("Lists.bottomTabContainer    this.bottomTabContainer: " );
	//console.dir({this_bottomTabContainer:this.bottomTabContainer});
	//console.log("Lists.showResult    this[tabPane]: " );
	//console.dir({this_tabPane:this[tabPane]});
	this.bottomTabContainer.selectChild(this[tabPane]);

	// UPDATE GRID
	this.core["detailed" + moduleName].updateGrid(name);
},
// TOP PANE
startLists : function () {

	var dataStore = this.core.dataStore;
	console.log("Lists.startLists    dataStore:");
	console.dir({dataStore:dataStore});
	
	this.projectList 	= 	new SelectList({ selectionMode: "single" }, "projects");
	this.sampleList 	= 	new SelectList({ selectionMode: "single" }, "samples");
	this.flowcellList 	= 	new SelectList({ selectionMode: "single" }, "flowcells");
	this.laneList 		=	new SelectList({ selectionMode: "single" }, "lanes");

	this.refreshLists(dataStore);
},
refreshLists : function (dataStore) {
	//	create the unique lists and render them
	console.log("Lists.refreshLists    dataStore.data:");
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
	console.log("Lists.renderLists")

	//// DEBUG
	//console.log("Lists.renderLists    projects, projectsArray:")
	//console.dir({projectsArray:projectsArray});
	//console.log("Lists.renderLists    samples, samplesArray:")
	//console.dir({samplesArray:samplesArray});
	//console.log("Lists.renderLists    flowcells, flowcellsArray:")
	//console.dir({flowcellsArray:flowcellsArray});
	//console.log("Lists.renderLists    lanes, lanesArray:")
	//console.dir({lanesArray:lanesArray});

	// GENERATE 'All ...' TITLES
	projectsArray.unshift("All (" + projectsArray.length + " Project" + (projectsArray.length != 1 ? "s" : "") + ")");
	samplesArray.unshift("All (" + samplesArray.length + " Sample" + (samplesArray.length != 1 ? "s" : "") + ")");
	flowcellsArray.unshift("All (" + flowcellsArray.length + " Flowcell" + (flowcellsArray.length != 1 ? "s" : "") + ")");
	lanesArray.unshift("All (" + lanesArray.length + " Lane" + (lanesArray.length != 1 ? "s" : "") + ")");

	// RENDER LISTS WITH ARRAYS
	try {
		{
			console.log("Lists.renderLists    DOING LISTS IN promise ARRAY");
			var promise = when(this.projectList.renderArray(projectsArray));
			console.log("Lists.renderLists    promise:");
			console.dir({promise:promise});
			
			promise.then(function(){}, this.sampleList.renderArray(samplesArray))
			.then(function(){}, this.flowcellList.renderArray(flowcellsArray))
			.then(function(){}, this.laneList.renderArray(lanesArray));	
		}
	} catch(e) {
		console.log("Lists.renderLists    **** PROBLEM OCCURRED WHILE DOING LISTS IN promise ARRAY ****");
	}
},
setGridListeners : function (dataStore, projectsArray, samplesArray, flowcellsArray, lanesArray) {
	console.log("Lists.setGridListeners    dataStore:");
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
},
setMenu : function (module, moduleName, target, currentItem) {
	//console.log("Lists.setMenu    module: " + module); 
	//console.dir({module:module});

	console.log("Lists.setMenu    moduleName: " + moduleName);
	var instance = moduleName.substring(0,1).toLowerCase() + moduleName.substring(1);
	//console.log("Lists.setMenu    instance: " + instance);
	//console.log("Lists.setMenu    this.core: " + this.core);
	//console.dir({this_core:this.core});
	//console.log("Lists.setMenu    target: " + target);
	//console.dir({target:target});
		
	this.core[instance] = new module({
		core	: 	this.core
	});
	console.log("Lists.setMenu    this.core[" + instance + "]: ");
	console.dir({this_core_instance:this.core[instance]});

	// BIND MENU TO NODE
	this.core[instance].menu.bindDomNode(target.domNode);
	//this.projectMenu.menu.bindDomNode(this.projectList.domNode);
	//console.log("Lists.setMenu    AFTER bindDomNode");

	console.log("Lists.setMenu    target"); 
	console.dir({target:target});

	target.on(".dgrid-row:contextmenu", function(event){
		//console.log("Lists.setMenu    " + instance + " FIRED");
		//console.log("Lists.setMenu    event: ");
		//console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedItem = row.data;
		//console.log("Lists.setMenu    CONTEXT MENU FIRED. selectedItem: " + selectedItem);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.core[instance][currentItem] = selectedItem;
	});
},
setProjectMenu : function () {
	console.log("Lists.setProjectMenu    DOING this.projectMenu = new ProjectMenu({ ... })");

	var thisObject = this;
	this.projectMenu = new ProjectMenu({parentWidget : this});
	console.log("Lists.setProjectMenu    this.projectMenu:");
	console.dir({this_projectMenu:this.projectMenu});

	// BIND MENU TO NODE
	this.projectMenu.menu.bindDomNode(this.projectList.domNode);
	console.log("Lists.setProjectMenu    AFTER bindDomNode");

	this.projectList.on(".dgrid-row:contextmenu", function(event){
		console.log("Lists.setProjectMenu    CONTEXT MENU FIRED");
		console.log("Lists.setProjectMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedProject = row.data;
		console.log("Lists.setProjectMenu    CONTEXT MENU FIRED. selectedProject: " + selectedProject);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.projectMenu.currentProject = selectedProject;
	});
},
setSampleMenu : function () {
	console.log("Lists.setSampleMenu    DOING this.sampleMenu = new SampleMenu({ ... })");

	var thisObject = this;
	this.sampleMenu = new SampleMenu({parentWidget : this});
	console.log("Lists.setSampleMenu    this.sampleMenu:");
	console.dir({this_sampleMenu:this.sampleMenu});

	// BIND MENU TO NODE
	this.sampleMenu.menu.bindDomNode(this.sampleList.domNode);
	console.log("Lists.setSampleMenu    AFTER bindDomNode");

	this.sampleList.on(".dgrid-row:contextmenu", function(event){
		console.log("Lists.setSampleMenu    CONTEXT MENU FIRED");
		console.log("Lists.setSampleMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedSample = row.data;
		console.log("Lists.setSampleMenu    CONTEXT MENU FIRED. selectedSample: " + selectedSample);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.sampleMenu.currentSample = selectedSample;

		// item is the store item
	});
},
setFlowcellMenu : function () {
	console.log("Lists.setFlowcellMenu    DOING this.flowcellMenu = new FlowcellMenu({ ... })");

	var thisObject = this;
	this.flowcellMenu = new FlowcellMenu({parentWidget : this});
	console.log("Lists.setFlowcellMenu    this.flowcellMenu:");
	console.dir({this_flowcellMenu:this.flowcellMenu});

	// BIND MENU TO NODE
	this.flowcellMenu.menu.bindDomNode(this.flowcellList.domNode);
	console.log("Lists.setFlowcellMenu    AFTER bindDomNode");

	this.flowcellList.on(".dgrid-row:contextmenu", function(event){
		console.log("Lists.setFlowcellMenu    CONTEXT MENU FIRED");
		console.log("Lists.setFlowcellMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedFlowcell = row.data;
		console.log("Lists.setFlowcellMenu    CONTEXT MENU FIRED. selectedFlowcell: " + selectedFlowcell);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.flowcellMenu.currentFlowcell = selectedFlowcell;

		// item is the store item
	});
},
setLaneMenu : function () {
	console.log("Lists.setLaneMenu    DOING this.laneMenu = new LaneMenu({ ... })");

	var thisObject = this;
	this.laneMenu = new LaneMenu({parentWidget : this});
	console.log("Lists.setLaneMenu    this.laneMenu:");
	console.dir({this_laneMenu:this.laneMenu});

	// BIND MENU TO NODE
	this.laneMenu.menu.bindDomNode(this.laneList.domNode);
	console.log("Lists.setLaneMenu    AFTER bindDomNode");

	this.laneList.on(".dgrid-row:contextmenu", function(event){
		console.log("Lists.setLaneMenu    CONTEXT MENU FIRED");
		console.log("Lists.setLaneMenu    event: ");
		console.dir({event:event});
		event.preventDefault(); // prevent default browser context menu
		event.stopPropagation();
		var row = event.target.childNodes[0];
		var selectedLane = row.data;
		console.log("Lists.setLaneMenu    CONTEXT MENU FIRED. selectedLane: " + selectedLane);
		
		// SET CURRENT PROJECT IN PROJECT MENU
		thisObject.laneMenu.currentLane = selectedLane;

		// item is the store item
	});
}


}); 	//	end declare

});	//	end define

