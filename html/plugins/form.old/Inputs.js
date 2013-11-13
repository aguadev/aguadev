dojo.provide("plugins.form.Inputs");

// PROVIDES FORM INPUT AND ROW EDITING WITH VALIDATION
// INHERITING CLASSES MUST IMPLEMENT saveInputs AND deleteItem METHODS
// THE dnd DRAG SOURCE MUST BE this.dragSourceWidget IF PRESENT

/* USE CASE 1: USER CREATES NEW PARAMETER USING 'New Param' BUTTON
  
  saveInputs

	-->	getFormInputs (return: inputs)

		--> processWidgetValue

			--> getWidgetValue

				--> setWidgetValue

	--> checkInputs (set: this.allValid, return inputs,
					return null if this.allValid == false )
		
		--> isValidInput (return true|false: non-empty if required & not invalid)
		
	--> addItem
	
*/
  
// INTERNAL MODULES
dojo.require("plugins.core.Common");

dojo.declare("plugins.form.Inputs",
	[ plugins.core.Common ], {

// FORM INPUT-S AND TYPES (word|phrase)
formInputs : {},

// DEFAULT INPUTS (e.g., name : "Name" )
defaultInputs : {},

// REQUIRED INPUTS CANNOT BE ''
requiredInputs : {},

// INVALID INPUTS (e.g., DEFAULT INPUTS:	name : "Name")
invalidInputs : {},

////}}}

constructor : function(args) {
	////console.log("Inputs.constructor     plugins.form.Inputs.constructor");	
},
postCreate : function() {
	////console.log("Inputs.postCreate    ");
	this.startup();
},
startup : function () {
	////console.log("Inputs.startup    plugins.form.Inputs.startup()");
},
setClearValues : function () {	
// SET ONCLICK TO CANCEL INVALID TEXT

////console.log("Inputs.setClearValues    this:");
//console.dir({this: this});

	for ( var name in this.invalidInputs )
	{
		dojo.connect(this[name], "onclick", dojo.hitch(this, "clearValue", this[name], this.invalidInputs[name]));
		dojo.connect(this[name], "onfocus", dojo.hitch(this, "clearValue", this[name], this.invalidInputs[name]));
	}
},
chainInputs : function (inputs) {
// CHAIN TOGETHER INPUTS ON 'RETURN' KEYPRESS
	////////console.log("Inputs.chainInputs    form.EditForm.chainInputs(inputs)");
	////////console.log("Inputs.chainInputs    inputs: " + dojo.toJson(inputs));
	for ( var i = 0; i < inputs.length - 1; i++ ) {
		var name = inputs[i];
		var nextName = inputs[i+1];
	////////console.log("Inputs.chainInputs    Doing dojo.connect for name " + i + ": " + name + " and " + nextName);
		this.chainOnkey(name, nextName);
	}
},
chainOnkey : function (current, next) {
// SHIFT FOCUS TO NEXT INPUT ON KEYPRESS
	////////console.log("Inputs.chainOnkey    form.EditForm.chainOnkey(current, next)");
	////////console.log("Inputs.chainOnkey    current: " + current);
	////////console.log("Inputs.chainOnkey    next: " + next);
	
	var thisObject = this;
	dojo.connect(this[current], "onkeypress", this, function(event){
		if ( event.keyCode == 13 )
		{				
			////////console.log("Inputs.chainOnkey    current " + current + " to next " + next);
			thisObject[next].focus();
			setTimeout(function() {
				thisObject[current].scrollTop = 0;
			}, 50);
		}
	});
},
saveInputs : function (inputs, updateArgs) {
	////console.log("Inputs.saveInputs    plugins.form.Inputs.saveInputs(inputs, updateArgs)");
	////console.log("Inputs.saveInputs    inputs: " + dojo.toJson(inputs));
	////console.log("Inputs.saveInputs    updateArgs: ");
	//console.dir(updateArgs);
	
	if ( this.saving == true )	return;
	this.saving = true;
	
	var formAdd = false;
	if ( inputs == null )
	{
		formAdd = true;
		inputs = this.getFormInputs(this);
		////console.log("Inputs.saveInputs    AFTER this.getFormInputs(this)    inputs: ");
		//console.dir(inputs);
		
		// RETURN IF INPUTS ARE NULL OR INVALID
		
		if ( inputs == null )
		{
			this.saving = false;
			return;
		}
	}

	var itemObject = new Object;
	itemObject.username = Agua.cookie('username');	
	itemObject.sessionid = Agua.cookie('sessionid');	
	for ( var input in inputs )
	{
		itemObject[input] = inputs[input];
	}
	this.saving = false;

	this.addItem(itemObject, formAdd);
},
getFormInputs : function (widget) {
// GET INPUTS FROM THE EDITED ITEM
	////console.log("Inputs.getFormInputs    plugins.form.Inputs.getFormInputs(widget)");
	////console.log("Inputs.getFormInputs    widget: " + widget);
	//console.dir({parameterRow: widget});

	var inputs = new Object;
	for ( var name in this.formInputs )
	{
		inputs[name] = this.processWidgetValue(widget, name);	
		inputs[name] = this.convertBackslash(inputs[name], "expand");
		inputs[name] = this.convertAngleBrackets(inputs[name], "htmlToText");
		inputs[name] = this.convertAmpersand(inputs[name], "htmlToText");
	}
	////console.log("Inputs.getFormInputs    inputs: " + dojo.toJson(inputs));
	inputs = this.checkInputs(widget, inputs);

	return inputs;
},
processWidgetValue : function (widget, name) {
	console.log("Inputs.processWidgetValue    (widget: " + widget + ", name: " + name + ")");
	console.dir({widget:widget});
	var value = this.getWidgetValue(widget[name]);
	console.log("Inputs.processWidgetValue    (name: " + name + ", value: " + value + ")");
	if ( value == null )	return value;
	if ( value.replace == null )	return value;
	
	if ( value == null )	return null;
	if ( widget.formInputs[name] == "word" )
		value = this.cleanWord(value);
	else if ( widget.formInputs[name] == "phrase" )
		value = this.cleanEnds(value);
	if ( value != null )	this.setWidgetValue(widget[name], value);
	console.log("Inputs.processWidgetValue    widget: " + widget + ", name: " + name + ". Returning value: " + value);

	return value;
},
getWidgetValue : function (widget) {
	var value;
	////////console.log("Inputs.getWidgetValue    (widget: " + widget);
	////////console.log("Inputs.getWidgetValue    widget: ");
	//////console.dir({widget:widget});
	if ( ! widget )	return;
	
	// NUMBER TEXT BOX
	if ( widget.id != null && widget.id.match(/^dijit_form_NumberTextBox/) )
	{
		////////console.log("Inputs.getWidgetValue    DOING NumberTextBox widget");
		value = String(widget);
		//value = String(widget.getValue());
	}
	// WIDGET COMBO BOX
	else if ( widget.get && widget.get('value') )
	{
		////////console.log("Inputs.getWidgetValue    DOING widget.get('value')");
		value = widget.get('value');
	}
	else if ( widget.getValue )
	{
		value = widget.getValue();
	}
	// HTML TEXT INPUT OR HTML COMBO BOX
	else if ( widget.value )
	{
		////////console.log("Inputs.getWidgetValue    DOING widget.value");
		value = String(widget.value.toString());
	}
	// HTML DIV	
	else if ( widget.innerHTML )
	{
	    ////////console.log("Inputs.getWidgetValue    DOING widget.innerHTML");

	    // CHECKBOX
		if ( widget.innerHTML == "<input type=\"checkbox\">" )
	    {
			////////console.log("Inputs.getWidgetValue    CHECKBOX - GETTING VALUE");
			value = widget.childNodes[0].checked;
			////////console.log("Inputs.getWidgetValue    value: " + value);
	    }
		else {
			value = widget.innerHTML;
		}
	}
	////////console.log("Inputs.getWidgetValue    XXXX value: " + dojo.toJson(value));
	if ( value == null )    value = '';
	return value;
},
setWidgetValue : function (widget, value) {
	////////console.log("Inputs.setWidgetValue    form.EditForm.setWidgetValue(widget, name, value)");
	////////console.log("Inputs.setWidgetValue    widget: " + widget);
	////////console.log("Inputs.setWidgetValue    value: " + value);
		
	//////////console.log("Clusters.getEditedInputs    NumberTextBox widget[" + name + "].value name: " + name);
	// NUMBER TEXT BOX
	if ( widget.id != null && widget.id.match(/^dijit_form_NumberTextBox/) )
	{
		////////console.log("Clusters.setEditedInputs    NumberTextBox widget.setValue(value)");
		widget.set('value', value);
	}
	// WIDGET COMBO BOX
	else if ( widget.set )
	{
		////////console.log("Inputs.setWidgetValue    widget.set('value', value)");
		widget.set('value', value);
	}
	// LEGACY: ALL NON-get/set WIDGETS
	else if ( widget.setValue )
	{
		////////console.log("Inputs.setWidgetValue    widget.set('value', value)");
		widget.setValue(value);
	}
	// HTML TEXT INPUT OR HTML COMBO BOX
	else if ( widget.value )
	{
		////////console.log("Inputs.setWidgetValue    widget.value");
		widget.value = value;
	}
	// HTML DIV	
	else if ( widget.innerHTML )
	{
		////////console.log("Inputs.setWidgetValue    widget.innerHTML name: " + name);
		widget.innerHTML = value;
	}
},
clearValue : function (widget, value) {
	////console.log("Inputs.clearValue    plugins.form.Inputs.clearValue(widget, value)");
	////console.log("Inputs.clearValue    widget: " + widget);
	////console.log("Inputs.clearValue    value: " + value);
	if ( widget == null )	return;

	if ( this.getWidgetValue(widget) == value )
		this.setWidgetValue(widget, '')
},
checkInputs : function (widget, inputs) {
// CHECK INPUTS ARE VALID, IF NOT RETURN NULL
	console.log("Inputs.checkInputs    plugins.form.Inputs.checkInputs(inputs)");
	console.log("Inputs.checkInputs    inputs: " + dojo.toJson(inputs));
	
	this.allValid = true;	
	for ( var key in this.formInputs )
	{
		var value = inputs[key];
		console.log("Inputs.checkInputs    Checking " + key + ": " + value);
		
		if ( this.isValidInput(key, value) )
		{
			console.log("Inputs.checkInputs    removing 'invalid' class for " + key + ": " + value);
			this.setValid(widget[key]);
		}
		else{
			console.log("Inputs.checkInputs    adding 'invalid' class for name " + key + ", value " + value);
			
			this.setInvalid(widget[key]);
			this.allValid = false;
		}
	}
	console.log("Inputs.checkInputs    this.allValid: " + this.allValid);
	if ( this.allValid == false )	return null;

	for ( var key in this.formInputs )
	{
		console.log("Inputs.checkInputs    BEFORE convert, inputs[key]: " + dojo.toJson(inputs[key]));
		inputs[key] = this.convertAngleBrackets(inputs[key], "htmlToText");
		//inputs[key] = this.convertBackslash(inputs[key], "textToHtml");
		console.log("Inputs.checkInputs    AFTER convert, inputs[key]: " + dojo.toJson(inputs[key]));
	}

	return inputs;
},
setValid : function (widget) {
	this.removeClass(widget, 'invalid');
},
setInvalid : function (widget) {
	this.addClass(widget, 'invalid');
},
removeClass : function (widget, className) {
	if ( widget.id != null && widget.id.match(/^dijit_form_/) )
	{
		//////console.log("Inputs.removeClass    removing class from domNode.firstChild: " + className);
		
		dojo.removeClass(widget.domNode, className);
	}
	else if ( widget.domNode )
	{
		//////console.log("Inputs.removeClass    removing class from domNode: " + className);
		
		dojo.removeClass(widget.domNode, className);
	}
	else	{
		//////console.log("Inputs.removeClass    removing class for widget: " + className);
		
		dojo.removeClass(widget, className);
	}
},
addClass : function (widget, className) {
	if ( widget.id != null && widget.id.match(/^dijit_form_/) )
	{
		//////console.log("Inputs.addClass    adding class to domNode.firstChild : " + className);
		
		dojo.addClass(widget.domNode, className);
	}
	else if ( widget.domNode )
	{
		//////console.log("Inputs.addClass    adding class to domNode: " + className);
		
		dojo.addClass(widget.domNode, className);
	}
	else	{
		//////console.log("Inputs.addClass    adding class: " + className);
		
		dojo.addClass(widget, className);
	}
},
isValidInput : function (name, value) {
	//////////console.log(">>>> EditForm.isValidInput    plugins.form.Inputs.isValidInput(name, value)");
	//////console.log("Inputs.isValidInput    name: " + name);
	//////console.log("Inputs.isValidInput    value: " + value);
	//////console.log("Inputs.isValidInput    this.invalidInputs[name]: " + this.invalidInputs[name]);
	//////console.log("Inputs.isValidInput    this.requiredInputs[name]: " + this.requiredInputs[name]);

	////console.log("Inputs.isValidInput    '" + name + "' value: " + value +" [ invalid: " + name + "]: '" + this.invalidInputs[name] + "', required: " + this.requiredInputs[name] + " ]");
	
	//////console.log("Inputs.isValidInput    this.invalidInputs[name]: " + this.invalidInputs[name]);
	//////console.log("Inputs.isValidInput    this.requiredInputs[name]: " + this.requiredInputs[name]);

	if ( this.invalidInputs[name] == null )	return true;
	else if ( this.requiredInputs[name] == null )	return true;
	else if ( value == null )	return false;
	else if ( value == '' )	return false;
	else if ( this.invalidInputs[name] == value ) return false;

	////console.log("Inputs.isValidInput    Returning true");
	return true;
}


}); // plugins.form.Inputs

