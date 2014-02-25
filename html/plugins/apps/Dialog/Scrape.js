define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/core/Common/Util",
	"plugins/core/Common/Array",
	"plugins/core/Common/Sort",
	"plugins/core/Util/ViewSize",
	"plugins/form/Dialog/Base",
	"dijit/_Widget",
	"dijit/_Templated",
	"dojo/ready",
	"dojo/domReady!",

	"dijit/form/SimpleTextarea",
	"dijit/form/Button",
	"dojo/dnd/Source",
	"dijit/form/Select",
	"plugins/dojox/widget/Dialog"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, CommonUtil, CommonArray, CommonSort, ViewSize, Base, _Widget, _Templated, ready) {

// FORM VALIDATION

/////}}}}}

return declare("plugins.apps.Dialog.Scrape",
	[ _Widget, _Templated, CommonUtil, CommonArray, CommonSort, Base ], {

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/apps/Dialog/templates/scrape.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/apps/Dialog/css/scrape.css"),
	require.toUrl("dojox/widget/Dialog/Dialog.css"),
	require.toUrl("dijit/themes/claro/claro.css")
],

// type : String
//		Type of dialog, e.g., project, sample, flowcell, lane, requeue
type : "flowcell",

// values : String{}
//		Hash of values provided in instantiation arguments
values : {},

// cols: String
// 		Default number of columns
cols: 60,

// rows: String
// 		Default number of rows
rows: 40,

// disabled : String
//		Disable with 'disabled', enable with ''
disabled : "",

/////}}}}}
constructor : function(args) {
    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Scrape.postCreate    plugins.init.Controller.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Scrape.startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);

	// ADD TO TAB CONTAINER		
	console.log("Scrape.startup    BEFORE appendChild(this.mainTab.domNode)");
	dojo.byId("attachPoint").appendChild(this.mainTab.domNode);
	console.log("Scrape.startup    AFTER appendChild(this.mainTab.domNode)");
	
	// SET SAVE BUTTON
	dojo.connect(this.saveButton, "onClick", dojo.hitch(this, "save"));
	
	// POPULATE FIELDS
	console.log("Scrape.startup    DOING this.populateFields(this.values)");
	console.dir({this_values:this.values});
	this.populateFields(this.values);
	
	// SHOW
	console.log("Scrape.startup    DOING this.mainTab.show()");
	this.mainTab.show();
},
sendQuery : function (data) {
	console.log("Scrape.sendQuery    data: " + dojo.toJson(data));
	console.dir({data:data});

	var mode = "update" + this.type.substring(0,1).toUpperCase() + this.type.substring(1);
	console.log("Scrape.sendQuery    mode: " + mode);
	
	var url = Agua.cgiUrl + "infusion.cgi?";
	
	// CREATE JSON QUERY
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie("username");
	query.sessionid 	= 	Agua.cookie("sessionid");
	query.taskid		=	this.core.infusion.taskid;
	query.mode 			= 	mode;
	query.module		= 	"Infusion::Base";
	query.token			= 	this.core.infusion.token;
	query.data 			= 	data;
	console.log("Scrape.save    query: " + dojo.toJson(query));
	console.dir({query:query});
	
	// SEND TO SERVER
	var thisObj = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			handle : function(json, ioArgs) {
				console.log("Scrape.save    json:");
				console.dir({json:json});
				
				var response = JSON.parse(json);
				thisObj.handleSave(response.data);
			},
			error : function(response, ioArgs) {
				console.log("Scrape.save    Error with JSON Post, response: ");
				console.dir({response:response});
			}
		}
	);
	
	this.saving = false;
},
handleSave : function (data) {
	console.log("Scrape.handleSave    data: ");
	console.dir({data:data});

	// UPDATE TABLE IN data
	console.log("Scrape.handleSave    DOING this.core.data.updateTable('sample', data)");
	this.core.data.updateTable(this.type, data);
},
usage : function () {
	var text = this.input.value;
	console.log("Scrape.usage    text: " + text);
	
	
}




}); //	end declare

});	//	end define

