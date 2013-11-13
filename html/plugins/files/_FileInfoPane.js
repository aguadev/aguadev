dojo.provide("plugins.files._FileInfoPane");

dojo.require("plugins.core.Common");
dojo.require("dojox.widget.RollingList");
//dojo.require("dojo.i18n"); 
//dojo.requireLocalization("dojox.widget", "FileDrag", null, ""); 

//dojo.require("plugins.files._GroupDragPane");

dojo.declare("plugins.files._FileInfoPane", 
	[dojox.widget._RollingListPane], {

	// summary: a pane to display the information for the currently-selected
	//	file

	// templateString: string
	//	delete our template string
	templateString: "",
	
	//Path to the template of this widget. 
	templatePath: dojo.moduleUrl("plugins", "files/templates/infopane.html"),
	
	//// templatePath: String. Our template path
	//templateString:"<div class=\"dojoxFileInfoPane\">\r\n\t<table>\r\n\t\t<tbody>\r\n\t\t\t<tr>\r\n\t\t\t\t<td class=\"dojoxFileInfoLabel dojoxFileInfoNameLabel\">Filename </td>\r\n\t\t\t\t<td class=\"dojoxFileInfoName\" dojoAttachPoint=\"nameNode\"></td>\r\n\t\t\t</tr>\r\n\t\t\t<tr>\r\n\t\t\t\t<td class=\"dojoxFileInfoLabel dojoxFileInfoSizeLabel\">Size (bytes) </td>\r\n\t\t\t\t<td class=\"dojoxFileInfoSize\" dojoAttachPoint=\"sizeNode\"></td>\r\n\t\t\t</tr>\r\n\t\t\t<tr>\r\n\t\t\t\t<td class=\"dojoxFileInfoLabel dojoxFileInfoPathLabel\">Sample </td>\r\n\t\t\t\t<td class=\"dojoxFileInfoPath\" dojoAttachPoint=\"sampleNode\"></td>\r\n\t\t\t</tr>\r\n\t\t</tbody>\r\n\t</table>\r\n</div>\r\n",
	
	////}}


postMixInProperties: function(){
//	    ////////console.log("FileDrag.postMixInProperties	plugins.files.FileDrag.postMixInProperties()");
	//this._messages = dojo.i18n.getLocalization("dojox.widget", "FileDrag", this.lang);
	this.inherited(arguments);
},

onItems: function() {
	//////console.log("files._FileInfoPane.onItems	plugins.files._FileInfoPane.onItems()");
	//////console.log("files._FileInfoPane.onItems	this.parentWidget: " + this.parentWidget);

	// summary:
	//	called after a fetch or load - at this point, this.items should be
	//  set and loaded.
	var store = this.store, item = this.items[0];
//    //////console.log("files._FileInfoPane.onItems	////console.dir(this.store): ");
//	////console.dir(this.store);

	////console.log("files._FileInfoPane.onItems	////console.dir(item): ");
	////console.dir(item);

	
	if(!item){
		this._onError("Load", new Error("No item defined"));
	}
	else
	{
		//////console.log("files._FileInfoPane.onItems	////console.dir(item): ");
		//this.nameNode.innerHTML = store.getLabel(item);
		this.nameNode.innerHTML = store.getValue(item, "name");
		this.sampleNode.innerHTML = store.getValue(item, "sample");
		this.sizeNode.innerHTML = store.getValue(item, "size");			
		this.bytesNode.innerHTML = store.getValue(item, "bytes");			
		this.parentWidget.scrollIntoView(this);

	    ////console.log("files._FileInfoPane.onItems	////console.dir(this.containerNode): ");
		//////console.dir(this.containerNode);

		//////console.log("files._FileInfoPane.onItems	BEFORE this.inherited(arguments)");
		this.inherited(arguments);
		//////console.log("files._FileInfoPane.onItems	AFTER this.inherited(arguments)");

		//this._setContent(this.domNode, true);

		//this._setContentAndScroll(this.containerNode, false);

		//this.refresh();
		//this.parentWidget.scrollIntoView(this);

	}
},



_setContentAndScroll: function(/*String|DomNode|Nodelist*/cont, /*Boolean?*/isFakeContent){
// OVERRIDE TO AVOID this._setContent

// summary: sets the value of the content and scrolls it into view

	//////console.log("files._FileInfoPane._setContentAndScroll    files._FileInfoPane._setContentAndScroll(cont, isFakeContent)");
	//////console.log("files._FileInfoPane._setContentAndScroll    BEFORE this._setContent");

return;

	this._setContent(cont, isFakeContent);
	//////console.log("files._FileInfoPane._setContentAndScroll    AFTER this._setContent");

	this.parentWidget.scrollIntoView(this);
},


//	,
//	
///* OVERRIDE TO AVOID THIS ERROR:
//
//Error undefined running custom onLoad code: This deferred has already been resolved
//
//NB: this.onLoad(data) CALLS onLoad IN dijit.layout.ContentPane:
//
//	// EVENT's, should be overide-able
//	onLoad: function(data){
//		// summary:
//		//		Event hook, is called after everything is loaded and widgetified
//		// tags:
//		//		callback
//	},
//*/
//	_onLoadHandler: function(data){
//
////////console.log("plugins.files.FileInfoPane._onLoadHandler    plugins.files.FileInfoPane._onLoadHandler(data)");
////////console.log("plugins.files.FileInfoPane._onLoadHandler    data: " + data);
//		// summary:
//		//		This is called whenever new content is being loaded
//		this.isLoaded = true;
//		try{
//			this.onLoadDeferred.callback(data);
//			this.onLoad(data);
//		}catch(e){
//			////console.error('Error '+this.widgetId+' running custom onLoad code: ' + e.message);
//		}
//	}	
});

