dojo.provide("plugins.home.Home");

if ( 1 ) {
// BASIC LAYOUT
dojo.require("dijit.layout.BorderContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dojox.io.windowName");
dojo.require("dojox.layout.ResizeHandle");
dojo.require("dijit.form.Button");
dojo.require("dojox.widget.Standby");
dojo.require("dojox.widget.Dialog");
dojo.require("dojox.fx.easing");
dojo.require("dojox.timing");

// UPGRADE LOG
dojo.require("plugins.dojox.layout.FloatingPane");

// PACKAGE COMBOBOX
dojo.require("dojo.store.Memory");
dojo.require("dijit.form.ComboBox");

// DIALOG WITH COMBOBOX
dojo.require("plugins.dijit.SelectiveDialog");

// NO UPGRADES DIALOG
dojo.require("dijit.Dialog");

// INHERITS
dojo.require("plugins.core.Common");
	
}

dojo.declare( "plugins.home.Home", 
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "home/templates/home.html"),

cssFiles : [
    dojo.moduleUrl("plugins", "home/css/home.css"),
    dojo.moduleUrl("dojox", "layout/resources/ResizeHandle.css"),
	dojo.moduleUrl("dojox", "layout/resources/FloatingPane.css"),
	dojo.moduleUrl("dojox", "widget/Dialog/Dialog.css")
],

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PANE WIDGETS
paneWidgets : null,

// AGUA WIKI
url : "http://www.aguadev.org/confluence/display/home/Home",

// UPGRADE PROGRESS DIALOG
progressPane : null,

// timerInterval
// Number of milliseconds between calls to onTick
// timerInterval : Integer
timerInterval : 30000,

// controller
// Widget containing multiple instances of this class as tabs
controller : null,

////}}}}

constructor : function(args) {	
	// LOAD CSS
	this.loadCSS();		

	this.controller = args.controller;
},
postCreate : function() {
	console.log("Home.postCreate    plugins.home.Home.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Home.startup    plugins.home.Home.startup()");
	console.log("Home.startup    this.mainTab");
	console.dir({this_mainTab:this.mainTab});

	this.inherited(arguments);

	// ADD ADMIN TAB TO TAB CONTAINER		
	Agua.tabs.addChild(this.mainTab);

	Agua.tabs.selectChild(this.mainTab);

	// LOAD PANE 
	this.loadPane();

	// HIDE 'CHECK FOR UPGRADES' IF NOT ADMIN USER
	this.disableUpgrade();
	
	// SET VERSION COMBO
	this.setPackageCombo();

	// SET CHECK UPGRADE DIALOG
	this.setSelectiveDialog();

	// SET SIMPLE MESSAGE DIALOG
	this.setSimpleDialog();

	// SET TIMER
	this.setTimer();
	
	// SET PROGRESS PANE (FLOATING PANE) BEHAVIOUR
	this.setProgressPane();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updatePackages");

	// CONNECT WINDOW AND PROGRESS PANE RESIZE
	dojo.connect(this.mainTab.controlButton, "onClickCloseButton", dojo.hitch(this, "onClose"));
},
onClose : function (args) {
    console.log("Home.onClose    caller: " + this.onClose.caller.nom);
    console.log("Home.onClose    args: ");
    console.dir({args:args});

    console.log("Home.onClose    DOING this.controller.removeTab(this)");
    this.controller.removeTab(this);    
},
destroyRecursive : function () {
	console.log("Home.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
//	if ( Agua && Agua.tabs )
//		Agua.tabs.removeChild(this.mainTab);

    // REMOVE UPDATE SUBSCRIPTIONS
    this.removeUpdateSubscriptions();

    var widgets = dijit.findWidgets(this.mainTab);
	console.log("Home.destroyRecursive    widgets: ");
	console.dir({widgets:widgets});
    dojo.forEach(widgets, function(w) {
        w.destroyRecursive(true);
    });

	this.destroy();
	this.inherited(arguments);

    // REMOVE THIS WIDGET FROM REGISTRY
//	console.log("Home.destroyRecursive    this.isd: " + this.id);
//    dojo.registry.remove(this.id);
},
removeUpdateSubscriptions : function () {
	console.log("Home.removeUpdateSubscriptions    DOING Agua.Updater.removeSubscriptions(this)");
	Agua.updater.removeSubscriptions(this);

	console.log("Home.removeUpdateSubscriptions    AFTER Agua.Updater.removeSubscriptions(this)");    
},
updatePackages : function (args) {
// RELOAD GROUP COMBO AND DRAG SOURCE AFTER CHANGES
// TO SOURCES OR GROUPS DATA IN OTHER TABS

	console.log("Home.updatePackages    Home.updatePackages(args)");
	console.dir({args:args});
	

	// SET DRAG SOURCE
	if ( args && ! args.reload )	return;

	if ( args.originator && args.originator == this )	return;
	
	console.log("Home.updatePackages    Calling setPackageCombo()");
	this.setPackageCombo();
},
disableUpgrade : function () {
	var packages = Agua.getPackages();
	console.log("plugins.home.Home.disableUpgrade    packages: ");
	console.dir({packages:packages});
	
	// DISABLE 'CHECK FOR UPGRADES' BUTTON IF packages IS EMPTY
	if ( packages == null || packages.length == 0 ) {
		console.log("plugins.home.Home.disableUpgrade    version is empty. Returning");
		dojo.removeClass(this.checkVersion, 'checkVersion');
		dojo.addClass(this.checkVersion, 'hidden');
		dojo.addClass(this.packageCombo, 'hidden');
	}
},
loadPane : function () {
	var url = this.url;
	console.log("Home.loadPane    url: " + url);

	var auth = true;
	var authTarget = this.bottomPane;
	if ( this.bottomPane.id == null )
		this.bottomPane.id = this.id + "_windowName";
	this.windowDeferred = dojox.io.windowName.send(
		"GET",
		{
			url: url,
			handleAs:"text",
			authElement: authTarget,
			onAuthLoad: auth && function () {
				authTarget.style.display='block';
				console.log("Changed authTarget style.display to 'block'");
			}
		}
	);
	
	this.windowDeferred.addBoth(function(result){
		console.dir({result: result});
		auth && (authTarget.style.display='none');
		alert(result)
	});
},
// SETTERS
setPackageCombo : function (packageName) {
	console.log("Home.setPackageCombo    packageName: " + packageName);
	
	var packages = Agua.getPackages();
	console.log("Home.setPackageCombo    BEFORE FILTER packages: ");
	console.dir({packages:packages});

	var username = Agua.cookie('username');
	packages = this.filterByKeyValues(packages, ['username'], [username])
	console.log("Home.setPackageCombo    AFTER FILTER packages by username: " + username);
	console.dir({packages:packages});

	var itemArray = this.hashArrayKeyToArray(packages, "package");
	console.log("Home.setPackageCombo    itemArray: " + dojo.toJson(itemArray));
	
	// RETURN IF packages NOT DEFINED
	if ( ! itemArray ) {
		console.log("Home.setPackageCombo    itemArray not defined. Returning.");
		return;
	}

	itemArray = itemArray.sort();
	
	// CREATE store
	var store 	=	this.createStore(itemArray);

	this.packageCombo.store = store;	
	
	// SET DEFAULT
	if ( ! packageName )
		packageName = itemArray[itemArray.length - 1];

	console.log("Home.setPackageCombo    SETTING value packageName: " + packageName);
	this.packageCombo.set('value', packageName);			
},
setSelectiveDialog : function () {
	var enterCallback = function (){};
	var cancelCallback = function (){};
	
	console.log("Stages.setSelectiveDialog    plugins.files.Stages.setSelectiveDialog()");
	this.selectiveDialog = new plugins.dijit.SelectiveDialog(
		{
			title 				:	"",
			message 			:	"",
			enterLabel 			:	"Upgrade",
			cancelLabel 		:	"Cancel",
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);

	// SET CLASS
	dojo.addClass(this.selectiveDialog.dialog.domNode, 'home');
	dojo.addClass(this.selectiveDialog.dialog.domNode, 'progressPane');
	dojo.addClass(this.selectiveDialog.dialog.domNode, 'home progressPane dojoxDialog dijitDialog');

	//console.log("Stages.setSelectiveDialog    this.selectiveDialog: " + this.selectiveDialog);
},
setSimpleDialog : function () {
	this.simpleDialog = new dijit.Dialog({})
	dojo.addClass(this.simpleDialog.domNode, 'simpleDialog dijitDialog');
	dojo.addClass(this.simpleDialog.containerNode, 'simpleDialog dijitDialogPaneContent');
},
setTimer : function () {
	console.log("Home.setTimer    this.timerInterval: " + this.timerInterval);
	this.timer = new dojox.timing.Timer;
	console.log("Home.setTimer    Created this.timer: " + this.timer);
	this.timer.setInterval(this.timerInterval);
},
setProgressPane : function () {
	console.log("plugins.home.Home.setProgressPane");
	console.dir({progressPane:this.progressPane});

	// SET CLASS
	dojo.attr(this.progressPane.domNode, 'class', 'home progressPane dojoxDialog dijitDialog');

	var thisObject = this;

	this.progressPane.close = dojo.hitch(this, function() {
		console.log("plugins.home.Home.setProgressPane    this.progressPane.close");
		this.progressPane.minimize();
		this.timer.stop();
		dojo.attr(this.timer, 'isRunning', false);
	});
	
	this.progressPane.onDownloadError = dojo.hitch(this, function() {
		console.log("Home.setProgressPane    this.progressPane.onLoadError");
	});

	dojo.connect(this.progressPane, "_onShow", this, "_onShow");
},
// SHOWers
showCurrentVersion : function () {
	console.log("Home.showCurrentVersion    plugins.home.Home.showCurrentVersion()");
	var packageName = this.packageCombo.get('value');
	console.log("Home.showCurrentVersion    packageName: " + packageName);
	
	var packageObject = this.getPackageObject(packageName);
	console.log("Home.showCurrentVersion    AFTER packageObject: " + dojo.toJson(packageObject));
	
	this.currentVersion.innerHTML = packageObject.version;
},
showUpgrades : function () {
	console.log("Home.showUpgrades    plugins.home.Home.showUpgrades()");
	var packageName = this.packageCombo.get('value');
	console.log("Home.showUpgrades    packageName: " + packageName);
	
	var packageObject = this.getPackageObject(packageName);
	console.log("Home.showUpgrades    AFTER packageObject: " + dojo.toJson(packageObject));

	if ( ! packageObject.current ) {
		console.log("Home.showUpgrades    packageObject.current not defined. Returning");
		return;
	}
	
	if ( packageObject.current.length == 0 ) {
		this.showLatestInstalled(packageName, packageObject.version);
	}
	else {
		this.loadSelectiveDialog(packageObject);
	}
},
// UPGRADE
loadSelectiveDialog : function (packageObject) {
	console.log("Home.loadSelectiveDialog    plugins.files.Home.loadSelectiveDialog(packageObject)");
	console.log("Home.loadSelectiveDialog    packageObject: " + dojo.toJson(packageObject));
	
	// SET CALLBACKS
	var thisObject = this;
	var cancelCallback = function (){
		console.log("Home.loadSelectiveDialog    cancelCallback()");
	};
	var enterCallback = dojo.hitch(this, function (input, selected, checked, dialogWidget)
		{
			console.log("Home.loadSelectiveDialog    Doing enterCallback(input, selected, checked, dialogWidget)");
			console.log("Home.loadSelectiveDialog    input: " + input);
			console.log("Home.loadSelectiveDialog    selected: " + selected);
			console.log("Home.loadSelectiveDialog    checked: " + checked);
			console.log("Home.loadSelectiveDialog    dialogWidget: " + dialogWidget);
			
			// CLOSE DIALOG
			setTimeout(function(){
				dialogWidget.close();
			}, 100);
			
			// DO UPGRADE VERSION
			thisObject.runUpgrade(selected, packageObject);
		}
	);		

	// SHOW THE DIALOG
	this.selectiveDialog.load({
			title 				:	"Current " + packageObject["package"] + " version: " + packageObject.version,
			message 			:	"Select upgrade version",
			comboValues 		:	packageObject.current,
			comboMessage 		:	"Agua version",
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback,
			enterLabel			:	"Upgrade",
			cancelLabel			:	"Cancel"
		}			
	);
},
runUpgrade : function (selectedVersion, packageObject) {
	console.log("Home.runUpgrade    selectedVersion: " + selectedVersion);
	console.log("Home.runUpgrade    packageObject: " + dojo.toJson(packageObject));

	console.log("plugins.home.Home.runUpgrade    Doing this.getStandby()");
	var standby = this.getStandby();
	console.log("plugins.home.Home.runUpgrade    standby: " + standby);

	// LAUNCH STANDBY
	standby.show();

	var thisObject = this;
	setTimeout(function(){
		thisObject.upgrade(selectedVersion, packageObject);
	}, 500);
},
upgrade : function (selectedVersion, packageObject) {
	
	packageObject.random = Math.floor(Math.random()*1000000000000);
	console.log("Home.upgrade    packageObject: " + dojo.toJson(packageObject));

	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query["package"] 	= 	packageObject["package"];
	query.repository 	= 	packageObject["package"];
	query.version 		= 	selectedVersion;
	query.privacy 		= 	packageObject.privacy;
	query.owner 		= 	packageObject.owner;
	query.installdir 	= 	packageObject.installdir;
	query.mode			= 	"upgrade";
	query.module 		= 	"Agua::Workflow";
	query.random 		= 	packageObject.random;
	console.log("packageObject" + dojo.toJson(packageObject));
	
	var thisObject = this;
	var xhrputReturn = dojo.xhrPut({
		url: url,
		contentType: "text",
		sync : false,
		handleAs: "json",
		putData: dojo.toJson(query),
		load: function(response, ioArgs) {
			if ( response.error != null ) {
				Agua.error("Home.runUpgrade    Error: " + response.error);
				thisObject.progressPane.hide();
				thisObject.progressPane.set('innerHTML', '');
				thisObject.stopProgress();
			}
			else {
				console.log("Home.runUpgrade    OK");

				// SHOW LOG
				var logfile = this.setLogFile(packageObject);
				var packageName = packageObject["package"];
				console.log("Home.upgrade    logfile: " + logfile);
				console.log("Home.upgrade    packageName: " + packageName);
				console.log("Home.upgrade    thisObject: " + thisObject);
				console.log("Home.upgrade    thisObject.progressPane: " + thisObject.progressPane);
				var title = thisObject(packageObject, version);
				console.log("Home.upgrade    title: " + title);
				thisObject.progressPane.set('title', title);
				thisObject.progressPane.set('href', logfile);
				thisObject.progressPane.show();
			
				// UPDATE PACKAGE IN AGUA DATA
				thisObject.updatePackage(packageObject);
				
				//// DISPLAY PROGRESS PAGE IN DIALOG
				//thisObject.showProgress(response.url, response.version);	
			}
			
			//// STOP STANDBY
			//thisObject.standby.hide();

		},
		error: function(response, ioArgs) {
			console.log("plugins.home.Home.runUpgrade    Error with JSON Post, response: " + dojo.toJson(response));
		}
	});	

	// DISPLAY PROGRESS PAGE IN DIALOG
	this.showProgress(packageObject, selectedVersion);	

	// STOP STANDBY
	this.standby.hide();
},
updatePackage : function (packageObject) {
	Agua.removePackage(packageObject);
	Agua.addPackage(packageObject);
	this.showCurrentVersion();
	
	if ( ! this.timer )	return;
	this.timer.stop();
	dojo.attr(this.timer, 'isRunning', false);
},
showProgress : function (packageObject, version) {
	console.log("Home.showProgress    packageObject: ");
	console.dir({packageObject:packageObject});
	console.log("Home.showProgress    version: " + version);

	// SET LOGFILE
	var logfile = this.setLogFile(packageObject);
	console.log("Home.showProgress    logfile: " + logfile);

	// SET TITLE
	var title = this.setTitle(packageObject, version);
	console.log("Home.showProgress    title: " + title);
	
	// SET PROGRESS PANE ATTRIBUTES AND SHOW
	this.progressPane.set('title', title);
	this.progressPane.set('href', logfile);
	this.progressPane.show();
	this.resizeProgress();

	this.pollProgress(logfile, version, packageObject);

	dojo.connect(this.progressPane, "close", dojo.hitch(this, "stopProgress"));
	dojo.connect(this.progressPane, "minimize", dojo.hitch(this, "stopProgress"));
	dojo.connect(this.progressPane, "resize", dojo.hitch(this, "startProgress"));
},
setLogFile : function (packageObject) {
	return "log/" + packageObject["package"] + "-upgradelog." + packageObject.random + ".html";
},
setTitle : function (packageObject, version) {
	var packageName = packageObject["package"];
	var title = packageName + " " + version + " upgrade log";

	return title;	
},
stopProgress : function () {
	console.log("Home.stopProgress    Home.stopProgress()");
	console.dir({timer:this.timer})
	if ( this.timer == null )	return;
	if ( dojo.attr(this.timer, 'isRunning') == false ) 	return;
	console.log("Home.stopProgress    Doing this.timer.stop()");
	dojo.attr(this.timer, 'isRunning', false);
	this.timer.stop();
	this.timer.interval = 999999999999;

	this.timer.onTick = function(){
		console.log("Home.stopProgress    timer.onTick()");
	}
	
	console.log("Home.stopProgress    Doing window.clearInterval(this.timer.timer)");
	window.clearInterval(this.timer.timer);
},
startProgress : function () {	
	// RESET TIMER INTERVAL
	this.timer.interval = this.timerInterval;
	console.log("Home.startProgress    timer:");
	console.dir({timer:this.timer})

	// RETURN IF TIMER isRunning
	if ( dojo.attr(this.timer, 'isRunning') == true ) 	return;
	console.log("Home.startProgress    Doing this.timer.start()");

	// SET TIMER isRunning
	dojo.attr(this.timer, 'isRunning', true);
	this.timer.start();
	this.resizeProgress();
},
resizeProgress : function () {
	if ( ! this.progressPane )	return;
	var node = this.progressPane.domNode;
	var viewport = dojo.window.getBox();
	var borderBox = dojo._getBorderBox(node);
	l = Math.floor(viewport.l + (viewport.w - borderBox.w) / 2);
	t = Math.floor(viewport.t + (viewport.h - borderBox.h) / 2);

	var dimensions = {
		left: l + "px",
		top: t + "px"
	};
	dojo.style(node, dimensions);
},
pollProgress : function (url, version, packageObject) {
	console.log("Home.pollProgress    Home.pollProgress(url, version)");
	console.log("Home.pollProgress    url: " + url);
	console.log("Home.pollProgress    version: " + version);
	
	// SET this.packageObject
	this.packageObject = packageObject;
	
	var thisObject = this;	
	this.timer.onTick = function() {
		console.log("Home.pollProgress    timer onTick: " + new Date().toTimeString());
		thisObject.progressPane.set('href', '');
		thisObject.progressPane.set('href', url);
		thisObject.progressPane.show();
	};	
	
	this.timer.start();
	dojo.attr(this.timer, 'isRunning', true);
},
reportedVersion : function() {
	console.log("Home.reportedVersion    plugins.home.Home.reportedVersion");
	var report = this.progressPane.containerNode.innerHTML;
	//console.dir({report:report});
	var version;
	var match = report.match(/Completed installation, version:\s*(\S+)/);
    if ( match ) {
	    version = match[1];
	}
	console.log("Home.reportedVersion    version: " + version);

	return version;
},
// PROGRESS PANE
_onShow : function () {
	console.log("Home.setProgressPane    this.progressPane._onShow");

	var thisObject = this;
	setTimeout ( function () {
		var report = thisObject.progressPane.containerNode.innerHTML;
		console.dir({report:report});
		var reportedVersion = thisObject.reportedVersion();
		//console.log("Home._onShow    reportedVersion: " + reportedVersion);
		if ( reportedVersion )  {
			console.log("Home._onShow    reportedVersion is defined: " + reportedVersion + ". Stopping timer");
			thisObject.stopProgress();
			
			thisObject.packageObject.version = reportedVersion;
			thisObject.setVersion(thisObject.packageObject);
	
			// RELOAD RELEVANT DISPLAYS
			Agua.updater.update("updatePackages", { originator: thisObject });	
		}
	},
	2000);
	
},
setVersion : function(packageObject) {
	console.log("Home.setVersion    packagObject: " + dojo.toJson(packageObject, true));	
	
	Agua.removePackage(packageObject);
	Agua.addPackage(packageObject);
	this.setPackageCombo(packageObject["package"]);
	this.showCurrentVersion();
},
getStandby : function () {
	console.log("Stages.getStandby    Stages.getStandby()");
	if ( this.standby == null ) {

		var id = dijit.getUniqueId("dojox_widget_Standby");
		this.standby = new dojox.widget.Standby (
			{
				target: this.bottomPane,
				//onClick: "reload",
				text: "Running upgrade",
				id : id,
				url: "plugins/core/images/agua-biwave-24.png"
			}
		);
		document.body.appendChild(this.standby.domNode);
	}

	console.log("Stages.getStandby    this.standby: " + this.standby);

	return this.standby;
},
newWindow : function () {
// RELOAD AGUA
	console.log("plugins.home.Home.newWindow    Home.newWindow()");
	var url = window.location;
	window.open(location, '_blank', 'toolbar=1,location=0,directories=0,status=0,menubar=1,scrollbars=1,resizable=1,navigation=0'); 
	//window.location.newWindow();
},
parseVersion : function (version) {
    var versionObject = {};
    if ( ! version.match(/^(\d+)\.(\d+)\.(\d+)(-)?(\S+)?$/) ) {
        //console.log("version does not match: " + version);
		return;
    }
    else {
        versionObject.major = parseInt(version.match(/^(\d+)\.(\d+)\.(\d+)(-\S+)?(\+\S+)?$/)[1]);
        versionObject.minor = parseInt(version.match(/^(\d+)\.(\d+)\.(\d+)(-\S+)?(\+\S+)?$/)[2]);
        versionObject.patch = parseInt(version.match(/^(\d+)\.(\d+)\.(\d+)(-\S+)?(\+\S+)?$/)[3]);
        versionObject.release = version.match(/^(\d+)\.(\d+)\.(\d+)(-\S+)?(\+\S+)?$/)[4];
        versionObject.build = version.match(/^(\d+)\.(\d+)\.(\d+)(-\S+)?(\+\S+)?$/)[5];
		
		if ( versionObject.release )	versionObject.release = versionObject.release.replace(/^-/,'');
		if ( versionObject.build )	versionObject.build = versionObject.build.replace(/^\+/,'');
    }
	
    //console.log("major: " + versionObject.major);
    //console.log("minor: " + versionObject.minor);
    //console.log("patch: " + versionObject.patch);
    //console.log("release: " + versionObject.release);
    //console.log("build: " + versionObject.build);

    return versionObject;
},
returnValue : function (value) {
	//var caller = this.returnValue.caller.nom;
	//console.log(caller + " this.returnValue value: " + value);
	return value;
},
compareStringNumber : function (a, b) {
    if ( ! a.match(/^(\D+)(\d+)$/) && ! b.match(/^(\D+)(\d+)$/) ) {
		var compare = a.toLowerCase().localeCompare(b.toLowerCase());
		//console.log("compareStringNumber    compare: " + compare);
		return compare;
    }
	else {
		var aObject = this.splitStringNumber(a);
		var bObject = this.splitStringNumber(b);
		//console.dir({aObject:aObject});
		//console.dir({bObject:bObject});
		
		if ( aObject.string != bObject.string ) {
			var compare = a.toLowerCase().localeCompare(b.toLowerCase());
			//console.log("compareStringNumber    stringObject compare: " + compare);
			this.returnValue(compare);
		}
		else {
			//console.log("compareStringNumber    comparing numbers");

			if ( ! aObject.number && ! bObject.number ) {
				this.returnValue(0);
			}
			else if ( aObject.number && ! bObject.number ) {
				this.returnValue(1);
			}
			else if ( bObject.number && ! aObject.number ) {
				this.returnValue(-1);
			}
			else if ( parseInt(aObject.number) > parseInt(bObject.number) ) {
				//	console.log("a is larger than a");
				return 1;
			}
			else if ( parseInt(bObject.number) > parseInt(aObject.number) ) {
				//console.log("b is larger than a");
				return -1;
			}
			else {
				this.returnValue(0);
			}
		}
	}
	
	return null;
},
splitStringNumber : function (string) {
	//if ( ! string.match(/^(\D+)(\d+)$/) )	return;
	var stringObject = new Object;
	stringObject.string = string.match(/^(\D+)/)[1];
	if ( string.match(/^(\D+)(\d+)$/) )
		stringObject.number = string.match(/^(\D+)(\d+)$/)[2];
	return stringObject;
},
// UTILS
showLatestInstalled : function (packageName, version) {
	console.dir({simpleDialog:this.simpleDialog});
	this.simpleDialog.titleNode.innerHTML = "Latest version of " + packageName + " is installed (version " + version + ")";

	this.simpleDialog.show();
},
getPackageObject : function (packageName) {
	var packages = Agua.getPackages();
	//console.log("Home.getPackageObject    packages: ");
	console.dir({packages:packages});
	
	for ( var i = 0; i < packages.length; i++ ) {
		if ( packages[i]["package"] == packageName ) {
			return packages[i];
			break;
		}
	}
	
	return;
},
laterVersions : function (versions) {

	for ( var i = 0; i < versions.length; i++ ) {
		var version = versions[i].version;
		var versionarray = versions[i].current;
		for ( var k = 0; k < versionarray.length; k++ ) {
			
			console.log("laterVersions    versionarray[" + k + "]: " + versionarray[k]);

			if ( versionarray[k] == version ) {
				versionarray.splice(k, 1);
				break;
			}
			else {
				versionarray.splice(k, 1);
				k--;
			}
		}
	}

	return versions;
},
sortVersions : function (versions) {

	console.log("Home.sortVersions    versions: " + dojo.toJson(versions));
	var thisObject = this;
	var versionSort = function (a,b) {
		//console.log("a: " + a);
		//console.log("b: " + b);
	
		var aVersion = thisObject.parseVersion(a);
		var bVersion = thisObject.parseVersion(b);
	
		//console.log("aVersion.major: " + aVersion.major);
		//console.log("aVersion.minor: " + aVersion.minor);
		//console.log("aVersion.patch: " + aVersion.patch);
		//console.log("aVersion.release: " + aVersion.release);
		//console.log("aVersion.build: " + aVersion.build);
		//
		//console.log("bVersion.major: " + bVersion.major);
		//console.log("bVersion.minor: " + bVersion.minor);
		//console.log("bVersion.patch: " + bVersion.patch);
		//console.log("bVersion.release: " + bVersion.release);
		//console.log("bVersion.build: " + bVersion.build);
	
		if ( aVersion.major > bVersion.major )	return thisObject.returnValue(1);
		else if ( bVersion.major > aVersion.major ) return thisObject.returnValue(-1);
		if ( aVersion.minor > bVersion.minor )	return thisObject.returnValue(1);
		else if ( bVersion.minor > aVersion.minor ) return thisObject.returnValue(-1);
		if ( aVersion.patch > bVersion.patch )	return thisObject.returnValue(1);
		else if ( bVersion.patch > aVersion.patch ) return thisObject.returnValue(-1);
		if ( ! aVersion.release && ! bVersion.release
			&& ! aVersion.build && ! bVersion.build )	return thisObject.returnValue(0);
		
		if ( aVersion.release && ! bVersion.release )	return thisObject.returnValue(1);
		if ( bVersion.release && ! aVersion.release )	return thisObject.returnValue(-1);
		
		if ( aVersion.release && bVersion.release ) {
			return thisObject.compareStringNumber(aVersion.release, bVersion.release);
		}
		
		if ( aVersion.build && ! bVersion.build )	return thisObject.returnValue(1);
		if ( bVersion.build && ! aVersion.build )	return thisObject.returnValue(-1);
		if ( aVersion.build && bVersion.build ) {
			return thisObject.compareStringNumber(aVersion.build, bVersion.build);
		}
		
		return thisObject.returnValue(0);
	};

	versions = versions.sort(versionSort);

	//versions = versions.reverse();	
	return versions;
}


}); // end of plugins.home.Home
