dojo.provide("plugins.workflow.Workflow");

/*	CLASS SUMMARY
 	
	THIS IS THE MAIN CLASS IN THE WORKFLOW PLUGIN WHICH INSTANTIATES ALL THE OTHERS
 
	1. SET LEFT PANE
		Apps.js
		SharedApps.js
	
	2. MIDDLE PANE
		Stages.js --> Target.js/StageRow.js
		
	
	3. RIGHT PANE
		SET STAGES, HISTORY AND SHARED IN 
	


	WIDGET HIERARCHY
		
				1_to_1	   1_to_1	 
		Workflow --> Stages --> Target 
		 |              |
		 |              |1_to_many
		 |              |   
		 | 1_to_1       --> StageRow
		 |                     |
		 |                     | 1_to_1
		 |                     |
		 -----------------> Parameters --> ParameterRow
                                    1_to_many

    CORE MODULES LIST

    core.workflow       =   plugins.workflow.Workflow
    core.parameters  	=   plugins.workflow.Parameters
    core.stages         =   plugins.workflow.Stages
    core.target         =   plugins.workflow.Target
    core.fileManager    =   plugins.workflow.FileManager
    core.apps           =   plugins.workflow.Apps.Apps
    core.aguaPackages   =   plugins.workflow.Apps.AguaPackages
    core.adminPackages  =   plugins.workflow.App.AdminPackages


-	USAGE SCENARIO 1: CREATION AND LOADING OF A NEW WORKFLOW PANE
	
		--> CREATE RIGHT PANE Parameters.js AS this.Parameters

		--> CREATE MIDDLE PANE Workflows.js VIA ITS METHOD updateDropTarget
	
			--> CREATE DROP TARGET Target.js
		
				--> OVERRIDE onDndDrop TO CONVERT DROPPED NODE
				
					INTO StageRow.js WITH ONCLICK loadParametersPane
		
					(CALLS loadParametersPane METHOD IN Workflow.js
					
					WHICH IN TURN CALLS load METHOD OF Parameters.js
					
			--> CALL loadParametersPane METHOD IN Workflow.js
					
				--> CALLS load METHOD OF Parameters.js

					--> CALLS checkValidParameters IN StageRow

			--> CHECK VALIDITY OF OTHER StageRows (2, 3, 4, ...)

				--> CALL checkValidParameters IN StageRow
			
			--> UPDATE VALIDITY OF Stage.js (RunWorkflow BUTTON)
			

	USAGE SCENARIO 2: USER DROPS APPLICATION INTO TARGET
	
		1. onDndDrop METHOD IN Target.js
		
			--> CONVERTS App.js INTO StageRow.js
		
			--> CALLS loadParametersPane IN Workflow.js 
		
				--> CALLS load IN Parameters.js
				
					--> CALLS checkValidParameters IN StageRow


	USAGE SCENARIO 3: USER UPDATES PARAMETER IN DATA PANE
	
		1. ParameterRow.js CHECKS VALIDITY AND PRESENCE OF FILES
	
			--> CALLS checkValidInputs METHOD OF Parameters.js
			
				GETS this.isValid FROM VALIDITY OF ALL PARAMETERS 
			
				--> CALLS setValid/setInvalid OF StageRow.js 
		
					--> CALLS updateRunButton OF Stages.js
					
						POLL VALIDITY OF ALL StageRows
						
						SET RunWorkflow BUTTON IF ALL STAGES VALID

*/


if ( 1 ) {
// EXTERNAL MODULES

// EXPANDOPANE
dojo.require("dojox.layout.ExpandoPane");

// FILE UPLOAD
dojo.require("plugins.form.UploadDialog");

// NOTES EDITOR
dojo.require("dijit.form.Textarea");

dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.ValidationTextBox");
dojo.require("dijit.form.NumberTextBox");
dojo.require("dijit.form.CurrencyTextBox");
dojo.require("dojo.currency");
dojo.require("dijit.Dialog");

// WIDGETS AND TOOLS FOR EXPANDO PANE
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.Tree");
dojo.require("dijit.layout.AccordionContainer");
dojo.require("dijit.layout.TabContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.layout.BorderContainer");
dojo.require("dojox.layout.FloatingPane");
dojo.require("dojo.fx.easing");
dojo.require("dojox.rpc.Service");
dojo.require("dojo.io.script");
dojo.require("dijit.TitlePane");

// DnD
dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");

// Menu
dojo.require("plugins.menu.Menu");

// TIMER
dojo.require("dojox.timing");

// TOOLTIP
dojo.require("dijit.Tooltip");

// TOOLTIP DIALOGUE
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Textarea");
dojo.require("dijit.form.CheckBox");
dojo.require("dijit.form.Button");

// INHERITED
dojo.require("plugins.core.Common");

// LAYOUT WIDGETS
dojo.require("dijit.layout.SplitContainer");
dojo.require("dijit.layout.ContentPane");

// INTERNAL MODULES
dojo.require("plugins.workflow.Parameters");
}

dojo.declare( "plugins.workflow.Workflow",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/workflow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CSS FILE FOR BUTTON STYLING
cssFiles : [
    dojo.moduleUrl("plugins") + "workflow/css/workflow.css",
    dojo.moduleUrl("plugins") + "workflow/css/history.css",
    dojo.moduleUrl("plugins") + "workflow/css/shared.css",
    dojo.moduleUrl("dojox") + "layout/resources/ExpandoPane.css",
    dojo.moduleUrl("dijit") + "themes/tundra/tundra.css"
	
    //dojo.moduleUrl("plugins", "workflow/css/workflow.css"),
],

// PARENT NODE, I.E., TABS NODE
attachWidget : null,

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,
workflow : null,

// POLL SERVER FOR WORKFLOW STATUS
polling : false,

// INSERT TEXT BREAKS WIDTH, CORRESPONDS TO CSS WIDTH OF INPUT 'value' TABLE ELEMENT
textBreakWidth : 22,

// plugins.workflow.FileManager
fileManager : null,

// CORE WORKFLOW OBJECTS
core : new Object,

// LOAD PANELS
// loadPanels: array of names of panels to be loaded
loadPanels : null,

////}}}
constructor : function(args) {
// LOAD CSS
	this.loadCSS();
	
	// SET ARGS
	this.attachWidget = Agua.tabs;

	if ( args != null )
	{
		this.
		project = args.project;
		this.workflow = args.workflow;
	}
	
	// SET CORE CLASSES
	this.core.workflow = this;

	// SET LOAD PANELS
	this.setLoadPanels(args);
},
postCreate: function() {
	this.startup();
},
startup : function () {
// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

    // ADD THIS WIDGET TO Agua
    Agua.addWidget("workflow", this);

	// ADD THE PANE TO THE TAB CONTAINER
	this.attachWidget.addChild(this.mainTab);
	this.attachWidget.selectChild(this.mainTab);

	// INSTANTIATE MODULES	
	var modules = [
		[ "plugins.workflow.Apps.AdminPackages", "adminPackages", this.leftPane ]
		,[ "plugins.workflow.Apps.AguaPackages", "aguaPackages", this.leftPane ]
		, [ "plugins.workflow.Parameters", "parameters", this.rightPane ]
		, [ "plugins.workflow.Grid", "grid", this.middlePane ]
		, [ "plugins.workflow.UserWorkflows", "userWorkflows", this.middlePane ]
		, [ "plugins.workflow.SharedWorkflows", "sharedWorkflows", this.middlePane ]
		, [ "plugins.workflow.History", "historyPane", this.middlePane ]
		, ["plugins.workflow.RunStatus.Status", "runStatus", this.rightPane ]
	];
	
	console.log("Workflow.startup    this.loadPanels:")
	console.dir({this_loadPanels:this.loadPanels});
	for ( var i = 0; i < modules.length; i++ )
	{
		var module = modules[i];

		if ( this.loadPanels && ! this.loadPanels[module[1].toLowerCase()] ) {
			console.log("Workflow.startup    Skipping panel for module: " + module[1]);
			continue;
		}

		this.setCoreWidget(module[0], module[1], module[2]);
	}

	// CLOSE LEFT PANE / MIDDLE PANE
	//this.leftPaneExpando.toggle();
	//this.middlePaneExpando.toggle();

	// SET PROJECT COMBO IF this.project IS DEFINED
	console.log("Workflow.startup    BEFORE this.core.userWorkflows.setProjectCombo()");
	console.log("Workflow.startup    this.project: " + this.project);
	console.log("Workflow.startup    this.workflow: " + this.workflow);
	
	if ( this.project != null && this.core.userWorkflows != null )
		this.core.userWorkflows.setProjectCombo(this.project, this.workflow);
},
setCoreWidget : function (moduleName, name, pane) {
// INSTANTIATE A moduleName WIDGET AND SET IT AS this.core.name
	console.log("Workflow.setCoreWidget    moduleName: " + moduleName);
	//console.log("Workflow.setCoreWidget    name: " + name);
	//console.log("Workflow.setCoreWidget    pane: " + pane);

	console.log("Workflow.setCoreWidget    BEFORE dojo.require moduleName: " + moduleName);
	dojo["require"](moduleName);
	console.log("Workflow.setCoreWidget    AFTER dojo.require moduleName: " + moduleName);
	
	if ( this[name] != null ) return;

	var module = dojo.getObject(moduleName);
	console.log("Workflow.setCoreWidget    module: ");
	console.dir({module:module});
	
	this[name] = new module(
	{
		attachNode : pane,
		parentWidget: this,
		core: this.core
	});
	console.log("Workflow.setCoreWidget    this[" + name + "]: " + this[name]);

	this.core[name] = this[name];
},
setParameters : function () {
// SET DATA TAB IN INFO PANE BY INSTANTIATING Parameters OBJECT
	////console.log("Workflow.setParameters    plugins.workflow.Stages.setParameters()");
	this.core.parameters = new plugins.workflow.Parameters({
		attachNode : this.rightPane,
		parentWidget: this,
		core: this.core
	});
	////console.log("Workflow.setParameters    this.core.parameters: ");
	////console.dir({this_core_parameters:this.core.parameters});
},
destroyRecursive : function () {
	console.log("Workflow.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});

	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}


}); // end of plugins.workflow.Workflow

