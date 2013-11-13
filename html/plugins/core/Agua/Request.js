dojo.provide("plugins.core.Agua.Request");

/* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
	
	ADMIN METHODS  
*/

dojo.declare( "plugins.core.Agua.Request",	[  ], {

///////}}}

// QUERY METHODS
getQueries : function () {
	console.log("Agua.Request.getQueries");
	return this.cloneData("queries");
},
isQuery : function (queryObject) {
// RETURN TRUE IF SOURCE NAME ALREADY EXISTS

	console.log("Agua.Request.isQuery    plugins.core.Data.isQuery(queryObject)");
	console.log("Agua.Request.isQuery    queryObject: " + dojo.toJson(queryObject));
	
	var downloads = this.getQueries();
	if ( downloads == null )	return false;
	
	return this._objectInArray(downloads, queryObject, [ "query" ]);
},
addQuery : function (queryObject) {
// ADD A QUERY OBJECT TO downloads
	console.log("Agua.Request.addQuery    plugins.core.Data.addQuery(queryObject)");
	console.log("Agua.Request.addQuery    queryObject: " + dojo.toJson(queryObject));	

	this._removeQuery(queryObject);
	if ( ! this._addQuery(queryObject) )	return false;
	
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"addQuery";
	query.module 		= 	"Agua::Request";
	query.data 			= 	queryObject;
	//console.log("Request.addItem    query: " + dojo.toJson(query));
	this.doPut({ url: url, query: query, sync: false });

	return null;
},
_addQuery : function (queryObject) {
// ADD A QUERY OBJECT TO downloads
	console.log("Agua.Request._addQuery    plugins.core.Data._addQuery(queryObject)");
	console.log("Agua.Request._addQuery    queryObject: " + dojo.toJson(queryObject));

	return this.addData("queries", queryObject, [ "query" ]);
},
removeQuery : function (queryObject) {
// REMOVE A SOURCE OBJECT FROM downloads AND groupmembers
	console.log("Agua.Request.removeQuery    plugins.core.Data.removeQuery(queryObject)");
	console.log("Agua.Request.removeQuery    queryObject: " + dojo.toJson(queryObject));	
	if ( ! this._removeQuery(queryObject) ) {
		console.log("Agua.Request.removeQuery    FAILED TO REMOVE queryObject: " + dojo.toJson(queryObject));
		return false;
	}

	// SEND TO SERVER
	var url = Agua.cgiUrl + "agua.cgi?";
	var query = new Object;
	query.username 		= 	this.cookie("username");
	query.sessionid 	= 	this.cookie("sessionid");
	query.mode 			= 	"removeQuery";
	query.module 		= 	"Agua::Request";
	query.data 			= 	queryObject;
	
	//console.log("Request.deleteItem    queryObject: " + dojo.toJson(queryObject));
	this.doPut({ url: url, query: query, sync: false });
},
_removeQuery : function (queryObject) {
// _remove A QUERY OBJECT FROM downloads
	console.log("Agua.Request._removeQuery    plugins.core.Data._removeQuery(queryObject)");
	console.log("Agua.Request._removeQuery    queryObject: " + dojo.toJson(queryObject));
	return this.removeData("queries", queryObject, ["filename"]);
},
// DOWNLOAD METHODS
getDownloads : function () {
	console.log("Agua.Request.getDownloads");
	return this.cloneData("downloads");
},
isDownload : function (downloadObject) {
// RETURN TRUE IF SOURCE NAME ALREADY EXISTS

	console.log("Agua.Request.isDownload    plugins.core.Data.isDownload(downloadObject)");
	console.log("Agua.Request.isDownload    downloadObject: " + dojo.toJson(downloadObject));
	
	var downloads = this.getDownloads();
	if ( downloads == null )	return false;
	
	return this._objectInArray(downloads, downloadObject, ["filename"]);
},
addDownload : function (downloadObject) {
// ADD A QUERY OBJECT TO downloads
	console.log("Agua.Request.addDownload    plugins.core.Data.addDownload(downloadObject)");
	console.log("Agua.Request.addDownload    downloadObject: " + dojo.toJson(downloadObject));	

	this._removeDownload(downloadObject);
	if ( ! this._addDownload(downloadObject) )	return false;
	
	var url = Agua.cgiUrl + "agua.cgi?";
	var download = new Object;
	download.username 		= 	this.cookie("username");
	download.sessionid 		= 	this.cookie("sessionid");
	download.mode 			= 	"addDownload";
	download.module 		= 	"Agua::Request";
	download.data 			= 	downloadObject;
	//console.log("Request.addItem    download: " + dojo.toJson(download));
	this.doPut({ url: url, download: download, sync: false });

	return null;
},
_addDownload : function (downloadObject) {
// ADD A QUERY OBJECT TO downloads
	console.log("Agua.Request._addDownload    plugins.core.Data._addDownload(downloadObject)");
	console.log("Agua.Request._addDownload    downloadObject: " + dojo.toJson(downloadObject));

	return this.addData("downloads", downloadObject, [ "username", "filename", "filesize" ]);
},
removeDownload : function (downloadObject) {
// REMOVE A SOURCE OBJECT FROM downloads AND groupmembers
	console.log("Agua.Request.removeDownload    plugins.core.Data.removeDownload(downloadObject)");
	console.log("Agua.Request.removeDownload    downloadObject: " + dojo.toJson(downloadObject));	
	if ( ! this._removeDownload(downloadObject) ) {
		console.log("Agua.Request.removeDownload    FAILED TO REMOVE downloadObject: " + dojo.toJson(downloadObject));
		return false;
	}

	// SEND TO SERVER
	var url = Agua.cgiUrl + "agua.cgi?";
	var download = new Object;
	download.username 		= 	this.cookie("username");
	download.sessionid 		= 	this.cookie("sessionid");
	download.mode 			= 	"removeDownload";
	download.module 		= 	"Agua::Request";
	download.data 			= 	downloadObject;
	
	//console.log("Request.deleteItem    downloadObject: " + dojo.toJson(downloadObject));
	this.doPut({ url: url, download: download, sync: false });
},
_removeDownload : function (downloadObject) {
// _remove A QUERY OBJECT FROM downloads
	console.log("Agua.Request._removeDownload    plugins.core.Data._removeDownload(downloadObject)");
	console.log("Agua.Request._removeDownload    downloadObject: " + dojo.toJson(downloadObject));
	var requiredKeys = [ "username", "filename", "filesize" ];
	this.removeData("downloads", downloadObject, requiredKeys);

	return this.removeData("downloads", downloadObject, ["query"]);
}


});