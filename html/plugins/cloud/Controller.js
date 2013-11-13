dojo.provide("plugins.cloud.Controller");

// OBJECT:  plugins.cloud.Controller
// PURPOSE: GENERATE AND MANAGE Admin PANES

// CONTAINER
dojo.require("dijit.layout.BorderContainer");

// GLOBAL ADMIN CONTROLLER VARIABLE
var adminController;

// HAS
dojo.require("plugins.cloud.Cloud");

dojo.declare( "plugins.cloud.Controller",
	[ dijit._Widget, dijit._Templated ],
{
// PANE ID 
paneId : null,

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "cloud/templates/controller.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// TAB PANES
tabPanes : [],

// INPUTS TO PASS TO TAB INSTANCES ON INSTANTIATION
inputs : null,

////}}}

// CONSTRUCTOR	
constructor : function(args) {

	console.log("admin.Controller.constructor    args:");
	console.dir({args:args});

	// SET INPUTS IF PRESENT
	if ( args.inputs )
		this.inputs = args.inputs;
	
	// LOAD CSS FOR BUTTON
	this.loadCSS();		
},
postCreate : function() {
	this.startup();
},
startup : function () {
	////console.log("admin.Controller.startup    plugins.cloud.Controller.startup()");

	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);
	
	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET ADMIN BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab");
},
createTab : function () {
	
	// GET INPUTS
	var inputs = this.inputs;
	
	// CREATE WIDGET	
	var widget;
	if ( ! inputs )
		widget = new plugins.cloud.Cloud({});
	else
		widget = new plugins.cloud.Cloud({inputs:inputs});
	
	console.log("admin.Controller.createTab    Doing this.tabPanes.push(widget)");
	this.tabPanes.push(widget);

	// ADD TO _supportingWidgets FOR INCLUSION IN DESTROY	
	this._supportingWidgets.push(widget);
},
createMenu : function () {
// ADD PROGRAMMATIC CONTEXT MENU
	var dynamicMenu = new dijit.Menu( { id: "admin" + this.paneId + 'dynamicMenuPopup'} );

	// ADD MENU TITLE
	dynamicMenu.addChild(new dijit.MenuItem( { label:"Application Menu", disabled:false} ));
	dynamicMenu.addChild(new dijit.MenuSeparator());

	//// ONE OF FOUR WAYS TO DO MENU CALLBACK WITH ACCESS TO THE MENU ITEM AND THE CURRENT TARGET 	
	// 4. dojo.connect CALL
	//	REQUIRES:
	//		ADDED menu.currentTarget SLOT TO dijit.menu
	var mItem1 = new dijit.MenuItem(
		{
			id: "admin" + this.paneId + "remove",
			label: "Remove",
			disabled: false
		}
	);
	dynamicMenu.addChild(mItem1);
	dojo.connect(mItem1, "onClick", function()
		{
			//////////console.log("admin.Controller.++++ dojo.connect mItem1, onClick");	
			var parentNode = dynamicMenu.currentTarget.parentNode;
			parentNode.removeChild(dynamicMenu.currentTarget);	
		}
	);

	// SEPARATOR
	dynamicMenu.addChild(new dijit.MenuSeparator());

	//	ADD run MENU ITEM
	var mItem2 = new dijit.MenuItem(
		{
			id: "admin" + this.paneId + "run",
			label: "Run",
			disabled: false
		}
	);
	dynamicMenu.addChild(mItem2);	

	dojo.connect(mItem2, "onClick", function()
		{
			////////console.log("admin.Controller.++++ 'Run' menu item onClick");
			var currentTarget = dynamicMenu.currentTarget; 
			var adminList = currentTarget.parentNode;
		}
	);
		
	return dynamicMenu;
},
loadCSS : function() {
	// LOAD CSS
	var cssFiles = [ "plugins/cloud/css/controller.css" ];
	for ( var i in cssFiles )
	{
		var cssFile = cssFiles[i];
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		cssNode.media = 'screen';
		document.getElementsByTagName("head")[0].appendChild(cssNode);
	}
}

}); // end of Controller

dojo.addOnLoad(
	function() {
		//// CREATE TAB
		////console.log("admin.Controller.addOnLoad    BEFORE createTab");
		//Agua.controllers["admin"].createTab();		
		////console.log("admin.Controller.addOnLoad    AFTER createTab");
	}
);

