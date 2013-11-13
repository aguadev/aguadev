dojo.provide("plugins.cloud.UserRow");


dojo.declare( "plugins.cloud.UserRow",
	[ dijit._Widget, dijit._Templated ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "cloud/templates/userrow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.cloud.Users WIDGET
parentWidget : null,

////}}}

constructor : function(args) {
	//////console.log("UserRow.constructor    plugins.workflow.UserRow.constructor()");
	this.parentWidget = args.parentWidget;
},

postCreate : function() {
	////////console.log("UserRow.postCreate    plugins.workflow.UserRow.postCreate()");
	this.formInputs = this.parentWidget.formInputs;
	this.startup();
},

startup : function () {
	//////console.log("UserRow.startup    plugins.workflow.UserRow.startup()");
	//////console.log("UserRow.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);
	
	var thisObject = this;

	dojo.connect( this.username, "onclick", function(event) {
		thisObject.toggle();
		event.stopPropagation(); //Stop Event Bubbling 			
	});

	// FIRSTNAME
	var thisObject = this;
	dojo.connect(this.firstname, "onclick", function(event)
		{
			//console.log("UserRow.startup    userRow.firstname clicked");
			thisObject.parentWidget.editRow(thisObject, event.target);
			event.stopPropagation(); //Stop Event Bubbling 			
		}
	);

	// LASTNAME
	dojo.connect(this.lastname, "onclick", function(event)
		{
			thisObject.parentWidget.editRow(thisObject, event.target);
			event.stopPropagation(); //Stop Event Bubbling 			
		}
	);

	// EMAIL
	dojo.connect(this.email, "onclick", function(event)
		{
			//////console.log("UserRow.startup    userRow.email clicked");

			thisObject.parentWidget.editRow(thisObject, event.target);
			event.stopPropagation(); //Stop Event Bubbling 			
		}
	);

	// PASSWORD
	dojo.connect(this.password, "onclick", function(event)
		{
			//console.log("UserRow.startup    userRow.password clicked");

			thisObject.clearValue(event.target);
			thisObject.parentWidget.editRow(thisObject, event.target);
			event.stopPropagation(); //Stop Event Bubbling 			
		}
	);
},

toggle : function () {
	//////console.log("UserRow.toggle    plugins.workflow.UserRow.toggle()");

	if ( this.firstname.style.display == 'block' ) this.firstname.style.display='none';
	else this.firstname.style.display = 'block';
	if ( this.lastname.style.display == 'block' ) this.lastname.style.display='none';
	else this.lastname.style.display = 'block';
	if ( this.email.style.display == 'block' ) this.email.style.display='none';
	else this.email.style.display = 'block';
	if ( this.password.style.display == 'block' ) this.password.style.display='none';
	else this.password.style.display = 'block';
},

clearValue : function (element) {
	//console.log("UserRow.clearValue    plugins.cloud.UserRow.clearValue(element)");
	//console.log("UserRow.clearValue    element.value: " + element.value);

	if ( element.clicked == true ) return;
	
	element.clicked = true;
	element.innerHTML = '';
	element.focus();
}


});
