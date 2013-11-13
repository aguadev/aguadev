dojo.provide("plugins.sharing.SourceRow");

dojo.declare( "plugins.sharing.SourceRow",
	[ dijit._Widget, dijit._Templated ],
{
		
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/sourcerow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.sharing.Sources WIDGET
parentWidget : null,

////}}}

constructor : function(args) {
	//////console.log("SourceRow.constructor    plugins.workflow.SourceRow.constructor()");
	this.parentWidget = args.parentWidget;
	//this.inherited(arguments);
},

postCreate : function() {
	////////console.log("SourceRow.postCreate    plugins.workflow.SourceRow.postCreate()");
	this.formInputs = this.parentWidget.formInputs;
	this.startup();
},

startup : function () {
	//////console.log("SourceRow.startup    plugins.workflow.SourceRow.startup()");
	//////console.log("SourceRow.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);
	
	//dojo.connect( this.name, "onclick", this.toggle);
	var thisObject = this;
	dojo.connect( this.name, "onclick", function(event) {
		thisObject.toggle();
		event.stopPropagation(); //Stop Event Bubbling 			
	});

	// ADD 'EDIT' ONCLICK
	dojo.connect(this.description, "onclick", function(event)
		{
			//////console.log("SourceRow.startup    sourceRow.description clicked");
			thisObject.parentWidget.editRow(thisObject, event.target);
			event.stopPropagation(); //Stop Event Bubbling 			
		}
	);

	// ADD 'EDIT' ONCLICK
	dojo.connect(this.location, "onclick", function(event)
		{
			//////console.log("SourceRow.startup    sourceRow.location clicked");
			thisObject.parentWidget.editRow(thisObject, event.target);
			event.stopPropagation(); //Stop Event Bubbling 			
		}
	);
},

toggle : function () {
	//////console.log("SourceRow.toggle    plugins.workflow.SourceRow.toggle()");

	if ( this.description.style.display == 'block' ) this.description.style.display='none';
	else this.description.style.display = 'block';
	if ( this.location.style.display == 'block' ) this.location.style.display='none';
	else this.location.style.display = 'block';
}

});
