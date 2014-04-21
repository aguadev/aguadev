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

return declare("plugins.infusion.Dialog.Project",
	[ dijit._Widget, dijit._Templated, CommonUtil, CommonArray, CommonSort, Base ], {

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Dialog/templates/project.html"),

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/Dialog/css/project.css"),
	require.toUrl("dojox/widget/Dialog/Dialog.css"),
	require.toUrl("dijit/themes/claro/claro.css")
],

// type : String
//		Type of dialog, e.g., project, sample, flowcell, lane, requeue
type : "project",

// fields : String[]
//		Array of form input fields
fields: [
	"projectId",
	"projectName",
	"status",
	"description",
	"workflow",
	"workflowVersion",
	"buildVersion",
	"dbsnpVersion",
	"includeNpf",
	"projectManager",
	"dataAnalyst",
	"buildLocation",
	"projectPolicy"
],

// fieldNameMap : String{}
//		Hash mapping between table fields and input names
fieldNameMap : {
	project_id 		:	"projectId",
	project_name 	:	"projectName",
	status			:	"status",
	description		:	"description",
	workflow		:	"workflow",
	workflow_version:	"workflowVersion",
	build_version	:	"buildVersion",
	dbsnp_version	:	"dbsnpVersion",
	include_NPF		:	"includeNpf",
	project_manager	:	"projectManager",
	data_analyst	:	"dataAnalyst",
	build_location	:	"buildLocation",
	project_policy	:	"projectPolicy"	
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

	//this.startup();
},
setNameFieldMap : function () {
	var nameFieldMap = {};
	for ( var field in this.fieldNameMap ) {
		nameFieldMap[this.fieldNameMap[field]] = field;
	}
	console.log("Project.setNameFieldMap    nameFieldMap: ");
	console.dir({nameFieldMap:nameFieldMap});
	
	this.nameFieldMap = nameFieldMap;
},
populateFields : function (values) {
	//console.log("Project.populateFields     values:");
	//console.dir({values:values});
	//console.log("Project.populateFields     value.length: " + values.length);
	
	for ( var field in values ) {
		//console.log("Project.populateFields     field: " + field);
		var name = this.fieldNameMap[field];
		//console.log("Project.populateFields     name: " + name);
		var value = values[field] || "";
		//console.log("Project.populateFields     value: " + value);
		
		if ( this[name] ) {
			//console.log("Project.populateFields     setting this[" + name + "] to value: " + value);
			
			this[name].setValue(value);
		}
	}
	
	this.values = values;	
},
setSelects : function () {
	console.log("Project.setSelects    this: " + this);
	console.dir({this:this});
	
	ready(function() {
		var buildOptions	= [
			{ label: "NCBI36", value: "NCBI36", selected: true },
			{ label: "NCBI37", value: "NCBI37" }
		];
		this.buildVersion.setOptions(buildOptions);
	
		var dbsnpOptions	= [
			{ label: "129", value: "129", selected: true },
			{ label: "130", value: "130" },
			{ label: "131", value: "131" },
			{ label: "132", value: "132" }
		];
		this.dbsnpVersion.setOptions(dbsnpOptions);

		var includeOptions	= [
			{ label: "Y", value: "Y", selected: true },
			{ label: "N", value: "N" }
		];
		this.includeNpf.setOptions(includeOptions);
	
		var statusOptions	= [
			{ label: "active", value: "active", selected: true },
			{ label: "hold", value: "hold" },
			{ label: "cancelled", value: "cancelled" }
		];
		this.status.setOptions(statusOptions);
	
		this.setWorkflowOptions();
	});
	

},
setWorkflowOptions : function () {
	var table = this.core.data.getTable("workflow");
	console.log("Project.setWorkflowOptions    table: " + table);
	console.dir({table:table});
	if ( ! table || table.length < 1 ) return;
	
	var hash = this.core.data.getHash("workflow", "arrayHash", "workflow_name", "workflow_version");
	console.log("Project.setWorkflowOptions    hash: " + hash);
	console.dir({hash:hash});
	if ( ! hash || hash == null || hash == {} ) return;

	// SET WORKFLOW HASH
	this.workflowHash = hash;
	
	var workflows = this.hashkeysToArray(hash);
	console.log("Project.setWorkflowOptions    workflows: " + workflows);
	console.dir({workflows:workflows});
	
	console.log("Project.setWorkflowOptions    DOING SORT workflows: " + workflows);
	workflows = workflows.sort(this.sortNaturally);
	console.log("Project.setWorkflowOptions    AFTER SORT workflows: " + workflows);

	console.log("Project.setWorkflowOptions    DOING this.setSelectOptions('workflow', workflows)");
	this.setSelectOptions("workflow", workflows);
	console.log("Project.setWorkflowOptions    AFTER this.setSelectOptions('workflow', workflows)");
	
	// SET VERSIONS FOR FIRST WORKFLOW
	var versions = hash[workflows[0]];
	console.log("Project.setWorkflowOptions    versions: " + versions);
	this.setSelectOptions("workflowVersion", versions);	

	// SET WORKFLOW LISTENER
	var thisObject = this;
	dojo.connect(this.workflow.input, "onchange", function() {
		console.log("Project.setWorkflowOptions    this.workflow.onChange FIRED");
		var workflowName = thisObject.workflow.getValue();
		console.log("Project.setWorkflowOptions    workflowName: " + workflowName);
		
		var versions = hash[workflowName];
		console.log("Project.setWorkflowOptions    versions: " + versions);
		thisObject.setSelectOptions("workflowVersion", versions);	
	})	
}

}); 	//	end declare

});	//	end define

