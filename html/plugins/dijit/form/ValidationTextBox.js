dojo.provide("plugins.dijit.form.ValidationTextBox");

dojo.require("dijit.form.ValidationTextBox");

dojo.declare("plugins.dijit.form.ValidationTextBox",
	[ dijit.form.ValidationTextBox ], {

validate: function(/*Boolean*/ isFocused){
	// summary:
	//		Called by oninit, onblur, and onkeypress.
	// description:
	//		Show missing or invalid messages if appropriate, and highlight textbox field.
	// tags:
	//		protected

	//console.log("plugins.dijit.form.ValidationTextBox.validate plugins.dijit.form.ValidationTextBox.validate(isFocused)");
	//console.log("plugins.dijit.form.ValidationTextBox.validate    this.target: " + this.target);
	// SKIP VALIDATE WHEN LOADING WIDGET
	if ( this.parentWidget == null )	return;

	// IF this IS THE newPassword WIDGET, RUN VALIDATE ON
	// ITS TARGET: THE confirmPassword WIDGET
	if ( this.target != null ) {
		var isValid = this.target.validate(isFocused);
		console.log("plugins.dijit.form.ValidationTextBox.validate    TARGET isValid: " + isValid);

		if ( ! isValid)
			this.state = "Error";
		else
			this.state = "Incomplete";
	
		this._setStateClass();
	}
	var message = "";
	var isValid = this.parentWidget.passwordsMatch();
	//console.log("plugins.dijit.form.ValidationTextBox.validate    isValid: " + isValid);

	if(isValid){ this._maskValidSubsetError = true; }
	var isEmpty = this._isEmpty(this.textbox.value);
	var isValidSubset = !isValid && !isEmpty && isFocused && this._isValidSubset();
	this.state = ((isValid || ((!this._hasBeenBlurred || isFocused) && isEmpty) || isValidSubset) && this._maskValidSubsetError) ? "" : "Error";
	
	if ( ! isValid)
		this.state = "Error";
	else
		this.state = "Incomplete";

	if(this.state == "Error"){ this._maskValidSubsetError = isFocused; } // we want the error to show up afer a blur and refocus

	this._setStateClass();

//return isValid;
	
	//console.log("plugins.dijit.form.ValidationTextBox.validate    DOING dijit.setWaiState(this.focusNode, " + this.focusNode, "invalid", isValid ? "false" : "true" + ")");

	dijit.setWaiState(this.focusNode, "invalid", isValid ? "false" : "true");
	if(isFocused){
		if(this.state == "Error"){
			message = this.getErrorMessage(true);
		}else{
			message = this.getPromptMessage(true); // show the prompt whever there's no error
		}
		this._maskValidSubsetError = true; // since we're focused, always mask warnings
	}
	this.displayMessage(message);

	// IF SOURCE EXISTS, SET SOURCE STATE
	if ( this.source ) {
		if ( ! isValid)
			this.source.state = "Error";
		else
			this.source.state = "Incomplete";
	
		this.source._setStateClass();
	}
	
	return isValid;
}	

}); // plugins.dijit.form.ValidationTextBox

