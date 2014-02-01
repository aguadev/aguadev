//dojo.provide("plugins.sharing.GroupProjectRow");
//
//
//dojo.declare( "plugins.sharing.GroupProjectRow",
//	[ dijit._Widget, dijit._Templated ],
//{

define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"dojo/domReady!",

	"dijit/layout/ContentPane",
	"dijit/form/Button",
	"dijit/form/ComboBox",
	"dijit/Tooltip",
	"dijit/form/Slider",
	"dojo/parser"
],

function (declare,
	arrayUtil,
	JSON,
	on,
	lang,
	domAttr,
	domClass,
	_Widget,
	_TemplatedMixin,
	Common
) {

/////}}}}}

return declare("plugins/sharing/GroupProjectRow",
	[ _Widget, _TemplatedMixin, Common ], {

// templateString : String	
//		Path to the template of this widget. 
templateString: dojo.cache("plugins", "sharing/templates/groupprojectrow.html"),
	
// PARENT plugins.sharing.Sources WIDGET
parentWidget : null,

constructor : function(args)
{
	////////console.log("GroupProjectRow.constructor    plugins.workflow.GroupProjectRow.constructor()");

	lang.mixin(this, args);
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


}); //	end declare

});	//	end define

	