define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/request/DownloadRow",
	"plugins/form/DndSource",
	"plugins/core/Common/Util",
	"dojo/store/Memory",
	"dojo/domReady!",

	"dijit/form/Select",
	"dijit/layout/BorderContainer",
	"dijit/form/Button",
	"dijit/layout/ContentPane",
	"plugins/form/SelectList",
	"plugins/form/ValidationTextBox"
],

function (
	declare,
	arrayUtil,
	JSON,
	on,
	lang,
	domAttr,
	domClass,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	DownloadRow,
	DndSource,
	CommonUtil,
	Memory
) {

/////}}}}}

return declare("plugins.request.Downloads",
	[
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	DndSource,
	CommonUtil
], {

// templateString : String
//		The template of this widget. 
templateString: dojo.cache("plugins", "request/templates/downloads.html"),

// cssFiles : ArrayRef
//		Array of CSS files to be loaded for all widgets in template
// 		OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/request/css/downloads.css"),
	require.toUrl("dojo/tests/dnd/dndDefault.css")
],

// parentWidget : Widget
//			Parent of this widget
parentWidget : null,

// DATA FIELDS TO BE RETRIEVED FROM DELETED ITEM
dataFields : [ "name", "appname", "paramtype" ],

rowClass : "plugins.request.DownloadRow",

avatarItems: [ "name", "description"],

avatarType : "parameters",

// LOADED DND WIDGETS
// attachPoint : DOM node or widget
// 		Attach this.mainTab using appendChild (DOM node) or addChild (Tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

// formInputs : HashKey
//		Hash of input names
formInputs : {
	filename 	: 	"word",
	filesize 	: 	"word"
},

// dragSource : DndSource Widget
//		The source container for DnD items
dragSource : null,

// core : HashRef
//		Hash of core classes
core : {},

/////}}}}}

constructor : function(args) {
	console.log("Downloads.constructor    args: ");
	console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);
},
postCreate : function() {
	// LOAD CSS
	console.log("Downloads.postCreate    DOING this.loadCSS()");
	this.loadCSS();		

	console.log("Downloads.postCreate    DOING this.startup()");
	this.startup();
},
startup : function () {
	console.group("Downloads-" + this.id + "    startup");

	// ATTACH PANE
	this.attachPane();

	// INITIALISE DRAG SOURCE
	this.initialiseDragSource();

	// UPDATE DOWNLOADS
	console.log("Downloads.startup    DOING this.updateDownloads()");
	this.updateDownloads();

	// SET DOWNLOAD NUMBER
	console.log("Downloads.startup    DOING this.setDownloadNumber()");
	this.setDownloadNumber();
	
	// SET DOWNLOAD SIZE
	this.setDownloadSize();
	
	console.groupEnd("Downloads-" + this.id + "    startup");
},
updateDownloads : function () {
	var downloads = Agua.getDownloads();
	console.log("Downloads.updateDownloads    downloads: ");
	console.dir({downloads:downloads});

	this.downloadCount.innerHTML	=	downloads.length;
	var ordinals = "";
	for ( var i = 0; i < downloads.length; i++ ) {
		ordinals += downloads[i].ordinal + ", ";
	}
	console.log("Downloads.updateDownloads    ordinals: " + ordinals);
	
	this.clearDragSource();
	
	this.loadDragItems(downloads);
},
setDownloadNumber : function () {
	var downloads	=	Agua.getDownloads();
	console.log("Downloads.setDownloadNumber    downloads:");
	console.dir({downloads:downloads});
	
	this.downloadCount.innerHTML = downloads.length;
},
setDownloadSize : function () {
	var downloads	=	Agua.getDownloads();
	//console.log("Downloads.setDownloadNumber    downloads:");
	//console.dir({downloads:downloads});
	
	var fileSize = 0;
	for ( var i = 0; i < downloads.length; i++ ) {
		fileSize += downloads[i].filesize;
	}
	//console.log("Downloads.setDownloadSize    fileSize: " + fileSize);
	var decimalUnits = true;
	fileSize = this.readableFileSize(fileSize, decimalUnits);
	//console.log("Downloads.setDownloadSize    FINAL fileSize: " + fileSize);
	
	this.fileSize.innerHTML = fileSize;
},
readableFileSize : function (bytes, decimalUnits) {
    var units = decimalUnits ? 1000 : 1024;
	if ( ! bytes || bytes === 0 )	return "0 b";
	//console.log("Downloads.readableFileSize    units: " + units);

    if( bytes < units ) return bytes + ' B';
    var suffixes = decimalUnits ? ['kB','MB','GB','TB','PB','EB','ZB','YB'] : ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];
    var index = -1;
    while(bytes >= units) {
		//console.log("Downloads.readableFileSize    bytes: " + bytes);
        bytes /= units;
        ++index;
    }
	
    return bytes.toFixed(1) + " " + suffixes[index];
},
addDownloads : function (newDownloads) {
	if ( ! newDownloads || newDownloads.length == 0 ) {
		return true;
	}
	
	var downloads	=	Agua.getDownloads();
	console.log("Downloads.addDownloads    downloads: ");
	console.dir({downloads:downloads});
	
	for ( var i = 0; i < newDownloads.length; i++ ) {
		if ( Agua.isDownload(newDownloads[i]))	continue;
		Agua._addDownload(newDownloads[i]);
	}

	this.updateDownloads();
	
	return true;	
},
toggleDisplay : function () {
	//console.log("Downloads.toggleDownloads");
	this.toggle(this.togglePoint);
},
getItemArray : function () {
	console.log("Downloads.getItemArray    this.dragSource: " + this.dragSource);
	console.dir({this_dragSource:this.dragSource});

	var childNodes	=	this.dragSource.getAllNodes();
	console.log("Downloads.getItemArray    childNodes: " + childNodes);
	console.dir(childNodes);

	console.log("DndSource.loadDragItems     childNodes.length: " + childNodes.length);
	var itemArray	=	[];
	for ( var i = 0; i < childNodes.length; i++ )
	{
		var widget = dijit.getEnclosingWidget(childNodes[i].firstChild);
		
		console.log("Downloads.getItemArray    childNodes: " + childNodes);
		console.dir(childNodes);
	
		var hash = {};	
		for ( key in this.formInputs ) {
			console.log("Downloads.getItemArray    widget[" + key + "]: " + widget[key]);
			hash[key]	=	widget[key];
		}
		itemArray.push(hash);
	}
	
	return itemArray;
},
createDownload : function () {
//	wget http://reqapi.annairesearch.com:8080/api/SubmitQuery.req?data=%5B%7B"password"%3A+"mypass"%2C+"userid"%3A+"andyh"%7D%2C+%7B"PAGE"%3A+%5B%7B"PAGENUM"%3A+"-1"%7D%5D%7D%5D

}


}); //	end declare

});	//	end define


