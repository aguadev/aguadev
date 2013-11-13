define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/core/Common/Util",
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
	//"dijit/form/TextBox",
	//"dijit/form/Textarea",
	//"dijit/form/NumberTextBox",
	//"dijit/form/HorizontalSlider",
	"dojox/widget/Dialog"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, CommonUtil, ready) {

// FORM VALIDATION

/////}}}}}

return declare("plugins.infusion.Dialog.Project",
	[ dijit._Widget, dijit._Templated, CommonUtil ], {


	
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Dialog/templates/project.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/Dialog/css/project.css"),
	require.toUrl("dojox/widget/Dialog/Dialog.css"),
	require.toUrl("dijit/themes/claro/claro.css")
],

// PARENT WIDGET
parentWidget : null,

// DEFAULT DATA VOLUME
defaultDataVolume : null,

/////}}}}}
constructor : function(args) {

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Controller.postCreate    plugins.init.Controller.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Project.startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);

	// ADD TO TAB CONTAINER		
	console.log("Project.startup    BEFORE appendChild(this.mainTab.domNode)");
	dojo.byId("attachPoint").appendChild(this.mainTab.domNode);
	console.log("Project.startup    AFTER appendChild(this.mainTab.domNode)");
	
	// SET SAVE BUTTON
	dojo.connect(this.saveButton, "onClick", dojo.hitch(this, "save"));

	// SET SELECTS
	this.setSelects();
	
	// SHOW
	this.mainTab.show();
	
	//// SET POSITION
	//this.setPosition();
},
//setPosition : function () {
//	var node = this.mainTab.domNode;
//	var viewport = winUtils.getBox(this.ownerDocument);
//	var	p = this._relativePosition,
//		bb = p ? null : domGeometry.position(node),
//		l = Math.floor(viewport.l + (p ? p.x : (viewport.w - bb.w) / 2)),
//		t = Math.floor(viewport.t + (p ? p.y : (viewport.h - bb.h) / 2))
//	;
//	console.log("Project.setPosition    l: " + l);
//	console.log("Project.setPosition    t: " + t);
//
//	domStyle.set(node, {
//		left: l + "px",
//		top: t + "px"
//	});
//	
//},
setSelects : function () {
	console.log("Project.setSelects");

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
},
// SAVE
save : function (event) {
	console.log("Project.save    event: " + event);
	
	if ( this.saving == true ) {
		console.log("Project.save    this.saving: " + this.saving + ". Returning.");
		return;
	}
	this.saving = true;
	
	var parameters = [
		"projectName",
		"description",
		"buildVersion",
		"dbsnpVersion",
		"projectManager",
		"dataAnalyst",
		"buildLocation",
		"projectPolicy"
	];
	var isValid = true;
	for ( var i = 0; i < parameters.length; i++ ) {
		var parameter = parameters[i];
		console.log("Project.save    ******* parameter: " + parameter);
		var value = this[parameter].getValue();
		console.log("Project.save    value: " + value);
		var valid = this[parameter].isValid();
		console.log("Project.save    valid: " + valid);
	}
	if ( ! valid )	{
		console.log("Project.save    One or more inputs not valid. Returning");
		this.saving = false;
		return;
	}

	//var uservolume = this.uservolume.value;
	//if ( uservolume.match(/New volume/) )	uservolume = '';
	//
	//// CLEAN UP WHITESPACE AND SUBSTITUTE NON-JSON SAFE CHARACTERS
	//var project = new Object;
	//project.project_name	= 	this.projectName.getValue();
	//project.password 		= this.password.value;
	//project.password 		= this.password.value;
	//project.password 		= this.password.value;
	//project.password 		= this.password.value;
	//project.amazonuserid 	= this.cleanEdges(this.amazonuserid.value);
	//project.datavolume 		= this.datavolume.value;
	//project.uservolume 		= uservolume;
	//project.datavolumesize 	= this.datavolumesize.value;
	//project.uservolumesize 	= this.uservolumesize.value;
	//project.ec2publiccert 	= this.cleanEdges(this.ec2publiccert.value);
	//project.ec2privatekey 	= this.cleanEdges(this.ec2privatekey.value);
	//project.projectaccesskeyid 	= this.cleanEdges(this.projectaccesskeyid.value);
	//project.projectsecretaccesskey = this.cleanEdges(this.projectsecretaccesskey.value);
	//
	//var url = this.cgiUrl + "/init.cgi?";
	//console.log("Project.saveStore     url: " + url);		
	//
	//// CREATE JSON QUERY
	//var query 			= 	new Object;
	//query.username 		= 	"agua";
	//query.mode 			= 	"init";
	//query.data 			= 	aws;
	//console.log("Project.save    query: " + dojo.toJson(query));
	//console.dir({query:query});
	//
	//
	//this.enableProgressButton();
	//
	//// SEND TO SERVER
	//var thisObj = this;
	//dojo.xhrPut(
	//	{
	//		url: url,
	//		contentType: "text",
	//		putData: dojo.toJson(query),
	//		load: function(response, ioArgs) {
	//			console.log("Project.save    response:");
	//			console.dir({response:response});
	//			thisObj.handleSave(response);
	//		},
	//		error: function(response, ioArgs) {
	//			console.log("Project.save    Error with JSON Post, response: ");
	//			console.dir({response:response});
	//		}
	//	}
	//);
	//
	this.saving = false;
},
handleSave : function (response) {
	console.log("Project.handleSave    response: ");
	console.dir({response:response});
	if ( ! response ) {
		this.toast({error:"No response from server. If problem persists, restart instance"})
		return;
	}
	this.toast(response);
},
cleanEdges : function (string) {
// REMOVE WHITESPACE FROM EDGES OF TEXT
	if ( string == null )	{ 	return null; }
	string = string.replace(/^\s+/, '');
	string = string.replace(/\s+$/, '');
	return string;
}

}); 	//	end declare

});	//	end define

