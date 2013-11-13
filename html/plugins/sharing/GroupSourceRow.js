dojo.provide("plugins.sharing.GroupSourceRow");


dojo.declare( "plugins.sharing.GroupSourceRow",
	[ dijit._Widget, dijit._Templated ],
{
	//Path to the template of this widget. 
	templatePath: dojo.moduleUrl("plugins", "sharing/templates/groupsourcerow.html"),

	// Calls dijit._Templated.widgetsInTemplate
	widgetsInTemplate : true,
	
	// PARENT plugins.sharing.Sources WIDGET
	parentWidget : null,
	
	constructor : function(args)
	{
		console.log("GroupSourceRow.constructor    args:");
		console.dir({args:args});	
		
		this.parentWidget = args.parentWidget;
		//this.inherited(arguments);
	},

	postCreate : function()
	{
		////////console.log("GroupSourceRow.postCreate    plugins.workflow.GroupSourceRow.postCreate()");

		this.startup();
	},
	
	startup : function ()
	{
		////////console.log("GroupSourceRow.startup    plugins.workflow.GroupSourceRow.startup()");
		////////console.log("GroupSourceRow.startup    this.parentWidget: " + this.parentWidget);

		this.inherited(arguments);
		
		var groupSourceRowObject = this;
		dojo.connect( this.name, "onclick", function(event) {
			groupSourceRowObject.toggle();
			event.stopPropagation(); //Stop Event Bubbling 			
		});

		//// ADD 'EDIT' ONCLICK
		//var groupSourceRowObject = this;
		//dojo.connect(this.description, "onclick", function(event)
		//	{
		//		////////console.log("GroupSourceRow.startup    groupSourceRow.description clicked");
		//
		//		groupSourceRowObject.parentWidget.editGroupSourceRow(groupSourceRowObject, event.target);
		//		event.stopPropagation(); //Stop Event Bubbling 			
		//	}
		//);
		//
		//// ADD 'EDIT' ONCLICK
		//var groupSourceRowObject = this;
		//dojo.connect(this.location, "onclick", function(event)
		//	{
		//		////////console.log("GroupSourceRow.startup    groupSourceRow.location clicked");
		//
		//		groupSourceRowObject.parentWidget.editGroupSourceRow(groupSourceRowObject, event.target);
		//		event.stopPropagation(); //Stop Event Bubbling 			
		//	}
		//);
	},
	
	toggle : function ()
	{
		////////console.log("GroupSourceRow.toggle    plugins.workflow.GroupSourceRow.toggle()");

		//if ( this.location.style.display == 'block' ) this.location.style.display='none';
		//else this.location.style.display = 'block';
		if ( this.description.style.display == 'block' ) this.description.style.display='none';
		else this.description.style.display = 'block';
	}
});
	
