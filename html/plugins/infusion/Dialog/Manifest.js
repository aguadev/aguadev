define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/core/Common/Util",
	"plugins/core/Util/ViewSize",
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
	"plugins/dojox/widget/Dialog",
	"plugins/form/DateTextBox"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, CommonUtil, ViewSize, ready) {

/* SUMMARY: Validation of form inputs:

Hi Stuart,

Here is an example of the manifest the customer send and we import into the LIMS. The project managers  have agreed to add a column which will contain the fold coverage (30X,40X..) or amount (110G , 220G ) minimum requirement.

The due date was also suggest to be 12 weeks (configurable) from the “date received”.

So the web site should read the file, parse the project name, also to edit the build (default to NCBI37, parsing the comment is useless), ask to associate an existent workflow with all the samples of the project.

After this is set every sample barcode (column named “Sample Well”) should be checked if already exists in the sample table,  if yes, abort the whole loading.

Ignore the column count but these are the columns that matter in bold. Unfortunately they don’t really respect the strictness very much.


Project Name		MMM_Thomas3
Principal Investigator	Miles Thomas
Institute Name		MMM_Thomas3
Date Received		4/14/2013
Target Coverage		30
Target Yield		105
Comment				NCBI genome build 37
SAMPLE_NAME         => 2,
PLATE_BARCODE       => 3,
SAMPLE_BARCODE      => 5,
SPECIES             => 6,
SEX                 => 7 , (M,F or U)

*/

/////}}}}}

return declare("plugins.infusion.Dialog.Manifest",
	[ dijit._Widget, dijit._Templated, CommonUtil ], {

// templatePath : String
// 		Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Dialog/templates/manifest.html"),

// widgetsInTemplate: Boolean
// 		Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// cssFiles : ArrayRef
// 		List of CSS files (OR USE @import IN HTML TEMPLATE)
cssFiles : [
	require.toUrl("plugins/infusion/Dialog/css/manifest.css"),
	require.toUrl("dojox/widget/Dialog/Dialog.css"),
	require.toUrl("dijit/themes/claro/claro.css")
],

// parentWidget : Object
//		The widget that created this one
parentWidget : null,

// duration : Integer
//		The number of days the average project is expected to take
duration : 90,

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
	console.log("Manifest.startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);

	// ADD TO TAB CONTAINER		
	console.log("Manifest.startup    BEFORE appendChild(this.mainTab.domNode)");
	dojo.byId("attachPoint").appendChild(this.mainTab.domNode);
	console.log("Manifest.startup    AFTER appendChild(this.mainTab.domNode)");
	
	// SET SAVE BUTTON
	dojo.connect(this.saveButton, "onClick", dojo.hitch(this, "save"));

	// SET SELECTS
	this.setSelects();
	
	// OVERRIDE dijit.Dialog._position
	console.log("Manifest.startup    DOING on(this.mainTab, ...)    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	
	this.positionHandle = on(this.mainTab, "_size", "_fixPosition");

	this.mainTab._sizingConnect = this.connect(this.mainTab._sizing, "onEnd", "_fixPosition");
	
	// SHOW
	this.mainTab.show();

	// SET DATE CHAINING
	this.setDateChaining();
	
	//// SET FOCUS
	//this.setFocus();
	
	//// SET POSITION
	//this.setPosition();
},
setDateChaining : function () {
	console.log("Manifest.setDateChaining    this.dateReceived: " + this.dateReceived);
	console.dir({this_dateReceived:this.dateReceived});
	
	// SET DUE DATE	
	this.setDateDue();	

	// SET dateDue TO SHADOW dateReceived (+ this.duration days)
	//console.log("Manifest.setDateChaining    this.dateReceived.input.focusNode: " + this.dateReceived.input.focusNode);
	//console.dir({this_dateReceived_input_focusNode:this.dateReceived.input.focusNode});
	
	// SET LISTENER TO UPDATE DATE DUE ON CHANGE DATE RECEIVED
	var thisObject = this;
	on(this.dateReceived.input.focusNode, "blur", function(event) {
		console.log("Manifest.setDateChaining    on(this.dateReceived.input.focusNode FIRED");
		thisObject.setDateDue();
	});
},
setDateDue : function () {
	console.log("Manifest.setDateDue    this.dateReceived:");
	console.dir({this_dateReceived:this.dateReceived});
	console.log("Manifest.setDateDue    this.dateDue:");
	console.dir({this_dateDue:this.dateDue});
	console.log("Manifest.setDateDue    this.duration: " + this.duration);
	
	console.log("Manifest.setDateDue    this.dateReceived.input.getValue(): " + this.dateReceived.input.getValue());
	
	console.log("Manifest.setDateDue    this.dateReceived.input.focusNode.value: " + this.dateReceived.input.focusNode.value);
	console.log("Manifest.setDateDue    this.dateReceived.input.displayedValue: " + this.dateReceived.input.displayedValue);
	console.log("Manifest.setDateDue    this.dateReceived.input._lastValueReported: " + this.dateReceived.input._lastValueReported);
	console.log("Manifest.setDateDue    this.dateDue.input.focusNode.value: " + this.dateDue.input.focusNode.value);
	console.log("Manifest.setDateDue    this.dateDue.input.displayedValue: " + this.dateDue.input.displayedValue);

	var dateReceivedString = this.dateReceived.input.displayedValue || this.dateReceived.input.focusNode.value;
	console.log("Manifest.setDateDue    dateReceivedString: " + dateReceivedString);

	if ( ! dateReceivedString ) {
		console.log("Manifest.setDateDue    dateReceivedString is empty. Returning");
		return;
	}

	var dateReceived = new Date(dateReceivedString);
	console.log("Manifest.setDateDue    dateReceived:");
	console.dir({dateReceived:dateReceived});

	var dateDue = this.addDaysToDate(dateReceived, this.duration + 1);
	var dateDueString = this.dateDue.formatDate(dateDue);
	console.log("Manifest.setDateDue    dateDueString: " + dateDueString);
	
	this.dateDue.input.focusNode.value = dateDueString;
},
addDaysToDate : function (date, days) {
	date.setDate(date.getDate() + days);
	
	return date;
},
setFocus : function () {
	console.log("Manifest.setFocus    this.projectName.domNode: ");
	console.dir({this_projectName_domNode:this.projectName.domNode});
	
	console.log("Manifest.setFocus    DEBUG RETURN");
	return;

	this.projectName.domNode.blur();
	this.mainTab.titleNode.focus();
},
_fixPosition: function() {
/* Position the dialog in the browser screen */

	var mb = dojo._getMarginSize(this.domNode);
	console.log("infusion.Dialog.Manifest._fixPosition    mb.w: " + mb.w);
	console.log("infusion.Dialog.Manifest._fixPosition    mb.h: " + mb.h);

	var viewport = dojo.window.getBox();
	console.log("infusion.Dialog.Manifest._fixPosition    viewport.w: " + viewport.w);
	console.log("infusion.Dialog.Manifest._fixPosition    viewport.h: " + viewport.h);
	
	if (viewport.h < mb.h) {

		console.log("infusion.Dialog.Manifest._fixPosition    viewport.h < mb.h");

		var top = dojo.style(this.domNode, "top");
		if (top < 0) {

			console.log("infusion.Dialog.Manifest._fixPosition    top < 0. Setting top to 0");

			dojo.style(this.domNode, {top: "0"});
		}
	}
},

setSelects : function () {
	console.log("Manifest.setSelects");

	var buildOptions	= [
		{ label: "M", value: "M", selected: true },
		{ label: "F", value: "F" },
		{ label: "U", value: "U" }
	];
	this.sex.setOptions(buildOptions);
},
// SAVE
save : function (event) {
	console.log("Manifest.save    event: " + event);
	
	if ( this.saving == true ) {
		console.log("Manifest.save    this.saving: " + this.saving + ". Returning.");
		return;
	}
	this.saving = true;
	
	var parameters = [
		"projectName",
		"principalInvestigator",
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
		console.log("Manifest.save    ******* parameter: " + parameter);
		var value = this[parameter].getValue();
		console.log("Manifest.save    value: " + value);
		var valid = this[parameter].isValid();
		console.log("Manifest.save    valid: " + valid);
	}
	if ( ! valid )	{
		console.log("Manifest.save    One or more inputs not valid. Returning");
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
	//console.log("Manifest.saveStore     url: " + url);		
	//
	//// CREATE JSON QUERY
	//var query 			= 	new Object;
	//query.username 		= 	"agua";
	//query.mode 			= 	"init";
	//query.data 			= 	aws;
	//console.log("Manifest.save    query: " + dojo.toJson(query));
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
	//			console.log("Manifest.save    response:");
	//			console.dir({response:response});
	//			thisObj.handleSave(response);
	//		},
	//		error: function(response, ioArgs) {
	//			console.log("Manifest.save    Error with JSON Post, response: ");
	//			console.dir({response:response});
	//		}
	//	}
	//);
	//
	this.saving = false;
},
handleSave : function (response) {
	console.log("Manifest.handleSave    response: ");
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

