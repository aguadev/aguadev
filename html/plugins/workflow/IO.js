dojo.provide("plugins.workflow.IO");

/* 

SET THE DEFAULT CHAINED VALUES FOR INPUTS AND OUTPUTS FOR AN
APPLICATION BASED ON THOSE OF THE PREVIOUS APPLICATIONS

E.G., THE NAME OF THE OUTPUT FILE FOR AN APPLICATION CAN BE MADE
TO DEPEND ON THE INPUTS FOR THE APPLICATION. IN THIS CASE, THE
args, inputParams AND paramFunction ENTRIES PROVIDE THE MEANS
TO INFER THE NAME OF THE OUTPUT FILE:

	stageParameters = [ 	    
	{
		"owner": "admin",
		"value": "",
		"args": "input.inputfile.value",
		"inputParams": "inputfile",
		"appname": "eland2ace.pl",
		"apptype": "converter",
		"argument": "",
		"category": "acefile",
		"valuetype": "file",
		"project": "Project1",
		"workflow": "Workflow1",
		"appnumber": "2"
		name: "acefile",
		paramtype: "output",
		format: "ace",
		args: [ 'arguments.inputfile.value' ],
		inputParams : [inputfile],
		paramFunction: "var acefile = inputfile; acefile = acefile.replace(/\\.txt/, \".ace\"); return acefile;"
	},
	...
*/


// INHERITS
dojo.require("plugins.core.Common");

dojo.declare( "plugins.workflow.IO",
	[ plugins.core.Common ],
{

////}

// PARENT WIDGET
parentWidget : null,

// CORE WORKFLOW OBJECTS
core : null,

constructor : function(args) {
	//console.log("IO.constructor     args:");
	//console.dir({args:args});
	
	// GET INFO FROM ARGS
	this.core = args.core;
	this.parentWidget = args.parentWidget;

	// LOAD CSS
	this.loadCSS();		
},
postCreate : function() {
	this.startup();
},
startup : function () {
	//console.log("IO.startup    plugins.workflow.IO.startup()");
	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 
},
chainStage : function (application, force) {
// 		1. SET INPUTS DEPENDENT ON THE OUTPUTS OF THE PREVIOUS STAGE
// 		2. SET RESOURCES DEPENDENT ON INPUTS OF THIS STAGE
// 		3. SET OUTPUTS DEPENDENT ON INPUTS AND RESOURCES OF THIS STAGE
//      (NB: REPEAT STEP 3 IF USER CHANGES RESOURCES MANUALLY)
	//console.log("IO.chainStage     plugins.workflow.IO.chainStage(application, force)");
	//console.log("IO.chainStage     application: " + dojo.toJson(application));
	//console.log("IO.chainStage     force: " + force);

	var chained = new Object;

	// SET INPUTS
	//console.log("IO.chainStage     Doing INPUTS for application: " + application.name);
	// RETURN IF NO PRECEDING APPLICATIONS
	if ( application.number != 1 )
	{
		chained.inputs = this.chainInputs(application, force);
	}
	
	//// SET RESOURCESsf 
	////console.log("IO.chainStage     Doing RESOURCES for application: " + application.name);
	//application = this.chainResources(application.arguments, application);
	//

	// SET OUTPUTS 
	//console.log("IO.chainStage     Doing OUTPUTS for application: " + application.name);
	chained.outputs = this.chainOutputs(application, force);

	// UPDATE VALID/INVALID CSS IN PARAMETERS PANE
	if ( this.core.parameters != null 
		&& this.core.parameters.isCurrentApplication(application) )
			this.core.parameters.setParameterRowStyles();

	//console.log("IO.chainStage     END");

	return chained;
},
chainInputs : function (application, force) {
// GET INPUTS FOR AN APPLICATION, BASED ON THE INPUTS, OUTPUTS
// AND OR RESOURCES OF THE PREVIOUS APPLICATION

	//console.log("IO.chainInputs     plugins.workflow.IO.chainInputs(application)");
	//console.log("IO.chainInputs     application: " );
	//console.dir({application:application});

	// GET THE input STAGE PARAMETERS FOR THIS STAGE        
	var stageParameters = Agua.getStageParameters(application);
	var inputParameters = this.filterByKeyValues(dojo.clone(stageParameters), ["paramtype"], ["input"]);
	//console.log("IO.chainInputs     stageParameters: ");
	//console.dir({stageParameters:stageParameters});
	
	// GET THE STAGE PARAMETERS FOR THE PRECEDING STAGE
	var appnumber = application.appnumber;
	if ( appnumber == null )
	{
		//console.log("IO.chainInputs     appnumber is null. Returning");
		return;
	}
	//console.log("IO.chainInputs     appnumber: " + appnumber);

	var stages = Agua.getStagesByWorkflow(application.project, application.workflow);
	//console.log("IO.chainInputs     stages: ");
	//console.dir({stages:stages});
	//console.log("IO.chainInputs     no. stages: " + stages.length);
	if ( stages == null )
	{
		//console.log("IO.chainInputs     stages is null. Returning");
		return;
	}
	
	//console.log("IO.chainInputs     previousStage = stages[" + (appnumber - 2) + "]");
	var previousStage = stages[appnumber - 2];
	if ( previousStage == null )
	{
		//console.log("IO.chainInputs     previousStage is null. Returning");
		return;
	}
	//console.log("IO.chainInputs     previousStage: ");
	//console.dir({previousStage:previousStage});

	var previousStageParameters = Agua.getStageParameters(previousStage);
	if ( previousStageParameters == null )
	{
		//console.log("IO.chainInputs     previousStageParameters is null. Returning");
		return;
	}
	//console.log("IO.chainInputs     previousStageParameters: ");
	//console.dir({previousStageParameters:previousStageParameters});
	
	for ( var i = 0; i < inputParameters.length; i++ )
	{
		//console.log("IO.chainInputs     ***************** Doing chainStageParameter inputParameters[" + i + "].name: " + inputParameters[i].name);
		//console.log("IO.chainInputs     " + inputParameters[i].name + " args: " + inputParameters[i].args);
		//console.log("IO.chainInputs     " + inputParameters[i].name + " inputParams: " + inputParameters[i].inputParams);
		//console.log("IO.chainInputs     " + inputParameters[i].name + " pararmFunction: " + inputParameters[i].paramFunction);
		//console.dir({inputParameter:inputParameters[i]});
		this.chainStageParameter(inputParameters[i], previousStageParameters, force);
	}
	//console.log("IO.chainInputs     Doing chainStageParameter " + i);
	
	//console.log("IO.chainInputs     inputParameters: ");
	//console.dir({inputParameters:inputParameters});
	return inputParameters;

},  //  chainInputs
chainResources: function (application, force) {
/*  GET RESOURCES FOR AN APPLICATION, BASED ON THE INPUTS, OUTPUTS

	AND/OR RESOURCES OF THE CURRENT APPLICATION
*/

},
chainOutputs : function (application, force) {
// GET OUTPUTS FOR AN APPLICATION, BASED ON THE INPUTS AND/OR
//	RESOURCES OF THE APPLICATION
	//console.log("IO.chainOutputs     plugins.workflow.IO.chainOutputs(application, force)");
	//console.log("IO.chainOutputs     application: " + dojo.toJson(application));

	// GET THE input STAGE PARAMETERS FOR THIS STAGE        
	var stageParameters = Agua.getStageParameters(application);
	//console.log("IO.chainOutputs     stageParameters: " + dojo.toJson(stageParameters));
	
	// GET OUTPUT STAGE PARAMETERS ONLY
	var outputParameters = dojo.clone(stageParameters);
	outputParameters = this.filterByKeyValues(dojo.clone(outputParameters), ["paramtype"], ["output"]);
	//console.log("IO.chainOutputs     outputParameters: " + dojo.toJson(outputParameters));
	
	for ( var i = 0; i < outputParameters.length; i++ )
	{
		//console.log("IO.chainOutputs     Doing chainStageParameter " + i);
		this.chainStageParameter(outputParameters[i], stageParameters, force);
	}
	//console.log("IO.chainOutputs     Returning outputParameters: " + dojo.toJson(outputParameters, true));

	return outputParameters;
},
chainStageParameter : function (stageParameter, sourceParameters, force) {
	//console.log("IO.chainStageParameter     plugins.workflow.IO.chainStageParameter(stageParameter, sourceParameters, force)");
	////console.log("IO.chainStageParameter     stageParameter: " + dojo.toJson(stageParameter));
	//console.log("IO.chainStageParameter     stageParameter.name: " + stageParameter.name);
	//console.log("IO.chainStageParameter     force: " + force);
	
	// RETURN IF args IS NULL
	if ( stageParameter.args == null || stageParameter.args == '' )
	{
		//console.log("IO.chainStageParameter     stageParameters.args is null or empty. Returning.");
		return;
	}

	var valuesArray = this.getValuesArray(stageParameter, dojo.clone(sourceParameters));
	//console.log("IO.chainStageParameter     valuesArray: ");
	//console.dir({valuesArray:valuesArray});	
	var value = this.getValue(valuesArray, stageParameter.inputParams, stageParameter.paramFunction);
	//console.log("IO.chainStageParameter     value: " + value);

	// REPLACE EMPTY STAGE PARAMETER VALUE IN Agua AND REMOTE DATABASE 
	// OR OVERWRITE EXISTING VALUE IF force IS TRUE
	if ( (force == true && value != null && value != '' )
		|| (value != null && value != '' && stageParameter.value == '') )
	{
		//console.log("IO.chainStageParameter     Adding chained value to stageParameter: " + value);
		
		stageParameter.value = value;
		stageParameter.chained = 1;
		Agua._removeStageParameter(stageParameter);
		Agua.addStageParameter(stageParameter);
		Agua.setParameterValidity(stageParameter, true);
	}
},
getValuesArray : function(parameter, sourceParameters) {
// GET THE ARRAY OF VALUES FOR THE args TO BE INPUT INTO THE paramFunction
	//console.log("IO.getValuesArray     plugins.workflow.WorfklowIO.getValuesArray(parameter, sourceParameters)");
	//console.log("IO.getValuesArray     parameter : ");
	//console.dir({parameter:parameter});
	//console.log("IO.getValuesArray     sourceParameters : ");
	//console.dir({sourceParameters:sourceParameters});
	// SANITY CHECK		
	if ( parameter.args == null || sourceParameters == null )
	{
		return;
	}
	// CONVERT args TO argsArray
	var argsArray = parameter.args.split(/,/);
	//console.log("IO.getValuesArray     argsArray: ");
	//console.dir({argsArray:argsArray});

	// RETURN AN ARRAY
	var valuesArray = new Array;

	var thisObject = this;
	//dojo.forEach(argsArray, function(args, i) {

	for ( var i = 0; i < argsArray.length; i++ ) {
		var args = argsArray[i];
		args = args.replace(/\s+/g, '');
		
		//console.log("IO.getValuesArray     argsArray[" + i + "]: " + argsArray[i]);
		//console.log("IO.getValuesArray     args: " + args);

		// EXTRACT ARGUMENT VALUE FROM APPLICATION OBJECT
		var array = args.split("\.");
		var paramtypeToken = array[0];
		var nameToken = array[1];
		var valueToken = array[2];
		//console.log("IO.getValuesArray     paramtypeToken: " + paramtypeToken);
		//console.log("IO.getValuesArray     nameToken: " + nameToken);
		//console.log("IO.getValuesArray     valueToken: " + valueToken);

		// FILTER BY PARAMTYPE TYPE (input|resource|output)
		var sources = dojo.clone(sourceParameters);
		sources = thisObject.filterByKeyValues(dojo.clone(sources), ["paramtype"], [paramtypeToken]);
		//console.log("IO.getValuesArray     '" + paramtypeToken + "' sources: ");
		//console.dir({sources:sources});

		// IF SOURCE PARAMETERS NOT PRESENT, SET VALUE TO ''
		if ( sources == null || sources.length == 0 )
		{
			valuesArray.push(null);
			continue;
		}
		// IF THE ARRAY OF SOURCE PARAMETERS WAS WANTED, STORE IT AND NEXT
		if ( nameToken == null || nameToken == '' )
		{
			valuesArray.push(sources);
			continue;
		}
		// GET THE SOURCE PARAMETER
		//console.log("IO.getValuesArray     BEFORE GET sourceParameter, nameToken: " + nameToken);
		var source = thisObject.filterByKeyValues(dojo.clone(sources), ["name"], [nameToken])[0];
		//console.log("IO.getValuesArray     " + nameToken + " source: ");
		//console.dir({source:source});

		// IF SOURCE PARAMETER NOT DEFINED, SET VALUE TO ''
		if ( source == null || source == '' )
		{
			valuesArray.push(null);
			continue;
		}

		// IF THE WHOLE PARAMETER HASH WAS WANTED, STORE IT AND NEXT
		if ( valueToken == null )
		{
			valuesArray.push(source);
			continue;
		}

		// OTHERWISE, GET THE PARAMETER'S VALUE
		var value = source.value;
		//console.log("IO.getValuesArray     value: " + value);
		valuesArray.push(value);
	}
//);
	//////console.log("IO.getValuesArray     Returning valuesArray: " + dojo.toJson(valuesArray));
	return valuesArray;
},
getValue : function (valuesArray, inputParams, paramFunction) {
// GET THE PARAMETER VALUE USING THE paramFunction IF PRESENT.
// OTHERWISE, RETURN A SCALAR OF THE FIRST ENTRY IN valuesArray
	//console.log("IO.getValue     plugins.workflow.Workflow.value(valuesArray, inputParams, paramFunction)");
	//console.log("IO.getValue     valuesArray: " + dojo.toJson(valuesArray));
	//console.log("IO.getValue     inputParams: " + dojo.toJson(inputParams));
	//console.log("IO.getValue     paramFunction: " + dojo.toJson(paramFunction));

	var value;
	if ( inputParams == null || inputParams == ''
		|| paramFunction == null || paramFunction == '' )
	{
		//console.log("IO.getValue     inputParams NOT DEFINED. Returning first entry in valuesArray: " + dojo.toJson(valuesArray));
		for ( var i = 0; i < valuesArray.length; i++ )
		{
			if ( valuesArray[i] == null || valuesArray[i] == '' )	continue;
			return valuesArray[i];
		}
	}
	
	// SET THE FUNCTION
	var inputParamsArray = inputParams.slice(',');
	var argumentFunction = new Function( inputParamsArray , paramFunction );
	
	// RUN THE FUNCTION WITH THE INPUT PARAMETER VALUES
	// HACK TO INPUT PARAMETER VALUES
    //var values = Array.prototype.slice.call( arguments, 2 );

	value = argumentFunction(valuesArray[0], valuesArray[1], valuesArray[2], valuesArray[3], valuesArray[4]);
	// THIS DOESN'T WORK
	//value = argumentFunction(valuesArray);
	//console.log("IO.getValue     value: " + value);

	return value;
}

});

