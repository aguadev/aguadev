// ALLOW THE USER TO SELECT FROM 'AGUA' USER AND 'ADMIN' USER APPLICATIONS AND DRAG THEM INTO WORKFLOWS

define([
	"dojo/_base/declare",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common",

	// INTERNAL MODULES
	"plugins/workflow/Apps/AppSource",
	"plugins/workflow/Apps/AppMenu",

	"dojo/ready",
	//"dojo/domReady!",

	"dijit/form/Button",
	"dijit/form/TextBox",
	"dijit/form/Textarea",
	"dijit/layout/ContentPane",
	"dojo/parser",
	"dojo/dnd/Source"
],

function (declare,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplateMixin,
	Common,
	AppSource,
	AppMenu,
	ready) {

return declare("plugins.workflow.Apps.Apps",
	[ _Widget, _TemplatedMixin, _WidgetsInTemplateMixin, Common ], {

////}}}}}
	
templateString: dojo.cache("plugins", "workflow/Apps/templates/apps.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/workflow/Apps/css/apps.css")
],

// CORE WORKFLOW OBJECTS
core : null,

// APPS CONTAINED BY THIS WIDGET
apps : [],

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachNode : null,

// TAB CONTAINER
tabContainer : null,

// CONTEXT MENU
contextMenu : null,

////}	

constructor : function (args) {
	//////console.log("Apps.constructor     plugins.workflow.Apps.constructor");			
	// GET INFO FROM ARGS
	this.core = args.core;
    this.apps = args.apps;
	this.parentWidget = args.parentWidget;
	this.attachNode = args.attachNode;
    
    // LOAD CSS
	this.loadCSS();		
},
postCreate : function () {
	this.startup();
},
startup : function () {
	console.log("Apps.Apps.startup    plugins.workflow.Apps.startup()");

	this.attachPane();

	// CREATE SOURCE MENU
	console.log("Apps.Apps.startup    DOING this.setContextMenu()");
	this.setContextMenu();
	
	// SET APP TITLE
	this.setPackageName();
	
	// SET APP TITLE
	this.setOwnerName();

	// SET DRAG APP - LIST OF APPS
	console.log("Apps.Apps.startup    DOING this.loadAppSources()");
	this.loadAppSources();	
},
// ATTACH PANE
attachPane : function () {
	// ADD TO TAB CONTAINER		
	console.log("Apps.Apps.attachPane    DOING this.attachNode.addChild(this.mainTab)");
	console.log("Apps.Apps.attachPane    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	console.log("Apps.Apps.attachPane    this.attachNode: ");
	console.dir({this_attachNode:this.attachNode});
	
	this.attachNode.addChild(this.mainTab);

	console.log("Apps.Apps.attachPane    DOING this.attachNode.selectChild(this.mainTab)");
	this.attachNode.selectChild(this.mainTab);
},
setSubscriptions : function () {
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateApps");
	
	//// SUBSCRIBE TO UPDATES
	//Agua.updater.subscribe(this, "updatePackages");
},
removePane : function () {
	console.log("Apps.Apps.removePane    DOING this.attachNode.removeChild(this.mainTab)");
	this.attachNode.removeChild(this.mainTab);
},
destroy : function () {
	console.log("Apps.Apps.destroy    DOING this.destroy()");
	this.removePane();
	this.mainTab.destroyRecursive();
	
},
setContextMenu : function () {
// GENERATE CONTEXT MENU
	console.log("Apps.setContextMenu     plugins.workflow.Apps.setContextMenu()");	
	//this.contextMenu = new plugins.workflow.Apps.AppMenu( {
	this.contextMenu = new AppMenu( {
			parentWidget: this
		}
	);	
},
setPackageName : function () {
	var apps = this.apps;
	console.log("Apps.setPackageName    apps: ");
	console.dir({apps:apps});
	
	// RETURN IF APPS IS EMPTY
	if ( ! apps || ! apps[0] )	return;	
	
	// GET PACKAGE NAME
	var packageName = apps[0]["package"];
	if ( ! packageName )	packageName = "";
	packageName = this.firstLetterUpperCase(packageName);
	console.log("Apps.setPackageName    packageName: " + packageName);

	// SET TITLE
	this.mainTab.set("title", packageName);	
},
setOwnerName : function () {
	var apps = this.apps;
	console.log("Apps.setPackageName    apps: ");
	console.dir({apps:apps});
	
	// RETURN IF APPS IS EMPTY
	if ( ! apps || ! apps[0] )	return;	
	
	// GET PACKAGE NAME
	var ownerName = apps[0]["owner"];
	if ( ! ownerName )	ownerName = "";
	console.log("Apps.setPackageName    ownerName: " + ownerName);

	// SET SUBTITLE
	var subTitle = "Owner: " + ownerName;
	this.ownerName.innerHTML = subTitle;	
},
updateApps : function (args) {
	//////console.log("Apps.refresh     plugins.workflow.Apps.refresh()");
	console.log("Apps.updateApps    args:");
	console.dir(args);
	this.loadAppSources();
},
closePanes : function () {
	console.log("Apps.closePanes     plugins.workflow.Apps.closePanes()");

	if ( this.appSources == null || this.appSources.length == 0 )	return;
	for ( var i = 0; i < this.appSources.length; i++ )
	{
        var titlePane = this.appSources[i].titlePane;
        console.log("Apps.closePanes     titlePane: " + titlePane);
        if ( titlePane.open == true )
            titlePane.toggle();
	}
},
clearAppSources : function () {
// DELETE EXISTING APP SOURCES
	console.log("Apps.clearAppSources     plugins.workflow.Apps.clearAppSources()");
	if ( this.appSources == null || this.appSources.length == 0 )	return;
	
	for ( var i = 0; i < this.appSources.length; i++ ) {
		//console.log("Apps.clearAppSources     Destroying this.appSources[" + i + "]: " + this.appSources[i]);
		this.appSources[i].clearDragSource();
		this.appSourcesContainer.removeChild(this.appSources[i].domNode);
		this.appSources[i].destroy();
	}
},
getAppsByType : function (type, apps) {
	//console.log("Apps.getAppsByType    plugins.workflow.Apps.getAppsByType(type)");
	//console.log("Apps.getAppsByType    type: " + type);
	var keyArray = ["type"];
	var valueArray = [type];
	var cloneapps = dojo.clone(apps);

	return this.filterByKeyValues(cloneapps, keyArray, valueArray);
},
loadAppSources : function () {
	console.log("Apps.loadAppSources     plugins.workflow.Apps.loadAppSources()");

	// DELETE EXISTING CONTENT
	this.clearAppSources();

	var apps = this.apps;
	console.log("Apps.loadAppSources     apps.length: " + apps.length);
	//console.log("Apps.loadAppSources     apps: ");
	//console.dir({apps:apps});
	var types = Agua.getAppTypes(apps);
	console.log("Apps.loadAppSources     types: " + dojo.toJson(types));

	//console.log("Apps.loadAppSources     this_appSourcesContainer: ");
	//console.dir({this_appSourcesContainer:this.appSourcesContainer});
	
	this.appSources = new Array;
	for ( var i = 0; i < types.length; i++ ) {
		var type = types[i];
		console.log("Apps.loadAppSources     Doing type: " + dojo.toJson(type));		

		// GET APPLICATIONS
		var itemArray = this.getAppsByType(type, apps);
		if ( itemArray == null || itemArray.length == 0 )	continue;
		//console.log("Apps.loadAppSources     itemArray.length: " + itemArray.length);
		//console.log("Apps.loadAppSources     itemArray: ");
		//console.dir({itemArray:itemArray});

		// CREATE TITLE PANE
		var appSource = new AppSource({
			title		: 	type,
			itemArray 	:	itemArray,
			contextMenu	:	this.contextMenu
		});
		//console.log("Apps.loadAppSources     appSource: ");
		//console.dir({appSource:appSource});

		this.appSources.push(appSource);
		this.appSourcesContainer.appendChild(appSource.domNode);

		// ADD TO _supportingWidgets FOR INCLUSION IN DESTROY	
		this._supportingWidgets.push(appSource);
	}
}

}); 	//	end declare

});	//	end define
