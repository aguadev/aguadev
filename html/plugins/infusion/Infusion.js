define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/on",
	"dojo/when",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/registry",
	"dojo/json",
	"plugins/infusion/Data",
	"dojo/store/Observable",
	"plugins/infusion/DataStore",
	"plugins/infusion/Lists",
	"plugins/infusion/Search",
	"plugins/infusion/Details",
	"plugins/infusion/Dialogs",
	"plugins/exchange/Exchange",
	"plugins/core/Common",
	//"dojox/io/windowName",
	//"plugins/graph/Graph",
	"dojo/ready",
	"dojo/domReady!",
	
	"plugins/dojox/layout/ExpandoPane",
	"dijit/TitlePane",
	"dijit/_Widget",
	"dijit/_Templated",

	"dojox/layout/ExpandoPane",
	"dojo/data/ItemFileReadStore",
	"dojo/store/Memory",
	"dijit/layout/AccordionContainer",
	"dijit/layout/TabContainer",
	"plugins/dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojox/layout/ContentPane",
	"dojox/layout/FloatingPane",
	"dijit/layout/BorderContainer",
	"dijit/form/Button"
],

function (declare, arrayUtil, on, when, lang, domAttr, domClass, registry, JSON, Data, Observable, DataStore, Lists, Search, Details, Dialogs, Exchange, Common, ready) {

////}}}}}

return declare("plugins.infusion.Infusion",[dijit._Widget, dijit._Templated, Common], {

// Path to the template of this widget. 
// templatePath : String
templatePath : require.toUrl("plugins/infusion/templates/infusion.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// core: Hash
// { files: XxxxxFiles object, infusion: Infusion object, etc. }
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
	
	//,
	//dojo.moduleUrl("https://da1s119xsxmu0.cloudfront.net/libraries/bootstrap/1.3.3/bootstrap.min.css")
],

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

//////}}
constructor : function(args) {		
	console.log("Infusion.constructor    args:");
	console.dir({args:args});

	// SET Infusion GLOBAL
	Infusion = this;
	
	if ( ! args )	return;
	
	// DEFAULT ATTACH WIDGET (OVERRIDE IN args FOR TESTING)
	this.attachPoint = Agua.tabs;	

    // MIXIN ARGS
    lang.mixin(this, args);

	// SET CORE
	this.core = new Object;
	this.core.infusion = this;

	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "agua.cgi";

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Infusion.postCreate    plugins.infusion.Infusion.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Infusion.startup    plugins.infusion.Infusion.startup()");
	if ( ! this.attachPoint ) {
		console.log("Infusion.startup    this.attachPoint is null. Returning");
		return;
	}
	
	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	// ADD PANE TO CONTAINER
	this.attachPane();
	
	// SET DATA
	this.core.data = this.setData();
	
	// SET DATASTORE
	this.core.dataStore = this.setDataStore();
	
	// SET EXCHANGE 
	this.core.exchange = this.setExchange();
	
	// SET UPLOADER
	this.core.dialogs = this.setDialogs();
	
	// SET SEARCH
	this.core.search = this.setSearch();
	
	// SET LISTS
	this.core.lists = this.setLists();	
	
    // SET DETAILS PANES
    this.core.details = this.setDetails();
},
// ATTACH PANE
attachPane : function () {

	console.log("Infusion.attachPane    caller: " + this.attachPane.caller.nom);
	console.log("Infusion.attachPane    this.mainTab: " + this.mainTab);
	console.dir({this_mainTab:this.mainTab});
	console.log("Infusion.attachPane    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
		
	if ( this.attachPoint.addChild ) {
		this.attachPoint.addChild(this.mainTab);
		this.attachPoint.selectChild(this.mainTab);
	}
	if ( this.attachPoint.appendChild ) {
		this.attachPoint.appendChild(this.mainTab.domNode);
	}
},
// DATA
setData : function () {
	console.log("Infusion.setData");

	this.core.data = new Data({
		core : this.core
	});

	// POPULATE this.storedHashes FOR EASY LOOKUP LATER
	this.core.data.refreshData();

	return this.core.data;
},
// DATASTORE
setDataStore : function () {
	console.log("Infusion.setDataStore");
	
	// ADD DATA TO DATA STORE
	this.core.dataStore = new Observable(new DataStore({
		core : this.core
	}));
	this.core.dataStore.startup();
    //this.core.dataStore.setData(this.core.data);
	console.log("Infusion.startup    this.core.dataStore:");
	console.dir({this_core_dataStore:this.core.dataStore});
	
	return this.core.dataStore;
},
// SEARCH
setSearch : function () {
	console.log("Infusion.setSearch");
	this.core.search = new plugins.infusion.Search({
		core		:	this.core,
		attachPoint:	this.leftTabContainer
	});

	return this.core.lists;	
},
// LISTS
setLists : function () {
	console.log("Infusion.setLists");
	console.log("Infusion.setLists    this.leftTabContainer:");
	console.dir({this_leftTabContainer:this.leftTabContainer});
	
	this.core.lists = new plugins.infusion.Lists({
		core		:	this.core,
		attachPoint:	this.leftTabContainer
	});

	return this.core.lists;
},
// DETAILS PANES
setDetails : function () {	
	
	// START UP TAB CONTAINER
	this.centerTabContainer.startup();
	console.log("Infusion.setDetails    this.centerTabContainer: " + this.centerTabContainer);
	console.dir({this_centerTabContainer:this.centerTabContainer});	
	
	this.core.details = new Details({
		core : this.core,
		attachPoint :	this.centerTabContainer
	});
	this.core.details.startup();
	
	return this.core.details;
},
showDetails : function (type, name) {
	console.log("Infusion.showDetails    type: " + type);
	console.log("Infusion.showDetails    name: " + name);

	this.core.details.show(type, name)
},
// DIALOG PANES
setDialogs : function () {	
	
	// START UP TAB CONTAINER
	this.centerTabContainer.startup();
	console.log("Infusion.setDialogs    this.centerTabContainer: " + this.centerTabContainer);
	console.dir({this_centerTabContainer:this.centerTabContainer});	
	
	this.core.dialogs = new Dialogs({
		core 		: 	this.core,
		attachPoint :	this.centerTabContainer
	});
	this.core.dialogs.startup();
	
	return this.core.dialogs;
},
// EXCHANGE
setExchange : function () {
// Listen and respond to socket.IO messages
	console.log("Infusion.setExchange");

	// SET TOKEN
	this.core.token = this.getToken();

	// INSTANTIATE EXCHANGE...
	var promise = when(this.core.exchange = new Exchange({}));
	console.log(".......................... Infusion.setExchange    this.core.exchange:");
	console.dir({this_exchange:this.core.exchange});

	//// ... THEN CONNECT
	//promise.then(this.core.exchange.connect());

	//// SET onMessage LISTENER
	var thisObject = this;
	this.core.exchange.onMessage = function (json) {
		console.log("Infusion.setExchange    this.core.exchange.onMessage FIRED    json:");
		console.dir({json:json});
		var data = JSON.parse(json);
		
		thisObject.onMessage(data);
	};
	
	try {
		this.core.exchange.connect();
	} catch(e) {
		console.log("Infusion.setExchange    *** CAN'T CONNECT TO SOCKET ***");;
	}
	
	//// CONNECT
	//var thisObject = this;
	//setTimeout(function(){
	//	thisObject.core.exchange.connect();
	//},
	//1000);	

	return this.core.exchange;
},
getToken : function () {
	this.token = this.randomString(16, 'aA#');
	console.log("Infusion.getToken    this.token: " + this.token);
},
getTaskId : function () {
	return this.randomString(16, 'aA');
},
randomString : function (length, chars) {
    var mask = '';
    if (chars.indexOf('a') > -1) mask += 'abcdefghijklmnopqrstuvwxyz';
    if (chars.indexOf('A') > -1) mask += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (chars.indexOf('#') > -1) mask += '0123456789';
    if (chars.indexOf('!') > -1) mask += '~`!@#$%^&*()_+-={}[]:";\'<>?,./|\\';
    var result = '';
    for (var i = length; i > 0; --i) result += mask[Math.round(Math.random() * (mask.length - 1))];
    return result;
},
onMessage : function (message) {

// summary:
//		Process the data in the client based on the type of message queue, whether the
//		client is the original sender, filtering by topic pattern, etc.
//		The following inputs are required:
//			queue		:	Type of message queue: fanout, routing, publish, topic and request
//				fanout	:	Run callback on all clients except the sender
//				routing	:	Run callback only in the sender client
//				publish	:	Run callback in all clients that have subscribed to the topic
//				topic	:	Run callback in all clients that pattern match the topic
//				request	:	Ignore (destined for server)
//			token		:	Token of the originating client
//			callback	:	Function to be called
//			data		:	A data hash to be passed to the callback function
//
//		NB: The above queues will be gradually implemented and may be changed or added to
//

	console.log("Infusion.onMessage    message: " + message);
	console.dir({message:message});

	// GET INPUTS	
	var queue =	message.queue;
	var sender = false;
	if ( message.token == this.token )	sender = true;	
	var callback	=	message.callback;	
	console.log("Infusion.onMessage    queue: " + queue);
	console.log("Infusion.onMessage    sender: " + sender);
	console.log("Infusion.onMessage    callback: " + callback);
	
	if ( sender && queue == "fanout" ) return;
	if ( sender && queue == "routing" ) {
		console.log("Infusion.onMessage    DOING this[" + callback + "](message)");
		this[callback](message);
	}
},
// BOTTOM PANE
updateBottomPane : function (type, name) {
	console.log("Infusion.updateBottomPane    type: " + type);
	console.log("Infusion.updateBottomPane    name: " + name);
	console.log("Infusion.updateBottomPane    bottomPane: ");
	console.dir({this_bottomPane:this.bottomPane});
	console.log("Infusion.updateBottomPane.iconNode    bottomPane.iconNode: ");
	console.dir({this_bottomPane_iconNode:this.bottomPane.iconNode});

	// OPEN IF CLOSED
	if ( ! this.bottomPane._showing ) {
		this.bottomPane.iconNode.click();
	}
	
	// SET TAB NAME
	var moduleName = type.substring(0,1).toUpperCase() + type.substring(1);
	console.log("Infusion.updateBottomPane    moduleName: " + moduleName);
	var tabPane = "detailed" + moduleName + "Tab";
	console.log("Infusion.updateBottomPane    tabPane: " + tabPane);
	
	// SELECT TAB
	console.log("Infusion.bottomTabContainer    this.bottomTabContainer: " );
	console.dir({this_bottomTabContainer:this.bottomTabContainer});
	console.log("Infusion.updateBottomPane    this[tabPane]: " );
	console.dir({this_tabPane:this[tabPane]});
	this.bottomTabContainer.selectChild(this[tabPane]);

	// UPDATE GRID
	this["detailed" + moduleName].updateGrid(name);
},
// RIGHT PANE
populateRightPane : function (dataStore) {
	var target = this.graph;
	//var url = "../graph/graph.html";
	//var url = "../../infusiondev/t/plugins/graph/test.html";

	//var jsonFile = "http://localhost/infusiondev/t/plugins/graph/print-data.json";
	var jsonFile = "t/plugins/graph/test1.csv";

	this.loadPane(target, jsonFile);
},
loadPane : function (target, jsonFile) {
	console.log("Infusion.loadPane    target: " + target);
	console.dir({target:target});

	var graph = new Graph();
	//console.log("print    graph: " + graph);
	//console.dir({graph:graph});
	var data = this.fetchSyncJson(jsonFile);
	//console.log("print    data: ");
	//console.dir({data:data});
	
	var text = graph.fetchSyncText(jsonFile);
	var csv = text.split("\n");
	var headers = csv.shift();
	//console.log("print    headers: " + headers);
	
	// LATER: CONFIGURE THIS DYNAMICALLY
	var index1 = 1;
	var index2 = 2;
	var xLabel;
	var yLabel;
	
	// IF THE xLabel AND yLabel ARE NOT PROVIDED AS ARGUMENTS,
	// GET THEM FROM THE CSV HEADER LINE BASED ON THEIR INDEXES
	var xLabel = headers[index1];
	var yLabel = headers[index2];
	
	// SET COLUMNS TO BE EXTRACTED FROM THE FILE BASED ON THEIR INDEXES
	var columns = [index1, index2];
	var values = graph.csvToValues(csv, columns)
	//console.log("print    values: ");
	//console.dir({values:values});
	
	// CONVERT DATE TO UNIX TIME
	for ( var i = 0; i < values.length; i++ ) {
		if ( ! values[i][0] )	continue;
		var array = graph.parseUSDate(values[i][0]);
		
		values[i][0] = ( graph.dateToUnixTime(array[0], array[1], array[2]) ) * 1000;
	}
	
	// JUST REVERSE THE DATA FOR A TEST EXAMPLE
	var values2 = [];
	for ( var i = 0; i < values.length; i++ ) {
		values2[values.length - (i + 1)] = values[i];
	}
	
	var data = [
		{
			key 	: 	"Freq1",
			bar		:	true,
			values	:	values
		}
		,
		{
			key 	: 	"Freq2",
			bar		:	false,
			values	:	values2
		}
	];
	//console.log("print    data: ");
	//console.dir({data:data});
	
	var series = graph.dataToSeries(data);
	//console.log("print    series: ");
	//console.dir({series:series});
	
	graph.print(target, series, "linePlusBarWithFocusChart", "Date", "Freq", "Change in Frequency over Time");
}


}); 	//	end declare

});	//	end define

