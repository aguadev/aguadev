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
	"plugins/infusion/Details/Project",
	"plugins/infusion/Details/Sample",
	"plugins/infusion/Details/Flowcell",
	"plugins/infusion/Details/Lane",
	"dojo/ready",
	"dojo/domReady!",
	
	"dijit/TitlePane",
	"dijit/form/TextBox",
	"dijit/form/Button",
	"dijit/layout/AccordionContainer",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojox/layout/ContentPane"
],

function (declare, arrayUtil, JSON, on, when, lang, domAttr, domClass, Data, Common, ProjectDetails, SampleDetails, FlowcellDetails, LaneDetails, ready) {

////}}}}}

return declare("plugins.infusion.Details",[Data], {

// core: Hash
// 		Holder for major components, e.g., core.data, core.dataStore
core : null,

// cssFiles : Array
// CSS FILES
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/css/details.css"),
	require.toUrl("plugins/infusion/images/elusive/css/elusive-webfont.css")
],

// callback : Function reference
// Call this after module has loaded
callback : null,

// attachPoint : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

//////}}
constructor : function(args) {		
	console.log("Details.constructor    args:");
	console.dir({args:args});
	
	if ( ! args )	return;
	
    // MIXIN ARGS
    lang.mixin(this, args);

	// SET core.lists
	if ( ! this.core ) 	this.core = new Object;
	this.core.details = this;

	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "agua.cgi";

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Details.postCreate    plugins.infusion.Infusion.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Details.startup    caller: " + this.startup.caller.nom);
	console.log("Details.startup    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
	
	if ( ! this.attachPoint ) {
		console.log("Details.startup    this.attachPoint is null. Returning");
		return;
	}
	
	if ( ! this.core ) {
		console.log("Details.startup    this.core is null. Returning");
		return;
	}

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// SET UP TITLE PANES TO LOAD GRIDS	
	this.setPanes();
},
setPanes : function () {
	console.log("Details.setPanes");
	this.setProjectDetails();
	this.setSampleDetails();
	this.setFlowcellDetails();
	this.setLaneDetails();	
},
setProjectDetails : function () {
	this.core.projectDetails = new ProjectDetails({
		attachPoint:	this.attachPoint,
		core		: 	this.core
	});
	console.log("Details.setProjectDetails    this.projectDetails:");
	console.dir({this_projectDetails:this.projectDetails});
},
setSampleDetails : function (dataStore) {
	this.core.sampleDetails = new SampleDetails({
		attachPoint:	this.attachPoint,
		core		: 	this.core
	});
	console.log("Details.setSampleDetails    this.sampleDetails:");
	console.dir({this_sampleDetails:this.sampleDetails});
},
setFlowcellDetails : function (dataStore) {
	this.core.flowcellDetails = new FlowcellDetails({
		attachPoint:	this.attachPoint,
		core		: 	this.core
	});
	console.log("Details.setFlowcellDetails    this.flowcellDetails:");
	console.dir({this_flowcellDetails:this.flowcellDetails});
},
setLaneDetails : function (dataStore) {
	this.core.laneDetails = new LaneDetails({
		attachPoint:	this.attachPoint,
		core		: 	this.core
	});
	console.log("Details.setLaneDetails    this.laneDetails:");
	console.dir({this_laneDetails:this.laneDetails});
},
showDetails : function (type, name) {
	console.log("Details.showDetails    type: " + type);
	console.log("Details.showDetails    name: " + name);

	// SET INSTANCE NAME
	var instanceName = type + "Details";
	console.log("Details.showDetails    instanceName: " + instanceName);

	// SET TAB NAME
	var tabPane = type + "DetailsTab";
	console.log("Details.showDetails    tabPane: " + tabPane);
	console.log("Details.showDetails    this.core[tabPane]: " );
	console.dir({this_tabPane:this[tabPane]});
	console.log("Details.showDetails    this: " + this);
	console.dir({this:this});
	
	// SELECT TAB
	this.attachPoint.selectChild(this.core[instanceName].tabNode);

	// UPDATE GRID
	this.core[instanceName].updateGrid(name);

	return true;
}



}); 	//	end declare

});	//	end define

