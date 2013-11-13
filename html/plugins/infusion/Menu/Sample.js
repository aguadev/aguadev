dojo.provide("plugins.infusion.Menu.Sample");

// WIDGET PARSER
dojo.require("dojo.parser");

// INHERITS
dojo.require("plugins.infusion.Menu.Base");

dojo.declare("plugins.infusion.Menu.Sample",
	[ plugins.infusion.Menu.Base ], {
		
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Menu/templates/sample.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/Menu/css/sample.css"),
	require.toUrl("dojox/form/resources/FileInput.css")
],

// PARENT WIDGET
parentWidget : null,

// delay: Integer (thousandths of a second)
// Poll delay
delay : 6000,

/////}}
	
startup : function () {
	console.group("Menu.Sample    " + this.id + "    startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// DISABLE MENU ITEMS
	//this.disableMenuItem('select');
	//this.disableMenuItem('add');
	this.menu._started = false;
	this.menu.startup();

	// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.menu.domNode, "oncontextmenu", function (event) {
		event.stopPropagation();
	});

	// SUBSCRIBE TO UPDATES
	if ( Agua && Agua.updater && Agua.updater.subscribe ) {
		Agua.updater.subscribe(this, "updateProjects");
		Agua.updater.subscribe(this, "updateWorkflows");	
	}

	console.groupEnd("Menu.Sample    " + this.id + "    startup");
},
updateProjects : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.log("workflow.Stages.updateProjects    workflow.Stages.updateProjects(args)");
	console.log("workflow.Stages.updateProjects    args:");
	console.dir(args);

	this.core.infusion.updateProjects();
},
updateClusters : function (args) {
// RELOAD RELEVANT DISPLAYS
	console.log("admin.Clusters.updateClusters    admin.Clusters.updateClusters(args)");
	console.log("admin.Clusters.updateClusters    args:");
	console.dir(args);
	this.setClusterCombo();
},
// COMPLETE
complete : function (event) {
	console.log("Menu.Sample.complete     this.sampleBarcode: " + sampleBarcode);
	this.confirmAction("completeSample", "Complete", this.doComplete);
},
doComplete : function (sampleBarcode) {
// UPDATE LANE IN data TABLES
	console.log("Menu.Sample.doComplete    sampleBarcode: " + sampleBarcode);

},
// CANCEL
cancel : function () {
	this.confirmAction("cancelSample", "Cancel", this.doCancel);
},
doCancel : function (sampleBarcode) {
// UPDATE LANE IN data TABLES
	console.log("Menu.Sample.doCancel    sampleBarcode: " + sampleBarcode);
},
// FAIL
fail : function () {
	this.confirmAction("failSample", "Fail", this.doFail);
},
doFail : function (sampleBarcode) {
// UPDATE LANE IN data TABLES
	console.log("Menu.Sample.doFail    sampleBarcode: " + sampleBarcode);
},
// REQUEUE
requeue : function () {
	this.confirmAction("requeueSample", "Requeue", this.doRequeue);
},
doRequeue : function (sampleBarcode) {
// UPDATE LANE IN data TABLES
	console.log("Menu.Sample.doRequeue    sampleBarcode: " + sampleBarcode);

},
setShortKeys : function () {
	// NOTE: USE accelKey IN DOJO 1.3 ONWARDS
	dojo.connect(this.menu, "onKeyPress", dojo.hitch(this, function(event)
	{
		console.log("Menu.Sample.setMenu     this.menu.onKeyPress(event)");
		var key = event.keyCode;
		if ( this.altOn == true )
		{
			switch (key)
			{
				case "s" : this.select(); break;
				case "a" : this.add(); break;
				case "n" : this.newFolder(); break;
				case "m" : this.rename(); break;
				case "l" : this.deleteFile(); break;
				case "o" : this.openWorkflow(); break;
				case "u" : this.upload(); break;
				case "w" : this.download(); break;
				case "r" : this.refresh(); break;
			}
		}
		event.stopPropagation();
	}));

	// SET ALT KEY ON/OFF
	dojo.connect(this.menu, "onKeyDown", dojo.hitch(this, function(event){
		console.log("Menu.Sample.setMenu     this.menu.onKeyDown(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = true;
	}));
	dojo.connect(this.menu, "onKeyUp", dojo.hitch(this, function(event){
		console.log("Menu.Sample.setMenu     this.menu.onKeyUp(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = false;
	}));	
},
getProjectName : function () {
// RETURN THE PROJECT NAME FOR THIS FILE DRAG OBJECT
	
	// SANITY		
	if ( this.menu.currentTarget == null )	return null;

	// GET THE PROJECT WIDGET
	var item = this.menu.currentTarget.item;
	//////console.log("WorkflowMenu.newFolder     this.menu.currentTarget: " + this.menu.currentTarget);
	//////console.log("WorkflowMenu.newFolder     item: " + item);
	var widget = dijit.getEnclosingWidget(this.menu.currentTarget);
	var projectName = widget.path;

	return projectName;
}


}); // plugins.infusion.Menu.Sample
