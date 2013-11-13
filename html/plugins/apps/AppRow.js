dojo.provide("plugins.apps.AppRow");

dojo.declare( "plugins.apps.AppRow",
	[ dijit._Widget, dijit._Templated ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "apps/templates/approw.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.apps.Apps WIDGET
parentWidget : null,

/////}}}

constructor : function(args) {
	////console.log("AppRow.constructor    plugins.workflow.AppRow.constructor()");
	////console.log("AppRow.constructor    args.submit: " + args.submit);
	this.checkboxOn = args.submit;
	this.parentWidget = args.parentWidget;
	this.formInputs = this.parentWidget.formInputs;
},


postCreate : function() {
	////////console.log("AppRow.postCreate    plugins.workflow.AppRow.postCreate()");

	this.startup();
},

startup : function () {
	//////console.log("AppRow.startup    plugins.workflow.AppRow.startup()");
	//////console.log("AppRow.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);
	
	// CONNECT TOGGLE EVENT
	var thisObject = this;
	dojo.connect( this.name, "onclick", function(event) {
		thisObject.toggle();
	});

	// ADD 'EDIT' ONCLICKS
	var thisObject = this;
	var array = [ "executor", "location", "description", "notes", "url" ];
	for ( var i in array )
	{
		dojo.connect(this[array[i]], "onclick", function(event)
			{
				//////console.log("AppRow.startup    " + array[i] + " clicked");
				thisObject.parentWidget.editRow(thisObject, event.target);
				event.stopPropagation(); //Stop Event Bubbling
			}
		);
	}
	
	// USE this.checkboxOn TO DECIDE IF CHECKBOX IS SELECTED
	////console.log("AppRow.startup    this.checkboxOn: " + this.checkboxOn);
	if ( this.checkboxOn != null && this.checkboxOn == 1 )
	{
		////console.log("AppRow.startup    this.checkboxOn = " + this.checkboxOn + ". Setting this.submit to On");
		this.localonly.setValue("on");
	}
},

submitChange : function (event) {
// REGISTER CHECKBOX CHANGE
	//console.log("AppRow.submitChange    plugins.apps.AppRow.submitChange(event)");		
	//console.log("AppRow.submitChange    event: " + event);		

	event.stopPropagation(); //Stop Event Bubbling
	//console.log("AppRow.submitChange    Doing inputs = this.parentWidget.getFormInputs(this)");		

	// GET INPUTS
	var inputs = this.parentWidget.getFormInputs(this);
	if ( inputs == null ) return;
	this.parentWidget.saveInputs(inputs, {reload: false});
},

// TOGGLE HIDDEN DETAILS	
toggle : function () {
	////console.log("AppRow.toggle    plugins.workflow.AppRow.toggle()");
	//////console.log("AppRow.toggle    this.description: " + this.description);

	var array = [ "executor", "packageCombo", "location", "localonlyContainer", "description", "notes", "url" ];
	for ( var i in array )
	{
		console.log("AppRow.toggle    this[" + array[i] + "]: " + this[array[i]]);

		if ( this[array[i]].style.display == 'inline-block' )	
			this[array[i]].style.display='none';
		else
			this[array[i]].style.display = 'inline-block';
	}
}

});
	
