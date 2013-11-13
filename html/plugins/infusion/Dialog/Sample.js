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

return declare("plugins.infusion.Dialog.Sample",
	[ dijit._Widget, dijit._Templated, CommonUtil, CommonArray, CommonSort, Base ], {

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Dialog/templates/sample.html"),

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/Dialog/css/sample.css"),
	require.toUrl("dojox/widget/Dialog/Dialog.css"),
	require.toUrl("dijit/themes/claro/claro.css")
],

// type : String
//		Type of dialog, e.g., project, sample, flowcell, lane, requeue
type : "sample",

// fields : String[]
//		Array of form input fields
fields: [

	"sampleId",
	"projectId",
	"sampleBarcode",
	"sampleName",
	"plateBarcode",
	"species",
	"gender",
	"volume",
	"concentration",
	"od260280",
	"tissueSource",
	"extractionMethod",
	"ethnicity",
	"parent1SampleId",
	"parent2SampleId",
	"replicatesId",
	"cancer",
	"matchSampleIds",
	"matchSampleType",
	"comment",
	"dueDate",
	"targetFoldCoverage",
	"gtGender",
	"doBuild",
	"status",
	"samplePolicy",
	"updateDate",
	"deliveredDate",
	"genotypeReport",
	"gtDelivSrc",
	//"userCodeAndIp",
	"FTAT",
	"analysis",
	"gtCallRate",
	"gtP99Cr"
],

// fieldNameMap : String{}
//		Hash mapping between table fields and input names
fieldNameMap : {

	sample_id		:	"sampleId",
	project_id		:	"projectId",
	sample_barcode	:	"sampleBarcode",
	sample_name		:	"sampleName",
	plate_barcode	:	"plateBarcode",
	species			:	"species",
	gender			:	"gender",
	volume			:	"volume",
	concentration	:	"concentration",
	od_260_280		:	"od260280",
	tissue_source	:	"tissueSource",
	extraction_method:	"extractionMethod",
	ethnicity		:	"ethnicity",
	parent_1_sample_id	:	"parent1SampleId",
	parent_2_sample_id	:	"parent2SampleId",
	replicates_id	:	"replicatesId",
	cancer			:	"cancer",
	match_sample_ids	:	"matchSampleIds",
	match_sample_type	:	"matchSampleType",
	comment			:	"comment",
	due_date		:	"dueDate",
	target_fold_coverage	:	"targetFoldCoverage",
	gt_gender		:	"gtGender",
	do_build		:	"doBuild",
	status			:	"status",
	sample_policy	:	"samplePolicy",
	update_date		:	"updateDate",
	delivered_date	:	"deliveredDate",
	genotype_report	:	"genotypeReport",
	gt_deliv_src	:	"gtDelivSrc",
	//user_code_and_ip:	"userCodeAndIp",
	FTAT			:	"FTAT",
	analysis		:	"analysis",
	gt_call_rate	:	"gtCallRate",
	gt_p99_cr		:	"gtP99Cr"

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
	console.log("Sample.setSelects");

	var genderOptions = ["M", "F", "U"];
	this.setSelectOptions("gender", genderOptions);
	
	var cancerOptions = ["N", "Y"];
	this.setSelectOptions("cancer", cancerOptions);

	var gtGenderOptions = ["M", "Y"];
	this.setSelectOptions("gtGender", gtGenderOptions);

	var doBuildOptions = ["no", "yes"];
	this.setSelectOptions("doBuild", doBuildOptions);

	var FTATOptions = ["N", "Y"];
	this.setSelectOptions("FTAT", FTATOptions);

	this.setStatusOptions();
}



}); 	//	end declare

});	//	end define

