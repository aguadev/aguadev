define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/when",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/infusion/Data",
	"plugins/core/Common",
	"plugins/infusion/Dialog/Project",
	"plugins/infusion/Dialog/Sample",
	"plugins/infusion/Dialog/Flowcell",
	"plugins/infusion/Dialog/Lane",
	"plugins/form/UploadDialog",
	"dojo/ready",
	"dojo/domReady!",
	
	"dijit/TitlePane",
	"dijit/form/TextBox",
	"dijit/form/Button",
	"dijit/_Widget",
	"dijit/_Templated",
	"dijit/layout/AccordionContainer",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojox/layout/ContentPane"
],

function (declare, arrayUtil, JSON, on, when, lang, domAttr, domClass, Data, Common, ProjectDialog, SampleDialog, FlowcellDialog, LaneDialog, UploadDialog, ready) {

////}}}}}

return declare("plugins.infusion.Dialog",[Data], {

// core: Hash
// 		Holder for major components, e.g., core.data, core.dataStore
core : null,

// dataStore : Store of class Observable(Memory)
//		Watches changes in the data and reacts accordingly
dataStore : null,

// cssFiles : Array
// CSS FILES
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/infusion/Dialog/css/dialog.css"),
],

// callback : Function reference
// Call this after module has loaded
callback : null,

// attachPoint : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

//////}}
constructor : function(args) {		
	console.log("Dialogs.constructor    args:");
	console.dir({args:args});
	
	if ( ! args )	return;
	
    // MIXIN ARGS
    lang.mixin(this, args);

	// SET core.lists
	if ( ! this.core ) 	this.core = new Object;
	this.core.details = this;

	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "agua.cgi";

	//// LOAD CSS
	//this.loadCSS();
},
postCreate : function() {
	console.log("Dialogs.postCreate    plugins.infusion.Infusion.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Dialogs.startup    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
	
	if ( ! this.attachPoint ) {
		console.log("Dialogs.startup    this.attachPoint is null. Returning");
		return;
	}
	
	if ( ! this.core ) {
		console.log("Dialogs.startup    this.core is null. Returning");
		return;
	}

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// SET UP TITLE PANES TO LOAD GRIDS	
	this.setDialogs();
},
setDialogs : function () {
	console.log("Dialogs.setDialogs");
	this.setUploadDialog();
	this.setProjectDialog();
	this.setSampleDialog();
	this.setFlowcellDialog();
	this.setLaneDialog();	
},
setProjectDialog : function () {
	this.core.projectDialog = new ProjectDialog({
		attachPoint:	this.projectAttachNode,
		core		: 	this.core
	});
	console.log("Dialogs.setProjectDialog    this.projectDialog:");
	console.dir({this_projectDialog:this.projectDialog});
	
	//this.projectAttachNode.appendChild(this.projectDialog.domNode);
},
setSampleDialog : function (dataStore) {
	this.core.sampleDialog = new SampleDialog({
		attachPoint:	this.sampleAttachNode,
		core		: 	this.core
	});
	console.log("Dialogs.setSampleDialog    this.sampleDialog:");
	console.dir({this_sampleDialog:this.sampleDialog});
},
setFlowcellDialog : function (dataStore) {
	this.core.flowcellDialog = new FlowcellDialog({
		attachPoint:	this.flowcellAttachNode,
		core		: 	this.core
	});
	console.log("Dialogs.setFlowcellDialog    this.flowcellDialog:");
	console.dir({this_flowcellDialog:this.flowcellDialog});
},
setLaneDialog : function (dataStore) {
	this.core.laneDialog = new LaneDialog({
		attachPoint:	this.laneAttachNode,
		core		: 	this.core
	});
	console.log("Dialogs.setLaneDialog    this.laneDialog:");
	console.dir({this_laneDialog:this.laneDialog});
},
showDialog : function (type, name) {
	console.log("Dialogs.showDialog    type: " + type);
	console.log("Dialogs.showDialog    name: " + name);

	// SET INSTANCE NAME
	var instanceName = type + "Dialog";
	//console.log("Dialogs.showDialog    instanceName: " + instanceName);
	//console.log("Dialogs.showDialog    this.core:");
	//console.dir({this_core:this.core});

	var object;
	var cowType = type.substring(0,1).toUpperCase() + type.substring(1);
	var subroutine = "get" + cowType + "Object";
	var object = this.core.data[subroutine](name);
	console.log("Dialogs.showDialog    object:");
	console.dir({object:object});

	this.core[instanceName].populateFields(object);
	this.core[instanceName].show();
},
// UPLOAD DIALOG
setUploadDialog : function () {
	console.log("Dialogs.setUploadDialog     DOING new plugins.form.UploadDialog");
	var uploaderId 	= 	dijit.getUniqueId("plugins.form.UploadDialog");
	var username 	= 	Agua.cookie('username');
	var sessionid 	= 	Agua.cookie('sessionid');
	var mode		=	"manifest";
	var token		=	this.core.token;
	
	this.core.uploadDialog = new plugins.form.UploadDialog({
		core		:	this.core,
		uploaderId	: 	uploaderId,
		username	: 	username,
		sessionid	: 	sessionid,
		token		:	token,
		mode		:	mode,
		url			:	Agua.cgiUrl + "upload.cgi"
	});
	console.log("Dialogs.setUploadDialog     this.core.uploadDialog: ");
	console.dir({this_uploadDialog:this.core.uploadDialog});
	
	// SET CONNECT
	dojo.connect(this.core.uploadDialog, "onComplete", this, "onUploadComplete");
},
onUploadComplete : function () {
	console.log("Dialogs.onUploadComplete    Waiting for message from server");
	//console.log("Dialogs.onUploadComplete    DOING this.core.uploadDialog.hide()");
	//this.core.uploadDialog.hide();
},
postUpload : function (message) {
	console.log("Dialogs.postUpload    message: " + message);
	console.dir({message:message});

	// DISPLAY ERROR IF PRESENT
	if ( message.error ) {
		console.log("Dialogs.postUpload    DOING this.core.uploadDialog.dialog.alert(message.error)");
		this.core.uploadDialog.alert.innerHTML = message.error;
	}
	// OTHERWISE, DISPLAY SAVE PROJECT DIALOG
	else {
		// CLEAR ALERT
		this.core.uploadDialog.alert.innerHTML = "";
		
		// ADD PROJECT TABLE
		this.core.data.addProject(message.data.project);

		// UPDATE SAMPLE TABLE
		this.core.data.addSamples(message.data.samples);

		// OPEN PROJECT DIALOG
		var thisObject = this;
		var promise = thisObject.core.uploadDialog.hide();
		when(promise, function() {
			console.log("Dialogs.postUpload    when.promise    DOING thisObject.showProjectDialog(message.data)");
			thisObject.showProjectDialog(message.data.project);
		});
	}
},
refreshData : function (type) {
	console.log("Dialogs.refreshData    type: " + type);

	if ( this.refreshing == true )	return;
	this.refreshing = true;

	var thisObject = this;
	var deferred = setTimeout(function() {
		console.log("Dialogs.refreshData    setTimeout 1000");
		thisObject.refreshing = false;
	},
	1000);
	
	return deferred;
},
showProjectDialog : function (data) {
	console.log("Dialogs.showProjectDialog    data: " + data);
	console.dir({data:data});

	if ( ! this.core.projectDialog ) {
		this.core.projectDialog = new DialogProject({
			values : data,
			parentWidget : this
		});
	}
	
	console.log("Dialogs.showProjectDialog    this.core.projectDialog:");
	console.dir({this_projectDialog:this.core.projectDialog});
	this.core.projectDialog.show();

	// ATTACH GRID TO PAGE
	var attachPoint = this.projectDialogAttachPoint;
	attachPoint.appendChild(this.core.projectDialog.containerNode)
},
showFlowcellDialog : function (data) {
	console.log("Dialogs.showFlowcellDialog    data: " + data);
	console.dir({data:data});

	if ( ! this.core.flowcellDialog ) {
		this.core.flowcellDialog = new DialogFlowcell({
			values : data,
			parentWidget : this
		});
	}
	console.log("Dialogs.showFlowcellDialog    this.core.flowcellDialog:");
	console.dir({this_flowcellDialog:this.core.flowcellDialog});
	this.core.flowcellDialog.show();
	
	//// ATTACH GRID TO PAGE
	//var attachPoint = this.core.flowcellDialogAttachPoint;
	//attachPoint.appendChild(this.core.flowcellDialog.containerNode)
},
showUploadDialog : function () {
	console.log("Dialogs.showUploadDialog");
	console.log("Dialogs.showUploadDialog    this.core:");
	console.dir({this_core:this.core});
	this.core.uploadDialog.dialog.set('title', "Upload Manifest File");
	this.core.uploadDialog.alert.innerHTML = "";
	this.core.uploadDialog.show();
}



}); 	//	end declare

});	//	end define

