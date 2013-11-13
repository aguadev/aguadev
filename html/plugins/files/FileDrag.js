dojo.provide("plugins.files.FileDrag");

dojo.require("plugins.core.Common");
dojo.require("dojox.widget.RollingList");
dojo.require("plugins.files._GroupDragPane");
dojo.require("plugins.files._FileInfoPane");

dojo.declare("plugins.files.FileDrag",	
	[ plugins.core.Common, dojox.widget.RollingList ],
{
// summary: a specialized version of RollingList that handles file information
//  in a store

// CSS FILES
cssFiles : [
	dojo.moduleUrl("dojox") + "widget/Dialog/Dialog.css",
	dojo.moduleUrl("dojox") + "widget/RollingList/RollingList.css",
	dojo.moduleUrl("plugins.files") + "/FileDrag/FileDrag.css"
],

templateString: "<div class=\"dojoxRollingList ${className}\"\n\t><div class=\"dojoxRollingListContainer\" dojoAttachPoint=\"containerNode\" dojoAttachEvent=\"onkeypress:_onKey\"\n\t></div\n\t><div class=\"dojoxRollingListButtons\" dojoAttachPoint=\"buttonsNode\"\n        ><button dojoType=\"dijit.form.Button\" dojoAttachPoint=\"okButton\"\n\t\t\t\tdojoAttachEvent=\"onClick:_onExecute\">${okButtonLabel}</button\n        ><button dojoType=\"dijit.form.Button\" dojoAttachPoint=\"cancelButton\"\n\t\t\t\tdojoAttachEvent=\"onClick:_onCancel\">${cancelButtonLabel}</button\n\t></div\n></div>\n",

className: "dojoxFileDrag",

// pathSeparator: string
//  Our file separator - it will be guessed if not set
pathSeparator: "",

// topDir: string
//	The top directory string - it will be guessed if not set
topDir: "",
	
// parentAttr: string
//	the attribute to read for finding our parent directory
parentAttr: "parentDir",

// pathAttr: string
//  the attribute to read for getting the full path of our file
pathAttr: "path",

// path: string
// full path to file
path : '',

// core: object
// Contains refs to higher objects in hierarchy
// e.g., { folders: Folders object, files: XxxxxFiles object, ... }
core : null,

//////}}
	
constructor: function (args){
	this.inherited(arguments);
	
	//console.log("FileDrag.constructor    args:");
	//console.dir({args:args});
	this.core = args.core;
	this.path = args.path;
},
addChild: function (itemPane, index){
	//console.log("FileDrag.addChild    itemPane:");
	//console.dir({itemPane:itemPane});
	//console.log("FileDrag.addChild    index: " + index);
	
	//console.log("FileDrag.addChild    Doing this.inherited(arguments)");
	this.inherited(arguments);
},
_itemsMatch: function(/*item*/ item1, /*item*/ item2){
	// Summary: returns whether or not the two items match - checks ID if
	//  they aren't the exact same object - ignoring trailing slashes

	return true;
},
selectChild : function (childName) {
	//////console.log("FileDrag.selectChild    childName: " + childName);
	
	dojo.forEach(this.getChildren(), function(child, index){
			
		//////console.log("FileDrag.selectChild    child " + index + ": ");
		////////console.dir(child)
		
	});
},
// RELOAD THE WHOLE FILE PANE
reload : function () {
	//////console.log("FileDrag.reload	plugins.files.FileDrag.reload()");

	// DESTROY CHILD WIDGETS
	//////console.log("FileDrag.reload	Doing this._removeAfter(0)");
	this._removeAfter(0);
	
	// SET this._started TO FALSE
	this._started = false;
	
	// DO startup
	this.load();
},
startup: function(){
	//console.group("FileDrag-" + this.id + "    startup");
	//console.log("FileDrag.startup    plugins.files.FileDrag.startup()");
	//console.log("FileDrag.startup    this:");
	
	// HACK TO SET WIDTH AND HEIGHT
	this.domNode.setAttribute('style', 'height: auto !important; width: auto !important; overflow-y: scroll !important; overflow-x: hidden !important; border: none !important;');
	
	this.buttonsNode.setAttribute('style', 'display: none !important');

	// LOAD CSS
	this.loadCSS(this.cssFiles);

	if(this._started){ return; }

	//////console.log("FileDrag.startup	BEFORE this.inherited(arguments)");
	this.inherited(arguments);
	//////console.log("FileDrag.startup	AFTER this.inherited(arguments)");

	// Figure out our file separator if we don't have it yet
	var conn, child = this.getChildren()[0];
	//////console.log("FileDrag.startup	AFTER var conn, child = this.getChildren()[0]");
	
	var setSeparator = dojo.hitch(this, function(){
		//console.log("FileDrag.startup	INSIDE setSeparator");
		
		if (conn) {
			this.disconnect(conn);
		}
		delete conn;
		var item = child.items[0];
		//console.log("FileDrag.startup    setSeparator    item:");
		//console.dir({item:item});
		
		if (item) {
			var store = this.store;
			var parent = store.getValue (item, this.parentAttr);
			var path = store.getValue (item, this.pathAttr);
			
			this.pathSeparator = this.pathSeparator || store.pathSeparator;
			if (!this.pathSeparator) {
				this.pathSeparator = path.substring (parent.length, parent.length + 1);
			}
			if (!this.topDir){
				this.topDir = parent;
				
				
				// AVOID ERROR: "TypeError: this.topDir is undefined"
				if ( ! this.topDir )	return;
				
				
				
				if (this.topDir.lastIndexOf (this.pathSeparator) !=  (this.topDir.length - 1)) {
					this.topDir += this.pathSeparator;
				}
			}
		}
	});
	
	
	if (!this.pathSeparator || !this.topDir) {
		if (!child.items){
			conn = this.connect (child, "onItems", setSeparator);
		}else{
			setSeparator ();
		}
	}
	//console.log("FileDrag.startup	AFTER setSeparator    this.topDir: " + this.topDir);

	//console.log("FileDrag.startup	END");
	//console.groupEnd("FileDrag-" + this.id + "    startup");
},
_removeAfter: function(/*Widget or int*/ idx){
	//////console.log("FileDrag._removeAfter	idx: " + idx);
	// summary: removes all widgets after the given widget (or index)
	
	if (typeof idx != "number" ){

		//////console.log("FileDrag._removeAfter	Doing idx = this.getIndexOfChild(idx)");

		idx = this.getIndexOfChild(idx);
	}
	
	var numberChildren = this.getChildren().length;
	//////console.log("FileDrag._removeAfter	numberChildren: " + numberChildren);

	//if ( idx < 0 )	{	idx = 0;	}		
	//if(idx >= 0)
	//{
		dojo.forEach(this.getChildren(), function(c, i){
			
			//if(i > idx || (idx == 0 && numberChildren > 0) )
			if(i > idx )
			{
				//////console.log("FileDrag._removeAfter	i (" + i + ") > idx (" + idx + "). Doing this.removeChild(c)");
				this.removeChild(c);
				//////console.log("FileDrag._removeAfter	AFTER this.removeChild(c)");
				
				//c.destroyRecursive();
				c.destroy();
				//////console.log("FileDrag._removeAfter	AFTER c.destroy()");
			}
		}, this);
	//}
	
	
	var children = this.getChildren(), child = children[children.length - 1];
	var selItem = null;
	while(child && !selItem){
		var val = child._getSelected ? child._getSelected() : null;
		if(val){
			selItem = val.item;
		}
		child = child.parentPane;
	}
	if(!this._setInProgress){
		this._setValue(selItem);
	}

	//////console.log("FileDrag._removeAfter	END FileDrag._removeAfter");
},
addChild: function(/*Widget*/ widget, /*int?*/ insertIndex){
	//////console.log("FileDrag.addChild	widget: " + widget);
	//////console.log("FileDrag.addChild	insertIndex: " + insertIndex);
			
	// summary: adds a child to this rolling list - if passed an insertIndex,
	//  then all children from that index on will be removed and destroyed
	//  before adding the child.

	this._removeAfter(insertIndex - 1);
	
	//////console.log("FileDrag.addChild     BEFORE this.inherited(arguments)");
	this.inherited(arguments);
	//////console.log("FileDrag.addChild     AFTER this.inherited(arguments)");
	
	if(!widget._started){
		widget.startup();
	}
	
	this.layout();
	
	if(!this._savedFocus){
		widget.focus();
	}
},
removeChild : function ( dragPane ) {
	
},
getChildItems: function(item){
	//////console.log("FileDrag.getChildItems	plugins.files.FileDrag.getChildItems(item)");


	var ret = this.inherited(arguments);
	
	
	// CHECK IF THE ITEM IS A DIRECTORY AND EMPTY
	if(!ret && this.store.getValue(item, "directory")){
		// It's an empty directory - so pass through an empty array
		ret = [];
	}
	
	return ret;
},
_getMenuItemForItem: function(/*item*/ item, /* dijit._Contained */ parentPane) {
// summary: returns a widget for the given store item.  The returned
//  item will be added to this widget's container widget.  null will
//  be passed in for an "empty" item. */

	var widgetItem;
	widgetItem = this.getMenuItemForItem(item, parentPane, null);

	// ADD this.store AND item TO WIDGET ITEM
	widgetItem.store = this.store;
	widgetItem.item = item;

//	if ( item && item.children )

	return widgetItem;
},
getMenuItemForItem: function(/*item*/ item, /* dijit._Contained */ parentPane, /* item[]? */ children){
	//////console.log("FileDrag.getMenuItemForItem	plugins.files.FileDrag.getMenuItemForItem(/*item*/ item, /* dijit._Contained */ parentPane, /* item[]? */ children)");

	if ( item == '<EMPTY>' )
	{
		var menuItem = {
			data : 'EMPTY',
			type : [ 'file' ]
		};
		return menuItem;	
	}

	//var parentWidgetNode = parentPane.parentWidget.domNode;
	//var childNodes = parentWidgetNode.childNodes;
	//var parentWidgetNode = parentPane.parentWidget.domNode;

	////console.log("FileDrag.getMenuItemForItem    Getting childNodes");
	var childNodes = this.parentWidget.domNode.childNodes;
	////console.log("FileDrag.getMenuItemForItem    childNodes.length: " + childNodes.length);
	
	var dragType = "workflow";
	if ( childNodes.length > 1 ) {
		dragType = "file";
	}

	// SET DND ITEM
	var menuItem = {
		data : item.name,
		type : [ dragType ]
	};
	
	return menuItem;
},
_getPaneForItem : function(/* item? */ item, /* dijit._Contained? */ parentPane, /* item[]? */ children){
	// OVERRIDE OF RollingList METHOD
	// summary: gets the pane for the given item, and mixes in our needed parts
	// Returns the pane for the given item (null if the root pane) - after mixing in
	// its stuff.

	//console.group("FileDrag-" + this.id + "    _getPaneForItem");

	//console.log("FileDrag._getPaneForItem	   caller: " + this._getPaneForItem.caller.nom);

	//console.log("FileDrag._getPaneForItem	   item: ");
	//console.dir({item:item});

	//console.log("FileDrag._getPaneForItem	   this.store: ");
	//console.dir({this_store:this.store});

	//console.log("FileDrag._getPaneForItem	   this.query: ");
	//console.dir({this_query:this.query});

	var pane = this.getPaneForItem(item, parentPane, children);

	// REQUIRED: SET 'store' OF RETURNED PANE FOR ITEM
	//console.log("FileDrag._getPaneForItem	   this.store: ");
	//console.dir({this_store:this.store});
		
	var parentPath = this.getPreviousParentPath();
	if ( ! parentPath ) {
		parentPath = this.store.path;
	}

	//console.log("FileDrag._getPaneForItem	   oooooooo BEFORE parentPath: " + parentPath);
	if ( item && item.name ) {
		if ( parentPath ) {
			parentPath += "/";
		}
		parentPath  += item.name
	}
	//console.log("FileDrag._getPaneForItem	   oooooooo AFTER parentPath: " + parentPath);
	
	//console.log("FileDrag._getPaneForItem	   Doing new plugins.dojox.data.FileStore");
	pane.store = new plugins.dojox.data.FileStore(
		{
			url					: 	this.store.url,
			putData				: 	this.store.putData,
			pathAsQueryParam	: 	true,
			path				:	parentPath,
			parentPath			:	parentPath,
			core				:	this.core
		}
	);

	pane.store.path = this.path;
	this.store.path = this.path;

	if ( item )
	{
		//////console.log("plugins.files.FileDrag._getPaneForItem    item && item.parentPath");
		// ADD CURRENT DIRECTORY TO PATH OF pane.store.path
		// I.E., pane.store.path = Project1/Workflow1/inputdir INSTEAD
		// OF JUST Project1/inputdir IN FETCH
		pane.store.path = item.parentPath ;
		//console.log("FileDrag._getPaneForItem    pane.store.path: " + pane.store.path);
		if ( pane.store.path == '' ) {
			//console.log("FileDrag._getPaneForItem    Setting pane.store.path = item.name : " + item.name);	
			pane.store.path = item.name;
		}
	
		// UPDATE FULL PATH IN FileStore's this.query
		// OTHERWISE WILL SUCCESSFULLY LOAD THE SAME BASE DIRECTORY (E.G., Project1) AGAIN AND AGAIN
		//console.log("plugins.files.FileDrag._getPaneForItem    BEFORE this.store.path: " + dojo.toJson(this.store.path, true));
		this.store.path += "/" + item.name
		//console.log("plugins.files.FileDrag._getPaneForItem    AFTER this.store.path: " + dojo.toJson(this.store.path, true));
	
		pane.path = item.parentPath + "/" + item.name;
		// NEEDED TO INCREMENT PATH
		pane.store.path = item.parentPath + "/" + item.name;
	}
	else
	{
		pane.path = this.path;
	}

	pane.store.parentPath = this.path;


	pane.parentWidget = this;
	pane.parentPane = parentPane || null;
	
	if( !item )
	{
		//console.log("FileDrag._getPaneForItem    !item. Setting pane.query = this.query: " + this.query);
		//console.dir({this_store:this.store});
	
		pane.query = this.query;
		pane.queryOptions = this.queryOptions;
	}
	else if ( children )
	{
		pane.items = children;
	}
	else {
		pane.items = [item];
	}

	//console.log("FileDrag._getPaneForItem    Returning pane: ");
	//console.dir({pane:pane});
	
	//console.groupEnd("FileDrag-" + this.id + "    _getPaneForItem");

	return pane;
},
getPaneForItem : function(/*item*/ item, /* dijit._Contained */ parentPane, /* item[]? */ children){
	//////console.log("FileDrag.getPaneForItem	plugins.files.FileDrag.getPaneForItem(/*item*/ item, /* dijit._Contained */ parentPane, /* item[]? */ children)");
//		//////console.log("FileDrag.getPaneForItem	   item: " + item);
	//console.log("FileDrag.getPaneForItem	   item: ");
	//console.dir({item:item});

	var groupDragPane = null;
	var path = '';
	
	// GET PATHS OF ALL CHILDREN
	var parentPath = '';
	var groupPanes = this.getChildren();
	if ( groupPanes ) {
		for ( var i = 0; i < groupPanes.length; i++ ) {
			//console.log("FileDrag.getPaneForItem	   groupPanes[" + i + "]: ");
			//console.dir({groupPane:groupPanes[i]});
		}	
	}

	//console.log("FileDrag.getPaneForItem	groupPanes.length: " + groupPanes.length);
	
	if ( groupPanes && groupPanes.length > 0 ) {
		parentPath = groupPanes[groupPanes.length - 1].store.path;
	}

	var path = parentPath;
	if ( item && item.path )
		path += "/" + item.path

	//console.log("FileDrag.getPaneForItem    XXXXXXXX parentPath: " + parentPath);
	//console.log("FileDrag.getPaneForItem    XXXXXXXX path: " + path);
	if ( item ) {
		//console.log("FileDrag.getPaneForItem    XXXXXXXX this.store.getValue(item, directory): " + dojo.toJson(this.store.getValue(item, "directory")));
	}

	if ( !item || (this.store.isItem(item) && groupPanes) || this.store.getValue(item, "directory") )
	{
		this.core.filedrag = this;
		
		groupDragPane = new plugins.files._GroupDragPane({
			parentPath		: 	parentPath,
			path			: 	path,
			fileMenu		: 	this.fileMenu,
			workflowMenu	: 	this.workflowMenu,
			folderMenu		: 	this.folderMenu,
			core			:	this.core
		});
		//console.log("FileDrag.getPaneForItem	   groupDragPane: " + groupDragPane);
	}
	else
	//if(this.store.isItem(item) && ! this.store.getValue(item, "directory"))
	{
		// GENERATE A FILE INFO PANE
		groupDragPane = new plugins.files._FileInfoPane({});
		
		// REMOVE dijitContentPane CLASS TO PREVENT overflow: auto CSS
		dojo.removeClass(groupDragPane.domNode, 'dijitContentPane');
	}
		
	//console.log("FileDrag.getPaneForItem	   Returning groupDragPane: " + groupDragPane);
	//console.dir({groupDragPane:groupDragPane});

	return groupDragPane;
},
getPreviousParentPath : function () {
// GET parentPath FOR NEWLY CREATED _GroupDragPane CHILD
// FROM parentPath OF PRECEDING CHILD
	var parentPath = '';
	var groupPanes = this.getChildren();
	if ( groupPanes ) {
		for ( var i = 0; i < groupPanes.length; i++ ) {
			//console.log("FileDrag.getPreviousParentPath	   groupPanes[" + i + "]: ");
			//console.dir({groupPane:groupPanes[i]});
		}	
	}

	//console.log("FileDrag.getPreviousParentPath	groupPanes.length: " + groupPanes.length);
	
	if ( groupPanes && groupPanes.length > 0 ) {
		parentPath = groupPanes[groupPanes.length - 1].store.path;
	}
	//console.log("FileDrag.getPreviousParentPath    XSXSXSXSX Returning parentPath: " + parentPath);

	return parentPath;
},
_setPathValueAttr: function(/*string*/ path){
	//////console.log("FileDrag._setPathValueAttr	plugins.files.FileDrag._setPathValueAttr(/*string*/ path)");
	// Summary: sets the value of this widget based off the given path
	if(!path){
		//this.attr("value", null);
		this.set("value", null);
		return;
	}
	if(path.lastIndexOf(this.pathSeparator) == (path.length - 1)){
		path = path.substring(0, path.length - 1);
	}
	this.store.fetchItemByIdentity({identity: path,
									onItem: dojo.hitch(this, "attr", "value"),
									scope: this});
},
_getPathValueAttr: function(/*item?*/val){
	//////console.log("FileDrag._getPathValueAttr	plugins.files.FileDrag._getPathValueAttr(/*item?*/val)");
	// summary: returns the path value of the given value (or current value
	//  if not passed a value)
	if(!val){
		val = this.value;
	}
	if(val && this.store.isItem(val)){
		return this.store.getValue(val, this.pathAttr);
	}else{
		return "";
	}
},
/*
//// loadingMessage: String
////	Message that shows while downloading
//loadingMessage: "<span class='dijitContentPaneLoading'>${loadingState}</span>", 
//
//// errorMessage: String
////	Message that shows if an error occurs
//errorMessage: "<span class='dijitContentPaneError'>${errorState}</span>", 
//
*/
onFetchStart: function(){

	//console.log("FileDrag.onFetchStart    plugins.files.FileDrag.onFetchStart()");

	//////console.log("FileDrag.onFetchStart	plugins.files.FileDrag.onFetchStart()");
	// summary:
	//		called before a fetch starts
	return this.loadingMessage;
},
onFetchError: function(/*Error*/ error){
	//////console.log("FileDrag.onFetchError	plugins.files.FileDrag.onFetchError(/*item?*/val)");
	//////console.log("FileDrag.onFetchError	error: " + dojo.toJson(error));

	// summary:
	//	called when a fetch error occurs.
	return this.errorMessage;
}
	
});
