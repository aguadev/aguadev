dojo.provide("plugins.core.Agua.Report");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	REPORT METHODS  
*/

dojo.declare( "plugins.core.Agua.Report",	[  ], {

/////}}}

getReports : function () {
// RETURN A COPY OF THE this.reports ARRAY

	console.log("Agua.Report.getReports    plugins.core.Data.getReports()");

	var stages = this.getStages();
	if ( stages == null )	return;
	//console.log("Agua.Report.getReports    stages: " + dojo.toJson(stages, true));

	var keys = [ "type" ];
	var values = [ "report" ];
	var reports = this.filterByKeyValues(stages, keys, values);
	//console.log("Agua.Report.getReports    reports: " + dojo.toJson(reports, true));

	return reports;
},
getReportsByWorkflow : function (projectName, workflowName) {
// RETURN AN ARRAY OF REPORT HASHES FOR THE SPECIFIED PROJECT AND WORKFLOW

	var reports = this.getReports();
	if ( reports == null )	return null;

	var keyArray = ["project", "workflow"];
	var valueArray = [projectName, workflowName];
	return this.filterByKeyValues(reports, keyArray, valueArray);
},
removeReport : function (reportObject) {
// REMOVE A REPORT OBJECT FROM THE this.reports ARRAY

	console.log("Agua.Report.removeReport    plugins.core.Data.removeReport(reportObject)");
	console.log("Agua.Report.removeReport    reportObject: " + dojo.toJson(reportObject));

	// REMOVE REPORT FROM this.reports
	var requiredKeys = ["project", "workflow", "name"];
	var success = this.removeData("reports", reportObject, requiredKeys);
	if ( success == true )	console.log("Agua.Report.removeReport    Removed report from this.reports: " + reportObject.name);
	else	console.log("Agua.Report.removeReport    Could not remove report from this.reports: " + reportObject.name);
	
	// REMOVE REPORT FROM groupmembers IF PRESENT
	var groupNames = this.getGroupsByReport(reportObject.name);
	console.log("Agua.Report.removeReport    groupNames: " + dojo.toJson(groupNames));
	for ( var i = 0; i < groupNames.length; i++ )
	{
		if ( this.removeReportFromGroup(groupNames[i], reportObject) == false )
			success = false;
	}

	return success;
},
isReport : function (reportName) {
// RETURN true IF A REPORT EXISTS IN this.reports
	console.log("Agua.Report.isReport    plugins.core.Data.isReport(reportName)");
	console.log("Agua.Report.isReport    reportName: *" + reportName + "*");
	//console.log("Agua.Report.isReport    this.reports: " + dojo.toJson(this.reports));

	var reports = this.getReports();	
	for ( var i in reports )
	{
		var report = reports[i];
		if ( report.name.toLowerCase() == reportName.toLowerCase() )
		{
			console.log("Agua.Report.isReport    report.name is a report: *" + report.name + "*");
			return true;
		}
	}
	
	return false;
},
addReport : function (reportObject) {
// ADD A REPORT 
	console.log("Agua.Report.addReport+     plugins.core.Data.addReport(projectName)");
	console.log("Agua.Report.addReport    reportObject: " + dojo.toJson(reportObject));

	// DO THE ADD
	var requiredKeys = ["project", "workflow", "name"];
	var success = this.addData("reports", reportObject, requiredKeys);
	
	if ( success == true ) console.log("Agua.Report.addReport    Added report to this.reports[" + reportObject.name);
	else console.log("Agua.Report.addReport    Could not add report to this.reports[" + reportObject.name);
	return success;
}

});