dojo.provide("plugins.sharing.ProjectRow");


dojo.declare( "plugins.sharing.ProjectRow",
	[ dijit._Widget, dijit._Templated ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/projectrow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.sharing.Projects WIDGET
parentWidget : null,

////}}}

constructor : function(args) {
	//////console.log("ProjectRow.constructor    plugins.workflow.ProjectRow.constructor()");
	this.parentWidget = args.parentWidget;	
},


postCreate : function() {
	////////console.log("ProjectRow.postCreate    plugins.workflow.ProjectRow.postCreate()");
	this.formInputs = this.parentWidget.formInputs;
	this.startup();
},

startup : function () {
	//////console.log("ProjectRow.startup    plugins.workflow.ProjectRow.startup()");
	//////console.log("ProjectRow.startup    this.parentWidget: " + this.parentWidget);
	this.inherited(arguments);
	
	var thisObject = this;
	dojo.connect( this.name, "onclick", function(event) {
		thisObject.toggle();
		event.stopPropagation(); //Stop Event Bubbling 			
	});

	// DESCRIPTION
	dojo.connect(this.description, "onclick", function(event)
		{
			//////console.log("ProjectRow.startup    projectRow.description clicked");
			thisObject.parentWidget.editRow(thisObject, event.target);
		}
	);

	// NOTES
	dojo.connect(this.notes, "onclick", function(event)
		{
			//////console.log("ProjectRow.startup    projectRow.notes clicked");
			thisObject.parentWidget.editRow(thisObject, event.target);
		}
	);
},

toggle : function () {
	//////console.log("ProjectRow.toggle    plugins.workflow.ProjectRow.toggle()");
	if ( this.description.style.display == 'block' ) this.description.style.display='none';
	else this.description.style.display = 'block';
	if ( this.notes.style.display == 'block' ) this.notes.style.display='none';
	else this.notes.style.display = 'block';
}

});
	
