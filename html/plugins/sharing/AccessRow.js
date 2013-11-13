////dojo.provide("plugins.sharing.AccessRow");
////
////
////dojo.declare( "plugins.sharing.AccessRow",
////	[ dijit._Widget, dijit._Templated ],
////{
////
define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/_Widget",
	"dijit/_Templated",
	"dojo/domReady!"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, _Widget, _Templated) {

return declare("plugins.sharing.AccessRow", [_Widget, _Templated], {

	////////}
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/sharing/templates/accessrow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.sharing.Apps WIDGET
parentWidget : null,

// INSTANTIATION ARGUMENTS
args : null,

constructor : function(args) {
	this.args = args;
	////console.log("AccessRow.constructor    args: " + dojo.toJson(args));
},

postCreate : function() {
	////console.log("AccessRow.postCreate    plugins.workflow.AccessRow.postCreate()");
	this.rights = this.parentWidget.rights;
	this.startup();
},

startup : function () {
	//console.log("AccessRow.startup    plugins.workflow.AccessRow.startup()");
	//console.log("AccessRow.startup    this.groupname: " + this.groupname);
	this.inherited(arguments);

	for ( var index in this.rights )
	{
		var right = this.rights[index];

		//console.log("AccessRow.startup    right: " + right);
		if ( this.args[right] == 1 )
			dojo.addClass(this[right], 'allowed');
		else
			dojo.addClass(this[right], 'denied');
	}
	////console.log("AccessRow.startup    this: " + this);
},

toggle : function (event) {
// TOGGLE HIDDEN NODES
	////console.log("sharing.AccessRow.toggle    event.target: " + event.target);
	var value = dojo.attr(event.target, 'value');
	event.stopPropagation();	
	////console.log("sharing.AccessRow.toggle    value: " + value);

	var ownership = "group";
	if ( value.match(/^world/) )	ownership = "world";
	////console.log("sharing.AccessRow.toggle    ownership: " + ownership);

	var permission;
	if ( value.match(/^group/) ) permission = value.replace(/^group/, '');
	if ( value.match(/^world/) ) permission = value.replace(/^world/, '');
	////console.log("sharing.AccessRow.toggle    permission: " + permission);

	var setClass = "allowed";
	var unsetClass = "denied";
	if ( dojo.hasClass(this[value], "allowed") )
	{
		setClass = "denied";
		unsetClass = "allowed";
	}

	this.descendingOwnership(ownership, permission, setClass, unsetClass);
		
	if ( ownership == "world" && setClass == "allowed" )
	{
		var deniedOk = false;
		this.descendingOwnership("group", permission, setClass, unsetClass, deniedOk);
	}
},

descendingOwnership : function (ownership, permission, setClass, unsetClass, deniedOk) {
	if ( deniedOk == null )	deniedOk = true;
	////console.log("access.AccessRow.descendingOwnership    access.AccessRow.descendingOwnership(ownership, permission, setClass, unsetClass)");
	////console.log("access.AccessRow.descendingOwnership    ownership: " + ownership);
	////console.log("access.AccessRow.descendingOwnership    permission: " + permission);
	////console.log("access.AccessRow.descendingOwnership    setClass: " + setClass);
	////console.log("access.AccessRow.descendingOwnership    unsetClass: " + unsetClass);
	////console.log("access.AccessRow.descendingOwnership    deniedOk: " + deniedOk);

	if ( permission == "write" )
	{
		this.setClasses(ownership, "write", setClass, unsetClass);
		this.setClasses(ownership, "copy", setClass, unsetClass);	
		this.setClasses(ownership, "view", setClass, unsetClass);
	}

	if ( permission == "copy" )
	{
		this.setClasses(ownership, "view", setClass, unsetClass);
		this.setClasses(ownership, "copy", setClass, unsetClass);
		if ( setClass == "denied" )	
			this.setClasses(ownership, "write", setClass, unsetClass);
		else if ( deniedOk == true )
			this.setClasses(ownership, "write", unsetClass, setClass);
	}

	if ( permission == "view" )
	{
		this.setClasses(ownership, "view", setClass, unsetClass);
		if ( setClass == "denied" && deniedOk == true )	
		{
			this.setClasses(ownership, "write", setClass, unsetClass);	
			this.setClasses(ownership, "copy", setClass, unsetClass);	
		}
		else if ( deniedOk == true )
		{
			this.setClasses(ownership, "write", unsetClass, setClass);	
			this.setClasses(ownership, "copy", unsetClass, setClass);	
		}
	}
},

setClasses : function (ownership, permission, setClass, unsetClass) {
////console.log("sharing.AccessRow.setClasses    ownership: " + ownership + ", permission: " + permission + ", setClass: " + setClass);

	dojo.addClass(this[ownership + permission ], setClass);
	dojo.removeClass(this[ownership + permission], unsetClass);
}




}); 	//	end declare

});	//	end define


