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
	"dgrid/extensions/Pagination",
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
	Pagination,
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

// fields : ArrayRef
//		Array of field options
fields : null,

// cssFiles: Array
// CSS FILES
cssFiles : [
	require.toUrl("plugins/request/css/grid.css"),
	require.toUrl("dgrid/css/dgrid.css"),
	require.toUrl("plugins/dnd/css/dnd.css"),
	require.toUrl("dgrid/css/extensions/ColumnHider.css")
],

// url: String
//		URL of Request server
url: "http://reqapi.annairesearch.com:8080/api/SubmitQuery.req",

// data : ArrayRef
//		Data to load into Grid
data : null,

// attachPoint : DIV element
//		Attach widget template to this element
attachPoint : null,

////}}}
constructor : function(args) {	
	////console.log("Grid.constructor    args:");
	////console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	
	////console.log("Grid.constructor    this.url: " + this.url);
	
	// LOAD CSS FILES
	this.loadCSS(this.cssFiles);		
},
postCreate: function() {
	this.startup();
},
// STARTUP
startup : function () {

	////console.group("Grid-" + this.id + "    startup");
	////console.log("Grid.startup    this.data.length: " + this.data.length);
	////console.dir({this_data:this.data});
	
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

	////console.groupEnd("Grid-" + this.id + "    startup");
},
// UPDATE GRID WITH FILTERS
updateGrid : function (filters) {
	//console.group("Grid-" + this.id + "    updateGrid");

	//console.log("Grid.updateGrid    filters.length: " + filters.length);
	//console.log("Grid.updateGrid    filters: ");
	//console.dir({filters:filters});
	
	var newData = [];
	var initialised = 0;
	//console.log("Grid.updateGrid    BEGIN newData: ");
	//console.dir({newData:newData});
	//console.log("Grid.updateGrid    BEGIN newData.length: " + newData.length);
	
	if ( ! this.data || this.data.length == 0 ) return;
	
	for ( var i = 0; i < filters.length; i++ ) {
		var filter	=	filters[i];
		//console.log("Grid.updateGrid    filter: " + JSON.stringify(filter));
		//console.log("Grid.updateGrid    newData.length: " + newData.length);
		//console.dir({newData:newData});
		
		if ( newData.length == 0
			&& filter.action == "AND"
			&& ! initialised ) {
			newData = dojo.clone(this.data);
			initialised = 1;
		}
		
		if ( filter.action == "AND" ) {
			//console.log("Grid.updateGrid    DOING 'AND' filter: ");
			//console.dir({filter:filter});
			
			newData = this.filterData(filter, newData);
			//console.log("Grid.updateGrid    DOING 'AND' newData: ");
			//console.dir({newData:newData});
		}
		else if ( filter.action == "OR" ) {
			//console.log("Grid.updateGrid    DOING 'OR' filter: ");
			//console.dir({filter:filter});
			
			var orData = dojo.clone(this.data);
			//console.log("Grid.updateGrid    BEGIN orData.length: " + orData.length);
			orData	=	this.filterData(filter, orData);
			//console.log("Grid.updateGrid    AFTER orData.length: " + orData.length);
			//console.log("Grid.updateGrid    orData: ");
			//console.dir({orData:orData});
	
			if ( orData && orData.length != 0 ) {
				newData = this.addNoDups(newData, orData);
			}
		}
		else {
			//console.log("Grid.updateGrid    SKIPPING filter.action neither 'AND' nor 'OR': " + filter.action);
		}
	}
	//console.log("Grid.updateGrid    FINAL newData.length: " + newData.length);
	//console.log("Grid.updateGrid    FINAL newData: ");
	//console.dir({newData:newData});

	this.setGrid(newData);

	//console.groupEnd("Grid-" + this.id + "    updateGrid");
},
addNoDups : function (hasharray1, hasharray2) {
	//console.log("Grid.addNoDups    hasharray1.length: " + hasharray1.length);
	//console.log("Grid.addNoDups    hasharray2.length: " + hasharray2.length);

	if ( hasharray1.length > hasharray2.length ) {
		return this.addArraysNoDups(hasharray1, hasharray2);
	}
	else {
		return this.addArraysNoDups(hasharray2, hasharray1);
	}
},
addArraysNoDups : function (hasharray1, hasharray2) {
	var array = [];
	array = array.concat(hasharray1);
	
	if ( array.length == 0 ) {
		//console.log("Grid.addArrayNoDups    hasharray1 empty. RETURNING hasharray2");
		return hasharray2;
	}
	
	//var offset = 0;
	for ( var i = 0; i < hasharray2.length; i++ ) {
		var found = 0;
		for ( var j = 0; j < array.length; j++ ) {
			//console.log("Grid.addArrayNoDups    Comparing hasharray2[" + i + "]['filename']: " + hasharray2[i]["filename"] + " with array[j]['filename']: " +  array[j]["filename"]);

			if ( array[j]["filename"] == hasharray2[i]["filename"]) {
				found = 1;
				//console.log("Grid.addArrayNoDups    SKIPPING hasharray2[" + i + "]");
				break;
			}
		}
		if ( ! found ) {
			array.push(hasharray2[i]);
		}

		//offset = i;
	}
	//console.log("Grid.addArrayNoDups    RETURNING array.length: " + array.length);
	
	return array;
},
filterData : function (filter, data) {
	////console.group("Grid-" + this.id + "    filterData");
	////console.log("Grid.filterData    filter: " + JSON.stringify(filter));
	////console.log("Grid.filterData    data: ");
	////console.dir({data:data});
	if ( filter.field == "ALL" ) {
		return this.all(filter, data);
	}
	
	////console.log("Grid.filterData    BEFORE FILTER, filter: " + JSON.stringify(filter));
	switch (filter.operator) {
		case "before" 	:	return this.before(filter, data); break;
		case "after" 	:	return this.after(filter, data); break;
		case "on" 		:	return this.on(filter, data); break;
		case "is" 		:	return this.is(filter, data); break;
		case "is not" 	:	return this.isNot(filter, data); break;
		case "contains" :	return this.contains(filter, data); break;
		case "NOT contains": 	return this.notContains(filter, data); break;
		case "==" 		:	return this.equals(filter, data); break;
		case "!=" 		:	return this.notEquals(filter, data); break;
		case ">" 		:	return this.greaterThan(filter, data); break;
		case "<" 		:	return this.lessThan(filter, data); break;
		case ">=" 		:	return this.greaterThanOrEqual(filter, data); break;
		case "<=" 		:	return this.lessThanOrEqual(filter, data); break;
	}
	////console.log("Grid.filterData    AFTER FILTER, filter: " + JSON.stringify(filter));
	
	////console.groupEnd("Grid-" + this.id + "    filterData");

	return [];
},
// FILTERS
loopFunction : function(filter, data, callback) {
	//////console.log("Grid.loopFunction    filter: " + JSON.stringify(filter));
	//////console.log("Grid.loopFunction    data.length: " + data.length);
	var newData = [];
	for ( var i = 0; i < data.length; i++ )	 {
		//////console.log("Grid.loopFunction    data[" + i + "][" + filter.field + "]: " + data[i][filter.field]);
		//////console.log("Grid.loopFunction    filter.value: " + filter.value);

		if ( callback(data[i][filter.field], filter.value) ) {
			
			//////console.log("Grid.loopFunction    PUSHING data[" + i + "]: " + JSON.stringify(data[i]));
			newData.push(data[i]);
		}
	}
	//////console.log("Grid.loopFunction    RETURNING newData: ");
	//////console.dir({newData:newData});
	
	return newData;
},
all : function (filter, data) {
	////console.log("Grid.all    filter: " + JSON.stringify(filter));
	//console.log("Grid.all    filter.value: " + filter.value);
	//console.log("Grid.all    data: ");
	//console.dir({data:data});
	////console.log("Grid.all    this.fields: ");
	////console.dir({this_fields:this.fields});
	
	var newData = [];
	for ( var i = 0; i < data.length; i++ )	 {

		for ( var j = 0; j < this.fields.length; j++ )	 {
			var field	=	this.fields[j];
			////console.log("Grid.all    data[" + i + "][" + field + "]: " + data[i][field]);
			////console.log("Grid.all    filter.value: " + filter.value);
			
			if ( data[i][field].toString().toLowerCase().match(filter.value.toString().toLowerCase()) ) {
				////console.log("Grid.all    PUSHING data[" + i + "]: " + JSON.stringify(data[i]));
				newData.push(data[i]);
				////console.log("Grid.all    BEFORE break");
				break;
			}
		}
	}
	//console.log("Grid.all    RETURNING newData.length: " + newData.length);
	//console.dir({newData:newData});
	
	return newData;
},
is : function (filter, data) {
	////console.log("Grid.is    filter: " + JSON.stringify(filter));

	var callback = function(input1, input2) {
		if ( input1.toLowerCase() == input2.toLowerCase() )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);
},
isNot : function (filter, data) {
	////console.log("Grid.isNot    filter: " + JSON.stringify(filter));
	////console.log("Grid.isNot    data.length: " + data.length);

	var callback = function (input1, input2) {
		if ( input1.toLowerCase() != input2.toLowerCase() ) {
			////console.log("Grid.isNot    RETURNING 1");
			return 1;
		}
		else return 0;
	};

	return this.loopFunction(filter, data, callback);	
},
before : function (filter, data) {
	var callback = function(input1, input2) {
		var date1 = new Date(input1);

		// date1 REMOVE HOURS, MINS AND SECS
		date1.setHours(0, 0, 0, 0);
		
		var date2 = new Date(input2);

		// NORMALIZE TIME ZONE
		var offset = date1.getTimezoneOffset();
		date2.setUTCHours(date2.getUTCHours() + (offset/60 || 0));

		var difference	=	(date1 - date2);

		if ( difference < 0 ) {
			return 1;
		}
		else {
			return 0;
		}
	}

	return this.loopFunction(filter, data, callback);	
},
on : function (filter, data) {
	var callback = function(input1, input2) {
		var date1 = new Date(input1);

		// date1 REMOVE HOURS, MINS AND SECS
		date1.setHours(0, 0, 0, 0);
		
		var date2 = new Date(input2);

		// NORMALIZE TIME ZONE
		var offset = date1.getTimezoneOffset();
		date2.setUTCHours(date2.getUTCHours() + (offset/60 || 0));

		var difference	=	(date1 - date2);
		if ( difference == 0 ) {
			return 0;
		}
		else {
			return 1;
		}
	}

	return this.loopFunction(filter, data, callback);	
},
after : function (filter, data) {
	var callback = function(input1, input2) {
		var date1 = new Date(input1);

		// date1 REMOVE HOURS, MINS AND SECS
		date1.setHours(0, 0, 0, 0);

		// NORMALIZE TIME ZONE
		var offset = date1.getTimezoneOffset();
		var date2 = new Date(input2);
		date2.setUTCHours(date2.getUTCHours() + (offset/60 || 0));

		var difference	=	(date1 - date2);
		if ( difference < 1 ) {
			
			return 0;
		}
		else return 1;
	}

	return this.loopFunction(filter, data, callback);	
},
equals : function (filter, data) {
	var callback = function(input1, input2) {
		if ( parseInt(input1) == parseInt(input2) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);
},
notEquals : function (filter, data) {
	var callback = function(input1, input2) {
		if ( parseInt(input1) != parseInt(input2) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);
},
greaterThan : function (filter, data) {
	var callback = function(input1, input2) {
		if ( parseInt(input1) > parseInt(input2) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);	
},
lessThan : function (filter, data) {
	var callback = function(input1, input2) {
		if ( parseInt(input1) < parseInt(input2) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);	
},
greaterThanOrEqual : function (filter, data) {
	var callback = function(input1, input2) {
		if ( parseInt(input1) >= parseInt(input2) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);	
},
lessThanOrEqual : function (filter, data) {
	var callback = function(input1, input2) {
		if ( parseInt(input1) <= parseInt(input2) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);	
},
contains : function (filter, data) {
	var callback = function(input1, input2) {
		if ( input1.toLowerCase().match(input2.toLowerCase()) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);
},
notContains : function (filter, data) {
	var callback = function(input1, input2) {
		if ( ! input1.toLowerCase().match(input2.toLowerCase()) )  {
			return 1;
		}
		else return 0;
	}

	return this.loopFunction(filter, data, callback);	
},
// UTIL
setGrid : function (data) {
	console.group("Grid-" + this.id + "    setGrid");
	console.log("Grid.setGrid    data: ");
	console.dir({data:data});
	console.log("Grid.setGrid    this.grid: ");
	console.dir({this_grid:this.grid});
	console.log("Grid.setGrid    this.attachPoint: ");
	console.dir({this_attachPoint:this.attachPoint});
	
	//this.clear();

	//var StandardGrid = declare([Grid, Selection, Keyboard, Hider, Resizer]);
	var StandardGrid = declare([Grid, Selection, Keyboard, Hider]);
	console.log("Grid.setGrid    StandardGrid:");
	console.dir({StandardGrid:StandardGrid});	
	
	if ( ! this.grid ) {
		console.log("Grid.setGrid    CREATING this.grid");

		var store = this.setDataStore(data);
		console.log("Grid.setGrid    store:");
		console.dir({store:store});
	
		var div = dojo.create('div');
		this.gridAttachPoint.appendChild(div);

		this.grid = new (declare([StandardGrid, Pagination]))({
			pagingLinks: 1,
			pagingTextBox: true,
			firstLastArrows: true,
			pageSizeOptions: [10, 15, 25, 50, 100, 150],
			attachPoint : this.attachPoint,
			store: store,
			columns: this.getColumns()
		}, div);

		var checkboxes = query(".field-Download");
		this.setCheckboxListeners(checkboxes);

		//this.grid.startup();
		//this.grid.renderArray(data);
		this.dataStore.startup();
		this.grid.refresh();
	}
	else {
		console.log("Grid.setGrid    this.grid.store:");
		console.dir({this_grid_store:this.grid.store});
		console.log("Grid.setGrid    DOING this.grid.renderArray(data)");
		//this.grid.renderArray(data);
		//console.log("Grid.setGrid    DOING this.grid.store.data = data");
		this.grid.store.data = data;
		this.dataStore.startup();
		this.grid.refresh();
	}

	//this.grid.startup();

	console.groupEnd("Grid-" + this.id + "    setGrid");
},
setCheckboxListeners : function (checkboxes) {
	//////console.log("Grid.setCheckboxListeners    checkboxes: " + checkboxes);
	//////console.dir({checkboxes:checkboxes});

	var thisObj =	this;	
	for ( var i = 0; i < checkboxes.length; i++ ) {
		var checkbox	=	checkboxes[i];
		
		on(checkbox, "mouseup", function() {
			//////console.log("Grid.setCheckboxListeners    checkbox: " + checkbox);
			//////console.dir({checkbox:checkbox});
			//////console.log("Grid.setCheckboxListeners    thisObj.grid: " + thisObj.grid);
			//////console.dir({thisObj_grid:thisObj.grid});
			var row = thisObj.grid.view.findRowIndex(checkbox);
			//////console.log("Grid.setCheckboxListeners    row: " + row);
			//////console.dir({row:row});
			var record = thisObj.grid.store.getAt(row);
			////console.log("Grid.setCheckboxListeners    record: " + record);
			////console.dir({record:record});
		});
	}
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
	//console.dir({this_grid:this.grid});

	this.grid = null;
},
setDataStore : function (data) {
	//////console.log("Grid.setDataStore");
	
	// ADD DATA TO DATA STORE
	this.dataStore = new Observable(new DataStore({
		data : data
	}));
	this.dataStore.startup();
	//////console.log("Grid.setDataStore    this.dataStore:");
	//////console.dir({this_core_dataStore:this.dataStore});
	
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
	//////console.log("Grid.constructor    this.attachPoint: " + this.attachPoint);
	//////console.log("Grid.constructor    this.containerNode: " + this.containerNode);
		
	if ( this.attachPoint.selectChild ) {
		//////console.log("Grid.attachPane    DOING this.addChild(this.containerNode)");
		this.attachPoint.addChild(this.containerNode);
		this.attachPoint.selectChild(this.containerNode);
	}
	else {
		//////console.log("Grid.attachPane    DOING this.appendChild(this.containerNode)");
		this.attachPoint.appendChild(this.containerNode);
	}
},
// TESTING
getItems : function () {
	////console.log("Grid.getItems    this.grid: " + this.grid);
	////console.dir({this_grid:this.grid});
	
	return this.grid.store.data;
}

}); //	end declare

});	//	end define

