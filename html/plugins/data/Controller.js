// CLASS:  plugins.data.Controller
// PURPOSE: LOAD, STORE AND PROVIDE ACCESS TO DATA

define([
	"dojo/_base/declare",
	"plugins/core/Common",
	"dijit/registry",
],

function (
	declare,
	Common,
	registry
) {

///////}}}}}

window.Agua = Agua;

return declare("plugins.login.Login",
	[
	Common
], {

name : "plugins_data_Controller",
version : "0.01",
description : "Load data from remote host",
url : '',
dependencies : [],

loaded: false,

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

	// SET ID
	this.setId();
	
	if ( Data != null )
	{
		if ( Data.data != null ) {
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
setId : function () {
	if ( this.id ) {
		console.log("data.Controller.startup    Returning existing this.id: " + this.id);
		return this.id;
	}
	var name	=	this.name;
	this.id 	= 	registry.getUniqueId(name);
	console.log("data.Controller.startup    this.id: " + this.id);
	console.log("data.Controller.startup    registry: ");
	console.dir({registry:registry});
	registry.add(this);
	
	return this.id;
},
getData : function() {
// LOAD ALL DATA, INCLUDING SHARED PROJECT DATA
	console.log("data.Controller.getData    plugins.data.Controller.getData()");		
	console.log("data.Controller.getData    Agua.dataUrl: " + Agua.dataUrl);
	
    if ( Agua.dataUrl )	return this.fetchJsonData();

	// SEND QUERY
	var query = new Object;
	query.mode 			= 	"getData";
	query.module 		= 	"Agua::Workflow";
	query.sourceid 		= 	this.id;
	query.callback		=	"loadData",
	console.log("data.Controller.getData    query: ");
	console.dir({query:query});

	Agua.exchange.send(query);
},
loadData : function (response) {
	console.log("data.Controller.loadData    response:");
	console.dir({response:response});

	console.log("data.Controller.loadData    this.loaded:" + this.loaded);
	if ( this.loaded == true ) {
		console.log("data.Controller.loadData    this.loaded is true. Returning.");
		return;
	}
	
	if ( response.error ) {
		Agua.error(response.error);
	}
	else {
		Agua.data = response.data;

		// START LOAD PLUGINS
		Agua.startPlugins();
		
		// SET loaded
		this.loaded = true;

		// DISPLAY VERSION
		Agua.displayVersion();
	}
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

	// SEND QUERY
	var query = new Object;
	query.mode 			= 	"getTable";
	query.module 		= 	"Agua::Workflow";
	query.sourceid 		= 	this.id;
	query.callback		=	"handleTable",
	Agua.exchange.send(query);
},
handleTable : function (response) {
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

}); //	end declare

});	//	end define

