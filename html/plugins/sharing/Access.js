define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"plugins/sharing/AccessRow",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common",
	"dojo/domReady!",
	"plugins/form/TextArea",
	"dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dijit/form/Button",
	"dijit/form/TextBox",
	"dijit/form/Textarea",
	"dojo/parser",
	"dojo/dnd/Source"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, AccessRow, _Widget, _TemplatedMixin, _WidgetsInTemplate, Common) {

return declare("plugins.sharing.Access", [_Widget, _TemplatedMixin, _WidgetsInTemplate, Common], {

//Path to the template of this widget. 
templatePath: require.toUrl("plugins/sharing/templates/access.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/sharing/css/access.css")
],

// ROW WIDGETS
accessRows : new Array,

// PERMISSIONS
rights: [
	'groupwrite', 'groupcopy', 'groupview', 'worldwrite', 'worldcopy', 'worldview'
],

// attachPoint : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

/////}}}
	
constructor : function (args) {

    // MIXIN ARGS
    lang.mixin(this, args);

	console.log("Access.constructor     this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint})

	this.loadCSS();
},

attachPane : function () {
	console.log("Access.attachPane    this.mainTab: " + this.mainTab);
	if ( this.attachPoint.addChild ) {
		console.log("oooooooooooooooooooooooooooooooooo Access.attachPane    DOING this.attachPoint.addChild(this.mainTab)");
		this.attachPoint.addChild(this.mainTab);
		this.attachPoint.selectChild(this.mainTab);
	}
	if ( this.attachPoint.appendChild ) {
		console.log("oooooooooooooooooooooooooooooooooo Access.attachPane    DOING this.appendWidget.addChild(this.mainTab)");
		this.attachPoint.appendChild(this.mainTab.domNode);
	}	
},
postCreate: function() {
	this.startup();
},

startup : function () {
	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ATTACH PANE
	this.attachPane();

	//// ADD ADMIN TAB TO TAB CONTAINER		
	//this.attachPoint.addChild(this.accessTab);
	//this.attachPoint.selectChild(this.accessTab);

	this.buildTable();

	// SUBSCRIBE TO UPDATES
	if ( Agua.updater ) {
		Agua.updater.subscribe(this, "updateGroups");
	}
},

updateGroups : function (args) {
// RELOAD RELEVANT DISPLAYS
	//console.log("sharing.Access.updateGroups    sharing.Access.updateGroups(args)");
	//console.log("sharing.Access.updateGroups    args:");
	//console.dir(args);

	this.buildTable();
},

buildTable : function () {
	//console.log("Access.buildTable     plugins.sharing.Access.buildTable()");
	//console.log("Access.buildTable     this.table: " + this.table);
	
	// GET ACCESS TABLE DATA
	var accessArray = Agua.getAccess();
	//console.log("Access.buildTable    accessArray: " + dojo.toJson(accessArray));	
	
	// CLEAN TABLE
	if ( this.table.childNodes )
	{
		while ( this.table.childNodes.length > 2 )
		{
			this.table.removeChild(this.table.childNodes[2]);
		}
	}

	// BUILD ROWS
	//console.log("Access.buildTable::groupTable     Doing group rows, accessArray.length: " + accessArray.length);
	this.tableRows = [];
	for ( var rowCounter = 0; rowCounter < accessArray.length; rowCounter++)
	{
	//console.log("Access.buildTable::groupTable     accessArray[" + rowCounter + "]: " + dojo.toJson(accessArray[rowCounter], true));
		accessArray[rowCounter].parentWidget = this;
		var accessRow = new AccessRow(accessArray[rowCounter]);
	//console.log("Access.buildTable::groupTable     Doing group rows, accessRow: " + accessRow);
	//console.log("Access.buildTable::groupTable     Doing group rows, accessRow.row: " + accessRow.row);
		this.table.appendChild(accessRow.row);
		this.tableRows.push(accessRow);
	}
	//console.log("Access.buildTable     Completed buildTable");
	
},	// buildTable

togglePermission : function (event) {
	var parentNode = event.target.parentNode;
	////console.log("Access.buildTable     parentNode: " + parentNode);
	
	var nodeClass = event.target.getAttribute('class');
	if ( nodeClass.match('allowed') )
	{
		dojo.removeClass(event.target,'allowed');
		dojo.addClass(event.target,'denied');
	}
	else
	{
		dojo.removeClass(event.target,'denied');
		dojo.addClass(event.target,'allowed');
	}
},

saveAccess : function () {
	////console.log("Access.saveAccess     plugins.sharing.Access.saveAccess()");
	////console.log("Access.saveAccess     this.tableRows.length: " + this.tableRows.length);

	// COLLECT DATA HERE
	var dataArray = new Array;
	for ( var i = 0; i < this.tableRows.length; i++ )
	{
		var data = new Object;
		data.owner 		= Agua.cookie('username');
		data.groupname	= this.tableRows[i].args.groupname;
		for ( var j = 1; j < this.rights.length; j++ )
		{
			data[this.rights[j]] = 0;
			if ( dojo.hasClass(this.tableRows[i][this.rights[j]], 'allowed') )
				data[this.rights[j]] = 1;
		}
		dataArray.push(data);
	}

	// CREATE JSON QUERY
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username = Agua.cookie('username');
	query.sessionid = Agua.cookie('sessionid');
	query.mode = "saveAccess";
	query.module = "Agua::Sharing";
	query.data = dataArray;
	////console.log("Access.saveAccess     query: " + dojo.toJson(query));
	
	// SEND TO SERVER
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			handle: function(response, ioArgs) {
				Agua.toast(response);
			}
		}
	);
}


}); 	//	end declare

});	//	end define


