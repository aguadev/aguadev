define([
	"dojo/_base/declare",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common/Util",
	"dojo/domReady!",
	"dijit/layout/TabContainer",
	"dijit/form/Select"
],

function (declare, on, lang, domAttr, domClass, _Widget, _TemplatedMixin, _WidgetsInTemplate, commonUtil) {

/////}}}}}

return declare("plugins.apps.ParameterRow",
	[_Widget, _TemplatedMixin, _WidgetsInTemplate, commonUtil], {

//Path to the template of this widget. 
templatePath: dojo.cache("plugins", "apps/templates/parameterrow.html"),

// parentWidget	:	Widget object
// 		Widget that has this parameter row
parentWidget : null,

// formInputs : Hash
//		Hash of form inputs against input types (word|phrase)
formInputs : {
// FORM INPUTS AND TYPES (word|phrase)
	locked : "",
	name: "word",
	argument: "word",
	type: "word",
	category: "word",
	value: "word",
	discretion: "word",
	description: "phrase",
	format: "word",
	args: "word",
	inputParams: "phrase",
	paramFunction: "phrase"
},

// cssFiles : Array
//		Array of CSS files to be loaded for all widgets in template
// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/apps/css/parameters.css"),
	require.toUrl("dojo/tests/dnd/dndDefault.css"),
	require.toUrl("dijit/themes/claro/document.css"),
	require.toUrl("dijit/tests/css/dijitTests.css")
],
/////}}}}}
constructor : function(args) {
	//console.log("ParameterRow.constructor    args: ");
	//console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
	
	this.lockedValue = args.locked;

	//console.log("ParameterRow.constructor    END");
},
postCreate : function(args) {
	//console.log("ParameterRow.postCreate    plugins.workflow.ParameterRow.postCreate(args)");
	//this.formInputs = this.parentWidget.formInputs;

	this.startup();
},
startup : function () {
	//console.log("ParameterRow.startup    plugins.workflow.ParameterRow.startup()");
	this.inherited(arguments);
	
	//console.log("ParameterRow.startup    AFTER this.inherited(arguments)");

	// CONNECT TOGGLE EVENT
	var thisObject = this;
	on( this.name, "click", function(event) {
		thisObject.toggle();
	});

	// SET LISTENER TO LEVEL ROW HEIGHTS
	this.setRowHeightListeners();
	
	// LEVEL ROW HEIGHT
	//this.levelRowHeight(this);
	//this.levelRowHeight(this);
	//this.toggleNode(this.args);
	//this.toggleNode(this.inputParams);
	
	//console.log("ParameterRow.startup    this.lockedValue: " + this.lockedValue);
	// SET LOCKED CLASS
	if ( this.lockedValue == 1 )	{
		domClass.remove(this.locked,'unlocked');
		domClass.add(this.locked,'locked');
	}
	else	{
		domClass.remove(this.locked,'locked');
		domClass.add(this.locked,'unlocked');
	}
	
	// ADD 'ONCLICK' EDIT VALUE LISTENERS
	var thisObject = this;
	var onclickArray = [ "argument", "category", "value", "description", "format", "args", "inputParams", "paramFunction" ];
	for ( var i in onclickArray )
	{
		on(this[onclickArray[i]], "click", function(event)
			{
				//console.log("ParameterRow.startup    onclick listener fired: " + onclickArray[i]);
				if ( ! thisObject.parentWidget ) {
					return;
				}
				thisObject.parentWidget.editRow(thisObject, event.target);
				event.stopPropagation(); //Stop Event Bubbling
			}
		);
	}
	
	// ADD 'ONCHANGE' COMBO BOX LISTENERS
	var thisObject = this;
	var onchangeArray = [ "valuetype", "ordinal", "discretion", "paramtype" ];
	for ( var i in onchangeArray ) {
		on(this[onchangeArray[i]], "change", function(event) {
				console.log("ParameterRow.startup    onchange listener fired: " + onchangeArray[i]);
				if ( ! thisObject.parentWidget ) {
					return;
				}
				var inputs = thisObject.parentWidget.getFormInputs(thisObject);
				thisObject.parentWidget.saveInputs(inputs, {originator: thisObject.parentWidget, reload: false});
				event.stopPropagation(); //Stop Event Bubbling
			}
		);
	}	
},
setRowHeightListeners : function () {

	var thisObject = this;
	on(this.args, 'change', dojo.hitch(function (event) {
		////console.log("ParameterRow.setRowHeightListeners    args    this: " + this);
		////console.log("ParameterRow.setRowHeightListeners    args    thisObject: " + thisObject);
		////console.log("ParameterRow.setRowHeightListeners    args.onchange");
		//thisObject.levelRowHeight(thisObject);
		setTimeout(function(thisObj){ thisObj.levelRowHeight(thisObj)}, 100, thisObject);
		event.stopPropagation();
	}));
	on(this.inputParams, 'change', dojo.hitch(function (event) {
		////console.log("ParameterRow.setRowHeightListeners    inputParams    this: " + this);
		////console.log("ParameterRow.setRowHeightListeners    inputParams    thisObject: " + thisObject);
		////console.log("ParameterRow.setRowHeightListeners    inputParams.onchange");
		setTimeout(function(thisObj){ thisObj.levelRowHeight(thisObj)}, 100, thisObject);
		event.stopPropagation();
	}));
	
},
levelRowHeight : function (paramRow) {
	//console.log("XXXX ParameterRow.levelRowHeight    plugins.workflow.ParameterRow.levelRowHeight()");
	//console.log("ParameterRow.levelRowHeight    BEFORE paramRow.args.clientHeight: " + paramRow.args.clientHeight);
	//console.log("ParameterRow.levelRowHeight    BEFORE this.inputParams.clientHeight: " + paramRow.inputParams.clientHeight);
	//console.log("ParameterRow.levelRowHeight    BEFORE paramRow.args.offsetHeight: " + paramRow.args.offsetHeight);
	//console.log("ParameterRow.levelRowHeight    BEFORE this.inputParams.offsetHeight: " + paramRow.inputParams.offsetHeight);

	// VIEW CURRENT STYLES
	//console.log("paramRow.args.style : " + domAttr.get(paramRow.args, 'style'));
	//console.log("paramRow.inputParams.style : " + domAttr.get(paramRow.inputParams, 'style'));

	// SET STYLES TO max-height TO SQUASH DOWN EMPTY SPACE
	domAttr.set(paramRow.inputParams, 'style', 'display: inline-block; max-height: ' + paramRow.inputParams.clientHeight + 'px !important');
	domAttr.set(paramRow.args, 'style', 'display: inline-block; max-height: ' + paramRow.args.clientHeight + 'px !important');
	domAttr.set(paramRow.inputParams, 'style', { display: "inline-block", "min-height": "20px !important" });
	domAttr.set(paramRow.args, 'style', {	display: "inline-block", "min-height": "20px !important" });
	//console.log("ParameterRow.levelRowHeight    AFTER max-height this.args.clientHeight       : " + paramRow.args.clientHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER max-height this.inputParams.clientHeight: " + paramRow.inputParams.clientHeight);

	//console.log("AFTER max-height    paramRow.args        : " + domAttr.get(paramRow.args, 'style'));
	//console.log("AFTER max-height    paramRow.inputParams : " + domAttr.get(paramRow.inputParams, 'style'));
	
	if ( paramRow.inputParams.clientHeight < paramRow.args.clientHeight )
	{
		//console.log("paramRow.inputParams.height < paramRow.args.height");
		//console.log("Doing set inputParams height = args height")
	
		domAttr.set(paramRow.inputParams, 'style', 'display: inline-block; height: 0px !important');
		domAttr.set(paramRow.inputParams, 'style', 'display: inline-block; min-height: ' + paramRow.args.offsetHeight + 'px !important');
	
	}
	else if ( paramRow.inputParams.clientHeight >= paramRow.args.clientHeight )
	{
		//console.log("paramRow.inputParams.clientHeight >= paramRow.args.clientHeight");
	
		domAttr.set(paramRow.args, 'style', 'display: inline-block; height: 0px !important');
		domAttr.set(paramRow.args, 'style', 'display: inline-block; min-height: ' + paramRow.inputParams.offsetHeight + 'px !important');
	}

	//console.log("ParameterRow.levelRowHeight    AFTER paramRow.args.clientHeight   : " + paramRow.args.clientHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER this.inputParams.clientHeight: " + paramRow.inputParams.clientHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER paramRow.args.offsetHeight   : " + paramRow.args.offsetHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER this.inputParams.offsetHeight: " + paramRow.inputParams.offsetHeight);

	//console.log("FINAL paramRow.args.style : " + domAttr.get(paramRow.args, 'style'));
	//console.log("FINAL paramRow.inputParams.style : " + domAttr.get(paramRow.inputParams, 'style'));
},
toggle : function () {
// TOGGLE HIDDEN NODES
	//////console.log("ParameterRow.toggle    plugins.workflow.ParameterRow.toggle()");
	//////console.log("ParameterRow.toggle    this.description: " + this.description);

	var array = [ "argument", "valuetype", "valuetypeToggle", "category", "value", "ordinal", "ordinalToggle", "description", "format", "args", "inputParams", "paramFunction" ];
	for ( var i in array ) {
		this.toggleNode(this[array[i]]);
	}

	//console.log("ParameterRow.toggle    this.args: " + this.args);
	//console.dir({this_args:this.args});
	
	var style = domAttr.get(this.args, 'style');
	//console.log("ParameterRow.toggle    style: " + style);
	
	var display = style.match(/display:\s*([^;]+)/)[1];
	if ( display == "inline-block" )
		this.levelRowHeight(this);
},
toggleNode : function(node) {
	if ( node.style.display == 'inline-block' ) node.style.display='none';
	else node.style.display = 'inline-block';
	
},
toggleLock : function (event) {
	//console.log("ParameterRow.toggleLock    plugins.apps.Parameter.toggleLock(name)");
	
	if ( dojo.hasClass(this.locked, 'locked')	){
		domClass.remove(this.locked, 'locked');
		domClass.add(this.locked, 'unlocked');
		
		if ( Agua
		&& Agua.toastMessage ) {
			Agua.toastMessage({
				message: "ParameterRow has been unlocked. Users can change this parameter",
				type: warning
			});
		}
		
	}	
	else {
		domClass.remove(this.locked, 'unlocked');
		domClass.add(this.locked, 'locked');

		Agua.toastMessage({
			message: "ParameterRow has been locked. Users cannot change this parameter",
			type: "warning" 
		});
	}	

	var inputs = this.parentWidget.getFormInputs(this);
	this.parentWidget.saveInputs(inputs, null);
	event.stopPropagation(); //Stop Event Bubbling
}

}); //	end declare

});	//	end define

