dojo.provide("plugins.workflow.StageRow");

dojo.require("plugins.core.Common");

dojo.declare( "plugins.workflow.StageRow",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/templates/stagerow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins") + "/workflow/css/stagerow.css" ],

// PARENT plugins.workflow.Apps WIDGET
parentWidget : null,

// APPLICATION OBJECT
application : null,

// CORE WORKFLOW OBJECTS
core : null,

/////}}}}}
constructor : function(args) {
	////console.log("StageRow.constructor    " + this.id);
	
	this.loadCSS();

	this.core = args.core;
	this.parentWidget = args.parentWidget;

	this.application = new Object;
	for ( var key in args )
	{
		if ( key != "parentWidget" )
		{
			this.application[key] = args[key];
		}
	}
	//////////console.log("StageRow.constructor    this.application: " + dojo.toJson(this.application));
	
	//this.inherited(arguments);
},
postCreate : function() {
	this.startup();
},
startup : function () {
/* SET this.name.parentWidget = this
  
	FOR RETRIEVAL OF this.application WHEN MENU IS CLICKED
	
	REM: remove ONCLICK BUBBLES ON stageRow.name NODE RATHER THAN ON node. 

	I.E., CONTRARY TO DESIRED, this.name IS THE TARGET INSTEAD OF THE node.
	
	ALSO ADDED node.parentWidget = stageRow IN Workflows.updateDropTarget()

*/
	//console.group("stageRow-" + this.id + "    startup");
	//console.dir({application:this.application});
	//////////console.log("StageRow.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);
	
	this.name.parentWidget = this;
	//////////console.log("StageRow.startup    this.name.parentWidget: " + this.name.parentWidget);
	
	this.setNumber(this.application.number);

	this.setSubmitStyle(this.application.submit);

	//console.groupEnd("stageRow-" + this.id + "    startup");
},
setSubmitStyle : function (submit) {
	//console.log("StageRow.setSubmitStyle     submit: " + submit)
	if ( submit == 1 ) {
		//console.log("StageRow.setSubmitStyle     DOING dojo.addClass(this.domNode, 'submit')")
		dojo.addClass(this.domNode, "submit");
	}
	else {
		//console.log("StageRow.setSubmitStyle     DOING dojo.removeClass(this.domNode, 'submit')")
		dojo.removeClass(this.domNode, "submit");
	}
	
},
checkValidParameters : function (force) {
	//console.group("stageRow-" + this.id + "    checkValidParameters");
	//console.log("StageRow.checkValidParameters    caller: " + this.checkValidParameters.caller.nom);

	// CHECK ALL PARAMETERS. COLLECT FILES IN this.fileStageParameters
	this.checkAllParameters(force);
	
	//console.log("StageRow.checkValidParameters    AFTER this.checkAllParameters(force)");
	//console.log("StageRow.checkValidParameters    this.fileStageParameters.length: " + this.fileStageParameters.length);
	
	if ( this.fileStageParameters.length != 0 )
		this.checkFiles();
	else
		this.checkRunStatus();

	//console.groupEnd("stageRow-" + this.id + "    checkValidParameters");
},
checkRunStatus : function() {
	//console.log("StageRow.checkRunStatus    plugins.workflow.StageRow.checkRunStatus");
	
	// DEBUG:
	if ( this.core.runStatus == null )	return;

	// CHECK IF STAGES ARE RUNNING
	//console.log("Parameters.load     BEFORE this.core.userWorkflows.indexOfRunningStage()");
	var indexOfRunningStage = this.core.userWorkflows.indexOfRunningStage();
	//console.log("Parameters.load     indexOfRunningStage: " + indexOfRunningStage);
	var runner = this.core.runStatus.createRunner(indexOfRunningStage);	
	var singleton = true;
	var selectTab = false;	
	//console.log("Parameters.load     DOING runStatus.getStatus");
	this.core.runStatus.getStatus(runner, singleton, selectTab);
},
checkAllParameters : function (force) {
/*	CHECK ALL THE PARAMETERS HAVE VALID INPUTS AND CHANGE CSS ACCORDINGLY.
 	
 	RETURN VALUE OF validInputs AS true IF ALL PARAMETERS ARE SATISFIED.
 	
 	OTHERWISE, RETURN false.
 	
	PROCESS FOR CHECKING VALIDITY FOR EACH PARAMETER

		1. SET this.validInputs TO TRUE, UPDATE ALONG THE WAY

		2. CHECK ONLY inputs (IGNORE outputs AND resources).
		
		3. FOR EACH INPUT:
	
			3.1 CHECK IF VALIDITY HAS ALREADY BEEN COMPUTED AND STORED
			
				IN Agua.getParameterValidity BOOLEAN. USE IF AVAILABLE AND NEXT 
		
			3.2 OTHERWISE, SET Agua.setParameterValidity FOR EACH
			
				PARAMETER AS FOLLOWS:
				
				a. IF FILE/DIR, IGNORE IF OPTIONAL UNLESS FILEPATH SPECIFIED
			
				b. IF NON-OPTIONAL FILE/DIR, ADD TO ARRAY OF FILES TO BE
				
					PASSED TO checkFiles
				
				c. IGNORE FLAGS, CHECK INTS AND NON-OPTIONAL TEXT
				
			3.3 RUN checkFiles FOR UNKNOWN FILES/DIRS:
			
				a. DO A BATCH FILE CHECK ON THE REMOTE SERVER. 
			
				b. SET validInputs TO FALSE IF ANY FILES/DIRS ARE MISSING
				
		4. ADJUST CSS CLASS OF StageRow ACCORDING TO VALUE OF validInputs
		
		5. RETURN BOOLEAN VALUE OF validInputs
		
*/

	//console.group("stageRow-" + this.id + "    checkAllParameters");
	//console.log("StageRow.checkAllParameters    caller: " + this.checkAllParameters.caller.nom);
	//console.log("StageRow.checkAllParameters    this.force: " + this.force);

	// SET this.isValid TO DEFAULT true
	this.isValid = true;

	// GET STAGE PARAMETERS
	var parameterRows = new Array;
	var stageParameters = new Array;
	//console.log("StageRow.checkAllParameters    this.application: ");
	//console.dir({application:this.application});
	//console.log("StageRow.checkAllParameters    this.core.parameters.application:");
	//console.dir({parameters_application:this.core.parameters.application});

	if ( this.core.parameters != null 
		&& this.core.parameters.isCurrentApplication(this.application) ) {
		parameterRows = this.core.parameters.childWidgets;
		//console.log("StageRow.checkAllParameters    APPLICATIONS IS CURRENT APPLICATION [" + this.application.name + "].     parameterRows.length: " + parameterRows.length);
		for ( var i = 0; i < this.core.parameters.childWidgets.length; i++ )
		{
			stageParameters.push(this.core.parameters.childWidgets[i].parameterObject);
		}
	}
	else {
		//console.log("StageRow.checkAllParameters    APPLICATION IS NOT CURRENT APPLICATION");
		stageParameters = Agua.getStageParameters(this.application);
	}
	//console.log("StageRow.checkAllParameters    stageParameters.length: " + stageParameters.length);

	if ( stageParameters == null ) {
		//console.groupEnd("stageRow-" + this.id + "    checkAllParameters");
		return false;
	}
	
	// GET ALL REQUIRED/ESSENTIAL INPUT FILE/DIRECTORY PARAMETERS
	this.fileStageParameters = new Array;
	this.fileParameterRows = new Array;
	for ( var i = 0; i < stageParameters.length; i++ )
	{
		//console.log("StageRow.checkAllParameters    Processing parameter: " + stageParameters[i].name + " (discretion: " + stageParameters[i].discretion + ")");

		// ADD SYSTEM VARIABLES
		stageParameters[i].value = this.systemVariables(stageParameters[i].value, stageParameters[i]);

		// UNLESS force SPECIFIED, GET VALIDITY IF EXISTS
		// AND MOVE ON TO NEXT STAGE PARAMETER
		var isValid = Agua.getParameterValidity(stageParameters[i]);
		if ( force != true && isValid != null && isValid != false )
		{
			//console.log("StageRow.checkAllParameters   inside required/essential isValid: " + isValid);

			//console.log("StageRow.checkAllParameters    isValid IS DEFINED and force != true");
			if ( parameterRows[i] != null )
			{
				//console.log("StageRow.checkValidFile    DOING parameterRow.setValid(node)");
				if ( isValid == true )
					parameterRows[i].setValid(parameterRows[i].containerNode);
				else {
					parameterRows[i].setInvalid(parameterRows[i].containerNode);
					this.isValid = false;
				}
			}
			//console.log("StageRow.checkAllParameters    End of processing parameter: " + stageParameters[i].name);

			continue;
		}

		// FLAGS ARE AUTOMATICALLY VALID
		else if ( stageParameters[i].valuetype == "flag" )
			continue;
		
		// SAVE UNKNOWN FILE/DIRECTORY FOR checkFiles LATER ON
		if ( stageParameters[i].valuetype == "file"
			||  stageParameters[i].valuetype == "directory" )
			this.checkValidFile(stageParameters[i], parameterRows[i]);

		// CHECK INTEGERS
		else if ( stageParameters[i].valuetype == "integer" )
			this.checkValidInteger(stageParameters[i], parameterRows[i]);

		// CHECK TEXT INPUTS
		else
			this.checkValidText(stageParameters[i], parameterRows[i]);
	}

	if ( this.fileStageParameters.length == 0 )
	{
		//console.log("StageRow.checkAllParameters    'this.fileStageParameters' is empty. Returning");	
		//console.log("StageRow.checkAllParameters    No filecheck required. FINAL this.isValid: " + this.isValid);
		
		if ( this.isValid == false || this.isValid == null )
			this.setInvalid();
		else this.setValid();

		//console.groupEnd("stageRow-" + this.id + "    checkFileParameters");
		return this.isValid;
	}

	//console.log("StageRow.checkAllParameters    this.fileStageParameters.length: " + this.fileStageParameters.length);
	//console.log("StageRow.checkAllParameters    this.fileParameterRows.length: " + this.fileParameterRows.length);
	//console.log("StageRow.checkAllParameters    END. this.fileParameterRows:");
	//console.dir({fileParameterRows:this.fileParameterRows});			
	//console.log("StageRow.checkAllParameters    END. this.fileStageParameters:");
	//console.dir({fileStageParameters:this.fileStageParameters});			


	//console.groupEnd("stageRow-" + this.id + "    checkAllParameters");
},
currentParametersApplication : function (application) {
	////console.log("StageRow.currentParametersApplication    StageRow.currentParametersApplication(application)");

	var keys = ["project", "workflow", "workflownumber", "name", "number"];
	return this._objectsMatchByKey(application, this.core.parameters.application, keys);	
},
checkFiles : function (files) {
	//console.group("stageRow-" + this.id + "    checkFiles");
	////console.log("StageRow.checkFiles    caller: " + this.checkFiles.caller.nom);
	////console.log("StageRow.checkFiles    StageRow.checkFiles(files)");
	////console.log("StageRow.checkFiles    this.checkFiles.caller.nom: " + this.checkFiles.caller.nom);
	////console.dir({caller: this.checkFiles.caller});
	////console.log("StageRow.checkFiles    this.fileStageParameters.length: " + this.fileStageParameters.length);
	////console.log("StageRow.checkFiles    this.fileParameterRows.length: " + this.fileParameterRows.length);

	if ( files == null )	files = this.fileStageParameters;
	////console.log("StageRow.checkFiles    this.fileStageParameters: " + this.fileStageParameters.length);
	//////console.log("StageRow.checkFiles    'this.fileStageParameters': " + dojo.toJson(this.fileStageParameters, true));
	////console.log("StageRow.checkFiles    BEFORE xhrPut this.isValid: " + this.isValid);
	
	// GET FILEINFO FROM REMOTE FILE SYSTEM
	var url = Agua.cgiUrl + "agua.cgi";
	var query 			= 	new Object;
	query.username = Agua.cookie('username');
	query.sessionid = Agua.cookie('sessionid');
	query.project 		= 	this.application.project;
	query.workflow 		= 	this.application.workflow;
	query.mode = "checkFiles";
	query.module = "Agua::Sharing";
	query.files 		= 	files;
	//console.log("StageRow.checkFiles    query: ");
	//console.dir({query:query});

	// SEND TO SERVER
	var thisObject = this;
	var xhrputReturn = dojo.xhrPut({
		url				: url,
		contentType		: "text",
		sync 			: false,
		handleAs		: "json",
		putData			: dojo.toJson(query),
		handle			: function(fileinfos, ioArgs) {
			thisObject.validateFiles(files, fileinfos);
			//console.log("StageRow.checkFiles    fileinfos: ");
			//console.dir({fileinfos:fileinfos});
			
			if ( thisObject.core.parameters != null 
				&& thisObject.core.parameters.isCurrentApplication(thisObject.application) ) {
				//console.log("StageRow.checkFiles    Doing checkRunStatus()");
				thisObject.checkRunStatus();
			}
		
			//console.groupEnd("stageRow-" + thisObject.id + "    checkFiles");
		}
	});	

	////console.log("StageRow.checkFiles    BEFORE setting stageRow CSS, FINAL this.isValid: " + this.isValid);	
	if ( this.isValid == false || this.isValid == null ) this.setInvalid();
	else this.setValid();

	return this.isValid;
},
validateFiles : function (fileinfos) {
	//console.group("stageRow-" + this.id + "    validateFiles");
	//console.log("StageRow.validateFiles    caller: " + this.validateFiles.caller.nom);
	//console.log("StageRow.validateFiles    fileinfos: ");
	//console.dir({fileinfos:fileinfos});
	//console.log("StageRow.validateFiles    this.fileParameterRows:");
	//console.dir({parameterRows:this.parameterRows});
	//console.log("StageRow.validateFiles    this.fileParameterRows:");
	//console.dir({fileParameterRows:this.fileParameterRows});			

	if ( fileinfos == null
		|| fileinfos.length == null
		|| ! fileinfos.length )
		return;
		
	for ( var i = 0; i < fileinfos.length; i++ )
	{
		//console.log("StageRow.validateFiles    fileinfos[" + i + "]: ");
		//console.dir({fileinfo:fileinfos[0]});
		var parameterRow = this.fileParameterRows[i];
		//console.log("StageRow.validateFiles    parameterRow: " + parameterRow);
//		if ( ! parameterRow || ! this.fileStageParameters )	return;
		
		// SET FILE INFO
		if ( this.fileStageParameters && this.fileStageParameters[i])
			Agua.setFileInfo(this.fileStageParameters[i], fileinfos[i]);
		
		if ( fileinfos[i].exists == "true" )
		{
			if ( fileinfos[i].type != this.fileStageParameters[i].valuetype )
			{
				// SET PARAMETER VALIDITY AS FALSE
				//console.log("StageRow.validateFiles    File/dir mismatch. Setting parameter validity as FALSE");
				Agua.setParameterValidity(this.fileStageParameters[i], false);
				this.isValid = false;
				if ( parameterRow != null )
				{
					//console.log("StageRow.validateFiles    DOING parameterRow.setInvalid(node)");
					parameterRow.setInvalid(parameterRow.containerNode);
				}
			}
			else {
				// SET PARAMETER VALIDITY AS TRUE
				//console.log("StageRow.validateFiles    paramtype matches. Setting parameter validity as TRUE");
				Agua.setParameterValidity(this.fileStageParameters[i], true);
				if ( parameterRow != null )
				{
					//console.log("StageRow.validateFiles    DOING parameterRow.setValid(containerNode)");
					//console.dir({containerNode:parameterRow.containerNode});
					parameterRow.setValid(parameterRow.containerNode);
				}
			}
		}
		else
		{
			if ( this.fileStageParameters[i].discretion == "essential" )
			{
				//console.log("StageRow.validateFiles    file '" + this.fileStageParameters[i].name + "' (discretion: " + this.fileStageParameters[i].discretion + ") does not exist. Setting stageParameter.isValid to FALSE");
				
				this.isValid = false;

				// DO Agua.setParameterValidity
				Agua.setParameterValidity(this.fileStageParameters[i], false);
				if ( parameterRow != null )
				{
					//console.log("StageRow.validateFiles    DOING parameterRow.setInvalid(node)");
					//console.dir({containerNode:parameterRow.containerNode});
					parameterRow.setInvalid(parameterRow.containerNode);
				}
			}
			else
			{
				// DO Agua.setParameterValidity
				Agua.setParameterValidity(this.fileStageParameters[i], true);
				if ( parameterRow != null )
				{
					//console.log("StageRow.validateFiles    DOING parameterRow.setValid(node)");
					//console.dir({containerNode:parameterRow.containerNode});
					parameterRow.setValid(parameterRow.containerNode);
				}
			}
		}
	}
	//console.log("StageRow.validateFiles    FINAL (w/o fileCheck) this.isValid: " + this.isValid);

	if ( this.isValid == false )
		this.setInvalid();
	else
		this.setValid();

	//console.groupEnd("stageRow-" + this.id + "    validateFiles");
},
checkValidFile : function (stageParameter, parameterRow) {
// LOAD UNKNOWN FILES INTO this.fileStageParameters AND this.fileParameterRows

	////console.group("StageRow-" + this.id + "    checkValidFile");
	//console.log("StageRow.checkValidFile     StageRow.checkValidFile(stageParameter)");
	//console.log("StageRow.checkValidFile     stageParameter: ");
	//console.dir({stageParameter:stageParameter});
	//console.log("StageRow.checkValidFile    stageParameter.name: " + stageParameter.name);
	
	var filepath = stageParameter.value;
	//console.log("StageRow.checkValidFile     Checking files/dirs");

	// CHECK NON-OPTIONAL FILEPATHS
	// required: FILE PATH MUST BE NON-EMPTY
	// essential: FILE/DIRECTORY MUST BE PHYSICALLY PRESENT
	if ( stageParameter.discretion == "required"
		|| stageParameter.discretion == "essential" )
	{
		//console.log("StageRow.checkValidFile     Parameter is required/essential");

		// SET this.isValid = false IF FILE/DIR IS NULL OR EMPTY
		if ( filepath == null || filepath == '' )
		{
			//console.log("StageRow.checkValidFile    Non-optional file/dir is null or empty.");
			//console.log("StageRow.checkValidFile    Setting stageParameter.parameterIsValid to FALSE.");
			this.setInvalidParameter(stageParameter, parameterRow);
		}

		// ADD TO this.fileStageParameters ARRAY IF NO fileinfo
		else if ( stageParameter.fileinfo == null )
		{
			//console.log("StageRow.checkValidFile    stageParameter.fileinfo is null. Pushing to fileStageParameters");
			//console.log("StageRow.checkValidFile    stageParameter: ");
			//console.dir({stageParameter:stageParameter});
			//console.log("StageRow.checkValidFile    parameterRow: ");
			//console.dir({parameterRow:parameterRow});
			
			this.fileStageParameters.push(stageParameter);
			this.fileParameterRows.push(parameterRow);
		}

		// FILE/DIR IS SPECIFIED BUT KNOWN TO NOT EXIST
		else if ( stageParameter.fileinfo.exists == "false" )
		{
			//console.log("StageRow.checkValidFile    Non-optional file/dir stageParameter.fileinfo.exists: " + stageParameter.fileinfo.exists);

			// PUSH ONTO this.fileStageParameters IF CHAINED = 0
			if ( stageParameter.chained == null
				|| stageParameter.chained == 0 )
			{
				//console.log("StageRow.checkValidFile    stageParameter.chained is 0 or null");
	 			//console.log("StageRow.checkValidFile    Pushing onto this.fileStageParameters");
				//console.log("StageRow.checkValidFile    stageParameter: ");
				//console.dir({stageParameter:stageParameter});
				//console.log("StageRow.checkValidFile    parameterRow: ");
				//console.dir({parameterRow:parameterRow});
				this.fileStageParameters.push(stageParameter);
				this.fileParameterRows.push(parameterRow);
			}
			
			// OTHERWISE, USE EXISTING PARAMETER VALIDITY INFO
			// TO SET THE VALIDITY OF THE PARAMETER ROW AND IGNORE
			// WHETHER OR NOT IT EXISTS (CHAINING IS THE PROMISE
			// THAT IT WILL EXIST ONCE THE PREVIOUS STAGE IS DONE.)
			else {
				//console.log("StageRow.checkValidFile    stageParameter.chained: " + stageParameter.chained);
				//console.log("StageRow.checkValidFile    Doing this.setValidParameter()");
				this.setValidParameter(stageParameter, parameterRow);
			}
		}
		
		// FILE/DIR IS SPECIFIED AND KNOWN TO EXIST
		else {
			//console.log("StageRow.checkValidFile    File/dir exists.");
			if ( stageParameter.fileinfo.type != stageParameter.valuetype )
			{
				// SET PARAMETER VALIDITY AS FALSE
				//console.log("StageRow.checkValidFile    File/dir mismatch. Setting parameter validity as FALSE");
				this.setInvalidParameter(stageParameter, parameterRow);
			}
			else {
				// SET PARAMETER VALIDITY AS TRUE
				//console.log("StageRow.checkValidFile    Paramtype matches. Setting parameter validity as TRUE");
				this.setValidParameter(stageParameter, parameterRow);
			}
		}
	}
	
	// IT'S AN OPTIONAL PARAMETER SO IT'S VALID IF EMPTY.
	// BUT IF ITS NOT EMPTY, CHECK IT EXISTS.
	else 
	{
		// IF EMPTY 
		if ( stageParameter.value == null
			|| stageParameter.value == '' )
		{
			//console.log("StageRow.checkValidFile    Ignoring empty optional file/dir parameter");
			this.setValidParameter(stageParameter, parameterRow);
		}
		else
		{
			//console.log("StageRow.checkValidFile    Optional file/dir parameter is specified. Pushing onto this.fileStageParameters array");
			//console.log("StageRow.checkValidFile    stageParameter: ");
			//console.dir({stageParameter:stageParameter});
			//console.log("StageRow.checkValidFile    parameterRow: ");
			//console.dir({parameterRow:parameterRow});
			this.fileStageParameters.push(stageParameter);
			this.fileParameterRows.push(parameterRow);
		}
	}

	////console.log("StageRow.checkValidFile    END. this.fileParameterRows:");
	////console.dir({fileParameterRows:this.fileParameterRows});			
	////console.log("StageRow.checkValidFile    END. this.fileStageParameters:");
	////console.dir({fileStageParameters:this.fileStageParameters});			
		
	//console.groupEnd("StageRow-" + this.id + "    checkValidFile");
},
checkValidInteger : function (stageParameter, parameterRow) {
	//console.log("StageRow.checkValidInteger     StageRow.checkValidInteger(stageParameter)");
	////console.log("StageRow.checkValidInteger     stageParameter: " + dojo.toJson(stageParameter));
	if ( stageParameter.discretion != "optional" )
	{
		// SET EMPTY NON-OPTIONAL INTEGER AS FALSE
		if ( stageParameter.value == null
				|| stageParameter.value == '' )
		{
			////console.log("StageRow.checkValidParameters      '" + stageParameter.name + "' Non-optional INTEGER input is empty. Setting this.isValid to FALSE");
			this.setInvalidParameter(stageParameter, parameterRow);
		}
		// NON-OPTIONAL INTEGER BUT IS NOT A PROPER NUMBER
		// ////SO SET TO false
		else if (! stageParameter.value.match(/^\s*[\d\.]+\s*$/) )
		{
			////console.log("StageRow.checkValidParameters      '" + stageParameter.name + "' Non-optional INTEGER input not valid. Setting this.isValid to FALSE");
			this.isValid = false;
			Agua.setParameterValidity(stageParameter, false);
		}
		// OTHERWISE, ITS A CORRECT OPTIONAL INTEGER SO SET TO true
		else
		{
			this.setValidParameter(stageParameter, parameterRow);
		}
	}
	else
	{
		// SET OPTIONAL INTEGER TO false IF ITS NON-EMPTY BUT NOT
		// AN INTEGER
		if ( stageParameter.value != null
				&& stageParameter.value != ''
				&& ! stageParameter.value.match(/^\s*[\d\.]+\s*$/) )
		{
			////console.log("StageRow.checkValidParameters      '" + stageParameter.name + "' Optional INTEGER input not valid. Setting this.isValid to FALSE");
			this.setInvalidParameter(stageParameter, parameterRow);
		}
		
		// OTHERWISE, ITS EITHER EMPTY OR AN INTEGER SO SET TO true
		else
		{
			////console.log("StageRow.checkValidParameters      '" + stageParameter.name + "' Optional INTEGER input is empty. Setting this.isValid to TRUE");
			this.setValidParameter(stageParameter, parameterRow);
		}
	}
},
checkValidText : function (stageParameter, parameterRow) {
	////console.log("StageRow.checkValidText     StageRow.checkValidText(stageParameter)");
	////console.log("StageRow.checkValidText     stageParameter: " + dojo.toJson(stageParameter));
	if ( stageParameter.discretion != "optional" )
	{
		if ( stageParameter.value == null
			|| stageParameter.value == '' )
		{
			////console.log("StageRow.checkValidText      '" + stageParameter.name + "' Required text input is null or empty. Setting this.isValid to FALSE");
			this.setInvalidParameter(stageParameter, parameterRow);
		}
		else
		{
			////console.log("StageRow.checkValidText      '" + stageParameter.name + "' Required text input is satisfied. Setting this.isValid to TRUE");
			this.setValidParameter(stageParameter, parameterRow);
		}
	}
	else
	{
		// THIS IS AN OPTIONAL PARAMETER SO, EMPTY OR NOT, ITS VALID
		////console.log("StageRow.checkValidText      '" + stageParameter.name + "' Optional text parameter. Setting stageParameter.isValid to TRUE");
		this.setValidParameter(stageParameter, parameterRow);
	}
},
toggle : function () {
	//////console.log("StageRow.toggle    plugins.workflow.StageRow.toggle()");
	//////console.log("StageRow.toggle    this.description: " + this.description);

	var array = [ "executor", "localonly", "location", "description", "notes" ];
	for ( var i in array )
	{
		if ( this[array[i]].style.display == 'table-cell' ) this[array[i]].style.display='none';
		else this[array[i]].style.display = 'table-cell';
	}
},
setInvalidParameter : function (stageParameter, parameterRow) {
	//console.log("StageRow.setInvalidParameter    stageParameter.name: " + stageParameter.name);
	//console.log("StageRow.setInvalidParameter    parameterRow: " + parameterRow);

	this.isValid = false;
	Agua.setParameterValidity(stageParameter, false);
	if ( parameterRow != null)
		parameterRow.setInvalid(parameterRow.containerNode);
},
setValidParameter : function (stageParameter, parameterRow) {
	////console.log("StageRow.setValidParameter    stageParameter.name: " + stageParameter.name);
	Agua.setParameterValidity(stageParameter, true);
	if ( parameterRow != null)
		parameterRow.setValid(parameterRow.containerNode);
},
setValid : function () {
	//console.log("StageRow.setValid    SETTING node to SATISFIED: " + this.id);
	//console.log("StageRow.setValid    this.setValid.caller.nom: " + this.setValid.caller.nom);
	
	dojo.removeClass(this.domNode, 'unsatisfied');
	dojo.addClass(this.domNode, 'satisfied');
	
	this.isValid = true;
	var stagesWidget = this.core.userWorkflows;
	//console.log("StageRow.setValid    this.stagesWidget: " + this.stagesWidget);
	stagesWidget.updateRunButton();	
},
setInvalid : function () {
	//console.log("StageRow.setInvalid    SETTING node to UNSATISFIED: " + this.id);
	//console.log("StageRow.setInvalid    this.setInvalid.caller.nom: " + this.setInvalid.caller.nom);
	
	dojo.removeClass(this.domNode, 'satisfied');
	dojo.addClass(this.domNode, 'unsatisfied');
	
	this.isValid = false;
	var stagesWidget = this.core.userWorkflows;
	//console.log("StageRow.setInvalid    this.stagesWidget: " + this.stagesWidget);
	stagesWidget.updateRunButton();	
},
getApplication : function () {
// RETURN A COPY OF this.application
	return dojo.clone(this.application);
},
setApplication : function (application) {
// SET this.application TO THE SUPPLIED APPLICATION OBJECT
	this.application = application;

	return this.application;
},
setNumber : function (number) {
// SET THE NUMBER NODE TO THE stage.number 
	//console.log("StageRow.setNumber    plugins.workflow.StageRow.setNumber(" + number + ")");
	this.application.number = number;
	this.application.appnumber = number;
	this.numberNode.innerHTML = number;
}

});
