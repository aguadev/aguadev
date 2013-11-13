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
	"plugins/infusion/Dialog/Base",
	"dojo/ready",
	"dojo/domReady!",

	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/form/ValidationTextBox",
	"plugins/form/TextArea",
	"plugins/form/Select",
	"dijit/layout/ContentPane",
	"dijit/form/Button",
	"dijit/form/Select",
	"plugins/dojox/widget/Dialog"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, CommonUtil, CommonArray, CommonSort, ViewSize, Base, ready) {

/////}}}}}

return declare("plugins.infusion.Dialog.Lane",
	[ dijit._Widget, dijit._Templated, CommonUtil, CommonArray, CommonSort, Base ], {

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Dialog/templates/lane.html"),

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/Dialog/css/lane.css"),
	require.toUrl("dojox/widget/Dialog/Dialog.css"),
	require.toUrl("dijit/themes/claro/claro.css")
],

// type : String
//		Type of dialog, e.g., project, sample, flowcell, lane, requeue
type : "lane",

// fields : String[]
//		Array of form input fields
fields: [
	"flowcellSamplesheetId",
	"flowcellId",
	"sampleId",
	"laneId",
	"refSequence",
	"control",
	"status",
	"indexval",
	"md5sum",
	"location",
	"dateUpdated"
],

// fieldNameMap : String{}
//		Hash mapping between table fields and input names
fieldNameMap : {
	flowcell_samplesheet_id	:	"flowcellSamplesheetId",
	flowcell_id				:	"flowcellId",
	sample_id				:	"sampleId",
	lane_id					:	"laneId",
	ref_sequence			:	"refSequence",
	control					:	"control",
	status					:	"status",
	indexval				:	"indexval",
	md5sum					:	"md5sum",
	location				:	"location",
	date_updated			:	"dateUpdated"
},

/////}}}}}
constructor : function(args) {
    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Controller.postCreate    plugins.init.Controller.postCreate()");

	this.startup();
},
setSelects : function () {
	console.log("Lane.setSelects");

	var controlOptions = ["N", "Y"];
	this.setSelectOptions("control", controlOptions);
	
	this.setStatusOptions();
}



}); 	//	end declare

});	//	end define

