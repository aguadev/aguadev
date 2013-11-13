/* CLASS SUMMARY: CREATE AND MODIFY VIEWS
	
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

define("plugins/view/Features", [
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

	// STATUS
	"plugins/form/Status",

	// STANDBY
	"dojox/widget/Standby",
	
	// WIDGETS IN TEMPLATE
	"dijit/form/ComboBox",
	"dijit/form/Button"
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
	Status,
	Standby
) {

/////}}}}}

return declare("plugins.view.Features",
	[ _Widget, _Templated, Common ], {

// PATH TO WIDGET TEMPLATE
templatePath: dojo.moduleUrl("plugins", "view/templates/features.html"),

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
	require.toUrl("plugins/view/css/features.css")
],

// url: String
// URL FOR REMOTE DATABASE
url: null,

// ready: Boolean
// 		Set to true once startup has completed
ready : false,

////}}}
constructor : function(args) {	
	console.log("Features.constructor    args:");
	console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	
	// LOAD CSS FILES
	this.loadCSS(this.cssFiles);		
},
postCreate: function() {
	this.startup();
},
// STARTUP
startup : function () {

	console.group("Features-" + this.id + "    startup");
	console.log("-------------------------- Features.startup    this.browsers:");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	// ADD THE PANE TO THE TAB CONTAINER
	this.attachPane()

	var thisObj = this;
	this.setProjectCombo().then(function() {
		console.log("Features.startup    INSIDE this.setFeatureCombo().then");
		
		// SET READY
		thisObj.ready = true;
	//
	//		// SET COMBO LISTENERS AFTER DELAY TO AVOID onchange FIRE
	//		setTimeout(function(thisObj) {
	//			thisObj.setComboListeners();
	//		},
	//		500,
	//		thisObj)
	//
	//	});
		
		console.log("Features-" + thisObj.id + "    startup    END");
		console.groupEnd("Features-" + thisObj.id + "    startup");
	})
},
attachPane : function () {
	console.log("Features.attachPane    this.attachPoint: " + this.attachPoint);
	if ( this.attachPoint.addChild ) {
		this.attachPoint.addChild(this.containerNode);
		this.attachPoint.selectChild(this.containerNode);
	}
	if ( this.attachPoint.appendChild ) {
		this.attachPoint.appendChild(this.containerNode);
	}	
},
setComboListeners : function () {
	console.log("Features.setComboListeners    DOING on(this.viewProjectCombo, 'change', this, 'fireViewProjectCombo')");

	var thisObj = this;
	on(this.viewProjectCombo, 'change', dojo.hitch(this, function(event) {
		console.log("Features.setComboListeners    FIRED on(this.viewProjectCombo, 'change')");
		
		this.fireViewProjectCombo(event);
	}));

	on(this.viewCombo, 'change', dojo.hitch(this, function(event) {
		console.log("Features.setComboListeners    FIRED on(this.viewCombo, 'change')");
		
		this.fireViewCombo(event);
	}));

	on(this.speciesCombo, 'change', dojo.hitch(this, function(event) {
		console.log("Features.setComboListeners    FIRED on(this.speciesCombo, 'change')");
		
		this.fireSpeciesCombo(event);
	}));
	
	on(this.workflowCombo, 'change', dojo.hitch(this, function(event) {
		console.log("Features.setComboListeners    FIRED on(this.workflowCombo, 'change')");
		
		this.fireWorkflowCombo(event);
	}));

},
_getDeferred : function() {
    if( ! this._deferred )
        this._deferred = new Deferred();
    return this._deferred;
},
// DISPLAY STATUS
setDisplayStatus : function () {
	this.displayStatus = new Status({
		status		:	"loading",
		attachPoint : 	this.leftPane.titleWrapper
	});	
},
displayLoading : function () {
	console.log("Features.displayReady    this.displayStatus:");
	this.displayStatus.setStatus("loading");
},
displayReady : function () {
	console.log("Features.displayReady    this.displayStatus:");
	console.dir({this_displayStatus:this.displayStatus});

	this.displayStatus.setStatus("ready");
},
loadEval : function (url) {
	console.log("Features.loadEval    url: " + url);
	// SEND TO SERVER
	dojo.xhrGet(
		{
			url: url,
			sync: true,
			handleAs: "text",
			load: function(response) {
				//console.log("Features.loadEval    response: " + dojo.toJson(response));
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
getWorkflow : function () {
	return this.workflowCombo.get('value');
},
getBuild : function () {
	//console.log("Features.getBuild    View.getBuild()");
	var speciesBuild = this.speciesCombo.get('value');
	//console.log("Features.getBuild    speciesBuild: "+ speciesBuild);

	if ( speciesBuild.match(/^(\S+)\(([^\)]+)\)$/) )
		return  speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[2];
},
getSpecies : function () {
	//console.log("Features.getSpecies    View.getSpecies()");
	//console.log("Features.getSpecies    this: " + this);

	var speciesBuild = this.speciesCombo.get('value');
	//console.log("Features.getSpecies    speciesBuild: "+ speciesBuild);

	if ( speciesBuild.match(/^(\S+)\(([^\)]+)\)$/) )
		return speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[1];
},
getFeature : function () {
	return this.featureCombo.get('value');
},
getProject : function () {
	return this.projectCombo.get('value');
},
// COMBO METHODS
setProjectCombo : function (projectName) {
	console.log("Features.setProjectCombo    projectName: " + projectName);

	var features = Agua.getFeatures();
	console.log("  .setProjectCombo    features: ");
	console.dir({features:features});

	var itemArray = this.hashArrayKeyToArray(features, "project");
	itemArray = this.uniqueValues(itemArray);
	console.log("  View.setProjectCombo    itemArray: ");
	console.dir({itemArray:itemArray});

	// CREATE STORE
	console.log("Features.setProjectCombo    DOING this.createStore(itemArray)");
	var store = this.createStore(itemArray);
	console.log("Features.setProjectCombo    store: " + store);

	// ADD STORE
	this.projectCombo.store = store;	
	
	// SET PROJECT IF NOT DEFINED TO FIRST ENTRY IN projects
	if ( projectName == null || ! projectName)
		projectName = itemArray[0];	
	this.projectCombo.set('value', projectName);			
	
	if ( projectName == null )
		projectName = this.projectCombo.get('value');

	// RESET THE WORKFLOW COMBO
	//console.log("Common.setProjectCombo    BEFORE this.setWorkflowCombo(" + projectName + ")");
	return this.setWorkflowCombo(projectName);
},
setWorkflowCombo : function (projectName, workflowName) {
	console.log("Features.setWorkflowCombo    projectName: " + projectName);
	console.log("Features.setWorkflowCombo    workflowName: " + workflowName);

	var deferred = this._getDeferred();
	deferred.resolve({success:true});

	if ( projectName == null
	|| ! projectName
	|| this.workflowCombo == null ) {
		console.log("Features.setWorkflowCombo    RETURNING deferred");
		return deferred;
	}
	
	// CREATE THE DATA FOR A STORE
	var itemArray = Agua.getViewProjectWorkflows(projectName);
	console.log("Features.setWorkflowCombo    projectName '" + projectName + "' itemArray: ");
	console.dir({itemArray:itemArray});
	
	// RETURN IF itemArray NOT DEFINED
	if ( ! itemArray )	return;

	// CREATE STORE
	console.log("Features.setWorkflowCombo    DOING this.createStore(itemArray)");
	var store = this.createStore(itemArray);
	console.log("Features.setWorkflowCombo    store: " + store);

	// ADD STORE
	this.workflowCombo.store = store;

	// START UP COMBO AND SET SELECTED VALUE TO FIRST ENTRY IN itemArray IF NOT DEFINED 
	if ( workflowName == null || ! workflowName )	workflowName = itemArray[0];
	//console.log("Features.setWorkflowCombo    workflowName: " + workflowName);

	this.workflowCombo.startup();
	this.workflowCombo.set('value', workflowName);			

	if ( projectName == null ) projectName = this.viewProjectCombo.get('value');
	if ( workflowName == null ) workflowName = this.workflowCombo.get('value');

	// RESET THE VIEW COMBO
	this.setSpeciesCombo(projectName, workflowName);

	return deferred;
},
setSpeciesCombo : function (projectName, workflowName, speciesName, buildName) {
	//console.log("Features.setSpeciesCombo    plugins.view.View.setSpeciesCombo(projectName, workflowName)");
	//console.log("Features.setSpeciesCombo    projectName: " + projectName);
	//console.log("Features.setSpeciesCombo    workflowName: " + workflowName);

	// SET DROP TARGET (LOAD MIDDLE PANE, BOTTOM)
	if ( projectName == null ) projectName = this.projectCombo.get('value');
	if ( workflowName == null ) workflowName = this.workflowCombo.get('value');

	var viewfeatures = Agua.getViewWorkflowFeatures(projectName, workflowName);
	if ( viewfeatures == null || viewfeatures.length == 0 ) {
		//console.log("Features.setSpeciesCombo    viewfeatures is null or empty. Returning");
		return;
	}
	////console.log("Features.setSpeciesCombo    viewfeatures: " + dojo.toJson(viewfeatures));

	// GET SPECIES+BUILD NAMES
	var itemArray = new Array;
	for ( var i = 0; i < viewfeatures.length; i++ ) {
		itemArray.push(viewfeatures[i].species + "(" + viewfeatures[i].build + ")");
	}
	itemArray = this.uniqueValues(itemArray);
	//console.log("Features.setSpeciesCombo    itemArray: " + dojo.toJson(itemArray));

	// SET SPECIES+ BUILD NAME
	var speciesBuildName;
	if ( speciesName == null || ! speciesName
		|| buildName == null || ! buildName ) {
		speciesBuildName = itemArray[0];
		speciesName = viewfeatures[0].species;
		buildName = viewfeatures[0].build;
	}
	else {
		speciesBuildName = speciesName + "(" + buildName + ")";
	}
	//console.log("Features.setSpeciesCombo    speciesBuildName: " + speciesBuildName);

	// DO data FOR store
	// CREATE STORE
	console.log("Features.setSpeciesCombo    DOING this.createStore(itemArray)");
	var store = this.createStore(itemArray);
	console.log("Features.setSpeciesCombo    store: " + store);

	// ADD STORE
	this.speciesCombo.store = store;

	// START UP COMBO (?? NEEDED ??)
	this.speciesCombo.startup();
	this.speciesCombo.set('value', speciesBuildName);			

	this.setFeatureCombo(projectName, workflowName, speciesName, buildName);
},
setFeatureCombo : function (projectName, workflowName, speciesName, buildName) {
	console.log("Features.setFeatureCombo    plugins.view.View.setFeatureCombo(projectName, workflowName)");
	console.log("Features.setFeatureCombo    projectName: " + projectName);
	console.log("Features.setFeatureCombo    workflowName: " + workflowName);

	var deferred = this._getDeferred();
	console.log("Features.setFeatureCombo    deferred: " + deferred);
	console.dir({deferred:deferred});
	
	if ( projectName == null || ! projectName 
		|| workflowName == null || ! workflowName 
		|| speciesName == null || ! speciesName 
		|| buildName == null || ! buildName ) {
		console.log("Features.setFeatureCombo    Project, workflow, species or build not defined. Returning.");
		console.log("Features.setFeatureCombo    RETURNING deferred");
		deferred.resolve({success:true});
		return deferred;
	}

	// CREATE THE DATA FOR A STORE		
	var itemArray = 	Agua.getViewSpeciesFeatureNames(projectName, workflowName, speciesName, buildName);
	if ( ! itemArray )
	{
		console.log("Features.setFeatureCombo    itemArray not defined. Returning.");
		console.log("Features.setFeatureCombo    RETURNING deferred");
		deferred.resolve({success:true});
		return deferred;
	}
	console.log("Features.setFeatureCombo    projectName '" + projectName + "' workflowName '" + workflowName + "' speciesName '" + speciesName + "' buildName '" + buildName + "' itemArray: " + dojo.toJson(itemArray));

	// CREATE STORE
	console.log("Features.setFeatureCombo    DOING this.createStore(itemArray)");
	var store = this.createStore(itemArray);
	console.log("Features.setFeatureCombo    store: " + store);

	// ADD STORE
	this.featureCombo.store = store;

	// SET SELECTED VALUE TO FIRST ENTRY IN itemArray
	var featureName = itemArray[0];

	this.featureCombo.startup();
	this.featureCombo.set('value', featureName);			

	console.log("Features.setFeatureCombo    RETURNING deferred");
	deferred.resolve({success:true});
	return deferred;
},
// ADD VIEW FEATURE
addViewFeature : function () {
	console.log("Features.addViewFeature    plugins.view.View.addViewFeature()");
	if ( ! this.getFeature()	)	return;

	var project		=	this.parent.getProject();
	var view 		= 	this.parent.getView();
	var feature 	= 	this.getFeature();

	if ( Agua.hasViewFeature(project, view, feature) ) {
		Agua.toastError("Feature '" + feature + "' already present in view '" + project + "." + view + "'");
		return;
	}

	// DISPLAY LOADING
	this.parent.displayLoading();

	// DISPLAY STANDBY
	this.parent.showStandby("Adding feature '" + feature + "' <br>to view '" + project + "." + view + "'");

	// PREPARE FEATURE TRACK OBJECT
	var featureObject = new Object;
	// VIEW INFO
	featureObject.project 		= project;
	featureObject.view 			= view;
	// SOURCE FEATURE INFO
	featureObject.feature 		= feature;
	featureObject.sourceproject = this.getProject();
	featureObject.sourceworkflow = this.getWorkflow();
	featureObject.species 		= this.getSpecies();
	featureObject.build 		= this.getBuild();
	
	if ( Agua.hasViewFeature == true ) {
		console.log("Features.addViewFeature    hasViewFeature is TRUE");
		return;	
	}

	// ADD ON REMOTE
	this._remoteAddViewFeature(dojo.clone(featureObject));
},
_remoteAddViewFeature : function ( featureObject) {
	console.log("Features._remoteAddViewFeature    featureObject:");
	console.dir({featureObject:featureObject});

	// SET USER INFO AND MODE
	var putData 		= 	{};
	putData.data		=	dojo.clone(featureObject);
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid 	= 	Agua.cookie('sessionid');

	putData.sourceid 	=	this.parent.id,
	putData.token		=	Agua.token,
	putData.callback 	= 	"_handleAddViewFeature",

	putData.mode 		= 	"addViewFeature";
	putData.module 		= 	"Agua::View";

	var url 			= 	this.url;
	var callback 		= 	function (response) {
		console.log("Features._remoteAddViewFeature    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("Features._remoteAddViewFeature    Error adding viewFeature");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
// STANDBY
setStandby : function () {
	console.log("Features.setStandby    _GroupDragPane.setStandby()");
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
	console.log("Features.setStandby    this.standby: ");
	console.dir({this_standby:this.standby});
	
	return this.standby;
},
showStandby : function (message) {
	// SET STANDBY TEXT
	console.log("Features.showStandby    message: " + message);
	this.standby._setTextAttr(message);
	this.standby.show();
},	
hideStandby : function () {
	// SET STANDBY TEXT
	this.standby._setTextAttr("");
	this.standby.hide();
},	
// FIRE COMBO HANDLERS
fireProjectCombo : function() {
	//if ( ! this.ProjectComboFired == true )
	//{
	//	this.projectComboFired = true;
	//}
	//else {
		console.log("Features.fireProjectCombo    plugins.view.View.fireProjectCombo()");
		var projectName = this.projectCombo.get('value');
		this.setWorkflowCombo(projectName);
	//}
},
fireWorkflowCombo : function() {
	//if ( ! this.workflowComboFired == true )
	//{
	//	this.workflowComboFired = true;
	//}
	//else {
		console.log("Features.fireWorkflowCombo    plugins.view.View.fireWorkflowCombo()");
		var projectName = this.projectCombo.get('value');
		var workflowName = this.workflowCombo.get('value');
		this.setSpeciesCombo(projectName, workflowName);
	//}
},
fireSpeciesCombo : function () {
	//if ( ! this.speciesComboFired == true )
	//{
	//	console.log("Features.fireSpeciesCombo    FIRST FIRE");
	//	this.speciesComboFired = true;
	//}
	//else {
		console.log("Features.fireSpeciesCombo    plugins.view.View.fireSpeciesCombo()");
		var projectName = this.viewProjectCombo.get('value');
		var workflowName = this.workflowCombo.get('value');
		var speciesName = this.getSpecies();
		var buildName = this.getBuild();
		console.log("Features.fireSpeciesCombo    projectName: " + projectName);
		console.log("Features.fireSpeciesCombo    workflowName: " + workflowName);
		console.log("Features.fireSpeciesCombo    speciesName: " + speciesName);
		console.log("Features.fireSpeciesCombo    buildName: " + buildName);
		console.log("Features.fireSpeciesCombo    this.setFeatureCombo(" + projectName + ", " + workflowName + ", " + speciesName + ", " + buildName + ")");
		
		if ( speciesName == null || buildName == null )
		{
			console.log("Features.fireSpeciesCombo    speciesName and/or buildName is null. Returning.");
			return;
		}
		
		this.setFeatureCombo(projectName, workflowName, speciesName, buildName);
	//}
},
destroyRecursive : function () {
	console.log("Features.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}


}); //	end declare

});	//	end define

