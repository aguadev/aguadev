console.log("plugins.request.Grid    LOADING");

/* SUMMARY: ALLOW USER TO SEARCH GENOMIC FILES IN GNOS REPOSITORIES USING METADATA TERMS */

define("plugins/request/Grid", [
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dojo/dom-construct",
	"dojo/query",

	"plugins/request/DataStore",
	"dojo/store/Observable",
	"dgrid/List",
	"dgrid/OnDemandGrid",
	"dgrid/editor",
	"dgrid/Selection",
	"dgrid/Keyboard",
	"dgrid/extensions/ColumnHider",
	//"dgrid/extensions/ColumnResizer",
	//"dgrid/test/data/base",

	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"plugins/core/Common",

	// STORE	
	"dojo/store/Memory",
	
	// STATUS
	"plugins/form/Status",
	
	// STANDBY
	"dojox/widget/Standby",
	
	// DIALOGS
	"plugins/dijit/ConfirmDialog",
	"plugins/dijit/SelectiveDialog",
	

	"dojo/domReady!",

	// TAB
	"dijit/layout/ContentPane",

	// HAS A
	"dijit/layout/BorderContainer",
	"plugins/dojox/layout/ExpandoPane",
	
	// WIDGETS IN TEMPLATE
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
	query,

	DataStore,
	Observable,
	List,
	Grid,
	Editor,
	Selection,
	Keyboard,
	Hider,
	//Resizer,
	//testStore,

	_Widget,
	_TemplatedMixin,
	Common,

	Memory,
	Status,
	Standby,
	ConfirmDialog,
	SelectiveDialog,

	ContentPane
) {

/////}}}}}

return declare("plugins/request/Grid",
	[ _Widget, _TemplatedMixin, Common ], {

// templateString : String	
// 		Template for this widget
templateString: dojo.cache("plugins", "request/templates/grid.html"),

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,
workflow : null,

// cssFiles: Array
// CSS FILES
cssFiles : [
	require.toUrl("plugins/request/css/grid.css"),
	require.toUrl("plugins/dnd/css/dnd.css"),
	require.toUrl("dgrid/css/extensions/ColumnHider.css")
],

// url: String
// URL FOR REMOTE DATABASE
url: "http://reqapi.annairesearch.com:8080/api/SubmitQuery.req",

// data : ArrayRef
//		Data to load into Grid
data : null,

////}}}
constructor : function(args) {	
	console.log("Grid.constructor    args:");
	console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	
	console.log("Grid.constructor    this.baseUrl: " + this.baseUrl);
	console.log("Grid.constructor    this.data: " + this.data);
	console.dir({this_data:this.data});
		
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

	console.group("Grid-" + this.id + "    startup");
	console.log("-------------------------- Grid.startup    this.browsers:");
	console.log("Grid.startup    this.loadOnStartup: " + this.loadOnStartup);
	
    // ADD THIS WIDGET TO Agua.widgets[type]
	if ( Agua && Agua.addWidget ) {
	    Agua.addWidget("request", this);
	}

	// ADD THE PANE TO THE TAB CONTAINER
	this.attachPane();
	
	// SET GRID
	if ( this.data ) {
		this.setGrid(this.data);
	}

	console.groupEnd("Grid-" + this.id + "    startup");
},
// UPDATE GRID WITH FILTERS
updateGrid : function (filters, data) {
	console.group("Grid-" + this.id + "    updateGrid");

	console.log("Grid.updateGrid    filters.length: " + filters.length);
	console.log("Grid.updateGrid    filters: ");
	console.dir({filters:filters});
	
	var newData = dojo.clone(data);
	console.log("Grid.updateGrid    BEGIN newData: ");
	console.dir({newData:newData});
	console.log("Grid.updateGrid    BEGIN newData.length: " + newData.length);
	
	if ( ! newData ) return;	
	
	for ( var i = 0; i < filters.length; i++ ) {
		var filter	=	filters[i];
		console.log("Grid.updateGrid    filter: " + JSON.stringify(filter));
		console.log("Grid.updateGrid    newData.length: " + newData.length);
		
		if ( filter.action == "AND" ) {
			console.log("Grid.updateGrid    DOING 'AND' filter: ");
			console.dir({filter:filter});
			
			newData = this.filterData(filter, newData);
			console.log("Grid.updateGrid    DOING 'AND' newData: ");
			console.dir({newData:newData});
		}
		else if ( filter.action == "OR" ) {
			console.log("Grid.updateGrid    DOING 'OR' filter: ");
			console.dir({filter:filter});
			
			var orData = dojo.clone(data);
			console.log("Grid.updateGrid    BEGIN orData.length: " + orData.length);
			orData	=	this.filterData(filter, orData);
			console.log("Grid.updateGrid    AFTER orData.length: " + orData.length);
			console.log("Grid.updateGrid    orData: ");
			console.dir({orData:orData});
	
			if ( orData && orData.length != 0 ) {
				newData = newData.concat(orData);
			}
		}
		else {
			console.log("Grid.updateGrid    SKIPPING filter.action neither 'AND' nor 'OR': " + filter.action);
		}
	}
	console.log("Grid.updateGrid    FINAL newData.length: " + newData.length);
	console.log("Grid.updateGrid    FINAL newData: ");
	console.dir({newData:newData});

	this.setGrid(newData);

	console.groupEnd("Grid-" + this.id + "    updateGrid");
},
filterData : function (filter, data) {
	console.group("Grid-" + this.id + "    filterData");

	console.log("Grid.filterData    filter: " + JSON.stringify(filter));
	console.log("Grid.filterData    data: ");
	console.dir({data:data});
	
	console.log("Grid.filterData    BEFORE FILTER, filter: " + JSON.stringify(filter));
	switch (filter.operator) {
		
		case "==" 		:	return this.equals(filter, data); break;
		case "!=" 		:	return this.notEquals(filter, data); break;
		case ">" 		:	return this.greaterThan(filter, data); break;
		case "<" 		:	return this.lessThan(filter, data); break;
		case ">=" 		:	return this.greaterThanOrEqual(filter, data); break;
		case "<=" 		:	return this.lessThanOrEqual(filter, data); break;
		case "contains" :	return this.contains(filter, data); break;
		case "!contains": 	return this.notContains(filter, data); break;
	}
	console.log("Grid.filterData    AFTER FILTER, filter: " + JSON.stringify(filter));
	
	console.groupEnd("Grid-" + this.id + "    filterData");

	return [];
},
// FILTERS
equals : function (filter, data) {
	console.log("Grid.equals    filter: " + JSON.stringify(filter));

	console.log("Grid.equals    FILTERING FOR " + filter.field + " = " + filter.value);
	data = this.filterByKeyValues(data, [filter.field], [filter.value]);

	console.log("Grid.equals    RETURNING data: ");
	console.dir({data:data});
	
	return data;
},
notEquals : function (filter, action, data) {
	console.log("Grid.notEquals    filter: " + JSON.stringify(filter));
	console.log("Grid.notEquals    FILTERING FOR " + filter.field + " = " + filter.value);

	var newData = [];
	for ( var i = 0; i < data.length; i++ )	 {
		if ( data[i][filter.field] != filter.value ) {
			newData.push(data[i]);
		}
	}
	console.log("Grid.notEquals    RETURNING newData: ");
	console.dir({newData:newData});
	
	return newData;	
},
greaterThan : function (filter, action, data) {
	
},
lessThan : function (filter, action, data) {
	
},
greaterThanOrEqual : function (filter, action, data) {
	
},
lessThanOrEqual : function (filter, action, data) {
	
},
contains : function (filter, action, data) {
	
},
notContains : function (filter, action, data) {
	
},
// UTIL
setGrid : function (data) {
	console.group("Grid-" + this.id + "    setGrid");
	//console.log("Grid.setGrid    data: ");
	//console.dir({data:data});
	
	this.clear();

	//var StandardGrid = declare([Grid, Selection, Keyboard, Hider, Resizer]);
	var StandardGrid = declare([Grid, Selection, Keyboard, Hider]);
	//console.log("Grid.setGrid    StandardGrid:");
	//console.dir({StandardGrid:StandardGrid});
	
	var store = this.setDataStore(data);

	var div = dojo.create('div');
	this.gridAttachPoint.appendChild(div);
	
	this.grid = new StandardGrid({
		store: store,
		columns: this.getColumns()
	}, div);
	this.grid.startup();

	var checkboxes = query(".field-Download");
	this.setCheckboxListeners(checkboxes);

	console.groupEnd("Grid-" + this.id + "    setGrid");
},
setCheckboxListeners : function (checkboxes) {
	//console.log("Grid.setCheckboxListeners    checkboxes: " + checkboxes);
	//console.dir({checkboxes:checkboxes});

	var thisObj =	this;	
	for ( var i = 0; i < checkboxes.length; i++ ) {
		var checkbox	=	checkboxes[i];
		
		on(checkbox, "mouseup", function() {
			//console.log("Grid.setCheckboxListeners    checkbox: " + checkbox);
			//console.dir({checkbox:checkbox});
			//console.log("Grid.setCheckboxListeners    thisObj.grid: " + thisObj.grid);
			//console.dir({thisObj_grid:thisObj.grid});
			var row = thisObj.grid.view.findRowIndex(checkbox);
			//console.log("Grid.setCheckboxListeners    row: " + row);
			//console.dir({row:row});
			var record = thisObj.grid.store.getAt(row);
			//console.log("Grid.setCheckboxListeners    record: " + record);
			//console.dir({record:record});

			
		});
	
		
	}
	
	//onMouseDown : function(e, t){
	//		if(t.className && t.className.indexOf('x-grid3-cc-'+this.id) != -1) {
	//			var row = this.grid.view.findRowIndex(t);
	//			var col = this.grid.view.findCellIndex(t);
	//			var r = this.grid.store.getAt(row);
	//			var field = this.grid.colModel.getDataIndex(col);
	//			var xe = {
	//				grid: this.grid,
	//				record: r,
	//				field: field,
	//				value: r.data[field],
	//				row: row,
	//				column: col,
	//				cancel:false
	//			};
	//			
	//			if(this.grid.fireEvent("beforeedit", xe, this.grid) !== false && xe.cancel !== true) {
	//				e.stopEvent();
	//				var index = this.grid.getView().findRowIndex(t);
	//				var record = this.grid.store.getAt(index);
	//				record.set(this.dataIndex, !record.data[this.dataIndex]);
	//				xe.value = record.data[this.dataIndex];
	//				this.grid.fireEvent("afteredit", xe, this.grid)
	//			}
	//		}
	//	},
},
clear : function () {
	//console.log("Grid.clear    BEFORE this.grid:");
	//console.dir({this_grid:this.grid});
	
	if ( this.grid ) {
		if ( this.grid.containerNode && this.grid.containerNode.parentNode ) {
			this.grid.containerNode.parentNode.removeChild(this.grid.containerNode);
		}
		this.grid.destroy();
	}

	//console.log("Grid.clear    AFTER grid:");
	//console.dir({this_grid:this.packageApps});

	this.grid = null;
},
setDataStore : function (data) {
	//console.log("Grid.setDataStore");
	
	// ADD DATA TO DATA STORE
	this.dataStore = new Observable(new DataStore({
		data : data
	}));
	this.dataStore.startup();
	//console.log("Grid.setDataStore    this.dataStore:");
	//console.dir({this_core_dataStore:this.dataStore});
	
	return this.dataStore;
},
getColumns : function (){
	// declare columns as an object hash (key translates to field)
	return {	
		'Select'		:	Editor({name: "CheckBox", field: "Download"}, "checkbox"),
		'Details'		:	{ field: "Details", hidden: true },
		'Source'		:	{ label: "Source", hidden: false },
		'AnalysisID'	:	{ label: "Analysis ID", hidden: true },
		'Disease'		:	{ label: "Disease", hidden: false },
		'Study'			:	{ label: "Study", hidden: true },
		'Strategy'		:	{ label: "Strategy", hidden: true },
		'Platform'		:	{ label: "Platform", hidden: true },
		'ParticipantID':	{ label: "Participant ID", hidden: true },
		'State'			:	{ label: "State", hidden: true },
		'ModifiedDate'	:	{ label: "Modified Date", hidden: true },
		'AnalysisURI'	:	{ label: "Analysis URI", hidden: true },
		'filename'		:	{ label: "File Name", hidden: false },
		'filesize'		:	{ label: "File Size", hidden: false },
		'UploadDate'	:	{ label: "Upload Date", hidden: false },
		'PublishedDate':	{ label: "Published Date", hidden: true }
	};
},
attachPane : function () {
	//console.log("Grid.constructor    this.attachPoint: " + this.attachPoint);
	//console.log("Grid.constructor    this.containerNode: " + this.containerNode);
		
	if ( this.attachPoint.selectChild ) {
		//console.log("Grid.attachPane    DOING this.addChild(this.containerNode)");
		this.attachPoint.addChild(this.containerNode);
		this.attachPoint.selectChild(this.containerNode);
	}
	else {
		//console.log("Grid.attachPane    DOING this.appendChild(this.containerNode)");
		this.attachPoint.appendChild(this.containerNode);
	}
}

}); //	end declare

});	//	end define

console.log("plugins.request.Grid    END");
