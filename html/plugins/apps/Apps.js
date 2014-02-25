dojo.provide("plugins.apps.Apps");

dojo.require("plugins.core.Common");

// DISPLAY DIFFERENT PAGES TO ALLOW THE apps AND ORDINARY
// USERS TO MODIFY THEIR SETTINGS

// DnD
dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");

// DIJITS
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.layout.ContentPane");

// rightPane buttons
dojo.require("dijit.form.Button");

dojo.declare( "plugins.apps.Apps", 
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "apps/templates/apps.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PANE WIDGETS
paneWidgets : null,

// CORE WORKFLOW OBJECTS
core : new Object,

cssFiles : [
	dojo.moduleUrl("plugins", "apps/css/apps.css")
],

// DEBUG: LIST OF PANELS TO LOAD
// paneList: ';'-separated String
panelList: null,

// INPUTS PASSED FROM CONTROLLER
// inputs: ';'-separated String
inputs : null,

// LOAD PANELS
// loadPanels: array of names of panels to be loaded
loadPanels : null,

/////}}
constructor : function(args) {
	console.log("apps.Apps.constructor    args:");
	console.dir({args:args});

	// SET LOAD PANELS
	this.setLoadPanels(args);
	
	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	////console.log("Apps.postCreate    plugins.apps.Controller.postCreate()");

	this.startup();
},
startup : function () {
	//console.log("Apps.startup    plugins.apps.Controller.startup()");

    // ADD THIS WIDGET TO Agua.widgets
    Agua.addWidget("apps", this);

	// CREATE HASH TO HOLD INSTANTIATED PANE WIDGETS
	this.paneWidgets = new Object;

	// LOAD HEADINGS FOR THIS USER
	this.headings = Agua.getAppHeadings();
	console.log("Apps.startup    this.headings:");
	console.dir({this_headings:this.headings});

	this.attachPane();
	
	// LOAD PANES
	this.loadPanes();
},
attachPane : function () {
	console.log("Apps.attachPane    Agua.tabs:");
	console.dir({Agua_tabs:Agua.tabs});
	console.log("Apps.attachPane    this.mainTab:");
	console.dir({this_mainTab:this.mainTab});

	// ADD mainTab TO CONTAINER		
	Agua.tabs.addChild(this.mainTab);
	Agua.tabs.selectChild(this.mainTab);
},
reload : function (target) {
//	reload
//		RELOAD A WIDGET, WIDGETS IN A PANE OR ALL WIDGETS
//	inputs:
//		target	:	'aguaApplication' | 'adminApplications'

	console.log("Apps.reload     plugins.apps.Apps.reload(target)");
	console.log("Apps.reload     target: " + target);

	if ( target == "all" ) {
		for ( var mainPane in this.headings )
		{
			for ( var i in this.headings[mainPane] )
			{
				this.reloadWidget(this.headings[mainPane][i]);
			}
		}
	}
	else if ( target == "leftPane"
			|| target == "middlePane"
			|| target == "rightPane" )
	{
		for ( var i in this.headings[target] )
		{
			this.reloadWidget(this.headings[target][i]);
		}
	}
	
	// OTHERWISE, THE target MUST BE A PANE NAME
	else
	{
		try {
			this.reloadWidget(target);
		}
		catch (e) {}
	}		
},
reloadWidget : function (paneName) {
// REINSTANTIATE A PANE WIDGET
	////console.log("Apps.reloadWidget     Reloading pane: " + paneName);

	delete this.paneWidgets[paneName];

	var thisObject = this;
	this.paneWidgets[paneName] = new plugins.apps[paneName](
		{
			parentWidget	:	thisObject,
			attachPoint 	:	thisObject.leftTabContainer
		}
	);
},
loadPanes : function () {
	var panes = ["left", "middle", "right"];
	for ( var i = 0; i < panes.length; i++ )
	{
		this.loadPane(panes[i]);
	}
},
loadPane : function(side) {
	console.log("Apps.loadPane     side: " + side);
	console.log("Apps.loadPane     this.loadPanels: ");
	console.dir({this_loadPanels:this.loadPanels});
	
	//console.log("Apps.loadPane     side: " + dojo.toJson(side));
	var pane = side + "Pane";
	var tabContainer = side + "TabContainer";
	if ( this.headings == null || this.headings[pane] == null )	return;
	for ( var i = 0; i < this.headings[pane].length; i++ )
	{
		//console.log("Apps.loadLeftPane     LOADING PANE this.headings[pane][" + i + "]: " + this.headings[pane][i]);

		var tabPaneName = this.headings[pane][i];
		console.log("Apps.loadPane    dojo.require tabPaneName: " + tabPaneName);

		if ( this.loadPanels && ! this.loadPanels[tabPaneName.toLowerCase()] ) {
			console.log("Apps.loadPane    Skipping panel: " + tabPaneName);
			continue;
		}

		var moduleName = "plugins.apps." + tabPaneName;
		console.log("Apps.loadPane    BEFORE dojo.require moduleName: " + moduleName);
		
		dojo["require"](moduleName);
		console.log("Apps.loadPane    AFTER dojo.require moduleName: " + moduleName);
		
		var thisObject = this;
		var tabPane = new plugins["apps"][tabPaneName](
			{
				parentWidget:	thisObject,
				attachPoint 	:	thisObject[tabContainer]
			}
		);
		
		// REGISTER THE NEW TAB PANE IN this.paneWidgets 
		if( this.paneWidgets[moduleName] == null )
			this.paneWidgets[moduleName] = new Array;
		this.paneWidgets[moduleName].push(tabPane);
	}
},
destroyRecursive : function () {
	console.log("Apps.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});

	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}

}); // end of plugins.apps.Apps

