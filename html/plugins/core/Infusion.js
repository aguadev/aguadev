dojo.provide("plugins.core.Infusion");

/*	PURPOSE

		1. PROVIDE INTERFACE WITH Agua DATA OBJECT REPRESENTATION
	
			OF THE DATA MODEL ON THE REMOTE SERVER

		2. PROVIDE METHODS TO CHANGE/INTERROGATE THE DATA OBJECT

		3. CALLS TO REMOTE SERVER TO REFLECT CHANGES ARE MOSTLY THE

			RESPONSIBILITY OF THE OBJECT USING THE Agua CLASS
	
	NOTES
	
		LOAD DATA WITH getData()
			
		LOAD PLUGINS WITH loadPlugins()
			- new pluginsManager
				- new Plugin PER MODULE
					- Plugin.loadPlugin CHECKS DEPENDENCIES AND LOADS MODULE
	
*/
if ( 1 ) {
// EXTERNAL MODULES
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dijit.Toolbar");
dojo.require("dijit.layout.TabContainer");
dojo.require("dijit.Tooltip");
dojo.require("dojox.widget.Standby");

// INTERNAL MODULES
// INHERITS
dojo.require("plugins.core.Common");
dojo.require("plugins.core.Conf");
dojo.require("plugins.core.Updater");
dojo.require("plugins.core.Agua.Data");
dojo.require("plugins.core.Agua.Access");
dojo.require("plugins.core.Agua.Ami");
dojo.require("plugins.core.Agua.App");
dojo.require("plugins.core.Agua.Aws");
dojo.require("plugins.core.Agua.Cloud");
dojo.require("plugins.core.Agua.Cluster");
dojo.require("plugins.core.Agua.Feature");
dojo.require("plugins.core.Agua.File");
dojo.require("plugins.core.Agua.Group");
dojo.require("plugins.core.Agua.Hub");
dojo.require("plugins.core.Agua.Package");
dojo.require("plugins.core.Agua.Parameter");
dojo.require("plugins.core.Agua.Project");
dojo.require("plugins.core.Agua.Report");
dojo.require("plugins.core.Agua.Shared");
dojo.require("plugins.core.Agua.Sharing");
dojo.require("plugins.core.Agua.Source");
dojo.require("plugins.core.Agua.Stage");
dojo.require("plugins.core.Agua.StageParameter");
dojo.require("plugins.core.Agua.User");
dojo.require("plugins.core.Agua.View");
dojo.require("plugins.core.Agua.Workflow");	
}
dojo.declare( "plugins.core.Infusion",
[
	dijit._Widget,
	dijit._Templated,
	plugins.core.Common,
	plugins.core.Agua.Data,
	plugins.core.Agua.Access,
	plugins.core.Agua.App,
	plugins.core.Agua.Ami,
	plugins.core.Agua.Aws,
	plugins.core.Agua.Cloud,
	plugins.core.Agua.Cluster,
	plugins.core.Agua.Feature,
	plugins.core.Agua.File,
	plugins.core.Agua.Group,
	plugins.core.Agua.Hub,
	plugins.core.Agua.Package,
	plugins.core.Agua.Parameter,
	plugins.core.Agua.Project,
	plugins.core.Agua.Report,
	plugins.core.Agua.Shared,
	plugins.core.Agua.Sharing,
	plugins.core.Agua.Source,
	plugins.core.Agua.Stage,
	plugins.core.Agua.StageParameter,
	plugins.core.Agua.User,
	plugins.core.Agua.View,
	plugins.core.Agua.Workflow
], {
name : "plugins.core.Agua",
version : "0.01",
description : "Create widget for positioning Plugin buttons and tab container for displaying Plugin tabs",
url : '',
dependencies : [],

// PLUGINS TO LOAD (NB: ORDER IS IMPORTANT FOR CORRECT LAYOUT)
pluginsList : [
	"plugins.data.Controller"
	//, "plugins.files.Controller"
	, "plugins.infusion.Controller"
	//, "plugins.apps.Controller"
	//, "plugins.sharing.Controller"
	//, "plugins.folders.Controller"
	//, "plugins.workflow.Controller"
	//, "plugins.view.Controller"
	, "plugins.home.Controller"
],

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "core/templates/agua.html"),	

// CSS files
cssFiles : [
	dojo.moduleUrl("plugins", "core/css/agua.css"),
	dojo.moduleUrl("plugins", "core/css/controls.css")
],

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CONTROLLERS
controllers : new Object(),

// DIV FOR PRELOAD SCREEN
splashNode : null,

// DIV TO DISPLAY PRELOAD MESSAGE BEFORE MODULES ARE LOADED
messageNode : null,

// PLUGIN MANAGER LOADS THE PLUGINS
pluginManager: null,

// COOKIES CONTAINS STORED USER ID AND SESSION ID
cookies : new Object,

// CONTAINS ALL LOADED CSS FILES
css : new Object,

// WEB URLs
cgiUrl : null,
htmlUrl : null,

// CHILD WIDGETS
widgets : new Object,

// TESTING - DON'T getData IF TRUE
testing: false,

////}}}}}}
// CONSTRUCTOR
constructor : function(args) {
	console.log("Infusion.constructor     plugins.core.Agua.constructor    args:");
	console.dir({args:args});

	this.cgiUrl = args.cgiUrl;
	this.htmlUrl = args.htmlUrl;
	if ( args.pluginsList != null )	this.pluginsList = args.pluginsList;
    this.database = args.database;
    this.dataUrl = args.dataUrl;
	console.log("Infusion.constructor     this.database: " + this.database);
	console.log("Infusion.constructor     this.testing: " + this.testing);
	console.log("Infusion.constructor     this.dataUrl: " + this.dataUrl); 
},
postCreate : function() {
	this.startup();
},
startup : function () {
// CHECK IF DEBUGGING AND LOAD PLUGINS
    console.group("Agua.startup");

	console.log("Infusion.startup    plugins.core.Agua.startup()");

	console.log("Infusion.startup    BEFORE loadCSS()");
	this.loadCSS();
	console.log("Infusion.startup    AFTER loadCSS()");
	
	// ATTACH THIS TEMPLATE TO attachPoint DIV ON HTML PAGE
	var attachPoint = dojo.byId("attachPoint");
	console.log("Infusion.startup    attachPoint:");
    console.dir({attachPoint:attachPoint});
	console.log("Infusion.startup    this.containerNode:");
    console.dir({this_containerNode:this.containerNode});

	attachPoint.appendChild(this.containerNode);

	// SET BUTTON LISTENER
	var listener = dojo.connect(this.aguaButton, "onClick", this, "reload");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// INITIALISE ELECTIVE UPDATER
	this.updater = new plugins.core.Updater();

	// SET LOADING PROGRESS STANDBY
	this.setStandby();

    // SET CONF
    this.setConf();
    
	// SET POPUP MESSAGE TOASTER
	this.setToaster();

	console.log("Infusion.startup    AFTER this.setToaster()");
    console.groupEnd("Agua.startup");

/*
	 GET DATA
	if ( this.dataUrl != null )	{
		console.log("Infusion.startup   Doing this.fetchJsonData()");
		this.fetchJsonData();
	}
	else if ( Data != null && Data.data != null ) {
		console.log("Infusion.startup   Doing this.loadData(Data.data)");
		this.loadData(Data.data);
	}
*/

},
setConf : function () {
	this.conf = new plugins.core.Conf({parent:this});
	this.conf.startup();
},
displayVersion : function () {
	console.log("Infusion.displayVersion     plugins.core.Agua.displayVersion()");
	
	// GET AGUA PACKAGE
	var packages = this.getPackages();
	console.log("Infusion.displayVersion    packages: ");
	console.dir({packages:packages});
	var packageObject = this._getObjectByKeyValue(packages, "package", "agua");
	console.log("Infusion.displayVersion    packageObject:");
	console.dir({packageObject:packageObject});
	if ( ! packageObject )	return;
	
	// DISPLAY VERSION
	var version = packageObject.version;
	console.log("Infusion.displayVersion     version: " + version);
	
	console.log("this.login.statusBar:");
	console.dir({statusBar:this.login.statusBar});

	//this.login.statusBar.aguaVersion.innerHTML = version;

	var aguaVersion = dojo.byId("aguaVersion");
	aguaVersion.innerHTML = version;
		
},
// START PLUGINS
startPlugins : function () {
	console.log("Infusion.startPlugins     plugins.core.Agua.startPlugins()");

	// DISABLE BACK BUTTON
	this.disableBackButton();

	//// DISABLE F5 RELOAD
	//this.disablePageReload();
	
	return this.loadPlugins(this.pluginsList);
},
disableBackButton : function () {
	console.log("Infusion.disableBackButton     plugins.core.Agua.disableBackButton()");
	window.history.forward(1);	
},
disablePageReload : function () {
	console.log("Infusion.disablePageReload     plugins.core.Agua.disablePageReload()");
//	dojo.connect(document, "onkeydown", this, "onKeyDownHandler");

	dojo.connect(document, "onkeydown", this, function (event) {
		console.log("Infusion.disablePageReload    event.keyCode: " + event.keyCode);

		if (event.keyCode === 116) {
			console.log("Infusion.disablePageReload    event.keyCode IS 116");
			event.stopPropagation();
			event.stopImmediatePropagation();
			console.log("Infusion.disablePageReload    DOING event.preventDefault()");
			event.preventDefault();
			return false;
		}
	});
	
	//document.onkeydown = function (e) {
	//  if (e.keyCode === 116) {
	//	return false;
	//  }
	//};

//	document.attachEvent("onkeydown", onKeyDownHandler);
},
onKeyDownHandler : function (event) {
	console.log("Infusion.onKeyDownHandler    event.keyCode: " + event.keyCode);

	switch (event.keyCode) {
		case 116 : // 'F5'
			event.returnValue = false;
			event.keyCode = 0;
			break;
	}
},
loadPlugins : function (pluginsList, pluginsArgs) {
	console.log("Infusion.loadPlugins    pluginsList: " + dojo.toJson(pluginsList));
	console.log("Infusion.loadPlugins    pluginsArgs: " + dojo.toJson(pluginsArgs));

	dojo.require("plugins.core.PluginManager");

	if ( pluginsList == null )	pluginsList = this.pluginsList;
	if ( pluginsArgs == null )	pluginsArgs = this.pluginsArgs;
	
	this.setStandby();
	console.dir({standby:this.standby});

	console.log("DOING this.standby.show()");
	this.standby.show();
	
	// LOAD PLUGINS
	console.log("Infusion.loadPlugins    Creating pluginsManager...");
	this.pluginManager = new plugins.core.PluginManager({
		parentWidget : this,
		pluginsList : pluginsList,
		pluginsArgs : pluginsArgs
	})
	console.log("Infusion.loadPlugins    After load PluginManager");
	
	//if ( this.controllers["home"] )	{
	//	console.log("Infusion.loadPlugins    this.controllers[home].createTab()");
	//	this.controllers["home"].createTab();
	//}
},
setStandby : function () {
	console.log("Infusion.setStandby    _GroupDragPane.setStandby()");
	if ( this.standby != null )	return this.standby;
	
	var id = dijit.getUniqueId("dojox_widget_Standby");
	this.standby = new dojox.widget.Standby (
		{
			target: this.containerNode,
			//onClick: "reload",
			centerIndicator : "text",
			text: "Waiting for remote featureName",
			id : id,
			url: "plugins/core/images/agua-biwave-24.png"
		}
	);
	document.body.appendChild(this.standby.domNode);
	dojo.addClass(this.standby.domNode, "view");
	dojo.addClass(this.standby.domNode, "standby");
	console.log("Infusion.setStandby    this.standby: " + this.standby);

	return this.standby;
},
addWidget : function (type, widget) {
    //console.log("Infusion.addWidget    core.Agua.addWidget(type, widget)");
    //console.log("Infusion.addWidget    type: " + type);
    //console.log("Infusion.addWidget    widget: " + widget);
    if ( Agua.widgets[type] == null ) {
        Agua.widgets[type] = new Array;
    }
    //console.log("Infusion.addWidget    BEFORE Agua.widgets[type].length: " + Agua.widgets[type].length);
    Agua.widgets[type].push(widget);
    //console.log("Infusion.addWidget    AFTER Agua.widgets[type].length: " + Agua.widgets[type].length);
},
removeWidget : function (type, widget) {
    console.log("Infusion.removeWidget    core.Agua.removeWidget(type, widget)");
    console.log("Infusion.removeWidget    type: " + type);
    console.log("Infusion.removeWidget    widget: " + widget);
        
    if ( Agua.widgets[type] == null )
    {
        console.log("Infusion.removeWidget    No widgets of type: " + type);
        return;
    }

    console.log("Infusion.removeWidget    BEFORE Agua.widgets[type].length: " + Agua.widgets[type].length);
    for ( var i = 0; i < Agua.widgets[type].length; i++ )
    {
        if ( Agua.widgets[type][i].id == widget.id )
        {
            Agua.widgets[type].splice(i, 1);
        }
    }
    console.log("Infusion.removeWidget    AFTER Agua.widgets[type].length: " + Agua.widgets[type].length);
},
addToolbarButton: function (label) {
// ADD MODULE BUTTON TO TOOLBAR
	//console.log("Infusion.addToolbarButton    plugins.core.Agua.addToolbarButton(label)");
	console.log("Infusion.addToolbarButton    label: " + label);
	console.log("Infusion.addToolbarButton    this.toolbar: " + this.toolbar);
	
	if ( this.toolbar == null )
	{
		//console.log("Infusion.addToolbarButton    this.toolbar is null. Returning");
		return;
	}
	
	var button = new dijit.form.Button({
		
		label: label,
		showLabel: true,
		//className: label,
		iconClass: "dijitEditorIcon dijitEditorIcon" + label
	});
	//console.log("Infusion.addToolbarButton    button: " + button);
	this.toolbar.addChild(button);
	
	return button;
},
cookie : function (name, value) {
// SET OR GET COOKIE-CONTAINED USER ID AND SESSION ID

	//console.log("Infusion.cookie     plugins.core.Agua.cookie(name, value)");
	//console.log("Infusion.cookie     name: " + name);
	//console.log("Infusion.cookie     value: " + value);		

	if ( value != null )
	{
		this.cookies[name] = value;
	}
	else if ( name != null )
	{
		return this.cookies[name];
	}

	//console.log("Infusion.cookie     this.cookies: " + dojo.toJson(this.cookies));

	return 0;
},
loadCSSFile : function (cssFile) {
// LOAD A CSS FILE IF NOT ALREADY LOADED, REGISTER IN this.loadedCssFiles
	//console.log("Infusion.loadCSSFile    cssFile: " + cssFile);
	//console.log("Infusion.loadCSSFile    this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));
	if ( this.loadedCssFiles == null || ! this.loadedCssFiles )
	{
		//console.log("Infusion.loadCSSFile    Creating this.loadedCssFiles = new Object");
		this.loadedCssFiles = new Object;
	}
	
	if ( ! this.loadedCssFiles[cssFile] )
	{
		console.log("Infusion.loadCSSFile    Loading cssFile: " + cssFile);
		
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		document.getElementsByTagName("head")[0].appendChild(cssNode);

		this.loadedCssFiles[cssFile] = 1;
	}
	else
	{
		//console.log("Infusion.loadCSSFile    No load. cssFile already exists: " + cssFile);
	}
	//console.log("Infusion.loadCSSFile    Returning this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));
	
	return this.loadedCssFiles;
},
// DATA METHODS
fetchJsonData : function() {
	console.log("Infusion.fetchJsonData    plugins.core.Agua.fetchJsonData()")	
	// GET URL 
    var url = this.dataUrl 
	console.log("Infusion.fetchJsonData    url: " + url);

    var thisObject = this;
    dojo.xhrGet({
        // The URL of the request
        url: url,
		sync: true,
        // Handle as JSON Data
        handleAs: "json",
        // The success callback with result from server
        handle: function(data) {
			console.log("Infusion.fetchJsonData    Setting this.data: " + data);
			thisObject.data = data;
        },
        // The error handler
        error: function() {
            console.log("Infusion.Error with JSON Post, response: " + response);
        }
    });
},
reload : function () {
// RELOAD AGUA
	//console.log("Infusion.constructor    plugins.core.Controls.reload()");
	var url = window.location;
	window.open(location, '_blank', 'toolbar=1,location=0,directories=0,status=0,menubar=1,scrollbars=1,resizable=1,navigation=0'); 

	//window.location.reload();
},
// LOGOUT
logout : function () {
	console.log("Infusion.logout    Doing delete this.data");
	delete this.data;


	var buttons = Agua.toolbar.getChildren();
	if ( ! buttons )	return;
	for ( var i = 0; i < buttons.length; i++ ) {
		var button = buttons[i];
		controller = button.parentWidget;
		console.log("Infusion.logout    controller " + i);
		console.dir({controller:controller});

		var name = controller.id.match(/plugins_([^_]+)/)[1]; 
		console.log("Infusion.logout    Doing delete Agua.controllers[" + name + "]");
		delete Agua.controllers[name];
		
		console.log("Infusion.logout    Doing controller.destroyRecursive()");
		if ( controller )
			controller.destroyRecursive();
	}	

	// DESTROY ALL WIDGETS
	dijit.registry.forEach(function(widget){
		console.log("Infusion.logout    widget: " + widget);	
		widget.destroy();
	});

	// RELOAD AGUA
	Agua = new plugins.core.Agua( {
		cgiUrl : "../cgi-bin/agua/"
		, htmlUrl : "../agua/"
	});

	Agua.login = new plugins.login.Login();

	
	console.log("Infusion.logout    COMPLETED");
}

}); // end of Agua
