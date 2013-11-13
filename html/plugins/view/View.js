console.log("plugins.view.View    LOADING");

/* SUMMARY: CREATE AND MODIFY VIEWS
	
	TAB HIERARCHY IS AS FOLLOWS:
	
		tabs	

			mainTab

				leftPane (SELECT VIEW AND FEATURE TRACKS)

					comboBoxes

				rightPane (VIEW GENOMIC BROWSER)

						Browser

							Features (DRAG AND DROP FEATURE TRACKS LIST)

							GenomeView (GOOGLE MAPS-STYLE GENOME NAVIGATION)


	USE CASE SCENARIO 1: USER ADDS A FEATURE TO A VIEW

		OBJECTIVE:
		
			1. MINIMAL ACTION TO ACHIEVE THE DESIRE RESULT
			
			2. IMMEDIATE AND ANIMATED RESPONSES TO INDICATE STATUS/PROGRESS


		IMPLEMENTATION:
		
		1. USER SELECTS FEATURE IN BOTTOM OF LEFT PANE AND CLICKS 'Add'
		
		2. IF FEATURE ALREADY EXISTS IN VIEW, DO NOTHING.

		3. OTHERWISE, addViewFeature CALL TO REMOTE WILL RETURN STATUS OR AN ERROR:
		
			IF STATUS IS 'Adding feature: featureName':
				
				1. START DELAYED POLL FOR STATUS
			
				2. POLL WILL STOP WHEN STATUS IS 'ready'
				
					OR THERE IS AN ERROR RESPONSE
					
				3. IF 'ready' THEN UPDATE CLIENT AND SERVER DATABASES
				
					AND RESET THE VIEW FEATURES COMBO BOX
		
				4. USER CAN CLICK THE 'refresh' BUTTON TO REMOVE ANY ERROR OR 
				
					NON-'ready' STATUS (E.G., PROLONGED 'adding' OR 'removing'
					
					DUE TO ERROR ON REMOTE SERVER):
			
				5. THE 'refresh' BUTTON IS THE VIEW ICON ON LEFT OF VIEW COMBO BOX 
			
			IF STATUS IS DIFFERENT, DO NOTHING.
			
			E.G.: 'Feature already present in view: featureName'
		
		4. IF ERROR, DO NOTHING.
		
			E.G.: 'Undefined inputs: feature, project, view'

*/	

define("plugins/view/View", [
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dojo/dom-construct",
	"dojo/Deferred",
	"dijit/_Widget",
	"dijit/_Templated",
	"plugins/core/Common",

	// STORE	
	"dojo/store/Memory",
	
	// FEATURES
	"plugins/view/Features",
	
	// JBROWSE BROWSER
	"JBrowse/Browser",
	
	// STATUS
	"plugins/form/Status",
	
	// STANDBY
	"dojox/widget/Standby",
	
	// DIALOGS
	"plugins/dijit/ConfirmDialog",
	"plugins/dijit/SelectiveDialog",
	
	// TAB
	"dijit/layout/ContentPane",

	// HAS A
	"dijit/layout/BorderContainer",
	"plugins/dojox/layout/ExpandoPane",
	
	// WIDGETS IN TEMPLATE
	"dijit/layout/SplitContainer",
	"dijit/layout/ContentPane",
	"dojo/data/ItemFileReadStore",
	"dijit/form/ComboBox",
	"dijit/form/Button",
	"dijit/layout/TabContainer",
	"dijit/layout/BorderContainer",
	"dojox/layout/FloatingPane",
	"dojo/fx/easing",
	"dojo/parser",
	"dijit/_base/place"
],

function (
	declare,
	arrayUtil,
	JSON,
	on,
	lang,
	domAttr,
	domClass,
	domConstruct,
	Deferred,
	_Widget,
	_Templated,
	Common,


	Memory,
	Features,
	Browser,
	Status,
	Standby,
	ConfirmDialog,
	SelectiveDialog,

	ContentPane
) {

/////}}}}}

return declare("plugins/view/View",
	[ _Widget, _Templated, Common ], {

// PATH TO WIDGET TEMPLATE
templatePath: dojo.moduleUrl("plugins", "view/templates/view.html"),

// PARENT NODE, I.E., TABS NODE
parentWidget : null,

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,
workflow : null,

// onChangeListeners : Array. LIST OF COMBOBOX ONCHANGE LISTENERS
onChangeListeners : new Object,

// setListeners : Boolean. SET LISTENERS FLAG 
setListeners : false,

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// cssFiles: Array
// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins", "view/css/view.css"),
	dojo.moduleUrl("plugins", "view/css/genome.css")
	,
	dojo.moduleUrl("dojox", "layout/resources/ExpandoPane.css"),
	dojo.moduleUrl("dojox", "layout/tests/_expando.css"),
	dojo.moduleUrl("plugins", "dnd/css/dnd.css")
],

// browsers: Array
// HASH ARRAY OF OPENED BROWSERS
browsers : new Array,

// url: String
// URL FOR REMOTE DATABASE
url: null,

// baseUrl : String
// BASE URL FOR VIEW DATA
baseUrl: "plugins/view/jbrowse/",

// browserUrl : String
// ROOT URL FOR Browser.js OBJECT
browserRoot : "plugins/view/jbrowse/",

// polling : Bool
// Polling for completion of new view
polling : false,

// delay : Int
// Delay between each poll (1000 = 1 second)
delay : 10000,

// ready: Boolean
// 		Set to true once startup has completed
ready : false,

// loadOnStartup: Boolean
// 		Call loadBrowser at end of startup method
loadOnStartup : true,

// lastViewComboValue : String
//		Holder to avoid fire viewCombo while setting it's value
lastViewComboValue : null,

////}}}
constructor : function(args) {	
	console.log("View.constructor    args:");
	console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	
	console.log("View.constructor    this.baseUrl: " + this.baseUrl);
	
	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "/agua.cgi";
	
	// LOAD CSS FILES
	this.loadCSS(this.cssFiles);		
},
postCreate: function() {
	this.startup();
},
// STARTUP
startup : function () {

	console.group("View-" + this.id + "    startup");
	console.log("-------------------------- View.startup    this.browsers:");
	console.dir({this_browsers:this.browsers});
	if ( this.browsers[0] ) {
    	console.log("View.constructor    this.browsers[0].project: " + this.browsers[0].project);
		console.log("View.constructor    this.browsers[0].workflow :" + this.browsers[0].workflow);
    }

	console.log("View.startup    this.loadOnStartup: " + this.loadOnStartup);

    // ADD THIS WIDGET TO Agua.widgets[type]
    Agua.addWidget("view", this);

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	// ADD THE PANE TO THE TAB CONTAINER
	this.attachWidget.addChild(this.mainTab);
	this.attachWidget.selectChild(this.mainTab);
	
	// SET displayStatus
	this.setDisplayStatus();
	
	//// EXPAND LEFT PANE
	//this.leftPane.toggle();

	// SET URL
	console.log("View.startup    DOING this.setUrl()");
	this.setUrl();
	
	// SET DIALOG WIDGETS
	this.setConfirmDialog();
	this.setSelectiveDialog();

	// SET LOADING STANDBY
	console.log("View.startup    DOING this.setStandby()");
	this.setStandby();
	
	// SET FEATURE COMBOS
	console.log("View.startup    DOING this.setFeatures()");
	var thisObj = this;
	this.setFeatures().then(function() {

	////this.setFeatureCombo().then(function() {
	////	console.log("View.startup    INSIDE this.setFeatureCombo().then");
	//	
		// LOAD VIEW COMBOS IN SUCCESSION
		console.log("View.startup    DOING this.setProjectCombo()");
		thisObj.setProjectCombo().then( function() {
	
		//thisObj.setOnkeyListener();

			thisObj.setOnkeyListener().then( function() {
			console.log("View.startup    INSIDE this.setOnkeyListener().then");
	
				console.log("View.startup    thisObj.loadOnStartup: " + thisObj.loadOnStartup);
			
				if ( thisObj.loadOnStartup ) {
					console.log("View.startup    DOING thisObj.loadBrowser()");
					thisObj.loadBrowser(thisObj.getProject(), thisObj.getView()); 
				}
		
				// SET READY
				thisObj.ready = true;
		
				// SET COMBO LISTENERS AFTER DELAY TO AVOID onchange FIRE
				setTimeout(function(thisObj) {
					thisObj.setComboListeners();
				},
				500,
				thisObj)
		
				console.log("View-" + thisObj.id + "    startup    END");
				console.groupEnd("View-" + thisObj.id + "    startup");
		

			});

		});
		
	})
},
// DISPLAY STATUS
setDisplayStatus : function () {
	this.displayStatus = new Status({
		status		:	"loading",
		attachPoint : 	this.leftPane.titleWrapper,
		loadingTitle: 	"",
		readyTitle 	: 	"",
		title		:	""
	});	
},
displayLoading : function () {
	console.log("View.displayReady    this.displayStatus:");
	this.displayStatus.setStatus("loading");
},
displayReady : function () {
	console.log("View.displayReady    this.displayStatus:");
	console.dir({this_displayStatus:this.displayStatus});

	this.displayStatus.setStatus("ready");
},
loadEval : function (url) {
	console.log("View.loadEval    url: " + url);
	// SEND TO SERVER
	dojo.xhrGet(
		{
			url: url,
			sync: true,
			handleAs: "text",
			load: function(response) {
				//console.log("View.loadEval    response: " + dojo.toJson(response));
				eval(response);
			},
			error: function(response, ioArgs) {
				console.log("  View.loadEval    Response error. Response: " + response);
				return response;
			}
		}
	);	
},
// GETTERS
_getDeferred : function() {
    if( ! this._deferred )
        this._deferred = new Deferred();
    return this._deferred;
},
getRefSeqFile : function (username, projectName, viewName) {
	return this.baseUrl + "/users"
						+ "/" + username
						+ "/" + projectName
						+ "/" + viewName
						+ "/data/seq/refSeqs.json";
						//+ "/json/volvox/seq/refSeqs.json";
},
getTrackinfofile : function (username, projectName, viewName) {
	return this.baseUrl + "/users"
						+ "/" + username
						+ "/" + projectName
						+ "/" + viewName
						+ "/data/trackInfo.js";
},
getProject : function () {
	return this.projectCombo.get('value');
},
getWorkflow : function () {
	return this.workflowCombo.get('value');
},
getView : function () {
	//console.log("view.View.getView    plugins.view.Views.getView()");	
	//console.log("view.View.getView    Returning this.viewCombo.get('value'): " + this.viewCombo.get('value'));
	return this.viewCombo.get('value');
},
getViewFeature : function () {
	return this.featureList.get('value') ?
		this.featureList.get('value') : '' ;
},
getBuild : function () {
	//console.log("View.getBuild    View.getBuild()");
	return this.buildLabel.innerHTML;
},
getSpecies : function () {
	//console.log("View.getSpecies    View.getSpecies()");
	return this.speciesLabel.innerHTML;
},
// SETTERS
setUrl : function () {
	this.url = Agua.cgiUrl + "agua.cgi?";
	return this.url;
},
setFeatures : function () {
	this.features = new Features({
		parent : this,
		attachPoint : this.featuresAttachPoint,
		url : this.url
	});
	
	var deferred = this._getDeferred();
	console.log("View.setFeatures    RETURNING deferred");
	deferred.resolve({success:true});
	return deferred;
},
setOnkeyListener : function () {
	console.log("View.setOnkeyListener    plugins.view.View.setOnkeyListener()");

	// SET ONKEYPRESS LISTENER
	var thisObject = this;
	this.viewCombo._onKey = function(event){
		console.log("View.setOnKeyListener._onKey	  event: " + event);
		console.dir({event:event});
		
		// summary: handles keyboard events
		var key = event.keyCode;			
		console.log("View.setOnKeyListener._onKey	    key: " + key);
		if ( key == 13 )
		{
			//thisObject.workflowCombo._hideResultList();
			
			var projectName = thisObject.projectCombo.get('value');
			var viewName = thisObject.viewCombo.get('value');
			console.log("View.setOnKeyListener._onKey	   projectName: " + projectName);
			console.log("View.setOnKeyListener._onKey	   thisObject.viewCombo: " + thisObject.viewCombo);
			console.log("View.setOnKeyListener._onKey	   viewName: " + viewName);
			
			// STOP PROPAGATION
			//event.stopPropagation();
			
			console.log("View.setOnKeyListener._onKey	   Checking if isView");
			var isView = Agua.isView(projectName, viewName);
			console.log("View.setOnKeyListener._onKey	   isView: " + isView);
			var isBrowser

			if ( isView == false )	thisObject.confirmAddView(projectName, viewName);
			else if ( ! thisObject.selectBrowser(projectName, viewName) ) {
				thisObject.reloadBrowser(projectName, viewName);
			}
			
			if ( thisObject.viewCombo._popupWidget != null ) {
				thisObject.viewCombo._showResultList();
			}
		}

		// STOP PROPAGATION
		//event.stopPropagation();
	};
	
	var deferred = this._getDeferred();
	console.log("View.setOnkeyListener    RETURNING deferred");
	deferred.resolve({success:true});
	return deferred;
},
setComboListeners : function () {
	console.log("View.setComboListeners    DOING on(this.projectCombo, 'change', this, 'fireProjectCombo')");

	var thisObj = this;
	on(this.projectCombo, 'change', dojo.hitch(this, function(event) {
		console.log("View.setComboListeners    FIRED on(this.projectCombo, 'change')");
		
		this.fireProjectCombo(event);
	}));
	
	on(this.viewCombo, 'change', dojo.hitch(this, function(event) {
		console.log("View.setComboListeners    FIRED on(this.viewCombo, 'change')");
		
		this.fireViewCombo(event);
	}));	
},
// DIALOGS
setConfirmDialog : function () {
	var yesCallback = function (){};
	var noCallback = function (){};
	var title = "Dialog title";
	var message = "Dialog message";
	
	this.confirmDialog = new ConfirmDialog(
		{
			title 				:	title,
			message 			:	message,
			parentWidget 		:	this,
			yesCallback 		:	yesCallback,
			noCallback 			:	noCallback
		}			
	);
},
loadConfirmDialog : function (title, message, yesCallback, noCallback) {
	////console.log("View.loadConfirmDialog    plugins.files.View.loadConfirmDialog()");
	////console.log("View.loadConfirmDialog    yesCallback.toString(): " + yesCallback.toString());
	////console.log("View.loadConfirmDialog    title: " + title);
	////console.log("View.loadConfirmDialog    message: " + message);
	////console.log("View.loadConfirmDialog    yesCallback: " + yesCallback);
	////console.log("View.loadConfirmDialog    noCallback: " + noCallback);

	this.confirmDialog.load(
		{
			title 				:	title,
			message 			:	message,
			yesCallback 		:	yesCallback,
			noCallback 			:	noCallback
		}			
	);
},
setSelectiveDialog : function () {
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "";
	var message = "";
	
	console.log("Stages.setSelectiveDialog    plugins.files.Stages.setSelectiveDialog()");
	this.selectiveDialog = new SelectiveDialog(
		{
			title 				:	title,
			message 			:	message,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
	console.log("Stages.setSelectiveDialog    this.selectiveDialog: " + this.selectiveDialog);
},
loadSelectiveDialog : function (title, message, comboValues, inputMessage, comboMessage, checkboxMessage, enterCallback, cancelCallback) {
	console.log("Stages.loadSelectiveDialog    plugins.files.Stages.loadSelectiveDialog()");
	console.log("Stages.loadSelectiveDialog    enterCallback.toString(): " + enterCallback.toString());
	console.log("Stages.loadSelectiveDialog    title: " + title);
	console.log("Stages.loadSelectiveDialog    message: " + message);
	console.log("Stages.loadSelectiveDialog    enterCallback: " + enterCallback);
	console.log("Stages.loadSelectiveDialog    cancelCallback: " + cancelCallback);


	this.selectiveDialog.load(
		{
			title 				:	title,
			message 			:	message,
			comboValues 		:	comboValues,
			inputMessage 		:	inputMessage,
			comboMessage 		:	comboMessage,
			checkboxMessage		:	checkboxMessage,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
},
// COMBOS
setProjectCombo : function (projectName, viewName) {
	console.log("View.setProjectCombo    projectName: " + projectName);
	console.log("View.setProjectCombo    viewName: " + viewName);

	var deferred = this._getDeferred();
	deferred.resolve({success:true});

	var projects = Agua.getProjects();
	////console.log("  Common.setProjectCombo    projects: " + dojo.toJson(projects));
	var itemArray = Agua.getProjectNames(projects);
	console.log("View.setProjectCombo    BEFORE SORT itemArray: ");
	console.dir({ itemArray: itemArray});
	
	console.log("View.setProjectCombo    DOING itemArray.sort(this.sortNaturally)");
	itemArray.sort(this.sortNaturally);

	console.log("View.setProjectCombo    AFTER SORT itemArray: ");
	console.dir({ projectName: projectName});

	if ( ! itemArray ) {
		console.log("  Common.setProjectCombo    itemArray not defined. Returning deferred.");
		return deferred;
	}

	// CREATE STORE
	console.log("View.setProjectCombo    DOING this.createStore(itemArray)");
	var store = this.createStore(itemArray);
	console.log("View.setProjectCombo    store: " + store);

	// ADD STORE
	this.projectCombo.store = store;	
	
	// SET PROJECT IF NOT DEFINED TO FIRST ENTRY IN projects
	if ( projectName == null || ! projectName)	projectName = itemArray[0];	
	this.projectCombo.set('value', projectName);			
	
	if ( projectName == null )	projectName = this.projectCombo.get('value');

	// RESET THE WORKFLOW COMBO
	console.log("View.setProjectCombo    BEFORE this.setWorkflowCombo(" + projectName + ")");
	return this.setViewCombo(projectName, viewName);
},
setViewCombo : function (projectName, viewName) {
	console.log("View.setViewCombo    projectName: " + projectName);
	console.log("View.setViewCombo    viewName: " + viewName);

	var deferred = this._getDeferred();
	deferred.resolve({success:true});

	// DO COMBO WIDGET SETUP	
	this.inherited(arguments);
	
	// SET VIEW NAME IF NOT DEFINED
	if ( viewName == null ) {
		var views = Agua.getViewsByProject(projectName);
		//console.log("View.setViewCombo    views: " + dojo.toJson(views));
		if ( views == null || views.length == 0 )	{
			console.log("View.setViewCombo    view is NULL or empty. Returning deferred");
			return deferred;
		}
		if ( views.length > 0 ) viewName = views[0].view;
	}

	console.log("View.setViewCombo    DOING this.setSpeciesLabel(" + projectName + ", " + viewName + ")");	
	return this.setSpeciesLabel(projectName, viewName);
},
setSpeciesLabel : function (projectName, viewName) {
// SET SPECIES AND BUILD LABELS
	console.log("View.setSpeciesLabel    plugins.view.View.setSpeciesLabel(projectName, viewName)");
	console.log("View.setSpeciesLabel    projectName: " + projectName);
	console.log("View.setSpeciesLabel    viewName: " + viewName);

	var species = Agua.getSpecies(projectName, viewName);
	this.speciesLabel.innerHTML = species || '';
	var build = Agua.getBuild(projectName, viewName);
	this.buildLabel.innerHTML = build || '';

	// SET SPECIES COMBO VALUE
	var setValue = species + "(" + build + ")";
	if ( this.features && this.features.speciesCombo ) {
		this.features.speciesCombo.set('value', setValue);
	}

	// SET FEATURE LIST
	var viewfeatures = Agua.getViewFeaturesByView(projectName, viewName);
	var featureNames = this.hashArrayKeyToArray(viewfeatures, "feature");
	//for ( var i = 0; i < viewfeatures.length; i++ )
	//	featureNames.push(viewfeatures[i].feature);
	console.log("View.setSpeciesLabel    featureNames: " + dojo.toJson(featureNames));

	return this.setFeatureList(featureNames);
},
setFeatureList : function (itemArray) {
	console.log("View.setFeatureList    plugins.view.View.setFeatureList(itemArray)");
	console.log("View.setFeatureList    itemArray: " + dojo.toJson(itemArray));

	// CREATE STORE
	console.log("View.setFeatureList    DOING this.createStore(itemArray)");
	var store = this.createStore(itemArray);
	console.log("View.setFeatureList    store: " + store);

	// ADD STORE
	this.featureList.store = store;

	// START UP COMBO AND SET SELECTED VALUE TO FIRST ENTRY 
	this.featureList.startup();
	this.featureList.set('value', itemArray[0]);			

	var deferred = this._getDeferred();
	console.log("View.setFeatures    RETURNING deferred");
	deferred.resolve({success:true});
	return deferred;
},
// VIEW METHODS
refreshView : function () {
/* RESET VIEW STATUS TO 'ready' AND RELOAD PANE */
	console.log("View.refreshView    plugins.view.View.refreshView()");
	
	// HIDE STANDBY
	this.standby.hide();
	
	// DISPLAY LOADING
	this.displayLoading();

	// RELOAD BROWSER
	this.reloadBrowser(this.getProject(), this.getView());

	// PREPARE FEATURE TRACK OBJECT
	var featureObject = new Object;

	// SOURCE FEATURE
	featureObject.feature 		= 	this.getFeature();
	featureObject.sourceproject = 	this.getFeatureProject();
	featureObject.sourceworkflow= 	this.getFeatureWorkflow();
	featureObject.species 		= 	this.getFeatureSpecies();
	featureObject.build 		= 	this.getFeatureBuild();
	// VIEW INFO
	featureObject.project 		= 	this.getProject();
	featureObject.view 			= 	this.getView();
	// USER INFO
	featureObject.username 		= 	Agua.cookie('username');
	featureObject.sessionid 	= 	Agua.cookie('sessionid');
	// MODE
	featureObject.mode 			= 	"refreshView";
	featureObject.module 		= 	"Agua::View";

	// DO REMOTE CALL
	var url = Agua.cgiUrl + "agua.cgi";
	var callback = dojo.hitch(this, "_refreshView");
	this.doPut({ url: this.url, query: featureObject, callback: callback });
},
_refreshView : function (response) {
	//console.log("View._refreshView    response: " + dojo.toJson(response));
	//console.log("View._refreshView    this: ");
	;

	// DISPLAY READY
	this.displayReady();

	if ( ! response )	{
		Agua.toastError("Problem reloading 'views'/'viewfeatures'");
	}
	else {
		Agua.setData("views", response.views);
		Agua.setData("viewfeatures", response.viewfeatures);
		this.setViewCombo(this.getProject());
	}
},
updateViewLocation : function (viewObject, location, chrom) {	
	// SKIP IF STILL LOADING

	//console.log("View.updateViewLocation    this.loading: " + this.loading);
	if ( this.loading == true )	return 1;

	//console.log("View.updateViewLocation    caller: " + this.updateViewLocation.caller.nom);
	//console.log("View.updateViewLocation    viewObject: " + viewObject);
	//console.dir({viewObject:viewObject});
	//console.log("View.updateViewLocation    location: " + location);
	//console.dir({location:location});
	//console.log("View.updateViewLocation    chrom: " + chrom);
	//console.log("View.updateViewLocation    this.loading: ");
	//console.dir({loading:this.loading});
	//console.log("View.updateViewLocation    VIEWS: ");
	//console.dir({views:Agua.data.views})
	
	// SKIP IF LOCATION NOT DEFINED OR NO MATCH
	if ( location == null )	return 1;
	var matches = String(location).match(/^([^:]+):([0-9]+)\.\.([0-9]+)/i);
	//console.log("View.updateViewLocation    matches: ");
	//console.dir({matches:matches})
	
	if ( matches == null )	return 1;

	// PARSE LOCATION FOR CHROMOSOME, START AND STOP
	//matches[6] = end base (or center base, if it's the only one)
	var chromosome = matches[1];
	if ( chromosome == null)	chromosome = chrom;
	var start = parseInt(matches[2]);
	var stop = parseInt(matches[3]);
	console.log("View.updateViewLocation    chromosome: " + chromosome);
	console.log("View.updateViewLocation    start: " + start);
	console.log("View.updateViewLocation    stop: " + stop);

	// SKIP IF BOTH START AND STOP NOT DEFINED
	if ( ! start && ! stop )	return 1;

	//console.log("View.updateViewLocation    BEFORE Agua.getViewObject");
	//console.dir({views:Agua.data.views})
	
	var object = Agua.getViewObject(viewObject.project, viewObject.view);
	//console.log("View.updateViewLocation    object: " + dojo.toJson(object));
	//console.log("View.updateViewLocation    AFTER Agua.getViewObject");
	//console.dir({views:Agua.data.views})

	if ( ! object ) {
		console.log("View.updateViewLocation    object NOT DEFINED");
		return;
	}
	
	if ( object.chromosome == chromosome
		&& object.start == start
		&& object.stop == stop )	return;

	object.chromosome = chromosome;
	object.start = start;
	object.stop = stop;
	
	//console.log("View.updateViewLocation    BEFORE _removeView(object): " + dojo.toJson(object));
	var success = Agua._removeView(object);
	if ( success != true ) {
		console.log("View.updateViewLocation    Could not do Agua.removeView() for add track to view " + viewObject.view);
		return;
	}
	//console.log("View.updateViewLocation    BEFORE _addView(object): " + dojo.toJson(object));

	success = Agua._addView(object);
	if ( success != true ) {
		////console.log("View.updateViewLocation    Could not do Agua._addView() for update track to view " + viewObject.view);
		return;
	}	
	//////console.log("View.updateViewLocation    Agua.views: " + dojo.toJson(Agua.views, true));

	// ADD STAGE TO stage TABLE IN REMOTE DATABASE
	object.username = Agua.cookie('username');
	object.sessionid = Agua.cookie('sessionid');
	object.mode = "updateViewLocation";
	object.module 		= 	"Agua::View";
	//////console.log("View.updateViewLocation    object: " + dojo.toJson(object));

	this.doPut({ url: this.url, query: object, doToast: false });	
},
handleTrackChange : function (viewObject, track, action) {	
	console.log("View.handleTrackChange    view.View.handleTrackChange(viewObject, track, action)");
	if ( this.loading == true )	return 1;

	//console.log("View.handleTrackChange    caller: " + this.handleTrackChange.caller.nom);
	//console.log("View.handleTrackChange    viewObject: " + dojo.toJson(viewObject));
	//console.log("View.handleTrackChange    track: " + track);
	//console.log("View.handleTrackChange    action: " + action);
		
	var object = Agua.getViewObject(viewObject.project, viewObject.view);
	//console.log("View.handleTrackChange    object: " + dojo.toJson(object));

	var tracks = [];
	//console.log("View.handleTrackChange    object.tracklist: " + object.tracklist);
	if ( object.tracklist ){
		tracks = object.tracklist.split(",");
	}
	//console.log("View.handleTrackChange    AFTER GENERATED, tracks: ");
	//console.dir({tracks:tracks});

	var index;
	for ( var i = 0; i < tracks.length; i++ )
	{
		if ( tracks[i] == track )
		{
			index = i;
			continue;
		}
	}
	//console.log("View.handleTrackChange    index: " + index);

	// IF DOING 'ADD', RETURN IF TRACK IS ALREADY IN TRACKLIST
	if ( action == "add" ) {
		if ( index != null )	return 0;
		else	tracks.push(track);
	}
	
	// IF DOING REMOVE, RETURN IF TRACK IS NOT IN TRACKLIST
	if ( action == "remove" ) {
		if ( index == null )	return 1;
		else	tracks.splice(index, 1);
	}
	//console.log("View.handleTrackChange    AFTER tracks: ");
	//console.dir({tracks:tracks});
	
	// REPLACE TRACKLIST IN VIEW WITH NEW VERSION
	object.tracklist = tracks.join(",");
	//console.log("View.updateViewobject.tracklist    AFTER object.tracklist: " + object.tracklist);

	this.updateViewTracklist(object);
},
updateViewTracklist : function (object) {
	console.log("View.updateViewTracklist    object: ");
	console.dir({object:object});
	
	var success = Agua._removeView(object);
	console.log("View.updateViewTracklist    success: " + success);
	console.dir({views:Agua.cloneData("views")});

	if ( ! success ) {
		console.log("View.updateViewTracklist    Could not do Agua._removeView() for view: " + object.view);
		return;
	}
	success = Agua._addView(object);
	console.log("View.updateViewTracklist    Agua._addView(object) success: " + success);
	console.dir({views:Agua.cloneData("views")});
	if ( ! success ) {
		console.log("View.updateViewTracklist    Could not do Agua._addView() for view: " + object.view);
		return;
	}
	
	// COMPLETE QUERY OBJECT
	object.username = Agua.cookie('username');
	object.sessionid = Agua.cookie('sessionid');
	object.mode = "updateViewTracklist";
	object.module 		= 	"Agua::View";

	this.doPut({ url: this.url, query: object, doToast : false });	
},
confirmAddView : function (projectName, viewName) {
// DISPLAY A 'Copy Workflow' DIALOG THAT ALLOWS THE USER TO SELECT 
// THE DESTINATION PROJECT AND THE NAME OF THE NEW WORKFLOW
	console.log("View.confirmAddView    plugins.files.View.confirmAddView()");
	console.log("View.confirmAddView    this.selectiveDialog: " + this.selectiveDialog);

	var thisObject = this;
	var speciesBuilds = Agua.getSpeciesBuilds();
	console.log("View.confirmAddView    speciesBuilds: " + dojo.toJson(speciesBuilds));

	var cancelCallback = function () {};
	var enterCallback = dojo.hitch(this, function (input, speciesBuild, checked, dialogWidget)
		{
			console.log("View.confirmAddView    Doing enterCallback(input, speciesBuild, checked, dialogWidget)");
			console.log("View.confirmAddView    viewName: " + viewName);
			console.log("View.confirmAddView    projectName: " + projectName);
			console.log("View.confirmAddView    input: " + input);
			console.log("View.confirmAddView    speciesBuild: " + speciesBuild);
			console.log("View.confirmAddView    checked: " + checked);
			console.log("View.confirmAddView    dialogWidget: " + dialogWidget);
			
			dialogWidget.messageNode.innerHTML = "Adding view: " + viewName;
			dialogWidget.close();
			
			console.log("View.confirmAddView    Doing this.addView()");
			thisObject.addView(projectName, viewName, speciesBuild);
		}
	);		

	// SHOW THE DIALOG
	this.selectiveDialog.load(
		{
			title 				:	"Add view: " + viewName,
			message 			:	"Select species/build combination",
			comboValues 		:	speciesBuilds,
			inputMessage 		:	null,
			comboMessage 		:	null,
			checkboxMessage		:	null,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback,
			enterLabel			:	"Add",
			cancelLabel			:	"Cancel"
		}			
	);
},
// ADD VIEW
addView : function (projectName, viewName, speciesBuild) {
	console.log("View.addView    projectName: " + projectName);
	console.log("View.addView    viewName: " + viewName);
	console.log("View.addView    speciesBuild: " + speciesBuild);

	// SHOW STANDBY
	this.standby.show();

	// GET SPECIES AND BUILD
	var species = speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[1];
	var build = speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[2];
	
	// SET SPECIES LABEL TO BLANK
	this.speciesLabel.innerHTML = '';
	this.buildLabel.innerHTML = '';

	var viewObject 		= new Object;
	viewObject.project 	= projectName;
	viewObject.view		= viewName;
	viewObject.species	= species;
	viewObject.build 	= build;
	console.log("View.addView    viewObject: " + viewObject);
	console.dir({viewObject:viewObject});
	
	// ADD VIEW ON REMOTE SERVER
	this._remoteAddView(dojo.clone(viewObject));
},
_remoteAddView : function (viewObject) {	
// ADD VIEW ON REMOTE
	console.log("View._remoteAddView    viewObject:");
	console.dir({viewObject:viewObject});

	var putData 		= 	dojo.clone(viewObject);
	putData.token		=	Agua.token,
	putData.sourceid 	=	this.id,
	putData.callback 	= 	"_handleAddView",
	putData.mode 		= 	"addView";
	putData.module 		= 	"Agua::View";
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid 	= 	Agua.cookie('sessionid');

	var url 			= this.url;
	var callback 		= function (response) {
		console.log("View._remoteAddView    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("View._remoteAddView    Error adding view");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
_handleAddView : function (response) {

	console.group("View-" + this.id + "    _handleAddview");
	console.log("View._handleAddView    response: ");
	console.dir({response:response});
	
	var viewObject 	=	response.viewobject;
	console.log("View._handleAddView    viewObject: ");
	console.dir({viewObject:viewObject});

	var returnValue = true;	
	if ( response.status == 'ready' ) {
		console.log("View._handleAddView    response status is 'ready'");

		console.log("View._handleAddView    DOING this.standby._setTextAttr('')");
		this.standby._setTextAttr("");

		console.log("View._handleAddView    DOING this.standby.hide()");
		this.standby.hide();

		// SET VIEW COMBO
		console.log("View._handleAddView    Doing this.setViewCombo()");
		this.setViewCombo(viewObject.project, viewObject.view);

		if ( ! Agua._addView(dojo.clone(viewObject)) ) {
			console.log("View.addView    Could not add view to this.views[" + viewObject.view + "]");
			Agua.toastError("Error on client. Failed to add view: " + viewObject.view);
			return false;
		}

		// RELOAD BROWSER
		console.log("View._handleAddView    Doing this.reloadBrowser()");
		this.loadBrowser(viewObject.project, viewObject.view); 

		// TOAST SUCCESS
		Agua.toastInfo("Added view: " + viewObject.view);

		return true;
	}
	else if ( response.error ) {
		console.log("View._handleAddView    response status is 'error'");

		// END STANDBY
		this.standby.hide();
		console.log("View.addView    Error on remote. Failed to add view: " + viewObject.view);

		// TOAST ERROR
		Agua.toastError("Error on remote. Failed to add view: " + viewObject.view);
		
		returnValue = false;
	}
	else {
		// END STANDBY
		this.standby.hide();

		// TOAST ERROR
		Agua.toastError("Error on remote. Status is not 'ready': '" + response.status + "'. Failed to add view: " + viewObject.view);

		returnValue = null;
	}

	console.log("View-" + this.id + "    _handleAddView    END");
	console.groupEnd("View-" + this.id + "    _handleAddView");

	return returnValue;
},
// REMOVE VIEW
confirmRemoveView : function () {
	var noCallback = function () {};
	var yesCallback = dojo.hitch(this, function () {
		this.removeView();
	});
	
	// SET TITLE AND MESSAGE
	var projectName = this.getProject();
	var viewName 	= this.getView();
	var title = "Delete view '" + projectName + "." + viewName + "' ?";
	var message = "All its data will be destroyed";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);
},
removeView : function () {
	console.log("View.removeView    plugins.view.View.removeView()");

	var projectName = 	this.getProject();
	var viewName 	= 	this.getView();
	var species 	=	this.getSpecies();
	var build		=	this.getBuild();
	console.log("View.removeView    projectName: " + projectName);
	console.log("View.removeView    viewName: " + viewName);
	console.log("View.removeView    species: " + species);
	console.log("View.removeView    build: " + build);

	// SET SPECIES LABEL TO BLANK
	this.speciesLabel.innerHTML = '';
	this.buildLabel.innerHTML = '';

	var viewObject 		= new Object;
	viewObject.project 	= projectName;
	viewObject.view		= viewName;
	viewObject.species	= species;
	viewObject.build 	= build;
	console.log("View.removeView    viewObject: " + viewObject);
	console.dir({viewObject:viewObject});

	// REMOVE BROWSER
	console.log("View._removeView    Doing this.removeBrowser()");
	var browserObject = this.getBrowser(viewObject.project, viewObject.view);
	console.log("View._removeView    browserObject: ");
	console.dir({browserObject:browserObject});
	if ( browserObject )
		this.removeBrowser(browserObject.browser, viewObject.project, viewObject.view);
	
	// SET VIEW PROJECT COMBO
	var previousView = Agua.getPreviousView(viewObject);
	console.log("View.removeView    previousView: ");
	console.dir({previousView:previousView});
	if ( previousView ) {
		console.log("View.removeView    XXX DOING this.setProjectCombo(previousView.project, previousView.view)");
		this.setProjectCombo(previousView.project, previousView.view);
	}

	Agua.toastInfo("Removed view: " + viewObject.view);

	this._remoteRemoveView(dojo.clone(viewObject));	
},
_removeView : function (viewObject) {
// REMOVE VIEW ON CLIENT, REMOVE BROWSER TAB AND RELOAD BROWSER

	console.log("View._removeView    viewObject: " + dojo.toJson(viewObject));
	console.dir({viewObject:viewObject});

	if ( ! Agua.removeView(viewObject) ) {
		console.log("View._removeView    Could not remove view: " + viewObject.view);
		return;
	}

	//var previousView = Agua.getPreviousView(viewObject);
	//console.log("View._removeView    previousView: ");
	//console.dir({previousView:previousView});
	
},
_remoteRemoveView : function (viewObject) {	
// REMOVE VIEW ON REMOTE
	console.log("View._remoteRemoveView    viewObject:");
	console.dir({viewObject:viewObject});

	var putData 		= 	dojo.clone(viewObject);
	putData.mode 		= 	"removeView";
	putData.module 		= 	"Agua::View";
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid 	= 	Agua.cookie('sessionid');

	var thisObject 		= this;
	var url 			= this.url;
	var callback 		= function (response) {
		console.log("View._remoteRemoveView    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("View._remoteRemoveView    Error removing view");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
_handleRemoveView : function (response, viewObject) {
	console.log("View._handleRemoveView    response: ");
	console.dir({response:response});
	console.log("View._handleRemoveView    viewObject: ");
	console.dir({viewObject:viewObject});
	
	var returnValue;
	if ( response.status == 'ready' ) {

		console.log("View._handleRemoveView    HERE 1 XXX");
		console.log("View._handleRemoveView    Removed view on remote: " + viewObject.view);

		if ( this.standby._textNode )
			this.standby._setTextAttr("");

		// HIDE STANDBY
		this.standby.hide();

		// REMOVE VIEW ON CLIENT
		this._removeView(dojo.clone(viewObject));

		// REMOVE BROWSER
		console.log("View._handleRemoveView    Doing this.removeBrowser()");
		var browserObject = this.getBrowser(viewObject.project, viewObject.view);
		console.log("View._handleRemoveView    browserObject: ");
		console.dir({browserObject:browserObject});
		this.removeBrowser(browserObject.browser, viewObject.project, viewObject.view);
		
		// GET PREVIOUS VIEW
		console.log("View._handleRemoveView    DOING Agua.getPreviousView(viewObject)");
		var previousView = Agua.getPreviousView(viewObject);
		console.log("View._handleRemoveView    previousView: ");
		console.dir({previousView:previousView});
		
		// SET COMBOS TO PREVIOUS VIEW
		console.log("View._handleRemoveView    DOING this.setProjectCombo(previousView.project, previousView.view)");
		this.setProjectCombo(previousView.project, previousView.view);

		// TOAST INFO
		Agua.toastInfo("Removed view: " + viewObject.view);
		
		returnValue = true;
	}
	else if ( response.error ) {
		console.log("View._handleRemoveView    Error on remote. Failed to remove view: " + viewObject.view);

		// HIDE STANDBY
		this.standby.hide();

		// TOAST ERROR
		Agua.toastError("Error on remote. Failed to remove view: " + viewObject.view);

		returnValue = false;
	}
	else {
		// HIDE STANDBY
		this.standby.hide();

		// TOAST ERROR
		Agua.toastError("Error on remote. Status is not 'ready': '" + response.status + "'. Failed to remove view: " + viewObject.view);

		returnValue = null;
	}
	
	return returnValue;
},
// ADD VIEW FEATURE
_handleAddViewFeature : function (response) {
	console.log("Features._handleAddViewFeature    response: ");
	console.dir({response:response});

	var featureObject 	=	response.featureobject;
	console.log("Features._handleAddViewFeature    featureObject: ");
	console.dir({featureObject:featureObject});
		
	var returnValue;
	if ( response.status == 'ready' ) {
		this.standby._setTextAttr("");
		this.standby.hide();
		
		// ADD ON CLIENT
		console.log("Features._handleAddViewFeature    featureObject: ");
		this._addViewFeature(dojo.clone(featureObject));

		// SET VIEW COMBO
		console.log("Features._handleAddViewFeature    Doing this.setViewCombo(featureObject.project, featureObject.view)")
		this.setViewCombo(featureObject.project, featureObject.view);
	
		// RELOAD BROWSER
		console.log("Features._handleAddViewFeature    Doing this.reloadBrowser(featureObject.project, featureObject.view)")
		this.reloadBrowser(featureObject.project, featureObject.view);
	
		// TOAST INFO
		Agua.toastInfo("Added feature '" + featureObject.feature + "' to view '" + featureObject.project + "." + featureObject.view + "'");
		
		returnValue = true;
	}
	else if ( response.error ) {
		// HIDE STANDBY
		this.standby.hide();

		// TOAST INFO
		Agua.toastInfo("Error on remote. Failed to remove feature '" + featureObject.feature + "' from view '" + featureObject.project + "." + featureObject.view + "'");
		
		returnValue = false;
	}
	else {
		Agua.toastError("Error on remote. Status is not 'ready': '" + response.status + "'. Failed to remove view: " + viewObject.view);

		returnValue = null;
	}
	
	return returnValue;
},
_addViewFeature : function (featureObject) {
	console.log("Features._addViewFeature    featureObject: ");
	console.dir({featureObject:featureObject});

	// ADD FEATURE TO VIEW
	if ( ! Agua._addViewFeature(featureObject) ) {
		console.log("Features._addViewFeature    Agua._addViewFeature FAILED");
		Agua.toastError("Failed to add feature to local data: " + featureObject.feature);
	}
},

// REMOVE VIEW FEATURE
removeViewFeature : function () {
	console.log("Features.removeViewFeature    plugins.view.View.removeViewFeature()");
	if ( ! this.getViewFeature()	)	return;

	var project		=	this.getProject();
	var view 		= 	this.getView();
	var feature 	= 	this.getViewFeature();

	if ( ! Agua.hasViewFeature(project, view, feature) ) {
		console.log("Features.removeViewFeature    Feature NOT present. Returning");
		return;
	}

	// DISPLAY STANDBY
	this.showStandby("Removing feature '" + feature + "' <br>from view '" + project + "." + view + "'");

	// REMOVE FROM CLIENT AND REMOTE
	var featureObject 			= new Object;
	featureObject.project 		= this.getProject();
	featureObject.view 			= this.getView();
	featureObject.feature 		= this.getViewFeature();
	featureObject.species		= this.getSpecies();
	featureObject.build 		= this.getBuild();
	featureObject.username 		= Agua.cookie('username');
	featureObject.sessionid 	= Agua.cookie('sessionid');
	featureObject.mode 			= "removeViewFeature";
	featureObject.module 		= "Agua::View";
	console.log("Features.removeViewFeature    featureObject: " + dojo.toJson(featureObject, true));

	// REMOVE ON REMOTE
	this._remoteRemoveViewFeature(dojo.clone(featureObject));
},
_remoteRemoveViewFeature : function (featureObject) {
	console.log("Features._remoteRemoveViewFeature    featureObject:");
	console.dir({featureObject:featureObject});

	// SET USER INFO AND MODE
	var putData 		= dojo.clone(featureObject);
	putData.username 	= Agua.cookie('username');
	putData.sessionid 	= Agua.cookie('sessionid');
	putData.mode 		= "removeViewFeature";
	putData.module 		= "Agua::View";

	var url 			= this.url;
	var callback 		= function (response) {
		console.log("Features._remoteRemoveViewFeature    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("Features._remoteRemoveViewFeature    Error removing viewFeature");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
_handleRemoveViewFeature : function (response) {
	console.log("Features._handleRemoveViewFeature    response: ");
	console.dir({response:response});
	
	var featureObject = response.featureobject;
	console.log("Features._handleRemoveViewFeature    featureObject: ");
	console.dir({featureObject:featureObject});
	
	var returnValue;
	if ( response.status == 'ready' ) {

		this.standby._setTextAttr("");
		this.standby.hide();

		// REMOVE ON CLIENT
		this._removeViewFeature(dojo.clone(featureObject));

		// RESET COMBOS
		console.log("Features._handleRemoveViewFeature    DOING this.setViewCombo(" + featureObject.project + ", " + featureObject.view + ")");
		this.setViewCombo(featureObject.project, featureObject.view);
	
		// RELOAD BROWSER
		console.log("Features._handleRemoveViewFeature    DOING this.reloadBrowser(" + featureObject.project + ", " + featureObject.view + ")");
		this.reloadBrowser(featureObject.project, featureObject.view);
	
		Agua.toastInfo("Removed feature '" + featureObject.feature + "' from view '" + featureObject.project + "." + featureObject.view + "'");

		returnValue = true;
	}
	else if ( response.error ) {

		// HIDE STANDBY
		this.standby.hide();

		// TOAST ERROR
		Agua.toastError("Error on remote. Failed to remove view feature: " + featureObject.feature);

		returnValue = false;
	}
	else {
		console.log("Features._handleRemoveViewFeature    Doing this._handleRemoveViewFeature()");
		var message = "View._delayedPoll    handleRemoveViewFeature";
		this._delayedPoll(dojo.clone(featureObject), dojo.hitch(this,"_handleRemoveViewFeature"), message);

		returnValue = null;
	}
	
	return returnValue;
},
_removeViewFeature : function (featureObject) {
	console.log("Features._removeViewFeature    featureObject: " + dojo.toJson(featureObject));

	// REMOVE FEATURE FROM VIEW
	console.log("Features._removeViewFeature    Doing Agua._removeViewFeature()");
	if ( ! Agua._removeViewFeature(featureObject) ) {
		console.log("Features._removeViewFeature    Agua._removeViewFeature FAILED");
	Agua.toastError("Failed to remove feature from local data: " + featureObject.feature);
	}
},
// STANDBY
setStandby : function () {
	console.log("View.setStandby    _GroupDragPane.setStandby()");
	if ( this.standby != null )	return this.standby;
	
	var id = dijit.getUniqueId("dojox_widget_Standby");
	this.standby = new Standby (
		{
			target: this.rightPane.domNode,
			//onClick: "reload",
			centerIndicator : "text",
			text: "Loading",
			id : id
			//, url: "plugins/core/images/agua-biwave-24.png"
		}
	);
	document.body.appendChild(this.standby.domNode);
	dojo.addClass(this.standby._textNode, "viewStandby");
	console.log("View.setStandby    this.standby: ");
	console.dir({this_standby:this.standby});
	
	return this.standby;
},
showStandby : function (message) {
	// SET STANDBY TEXT
	console.log("View.showStandby    message: " + message);
	this.standby._setTextAttr(message);
	this.standby.show();
},	
hideStandby : function () {
	// SET STANDBY TEXT
	this.standby._setTextAttr("");
	this.standby.hide();
},	
// BROWSER METHODS
loadBrowser : function (projectName, viewName) {
	console.group("View-" + this.id + "    loadBrowser");
	console.log("View.loadBrowser      ********************* caller: " + this.loadBrowser.caller.nom);
	console.log("View.loadBrowser      PASSED projectName: " + projectName);
	console.log("View.loadBrowser      PASSED viewName: " + viewName);
	
	if ( projectName == null )	projectName = this.getProject();
	if ( viewName == null )		viewName = this.getView();
	console.log("View.loadBrowser      projectName: " + projectName);
	console.log("View.loadBrowser      viewName: " + viewName);

	var username = Agua.cookie('username');
	console.log("View.loadBrowser      username: " + username);

	// CHECK INPUTS
	if ( ! viewName )	{
		console.log("View.loadBrowser      viewName not defined. Returning");
		return;
	}
	if ( projectName == null || viewName == null ) {
		console.log("View.loadBrowser    One of the required inputs (projectName, viewName) is null. Returning");
		return;
	}
	
	// SELECT VIEW TAB IF EXISTS
	if ( this.selectBrowser(projectName, viewName) )	return;
	
	// SET REFSEQS FILE
	var refSeqFile = this.getRefSeqFile(username, projectName, viewName);
	console.log("View.loadBrowser      refSeqFile: " + refSeqFile);

	// SET VIEW OBJECT
	var viewObject = Agua.getViewObject(projectName, viewName);
	console.log("View.loadBrowser      viewObject: " + dojo.toJson(viewObject));
	console.dir({viewObject:viewObject});
	if ( ! viewObject )	{
		console.log("View.loadBrowser      viewObject is not defined. Returning");
		return;
	}
	
	// SET LOCATION 
	var location	=	viewObject.chromosome + ":" + viewObject.start + "..." + viewObject.stop;
	console.log("View.loadBrowser      location: " + location);
	
	// GET UNIQUE ID FOR THIS MENU TO BE USED IN DND SOURCE LATER
	var objectName = "plugins.view.View.jbrowse.Browser";
	var browserId = dijit.getUniqueId(objectName.replace(/\./g,"_"));
	
	// SET LOADING FLAG TO STOP PREMATURE updateViewLocation/ViewTracklist
	this.loading = true;

	var queryParams = {
		data : this.baseUrl + "/users/" + username + "/" + projectName + "/" + viewName+ "/data/",
		highlight: "",
		loc: location,
		tracks	:	viewObject.tracks
		//tracks: "DNA,snps,Genes,ExampleFeatures,CDS,volvox_microarray.bw_density,volvox-sorted.bam_coverage,volvox_sine_xyplot,volvox_vcf_test,volvox_microarray.wig,volvox-sorted.bam,Clones"
	};
	console.log("View.loadBrowser    queryParams:");
	console.dir({queryParams:queryParams});

	// Browser	
	var b; 
	var thisObject = this;
	//try {
		b = new Browser({
			parentWidget 	: this,
			viewObject	 	: viewObject,
			attachWidget 	: this.rightPane,

			refSeqs			: refSeqFile,
			baseUrl 		: this.baseUrl,
			include			: [
				//{
				//	version:	"1",
				//	url:	this.baseUrl + "/users/" + username + "/jbrowse_conf.json"
				//},
				{
					version:	"1",
					url:		queryParams.data + "/trackList.json"
				}
			],

			browserRoot 	: this.browserRoot,
			nameUrl: queryParams.data + "/names/root.json",
			queryParams: queryParams,
			location: queryParams.loc,
			forceTracks: queryParams.tracks,
			initialHighlight: queryParams.highlight,
			show_nav: queryParams.nav,
			show_tracklist: true,
			show_overview: queryParams.overview,
			makeFullViewURL: function( browser ) {
				return browser.makeCurrentViewURL({ nav: 1, tracklist: 1, overview: 1 });
			},
			updateBrowserURL: true,
		});
		
		// SUBSCRIBE TO TRACK CHANGES
		b.subscribe( '/jbrowse/v1/c/tracks/replace', dojo.hitch( this, 'replaceTracks' ));
		b.subscribe( '/jbrowse/v1/c/tracks/delete',  dojo.hitch( this, 'updateTracks', b ));

	/*
	}
	catch(error) {
		console.log("View.loadBrowser    new Browser FAILED. Returning");
		console.dir({error:error});
	
		thisObject.loading = false;
		thisObject.loadError(error);
		return;
	}
	*/
	
	// ADD TO this.browsers ARRAY		
	this.addBrowser(b, projectName, viewName);
	console.dir({browser:b});
	console.log("View.loadBrowser    XXXXXXX AFTER this.addBrowser(...) XXXXXX");
	console.log("View.loadBrowser    this.loading: " + this.loading);
	
	// CONNECT TO browser.mainTab DESTROY TO DO this.removeBrowser
	dojo.connect(b.mainTab, "destroy", dojo.hitch(this, "removeBrowserObject", b, projectName, viewName));

	this.loading = false;
	console.log("View.loadBrowser    XXXXXXX SET this.loading TO : " + this.loading + " XXXXXXX");

	console.groupEnd("View-" + this.id + "    loadBrowser");	

	return b;

}, // 	END loadBrowser 
updateTracks : function (browser) {
	console.log("View.updateTracks    browser:");
	console.dir({browser:browser});
	
	var tracks = [];
	for ( var i = 0; i < browser.view.tracks.length; i++ ) {
		tracks.push(browser.view.tracks[i].key);
	}
	console.log("View.updateTracks    tracks:");
	console.dir({tracks:tracks});

	var viewObject = browser.viewObject;
	console.log("View.updateTracks    BEFORE viewObject: "  + dojo.toJson(viewObject));
	console.dir({viewObject_tracks:viewObject.tracks});
	viewObject.tracks = tracks.join();
	console.log("View.updateTracks    AFTER viewObject: "  + dojo.toJson(viewObject));
	console.dir({viewObject_tracks:viewObject.tracks});

	this.updateViewTracklist(viewObject);
},
showTracks : function (browser) {
	console.log("View.showTracks    browser:");
	console.dir({browser:browser});
	
	var tracks = [];
	for ( var i = 0; i < browser.view.tracks.length; i++ ) {
		tracks.push(browser.view.tracks[i].key);
	}
	console.log("View.showTracks    tracks:");
	console.dir({tracks:tracks});

	var viewObject = browser.viewObject;
	console.log("View.showTracks    BEFORE viewObject: " + dojo.toJson(viewObject));
	console.dir({viewObject:viewObject});
	viewObject.tracks = tracks.join();
	console.log("View.showTracks    AFTER viewObject:");
	console.dir({viewObject:viewObject});

	this.updateViewTracklist(viewObject);
},
hideTracks : function (args) {
	console.log("View.hideTracks    args:");
	console.dir({args:args});
	this.showTracks(args);
},
replaceTracks : function (args) {
	console.log("View.replaceTracks    args:");
	console.dir({args:args});
},
getLocationObject : function (viewObject) {
// DEFAULT RANGE IS LEFT TENTH OF FIRST CHROMOSOME
	console.log("View.getLocationObject    viewObject:");
	console.dir({viewObject:viewObject});
	
	var locationObject = new Object;
	locationObject.name		= 	viewObject.chromosome;
	locationObject.start	=	parseInt(viewObject.start);
	locationObject.stop		=	parseInt(viewObject.stop);

	console.log("View.getLocationObject    Returning locationObject:");
	console.dir({locationObject:locationObject});

	return locationObject;	
},
loadError : function (error) {
	console.log("View.loadError    error: " + error);
	console.dir({error:error});
	
},
reloadBrowser : function (projectName, viewName) {
	console.log("View.reloadBrowser      caller: " + this.reloadBrowser.caller.nom);
	console.log("View.reloadBrowser      projectName: " + projectName);
	console.log("View.reloadBrowser      viewName: " + viewName);

	var browser = this.getBrowser(projectName, viewName); 
	if ( browser != null )
	{
		// REMOVE EXISTING BROWSER FOR THIS VIEW
		console.log("View.reloadBrowser    BEFORE this.removeBrowser(projectName, workflow, viewName)");
		this.removeBrowser(browser.browser, projectName, viewName);
		console.log("View.reloadBrowser    AFTER this.removeBrowser(projectName, workflow, viewName)");
	}
	this.loadBrowser(projectName, viewName);

	console.log("View.reloadBrowser    AFTER loadBrowser");

}, // 	reloadBrowser 
selectBrowser : function (projectName, viewName) {
// FOR EACH NEWLY OPENED VIEW TAB, THE ASSOCIATED BROWSER 
// OBJECT IS ADDED TO this.browsers ARRAY
	//console.log("View.selectBrowser    plugins.view.View.selectBrowser(projectName, viewName)");
	console.log("View.selectBrowser    projectName: " + projectName);
	console.log("View.selectBrowser    viewName: " + viewName);

	var browserObject = this.getBrowser(projectName, viewName);
	console.log("View.selectBrowser    browserObject: " + browserObject);

	if ( browserObject == null )	return;
	var browser = browserObject.browser;

	//console.log("View.selectBrowser    BEFORE selectChild(browser.mainTab)");
	this.rightPane.selectChild(browser.mainTab);
	//console.log("View.selectBrowser    AFTER selectChild(browser.mainTab)");
	
	return 1;
},
getBrowser : function (projectName, viewName) {
	//console.log("View.getBrowser    projectName: " + projectName);
	//console.log("View.getBrowser    viewName: " + viewName);

	var index = this.getBrowserIndex(projectName, viewName);
	console.log("View.getBrowser    index: " + index);
	if ( index == null )	return;

	return this.browsers[index];
},
addBrowser : function(browser, projectName, viewName) {
// FOR EACH NEWLY OPENED VIEW TAB, THE ASSOCIATED BROWSER 
// OBJECT IS ADDED TO this.browsers ARRAY
	//console.log("View.addBrowser    plugins.view.View.addBrowser(browser, project, workflow, view)");
	console.log("View.addBrowser    browser: " + browser);
	console.log("View.addBrowser    projectName: " + projectName);
	console.log("View.addBrowser    viewName: " + viewName);
	console.log("View.addBrowser    viewId: " + this.id);
	
	var browserObject = {
		browser : 	browser,
		project: 	projectName,
		view:		viewName,
		viewid:     this.id
	};

	var success = this._addObjectToArray(this.browsers, browserObject, ["browser", "project", "view", "viewid"]);
	console.log("View.addBrowser    success: " + success);

	//// ADD TO TABS
	//this.rightPane.addChild(browserObject.browser.mainTab);
	//this.rightPane.selectChild(browserObject.browser.mainTab);
	
	return success;	
},
isBrowser : function (projectName, viewName) {
	console.log("View.isBrowser    projectName: " + projectName);
	console.log("View.isBrowser    viewName: " + viewName);

	if ( this.getBrowserIndex(projectName, viewName) != null )	{
		console.log("View.isBrowser    Returning 1");
		return 1;
	}
	else {
		console.log("View.isBrowser    Returning 0");
		return 0;
	}	
},
getBrowserIndex : function (projectName, viewName) {
	console.log("View.getBrowserIndex    projectName: " + projectName);
	console.log("View.getBrowserIndex    viewName: " + viewName);
	console.log("View.getBrowserIndex    this.browsers: ");
	console.dir({this_browsers:this.browsers});

	var browserObject = {
		project	: 	projectName,
		view	:	viewName
	};

	var index = this._getIndexInArray(this.browsers, { project: projectName, view: viewName }, [ "project", "view" ])
	console.log("View.getBrowserIndex    index: " + index);	
	
	return index;
},
removeBrowser : function (browser, projectName, viewName) {
// WHEN A VIEW TAB IS CLOSED, REMOVE ITS ASSOCIATED
// browser OBJECT FROM this.browsers AND DESTROY IT
	console.log("View.removeBrowser    plugins.viewName.View.removeBrowser(browser, projectName, viewName)");
	console.log("View.removeBrowser    browser: " + browser);
	console.log("View.removeBrowser    projectName: " + projectName);
	console.log("View.removeBrowser    viewName: " + viewName);
	
	this.removeBrowserTab(browser);
	var success = this.removeBrowserObject(browser, projectName, viewName);
	console.log("View.removeBrowser    success: " + success);

},
removeBrowserObject : function (browser, projectName, viewName) {
	console.log("View.removeBrowserObject    caller: " + this.removeBrowserObject.caller.nom);
	console.log("View.removeBrowserObject    browser: " + browser);
	console.dir({browser:browser});
	console.log("View.removeBrowserObject    projectName: " + projectName);
	console.log("View.removeBrowserObject    viewName: " + viewName);
	console.log("View.removeBrowserObject    BEFORE this.browsers: ");
	console.dir({this_browsers:this.browsers});

	var browserObject = {
		browser : 	browser,
		project: 	projectName,
		view:		viewName
	};
	console.log("View.removeBrowserObject    browserObject: ");
	console.dir({browserObject:browserObject});

	console.log("View.removeBrowserObject    BEFORE this.browsers.length: " + this.browsers.length);
	var success = this._removeObjectFromArray(this.browsers, browserObject, ["browser", "project", "view"]);
	console.log("View.removeBrowserObject    success: " + success);
	console.log("View.removeBrowserObject    AFTER this.browsers: ");
	console.dir({this_browsers:this.browsers});
	console.log("View.removeBrowserObject    AFTER this.browsers.length: " + this.browsers.length);

	return success;	
},
removeBrowserTab : function (browser, projectName, viewName) {
	// REMOVE BROWSER TAB FROM PANE
	console.log("View.removeBrowserTab    browser:");
	console.dir({browser:browser});
	
	this.rightPane.removeChild(browser.mainTab);
	console.log("View.removeBrowserTab    AFTER removeChild(browser.mainTab)");

	return true;
},
// FIRE COMBO HANDLERS
fireProjectCombo : function() {
	console.log("View.fireProjectCombo    projectCombo._onchange");
	var projectName = this.projectCombo.get('value');
	this.setViewCombo(projectName);
},
fireViewCombo : function (event) {
// ONCHANGE IN VIEW COMBO FIRED
	console.log("00000000000000000000000 View.fireViewCombo    caller: " + this.fireViewCombo.caller.nom);
	console.log("View.fireViewCombo    event: " + event);
	console.dir({event:event});
	console.log("View.fireViewCombo    this.viewComboFired: " + this.viewComboFired);
	console.log("View.fireViewCombo    this.ready: " + this.ready);

	if ( this.lastViewComboValue === event ) {
		console.log("View.fireViewCombo    SKIPPING REPEAT MESSAGE");
		return;
	}
	else {
		this.lastViewComboValue	= event;
		var thisObj = this;
		setTimeout(function() {
			thisObj.lastViewComboValue = null;
		},
		500);
	}

	var projectName = this.getProject();
	var viewName = this.getView();
	console.log("View.fireViewCombo    projectName: " + projectName);
	console.log("View.fireViewCombo    viewName: " + viewName);

	console.log("View.fireViewCombo    DOING this.setSpeciesLabel()");
	this.setSpeciesLabel(projectName, viewName);

	console.log("View.fireViewCombo    DOING this.loadBrowser()");
	this.loadBrowser(projectName, viewName);
},
destroyRecursive : function () {
	console.log("View.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}


}); //	end declare

});	//	end define

console.log("plugins.view.View    END");
