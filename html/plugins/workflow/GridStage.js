dojo.provide("plugins.workflow.GridStage");

dojo.require("plugins.core.Common");

dojo.declare( "plugins.workflow.GridStage",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
	/////}

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

postCreate : function() {
	this.startup();
},

constructor : function(args) {
	//console.log("GridStage.constructor    plugins.workflow.GridStage.constructor()");

	this.loadCSS();

	this.core = args.core;
	//console.log("GridStage.constructor    this.core: " + this.core);

	this.parentWidget = args.parentWidget;

	this.application = new Object;
	for ( var key in args )
	{
		if ( key != "parentWidget" )
		{
			this.application[key] = args[key];
		}
	}
	////console.log("GridStage.constructor    this.application: " + dojo.toJson(this.application));
	
	//this.inherited(arguments);
},

startup : function () {
	//console.log("GridStage.startup    plugins.workflow.GridStage.startup()");
	////console.log("GridStage.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);
	
	this.name.parentWidget = this;
	
	// CONNECT TOGGLE EVENT
	var thisObject = this;
	dojo.connect( this.nameNode, "onclick", function(event) {
		event.stopPropagation();
		thisObject.toggle();
	});
},

toggle : function () {
	//console.log("GridStage.toggle    plugins.workflow.GridStage.toggle()");
	var array = [ "executor", "submit", "location", "description" ];
	for ( var i in array )
	{
		var nodeName = array[i] + "Node";
		//console.log("GridStage.toggle    nodeName: " + nodeName);
		if ( this[nodeName].style.display == 'table-cell' )
			this[nodeName].style.display='none';
		else this[nodeName].style.display = 'table-cell';
	}
},


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
			
				b. IF NON-OPTIONAL FILE/DIR, ADD TO ARRAY OF files FOR checkFiles
			
				c. IGNORE FLAGS, CHECK INTS AND NON-OPTIONAL TEXT
				
			3.3 RUN checkFiles FOR UNKNOWN FILES/DIRS:
			
				a. DO A BATCH FILE CHECK ON THE REMOTE SERVER. 
			
				b. SET validInputs TO FALSE IF ANY FILES/DIRS ARE MISSING
				
		4. ADJUST CSS CLASS OF GridStage ACCORDING TO VALUE OF validInputs
		
		5. RETURN BOOLEAN VALUE OF validInputs
		
*/

checkAllParameters : function (force) {
	//console.log("GridStage.checkAllParameters     plugins.workflow.GridStage.checkAllParameters(force)");
	//console.log("GridStage.checkAllParameters    this.force: " + this.force);
	//console.log("GridStage.checkAllParameters    this.application.name: ****** " + this.application.name + " ******");

	// SET this.isValid TO DEFAULT true
	this.isValid = true;

	// GET STAGE PARAMETERS
	var parameterRows = new Array;
	var stageParameters = new Array;
	//console.log("GridStage.checkAllParameters    this.application: " + dojo.toJson(this.application));
	//console.log("GridStage.checkAllParameters    this.core.parameters.application: " + dojo.toJson(this.core.parameters.application));

	if ( this.core.parameters != null 
		&& this.core.parameters.isCurrentApplication(this.application) ) {
		parameterRows = this.core.parameters.childWidgets;
		//console.log("GridStage.checkAllParameters    APPLICATIONS IS CURRENT APPLICATION [" + this.application.name + "]. parameterRows.length: " + parameterRows.length);
		for ( var i = 0; i < this.core.parameters.childWidgets.length; i++ )
		{
			stageParameters.push(this.core.parameters.childWidgets[i].parameterObject);
		}
	}
	else {
		stageParameters = Agua.getStageParameters(this.application);
	}
	//console.log("GridStage.checkAllParameters    stageParameters.length: " + stageParameters.length);
	if ( stageParameters == null )	return false;

	// GET ALL REQUIRED/ESSENTIAL INPUT FILE/DIRECTORY PARAMETERS
	this.fileStageParameters = new Array;
	this.fileParameterRows = new Array;
	for ( var i = 0; i < stageParameters.length; i++ )
	{
		//if ( stageParameters[i].paramtype != "input" )	continue;

		// ADD SYSTEM VARIABLES		
		stageParameters[i].value = this.systemVariables(stageParameters[i].value, stageParameters[i]);
		////////////console.log("GridStage.checkAllParameters     [" + i + "] '"
		//////////////////	+ stageParameters[i].name + "'  ("
		//////////////////	+ stageParameters[i].valuetype + ", "
		//////////////////	+ stageParameters[i].discretion + ") value '"
		//////////////////	+ stageParameters[i].value + "', chained: "
		//////////////////	+ stageParameters[i].chained + " [fileinfo: "
		//////////////////	+ dojo.toJson(stageParameters[i].fileinfo) + "]");

		// UNLESS force SPECIFIED, GET VALIDITY IF EXISTS
		// AND MOVE ON TO NEXT STAGE PARAMETER
		var isValid = Agua.getParameterValidity(stageParameters[i]);
		if ( force != true && isValid != null )
		{
			//console.log("GridStage.checkAllParameters    isValid IS DEFINED and force != true");
			if ( parameterRows[i] != null )
			{
				//console.log("GridStage.checkValidFile    DOING parameterRow.setValid(node)");
				if ( isValid == true )
					parameterRows[i].setValid(parameterRows[i].containerNode);
				else {
					parameterRows[i].setInvalid(parameterRows[i].containerNode);
					this.isValid = false;
				}
			}
			//console.log("GridStage.checkAllParameters    End of processing parameter: " + stageParameters[i].name);

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

	//console.log("GridStage.checkAllParameters    this.fileStageParameters.length: " + this.fileStageParameters.length);	
	if ( this.fileStageParameters.length == 0 )
	{
		//console.log("GridStage.checkAllParameters    'this.fileStageParameters' is empty. Returning");	
		//console.log("GridStage.checkAllParameters    No filecheck required. FINAL this.isValid: " + this.isValid);
		
		if ( this.isValid == false || this.isValid == null )
			this.setInvalid();
		else this.setValid();

		return this.isValid;
	}

	//console.log("GridStage.checkAllParameters    this.fileStageParameters.length: " + this.fileStageParameters.length);
	//console.log("GridStage.checkAllParameters    this.fileParameterRows.length: " + this.fileParameterRows.length);

},

checkValidParameters : function (force) {
	this.checkAllParameters(force);
	if ( this.fileStageParameters.length != 0 )
		this.checkFiles();
},

currentParametersApplication : function (application) {
	//console.log("GridStage.currentParametersApplication    GridStage.currentParametersApplication(application)");

	var keys = ["project", "workflow", "workflownumber", "name", "number"];
	return this._objectsMatchByKey(application, this.core.parameters.application, keys);	
},

checkFiles : function (files) {
	//console.log("GridStage.checkFiles    GridStage.checkFiles(files)");
	//console.log("GridStage.checkFiles    this.checkFiles.caller.nom: " + this.checkFiles.caller.nom);
	//console.dir({caller: this.checkFiles.caller});

	//console.log("GridStage.checkFiles    this.fileStageParameters.length: " + this.fileStageParameters.length);
	//console.log("GridStage.checkFiles    this.fileParameterRows.length: " + this.fileParameterRows.length);

	if ( files == null )	files = this.fileStageParameters;
	//console.log("GridStage.checkFiles    this.fileStageParameters: " + this.fileStageParameters.length);
	//console.log("GridStage.checkFiles    'this.fileStageParameters': " + dojo.toJson(this.fileStageParameters, true));
	//console.log("GridStage.checkFiles    BEFORE xhrPut this.isValid: " + this.isValid);
	
	// GET FILEINFO FROM REMOTE FILE SYSTEM
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username = Agua.cookie('username');
	query.sessionid = Agua.cookie('sessionid');
	query.project = this.application.project;
	query.workflow = this.application.workflow;
	query.mode = "checkFiles";
	query.module 		= 	"Agua::Workflow";
	query.files = files;

	// SEND TO SERVER
	var thisObject = this;
	var xhrputReturn = dojo.xhrPut({
		url: url,
		contentType: "text",
		sync : false,
		handleAs: "json",
		putData: dojo.toJson(query),
		handle: function(fileinfos, ioArgs) {
			thisObject.validateFiles(files, fileinfos);
		}
	});	

	//console.log("GridStage.checkFiles    BEFORE setting stageRow CSS, FINAL this.isValid: " + this.isValid);	
	if ( this.isValid == false || this.isValid == null ) this.setInvalid();
	else this.setValid();
	
	return this.isValid;
},


validateFiles : function (fileinfos) {
	//console.log("GridStage.validateFiles    GridStage.validateFiles(fileinfos)");
	//console.log("GridStage.validateFiles    JSON fileinfos: " + dojo.toJson(fileinfos));
	if ( fileinfos == null
		|| fileinfos.length == null
		|| ! fileinfos.length )
		return;
		
	for ( var i = 0; i < fileinfos.length; i++ )
	{
		//console.log("GridStage.validateFiles    fileinfos[" + i + "]: " + dojo.toJson(fileinfos[i]));
		var parameterRow = this.fileParameterRows[i];
		//console.log("GridStage.validateFiles    parameterRow: " + parameterRow);

		// SET FILE INFO
		Agua.setFileInfo(this.fileStageParameters[i], fileinfos[i]);
		
		if ( fileinfos[i].exists == "true" )
		{
			if ( fileinfos[i].type != this.fileStageParameters[i].valuetype )
			{
				// SET PARAMETER VALIDITY AS FALSE
				//console.log("GridStage.validateFiles    File/dir mismatch. Setting parameter validity as FALSE");
				Agua.setParameterValidity(this.fileStageParameters[i], false);
				this.isValid = false;
				if ( parameterRow != null )
				{
					//console.log("GridStage.validateFiles    DOING parameterRow.setInvalid(node)");
					parameterRow.setInvalid(parameterRow.containerNode);
				}
			}
			else {
				// SET PARAMETER VALIDITY AS TRUE
				//console.log("GridStage.validateFiles    paramtype matches. Setting parameter validity as TRUE");
				Agua.setParameterValidity(this.fileStageParameters[i], true);
				if ( parameterRow != null )
				{
					//console.log("GridStage.validateFiles    DOING parameterRow.setValid(node)");
					//console.dir(parameterRow.containerNode);
					parameterRow.setValid(parameterRow.containerNode);
				}
			}
		}
		else
		{
			if ( this.fileStageParameters[i].discretion == "essential" )
			{
				//console.log("GridStage.validateFiles    file '" + this.fileStageParameters[i].name + "' (discretion: " + this.fileStageParameters[i].discretion + ") does not exist. Setting stageParameter.isValid to FALSE");
				
				this.isValid = false;

				// DO Agua.setParameterValidity
				Agua.setParameterValidity(this.fileStageParameters[i], false);
				if ( parameterRow != null )
				{
					//console.log("GridStage.validateFiles    DOING parameterRow.setInvalid(node)");
					//console.dir(parameterRow.containerNode);
					parameterRow.setInvalid(parameterRow.containerNode);
				}
			}
			else
			{
				// DO Agua.setParameterValidity
				Agua.setParameterValidity(this.fileStageParameters[i], true);
				if ( parameterRow != null )
				{
					//console.log("GridStage.validateFiles    DOING parameterRow.setValid(node)");
					//console.dir(parameterRow.containerNode);
					parameterRow.setValid(parameterRow.containerNode);
				}
			}
		}
	}
	//console.log("GridStage.validateFiles    FINAL (w/o fileCheck) this.isValid: " + this.isValid);

	if ( this.isValid == false )
		this.setInvalid();
	else
		this.setValid();
},

checkValidFile : function (stageParameter, parameterRow) {
	//console.log("GridStage.checkValidFile     GridStage.checkValidFile(stageParameter)");
	//console.log("GridStage.checkValidFile     stageParameter: " + dojo.toJson(stageParameter));
	//console.log("GridStage.checkValidFile    stageParameter.name: " + stageParameter.name);
	
	var filepath = stageParameter.value;
	//console.log("GridStage.checkValidFile     Checking files/dirs");

	// CHECK NON-OPTIONAL FILEPATHS
	// required: FILE PATH MUST BE NON-EMPTY
	// essential: FILE/DIRECTORY MUST BE PHYSICALLY PRESENT
	if ( stageParameter.discretion == "required"
		|| stageParameter.discretion == "essential" )
	{
		//console.log("GridStage.checkValidFile     Parameter is required/essential");

		// SET this.isValid = false IF FILE/DIR IS NULL OR EMPTY
		if ( filepath == null || filepath == '' )
		{
			//console.log("GridStage.checkValidFile    Non-optional file/dir is null or empty.");
			//console.log("GridStage.checkValidFile    Setting stageParameter.parameterIsValid to FALSE.");
			this.setInvalidParameter(stageParameter, parameterRow);
		}

		// ADD TO this.fileStageParameters ARRAY IF NO fileinfo
		else if ( stageParameter.fileinfo == null )
		{
			//console.log("GridStage.checkValidFile    stageParameter.fileinfo is null. Pushing to fileStageParameters");
			this.fileStageParameters.push(stageParameter);
			this.fileParameterRows.push(parameterRow);
		}

		// FILE/DIR IS SPECIFIED BUT KNOWN TO NOT EXIST
		else if ( (stageParameter.fileinfo.exists == false) )
		{
			//console.log("GridStage.checkValidFile    Non-optional file/dir stageParameter.exists is null or false.");

			// PUSH ONTO this.fileStageParameters IF CHAINED = 0
			if ( stageParameter.chained == null
				|| stageParameter.chained == 0 )
			{
				//console.log("GridStage.checkValidFile    stageParameter.chained is 0 or null");
	 			//console.log("GridStage.checkValidFile    Pushing onto this.fileStageParameters");
				this.fileStageParameters.push(stageParameter);
				this.fileParameterRows.push(parameterRow);
			}
			
			// OTHERWISE, USE EXISTING PARAMETER VALIDITY INFO
			// TO SET THE VALIDITY OF THE PARAMETER ROW AND IGNORE
			// WHETHER OR NOT IT EXISTS (CHAINING IS THE PROMISE
			// THAT IT WILL EXIST ONCE THE PREVIOUS STAGE IS DONE.)
			else {
				this.setValidParameter(stageParameter, parameterRow);
			}
		}
		
		// FILE/DIR IS SPECIFIED AND KNOWN TO EXIST
		else {
			//console.log("GridStage.checkValidFile    File/dir exists.");
			if ( stageParameter.fileinfo.type != stageParameter.valuetype )
			{
				// SET PARAMETER VALIDITY AS FALSE
				//console.log("GridStage.checkValidFile    File/dir mismatch. Setting parameter validity as FALSE");
				this.setInvalidParameter(stageParameter, parameterRow);
			}
			else {
				// SET PARAMETER VALIDITY AS TRUE
				//console.log("GridStage.checkValidFile    Paramtype matches. Setting parameter validity as TRUE");
				this.setValidParameter(stageParameter, parameterRow);
			}
		}
	}
	
	// THIS IS AN OPTIONAL PARAMETER SO ITS VALID IF EMPTY.
	// BUT IF ITS NOT EMPTY, CHECK IT EXISTS.
	else 
	{
		// IF EMPTY 
		if ( stageParameter.value == null
			|| stageParameter.value == '' )
		{
			//console.log("GridStage.checkValidFile    Ignoring empty optional file/dir parameter");
			this.setValidParameter(stageParameter, parameterRow);
		}
		else
		{
			//console.log("GridStage.checkValidFile    Optional file/dir parameter is specified. Pushing onto this.fileStageParameters array");
			this.fileStageParameters.push(stageParameter);
			this.fileParameterRows.push(parameterRow);
		}
	}
},

checkValidInteger : function (stageParameter, parameterRow) {
	//console.log("GridStage.checkValidInteger     GridStage.checkValidInteger(stageParameter)");
	//console.log("GridStage.checkValidInteger     stageParameter: " + dojo.toJson(stageParameter));
	if ( stageParameter.discretion != "optional" )
	{
		// SET EMPTY NON-OPTIONAL INTEGER AS FALSE
		if ( stageParameter.value == null
				|| stageParameter.value == '' )
		{
			//console.log("GridStage.checkValidParameters      '" + stageParameter.name + "' Non-optional INTEGER input is empty. Setting this.isValid to FALSE");
			this.setInvalidParameter(stageParameter, parameterRow);
		}
		// NON-OPTIONAL INTEGER BUT IS NOT A PROPER NUMBER
		// ////SO SET TO false
		else if (! stageParameter.value.match(/^\s*[\d\.]+\s*$/) )
		{
			//console.log("GridStage.checkValidParameters      '" + stageParameter.name + "' Non-optional INTEGER input not valid. Setting this.isValid to FALSE");
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
			//console.log("GridStage.checkValidParameters      '" + stageParameter.name + "' Optional INTEGER input not valid. Setting this.isValid to FALSE");
			this.setInvalidParameter(stageParameter, parameterRow);
		}
		
		// OTHERWISE, ITS EITHER EMPTY OR AN INTEGER SO SET TO true
		else
		{
			//console.log("GridStage.checkValidParameters      '" + stageParameter.name + "' Optional INTEGER input is empty. Setting this.isValid to TRUE");
			this.setValidParameter(stageParameter, parameterRow);
		}
	}
},

checkValidText : function (stageParameter, parameterRow) {
	//console.log("GridStage.checkValidText     GridStage.checkValidText(stageParameter)");
	//console.log("GridStage.checkValidText     stageParameter: " + dojo.toJson(stageParameter));
	if ( stageParameter.discretion != "optional" )
	{
		if ( stageParameter.value == null
			|| stageParameter.value == '' )
		{
			//console.log("GridStage.checkValidText      '" + stageParameter.name + "' Required text input is null or empty. Setting this.isValid to FALSE");
			this.setInvalidParameter(stageParameter, parameterRow);
		}
		else
		{
			//console.log("GridStage.checkValidText      '" + stageParameter.name + "' Required text input is satisfied. Setting this.isValid to TRUE");
			this.setValidParameter(stageParameter, parameterRow);
		}
	}
	else
	{
		// THIS IS AN OPTIONAL PARAMETER SO, EMPTY OR NOT, ITS VALID
		//console.log("GridStage.checkValidText      '" + stageParameter.name + "' Optional text parameter. Setting stageParameter.isValid to TRUE");
		this.setValidParameter(stageParameter, parameterRow);
	}
},
setInvalidParameter : function (stageParameter, parameterRow) {
	//console.log("GridStage.setInvalidParameter    stageParameter.name: " + stageParameter.name);
	this.isValid = false;
	Agua.setParameterValidity(stageParameter, false);
	if ( parameterRow != null)
		parameterRow.setInvalid(parameterRow.containerNode);
},

setValidParameter : function (stageParameter, parameterRow) {
	//console.log("GridStage.setValidParameter    stageParameter.name: " + stageParameter.name);
	Agua.setParameterValidity(stageParameter, true);
	if ( parameterRow != null)
		parameterRow.setValid(parameterRow.containerNode);
},

setValid : function () {
	//console.log("GridStage.setValid    SETTING node to SATISFIED");
	//console.log("GridStage.setValid    this.core: ");
	//for ( var key in this.core )
	//{
	//	//console.log(key + ": " + this.core[key]);		
	//}
	
	dojo.removeClass(this.domNode, 'unsatisfied');
	dojo.addClass(this.domNode, 'satisfied');
	
	this.isValid = true;
	var stagesWidget = this.core.userWorkflows;
	//console.log("GridStage.setValid    this.stagesWidget: " + this.stagesWidget);
	stagesWidget.updateRunButton();	
},

setInvalid : function () {
	//console.log("GridStage.setInvalid    SETTING node to UNSATISFIED");
	//console.log("GridStage.setInvalid    this.core: ");
	for ( var key in this.core )
	{
		//console.log(key + ": " + this.core[key]);		
	}

	dojo.removeClass(this.domNode, 'satisfied');
	dojo.addClass(this.domNode, 'unsatisfied');
	
	this.isValid = false;
	var stagesWidget = this.core.userWorkflows;
	//console.log("GridStage.setInvalid    this.stagesWidget: " + this.stagesWidget);
	stagesWidget.updateRunButton();	
}


});
