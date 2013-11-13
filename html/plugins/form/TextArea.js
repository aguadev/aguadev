define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-style",
	"dojo/dom-class",
	"plugins/core/Common/Util",
	"dijit/Tooltip",
	"dojo/ready",
	"dojo/domReady!",

	"dijit/_Widget",
	"dijit/_Templated",
	"dijit/form/SimpleTextarea"
	],
//////}}}}}}

function (declare, arrayUtil, JSON, on, lang, domStyle, domClass, CommonUtil, Tooltip, ready) {

//////}}}}}}

return declare("plugins.form.TextArea",
	[ dijit._Widget, dijit._Templated, CommonUtil ], {
//////}}}}}}
	
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/form/templates/textarea.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

_earlyTemplatedStartup: true,

noStart : false,
 
// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("dijit/themes/dijit.css"),
	require.toUrl("dijit/themes/soria/soria.css"),
	require.toUrl("dijit/themes/tundra/tundra.css"),
	require.toUrl("plugins/form/css/textarea.css")
],

// pattern: String
// 		Regex pattern used to validate input
pattern : ".*",

// cols: String
// 		Default number of columns
cols: 50,

// rows: String
// 		Default number of rows
rows: 50,

// disabled : Boolean
//		Disable input and grey out box if true
disabled : false,

// tooltipPosition: String[]
//		See description of `dijit/Tooltip.defaultPosition` for details on this parameter.
tooltipPosition: [],

/////}}}}}

constructor : function(args) {

//////}}}}}}

	dojo.mixin(this, args);
	
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	this.inherited(arguments);
	
	// SET PARAMETERS, E.G.:
	// value="admin"
	// pattern="[a-z]{5,20}"
	// invalidMessage="Lowercase letters (5-20)"
	// promptMessage="Lowercase letters (5-20)"
	// required="false"
	
	this.mixinArgs();

	// SET VALIDATION
	this.setValidation();
	
	// SET PROMPT
	this.setPrompt();

	// SET COLUMN HEIGHTS
	this.setColumnHeights();
},
setDisabled : function () {
	console.log("TextArea.setDisabled    this.disabled: " + this.disabled);
	if ( this.disabled ) {
		console.log("TextArea.setDisabled    DOING domClass.add(this.input, 'disabled')");
		domClass.add(this.input, "disabled");
	}
},
setColumnHeights : function () {

//////}}}}}}

	//console.log("TextArea.setColumnHeights    this.input.domNode: " + this.input.domNode);
	//console.dir({this_input_domNode:this.input.domNode});
	//console.log("TextArea.setColumnHeights    this.input: " + this.input);
	//console.dir({this_input:this.input});
	
	// SET LISTENER - IF TEXTAREA HEIGHT IS CHANGED,
	// ADJUST LABEL HEIGHT ACCORDINGLY
	var thisObject = this;
	on(this.input.textbox, "mouseup", function () {
		//console.log("TextArea.setColumnHeights    this.input.texbox FIRED");
		thisObject.autoResizeLabel();
	});

	// WAIT UNTIL TEXTAREA WIDGET HEIGHT IS AVAILABLE IN DOM,
	// THEN ADJUST INITIAL LABEL HEIGHT ACCORDINGLY
	var thisObject = this;
	ready( function () {
		thisObject.autoResizeLabel();	
	});
},
autoResizeLabel : function () {	
	var height = this.input.domNode.offsetHeight + "px";
	//console.log("TextArea.autoResizeLabel    height XXX: " + height);
	
	domStyle.set(this.labelElement, "height", height);	
},	
mixinArgs : function () {
//////}}}}}}

	var parameters = [
		"rows",
		"cols",
		"pattern",
		"maxlength",
		"value",
		"invalidMessage",
		"promptMessage",
		"required"
	];
	for ( var i in parameters ) {
		var parameter = parameters[i];
		this.input[parameter] = this[parameter];
		//console.log("TextArea.mixinArgs   this.input[" + parameter + "]: " + this.input[parameter]);	
	}	
},
setPrompt : function () {
	var thisObject = this;
	this.input.on("click", function () {
		var contentLength = thisObject.getContentLength();
		if ( ! contentLength ) {
			thisObject.displayMessage(thisObject.invalidPrompt);
		}
	});
},
setValidation : function () {

	var thisObject = this;
	this.input.on("blur", function () {
		// UPDATE LETTER COUNT
		thisObject.updateLetterCount();
		
		// CHECK VALIDITY
		var valid = thisObject.isValid();
		//console.log("TextArea.setValidation    ON.blur FIRED    valid: " + valid);

		if ( ! valid ) {
			//console.log("TextArea.setValidation    ON.blur FIRED    thisObject.setInvalid();");
			thisObject.setInvalid();
			thisObject.displayMessage(thisObject.invalidMessage);
		}
		else {
			//console.log("TextArea.setValidation    ON.blur FIRED    thisObject.setValid();");
			thisObject.setValid();
			thisObject.hideMessage();
		}
	})
},
setInvalid : function () {
	domClass.add(this.input.focusNode, "invalid");
},
setValid : function () {
	domClass.remove(this.input.focusNode, "invalid");	
},
isValid : function () {
	var content = this.getValue() || "";
	//console.log("TextArea.isValid    content: " + content);
	//console.log("TextArea.isValid    this.pattern: " + this.pattern);
	var regex = new RegExp(this.pattern);
	if ( ! content.match(regex) ) {
		//console.log("TextArea.isValid    MATCH. Returning 0");
		this.setInvalid();
		return 0;
	}
	
	this.setValid();
	//console.log("TextArea.isValid    Returning 1");
	return 1;	
},
getValue : function () {
	return this.input.value;
},
setValue : function (value) {
	//console.log("plugins.form.TextArea.setValue    value: " + value);
	//console.log("plugins.form.TextArea.setValue    this.input: " + this.input);
	//console.dir({this_input:this.input});
	
	this.input.value = value;
	this.input.textbox.value = value;
},
getContentLength : function () {
	var content = this.getValue();
	if ( ! content )	return 0;
	
	return content.length;
},
updateLetterCount : function () {
	var count = this.getContentLength();
	
	this.letterCount.innerHTML = count;
},
displayMessage: function(/*String*/ message){
	// summary:
	//		Overridable method to display validation errors/hints.
	//		By default uses a tooltip.
	// tags:
	//		extension
	if (message && this.focused) {
		Tooltip.show(message, this.input.focusNode, this.tooltipPosition, !this.isLeftToRight());
	}
	else {
		Tooltip.hide(this.input.focusNode);
	}
},
hideMessage: function(){
	Tooltip.hide(this.input.focusNode);
}


}); 	//	end declare

});	//	end define
