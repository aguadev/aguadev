dojo.provide("plugins.sharing.Sharing");

// ALLOW USER TO MANAGE SHARED RESOURCES AND GROUPS
dojo.require("plugins.core.Common");

// DnD
dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");

// comboBox data store
dojo.require("dojo.store.Memory");
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.layout.ContentPane");

// rightPane buttons
dojo.require("dijit.form.Button");

/*
// TEMPLATE MODULES
//LEFT PANE
dojo.require("plugins.sharing.Apps");
dojo.require("plugins.sharing.GroupProjects");
dojo.require("plugins.sharing.Settings");
dojo.require("plugins.sharing.Clusters");

// MIDDLE PANE
dojo.require("plugins.sharing.Parameter");
dojo.require("plugins.sharing.Groups");
dojo.require("plugins.sharing.Projects");
dojo.require("plugins.sharing.Access");

// RIGHT PANE
dojo.require("plugins.sharing.GroupSources");
dojo.require("plugins.sharing.GroupUsers");
dojo.require("plugins.sharing.Sources");
dojo.require("plugins.sharing.Users");
*/

dojo.declare( "plugins.sharing.Sharing", 
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/sharing.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PANE WIDGETS
paneWidgets : null,

// CORE WORKFLOW OBJECTS
core : new Object,

cssFiles : [
	dojo.moduleUrl("plugins", "sharing/css/sharing.css")
],

modules : {
// LEFT PANE
	"GroupProjects"	:	"plugins.sharing.GroupProjects",
	"Settings"	:	"plugins.sharing.Settings",
	"Clusters"	:	"plugins.sharing.Clusters",
	
	// MIDDLE PANE
	"Groups"	:	"plugins.sharing.Groups",
	"Projects"	:	"plugins.sharing.Projects",
	"Access"	:	"plugins.sharing.Access",
	
	// RIGHT PANE
	"GroupSources"	:	"plugins.sharing.GroupSources",
	"GroupUsers":	"plugins.sharing.GroupUsers",
	"Sources"	:	"plugins.sharing.Sources",
	"Users"		:	"plugins.sharing.Users"
},
/////}}

constructor : function(args) {	
	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	////console.log("Controller.postCreate    plugins.sharing.Controller.postCreate()");

	this.startup();
},
startup : function () {
	//console.log("Controller.startup    plugins.sharing.Controller.startup()");

    // ADD THIS WIDGET TO Agua.widgets
    Agua.addWidget("sharing", this);

	// ATTACH PANE
	this.attachPane();
	
	// CREATE HASH TO HOLD INSTANTIATED PANE WIDGETS
	this.paneWidgets = new Object;

	// LOAD HEADINGS FOR THIS USER
	//this.headings = Agua.getSharingHeadings();
	this.headings = {
		leftPane: [
			"Groups"
		],
		middlePane	:[
			"GroupProjects"
		]
	};
	
	// LOAD PANES
	this.loadPanes();
},
attachPane : function () {
	console.log("Sharing.attachPane    Agua.tabs");
	console.dir({Agua_tabs:Agua.tabs});
	
	Agua.tabs.addChild(this.mainTab);
	Agua.tabs.selectChild(this.mainTab);
},
reload : function (target) {
// RELOAD A WIDGET, WIDGETS IN A PANE OR ALL WIDGETS
	////console.log("Sharing.reload     plugins.sharing.Sharing.reload(target)");
	////console.log("Sharing.reload     target: " + target);

	if ( target == "all" )
	{
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
	////console.log("Sharing.reloadWidget     Reloading pane: " + paneName);

	delete this.paneWidgets[paneName];

	var thisObject = this;
	this.paneWidgets[paneName] = new plugins.sharing[paneName](
		{
			parentWidget: thisObject,
			attachPoint : thisObject.leftTabContainer
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
	//console.log("Sharing.loadPane     plugins.sharing.Sharing.loadPane(side)");
	//console.log("Sharing.loadPane     side: " + dojo.toJson(side));
	var pane = side + "Pane";
	var tabContainer = side + "TabContainer";
	if ( this.headings == null || this.headings[pane] == null )	return;
	for ( var i = 0; i < this.headings[pane].length; i++ )
	{
		//console.log("Sharing.loadLeftPane     LOADING PANE this.headings[pane][" + i + "]: " + this.headings[pane][i]);

		var tabPaneName = this.headings[pane][i];
		console.log("Sharing.loadPane    dojo.require tabPaneName: " + tabPaneName);
		var moduleName = this.modules[tabPaneName];
		console.log("Sharing.loadPane    BEFORE dojo.require moduleName: " + moduleName);
		dojo["require"](moduleName);
		console.log("Sharing.loadPane    AFTER dojo.require moduleName: " + moduleName);
		
		var thisObject = this;
		var tabPane = new plugins["sharing"][tabPaneName](
			{
				parentWidget: thisObject,
				attachPoint : thisObject[tabContainer]
			}
		);
		
		// REGISTER THE NEW TAB PANE IN this.paneWidgets 
		if( this.paneWidgets[moduleName] == null )
			this.paneWidgets[moduleName] = new Array;
		this.paneWidgets[moduleName].push(tabPane);
	}
},
destroyRecursive : function () {
	console.log("Sharing.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});

	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}


}); // end of plugins.sharing.Sharing

