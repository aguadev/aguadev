define([
	"dojo/_base/declare",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"dojo/domReady!"
],

function (declare,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplateMixin
) {

/////}}}}}

return declare("plugins.apps.Packages",
	[ _Widget, _TemplatedMixin, _WidgetsInTemplateMixin ], {

// templateString : String	
//		Path to the template of this widget. 
templateString: dojo.cache("plugins", "apps/templates/packagerow.html"),

// PARENT plugins.apps.Packages WIDGET
parentWidget : null,

/////}}}

constructor : function(args) {
	////console.log("PackageRow.constructor    plugins.workflow.PackageRow.constructor()");
	////console.log("PackageRow.constructor    args.submit: " + args.submit);
	this.parentWidget = args.parentWidget;
	this.formInputs = this.parentWidget.formInputs;
},

postCreate : function() {
	this.startup();
},

startup : function () {
	console.log("PackageRow.startup    this: " + this);

	this.inherited(arguments);
	
	// CONNECT TOGGLE EVENT
	this.setToggle();

	// ADD 'EDIT' ONCLICKS
	this.setEdit();
},

setToggle : function () {
// CONNECT TOGGLE EVENT
	var thisObject = this;
	var array = [ "package", "version" ];
	for ( var i in array )
	{
		dojo.connect(this[array[i]], "onclick", function(event) {
		//dojo.connect( this.package, "onclick", function(event) {
			thisObject.toggle();
		});
	}	
},

setEdit : function () {
// ADD 'EDIT' ONCLICKS
	var thisObject = this;
	var array = [ "opsdir", "description", "notes", "website" ];
	for ( var i in array )
	{
		dojo.connect(this[array[i]], "onclick", function(event)
			{
				//console.log("PackageRow.startup    onclick fired. event.target: " + event.target);
				thisObject.parentWidget.editRow(thisObject, event.target);
				event.stopPropagation(); //Stop Event Bubbling
			}
		);
	}
},

// TOGGLE HIDDEN DETAILS	
toggle : function () {
	////console.log("PackageRow.toggle    plugins.workflow.PackageRow.toggle()");
	//////console.log("PackageRow.toggle    this.description: " + this.description);
	var array = [ "opsdir", "installdir", "description", "notes", "website" ];
	for ( var i in array )
	{
		//console.log("PackageRow.toggle    this[" + array[i] + "] :" + this[array[i]]);
		if ( this[array[i]].style.display == 'inline-block' )	
			this[array[i]].style.display='none';
		else
			this[array[i]].style.display = 'inline-block';
	}
}

}); //	end declare

});	//	end define

	
