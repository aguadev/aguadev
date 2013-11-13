dojo.provide("plugins.sharing.GroupRow");


dojo.declare( "plugins.sharing.GroupRow",
	[ dijit._Widget, dijit._Templated ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/grouprow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.sharing.Groups WIDGET
parentWidget : null,

////}}}}

constructor : function(args) {
	//////console.log("GroupRow.constructor    plugins.workflow.GroupRow.constructor()");
	this.parentWidget = args.parentWidget;
},


postCreate : function() {
	////////console.log("GroupRow.postCreate    plugins.workflow.GroupRow.postCreate()");
	this.formInputs = this.parentWidget.formInputs;
	this.startup();
},

startup : function () {
	//////console.log("GroupRow.startup    plugins.workflow.GroupRow.startup()");
	//////console.log("GroupRow.startup    this.parentWidget: " + this.parentWidget);
	this.inherited(arguments);
	
	var thisObject = this;
	dojo.connect( this.groupname, "onclick", function(event) {
		thisObject.toggle();
		event.stopPropagation(); //Stop Event Bubbling 			
	});

	// DESCRIPTION
	dojo.connect(this.description, "onclick", function(event)
		{
			//////console.log("GroupRow.startup    groupRow.description clicked");
			thisObject.parentWidget.editRow(thisObject, event.target);
		}
	);

	// NOTES
	dojo.connect(this.notes, "onclick", function(event)
		{
			//////console.log("GroupRow.startup    groupRow.notes clicked");
			thisObject.parentWidget.editRow(thisObject, event.target);
		}
	);
},

toggle : function () {
	//////console.log("GroupRow.toggle    plugins.workflow.GroupRow.toggle()");
	if ( this.description.style.display == 'block' ) this.description.style.display='none';
	else this.description.style.display = 'block';
	if ( this.notes.style.display == 'block' ) this.notes.style.display='none';
	else this.notes.style.display = 'block';
}

});
	
