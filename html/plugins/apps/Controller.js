
dojo.provide("plugins.apps.Controller");

// OBJECT:  plugins.apps.Controller
// PURPOSE: GENERATE AND MANAGE Apps PANES

// CONTAINER
dojo.require("dijit.layout.BorderContainer");

// GLOBAL ADMIN CONTROLLER VARIABLE
var adminController;

// HAS
dojo.require("plugins.apps.Apps");

dojo.declare( "plugins.apps.Controller",
	[ dijit._Widget, dijit._Templated ],
{
// PANE ID 
paneId : null,

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "apps/templates/controller.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// TAB PANES
tabPanes : [],

// INPUTS TO PASS TO TAB INSTANCES ON INSTANTIATION
inputs : null,

// FLAG INDICATING CURRENTLY RUNNING createTab METHOD
creating: false,

////}}}

// CONSTRUCTOR	
constructor : function(args) {

	console.log("apps.Controller.constructor    args:");
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
	////console.log("apps.Controller.startup    plugins.apps.Controller.startup()");

	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);
	
	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET ADMIN BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab");

// ************************
// ************************
// DEBUG: CREATE TAB
	this.createTab();
// ************************
// ************************
	
	
},
createTab : function (event) {
	console.log("apps.Controller.createTab    event: " + event);
	
	console.log("apps.Controller.createTab    this.creating: " + this.creating);
	if ( this.creating == true )	return;
	
	// INDICATE ACTIVITY WITH SPINNER
	this.showButtonActive();
	
	// GET INPUTS
	var inputs = this.inputs;
	
	// SET this.creating
	this.creating = true;
	
	try {
		// CREATE WIDGET	
		var widget;
		if ( ! inputs )
			widget = new plugins.apps.Apps({});
		else
			widget = new plugins.apps.Apps({inputs:inputs});
		
		console.log("apps.Controller.createTab    Doing this.tabPanes.push(widget)");
		this.tabPanes.push(widget);
	
		// ADD TO _supportingWidgets FOR INCLUSION IN DESTROY	
		console.log("apps.Controller.createTab    Doing this._supportingWidgets.push(widget)");
		this._supportingWidgets.push(widget);

		// RESTORE this.creating
		// DELAY TO AVOID node is undefined ERROR
		console.log("apps.Controller.createTab    Doing setTimeout");
		setTimeout( function(thisObj) {
    		console.log("apps.Controller.createTab    INSIDE setTimeout");
			thisObj.creating = false;
			thisObj.showButtonInactive();
		},
		1000,
		this);
	}
	catch (error) {
		console.log("apps.Controller.createTab    ERROR creating new tab: ");
		console.dir({error:error});

		// RESTORE this.creating
		this.creating = false;
		this.showButtonInactive();
	}
},
showButtonActive : function () {
	console.log("apps.Controller.createTab    DOING dojo.addClass(this.menuButton, menuButtonActive)");
	dojo.addClass(this.menuButton.iconNode, "menuButtonActive");
},
showButtonInactive : function () {
	console.log("apps.Controller.createTab    DOING dojo.removeClass(this.menuButton, menuButtonActive)");
	dojo.removeClass(this.menuButton.iconNode, "menuButtonActive");
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
			//////////console.log("apps.Controller.++++ dojo.connect mItem1, onClick");	
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
			////////console.log("apps.Controller.++++ 'Run' menu item onClick");
			var currentTarget = dynamicMenu.currentTarget; 
			var adminList = currentTarget.parentNode;
		}
	);
		
	return dynamicMenu;
},
loadCSS : function() {
	// LOAD CSS
	var cssFiles = [ "plugins/apps/css/controller.css" ];
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
		////console.log("apps.Controller.addOnLoad    BEFORE createTab");
		//Agua.controllers["admin"].createTab();		
		////console.log("apps.Controller.addOnLoad    AFTER createTab");
	}
);

