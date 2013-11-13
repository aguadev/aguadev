define([
	"dojo/_base/declare",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dojo/domReady!"
],

function (declare, _Widget, _TemplatedMixin) {

return declare("plugins.workflow.Apps.AppRow",
	[ _Widget, _TemplatedMixin ], {
	
// Template of this widget. 
templateString: dojo.cache("plugins", "workflow/Apps/templates/approw.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.workflow.Apps WIDGET
parentWidget : null,

// CORE WORKFLOW OBJECTS
core : null,


// APPLICATION OBJECT
application : null,

constructor : function(args) {
	//console.log("AppRow.constructor    plugins.workflow.AppRow.constructor()");
	//console.log("AppRow.constructor    args.localonly: " + args.localonly);
	//console.log("AppRow.constructor    args: ");
	//console.dir({args:args});
	
	this.core = args.core;
	this.parentWidget = args.parentWidget;

	this.application = new Object;
	for ( var key in args )
	{
		if ( key != "parentWidget" ) {
			////console.log("AppRow.constructor    Setting this.application[" + key + "] = " + args[key]);
			this.application[key] = args[key];
		}
	}
	////console.log("AppRow.constructor    this.application: " + dojo.toJson(this.application));
	
	//this.inherited(arguments);
},

// RETURN A COPY OF this.application
getApplication : function ()
{
	return dojo.clone(this.application);
},

// SET this.application TO THE SUPPLIED APPLICATION OBJECT
setApplication : function (application) {
	this.application = application;

	return this.application;
},
postCreate : function() {
	//////console.log("AppRow.postCreate    plugins.workflow.AppRow.postCreate()");

	this.startup();
},
startup : function () {
	////console.log("AppRow.startup    plugins.workflow.AppRow.startup()");
	////console.log("AppRow.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);
	
	
	// HACK:
	//
	// SET parentWidget TO this.name FOR RETRIEVAL OF this.application
	// WHEN MENU IS CLICKED
	//
	// REM: remove ONCLICK BUBBLES ON appRow.name NODE RATHER THAN ON node. 
	// I.E., CONTRARY TO DESIRED, this.name IS THE TARGET INSTEAD OF THE node.
	//
	// ALSO ADDED node.parentWidget = appRow IN Workflows.updateDropTarget()

	this.name.parentWidget = this;
	////console.log("AppRow.startup    this.name.parentWidget: " + this.name.parentWidget);
	
	// CONNECT TOGGLE EVENT
	var appRowObject = this;
	dojo.connect( this.name, "onclick", function(event) {
		event.stopPropagation();
		appRowObject.toggle();
	});

},
toggle : function () {
	////console.log("AppRow.toggle    plugins.workflow.AppRow.toggle()");
	////console.log("AppRow.toggle    this.description: " + this.description);

	var array = [ "description", "location", "notes", "version", "executor", "localonly" ];
	for ( var i in array )
	{
		if( this[array[i]].style )
		{
			if ( this[array[i]].style.display == 'table-cell' ) this[array[i]].style.display='none';
			else this[array[i]].style.display = 'table-cell';
		}
	}
}

	
	}); 	//	end declare
	
	});	//	end define
