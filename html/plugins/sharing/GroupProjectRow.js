dojo.provide("plugins.sharing.GroupProjectRow");


dojo.declare( "plugins.sharing.GroupProjectRow",
	[ dijit._Widget, dijit._Templated ],
{
	//Path to the template of this widget. 
	templatePath: dojo.moduleUrl("plugins", "sharing/templates/groupprojectrow.html"),

	// Calls dijit._Templated.widgetsInTemplate
	widgetsInTemplate : true,
	
	// PARENT plugins.sharing.Sources WIDGET
	parentWidget : null,
	
	constructor : function(args)
	{
		////////console.log("GroupProjectRow.constructor    plugins.workflow.GroupProjectRow.constructor()");

		this.parentWidget = args.parentWidget;
		//this.inherited(arguments);
	},

	postCreate : function()
	{
		////////console.log("GroupProjectRow.postCreate    plugins.workflow.GroupProjectRow.postCreate()");

		this.startup();
	},
	
	startup : function ()
	{
		//////console.log("GroupProjectRow.startup    plugins.workflow.GroupProjectRow.startup()");
		//////console.log("GroupProjectRow.startup    this.parentWidget: " + this.parentWidget);
		//////console.log("GroupProjectRow.startup    this.name: " + this.name);

		this.inherited(arguments);
		
		var groupProjectRowObject = this;
		dojo.connect( this.name, "onclick", function(event) {
			
			//////console.log("GroupProjectRow.startup    fired onclick");
			groupProjectRowObject.toggle();
			event.stopPropagation(); //Stop Event Bubbling 			
		});

		//// ADD 'EDIT' ONCLICK
		//var groupProjectRowObject = this;
		//dojo.connect(this.description, "onclick", function(event)
		//	{
		//		////////console.log("GroupProjectRow.startup    groupProjectRow.description clicked");
		//
		//		groupProjectRowObject.parentWidget.editGroupProjectRow(groupProjectRowObject, event.target);
		//		event.stopPropagation(); //Stop Event Bubbling 			
		//	}
		//);
		//
		//// ADD 'EDIT' ONCLICK
		//var groupProjectRowObject = this;
		//dojo.connect(this.location, "onclick", function(event)
		//	{
		//		////////console.log("GroupProjectRow.startup    groupProjectRow.location clicked");
		//
		//		groupProjectRowObject.parentWidget.editGroupProjectRow(groupProjectRowObject, event.target);
		//		event.stopPropagation(); //Stop Event Bubbling 			
		//	}
		//);
	},
	
	toggle : function ()
	{
		////////console.log("GroupProjectRow.toggle    plugins.workflow.GroupProjectRow.toggle()");

		if ( this.description.style.display == 'block' ) this.description.style.display='none';
		else this.description.style.display = 'block';
	}
});
	