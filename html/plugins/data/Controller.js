dojo.provide("plugins.data.Controller");

// OBJECT:  plugins.data.Controller
// PURPOSE: LOAD, STORE AND PROVIDE ACCESS TO DATA

// CONTAINER
dojo.require("plugins.core.Common");

// GLOBAL VARIABLE
//var Data = new Object;

// HAS
//dojo.require("plugins.data.Data");

dojo.declare( "plugins.data.Controller",
	[ plugins.core.Common ],
{

name : "plugins.data.Controller",
version : "0.01",
description : "Load data from remote host",
url : '',
dependencies : [],

// data : object
// Hash for all data tables
data: null,

////}}}
// CONSTRUCTOR	
constructor : function(args) {
	console.log("data.Controller.constructor     plugins.data.Controller.constructor");
	this.startup();
},
startup : function () {
	console.log("data.Controller.startup    Data.data: ");
	console.dir({data:Data.data});
	
	if ( Data != null )
	{
		if ( Data.data != null )
		{
			console.log("data.Controller.startup    Data.data: ");
			console.dir({data:Data.data});

			this.data = Data.data;
			Agua.data = Data.data;
		}
		else
			this.getData();
	}
	else
		this.getData();

	Data = this;	
},
getData : function() {
// LOAD ALL DATA, INCLUDING SHARED PROJECT DATA
	console.log("data.Controller.getData    plugins.data.Controller.getData()");		
	console.log("data.Controller.getData    Agua.dataUrl: " + Agua.dataUrl);
	
    if ( Agua.dataUrl != null )	return this.fetchJsonData();

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
    if ( Agua.database )
        query.database 	= Agua.database;
	query.mode 			= 	"getData";
	query.module 		= 	"Agua::Workflow";
	
	console.log("data.Controller.getta    query: ");
	console.dir({query:query});

	if ( Data == null )
		Data = new Object;


	Agua.exchange.send(query);
	
	var thisObject = this;
	dojo.xhrPut(
		{
			url: url,
			putData: dojo.toJson(query),
			handleAs: "json",
			//handleAs: "json-comment-optional",
			preventCache : true,
			sync: true,
			load: function(response, ioArgs) {

				//console.log("data.Controller.getData    response: ", dojo.toJson(response));

				if ( response.error )
				{
					Agua.error(response.error);
				}
				else
				{
					Data.data = response;
					thisObject.data = response;
					Agua.data = response;
					console.log("data.Controller.getData    BEFORE thisObject.responseToData(response)");
					//thisObject.responseToData(response);

					// DISPLAY VERSION
					Agua.displayVersion();
				}
			},
			error: function(response, ioArgs) {
				console.log("Error with JSON Post, response: " + dojo.toJson(response) + ", ioArgs: " + dojo.toJson(ioArgs));
			}
		}
	);

	// DISABLE 
	if ( this.testing )
	{
		Agua.cgiUrl = "../";
	}

	return null;
},
fetchJsonData : function() {
	console.log("data.Controller.fetchJsonData    plugins.data.Controller.fetchJsonData()");		

	// GET URL 
    var url = Agua.dataUrl 
	console.log("data.Controller.fetchJsonData    url: " + url);

	console.log("data.Controller.fetchJsonData    DOING dojo.xhrGet");
	
    var thisObject = this;
    dojo.xhrGet({
        // The URL of the request
        url: url,
        sync: true,
		// Handle as JSON Data
		// chrome: handle as text, convert to JSON
        handleAs: "json",
        // The success callback with result from server
//        load: function(text) {
//			var response = dojo.fromJson(response)
        load: function(response) {

			//console.log("data.Controller.fetchJsonData    response: ", dojo.toJson(response));
			console.log("data.Controller.fetchJsonData    response: ");
			console.dir({response:response});

			if ( Data != null )
				Data.data = response;
			Agua.data = response;
			//thisObject.responseToData(response);
        },
        // The error handler
        error: function() {
			Agua.error("Failed to fetch data");
        }
    });
},
getTable : function(table) {
// LOAD ALL AGUA DATA FOR THIS USER, INCLUDING SHARED PROJECT DATA

	console.log("data.Controller.getTable    plugins.data.Controller.getTable(table)");		
	console.log("data.Controller.getTable    table: " + table);

    if ( Agua.dataUrl != null )
    {
		console.log("data.Controller.getTable    Agua.dataUrl: " + Agua.dataUrl);
		console.log("data.Controller.getTable    Agua.dataUrl not null. Doing return this.fetchJsonData()");
        return this.fetchJsonData();
    }

	// GET URL 
	var url = Agua.cgiUrl + "agua.cgi";
	//console.log("data.Controller.getTable    url: " + url);		

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query = new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
    if ( this.database != null )
        query.database 	= this.database;
	query.mode 			= 	"getTable";
	query.module 		= 	"Agua::Workflow";
	query.table 		= 	table;
	console.log("data.Controller.getTable    query: " + dojo.toJson(query, true));

	var thisObject = this;
	dojo.xhrPut(
		{
			url: url,
			putData: dojo.toJson(query),
			handleAs: "json",
			//handleAs: "json-comment-optional",
			sync: true,
			load: function(response, ioArgs) {
				console.log("data.Controller.JSON Post worked.");
				if ( response.error )
				{
					console.log("data.Controller.getTable    xhrPut error: " + response.error);
				}
				else
				{
					thisObject.responseToData(response);
					//for ( var key in response )
					//{
					//	console.log("data.Controller.getTable    storing key: " + key);
					//	thisObject[key] = response[key];
					//}
				}
			},
			error: function(response, ioArgs) {
				console.log("data.Controller.Error with JSON Post, response: " + response + ", ioArgs: " + ioArgs);
			}
		}
	);
	//console.log("data.Controller.getTable    this.headings: " + dojo.toJson(this.headings));
},
responseToData : function (response) {
	console.log("data.Controller.responseToData    response: " + response);
	console.log("data.Controller.responseToData    response: " + dojo.toJson(response));
	var keys = this.hashkeysToArray(response);
	keys.sort();
	var thisObject = this;
	dojo.forEach(keys, function(key){
		console.log("data.Controller.getData    storing key: " + key);
		Agua.data[key] = response[key];
	});
},
destroyRecursive : function () {
	dojo.destroy(this);
}


}); // end of Controller

