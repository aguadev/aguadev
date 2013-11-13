dojo.provide("plugins.workflow.ParameterRow");

// INTERNAL MODULES
// HAS A 
dojo.require("plugins.form.UploadDialog");
dojo.require("dojo.io.iframe");

// INHERITS
dojo.require("plugins.core.Common");
dojo.require("plugins.form.EditRow");
dojo.require("plugins.form.Inputs");

dojo.declare( "plugins.workflow.ParameterRow",
	[ plugins.form.EditRow, plugins.form.Inputs, plugins.core.Common, dijit._Widget, dijit._Templated ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/parameterrow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

validInput : true,	// FILE PRESENT BOOLEAN

// CORE WORKFLOW OBJECTS
core : null,

formInputs : {		// FORM INPUTS AND TYPES (word|phrase)
	valueNode: "word",
	descriptionNode: "phrase"
},
defaultInputs : {	// DEFAULT INPUTS
	valueNode: "",
	descriptionNode: ["Description"]
},

requiredInputs : {	// REQUIRED INPUTS CANNOT BE ''
	valueNode : 1
},
invalidInputs : {	// THESE INPUTS ARE INVALID

	valueNode : ["essential", "required", "optional"]
	//description: "Description",
	//notes: "Notes"
},

// uploader : 

/////}}}}
constructor : function(args) {
	//////console.log("ParameterRow.constructor    plugins.workflow.ParameterRow.constructor(args)");
	this.passedArgs = args;
	this.core = args.core;
	this.uploader = args.uploader;

	// POPULATE this.parameterObject TO BE USED IN saveInputs
	this.parameterObject = new Object;
	for ( var key in args )
	{
		if ( key == "core" || key == "uploader" )	continue;
		////console.log("ParameterRow.constructor    this.parameterObject[" + key + "]: " + args[key]);
		this.parameterObject[key] = args[key];
	}

	////console.log("ParameterRow.constructor    END");	
},
postCreate : function() {
	////console.log("ParameterRow.postCreate    plugins.workflow.ParameterRow.postCreate()");
	////console.log("ParameterRow.postCreate    DOING this.inherited(arguments)");
	this.inherited(arguments);
	this.startup();
},
startup : function () {
	////console.log("ParameterRow.startup    plugins.workflow.ParameterRow.startup()");
	this.inherited(arguments);

	// SET TOGGLE VISIBILITY WITH name ELEMENT ONCLICK
	this.setToggle();

	// SET LISTENERS FOR EDIT ONCLICK
	this.setEditOnclicks();

	// SET this.nameNode.parentWidget FOR 'ONCLICK REMOVE' IN Workflow.updateDropTarget
	this.nameNode.parentWidget = this;
	
	// SET BROWSE BUTTON IF FILE OR DIRECTORY
	this.setBrowseButton();
	
	// SET UPLOAD BUTTON ONCLICK LISTENER
	if ( this.valuetype == "file" )
		this.setFileDownload();
	
	if ( this.valuetype == "flag" )
		this.setCheckbox();
		
	// CHECK CURRENT VALUE IS VALID
	////console.log("ParameterRow.startup    Doing this.checkInput(node, inputValue, force)");
	var node = this.valueNode;
	////console.log("ParameterRow.startup    node: " + node);

	//var inputValue = this.valueNode.innerHTML;	
	//var force = true;
	//this.checkInput(node, inputValue, force);	
},
getInputValue : function () {
// GET INPUTS FROM THE FORM
	//console.log("ParameterRow.getInputValue    plugins.workflow.ParameterRow.getInputValue()");
	//console.log("ParameterRow.getInputValue    '" + this.name + "' this.valueNode.innerHTML: " + this.valueNode.innerHTML);

	if ( inputValue && inputValue.match(/^<input type="checkbox">/) )
	{
		return this.valueNode.firstChild.checked;
	}

	var value;
	if ( this.valueNode.innerHTML )
	{
		value = this.valueNode.innerHTML;
	}
	
	var name = "valueNode";
	if ( this.formInputs[name] == "word" )
	{
		value = this.cleanWord(value);
	}
	else if ( this.formInputs[name] == "phrase" )
	{
		value = this.cleanEnds(value);
	}

	////console.log("ParameterRow.getvalue    BEFORE convertString, value: " + value);
	value = this.convertString(value, "htmlToText");
	////console.log("ParameterRow.getvalue    AFTER convertString, value: " + value);

	this.valueNode.value = value;

	return value;
},
destroy: function (preserveDom) {
// overridden destroy method. call the parent method
	////console.log("ParameterRow.destroy    plugins.report.ParameterRow.destroy()");
	this.inherited(arguments);
},
/////////	FLAG
setCheckbox : function () {
// ADD A CHECKBOX TO THE valueNode IF THE INPUT TYPE IS A FLAG
	//console.log("ParameterRow.setCheckbox    plugins.workflow.ParameterRow.setCheckbox()");
	//console.log("ParameterRow.setCheckbox    this.valuetype: " + this.valuetype);

	this.checkbox = document.createElement('input');
	this.checkbox.type = "checkbox";
	if ( this.parameterObject.valuetype == "flag" )
	if ( this.value == 1 )
		this.checkbox.checked = true;
	else
		this.checkbox.checked = false;
	this.valueNode.innerHTML = '';
	this.valueNode.appendChild(this.checkbox);

	dojo.connect(this.checkbox, "onchange", dojo.hitch(this, "handleCheckboxOnChange"));
},
handleCheckboxOnChange : function (event) {
	//console.log("ParameterRow.handleCheckboxOnChange    plugins.workflow.ParameterRow.handleCheckboxOnChange(event)");
	//console.log("ParameterRow.handleCheckboxOnChange    event: " + event);

	//Stop Event Bubbling
	event.stopPropagation(); 

	// GET INPUTS
	var inputs = this.getFormInputs(this);
	//console.log("ParameterRow.handleCheckboxOnChange    inputs: " + dojo.toJson(inputs));
	if ( inputs == null ) return;

	// SAVE STAGE PARAMETER
	//console.log("ParameterRow.setCheckbox    Doing thisObject.saveInputs(inputs)");
	this.saveInputs(inputs, {originator: this, reload: false});
},
/////////	FILE MANAGER
setBrowseButton : function() {
	////console.log("ParameterRow.setBrowseButton    plugins.report.ParameterRow.browseButton()");
	////console.log("ParameterRow.setBrowseButton    this.paramtype: " + this.paramtype);
	////console.log("ParameterRow.setBrowseButton    this.valuetype: " + this.valuetype);
	
	// RETURN IF THE PARAMTYPE IS NOT file* OR director*
	if (! this.valuetype.match(/^file/) && ! this.valuetype.match(/^director/))	return;

	////console.log("ParameterRow.setBrowseButton    Doing dojo.connect");
	dojo.connect(this.browseButton, "onclick", this, dojo.hitch( this, function(event)
		{
			// DO FILTER REPORT
			this.openFileManager();
		}
	));
},
openFileManager : function() {
/* OPEN FILE MANAGER TO ALLOW SELECTION OF FILE AS ARGUMENT VALUE.
	PASS THIS PARAMETER ROW OBJECT AS A PARAMETER TO BE USED IN
	THE CALLBACK TO SET THE ARGUMENT VALUE (LOCALLY AND REMOTELY).
*/

	//console.log("ParameterRow.openFileManager     workflow.ParameterRow.openFileManager()");
	if ( ! Agua.fileManager ) {
		//console.log("ParameterRow.openFileManager     Agua.fileManager is null. Returning");
		return;
	}
		
	if ( this.paramtype != "input" ) {
		//console.log("ParameterRow.openFileManager     Doing Agua.fileManager.disableMenus()");
		Agua.fileManager.disableMenuSelect();
		Agua.fileManager.disableMenuAdd();
	}
	else {
		//console.log("ParameterRow.openFileManager     Doing Agua.fileManager.enableMenus()");
		Agua.fileManager.enableMenuSelect();	
		Agua.fileManager.enableMenuAdd();	
	}

	Agua.fileManager.show(this);
},
/////////	CHECKINPUT 
saveInputs : function(inputs, updateArgs) {
	//console.log("ParameterRow.saveInputs    plugins.workflow.ParameterRow.saveInputs(inputs, updateArgs)");	
	//console.log("ParameterRow.saveInputs    inputs: " + inputs);
	//console.dir(inputs);
	//console.log("ParameterRow.saveInputs    updateArgs: ");
	//console.dir(updateArgs) 

	// SET savingParameter FLAG
	//console.log("ParameterRow.saveInputs    this.savingParameter: " + this.savingParameter);
	if ( this.savingParameter == true )
		return;
	this.savingParameter = true;

	// PREPARE ARGUMENTS:	node, inputValue, force
	var node = updateArgs.originator.valueNode;
	var inputValue = inputs.valueNode;	
	var force = true;
	//console.log("ParameterRow.saveInputs    node: " + node);
	//console.log("ParameterRow.saveInputs    inputValue: " + inputValue);
	//console.log("ParameterRow.saveInputs    force: " + force);
	//console.log("ParameterRow.saveInputs    this.valuetype: " + this.valuetype);

	if ( this.valuetype == "flag" )
	{
		//console.log("ParameterRow.saveInputs    DOING inputValue = this.getCheckboxValue()");
		inputValue = this.getCheckboxValue();
		//console.log("ParameterRow.saveInputs    inputValue: " + inputValue);
		inputs.valueNode = inputValue;
	}

	//console.log("ParameterRow.saveInputs    Doing this.checkInput(node, inputValue, force)");
	this.checkInput(node, inputValue, force);

	// DOUBLE-UP BACKSLASHES
	for ( var i = 0; i < inputs.length; i++ ) {
		inputs[i] = this.convertBackslash(inputs[i], "expand");
	}
	//console.log("ParameterRow.saveInputs    AFTER this.convertBackslash() inputs: " + dojo.toJson(inputs));
	
	// POPULATE PARAMETER OBJECT
	this.parameterObject.username = Agua.cookie('username');
	this.parameterObject.sessionid = Agua.cookie('sessionid');
	for ( key in inputs )
	{
		this.parameterObject[key] = inputs[key];
	}
	delete this.parameterObject.uploader;
	this.parameterObject.value = this.parameterObject.valueNode;
	delete this.parameterObject.valueNode;
	//this.parameterObject.chained = 0;

	// UNSET savingParameter FLAG
	this.savingParameter = false;
	
	// ADD STAGE PARAMETER		
	//console.log("ParameterRow.saveInputs    Doing Agua.addStageParameter(stageParameterObject)");
	Agua.addStageParameter(this.parameterObject);

	// CHAIN OUTPUTS
	//console.log("ParameterRow.saveInputs    Doing this.core.io.chainOutputs()");
	var application = this.core.parameters.application;
	//console.log("ParameterRow.saveInputs    application: " + dojo.toJson(application));
	var chainedOutputs = this.core.io.chainOutputs(application, true);
	//console.log("ParameterRow.saveInputs    chainedOutputs: " + dojo.toJson(chainedOutputs));
	this.core.parameters.resetChainedOutputs(chainedOutputs);

	// REFRESH VALIDITY OF PARAMETERS PANE
	this.core.parameters.checkValidInputs();
	
},
getCheckboxValue : function () {
	////console.log("ParameterRow.checkCheckBoxValue    plugins.workflow.ParameterRow.checkCheckBoxValue()");	
	if ( this.valueNode.firstChild.checked == true )	return "1";
	return "0";
},
checkInput : function (node, inputValue, force) {
// CHECK IF INPUT IS VALID OR IF FILE/DIRECTORY IS PRESENT.
// SET NODE CSS ACCORDINGLY.
	//console.group("ParameterRow-" + this.id + "    checkInput");
	//console.log("ParameterRow.checkInput    node, inputValue, force");	
	//console.log("ParameterRow.checkInput    node: " + node);
	//console.log("ParameterRow.checkInput    inputValue: " + inputValue);
	//console.log("ParameterRow.checkInput    force: " + force);
	
	// NO NEED TO CHECK FLAG
	if ( this.valuetype == "flag" )
	{
		////console.log("ParameterRow.checkInput    this.valuetype = flag. Setting this.validInput = true and returning");
		this.validInput == true;	
		this.setValid(node);
	}

	// IF EMPTY, CHECK IF REQUIRED OR ESSENTIAL
	else if ( inputValue == null || inputValue == '' )
		this.checkEmpty(node);

	// DO TEXT INPUT IF TYPE IS NOT file, files, directory, OR directories
	else if ( ! this.valuetype.match(/^file$/)
			&& ! this.valuetype.match(/^directory$/) )
	{
		if ( this.parameterObject.valuetype == "integer" )
		{
			////console.log("ParameterRow.checkInput    Doing this.checkIntegerInput");
			this.checkIntegerInput(node, inputValue);
		}
		else if ( this.parameterObject.valuetype == "string" )
		{
			////console.log("ParameterRow.checkInput    Doing this.checkTextInput");
			this.checkTextInput(node, inputValue);
		}
	}
	
	// OTHERWISE, DO FILE INPUT
	else
	{
		////console.log("ParameterRow.checkInput    Doing this.checkFile");
		if ( force == null )	force = false;
		this.checkFile(node, inputValue, force);
	}

	//console.groupEnd("ParameterRow-" + this.id + "    checkInput");
},
checkEmpty : function (node) {
	////console.log("ParameterRow.checkEmpty    ParameterRow.checkEmpty(node)");
	
	// IF ESSENTIAL/REQUIRED, SET AS INVALID
	if ( this.discretion == "essential"
		||	this.discretion == "required" )
	{
		// SET this.validInput AS FALSE AND SET invalid CSS
		this.setInvalid(node);
		this.validInput = false;

		// SET STAGE PARAMETER'S  AS false
		////console.log("ParameterRow.checkEmpty    null/empty for essential/required input '" + this.name + "'. Setting stageParameter. to FALSE");
		Agua.setParameterValidity(this, false);
	}
	else
	{
		// SET STAGE PARAMETER  AS TRUE
		////console.log("ParameterRow.checkEmpty    null/empty for NON-essential/required input '" + this.name + "'. Setting stageParameter. to TRUE");
		Agua.setParameterValidity(this, true);
		this.setValid(node);
		this.validInput = true;
	}

	// SET PARENT INFO PANE'S validInputs FLAG AND
	// CALL stages.updateRunButton
	this.core.parameters.checkValidInputs();
},
checkIntegerInput : function (node, inputValue) {
	//console.log("ParameterRow.checkIntegerInput    plugins.workflow.ParameterRow.checkIntegerInput()");	
	//console.log("ParameterRow.checkIntegerInput    node: " + node);
	//console.log("ParameterRow.checkIntegerInput    inputValue: " + inputValue);

	// ADD invalid CLASS IF INPUT IS NOT VALID
	if ( ! inputValue.match(/^\s*[\d\.]+\s*$/) )
	{
		//console.log("ParameterRow.isValidInput    Non-integer inputValue. Returning false");
		this.validInput = false;
		this.setInvalid(node);
		Agua.setParameterValidity(this, false);
	}
	else {
		this.setValid(node);
		Agua.setParameterValidity(this, true);
	}
},
checkTextInput : function (node, inputValue) {
	//console.log("ParameterRow.checkTextInput    plugins.workflow.ParameterRow.checkTextInput()");	
	//console.log("ParameterRow.checkTextInput    node: " + node);
	//console.log("ParameterRow.checkTextInput    inputValue: " + inputValue);

	var validInput = true;
	this.validInput = this.isValidInput(this.invalidInputs, "valueNode", inputValue);
	//console.log("ParameterRow.checkIntegerInput    this.validInput: " + this.validInput);

	// IF THE INPUT IS NOT VALID, ADD THE invalid CLASS.
	if ( this.validInput == false
		&& this.paramtype == "input" )
	{
		//console.log("ParameterRow.checkInput    text input not valid. Setting stageParameter. to FALSE");
		this.setInvalid(node);
		Agua.setParameterValidity(this, false);
	}
	
	// IF THE INPUT IS VALID, TOGGLE ITS 'required|satisfied'
	// ACCORDINGLY IF THE INPUT IS REQUIRED. IF NOT, DO NOTHING
	else
	{
		//console.log("ParameterRow.checkInput    text input is valid. Setting stageParameter. to TRUE");
		this.setValid(node);
		Agua.setParameterValidity(this, true);
	}

	//// MAKE THE PARENT Parameters CHECK FOR VALID INPUTS
	//// AMONG ALL OF ITS ParameterRow CHILDREN AND UPDATE
	//// THE DISPLAY OF THE STAGE IN THE WORKFLOW ACCORDINGLY.
	//// ALSO SET PARENT INFO PANE'S validInputs FLAG AND
	//// CALL stages.updateRunButton
	this.core.parameters.checkValidInputs();

},	//	checkTextInput
checkFile : function (node, inputValue, force) {
/* CHECK IF FILE/DIRECTORY IS PRESENT ON SERVER.
// CALL PARENT WIDGET TO UPDATE ITS validInputs SLOT.
// NB: RETURN NULL IF inputValue IS EMPTY OR NULL */
	//console.log("ParameterRow.checkFile    plugins.workflow.ParameterRow.checkFile()");	
	//console.log("ParameterRow.checkFile    node: " + node);
	////console.log("ParameterRow.checkFile    '" + this.name + "' inputValue: " + inputValue);
	////console.log("ParameterRow.checkFile    force: " + force);

	if ( inputValue == null || inputValue == '' )	return null;

	// RETURN IF fileExists HAS BEEN ALREADY SET TO true
	//console.log("ParameterRow.checkFile    force: " + force);
	if ( this.parameterObject.fileinfo != null )
		this.handleCheckfile(node, this.parameterObject.fileinfo);
	var fileinfo = Agua.getFileInfo(this.parameterObject);
	if ( fileinfo != null )
		this.handleCheckfile(node, fileinfo);

	// GENERATE QUERY JSON FOR THIS WORKFLOW IN THIS PROJECT
	var query = new Object;

	// SET requestor = THIS_USER IF core.parameters.shared IS TRUE
	if ( this.core.parameters.shared == true )
	{
		query.username = this.username;
		query.requestor = Agua.cookie('username');
	}
	else
	{
		query.username = Agua.cookie('username');
	}

	query.sessionid 	= 	Agua.cookie('sessionid');
	query.project 		= 	this.project;
	query.workflow 		= 	this.workflow;
	query.mode 			= 	"checkFile";
	query.module 		= 	"Agua::Workflow";
	query.filepath 		= 	inputValue;
	//////console.log("ParameterRow.checkFile    checkFile query: " + dojo.toJson(query));

	var url = this.randomiseUrl(Agua.cgiUrl + "agua.cgi");
	////////console.log("ParameterRow.checkFile    url: " + url);

	// ADD RANDOM NUMBER CONTENT TO DISAMBIGUATE xhrPut REQUESTS ON SERVER
	var content = Math.floor(Math.random()*1000000000000);
	var thisObject = this;
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			preventCache: true,
			sync : false,
			handleAs: "json",
			content: content,
			putData: dojo.toJson(query),
			//timeout: 20000,
			handle: function(fileinfo, ioArgs) {
				//console.log("ParameterRow.checkFile    JSON fileinfo for inputValue '" + inputValue + "': " + dojo.toJson(fileinfo));

				Agua.setFileInfo(thisObject.parameterObject, fileinfo);

				thisObject.handleCheckfile(node, fileinfo);

				// SET PARENT INFO PANE'S validInputs FLAG AND
				// CALL stages.updateRunButton
				thisObject.core.parameters.checkValidInputs();
			},
			error: function(response, ioArgs) {
				//console.log("ParameterRow.checkFile    Error with JSON Post, response: " + response);
			}
		}
	);	
},
handleCheckfile : function (node, fileinfo) {
// HANDLE JSON RESPONSE FROM checkFile QUERY
	//console.log("ParameterRow.handleCheckfile    plugins.workflow.ParameterRow.handleCheckfile(node, fileinfo)");
	//console.log("ParameterRow.handleCheckfile    BEFORE node: node");
	//console.log("ParameterRow.handleCheckfile    node: " + node);
	//console.log("ParameterRow.handleCheckfile    fileinfo: " + dojo.toJson(fileinfo));

	// SET FILEINFO
	//console.log("ParameterRow.handleCheckfile    DOING Agua.setFileInfo(this.parameterObject, fileinfo)");
	Agua.setFileInfo(this.parameterObject, fileinfo);

	if ( fileinfo == null || fileinfo.exists == null )
	{
		//console.log("ParameterRow.handleCheckfile    Either fileinfo or fileinfo.exists is null. Returning");
		return;
	}


	//if ( this.discretion == "required" )
	//{
	//	this.validInput = true;
	//	this.inputSatisfied(node);
	//
	//	// SET STAGE PARAMETER'S isValid AS true
	//	////console.log("ParameterRow.Checkfile    null/empty for essential/required input. DOING Agua.setParameterValidity(this, true)");
	//	Agua.setParameterValidity(this, true);
	//	return;
	//}
	//
	
	// IF THE FILE EXISTS, SET this.validInput TO TRUE
	// AND ADD filePresent AND inputSatisfied CSS CLASSES 
	if ( fileinfo.exists == "true" )
	{
		//console.log("ParameterRow.handleCheckfile    File exists. Changing CSS");
		//console.log("ParameterRow.handleCheckfile    this.valuetype: " + this.valuetype);
		//console.log("ParameterRow.handleCheckfile    fileinfo.type: " + fileinfo.type);
		
		// SET FILE PRESENT CSS
		this.filePresent(node);

		// IF file, files OR directory, directories SET CSS TO satisfied
		if( (this.valuetype == "directory" && fileinfo.type == "directory")
		   || (this.valuetype == "file" && fileinfo.type == "file") )
		{
			//console.log("ParameterRow.handleCheckfile    The file or directory is of the correct type. Doing this.setValid(node)");
			
			// SET SATIFIED/REQUIRED CSS AND this.validInput			
			this.setValid(node);
			this.validInput = true;

			// SET STAGE PARAMETER'S isValid AS true
			//console.log("ParameterRow.handleCheckfile    essential/required file/dir is  present. DOING Agua.setParameterValidity(this, true)");
			Agua.setParameterValidity(this, true);
		}
		
		// OTHERWISE, ITS A DIRECTORY WHEN A FILE IS REQUIRED, OR VICE-VERSA
		// SO SET CSS CLASS TO required
		else
		{
			//console.log("ParameterRow.handleCheckfile    File found when directory required (or vice-versa). Doing this.setInvalid(node)");
			//////console.log("ParameterRow.handleCheckfile    Setting CSS to required");
			this.setInvalid(node);
			this.validInput = false;
			//this.inputRequired(node);

			// SET STAGE PARAMETER'S isValid AS false
			//console.log("ParameterRow.handleCheckfile    null/empty for essential/required input. DOING Agua.setParameterValidity(this, false)");
			Agua.setParameterValidity(this, false);
		}
	}	// fileinfo.exists == true
	
	// OTHERWISE, ADD fileMissing AND inputRequired CSS
	// CLASSES AND SET this.validInput TO FALSE
	else
	{
		//console.log("ParameterRow.handleCheckfile    File does not exist. Changing class of node to 'fileMissing'");
		//console.log("ParameterRow.handleCheckfile    node: " + node);

		// SET FILE MISSING CSS
		this.fileMissing(node);

		// IF FILE MUST BE PHYSICALLY PRESENT (I.E., IT'S essential)
		// SET required CSS AND this.validInput TO FALSE			
		if ( this.discretion == "essential" )
		{
			this.validInput = false;
			this.setInvalid(node);
			//this.inputRequired(node);
		
			// SET STAGE PARAMETER'S isValid AS false
			//console.log("ParameterRow.handleCheckfile    null/empty for essential input. DOING Agua.setParameterValidity(this, false)");
			Agua.setParameterValidity(this, false);
		}

		// FILE IS NOT REQUIRED TO BE PHYSICALLY PRESENT
		// (I.E., IT'S NOT essential).
		// SET satisfied CSS AND this.validInput TO TRUE
		else
		{
			this.validInput = true;
			this.setValid(node);

			// SET STAGE PARAMETER'S isValid AS true
			//console.log("ParameterRow.handleCheckfile    null/empty for required input. DOING Agua.setParameterValidity(this, true)");
			Agua.setParameterValidity(this, true);
		}
	}
	
	//console.log("ParameterRow.handleCheckfile    " + this.appname + " parameter " + this.name + " FINAL this.validInput: " + this.validInput);
	
	// MAKE PARENT WIDGET CHECK ALL INPUTS ARE VALID AND SET
	// ITS OWN isValid FLAG AND CSS ACCORDINGLY
	
	//console.log("ParameterRow.handleCheckfile    " + this.appname + " parameter " + this.name + " FINAL this.validInput: " + this.validInput);


	////console.log("ParameterRow.handleCheckfile    DOING this.core.parameters.checkValidInputs()");
	
},
isValidInput : function (name, value) {
// DEFER VALIDITY CHECK UNTIL saveInputs
	return true;
},
/////////	EDIT VALUE 
setEditOnclicks : function () {
// ADD 'ONCLICK' EDIT VALUE LISTENERS
	//console.log("ParameterRow.setEditOnClicks    plugins.workflow.ParameterRow.setEditOnClicks()");

	if ( this.paramtype != "input" )
	{
		//console.log("ParameterRow.setEditOnClicks    Skipping onclick listeners for paramtype: " + this.paramtype);
		return;
	}
	var thisObject = this;
	var array = ["valueNode", "descriptionNode"];
	for ( var i in array ) {
		// IGNORE IF TYPE IS FLAG (SET FLAG ONCHANGE EARLIER IN setCheckbox)
		if ( this.valuetype != "flag" ) {
			//console.log("ParameterRow.setEditOnClicks    [" + i + "]    Non-flag input: " + array[i]);

			dojo.connect(this[array[i]], "onclick", dojo.hitch(this, function(event)
				{
					//console.log("ParameterRow.setEditOnClicks    [" + i + "]    onclick listener fired: " + array[i]);
					var node = event.target;
					this.editRow(this, node);
					event.stopPropagation(); //Stop Event Bubbling
				}
			));
		}	
	}
},
/////////	DOWNLOAD 
setFileDownload : function(node, name) {
	////console.log("ParameterRow.setFileDownload    plugins.report.ParameterRow.setFileDownload()");
	
	dojo.connect(this.downloadButton, "onclick", this, dojo.hitch( this, function(event)
		{
			////console.log("ParameterRow.setFileDownload    download onclick fired");
			
			// DO FILTER REPORT
			this.downloadFile(this.valueNode.innerHTML);
		}
	));
},
downloadFile : function (filepath) {
	////console.log("ParameterRow.downloadFile     plugins.workflow.ParameterRow.downloadFile(filepath)");
	////console.log("ParameterRow.downloadFile     filepath: " + filepath);
	var query = "?mode=downloadFile";

	// SET requestor = THIS_USER IF core.parameters.shared IS TRUE
	if ( this.core.parameters.shared == true )
	{
		query += "&username=" + this.username;
		query += "&requestor=" + Agua.cookie('username');
	}
	else
	{
		query += "&username=" + Agua.cookie('username');
	}

	query += "&sessionid=" + Agua.cookie('sessionid');
	query += "&filepath=" + filepath;
	////console.log("ParameterRow.downloadFile     query: " + query);
	
	var url = Agua.cgiUrl + "download.cgi";
	////console.log("ParameterRow.downloadFile     url: " + url);
	
	var args = {
		method: "GET",
		url: url + query,
		handleAs: "json",
		//timeout: 10000,
		load: this.handleDownload
	};
	////console.log("ParameterRow.downloadFile     args: ", args);

	// do an IFrame request to download the csv file.
	//////console.log("ParameterRow.downloadFile     Doing dojo.io.iframe.send(args))");
	var value = dojo.io.iframe.send(args);
},
handleDownload : function (response, ioArgs) {
	////console.log("ParameterRow.handleDownload     plugins.workflow.ParameterRow.handleDownload(response, ioArgs)");
	////console.log("ParameterRow.handleDownload     response: " + dojo.toJson(response));
	////console.log("ParameterRow.handleDownload     response.message: " + response.message);

	if ( response.message == "ifd.getElementsByTagName(\"textarea\")[0] is undefined" )
	{
		Agua.toastMessage({
			message: "Download failed: File is not present",
			type: "error"
		});	//////console.log("ParameterRow.downloadFile     value: " + dojo.toJson(value));

	}	
},
/////////	UPLOAD 
upload : function (event) {
	console.log("ParameterRow.upload     plugins.files.Menu.upload(event)");
	console.log("ParameterRow.upload     this: " + this);
	console.log("ParameterRow.upload     event: " + event);

	// SET THE PATH AS THE WORKFLOW FOLDER		
	var path = this.project + "/" + this.workflow;
	console.log("ParameterRow.upload     path: " + path);
	if ( path == null || path == '' )	return;

	this.uploader.path = path;
	this.uploader.show();
	dojo.stopEvent(event);
	
	var thisObject = this;
    this.uploader.onComplete = function(/* Object */customEvent){
        thisObject.onComplete(customEvent);
    }
},
onComplete : function (customEvent) {
// 		Fires when all files have uploaded
// 		Event is an array of all files

    ////////console.log("ParameterRow.onComplete    form.plugins.ParameterRow.onComplete(customEvent)");
    ////////console.log("ParameterRow.onComplete    customEvent: " + dojo.toJson(customEvent));	

	if ( ! customEvent.match(/\/([^\/]+)$/) ) 	return;
	var filename = customEvent.match(/\/([^\/]+)$/)[1];
	////////console.log("ParameterRow.onComplete    filename: " + dojo.toJson(filename));	
	var path = this.project + "/" + this.workflow + "/" + filename;
	////////console.log("ParameterRow.onComplete    path: " + dojo.toJson(path));	

	this.changeValue(this.valueNode, this.valueNode.value, path, "file");
},
/////////	VALUES
changeValue : function (node, oldValue, newValue, type) {
/* 1. DISPLAY THE NEW VALUE AND ADD IT TO Agua
// 2. CHECK THE FILE IS PRESENT
// 3. UPDATE THE STAGE DISPLAY IN THE WORKFLOW
//	TO REFLECT THE STATE OF COMPLETENESS AND 
// 	VALIDITY OF ITS INPUTS  */
	//console.log("ParameterRow.changeValue     plugins.workflow.ParameterRow.changeValue(node, oldValue, newValue)");
	//console.log("ParameterRow.changeValue     node: " + node);
	//console.log("ParameterRow.changeValue     newValue: " + newValue);
	//console.log("ParameterRow.changeValue     oldValue: " + oldValue);
	//console.log("ParameterRow.changeValue     type: " + type);
	//console.log("ParameterRow.changeValue     this.valuetype: " + this.valuetype);

	// IF SOMETHING WENT WRONG, USE THE OLD VALUE
	if ( newValue == null || newValue == '' || newValue == oldValue )
	{
		//console.log("ParameterRow.changeValue    newValue is empty or newValue == oldValue. Either upload was aborted or the files have the same name. Returning.");

		// PUT THE OLD VALUE BACK IN THE TABLE
		node.innerHTML = oldValue;
		return;
	}
	
	// PUT THE VALUE IN THE TABLE
	node.innerHTML = newValue;

	// SAVE THIS OPTION VALUE FOR THE WORKFLOW TO THE SERVER
	this.parameterObject.value = newValue;
	//console.log("ParameterRow.changeValue     this.parameterObject: ");
	//console.dir(this.parameterObject);
	
	// SET USER NAME TO COMPLETE stageparameter UNIQUE KEY
	this.parameterObject.username = Agua.cookie('username');
	
	// ADD STAGE PARAMETER		
	//console.log("ParameterRow.changeValue     Doing Agua.addStageParameter(this.parameterObject)");
	Agua.addStageParameter(this.parameterObject);

	// SET FILE PRESENT CSS
	this.filePresent(node);

	// CHECK TYPE MATCHES E.G., EXPECTED DIRECTORY AND FOUND DIRECTORY
	// IF TYPE DOES NOT MATCH, SET AS INVALID AND REQUIRED
	if ( this.valuetype.substring(0,4) != type.substring(0,4) )
	{
		//console.log("ParameterRow.changeValue     type (" + type + ") does not match this.valuetype (" + this.valuetype + ") ");

		//// ALTHOUGH FILE EXISTS, IF ITS THE WRONG TYPE,
		// SET THIS INPUT AS VALID
		this.validInput = false;

		// SET VALID CSS
		this.setInvalid(node);

		// SET STAGE PARAMETER'S isValid AS TRUE
		//console.log("ParameterRow.handleCheckfile    File found where directory wanted (or vice-versa). Setting stageParameter.isValid to FALSE");
		Agua.setParameterValidity(this, false);

	}
	else
	{
		//console.log("ParameterRow.changeValue     type (" + type + ") matches this.valuetype (" + this.valuetype + ") ");
		// SET THIS INPUT AS VALID
		this.validInput = true;

		// REMOVE RED BORDER (.infopane .invalid OR .infopane .input .required)
		this.setValid(node);
		
		// SET STAGE PARAMETER'S isValid AS TRUE
		//console.log("ParameterRow.handleCheckfile    File found where wanted. Setting stageParameter.isValid to TRUE");
		Agua.setParameterValidity(this, true);
	}
	
	// UPDATE this.validInputs IN PARENT INFOPANE WIDGET
	//console.log("ParameterRow.changeValue     DOING this.core.parameters.checkValidInputs()");
	this.core.parameters.checkValidInputs();		
},
addValue : function (node, oldValue, newValue, type) {
/* 1. DISPLAY THE NEW VALUE AND ADD IT TO Agua
// 2. CHECK THE FILE IS PRESENT
// 3. UPDATE THE STAGE DISPLAY IN THE WORKFLOW
//	TO REFLECT THE STATE OF COMPLETENESS AND 
// 	VALIDITY OF ITS INPUTS  */
	//console.log("ParameterRow.addValue     plugins.workflow.ParameterRow.addValue(node, oldValue, newValue)");
	//console.log("ParameterRow.addValue     node: " + node);
	//console.log("ParameterRow.addValue     newValue: " + newValue);
	//console.log("ParameterRow.addValue     oldValue: " + oldValue);
	//console.log("ParameterRow.addValue     type: " + type);
	//console.log("ParameterRow.addValue     this.valuetype: " + this.valuetype);

	// IF SOMETHING WENT WRONG, USE THE OLD VALUE
	if ( newValue == null || newValue == '' || newValue == oldValue )
	{
		//console.log("ParameterRow.addValue    newValue is empty or newValue == oldValue. Either upload was aborted or the files have the same name. Returning.");

		// PUT THE OLD VALUE BACK IN THE TABLE
		node.innerHTML = oldValue;
		return;
	}

	// ADD NEW VALUE TO OLD VALUE
	if ( oldValue ) newValue = oldValue + "," + newValue;
	
	// SET INPUT VALUE TO NEW VALUE
	node.innerHTML = newValue;

	// SAVE THIS OPTION VALUE FOR THE WORKFLOW TO THE SERVER
	//console.log("ParameterRow.addValue     Doing Agua.addStageParameter(stageParameterObject)");
	var stageParameterObject = new Object;
	for ( var key in this.passedArgs )
	{
		if ( key != "core" )
			stageParameterObject[key] = this.passedArgs[key];
	}
	stageParameterObject.value = newValue;
	//console.log("ParameterRow.addValue     stageParameterObject: ");
	//console.dir({stageParameterObject:stageParameterObject});

	// REMOVE UPLOADER
	delete stageParameterObject.uploader;
	
	// SET USER NAME TO COMPLETE stageparameter UNIQUE KEY
	stageParameterObject.username = Agua.cookie('username');
	
	// ADD STAGE PARAMETER		
	Agua.addStageParameter(stageParameterObject);

	// SET FILE PRESENT CSS
	this.filePresent(node);

	// CHECK TYPE MATCHES E.G., EXPECTED DIRECTORY AND FOUND DIRECTORY
	// IF TYPE DOES NOT MATCH, SET AS INVALID AND REQUIRED
	if ( this.valuetype != type )
		//|| ( this.valuetype == "file" && oldValue != '' )
		//|| ( this.valuetype == "directory" && oldValue != '')  )
	{
		//console.log("ParameterRow.addValue     Input types do not match. Doing this.setInvalid(node)");

		// SET THIS INPUT AS VALID
		this.validInput = false;

		// SET VALID CSS
		this.setInvalid(node);

		//// SET INPUT REQUIRED CSS IF essential OR required
		//if ( this.discretion == "essential" || this.discretion == "required" )
		//	this.inputRequired(node);

		// SET STAGE PARAMETER'S isValid AS TRUE
		//console.log("ParameterRow.handleCheckfile    File found where directory wanted (or vice-versa). Setting stageParameter.isValid to FALSE");
		Agua.setParameterValidity(this, false);
	}
	else
	{
		//console.log("ParameterRow.addValue     Input types match. Doing this.setValid(node)");

		// SET THIS INPUT AS VALID
		this.validInput = true;

		// REMOVE RED BORDER (.infopane .invalid OR .infopane .input .required)
		this.setValid(node);
		
		// SET INPUT SATISFIED CSS
		if ( this.discretion == "essential" || this.discretion == "required" )
			this.inputSatisfied(node);
		
		// SET STAGE PARAMETER'S isValid AS TRUE
		//console.log("ParameterRow.handleCheckfile    File found where wanted. Setting stageParameter.isValid to TRUE");
		Agua.setParameterValidity(this, true);
	}
	
	// UPDATE this.validInput AND required|satisfied NODE CSS
	//console.log("ParameterRow.handleCheckfile    File found where wanted. Setting stageParameter.isValid to TRUE");

	var thisObj = this;
	setTimeout(function(){
		//console.log("ParameterRow.handleCheckfile    Doing setTimeout thisObj.checkFile(" + node + ", " + newValue + ")");
		thisObj.checkFile(node, newValue)
	}, 100, this);

	////////// UPDATE required|satisfied NODE CSS
	
	
	// UPDATE this.validInputs IN PARENT INFOPANE WIDGET
	//console.log("ParameterRow.addValue     DOING this.core.parameters.checkValidInputs()");
	this.core.parameters.checkValidInputs();		
},
filePresent : function (node) {
	////console.log("ParameterRow.filePresent(node)");
	////console.log("ParameterRow.filePresent    node: " + node);
	dojo.removeClass(node, 'fileMissing');
	dojo.addClass(node, 'filePresent');
},
fileMissing : function (node) {
	////console.log("ParameterRow.fileMissing(node)");
	////console.log("ParameterRow.fileMissing    node: " + node);
	dojo.removeClass(node, 'filePresent');
	dojo.addClass(node, 'fileMissing');
},
setInvalid : function (node) {
	//console.group("ParameterRow-" + this.id + "    setInvalid");
	//console.dir({node:node});
	var caller = this.setInvalid.caller.nom;
	//console.log("ParameterRow.setInvalid    caller: " + caller);
	//console.log("ParameterRow.setInvalid    this.discretion: " + this.discretion);
	
	dojo.addClass(node, 'invalid');
	dojo.addClass(this.domNode, 'invalid');

	if ( this.discretion == "required" || this.discretion == "essential" )
	{
		//console.log("ParameterRow.setValid    Setting required");
		dojo.removeClass(node, 'satisfied');
		dojo.addClass(node, 'required');
		dojo.removeClass(this.domNode, 'satisfied');
		dojo.addClass(this.domNode, 'required');
	}

	//console.groupEnd("ParameterRow-" + this.id + "    setInvalid");
},
setValid : function (node) {
	//console.group("ParameterRow-" + this.id + "    setValid");
	//console.dir({node:node});
	var caller = this.setValid.caller.nom;
	//console.log("ParameterRow.setValid    caller: " + caller);
	//console.log("ParameterRow.setValid    this.discretion: " + this.discretion);
	
	dojo.removeClass(node, 'invalid');
	dojo.removeClass(this.domNode, 'invalid');

	if ( this.discretion == "essential"
		|| this.discretion == "required" )
	{
		//console.log("ParameterRow.setValid    Setting satisfied");
		dojo.removeClass(node, 'required');
		dojo.addClass(node, 'satisfied');
		dojo.removeClass(this.domNode, 'required');
		dojo.addClass(this.domNode, 'satisfied');
	}

	//console.groupEnd("ParameterRow-" + this.id + "    setValid");
},
/////////	TOGGLE 
setToggle : function () {
	// CONNECT TOGGLE EVENT
	var parameterRowObject = this;
	dojo.connect( this.nameNode, "onclick", function(event) {
		//////console.log("ParameterRow.setToggle    fired event");
		event.stopPropagation();
		parameterRowObject.toggle();
	});
},
toggle : function () {
	//////////console.log("ParameterRow.toggle    plugins.workflow.ParameterRow.toggle()");
	//////console.log("ParameterRow.toggle    this.description: " + this.description);
	//////console.log("ParameterRow.toggle    this.paramtype: " + this.paramtype);
	
	// TOGGLE HIDDEN TABLE
	// TO MAKE LAST ROW TAKE UP ALL OF THE REMAINING SPACE
	if ( this["hidden"].style.display == 'table' ) this["hidden"].style.display='none';
	else this["hidden"].style.display = 'table';

	// TOGGLE HIDDEN ELEMENTS
	//var array = [ "description", "notes" ];
	var array = ["descriptionNode", "typeNode", "typeTitle"];
	for ( var i in array )
	{
		if ( this[array[i]].style.display == 'table-cell' ) this[array[i]].style.display='none';
		else this[array[i]].style.display = 'table-cell';
	}
	
	// DO SPECIAL TOGGLE FOR UPLOAD AND BROWSE BUTTONS
	// DEPENDING ON PARAMETER TYPE: file OR directory
	var buttons;
	var end = 0;
	if ( this.paramtype == "input" )
	{
		buttons = ["browseButton", "downloadButton", "uploadButton", "fileInputMask"];
		if ( this.valuetype == "file" || this.valuetype == "files" )	end = 4;
		if ( this.valuetype == "directory" || this.valuetype == "directories" )	end = 1;
		//if ( this.valuetype == "integer" )	end = 0;
		//if ( this.valuetype == "string" )	end = 0;
		//if ( this.valuetype == "flag" )	end = 0;
		
		// REMOVE UPLOAD IF this.core.parameters SHARED IS TRUE
		if ( this.core.parameters.shared == true
				&& end == 4 )
		{
			end = 2;
		}		
	}
	else if ( this.paramtype == "output" )
	{
		buttons = ["browseButton", "downloadButton"];
		if ( this.valuetype == "file" ) end = 2;
	}
	
	//////console.log("ParameterRow.toggle    this.paramtype: " + this.paramtype);
	//////console.log("ParameterRow.toggle    buttons: " + dojo.toJson(buttons));
	//////console.log("ParameterRow.toggle    this.valuetype: " + this.valuetype);

	// DO TOGGLE
	for ( var i = 0; i < end; i++ )
	{
		////////console.log("ParameterRow.toggle    DOING toggle for this.buttons[" + i + "]");
		//////console.log("ParameterRow.toggle    this[" + buttons[i] + "]" + this[buttons[i]]);

		if ( this[buttons[i]].style.display == 'table-cell' ) this[buttons[i]].style.display='none';
		else this[buttons[i]].style.display = 'table-cell';
	}
}

});

