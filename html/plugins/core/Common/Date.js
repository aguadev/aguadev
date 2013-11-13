dojo.provide("plugins.core.Common.Date");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	DATE METHODS  
*/

dojo.declare( "plugins.core.Common.Date",	[  ], {

///////}}}

// DATES
currentDate : function () {
	var date = new Date;
	var string = date.toString();

	return string;
},
currentMysqlDate : function () {
	var date = new Date;
	date = this.dateToMysql(date);	
	
	return date;
},
dateToMysql : function (date) {

  return date.getFullYear()
	+ '-'
	+ (date.getMonth() < 9 ? '0' : '') + (date.getMonth()+1)
	+ '-'
	+ (date.getDate() < 10 ? '0' : '') + date.getDate()
	+ ' '
	+ (date.getHours() < 10 ? '0' : '' ) + date.getHours()
	+ ':'
	+ (date.getMinutes() < 10 ? '0' : '' ) + date.getMinutes() 
	+ ':'
	+ (date.getSeconds() < 10 ? '0' : '' ) + date.getSeconds();
},
mysqlToDate : function (timestamp) {
	// FORMAT: 2007-06-05 15:26:03
	var regex=/^([0-9]{2,4})-([0-1][0-9])-([0-3][0-9]) (?:([0-2][0-9]):([0-5][0-9]):([0-5][0-9]))?$/;
	var elements = timestamp.replace(regex,"$1 $2 $3 $4 $5 $6").split(' ');

	return new Date(elements[0],elements[1]-1,elements[2],elements[3],elements[4],elements[5]);
}



});