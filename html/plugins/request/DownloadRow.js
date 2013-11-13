define([
	"dojo/_base/declare",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common/Util",
	"dojo/domReady!",
	"dijit/layout/TabContainer",
	"dijit/form/Select"
],

function (
	declare,
	on,
	lang,
	domAttr,
	domClass,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	CommonUtil
) {

/////}}}}}

return declare("plugins.request.DownloadRow",
	[
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplate,
	CommonUtil
], {

// templateString : String
//		Template of this widget. 
templateString: dojo.cache("plugins", "request/templates/downloadrow.html"),

// parentWidget	:	Widget object
// 		Widget that has this parameter row
parentWidget : null,

// filename : String
//		Query term
filename : "",

// filesize : String
//		Query term
filesize : "",

// cssFiles : Array
//		Array of CSS files to be loaded for all widgets in template
// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/request/css/downloadrow.css"),
	require.toUrl("dojo/tests/dnd/dndDefault.css"),
	require.toUrl("dijit/themes/claro/document.css")
	//,
	//require.toUrl("dijit/tests/css/dijitTests.css")
],
/////}}}}}
constructor : function(args) {
	//console.log("DownloadRow.constructor    args: ");
	//console.dir({args:args});

    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
	
	this.lockedValue = args.locked;

	//console.log("DownloadRow.constructor    END");
},
postCreate : function(args) {
	//console.log("DownloadRow.postCreate    plugins.workflow.DownloadRow.postCreate(args)");
	//this.formInputs = this.parentWidget.formInputs;

	this.startup();
},
startup : function () {
	// SET TITLE TO FULL FILE NAME
	this.fileNameNode.title = this.filename;
	
	// GET SHORTENED FILENAME
	var prefix = 10;
	var suffix = 22;
	var formattedFilename = this.shortenFilename(this.filename, prefix, suffix);
	//console.log("DownloadRow.startup    formattedFilename: " + formattedFilename);
	
	// GET COMMA-FORMATTED FILESIZE
	var formattedFilesize = this.addCommas(this.filesize);	
	
	this.fileNameNode.innerHTML = formattedFilename;
	this.fileSizeNode.innerHTML = formattedFilesize;	
},
shortenFilename : function (text, prefix, suffix) {
	prefix	=	parseInt(prefix);
	suffix	=	parseInt(suffix);

	////console.log("DownloadRow.shortenFilename    text: " + text);
	////console.log("DownloadRow.shortenFilename    prefix: " + prefix);
	////console.log("DownloadRow.shortenFilename    suffix: " + suffix);
	
	if ( text.length < (prefix + suffix + 3) ) {
		return text;
	}

	return text.substring(0,prefix) + "..." + text.substring(text.length - suffix, text.length);
},
addCommas : function (integer) {
	////console.log("DownloadRow.addCommas    integer: " + integer);
	////console.log("DownloadRow.addCommas    integer.toString().length: " + integer.toString().length);

	var position = 3;
	if ( integer.toString().length <= position ) {
		return integer;
	}
	
	var output = "";
	var stop 	= 	integer.toString().length + 3 - position;
	var start	=	integer.toString().length - position;
	while ( parseInt(integer.toString().length) > position ) {
		////console.log("DownloadRow.addCommas    position: " + position);
		////console.log("DownloadRow.addCommas    start: " + start);
		////console.log("DownloadRow.addCommas    stop: " + stop);
		
		output = ","
			+ integer.toString().substring(start, stop)
			+ output;
		position+=3;

		stop 	= 	integer.toString().length + 3 - position;
		start	=	integer.toString().length - position;
	}
	////console.log("DownloadRow.addCommas    output: " + output);
	////console.log("DownloadRow.addCommas    FINAL start: " + start);

	if ( start > -3  ) {
		output	=	integer.toString().substring(0, start + 3) + output;
	}
	////console.log("DownloadRow.addCommas    FINAL output: " + output);
	
	return output;
},
deleteSelf : function () {
	//console.log("DownloadRow.deleteSelf    this:");
	//console.dir({this:this});
	
	if ( this.parentWidget && this.parentWidget.deleteDownloadRow ) {
		this.parentWidget.deleteDownloadRow(this.domNode.parentNode);
	}
}

}); //	end declare

});	//	end define

