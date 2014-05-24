/*	PURPOSE

		1. PROVIDE INTERFACE WITH DATA MODEL ON THE REMOTE SERVER

		2. PROVIDE METHODS TO CHANGE/INTERROGATE THE DATA OBJECT

		3. CALL REMOTE SERVER TO PROPAGATE DATA CHANGES
	
	NOTES
	
		USAGE SCENARIOS:
		
			LOAD DATA
			Agua.getData()
				
			LOAD PLUGINS
			Agua.loadPlugins()
				- new pluginsManager
					- new Plugin PER MODULE
						- Plugin.loadPlugin CHECKS DEPENDENCIES AND LOADS MODULE
	
*/

define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	'dojo/Deferred',
	"dojo/when",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/registry",
	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/core/Common",
	"plugins/exchange/Exchange",
	"plugins/data/Controller",
	"plugins/core/Updater",
	"plugins/core/Conf",

	// INTERNAL MODULES
	"plugins/core/Agua/Data",
	"plugins/core/Agua/Access",
	"plugins/core/Agua/App",
	"plugins/core/Agua/Ami",
	"plugins/core/Agua/Aws",
	"plugins/core/Agua/Cloud",
	"plugins/core/Agua/Cluster",
	"plugins/core/Agua/Exchange",
	"plugins/core/Agua/Feature",
	"plugins/core/Agua/File",
	"plugins/core/Agua/Group",
	"plugins/core/Agua/Hub",
	"plugins/core/Agua/Package",
	"plugins/core/Agua/Parameter",
	"plugins/core/Agua/Project",
	"plugins/core/Agua/Report",
	"plugins/core/Agua/Request",
	"plugins/core/Agua/Shared",
	"plugins/core/Agua/Sharing",
	"plugins/core/Agua/Source",
	"plugins/core/Agua/Stage",
	"plugins/core/Agua/StageParameter",
	"plugins/core/Agua/User",
	"plugins/core/Agua/View",
	"plugins/core/Agua/Workflow",
	"plugins/core/PluginManager",

	// Login
	"plugins/login/Login",

	// EXTERNAL MODULES
	"dijit/Toolbar",
	"dijit/layout/TabContainer",
	"dijit/Tooltip",
	"dojox/widget/Standby"
],
	   
function (
	declare,
	arrayUtil,
	JSON,
	on,
	Deferred,
	when,
	lang,
	domAttr,
	domClass,
	registry,
	_Widget,
	_Templated,
	Common,
	Exchange,
	DataController,
	Updater,
	Conf,
	AguaData,
	AguaAccess,
	AguaApp,
	AguaAmi,
	AguaAws,
	AguaCloud,
	AguaCluster,
	AguaExchange,
	AguaFeature,
	AguaFile,
	AguaGroup,
	AguaHub,
	AguaPackage,
	AguaParameter,
	AguaProject,
	AguaRequest,
	AguaReport,
	AguaShared,
	AguaSharing,
	AguaSource,
	AguaStage,
	AguaStageParameter,
	AguaUser,
	AguaView,
	AguaWorkflow,
	PluginManager,
	Login
) {
////}}}}}
return declare("plugins.core.Agua",
[
	_Widget,
	_Templated,
	Common,
	AguaData,
	AguaAccess,
	AguaApp,
	AguaAmi,
	AguaAws,
	AguaCloud,
	AguaCluster,
	AguaExchange,
	AguaFeature,
	AguaFile,
	AguaGroup,
	AguaHub,
	AguaPackage,
	AguaParameter,
	AguaProject,
	AguaReport,
	AguaRequest,
	AguaShared,
	AguaSharing,
	AguaSource,
	AguaStage,
	AguaStageParameter,
	AguaUser,
	AguaView,
	AguaWorkflow
], {

name : "plugins.core.Agua",
version : "0.01",
description : "Create widget for positioning Plugin buttons and tab container for displaying Plugin tabs",
url : '',
dependencies : [],

// PLUGINS TO LOAD (NB: ORDER IS IMPORTANT FOR CORRECT LAYOUT)
pluginsList : [
	"plugins.files.Controller"
	, "plugins.apps.Controller"
	, "plugins.sharing.Controller"
	, "plugins.folders.Controller"
	, "plugins.workflow.Controller"
	, "plugins.view.Controller"
	, "plugins.cloud.Controller"
	//, "plugins.request.Controller"
	//, "plugins.home.Controller"
],

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/core/templates/agua.html"),	

// CSS files
cssFiles : [
	require.toUrl("plugins/core/css/agua.css"),
	require.toUrl("plugins/core/css/controls.css")
],

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CONTROLLERS
controllers : [],

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

// token : String
//		16-letter aA# used to uniquely identify this object for WebSocket traffic
token : null,

// doLogin : Boolean
//		Call method 'login' if true, use false for testing
doLogin : true,

////}}}}}}

// CONSTRUCTOR
constructor : function(args) {
	console.log("Agua.constructor     plugins.core.Agua.constructor    args:");
	console.dir({args:args});

	this.cgiUrl = args.cgiUrl;
	this.htmlUrl = args.htmlUrl;
	if ( args.pluginsList != null )	this.pluginsList = args.pluginsList;
    this.database = args.database;
    this.dataUrl = args.dataUrl;
	console.log("Agua.constructor     this.database: " + this.database);
	console.log("Agua.constructor     this.testing: " + this.testing);
	console.log("Agua.constructor     this.dataUrl: " + this.dataUrl); 
},
postCreate : function() {
	this.startup();
},
startup : function () {
    console.group("Agua.startup");
	
	// SET GLOBAL Agua
	window.Agua = this;
	
	console.log("Agua.startup    BEFORE loadCSS()");
	this.loadCSS();
	console.log("Agua.startup    AFTER loadCSS()");
	
	// ATTACH PANE
	this.attachPane();

	// SET BUTTON LISTENER
	var listener = dojo.connect(this.aguaButton, "onClick", this, "reload");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// SET AUTOHIDE
	//console.log("Agua.startup    BEFORE setAutoHide()");
	this.setAutoHide();
	//console.log("Agua.startup    AFTER setAutoHide()");

	// SET EXCHANGE 
	console.log("Agua.startup    BEFORE this.setExchange()");
	var thisObject = this;
	this.setExchange(Exchange).then( function() {

		// INITIALISE ELECTIVE UPDATER
		thisObject.updater = new Updater();
		console.log("Agua.startup    new plugins.core.Updater()");
	
		// SET LOADING PROGRESS STANDBY
		console.log("Agua.startup    BEFORE thisObject.setStandby()");
		thisObject.setStandby();
		console.log("Agua.startup    AFTER thisObject.setStandby()");
	
		// SET CONF
		console.log("Agua.startup    BEFORE thisObject.setConf()");
		thisObject.setConf();
		console.log("Agua.startup    AFTER thisObject.setConf()");
		
		// SET POPUP MESSAGE TOASTER
		console.log("Agua.startup    BEFORE thisObject.setToaster()");
		thisObject.setToaster();
		console.log("Agua.startup    AFTER thisObject.setToaster()");
	
		// SHOW LOGIN
		console.log("Agua.startup    BEFORE thisObject.doLogin()");
		console.log("Agua.startup    Agua");
		console.dir({Agua:Agua});
	
		thisObject.doLogin();
		console.log("Agua.startup    AFTER thisObject.doLogin()");

	});

	console.log("Agua.startup    AFTER this.setExchange()");

	
    console.groupEnd("Agua.startup");
},
/**
 * Run a function that will eventually resolve the named Deferred
 * (milestone).
 * @param {String} name the name of the Deferred
 */
_milestoneFunction : function( /**String*/ name, func ) {

    console.log("Browser._milestoneFunction    name: " + name);
    
    var thisB = this;
    var args = Array.prototype.slice.call( arguments, 2 );

    var d = thisB._getDeferred( name );
    args.unshift( d );
    try {
        func.apply( thisB, args ) ;
    } catch(e) {
        console.error( e, e.stack );
        d.resolve({ success:false, error: e });
    }

    return d;
},
/**
 * Fetch or create a named Deferred, which is how milestones are implemented.
 */
_getDeferred : function( name ) {
    if( ! this._deferred )
        this._deferred = {};
    return this._deferred[name] = this._deferred[name] || new Deferred();
},
/**
 * Attach a callback to a milestone.
 */
afterMilestone : function( name, func ) {
    return this._getDeferred(name)
        .then( function() {
                   try {
                       func();
                   } catch( e ) {
                       console.error( ''+e, e.stack, e );
                   }
               });
},
/**
 * Indicate that we've reached a milestone in the initalization
 * process.  Will run all the callbacks associated with that
 * milestone.
 */
passMilestone : function( name, result ) {
    return this._getDeferred(name).resolve( result );
},
/**
 * Return true if we have reached the named milestone, false otherwise.
 */
reachedMilestone : function( name ) {
    return this._getDeferred(name).fired >= 0;
},
/**
 *  Load our configuration file(s) based on the parameters the
 *  constructor was passed.  Does not return until all files are
 *  loaded and merged in.
 *  @returns nothing meaningful
 */

attachPane : function () {
	// ATTACH THIS TEMPLATE TO attachPoint DIV ON HTML PAGE
	var attachPoint = dojo.byId("attachPoint");
	console.log("Agua.attachPane    attachPoint:");
    console.dir({attachPoint:attachPoint});
	console.log("Agua.attachPane    this.containerNode:");
    console.dir({this_containerNode:this.containerNode});

	attachPoint.appendChild(this.containerNode);
},
setAutoHide : function () {
	if ( ! this.toolbar.containerNode ) {
		console.log("Agua.setAutoHide    this.toolbar.containerNode not defined. Returning");
		return;
	}
	var thisObject = this;
	this.toolbar.containerNode.onmouseover = function () {
		//console.log("Agua.setAutoHide     onmouseover FIRED");
		dojo.attr(thisObject.toolbar.containerNode, "height", "30px !important");
	};
	this.toolbar.containerNode.onmouseout = function () {
		//console.log("Agua.setAutoHide     onmouseout FIRED");
		dojo.attr(thisObject.toolbar.containerNode, "height", "0px !important");
	};
},
setConf : function () {
	this.conf = new Conf({parent:this});
	this.conf.startup();
},
displayVersion : function () {
	console.log("Agua.displayVersion     plugins.core.Agua.displayVersion()");
	
	// GET AGUA PACKAGE
	var packages = this.getPackages();
	console.log("Agua.displayVersion    packages: ");
	console.dir({packages:packages});
	var packageObject = this._getObjectByKeyValue(packages, "package", "agua");
	console.log("Agua.displayVersion    packageObject:");
	console.dir({packageObject:packageObject});
	if ( ! packageObject )	return;
	
	// DISPLAY VERSION
	var version = packageObject.version;
	console.log("Agua.displayVersion     version: " + version);
	
	console.log("this.login.statusBar:");
	console.dir({statusBar:this.login.statusBar});

	var aguaVersion = dojo.byId("aguaVersion");
	aguaVersion.innerHTML = version;
		
},
// LOAD DATA
loadData : function () {
	console.log("Agua.loadData    DOING new DataController({})");
	Agua.controllers["data"]	=	new DataController({});
	console.log("Agua.loadData    AFTER new DataController({})");
},
// START PLUGINS
startPlugins : function () {
	console.log("Agua.startPlugins     plugins.core.Agua.startPlugins()");

	// DISABLE BACK BUTTON
	this.disableBackButton();
	
	//// DISABLE F5 RELOAD
	//this.disablePageReload();
	
	return this.loadPlugins(this.pluginsList);
},
disableBackButton : function () {
	console.log("Agua.disableBackButton     plugins.core.Agua.disableBackButton()");
	window.history.forward(1);	
},
disablePageReload : function () {
	console.log("Agua.disablePageReload     plugins.core.Agua.disablePageReload()");
//	dojo.connect(document, "onkeydown", this, "onKeyDownHandler");

	dojo.connect(document, "onkeydown", this, function (event) {
		console.log("Agua.disablePageReload    event.keyCode: " + event.keyCode);

		if (event.keyCode === 116) {
			console.log("Agua.disablePageReload    event.keyCode IS 116");
			event.stopPropagation();
			event.stopImmediatePropagation();
			console.log("Agua.disablePageReload    DOING event.preventDefault()");
			event.preventDefault();
			return false;
		}
	});	
},
onKeyDownHandler : function (event) {
	console.log("Agua.onKeyDownHandler    event.keyCode: " + event.keyCode);

	switch (event.keyCode) {
		case 116 : // 'F5'
			event.returnValue = false;
			event.keyCode = 0;
			break;
	}
},
loadPlugins : function (pluginsList, pluginsArgs) {
	console.log("Agua.loadPlugins    pluginsList: " + dojo.toJson(pluginsList));
	console.log("Agua.loadPlugins    pluginsArgs: " + dojo.toJson(pluginsArgs));

//console.log("Agua.loadPlugins    DEBUG RETURN");
//return;

	if ( pluginsList == null )	pluginsList = this.pluginsList;
	if ( pluginsArgs == null )	pluginsArgs = this.pluginsArgs;
	
	this.setStandby();

	console.log("Agua.loadPlugins    DOING this.standby.show()");
	console.log("Agua.loadPlugins    this.standby:");
	console.dir({standby:this.standby});
	this.standby.show();
	console.log("Agua.loadPlugins    AFTER this.standby.show()");
	
	// LOAD PLUGINS
	console.log("Agua.loadPlugins    DOING new pluginManager(...)");
	this.pluginManager = new PluginManager({
		parentWidget : this,
		pluginsList : pluginsList,
		pluginsArgs : pluginsArgs
	})
	console.log("Agua.loadPlugins    AFTER load PluginManager");

	if ( this.controllers["workflow"] )	{
		console.log("Agua.loadPlugins    this.controllers[workflow].createTab()");
		this.controllers["workflow"].createTab();
	}
},
setStandby : function () {
	console.log("Agua.setStandby    this.standby:");
	console.dir({this_standby:this.standby})
	console.log("Agua.setStandby    this.containerNode:");
	console.dir({this_containerNode:this.containerNode})
	
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
	console.log("Agua.setStandby    this.standby: " + this.standby);

	return this.standby;
},
addWidget : function (type, widget) {
    //console.log("Agua.addWidget    core.Agua.addWidget(type, widget)");
    //console.log("Agua.addWidget    type: " + type);
    //console.log("Agua.addWidget    widget: " + widget);
    if ( Agua.widgets[type] == null ) {
        Agua.widgets[type] = new Array;
    }
    //console.log("Agua.addWidget    BEFORE Agua.widgets[type].length: " + Agua.widgets[type].length);
    Agua.widgets[type].push(widget);
    //console.log("Agua.addWidget    AFTER Agua.widgets[type].length: " + Agua.widgets[type].length);
},
removeWidget : function (type, widget) {
    console.log("Agua.removeWidget    core.Agua.removeWidget(type, widget)");
    console.log("Agua.removeWidget    type: " + type);
    console.log("Agua.removeWidget    widget: " + widget);
        
    if ( Agua.widgets[type] == null )
    {
        console.log("Agua.removeWidget    No widgets of type: " + type);
        return;
    }

    console.log("Agua.removeWidget    BEFORE Agua.widgets[type].length: " + Agua.widgets[type].length);
    for ( var i = 0; i < Agua.widgets[type].length; i++ )
    {
        if ( Agua.widgets[type][i].id == widget.id )
        {
            Agua.widgets[type].splice(i, 1);
        }
    }
    console.log("Agua.removeWidget    AFTER Agua.widgets[type].length: " + Agua.widgets[type].length);
},
addToolbarButton: function (label) {
// ADD MODULE BUTTON TO TOOLBAR
	//console.log("Agua.addToolbarButton    plugins.core.Agua.addToolbarButton(label)");
	console.log("Agua.addToolbarButton    label: " + label);
	console.log("Agua.addToolbarButton    this.toolbar: " + this.toolbar);
	
	if ( this.toolbar == null )
	{
		//console.log("Agua.addToolbarButton    this.toolbar is null. Returning");
		return;
	}
	
	var button = new dijit.form.Button({
		
		label: label,
		showLabel: true,
		//className: label,
		iconClass: "dijitEditorIcon dijitEditorIcon" + label
	});
	//console.log("Agua.addToolbarButton    button: " + button);
	this.toolbar.addChild(button);
	
	return button;
},
loadCSSFile : function (cssFile) {
// LOAD A CSS FILE IF NOT ALREADY LOADED, REGISTER IN this.loadedCssFiles
	//console.log("Agua.loadCSSFile    cssFile: " + cssFile);
	//console.log("Agua.loadCSSFile    this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));
	if ( this.loadedCssFiles == null || ! this.loadedCssFiles )
	{
		//console.log("Agua.loadCSSFile    Creating this.loadedCssFiles = new Object");
		this.loadedCssFiles = new Object;
	}
	
	if ( ! this.loadedCssFiles[cssFile] )
	{
		console.log("Agua.loadCSSFile    Loading cssFile: " + cssFile);
		
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		document.getElementsByTagName("head")[0].appendChild(cssNode);

		this.loadedCssFiles[cssFile] = 1;
	}
	else
	{
		//console.log("Agua.loadCSSFile    No load. cssFile already exists: " + cssFile);
	}
	//console.log("Agua.loadCSSFile    Returning this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));
	
	return this.loadedCssFiles;
},
// DATA METHODS
fetchJsonData : function() {
	console.log("Agua.fetchJsonData    plugins.core.Agua.fetchJsonData()")	
	// GET URL 
    var url = this.dataUrl 
	console.log("Agua.fetchJsonData    url: " + url);

    var thisObject = this;
    dojo.xhrGet({
        // The URL of the request
        url: url,
		sync: true,
        // Handle as JSON Data
        handleAs: "json",
        // The success callback with result from server
        handle: function(data) {
			console.log("Agua.fetchJsonData    Setting this.data: " + data);
			thisObject.data = data;
        },
        // The error handler
        error: function() {
            console.log("Agua.Error with JSON Post, response: " + response);
        }
    });
},
reload : function () {
// RELOAD AGUA
	//console.log("Agua.constructor    plugins.core.Controls.reload()");
	var url = window.location;
	window.open(location, '_blank', 'toolbar=1,location=0,directories=0,status=0,menubar=1,scrollbars=1,resizable=1,navigation=0'); 

	//window.location.reload();
},
// LOGOUT
doLogout : function () {
	console.log("Agua.logout    Doing delete this.data");
	delete this.data;

	var buttons = Agua.toolbar.getChildren();
	if ( ! buttons )	return;
	for ( var i = 0; i < buttons.length; i++ ) {
		var button = buttons[i];
		controller = button.parentWidget;
		console.log("Agua.logout    controller " + i);
		console.dir({controller:controller});

		var name = controller.id.match(/plugins_([^_]+)/)[1]; 
		console.log("Agua.logout    Doing delete Agua.controllers[" + name + "]");
		delete Agua.controllers[name];
		
		console.log("Agua.logout    Doing controller.destroyRecursive()");
		if ( controller )
			controller.destroyRecursive();
	}	

	// DESTROY ALL WIDGETS
	dijit.registry.forEach(function(widget){
		console.log("Agua.logout    widget: " + widget);	
		widget.destroy();
	});

	// RELOAD AGUA
	Agua = new plugins.core.Agua( {
		cgiUrl : "../cgi-bin/agua/"
		, htmlUrl : "../agua/"
	});

	console.log("Agua.logout    DOING Agua.login = new plugins.login.Login");
	Agua.login = new plugins.login.Login();

	
	console.log("Agua.logout    COMPLETED");
},
doLogin : function () {
	console.log("Agua.login    DOING Agua.login = new plugins.login.Login");
	Agua.login = new Login();	
}



}); 	//	end declare

});	//	end define

