dojo.provide("plugins.cloud.Clusters");

// ALLOW THE USER TO ADD, REMOVE AND MODIFY StarCluster CLUSTER GROUPS

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.NumberTextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("plugins.dnd.Source");

// FORM VALIDATION
dojo.require("plugins.form.TextArea");
dojo.require("plugins.form.EditForm");
dojo.require("plugins.core.Common");
dojo.require("dijit.form.ComboBox");

// HAS A
dojo.require("plugins.cloud.ClusterRow");

dojo.declare("plugins.cloud.Clusters",
	[ dijit._Widget, dijit._Templated, plugins.core.Common, plugins.form.EditForm ],
{

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "cloud/templates/clusters.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

//addingUser STATE
addingUser : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins") + "/cloud/css/clusters.css"],

// PARENT WIDGET
parentWidget : null,

instancetypeslots: {
	"t1.micro"	:	 1,
	"m1.small"	:  	 1,
	"m1.large"	:	 4,
	"m1.xlarge"	:	 8,
	"m2.xlarge"	:	 7,
	"m2.2xlarge":	13,
	"m2.4xlarge":	26,
	"c1.medium"	:	 5,
	"c1.xlarge"	:	20,
	"cc1.4xlarge":	34,
	"cg1.4xlarge":	34
},

formInputs : {
// FORM INPUTS AND TYPES (word|phrase)
	cluster		:	"word",
	minnodes	:	"number",
	maxnodes	:	"number",
	instancetype:	"combo",
	amiid		:	"word",
	availzone	:	"word",
	description	:	"phrase"
},

defaultInputs : {
// DEFAULT INPUTS
	cluster 	: 	"myCluster",
	minnodes	:	"minNodes",
	maxnodes	:	"maxNodes",
	instancetype:	"instanceType", 
	amiid		:	"AMI ID",
	description	:	"Description",
	notes		:	"Notes"
},

requiredInputs : {
// REQUIRED INPUTS CANNOT BE ''
// combo INPUTS ARE AUTOMATICALLY NOT ''
	cluster 	: 1,
	minnodes 	: 1, 
	maxnodes	: 1, 
	amiid		: 1
},

invalidInputs : {
// THESE INPUTS ARE INVALID
	cluster 	: 	"myCluster",
	minnodes	:	"",
	maxnodes	:	"",
	amiid		:	"",
	description	:	"Description"
},

dataFields : [
	"cluster"
],

rowClass : "plugins.cloud.ClusterRow",

avatarType : "parameters",

avatarItems: [ "cluster", "minnodes", "maxnodes", "instancetype", "description"],

/////}}}
// STARTUP METHODS
constructor : function(args) {
	////////console.log("Clusters.constructor     plugins.cloud.Clusters.constructor");			
	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.clusters = args.parentWidget.clusters;

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	////////console.log("Controller.postCreate    plugins.cloud.Controller.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Clusters.startup    plugins.cloud.Clusters.startup()");
	console.log("Clusters.startup    this: " + this);

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ATTACH PANE
	this.attachPane();

	// SET NEW PARAMETER FORM
	this.setForm();

	// SET AMI COMBO BOX
	this.setAmiCombo();

	// SET DRAG SOURCE - LIST OF CLUSTERS
	this.setDragSource();

	//console.log("Clusters.startup    BEFORE this.setTrash(this.dataFields), I.E., plugins.form.DndTrash.startup()");
	this.setTrash(this.dataFields);	
	//console.log("Clusters.startup    AFTER this.setTrash(this.dataFields), I.E., plugins.form.DndTrash.startup()");

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateClusters");

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateAmis");
},
updateClusters : function (args) {
// RELOAD THE COMBO AND DRAG SOURCE AFTER CHANGES
// TO DATA IN OTHER TABS

	console.log("Cluster.updateClusters    args: " );
	console.dir(args);
	
	// SET DRAG SOURCE
	if ( args == null || args.reload != false ) {
		////console.log("Cluster.updateClusters    Calling setDragSource()");
		this.setDragSource();
	}
},
updateAmis : function (args) {
// RELOAD THE COMBO AND DRAG SOURCE AFTER CHANGES
// TO DATA IN OTHER TABS
	console.log("Amis.updateAmis(args)");
	console.log("Amis.updateAmis    args: " );
	console.dir(args);
	
	if ( args.originator == this )
	{
		if ( args.reload == false )	return;
	}

	console.log("Amis.updateAmis    Doing this.setAmiCombo()");

	// SET AMI COMBO BOX
	this.setAmiCombo();
},
setForm : function () {
// SET LISTENERS TO ACTIVATED SAVE BUTTON AND TO CLEAR DEFAULT TEXT
// WHEN INPUTS ARE CLICKED ON
	////console.log("Clusters.setForm    plugins.cloud.Clusters.setForm()");

	// SET ADD PARAMETER ONCLICK
	dojo.connect(this.addClusterButton, "onclick", dojo.hitch(this, "newCluster", null, null));	

	// SET CLEARVALUE ON CLUSTER VALIDATION TEXT BOX
	dojo.connect(this.cluster, "onFocus", dojo.hitch(this, "clearValue", this.cluster, this.invalidInputs["cluster"]));

	// SET AVAILABILITY ZONE COMBO
	var fakeEvent = {
		target: {
			selectedIndex: 0,
			options : [ {text: "us-east-1"} ]
		}
	};
	this.setAvailzoneCombo(fakeEvent);	

	// SET TRASH, ETC.
	this.inherited(arguments);
},
setAmiInfo : function (event) {
	console.log("Clusters.setAmiInfo     plugins.cloud.Clusters.setAmiInfo(event)");
	//console.log("Clusters.setAmiInfo     event.target: " + event.target);

	var amiid = this.amiid.get('value');
	console.log("Clusters.setAmiInfo     amiid: " + amiid);

	var amiObject = Agua.getAmiObjectById(amiid);
	console.log("Clusters.setAmiInfo     amiObject: " + dojo.toJson(amiObject));

	this.aminame.innerHTML = amiObject.aminame;
	this.amitype.innerHTML = amiObject.amitype;

	this.amiid.focusNode.title = amiObject.description;
	this.amiidContainer.title = amiObject.description;
	this.aminame.title = amiObject.description;
	this.amitype.title = amiObject.description;
},
setAvailzoneCombo : function (event) {
	////console.log("Clusters.setAvailzoneCombo     plugins.cloud.Clusters.setAvailzoneCombo(event)");
	////console.log("Clusters.setAvailzoneCombo     event.target: " + event.target);
	var region = this.getSelectedValue(event.target);
	////console.log("Clusters.setAvailzoneCombo     region: " + region);

	var itemArray = Agua.getAvailzonesByRegion(region);	
	////console.log("Clusters.setAvailzoneCombo     itemArray: " + dojo.toJson(itemArray));
	// CREATE STORE
	var store 	=	this.createStore(itemArray);
		
	// SET COMBO
	this.availzone.store = store;
	this.availzone.startup();
	////console.log("Clusters.setAvailzoneCombo     AFTER this.availzone.startup()");

	// SET COMBO VALUE
	var firstValue = itemArray[0];
	this.availzone.setValue(firstValue);
	////console.log("Clusters.setAvailzoneCombo     AFTER this.availzone.setValue(firstValue)");
},
getItemsArray : function () {
	var amis = Agua.getAmis();	
	console.log("Clusters.getItemsArray     amis: " + dojo.toJson(amis));
	return this.hashArrayKeyToArray(amis, ["amiid"]); 	
},
setAmiCombo : function () {
	console.log("Clusters.setAmiCombo     plugins.cloud.Clusters.setAmiCombo()");

	var amis = this.getItemsArray();	
	console.log("Clusters.setAmiCombo     amis: " + dojo.toJson(amis));
	
	// SET STORE
	var data = {identifier: "name", items: []};
	for ( var i = 0; i < amis.length; i++ )
	{
		data.items[i] = { name: amis[i]	};
	}
	console.log("Clusters.setAmiCombo     data: " + dojo.toJson(data));
	var store = new dojo.data.ItemFileWriteStore({	data: data	});

	// SET COMBO
	this.amiid.store = store;
	this.amiid.startup();
	console.log("Clusters.setAmiCombo     AFTER this.amiid.startup()");

	// SET COMBO VALUE
	var firstValue = amis[0];
	this.amiid.setValue(firstValue);
	console.log("Clusters.setAmiCombo     AFTER this.amiid.setValue(firstValue)");
},
getItemArray : function () {
// GET A LIST OF DATA ITEMS - ONE FOR EACH ROW
	return Agua.getClusters();
},
setDragSource : function () {
// SET THE DRAG SOURCE WITH PARAMETER OBJECTS
	console.log("Clusters.setDragSource     plugins.cloud.Clusters.setDragSource()");

	// GENERATE DND GROUP
	if ( this.dragSource == null ) {
		this.initialiseDragSource();
		this.setDragSourceCreator();
	}

	// DELETE EXISTING CONTENT
	this.clearDragSource();

	// INITIALISE USER INFO
	var itemArray = this.getItemArray();
	//console.log("Clusters.setDragSource     itemArray: " + dojo.toJson(itemArray));

	// REMOVE USERNAME FROM BEGINNING OF CLUSTER NAME
	var regex = Agua.cookie('username') + "-";
	for ( var i = 0; i < itemArray.length; i++ )
	{
		itemArray[i].cluster = itemArray[i].cluster.replace(regex, '');
	}

	itemArray = this.sortHasharray(itemArray, 'cluster');
	//console.log("Clusters.setDragSource    itemArray: " + dojo.toJson(itemArray));
	
	// CHECK IF itemArray IS NULL
	if ( itemArray == null )
	{
		//console.log("Clusters.setDragSource     itemArray is null or empty. Returning.");
		return;
	}

	this.loadDragItems(itemArray);
},
newCluster : function (inputs, reload) {
//	SAVE A PARAMETER TO Agua.parameters AND TO REMOTE DATABASE
	////console.log("Clusters.newCluster    plugins.cloud.Clusters.newCluster(inputs, reload)");
	//////console.log("Clusters.newCluster    inputs: " + dojo.toJson(inputs));
	//////console.log("Clusters.newCluster    reload: ");
	//////console.dir(reload);
	
	if ( this.saving == true )	return;
	this.saving = true;

	if ( inputs == null )
	{
		inputs = this.getFormInputs(this);
		////console.log("Clusters.newCluster    inputs: ");
		////console.dir(inputs);
		
		// RETURN IF INPUTS ARE NULL OR INVALID
		
		if ( inputs == null )
		{
			this.saving = false;
			return;
		}
	}
	inputs.cluster = Agua.getClusterLongName(inputs.cluster);
	//////console.log("Clusters.newCluster    inputs: " + dojo.toJson(inputs));
	Agua.newCluster(inputs);
	
	this.saving = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateClusters", reload);

}, // Clusters.newCluster
saveInputs : function (inputs, reload) {
//	SAVE A PARAMETER TO Agua.parameters AND TO REMOTE DATABASE
	////console.log("Clusters.saveInputs    plugins.cloud.Clusters.saveInputs(inputs, reload)");
	//////console.log("Clusters.saveInputs    inputs: " + dojo.toJson(inputs));
	//////console.log("Clusters.saveInputs    reload: ");
	//////console.dir(reload);
	
	if ( this.saving == true )	return;
	this.saving = true;

	if ( inputs == null )
	{
		inputs = this.getFormInputs(this);
		////console.log("Clusters.saveInputs    inputs: ");
		////console.dir(inputs);
		
		// RETURN IF INPUTS ARE NULL OR INVALID
		
		if ( inputs == null )
		{
			this.saving = false;
			return;
		}
	}
	inputs.cluster = Agua.getClusterLongName(inputs.cluster);
	//////console.log("Clusters.saveInputs    inputs: " + dojo.toJson(inputs));
	Agua.addCluster(inputs);
	
	this.saving = false;

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateClusters", reload);

}, // Clusters.saveInputs
deleteItem : function (clusterObject) {
	////console.log("Clusters.deleteItem    plugins.cloud.Clusters.deleteItem(name)");
	////console.log("Clusters.deleteItem    clusterObject: " + dojo.toJson(clusterObject));

	// REMOVING PARAMETER FROM Agua.parameters
	clusterObject.cluster = Agua.cookie('username') + "-" + clusterObject.cluster;
	
	Agua.removeCluster(clusterObject);
	
	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateClusters", {originator: this, reload: false});

	// RELOAD RELEVANT DISPLAYS
	Agua.updater.update("updateAmis", {originator: this, reload: false});

}, // Clusters.deleteItem
checkEnter : function (event) {
	////console.log("Cluster.checkEnter    event.keyCode: " + event.keyCode);

	if (event.keyCode == dojo.keys.ENTER)
	{
		this.saveInputs();
		dojo.stopEvent(event);
	}
},
checkEnterNodes : function (event) {
	////console.log("Clusters.checkEnterNodes    event.keyCode: " + event.keyCode);

	if (event.keyCode == dojo.keys.ENTER)
	{
		dojo.stopEvent(event);

		////console.log("Clusters.checkEnterNodes    setting document.body.focus()");
		document.body.focus();

		this.checkNodeNumbers();

		this.saveInputs();
	}
},
checkNodeNumbers : function () {
// SET MIN NODES VALUE TO SENSIBLE NUMBER 
	////console.log("Clusters.checkNodeNumbers     plugins.cloud.Clusters.checkNodeNumbers()");
	//////console.log("Clusters.checkNodeNumbers     this.minnodes.get('value'): " + this.minnodes.get('value'));
	//////console.log("Clusters.checkNodeNumbers     this.maxnodes.get('value'): " + this.maxnodes.get('value'));
	
	if (this.minnodes.value > this.maxnodes.value )
	{
		////console.log("Clusters.checkNodeNumbers     this.minnodes.value > this.maxnodes.value");
		this.minnodes.set('value', this.maxnodes.value);
	}
}

}); // plugins.cloud.Clusters

