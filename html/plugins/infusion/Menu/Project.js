dojo.provide("plugins.infusion.Menu.Project");

// WIDGET PARSER
dojo.require("dojo.parser");

// INHERITS
dojo.require("plugins.infusion.Menu.Base");

dojo.declare("plugins.infusion.Menu.Project",
	[ plugins.infusion.Menu.Base ], {
		
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/infusion/Menu/templates/project.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/infusion/Menu/css/project.css"),
	require.toUrl("dojox/form/resources/FileInput.css")
],

// delay: Integer (thousandths of a second)
// Poll delay
delay : 6000,

/////}}
	
startup : function () {
	console.group("Menu.Project    " + this.id + "    startup");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// DISABLE MENU ITEMS
	//this.disableMenuItem('select');
	//this.disableMenuItem('add');

	// STARTUP MENU
	this.menu._started = false;
	this.menu.startup();

	// STOP PROPAGATION TO NORMAL RIGHTCLICK CONTEXT MENU
	dojo.connect(this.menu.domNode, "oncontextmenu", function (event) {
		event.stopPropagation();
	});

	console.groupEnd("Menu.Project    " + this.id + "    startup");
},
// EDIT
newProject : function () {
	this.core.dialogs.showUploadDialog();
},
// EDIT
edit : function () {
	var projectName = this.currentProject;
	console.log("Menu.Project.edit    projectName: " + projectName);
	
	var object = this.core.data.getProjectObject(projectName);
	console.log("Menu.Project.edit    object: " + object);
	console.dir({object:object});
	
	this.core.dialogs.showProjectDialog(object);
},
// COMPLETE
complete : function (event) {
	console.log("Menu.Project.complete     this.projectName: " + projectName);
	this.confirmAction("completeProject", "Complete", this.doComplete);
},
doComplete : function (projectName) {
// UPDATE PROJECT IN data TABLES
	console.log("Menu.Project.doComplete    projectName: " + projectName);
},
// CANCEL
cancel : function () {
	this.confirmAction("cancelProject", "Cancel", this.doCancel);
},
doCancel : function (projectName) {
// UPDATE PROJECT IN data TABLES
	console.log("Menu.Project.doCancel    projectName: " + projectName);
},
// HOLD
hold : function () {
	this.confirmAction("holdProject", "Hold", this.doHold);
},
doHold : function (projectName) {
// UPDATE PROJECT IN data TABLES
	console.log("Menu.Project.doHold    projectName: " + projectName);

},
setShortKeys : function () {
	// NOTE: USE accelKey IN DOJO 1.3 ONWARDS
	dojo.connect(this.menu, "onKeyPress", dojo.hitch(this, function(event)
	{
		console.log("Menu.Project.setMenu     this.menu.onKeyPress(event)");
		var key = event.keyCode;
		if ( this.altOn == true )
		{
			switch (key)
			{
				case "n" : this.newProject(); break;
				case "e" : this.edit(); break;
				case "c" : this.complete(); break;
				case "l" : this.cancel(); break;
				case "h" : this.hold(); break;
			}
		}
		event.stopPropagation();
	}));

	// SET ALT KEY ON/OFF
	dojo.connect(this.menu, "onKeyDown", dojo.hitch(this, function(event){
		console.log("Menu.Project.setMenu     this.menu.onKeyDown(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = true;
	}));
	dojo.connect(this.menu, "onKeyUp", dojo.hitch(this, function(event){
		console.log("Menu.Project.setMenu     this.menu.onKeyUp(event)");
		var keycode = event.keyCode;
		if ( keycode == 18 )	this.altOn = false;
	}));	
}

}); // plugins.infusion.Menu.Project
