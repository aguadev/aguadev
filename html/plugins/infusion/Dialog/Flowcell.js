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

// FORM VALIDATION

/////}}}}}

return declare("plugins.infusion.Dialog.Flowcell",
	[ dijit._Widget, dijit._Templated, CommonUtil, CommonArray, CommonSort, Base ], {

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Dialog/templates/flowcell.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/Dialog/css/flowcell.css"),
	require.toUrl("dojox/widget/Dialog/Dialog.css"),
	require.toUrl("dijit/themes/claro/claro.css")
],

// type : String
//		Type of dialog, e.g., project, sample, flowcell, lane, requeue
type : "flowcell",

//		Array of form input fields
fields: [
	"flowcellId",
	"server",
	"flowcellBarcode",
	"updateTimestamp",
	"fpgaVersion",
	"rtaVersion",
	"runLength",
	"indexed",
	"status",
	//"operator",
	"description",
	//"recipe",
	"machineName",
	"location",
	"runStartDate",
	"priorityFlowcell",
	//"locationMd5sum",
	"comments",
	"symptoms",
	//"userCodeAndIp",
	"attemptingRehyb",
	"lcmBroadCause",
	"lcmSpecificCause",
	"lcmStatus",
	"lcmEquipmentRelated",
	"lcmComments"
],

// fieldNameMap : String{}
//		Hash mapping between table fields and input names
fieldNameMap : {
	flowcell_id			:	"flowcellId",
	server				:	"server",
	flowcell_barcode	:	"flowcellBarcode",
	update_timestamp	:	"updateTimestamp",
	fpga_version		:	"fpgaVersion",
	rta_version			:	"rtaVersion",
	run_length			:	"runLength",
	indexed				:	"indexed",
	status				:	"status",
	//operator			:	"operator",
	description			:	"description",
	//recipe				:	"recipe",
	machine_name		:	"machineName",
	location			:	"location",
	run_start_date		:	"runStartDate",
	priority_flowcell	:	"priorityFlowcell",
	//location_md5sum		:	"locationMd5sum",
	comments			:	"comments",
	symptoms			:	"symptoms",
	//user_code_and_ip	:	"userCodeAndIp",
	attempting_rehyb	:	"attemptingRehyb",
	lcm_broad_cause		:	"lcmBroadCause",
	lcm_specific_cause	:	"lcmSpecificCause",
	lcm_status			:	"lcmStatus",
	lcm_equipment_related:	"lcmEquipmentRelated",
	lcm_comments		:	"lcmComments"
},

// nameFieldMap : String{}
//		Hash mapping between input names and table fields
//		Calculated as reverse of fieldNameMap on startup
nameFieldMap : {},

// values : String{}
//		Hash of values provided in instantiation arguments
values : {},

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
	console.log("Flowcell.setSelects");

	this.setSelectOptions("indexed", ["no", "yes"], "no");
	this.setSelectOptions("attemptingRehyb", ["0", "1", "2", "3"], "0");
	
	this.setStatusOptions();

	this.setFailureMode();
}



}); 	//	end declare

});	//	end define

