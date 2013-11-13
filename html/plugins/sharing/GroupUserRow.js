dojo.provide("plugins.sharing.GroupUserRow");


dojo.declare( "plugins.sharing.GroupUserRow",
	[ dijit._Widget, dijit._Templated ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/groupuserrow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.sharing.Sources WIDGET
parentWidget : null,

////}}}

constructor : function(args) {
	////////console.log("GroupUserRow.constructor    plugins.workflow.GroupUserRow.constructor()");
	this.parentWidget = args.parentWidget;
},

postCreate : function() {
	this.startup();
},

startup : function () {
	////////console.log("GroupUserRow.startup    plugins.workflow.GroupUserRow.startup()");
	this.inherited(arguments);
	
	var groupUserRowObject = this;
	dojo.connect( this.username, "onclick", function(event) {
		groupUserRowObject.toggle();
		event.stopPropagation(); //Stop Event Bubbling 			
	});
},

toggle : function () {
	////////console.log("GroupUserRow.toggle    plugins.workflow.GroupUserRow.toggle()");

	if ( this.email.style.display == 'block' ) this.email.style.display='none';
	else this.email.style.display = 'block';
	if ( this.fullname.style.display == 'block' ) this.fullname.style.display='none';
	else this.fullname.style.display = 'block';
	if ( this.description.style.display == 'block' ) this.description.style.display='none';
	else this.description.style.display = 'block';
}
});
	
