console.log("plugins.request.Request    LOADING");

/* SUMMARY: CREATE AND MODIFY VIEWS
	
	TAB HIERARCHY IS AS FOLLOWS:
	
		tabs	

			mainTab

				leftPane (SELECT VIEW AND FEATURE TRACKS)

					comboBoxes

				rightPane (VIEW GENOMIC BROWSER)

						Browser

							Features (DRAG AND DROP FEATURE TRACKS LIST)

							GenomeRequest (GOOGLE MAPS-STYLE GENOME NAVIGATION)


	USE CASE SCENARIO 1: USER ADDS A FEATURE TO A VIEW

		OBJECTIVE:
		
			1. MINIMAL ACTION TO ACHIEVE THE DESIRE RESULT
			
			2. IMMEDIATE AND ANIMATED RESPONSES TO INDICATE STATUS/PROGRESS


		IMPLEMENTATION:
		
		1. USER SELECTS FEATURE IN BOTTOM OF LEFT PANE AND CLICKS 'Add'
		
		2. IF FEATURE ALREADY EXISTS IN VIEW, DO NOTHING.

		3. OTHERWISE, addRequestFeature CALL TO REMOTE WILL RETURN STATUS OR AN ERROR:
		
			IF STATUS IS 'Adding feature: featureName':
				
				1. START DELAYED POLL FOR STATUS
			
				2. POLL WILL STOP WHEN STATUS IS 'ready'
				
					OR THERE IS AN ERROR RESPONSE
					
				3. IF 'ready' THEN UPDATE CLIENT AND SERVER DATABASES
				
					AND RESET THE VIEW FEATURES COMBO BOX
		
				4. USER CAN CLICK THE 'refresh' BUTTON TO REMOVE ANY ERROR OR 
				
					NON-'ready' STATUS (E.G., PROLONGED 'adding' OR 'removing'
					
					DUE TO ERROR ON REMOTE SERVER):
			
				5. THE 'refresh' BUTTON IS THE VIEW ICON ON LEFT OF VIEW COMBO BOX 
			
			IF STATUS IS DIFFERENT, DO NOTHING.
			
			E.G.: 'Feature already present in request: featureName'
		
		4. IF ERROR, DO NOTHING.
		
			E.G.: 'Undefined inputs: feature, project, request'

*/	

define("plugins/request/Request", [
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dojo/dom-construct",
	"dojo/Deferred",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common",
	"plugins/request/Search",
	"plugins/request/Grid",

	// STORE	
	"dojo/store/Memory",
	
	// STATUS
	"plugins/form/Status",
	
	// STANDBY
	"dojox/widget/Standby",
	
	// DIALOGS
	"plugins/dijit/ConfirmDialog",
	"plugins/dijit/SelectiveDialog",
	
	// TAB
	"dijit/layout/ContentPane",

	// WIDGETS IN TEMPLATE
	"dijit/layout/BorderContainer",
	"plugins/dojox/layout/ExpandoPane",	
	"dijit/layout/SplitContainer",
	"dijit/layout/ContentPane",
	"dojo/data/ItemFileReadStore",
	"dijit/form/ComboBox",
	"dijit/form/Button",
	"dijit/layout/TabContainer",
	"dijit/layout/BorderContainer",
	"dojox/layout/FloatingPane",
	
	"dojo/fx/easing",
	"dojo/parser",
	"dijit/_base/place"
],

function (
	declare,
	arrayUtil,
	JSON,
	on,
	lang,
	domAttr,
	domClass,
	domConstruct,
	Deferred,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplateMixin,
	Common,
	Search,
	Grid,

	Memory,
	Status,
	Standby,
	ConfirmDialog,
	SelectiveDialog,
	ContentPane
) {

/////}}}}}

return declare("plugins/request/Request",
	[
		_Widget,
		_TemplatedMixin,
		_WidgetsInTemplateMixin,
		Common
], {

// templateString : String
// 		Template for this widget
templateString : dojo.cache("plugins", "request/templates/request.html"),

// cssFiles: ArrayRef
// 		CSS files for this widget
cssFiles : [
	dojo.moduleUrl("plugins", "request/css/request.css"),
	dojo.moduleUrl("dgrid", "css/dgrid.css"),
	dojo.moduleUrl("dojox", "layout/resources/ExpandoPane.css"),
	dojo.moduleUrl("dojox", "layout/tests/_expando.css"),
	dojo.moduleUrl("plugins", "dnd/css/dnd.css")
],

// url: String
// URL FOR REMOTE DATABASE
//url: "http://reqapi.annairesearch.com:8080/api/SubmitQuery.req",
url: "t/unit/plugins/request/request/data.json",

// core : HashRef
//		Hash of core classes
core : {},

////}}}
constructor : function(args) {	
	console.log("Request.constructor    args:");
	console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	
	console.log("Request.constructor    this.url: " + this.url);
		
	// LOAD CSS FILES
	this.loadCSS(this.cssFiles);		
},
postCreate: function() {
	this.startup();
},
// STARTUP
startup : function () {

	console.group("Request-" + this.id + "    startup");

    // ADD THIS WIDGET TO Agua.widgets[type]
	if ( Agua && Agua.addWidget ) {
	    Agua.addWidget("request", this);
	}

	// ATTACH PANE TO TAB PANE
	this.attachPane();
	
	// SET SEARCH
	this.setSearch();	
	
	// SET GRID
	this.setGrid();	

	
//// EXPAND LEFT PANE
	//this.leftPane.toggle();

	console.groupEnd("Request-" + this.id + "    startup");
},
// SETTERS
setSearch : function () {
	console.log("Request.setSearch    ");
	
	this.core.search = new Search({
		parent : this,
		attachPoint : this.searchAttachPoint,
		url : this.url,
		core : this.core
	});
},
setGrid : function () {

	var data = this.fetchSyncJson(this.url);

	//var data = this.fetchSyncJson("./data.json");

	
	console.log("Request.setGrid    data: ");
	console.dir({data:data});
	console.log("Request.setGrid    this.url: " + this.url);

	this.core.grid = new Grid({
		data : data,
		parent : this,
		attachPoint : this.gridAttachPoint,
		url : this.url,
		core : this.core
	});
},
attachPane : function () {
	console.log("Request.attachPane    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
	console.log("Request.attachPane    this.containerNode: " + this.containerNode);
	console.dir({this_containerNode:this.containerNode});	
	console.log("Request.attachPane    this.mainTab: " + this.mainTab);
	console.dir({this_mainTab:this.mainTab});	
	
	if ( this.attachPoint.selectChild ) {
		console.log("Request.attachPane    DOING this.addchild(this.mainTab)");
		this.attachPoint.addChild(this.mainTab);
		this.attachPoint.selectChild(this.mainTab);
	}
	else {
		this.attachPoint.appendChild(this.containerNode);
	}
},
destroyRecursive : function () {
	console.log("Request.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}

}); //	end declare

});	//	end define

console.log("plugins.request.Request    END");
