dojo.provide("plugins.cloud.AmiRow");

dojo.require("dojo.data.ItemFileWriteStore");

dojo.declare( "plugins.cloud.AmiRow",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "cloud/templates/amirow.html"),

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
	////console.log("AmiRow.postCreate    plugins.workflow.AmiRow.postCreate()");
	this.formInputs = this.parentWidget.formInputs;
	////console.log("AmiRow.postCreate    this.formInputs: " + dojo.toJson(this.formInputs));

	this.startup();
},

startup : function () {
	//console.log("AmiRow.startup    plugins.workflow.AmiRow.startup()");
	////console.log("AmiRow.startup    this.parentWidget: " + this.parentWidget);
	this.inherited(arguments);

	// SET AVAILABILITY ZONE COMBO
	var fakeEvent = {
		target: {
			selectedIndex: 0,
			options : [ {text: "us-east-1"} ]
		}
	};

	// SET LISTENER FOR CHANGES TO AMI NAME
	this.setOnkeyListeners(["aminame"]);

	setTimeout(function(thisObj) {
		////console.log("AmiRow.startup    Doing setTimeout(thisObj.setComboListeners");
		thisObj.setComboListeners();
	}, 2000, this);
},

setOnkeyListeners : function (names) {

	var thisObject = this;
	for ( var i in names )
	{
		dojo.connect(thisObject[names[i]], "onKeyPress", function(evt){
			var key = evt.keyCode;
			evt.stopPropagation();
			//console.log("AmiRow.setOnkeyListeners    key: " + key);	
			if ( key == 13 )	thisObject.saveInputs();
		});
	}
},


setComboListeners : function () {
	////console.log("AmiRow.setComboListeners    AmiRow.setComboListeners()");
	var thisObject = this;
	dojo.connect(this.amitype, "onchange", function(event)
		{
			////console.log("AmiRow.setComboListeners    onchange fired: " + onchangeArray[i]);
			//console.log("AmiRow.setComboListeners    onchange    event: " + event);
			if ( event.stopPropagation == null )	return;
			var inputs = thisObject.parentWidget.getFormInputs(thisObject);
			thisObject.parentWidget.saveInputs(inputs, {reload: false});
			event.stopPropagation(); //Stop Event Bubbling
		}
	);
},

saveInputs : function () {
	////console.log("AmiRow.saveInputs    plugins.workflow.AmiRow.saveInputs()");
	////console.log("AmiRow.saveInputs    this.parentWidget: " + this.parentWidget);
	
	var inputs = this.parentWidget.getFormInputs(this);
	//console.log("AmiRow.saveInputs    inputs: " + dojo.toJson(inputs));

	this.parentWidget.saveInputs(inputs, {reload: false});
},

editCluster : function (event) {
	//console.log("AmiRow.editCluster    plugins.workflow.AmiRow.editCluster()");
	//console.log("AmiRow.editCluster    this.parentWidget: " + this.parentWidget);

	this.parentWidget.editRow(this, event.target);
	event.stopPropagation(); //Stop Event Bubbling
},

toggle : function () {
// TOGGLE HIDDEN NODES
	console.log("AmiRow.toggle    plugins.workflow.AmiRow.toggle()");
	console.log("AmiRow.toggle    this.description: " + this.description);

	var array = [ "description" ];
	for ( var i in array )
	{
		console.log("AmiRow.toggle    toggling: " + array[i]);
		if ( this[array[i]].style.display == 'table-cell' )
			this[array[i]].style.display='none';
		else
			this[array[i]].style.display = 'table-cell';
	}
}


});
