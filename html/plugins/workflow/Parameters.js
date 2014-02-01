dojo.provide("plugins.workflow.Parameters");

// ALLOW THE USER TO ADD, REMOVE AND MODIFY PARAMETERS

dojo.require("dijit.TitlePane");

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dojo.parser");
dojo.require("plugins.core.Common");

// HAS A
dojo.require("plugins.workflow.ParameterRow");

dojo.declare("plugins.workflow.Parameters",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/parameters.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins", "workflow/css/parameters.css") ],

// PARENT WIDGET
parentWidget : null,

// ARRAY OF CHILD WIDGETS
childWidgets : null,

// isVALID BOOLEAN: ALL PARAMETERS ARE VALID
isValid : null,
// CORE WORKFLOW OBJECTS
core : null,

/////}
constructor : function(args) {
	////////console.log("Parameters.constructor     plugins.workflow.Parameters.constructor");			
	this.core = args.core;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	////////console.log("Controller.postCreate    plugins.workflow.Controller.postCreate()");

	this.startup();
},
startup : function () {
// DO inherited, LOAD ARGUMENTS AND ATTACH THE MAIN TAB TO THE ATTACH NODE
	////////console.log("Parameters.startup    plugins.workflow.Parameters.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	////////console.log("Parameters.startup    this.application: " + this.application);
	////////console.log("Parameters.startup    this.attachPoint: " + this.attachPoint);

	this.setUploader();

	// ADD TO TAB CONTAINER		
	this.attachPoint.addChild(this.mainTab);
	this.attachPoint.selectChild(this.mainTab);
},
setUploader : function () {

	var uploaderId = dijit.getUniqueId("plugins_form_Uploader");
	//////console.log("Parameter.setUploader     uploaderId: " + uploaderId);
	var username = Agua.cookie('username');
	var sessionid = Agua.cookie('sessionid');
	this.uploader = new plugins.form.UploadDialog(
	{
		uploaderId: uploaderId,
		username: 	username,
		sessionid: 	sessionid
	});
},
clear : function () {
// CLEAR THE INPUT AND OUTPUT PANES
	////////console.log("Parameters.hide    plugins.workflow.Parameters.hide()");
	this.mainTab.style.visibility = "hidden";	

	this.appNameNode.innerHTML = '';

	while ( this["inputRows"].firstChild )
	{
		this["inputRows"].removeChild(this["inputRows"].firstChild);
	}
	while ( this["outputRows"].firstChild )
	{
		this["outputRows"].removeChild(this["outputRows"].firstChild);
	}
},
resetChainedOutputs : function (chainedOutputs) {
	////console.log("XXXX Parameters.resetChainedOutputs    Parameters.resetChainedOutputs(chainedOutputs");	
	////console.log("xxx Parameters.resetChainedOutputs    chainedOutputs.length: " + chainedOutputs.length);
	////console.log("Parameters.resetChainedOutputs    this.childWidgets.length: " + this.childWidgets.length);
	var thisObject = this;
	dojo.forEach(chainedOutputs, function(chainedOutput, i) {
		////console.log("Parameters.resetChainedOutputs    chainedOutput " + i + ": " + chainedOutputs[i]);
		if ( chainedOutput == null )
		{
			////console.log("Parameters.resetChainedOutputs    chainedOutput is null. NEXT");
			return;
		}
        var chainedValue = chainedOutput.value;
	////console.log("Parameters.resetChainedOutputs    chainedValue " + i + ": " + chainedValue);
		thisObject.setOutputValue(chainedValue)
	});
},
setOutputValue : function (chainedValue) {
	////console.log("Parameters.setOutputValue    Parameters.setOutputValue(chainedValue)");
	////console.log("Parameters.setOutputValue    chainedValue: " + chainedValue);
	////console.log("Parameters.setOutputValue    this.childWidgets.length: " + this.childWidgets.length);
	////console.log("Parameters.setOutputValue    ////console.dir(this): " + this.childWidgets.length);
	var thisObject = this;
	dojo.forEach(thisObject.childWidgets, function(parameterRow, j) { 
		////console.log("Parameters.setOutputValue    parameterRow" + j + " '" + parameterRow.name + "'" + "[" + parameterRow.paramtype + "]: " + parameterRow.value);
		if ( parameterRow.paramtype == "input" )    return;
////console.log("HERE");
		if ( chainedValue == null || chainedValue == '')   return;
		if ( chainedValue != parameterRow.value )
		{
			////console.log("Parameters.setOutputValue    Setting parameterRow.value: " + chainedValue);
			parameterRow.value = chainedValue;
			parameterRow.valueNode.innerHTML = chainedValue;
			return;
		}
    });
},
load : function (node, shared, force) {
// LOAD APPLICATION DATA INTO INPUT AND OUTPUT TITLE PANES
	//console.log("Parameters.load    plugins.workflow.Parameters.load(node, shared, force)");
	console.log("Parameters.load    node: " + node);
	console.dir({node:node});
	//console.log("Parameters.load    shared: " + shared);
	//console.log("Parameters.load    force: " + force);
	//console.log("Parameters.load    node.parentWidget: " + node.parentWidget);
	//console.log("Parameters.load    node.stageRow: " + node.stageRow);

	//console.log("Parameters.load    PASSED node.application:");
	//console.dir({node_application:node.application});	

	// SET DEFAULT force = FALSE
	if ( force == null)	force = false;

	// SET this.shared
	this.shared = shared;

	// SET this.parentNode
	this.parentNode = node;
	this.parentWidget = node.parentWidget;
	//console.log("Parameters.load    this.parentWidget: " + this.parentWidget);

	// SET this.stageRow
	if ( node.stageRow ) this.stageRow = node.stageRow;
	else this.stageRow = node.parentWidget;
	if ( this.stageRow == null && node.childNodes ) {
		this.stageRow = dijit.byNode(node.childNodes[0]);
	}
	//console.log("Parameters.load    node.stageRow: " + node.stageRow);
	//console.log("Parameters.load    node.parentWidget: " + node.parentWidget);
	//console.log("Parameters.load    node.childNodes[0]: " + node.childNodes[0]);
	//console.log("Parameters.load    this.stageRow: " + this.stageRow);
	//console.log("Parameters.load    dijit.getEnclosingWidget(node.childNodes[0]: " + dijit.getEnclosingWidget(node.childNodes[0]));

	// SET this.application
	this.application = node.application;
	if ( node.application == null ) {
		console.log("Parameters.load     node.application is null. Using node.parentWidget.application");
		this.application = node.parentWidget.application;
	}

	//console.log("Parameters.load    AFTER node.application:");
	//console.dir({node_application:node.application});
	//
	//console.log("Parameters.load     this.application: " + dojo.toJson(this.application, true));
	//console.log("Parameters.load     console.dir(this):");
	//console.dir(this);
	//console.log("Parameters.load     this.childWidgets: " + this.childWidgets);
//
	// INITIALISE this.childWidgets
	if ( this.childWidgets == null ) this.childWidgets = new Array;

	// DESTROY ANY EXISTING ParameterRow CHILD WIDGETS
	while ( this.childWidgets.length > 0 ) {
		var widget = this.childWidgets.splice(0,1)[0];
		if ( widget.destroy )	widget.destroy();
	}
	//console.log("Parameters.load     AFTER widget.destroy(), this.childWidgets.length: " + this.childWidgets.length);
	
	// SET PROJECT.WORKFLOW NAME
	this.workflowNameNode.innerHTML = this.application.project + ". " + this.application.workflow;	
	
	// SET APPLICATION NAME AND NUMBER
	this.appNameNode.innerHTML = this.application.number + ". " + this.application.name;

	// LOAD INPUT TITLE PANE
	//console.log("Parameters.load     BEFORE this.loadTitlePane(****************** input ******************)");
	this.loadTitlePane("input");

	// LOAD OUTPUT TITLE PANE
	//console.log("Parameters.load     BEFORE this.loadTitlePane(****************** output ******************)");
	this.loadTitlePane("output");

	// SELECT THIS TAB PANE
	this.attachPoint.selectChild(this.mainTab);

	// CALL StageRow.checkValidParameters TO CHECK THAT ALL
	// REQUIRED PARAMETER INPUTS ARE SATISFIED
	var stageRow = node.parentWidget;
	//console.log("Parameters.load     stageRow: " + stageRow);
	//console.dir({stageRow:stageRow});
	//console.log("Parameters.load     node: " + node);
	//console.dir(node);
	
	// DON'T IGNORE STORED Agua.getParameterValidity DATA
	// USE THE UPDATED Agua.getParameterValidity DATA TO SET CSS 
	// CLASSES OF PARAMETER ROWS
	//console.log("Parameters.load     BEFORE stageRow.checkValidParameters()");
	if ( ! shared )
		stageRow.checkValidParameters(force);
	//console.log("Parameters.load     AFTER stageRow.checkValidParameters()");

	//////// USE THE UPDATED Agua.getParameterValidity DATA TO SET CSS 
	//////// CLASSES OF PARAMETER ROWS
	////////this.setParameterRowStyles();

	console.log("Parameters.load     END");
},
setParameterRowStyles : function () {
	console.group("Parameters-" + this.id + "    setParameterRowStyles");
	console.log("Parameters.setParameterRowStyles    caller: " + this.setParameterRowStyles.caller.nom);
	
	var parameterRows = this.childWidgets;
	var parameterHash = new Object;
	for ( var i = 0; i < parameterRows.length; i++ )
	{
		////console.log("Parameters.setParameterRowStyles     parameterRows[" + i + "]: "+ parameterRows[i]);
		//////console.log("Parameters.setParameterRowStyles     " + parameterRows[i].name + ", parameterRows[" + i + "].paramtype: " + parameterRows[i].paramtype);
		if ( parameterRows[i].paramtype == "input" ) 
			parameterHash[parameterRows[i].name] = parameterRows[i];
	}
	console.log("Parameters.setParameterRowStyles     parameterRows:");
	console.dir({parameterRows:parameterRows});

	////////console.log("Parameters.setParameterRowStyles     this.application: " + dojo.toJson(this.application, true));
	var stageParameters = Agua.getStageParameters(this.application);
	////////console.log("Parameters.setParameterRowStyles     stageParameters: " + dojo.toJson(stageParameters, true));
	//////console.log("Parameters.setParameterRowStyles     stageParameters.length: " + stageParameters.length);
	for ( var i = 0; i < stageParameters.length; i++ )
	{
		if ( stageParameters[i].paramtype != "input" ) continue;

		var parameterRow = parameterHash[stageParameters[i].name];
		////console.log("Parameters.setParameterRowStyles    stageParameters[i] " + stageParameters[i].name + " (paramtype: " + stageParameters[i].paramtype + ") parameterRow: " + parameterRow);

		var isValid = Agua.getParameterValidity(stageParameters[i]);
		//////console.log("Parameters.setParameterRowStyles     stageParameters[" + i + "] '" + stageParameters[i].name + "' isValid: " + isValid);
		if ( isValid == true || isValid == null )
		{
			//////console.log("Parameters.setParameterRowStyles     Doing parameterRows[" + i +  "].setValid()");
			parameterRow.setValid(parameterRow.domNode);
		}
		else
		{
			parameterRow.setInvalid(parameterRow.domNode);
		}
	}	

	console.groupEnd("Parameters-" + this.id + "    setParameterRowStyles");
},
loadTitlePane : function (paneType, shared) {
	//console.log("Parameters.loadTitlePane    plugins.workflow.Parameters.loadTitlePane(paneType)");
	console.log("Parameters.loadTitlePane    paneType: " + paneType);
	console.log("Parameters.loadTitlePane    this.shared: " + this.shared);

	var paneRows = paneType + "Rows";

	// DEBUG
	var stageParameters = Agua._getStageParameters();
	//console.log("Parameters.loadTitlePane    START stageParameters.length:" + stageParameters.length);

	// CLEAR PANE
	while ( this[paneRows].firstChild )
		this[paneRows].removeChild(this[paneRows].firstChild);

	//////////console.log("Parameters.loadTitlePane    this.application:" + dojo.toJson(this.application));
	var stageObject = {
		username: this.application.username,
		project: this.application.project,
		workflow: this.application.workflow,
		workflownumber: this.application.workflownumber,
		submit: this.application.submit,
		name: this.application.name,
		number: this.application.number   // NB: SWITCH FROM number TO appnumber
	};
	////////console.log("Parameters.loadTitlePane    stageObject:" + dojo.toJson(stageObject, true));

	if ( paneType == "input" )
		this.addSubmit(dojo.clone(stageObject), paneRows);
		
	// GET OUTPUTS FROM Agua.stageparameters	
	var parameters;
	if ( this.shared == true ) {
		//console.log("Parameters.loadTitlePane     DOING parameters = Agua.getSharedStageParameters(stageObject)");
		parameters = Agua.getSharedStageParameters(stageObject);
	}
	else {
		//console.log("Parameters.loadTitlePane     DOING parameters = Agua.getStageParameters(stageObject)");
		parameters = Agua.getStageParameters(stageObject);
	}
    //console.log("Parameters.loadTitlePane    parameters:");
    //console.dir({parameters:parameters});

	// DEBUG
	stageParameters = Agua._getStageParameters();
	//console.log("Parameters.loadTitlePane    MIDDLE stageParameters.length:" + stageParameters.length);
	//console.log("Parameters.loadTitlePane    BEFORE filter parameters:" + dojo.toJson(parameters));
	//console.log("Parameters.loadTitlePane    BEFORE filter, parameters.length:" + parameters.length);
	//console.log("Parameters.loadTitlePane    filter by paramtype:" + paneType);
	parameters = this.filterByKeyValues(parameters, ["paramtype"], [paneType]);
	parameters = this.sortHasharrayByKeys(parameters, ["ordinal","name"]);
	//console.log("Parameters.loadTitlePane    AFTER filter, parameters.length:" + parameters.length);
	//console.log("Parameters.loadTitlePane     AFTER parameters:" + dojo.toJson(parameters, true));

	// DEBUG
	stageParameters = Agua._getStageParameters();
	//console.log("Parameters.loadTitlePane    END stageParameters.length:" + stageParameters.length);

	if ( parameters == null ) {
		//console.log("Parameters.loadTitlePane     parameters == null. Returning.");
		return;
	}
	
	for ( var i = 0; i < parameters.length; i++ )
	{
		//console.log("Parameters.loadTitlePane    loading parameter " + i + ": " + dojo.toJson(parameters[i]));

		// SET parameter KEY:VALUE PAIRS
		var parameter = new Object;
		for ( var key in parameters[i] )
		{
			// CONVERT '\\\\' INTO '\\'
			//if ( parameters[i][key] && parameters[i][key].replace )
			if ( parameters[i][key].replace )
				parameter[key] = parameters[i][key].replace(/\\\\/g, '\\');
			else
				parameter[key] = parameters[i][key];
		}
		
		// CONVERT PROJECT AND WORKFLOW VALUES
		var username = Agua.cookie('username');
		if ( parameter.value == null )	parameter.value = '';
		else {
			parameter.value = String(parameter.value);
			parameter.value = parameter.value.replace(/%username%/, username);
			parameter.value = parameter.value.replace(/%project%/, parameter.project);
			parameter.value = parameter.value.replace(/%workflow%/, parameter.workflow);
			parameter.value = parameter.value.replace(/%username%/, Agua.cookie('username'));
		}

		// ADD CORE LIST
		parameter.core = this.core;
		parameter.uploader = this.uploader;
		
		// INSTANTIATE plugins.workflow.ParameterRow
		//////////////console.log("Parameters.loadTitlePane    Doing new plugins.workflow.ParameterRow(parameter)");
		var ParameterRow = new plugins.workflow.ParameterRow(parameter);
		this[paneRows].appendChild(ParameterRow.domNode);
		//////////////console.log("Parameters.loadTitlePane    AFTER new plugins.workflow.ParameterRow(parameter)");
		// PUSH ONTO ARRAY OF CHILD WIDGETS
		this.childWidgets.push(ParameterRow);
	}	
	//////console.log("Parameters.loadTitlePane    END");
},
addSubmit : function (stageObject, paneRows) {
	////console.group("Parameters-" + this.id + "    addSubmit")
	////console.log("Parameters.addSubmit    workflow.Parameters.addSubmit(stageObject, paneRows)");
	////console.dir({stageObject:stageObject});
	var stageRow = this.stageRow;
	////console.log("Parameters.addSubmit    stageRow: " + stageRow);
	////console.dir({stageRow:stageRow});
	////console.dir({thisApplication:this.application});
	////console.log("Parameters.addSubmit    paneRows.length: " + paneRows.length);
	
	var submitParameter = stageObject;
	submitParameter.description = "Submit this stage to the cluster (if cluster is defined)"
	submitParameter.discretion = "optional";
	submitParameter.name = "SUBMIT"
	submitParameter.value = this.application.submit;
	submitParameter.paramtype = "input";
	submitParameter.valuetype = "flag";
	if ( ! submitParameter.value )	submitParameter.value = '';
	////console.dir({submitParameter:submitParameter});

	var ParameterRow = new plugins.workflow.ParameterRow(submitParameter);

	var thisObject = this;
	ParameterRow.handleCheckboxOnChange = dojo.hitch(thisObject, function (event) {
		////console.log("Parameters.addSubmit    ParameterRow.handleCheckboxOnChange    event.target: " + event.target);
		////console.log("Parameters.addSubmit    ParameterRow.handleCheckboxOnChange    event.target.checked: " + dojo.toJson(event.target.checked));
		event.stopPropagation(); 
		////console.log("Parameters.addSubmit    ParameterRow.handleCheckboxOnChange    Doing thisObject.updateSubmit()");
		stageObject.submit = 0;
		if ( event.target.checked == true )
			stageObject.submit = 1;
		////console.log("Parameters.addSubmit    ParameterRow.handleCheckboxOnChange    stageObject.submit: " + stageObject.submit);

		this.application.submit = stageObject.submit;
		////console.log("Parameters.addSubmit    this:");

		////console.log("Parameters.addSubmit    DOING Agua.updateStageSubmit(stageObject)");
 
		this.setStageSubmitStyle(stageRow, stageObject.submit);

		Agua.updateStageSubmit(stageObject)
	
	});

	this[paneRows].appendChild(ParameterRow.domNode);

	////console.groupEnd("Parameters-" + this.id + "    addSubmit")
},
setStageSubmitStyle : function (stageRow, submit) {
	//console.group("Parameters-" + this.id + "    setStageSubmitStyle")
	//console.group("Parameters.setStageSubmitStyle     stageRow: " + stageRow)
	//console.dir({stageRow:stageRow});
	//console.group("Parameters.setStageSubmitStyle     submit: " + submit)

	stageRow.setSubmitStyle(submit);

	//console.groupEnd("Parameters-" + this.id + "    setStageSubmitStyle")
},
checkValidInputs : function () {
// 1. CHECK VALIDITY OF ALL PARAMETERS, STORE AS this.isValid
// 2. CHANGE StageRow Style ACCORDINGLY	SET stageRow.isValid
// 3. stageRow CALLS Stages.updateRunButton AND TOGGLES 
// 		runWorkflow BUTTON
	////////console.log("Parameters.checkValidInputs     plugins.workflow.Parameters.checkValidInputs()");
	////////console.log("Parameters.checkValidInputs     this: " + this);
	////////console.log("Parameters.checkValidInputs     this.childWidgets.length: " + this.childWidgets.length);

	this.isValid = true;
	for ( var i = 0; i < this.childWidgets.length; i++ )
	{
		if ( this.childWidgets[i].paramtype != "input" )	continue;
		////////console.log("Parameters.checkValidInputs     this.childWidgets[" + i + "] '" + this.childWidgets[i].name + "' * " + this.childWidgets[i].value + " * validInput: " + this.childWidgets[i].validInput);

		if ( this.childWidgets[i].validInput == false )
		{
			////////console.log("Parameters.checkValidInputs     Setting this.isValid to false");
			this.isValid = false;
		
			break;
		}
	}	
	////////console.log("Parameters.checkValidInputs     this.isValid: " + this.isValid);

	// CALL StageRow.checkValidParameters TO CHECK THAT ALL
	// REQUIRED PARAMETER INPUTS ARE SATISFIED
	var stageRow = this.stageRow;
	////////console.log("Parameters.load     stageRow: " + stageRow);
	////////console.log("Parameters.load     Calling stageRow.checkValidParameters()");
	if ( this.stageRow == null )	return;
	
	////////console.log("Parameters.checkValidInputs     FINAL this.isValid: " + this.isValid);
	if ( this.isValid == true ) this.stageRow.setValid();
	else this.stageRow.setInvalid();
},
isCurrentApplication : function (application) {
// RETURN true IF THE application IS IDENTICAL TO THE CURRENT APPLICATION
	var keys = ["project", "workflow", "workflownumber", "name", "number"];
	return ( this._objectsMatchByKey(application,
		this.core.parameters.application, keys) );
}

}); // plugins.workflow.Parameters

