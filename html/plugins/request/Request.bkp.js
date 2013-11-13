console.log("plugins.request.Request    LOADING");

/* SUMMARY: Allow user to search genomic files in GNOS repositories using metadata terms */

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
	
	// READY
	//"dojo/ready",
	"dojo/domReady!",
	
	// WIDGETS IN TEMPLATE
	"dijit/layout/BorderContainer",
	"dijit/layout/TabContainer",
	"plugins/dojox/layout/ExpandoPane",
	
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
	Common,
	Search,
	Grid,

	Memory,
	Status,
	Standby,
	ConfirmDialog,
	SelectiveDialog
	//,
	//ready
) {

/////}}}}}

return declare("plugins/request/Request",
	[ _Widget, _TemplatedMixin, Common ], {

// templateString : String
// 		WIDGET TEMPLATE
templateString: dojo.cache("plugins", "request/templates/request.html"),

// PARENT NODE, I.E., TABS NODE
parentWidget : null,

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,
workflow : null,

// onChangeListeners : Array. LIST OF COMBOBOX ONCHANGE LISTENERS
onChangeListeners : new Object,

// setListeners : Boolean. SET LISTENERS FLAG 
setListeners : false,

// cssFiles: Array
// CSS FILES
cssFiles : [
	require.toUrl("plugins/request/css/request.css"),
	require.toUrl("plugins/request/css/jquery-ui-1.8.21.custom.css"),
	require.toUrl("dojox/layout/resources/ExpandoPane.css"),
	require.toUrl("dojox/layout/tests/_expando.css"),
	require.toUrl("plugins/dnd/css/dnd.css")
],

// grid : plugins/request/Grid object
//		Grid widget to display downloadable files
grid : null,

// search : plugins/request/Search object
//		Widget to display search options and enable search
search : null,

////}}}
constructor : function(args) {	
	console.log("Request.constructor    args:");
	console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	
	console.log("Request.constructor    this.baseUrl: " + this.baseUrl);
	
	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "/agua.cgi";
	
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

	//// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	//this.inherited(arguments);

	// ATTACH PANE
	var thisObject = this;
	//ready(function() {
		dojo.parser.parse();
		thisObject.attachPane();
	//})
	
	//// TOGGLE LEFT PANE
	//this.leftPane.toggle();

	// SET SEARCH
	this.setSearch();	

	//// SET SEARCH
	//this.setGrid();	

	console.groupEnd("Request-" + this.id + "    startup");
},
// SETTERS
setSearch : function () {
	console.log("Request.setSearch    ");
	
	this.search = new Search({
		parent : this,
		attachPoint : this.searchAttachPoint,
		url : this.url
	});
	
	//var deferred = this._getDeferred();
	//console.log("Request.setSearch    RETURNING deferred");
	//deferred.resolve({success:true});
	//return deferred;
},
setGrid : function () {
	console.log("Request.setGrid    ");

	this.grid = new Grid({
		parent : this,
		attachPoint : this.gridAttachPoint,
		url : this.url
	});
	
	//var deferred = this._getDeferred();
	//console.log("Request.setGrid    RETURNING deferred");
	//deferred.resolve({success:true});
	//return deferred;
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
