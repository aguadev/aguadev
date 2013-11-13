
dojo.provide("plugins.workflow.RunStatus.StageStatus");

dojo.require("plugins.workflow.RunStatus.StageStatusRow");

dojo.declare("plugins.workflow.RunStatus.StageStatus",
[ dijit._Widget, dijit._Templated ], {
templatePath: dojo.moduleUrl("plugins", "workflow/RunStatus/templates/stagestatus.html"),

widgetsInTemplate : true,

stages : null,

rows: new Array(),

////}}}}
constructor : function(args) {	
	console.log("StageStatus.constructor    plugins.workflow.RunStatus.StageStatusRow.constructor(args)");
},
postCreate : function() {
	this.startup();
},
startup : function () {
	console.group("StageStatus-" + this.id + "    startup");	

	this.inherited(arguments);

	// ATTACH stageTable TO attachNode
	this.attachTable();

	console.groupEnd("StageStatus-" + this.id + "    startup");	
},
attachTable : function () {
	console.log("StageStatus.attachTable    this.attachNode: ");
	console.dir({attachNode:this.attachNode});
	
	this.attachNode.appendChild(this.stageTable);
	console.log("StageStatus.attachTable    AFTER this.attachNode.appendChild(this.stageTable)");	
},
displayStatus : function (stagestatus) {
	console.group("StageStatus-" + this.id + "    displayStatus");

	console.log("StageStatus.displayStatus      stagestatus:");
	console.dir({stagestatus:stagestatus});
	
	// REMOVE PREVIOUS STATUS 	
	this.clearStatus();
	
	// RETURN IF STATUS IS NULL
	if ( ! stagestatus  ) {
		console.log("StageStatus.displayStatus    stagestatus is null. Returning");
		return;
	}

	// SET this.status
	this.status = stagestatus.status;

	// DISPLAY NAME AND STATUS
	this.core.runStatus.workflowName.innerHTML = stagestatus.project + '.' + stagestatus.workflow;
	this.core.runStatus.workflowStatus.innerHTML = stagestatus.status;
	
	// DISPLAY STAGES STATUS	
	var stages = stagestatus.stages;
	console.log("StageStatus.displayStatus    DOING this.displayStagesStatus()");
	this.displayStagesStatus(stages);

	console.groupEnd("StageStatus-" + this.id + "    displayStatus");
},
clearStatus : function () {
	console.log("StageStatus.clearStatus    BEFORE clear this.stageTable");

	this.core.runStatus.innerHTML = "";

    while ( this.stageTable.childNodes && this.stageTable.childNodes.length ) {
    console.log("StageStatus.clearStatus    REMOVING node " + this.stageTable.childNodes[0]);
        this.stageTable.removeChild(this.stageTable.childNodes[0]);
    }
	console.log("StageStatus.clearStatus    AFTER clear this.stageTable");
},
displayStagesStatus : function (stages) {
	console.group("StageStatus-" + this.id + "    displayStagesStatus");

	// ATTACH stageTable TO attachNode IF NOT ALREADY ATTACHED
	if ( this.stageTable.parentNode == null )
		this.attachTable();
	
	console.log("StageStatus.displayStagesStatus    stages:");
	console.dir({stages:stages});
	console.log("StageStatus.displayStagesStatus    this.stageTable:");
	console.dir({this_stageTable:this.stageTable});
	
    if ( ! stages )  return;
    
	// SET THE NODE CLASSES BASED ON STATUS
    this.rows = [];
	for ( var i = 0; i < stages.length; i++ )
	{
		console.log("StageStatus.displayStatus     Doing stages[" + i + "]: ");
		console.dir({stage:stages[i]});

		var tr = document.createElement('tr');
		this.stageTable.appendChild(tr);
		
		stages[i].duration = this.calculateDuration(stages[i]);
		//console.log("StageStatus.displayStatus     stages[i].duration: " + stages[i].duration);

		stages[i].lapsed = this.calculateLapsed(stages[i]);
		//console.log("StageStatus.displayStatus     stages[i].lapsed: " + stages[i].lapsed);

		if ( stages[i].completed == "0000-00-00 00:00:00" )
			stages[i].completed = '';
		if ( stages[i].queued == "0000-00-00 00:00:00" )
			stages[i].queued = '';
		
		stages[i].core = this.core;
		var stagestatusRow = new plugins.workflow.RunStatus.StageStatusRow(stages[i]);
		
		console.log("StageStatus.displayStatus     stagestatusRow:");
		console.dir({stagestatusRow:stagestatusRow});
		
        this.rows.push(stagestatusRow);

		var td = document.createElement('td');
		tr.appendChild(td);
		td.appendChild(stagestatusRow.domNode);
	}
	
	console.groupEnd("StageStatus-" + this.id + "    displayStagesStatus");
},
stringToDate : function (string) {
// CONVERT 2010-02-21 10:45:46 TO year, month, day, hour, minutes, seconds

	//console.log("StageStatus.stringToDate    string: " + string);

	// FORMAT: 2012-02-2604:24:14
	var array = string.match(/^(\d{4})\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)/);
	//console.log("StageStatus.arrayToDate    array: ");
	//console.dir({array:array});
	
	// REMOVE FIRST MATCH (I.E., ALL OF MATCHED STRING)
	array.shift();
	
	// MONTH IS ZERO-INDEXED
	array[1]--;

	// GENERATE NEW DATE
	return new Date(array[0],array[1],array[2],array[3],array[4],array[5]);
},
secondsToDuration : function (milliseconds) {
// CONVERT MILLISECONDS TO hours, mins AND secs 
	var duration = '';
	var remainder = 0;

	// IGNORE MILLISECONDS	
	remainder = milliseconds % 1000;
	milliseconds -= remainder;
	milliseconds /= 1000;

	// GET SECONDS	
	remainder = milliseconds % 60;
	if (remainder)
		duration = remainder.toString();
	else
		duration = "0";
	duration = duration + " sec";

	// Strip off last component
	milliseconds -= remainder;
	milliseconds /= 60;

	// GET HOURS	
	remainder = milliseconds % 60;
	duration = remainder.toString() + " min " + duration;

	// Strip off last component
	milliseconds -= remainder;
	milliseconds /= 60;

	// GET DAYS
	return milliseconds.toString() + " hours " + duration;
},
calculateDuration : function (stage) {
	//console.log("StageStatus.calculateDuration    stage.started: " + stage.started);

	var duration = '';
	// IF STARTED, GET THE DURATION
	if ( stage.started
		&& stage.started != "0000-00-00 00:00:00" )
	{
		// GET DURATION BY SUBSTRACTING started FROM completed OR now
		var startedDate = this.stringToDate(stage.started);
		var currentDate;
		if ( ! stage.completed 
			|| stage.completed == "0000-00-00 00:00:00" ) {
			currentDate = this.stringToDate(stage.now);
		}
		else {
			currentDate = this.stringToDate(stage.completed);
		}
		
		// CONVERT DIFFERENCE TO DURATION
		var seconds = currentDate - startedDate;
		duration = this.secondsToDuration(seconds);
	}

	return duration;
},
calculateLapsed : function (stage) {
	//console.log("StageStatus.calculateLapsed    stage.completed: " + stage.completed);

	var lapsed = '';
	if ( ! stage || ! stage.completed || stage.completed == "0000-00-00 00:00:00" )
		return lapsed;
	
	var completedDate = this.stringToDate(stage.completed);
	var currentDate	= new Date;
	//console.log("StageStatus.calculateLapsed    currentDate: " + currentDate);
	//console.dir({currentDate:currentDate});
	
	// GET DURATION BY SUBSTRACTING completed FROM CURRENT TIME
	var seconds = currentDate - completedDate;
	//console.log("StageStatus.calculateLapsed    seconds: " + seconds);

	lapsed = this.secondsToDuration(seconds);
	//console.log("StageStatus.calculateLapsed    lapsed: " + lapsed);
	
	return lapsed;
}



}); // plugins.workflow.RunStatus.StageStatus
