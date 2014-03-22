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
	"dojo/io/script",
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
	script,

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
	require.toUrl("plugins/request/css/request.css"),
	require.toUrl("dojox/layout/resources/ExpandoPane.css"),
	require.toUrl("dojox/layout/tests/_expando.css"),
	require.toUrl("plugins/dnd/css/dnd.css")
],

// url: String
// URL FOR REMOTE DATABASE
//url : "http://reqapi.annairesearch.com:8080/api/SubmitQuery.req",
url : "t/unit/plugins/request/request/data-10.json",

// core : HashRef
//		Hash of core classes
core : {},

// fields : ArrayRef
//		Array of field options
fields : [
	"Source",
	"Source Name",
	"Analysis ID",
	"state",
	"reason",
	"Modified Date",
	"Upload Date",
	"Published Date",
	"Short Center Name",
	"study",
	"Aliquot ID",
	"Sample Accession",
	"Legacy Sample ID",
	"Disease Abbreviation",
	"TSS ID",
	"Participant ID",
	"Sample ID",
	"Analyte Code",
	"Sample Type",
	"Library Strategy",
	"platform",
	"Analysis URI",
	"filename",
	"filesize",
	"checksum",
	"Checksum Type",
	"Disease",
	"Analyte",
	"Sample",
	"Center Name"
],

// fieldOperators : HashRef
//		Hash of fields against operators
fieldOperators : {
	"Source" : ["is", "is not", "contains", "NOT contains"],
	"Source Name" : ["is", "is not", "contains", "NOT contains"],
	"Analysis ID" : ["is", "is not", "contains", "NOT contains"],
	"state" : ["is", "is not", "contains", "NOT contains"],
	"reason" : ["is", "is not", "contains", "NOT contains"],
	"Modified Date" : ["before", "after"],
	"Upload Date" : ["before", "after"],
	"Published Date" : ["before", "after"],
	"Short Center Name" : ["is", "is not", "contains", "NOT contains"],
	"study" : ["is", "is not", "contains", "NOT contains"],
	"Aliquot ID" : ["is", "is not", "contains", "NOT contains"],
	"Sample Accession" : ["is", "is not", "contains", "NOT contains"],
	"Legacy Sample ID" : ["is", "is not", "contains", "NOT contains"],
	"Disease Abbreviation" : ["is", "is not", "contains", "NOT contains"],
	"TSS ID" : ["is", "is not", "contains", "NOT contains"],
	"Participant ID" : ["is", "is not", "contains", "NOT contains"],
	"Sample ID" : ["is", "is not", "contains", "NOT contains"],
	"Analyte Code" : ["is", "is not", "contains", "NOT contains"],
	"Sample Type" : ["is", "is not", "contains", "NOT contains"],
	"Library Strategy" : ["is", "is not", "contains", "NOT contains"],
	"platform" : ["is", "is not", "contains", "NOT contains"],
	"Analysis URI" : ["is", "is not", "contains", "NOT contains"],
	"filename" : ["is", "is not", "contains", "NOT contains"],
	"filesize" : ["==", "!=", ">", "<", ">=", "<="],
	"checksum" : ["is", "is not", "contains", "NOT contains"],
	"Checksum Type" : ["is", "is not", "contains", "NOT contains"],
	"Disease" : ["is", "is not", "contains", "NOT contains"],
	"Analyte" : ["is", "is not", "contains", "NOT contains"],
	"Sample" : ["is", "is not", "contains", "NOT contains"],
	"Center Name" : ["is", "is not", "contains", "NOT contains"]
},

// fieldTypes : HashRef
//		Hash of fields against input types
fieldTypes : {
	"Source" : ["text"],
	"Source Name" : ["text"],
	"Analysis ID" : ["text"],
	"state" : ["text"],
	"reason" : ["text"],
	"Modified Date" : ["date"],
	"Upload Date" : ["date"],
	"Published Date" : ["date"],
	"Short Center Name" : ["text"],
	"study" : ["text"],
	"Aliquot ID" : ["text"],
	"Sample Accession" : ["text"],
	"Legacy Sample ID" : ["text"],
	"Disease Abbreviation" : ["text"],
	"TSS ID" : ["text"],
	"Participant ID" : ["text"],
	"Sample ID" : ["text"],
	"Analyte Code" : ["text"],
	"Sample Type" : ["text"],
	"Library Strategy" : ["text"],
	"platform" : ["text"],
	"Analysis URI" : ["text"],
	"filename" : ["text"],
	"filesize" : ["number"],
	"checksum" : ["text"],
	"Checksum Type" : ["text"],
	"Disease" : ["text"],
	"Analyte" : ["text"],
	"Sample" : ["text"],
	"Center Name" : ["text"]
},

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

	// SET DATA
	this.setData();

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
		parent 			: 	this,
		attachPoint 	: 	this.searchAttachPoint,
		url 			: 	this.url,
		core 			: 	this.core,
		fields			:	this.fields,
		fieldOperators	:	this.fieldOperators,
		fieldTypes		:	this.fieldTypes
	});
},
rowsToObject : function (rows) {
	//console.log("Request.rowsToObject    rows: " + rows);
	//console.dir({rows:rows});

	var headers =	rows.splice(0,1)[0];
	console.log("Request.rowsToObject    headers: " + headers);
	console.dir({headers:headers});
	
	var data = [];
	for ( var i = 0; i < rows.length; i++ ) {
		var hash = {};
		for ( var j = 0; j < headers.length; j++ ) {
			hash[headers[j]] = rows[i][j];
		}
		//console.log("Request.rowsToObject    hash: " + hash);
		//console.dir({hash:hash});		
		data.push(hash);
	}

	return data;
},
setData : function () {
	console.log("Request.setData    this.url: " + this.url);

	//var data = this.fetchSyncJson(this.url);

	var rows = this.fetchSyncJson(this.url);
	var data = this.rowsToObject(rows);

	this.data = data;
	return ;

	//var data = {"data": [{"password": "mypass", "userid": "andyh"}, {"PAGE": [{"PAGENUM": "-1"}]}]};
	//var data = {"password": "mypass", "userid": "andyh","PAGE": [{"PAGENUM": "-1"}]};
	var data = {"password": "Test1Test", "userid": "andyh","PAGENUM": "-1"};
	
	var thisObj	=	this;
	script.get({
        //url: "http://reqapi.annairesearch.com:8080/api/SubmitQuery.req",
		url: "http://reqapi.annairesearch.com:8080/api/SubmitQuery.req?data=%5B%7B\"password\"%3A+\"mypass\"%2C+\"userid\"%3A+\"andyh\"%7D%2C+%7B\"PAGE\"%3A+%5B%7B\"PAGENUM\"%3A+\"-1\"%7D%5D%7D%5D",

        //content: JSON.stringify(data),
        content: data,
        callbackParamName: "callback"
    }).then(function(data){
 
		console.log("Request.setData    data: ");
		console.dir({data:data});
		thisObj.data	=	data;
    });
	
	//var callback 		= function (response) {
	//	console.log("View._remoteAddView    response: ");
	//	thisObj.data	=	response;
	//	console.log("Request.setGrid    thisObj.data: ");
	//	console.dir({thisObj_data:thisObj.data});
	//}
	//
	////http://reqapi.annairesearch.com:8080/api/SubmitQuery.test
	//var inputs = {
	//	url 	:	"http://reqapi.annairesearch.com:8080/api/SubmitQuery.test",
	//	query	:	[{"password":"mypass","userid":"andyh"},{"PAGE":[{"PAGENUM":"-1"}]}],
	//	sync	:	true,
	//	callback:	callback,
	//	doToast	:	false
	//	//sourceid:	this.id,
	//	//token	:	this.token,
	//	//mode 	: 	"addView",
	//	//module 	:	"Agua::View",
	//};
	//
	////this.doPut({ url: url, query: putData, callback: callback, doToast: false });
	//this.doGet(inputs);
},
setGrid : function () {
	console.log("Request.setGrid    this.data: ");
	console.dir({this_data:this.data});

	this.core.grid = new Grid({
		data 			: 	this.data,
		parent 			: 	this,
		attachPoint 	: 	this.gridAttachPoint,
		url 			: 	this.url,
		core 			: 	this.core,
		fields			:	this.fields
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