dojo.provide("plugins.cloud.ClusterRow");

dojo.require("dojo.data.ItemFileWriteStore");

dojo.declare( "plugins.cloud.ClusterRow",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "cloud/templates/clusterrow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.cloud.Apps WIDGET
parentWidget : null,

////}}}

constructor : function(args) {
	this.parentWidget = args.parentWidget;
	this.lockedValue = args.locked;
	this.args = args;
},
postCreate : function() {
	//console.log("ClusterRow.postCreate    plugins.workflow.ClusterRow.postCreate()");
	this.formInputs = this.parentWidget.formInputs;
	//console.log("ClusterRow.postCreate    this.formInputs: " + dojo.toJson(this.formInputs));

	this.startup();
},
startup : function () {
	//console.log("ClusterRow.startup    plugins.workflow.ClusterRow.startup()");
	//console.log("ClusterRow.startup    this: " + this);
	this.inherited(arguments);

	// SET AVAILABILITY ZONE COMBO
	var fakeEvent = {
		target: {
			selectedIndex: 0,
			options : [ {text: "us-east-1"} ]
		}
	};
	this.setAvailzoneCombo(fakeEvent);
	if ( this.args.availzone != null )
		this.availzone.set('value', this.args.availzone);		

	// SET AMI COMBO BOX
	this.setAmiCombo(this.args.amiid);
	this.setAmiInfo();

	// SET LISTENER FOR CHANGES TO amiid
	this.setOnkeyListeners(["amiid"]);

	setTimeout(function(thisObj) {
		//console.log("ClusterRow.startup   *******  Doing setTimeout(thisObj.setComboListeners *******");
		thisObj.setComboListeners();
	}, 2000, this);
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateClusters");

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateAmis");
},
updateClusters : function (args) {
// RELOAD THE COMBO AND DRAG SOURCE AFTER CHANGES
// TO DATA IN OTHER TABS
	console.log("ClusterRow.updateClusters(args)");
	console.log("ClusterRow.updateClusters    args: " );
	console.dir(args);
	
	// SET DRAG SOURCE
	if ( args == null || args.reload != false )
	{
		//////console.log("Cluster.updateClusters    Calling setDragSource()");
	} 
},
updateAmis : function (args) {
// RELOAD THE COMBO AND DRAG SOURCE AFTER CHANGES
// TO DATA IN OTHER TABS
	//console.log("ClusterRow.updateAmis(args)");
	//console.log("ClusterRow.updateAmis    args: " );
	//console.dir(args);
	
	if ( args.originator == this )
	{
		if ( args.reload == false )	return;
	}

	//console.log("ClusterRow.updateAmis    Doing this.setAmiCombo()");

	// SET AMI COMBO BOX
	this.setAmiCombo();
},
setComboListeners : function () {
	//console.log("ClusterRow.setComboListeners    ClusterRow.setComboListeners()");
	var thisObject = this;
	dojo.connect(this.instancetype, "onchange", function(event)
		{
			//console.log("ClusterRow.setComboListeners    onchange fired: " + onchangeArray[i]);
			//console.log("ClusterRow.setComboListeners    onchange    event: " + event);
			if ( event.stopPropagation == null )	return;
			var inputs = thisObject.parentWidget.getFormInputs(thisObject);
			thisObject.parentWidget.saveInputs(inputs, {reload: false});
			event.stopPropagation(); //Stop Event Bubbling
		}
	);

	dojo.connect(this.availzone, "onChange", function(availzone)
		{
			//console.log("ClusterRow.setComboListeners    onChange    availzone: " + availzone);
			var inputs = thisObject.parentWidget.getFormInputs(thisObject);
			thisObject.parentWidget.saveInputs(inputs, {reload: false});
		}
	);
	
	
	dojo.connect(this.amiid, "onChange", function()
		{
			//console.log("ClusterRow.setComboListeners    onChange    this.amiid: " + this.amiid);
			var inputs = thisObject.parentWidget.getFormInputs(thisObject);
			thisObject.parentWidget.saveInputs(inputs, {reload: false});
		}
	);
	
	
},
setOnkeyListeners : function (names) {

	var thisObject = this;
	for ( var i in names )
	{
		dojo.connect(thisObject[names[i]], "onKeyPress", function(evt){
			var key = evt.keyCode;
			evt.stopPropagation();
			//console.log("ClusterRow.setOnkeyListeners    key: " + key);	
			if ( key == 13 )	thisObject.saveInputs();
		});
	}
},
getItemsArray : function () {
	var amis = Agua.getAmis();	
	//console.log("ClusterRow.setAmiCombo     amis: " + dojo.toJson(amis));
	return this.hashArrayKeyToArray(amis, ["amiid"]); 	
},
setAmiCombo : function (amiid) {
	//console.log("ClusterRow.setAmiCombo     plugins.cloud.Clusters.setAmiCombo(amiid)");

	var amis = this.getItemsArray();	
	//console.log("ClusterRow.setAmiCombo     amis: " + dojo.toJson(amis));
	
	// SET STORE
	var data = {identifier: "name", items: []};
	for ( var i = 0; i < amis.length; i++ )
	{
		data.items[i] = { name: amis[i]	};
	}
	//console.log("ClusterRow.setAmiCombo     data: " + dojo.toJson(data));
	var store = new dojo.data.ItemFileWriteStore({	data: data	});

	// SET COMBO
	this.amiid.store = store;
	this.amiid.startup();
	//console.log("ClusterRow.setAmiCombo     AFTER this.amiid.startup()");

	// SET COMBO VALUE
	var firstValue = amiid;
	if ( firstValue == null )
		firstValue = amis[0];
	this.amiid.setValue(firstValue);
	//console.log("ClusterRow.setAmiCombo     AFTER this.amiid.setValue(firstValue)");

	this.setAmiInfo();
},
setAmiInfo : function () {
	//console.log("ClusterRow.setAmiInfo     plugins.cloud.Clusters.setAmiInfo()");
	//console.log("ClusterRow.setAmiInfo     //console.dir(this)");
	;

	var amiid = this.amiid.get('value');
	//console.log("ClusterRow.setAmiInfo     amiid: " + amiid);

	var amiObject = Agua.getAmiObjectById(amiid);
	//console.log("ClusterRow.setAmiInfo     amiObject: " + dojo.toJson(amiObject));
	if ( amiObject == null ) {
		this.aminame.innerHTML = "";
		this.amitype.innerHTML = "";
	}
	else
	{
		this.aminame.innerHTML = amiObject.aminame;
		this.amitype.innerHTML = amiObject.amitype;
	}

},
setAvailzoneCombo : function (event) {
	//console.log("ClusterRow.setAvailzoneCombo     plugins.cloud.ClustersRow.setAvailzoneCombo(event)");
	//console.log("ClusterRow.setAvailzoneCombo     this: " + this);
	//console.log("ClusterRow.setAvailzoneCombo     event.target: " + event.target);
	var region = this.getSelectedValue(event.target);
	//console.log("ClusterRow.setAvailzoneCombo     region: " + region);
	var availzones = Agua.getAvailzonesByRegion(region);	
	//console.log("ClusterRow.setAvailzoneCombo     availzones: " + dojo.toJson(availzones));
	
	// SET STORE
	var data = {identifier: "name", items: []};
	for ( var i = 0; i < availzones.length; i++ )
	{
		data.items[i] = { name: availzones[i]	};
	}
	//console.log("ClusterRow.setAvailzoneCombo     data: " + dojo.toJson(data));
	var store = new dojo.data.ItemFileWriteStore(	{	data: data	}	);

	// SET COMBO
	this.availzone.store = store;
	this.availzone.startup();

	// SET COMBO VALUE
	var firstValue = availzones[0];
	this.availzone.set('value', firstValue);
},
saveInputs : function () {
	//console.log("ClusterRow.saveInputs    XXXXXXXXXX plugins.workflow.ClusterRow.saveInputs()");
	//console.log("ClusterRow.saveInputs    this.saveInputs.caller.nom: " + this.saveInputs.caller.nom);
	//console.log("ClusterRow.saveInputs    this.parentWidget: " + this.parentWidget);
	
	this.setAmiInfo();
	
	this.checkNodeNumbers();
	//console.log("ClusterRow.saveInputs    AFTER checkNodeNumbers");

	var inputs = this.parentWidget.getFormInputs(this);
	//console.log("ClusterRow.saveInputs    inputs: " + dojo.toJson(inputs));

	this.parentWidget.saveInputs(inputs, {reload: false});
},
checkNodeNumbers : function() {
	//console.log("ClusterRow.checkNodeNumbers    plugins.workflow.ClusterRow.checkNodeNumbers()");
	//console.log("ClusterRow.checkNodeNumbers     this.minnodes.get('value'): " + this.minnodes.get('value'));
	//console.log("ClusterRow.checkNodeNumbers     this.maxnodes.get('value'): " + this.maxnodes.get('value'));
	
	if (this.minnodes.get('value') > this.maxnodes.get('value') )
	{
		//console.log("ClusterRow.checkNodeNumbers     this.minnodes.value > this.maxnodes.value");
		this.minnodes.set('value', this.maxnodes.get('value'));
	}
},
editCluster : function (event) {
	//console.log("ClusterRow.editCluster    plugins.workflow.ClusterRow.editCluster()");
	//console.log("ClusterRow.editCluster    this.parentWidget: " + this.parentWidget);

	this.parentWidget.editRow(this, event.target);
	event.stopPropagation(); //Stop Event Bubbling
},
checkEnterNodes : function (event) {
	//console.log("ClusterRow.checkEnterNodes    event.keyCode: " + event.keyCode);

	if (event.keyCode == dojo.keys.ENTER)
	{
		dojo.stopEvent(event);
		//console.log("ClusterRow.checkEnterNodes    setting document.body.focus()");
		document.body.focus();

		this.checkNodeNumbers();

		var inputs = this.parentWidget.getFormInputs(this);
		this.saveInputs(inputs, null);

		//console.log("ClusterRow.checkEnterNodes    Doing dojo.stopEvent(event)");
	}
},
toggle : function () {
// TOGGLE HIDDEN NODES
	//console.log("ClusterRow.toggle    plugins.workflow.ClusterRow.toggle()");
	//console.log("ClusterRow.toggle    this.description: " + this.description);

	var array = [ "aminame", "amitype", "instancetypeContainer", "amiidContainer", "regionContainer", "availzoneContainer", "description" ];
	for ( var i in array )
	{
		//console.log("ClusterRow.toggle    toggling: " + array[i]);
		if ( this[array[i]].style.display == 'table-cell' )
			this[array[i]].style.display='none';
		else
			this[array[i]].style.display = 'table-cell';
	}
}


});
