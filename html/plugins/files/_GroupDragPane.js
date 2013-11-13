dojo.provide("plugins.files._GroupDragPane");

/* SUMMARY:  HANDLE GETTING SELECTED OBJECT IN DND LIST

	OVERRIDE onDropInternal(), onDropExternal()

	OR onDrop TO COVER BOTH ON THE source/target OBJECT.

*/

dojo.require("dojo.dnd.Source");
dojo.require("dijit.Menu");
dojo.require("dijit.InlineEditBox");

// HAS A
dojo.require("dojox.widget.Standby");
dojo.require("plugins.dojox.Timer");
dojo.require("plugins.files.Dialog");
dojo.require("plugins.dijit.Confirm");

dojo.declare("plugins.files._GroupDragPane",
	[dojox.widget._RollingListPane], {

// summary: a pane that will handle groups (treats them as menu items)

// templateString: string
//	our template
templateString: '<div><div dojoAttachPoint="containerNode"></div>' +
				'<div dojoAttachPoint="menuContainer">' +
					'<div dojoAttachPoint="menuNode"></div>' +
				'</div></div>',

// _dragSource: dijit.Menu
//  The menu that we will call addChild() on for adding items
_dragSource: null,

// dialog box to show copying
_copyBox : null,

// OBJECT-WIDE DEBUG STATUS
debug : false,

// polling : bool
// Whether or not the object is polling for completion 
polling : false,

// polling : bool
// Whether or not dragPane is loading
loading : false,

// core: object
// Contains refs to higher objects in hierarchy
// e.g., { folders: Folders.js object, files: XxxxxFiles.js object, ... }
core : null,

/////}}}}

constructor: function (args){
	this.inherited(arguments);
	
	//console.log("_GroupDragPane.constructor    ------------------ args:");
	//console.dir({args:args});
	this.core 		= args.core;
	this.path		=	args.path;
	this.parentPath	=	args.parentPath;
},
startup: function (){
	this.inherited(arguments);
	// 	RETURN IF THIS.LOADING == TRUE
	if ( this.loading )	{
		//console.log("_GroupDragPane.startup    Returning because this.loading == true");
		return;
	}
	
	// SET THIS.LOADING = FALSE
	//console.log("_GroupDragPane.startup    Setting this.loading = true");
	this.loading = true;

	// SET SEQUENCE AND STANDBY
	this.setSequence();
	this.setStandby();

	//console.groupEnd("_GroupDragPane-" + this.id + "    startup");
},
_doQuery: function () {
// summary: either runs the query or loads potentially not-yet-loaded items.
	this.isLoaded = false;

	this._setContentAndScroll(this.onFetchStart());

	this.store.fetch({
		query: this.path, 
		onComplete: function(items){
			this.items = items;
			this.onItems();
		}, 
		onError: function(e) {
			this._onError("Fetch", e);
		},
		scope: this
	});
},
onLoad : function (data) {
	
	// THIS.INHERITED
	//console.log("_GroupDragPane.onLoad    Doing this.inherited(arguments)");
	this.inherited(arguments);
	
	// SET THIS LOADING = FALSE
	//console.log("_GroupDragPane.onLoad    Setting this.loading = false");
	this.loading = false;

	//console.log("_GroupDragPane.onLoad    END");
},
_onLoadHandler: function(data){
// OVERRIDE TO AVOID THIS ERROR:
// Error undefined running custom onLoad code: This deferred has already been resolved

	// summary:
	//		This is called whenever new content is being loaded
	this.isLoaded = true;
	try{
		//this.onLoadDeferred.callback(data);
		//console.log("_GroupDragPane._onLoadHandler    Doing this.onLoad(data)");
		this.onLoad(data);
	}
	catch(e) {
		//////console.error('Error '+this.widgetId+' running custom onLoad code: ' + e.message);
	}


    //console.log("_GroupDragPane._onLoadHandler    END");
	
	//console.groupEnd("FileManager-" + this.id + "    roundRobin");
	//console.log("_GroupDragPane._onLoadHandler    Doing this.core.folders.roundRobin()");
	this.core.folders.roundRobin();
},
_loadCheck: function(/* Boolean? */ forceLoad){
// summary: checks that the store is loaded
	var displayState = this._isShown();
	if((this.store || this.items) && (forceLoad || (this.refreshOnShow && displayState) || (!this.isLoaded && displayState))){
		
		this.query = this.path;
		//console.log("_GroupDragPane._loadCheck    this.query: " + this.query);

		this._doQuery();
	}
},
_setContent: function(/*String|DomNode|Nodelist*/cont){
	if(!this._dragSource){
		// Only set the content if we don't already have a menu
		//this.inherited(arguments);
	}
},
createMenu : function (type) {
// ADD PROGRAMMATIC CONTEXT MENU
	//console.log("_GroupDragPane.createMenu     type: " + type);
	
	if ( type == "workflow" ) {
		if ( this.workflowMenu ) return this.workflowMenu.menu;
	}
	else if ( type == "folder" ) {
		if ( this.folderMenu ) return this.folderMenu.menu;
	}
	else {
		if ( this.fileMenu ) return this.fileMenu.menu;
	}
},
addItem : function (name, type, username, location) {
	// REMOVE EMPTY ITEM IF PRESENT
	this.removeEmptyItem();
	
	// INSERT NEW CHILD
	var item = new Object;
	item.name = name;
	item.type = [type];
	item.directory = true;
	item.parentPath = this.path;
	item.path = name;
	item.children = [];
	//console.log("_GroupDragPane.addItem    item: ");
	//console.dir({item:item});
	this.items.push(item);

	// SET FILECACHE
	var cacheItem = dojo.clone(item);
	Agua.setFileCache(username, location, cacheItem);

	// GENERATE CHILD
	var newChild = this.parentWidget._getMenuItemForItem(item, this);
	//console.log("_GroupDragPane.addItem    newChild: ");
	//console.dir({newChild:newChild});

	// INSERT CHILD
	this._dragSource.insertNodes(false, [ newChild ]);

	// ADD 'directory' CLASS TO NEW CHILD
	var allNodes = this._dragSource.getAllNodes();
	var node = allNodes[allNodes.length - 1];
	node.setAttribute("dndType", "file");
	dojo.addClass(node, "directory");
	
	// ADD item ATTRIBUTE ON NODE
	node.item = item;
	node.item._S = newChild.store;

	// ADD MENU
	var dynamicMenu = this.createMenu(type);
	//console.log("_GroupDragPane.addItem   dynamicMenu: ");
	//console.dir({dynamicMenu:dynamicMenu});
	
	// BIND THE MENU TO THE DND NODE
	dynamicMenu.bindDomNode(node);
	
	// CONNECT ONCLICK
	dojo.connect(node, "onclick", this, "onclickHandler");
},	
renameItem : function (dndItem, newItemName) {
	//console.log("WorkflowMenu.renameWorkflow     dndItem: ");
	//console.dir({dndItem:dndItem});
	var itemName = dndItem.item.name;
	//console.log("_GroupDragPane.renameItem    itemName: " + itemName);
	//console.log("_GroupDragPane.renameItem    newItemName: " + newItemName);

	// RENAME DND ITEM
	dndItem.innerHTML = newItemName;
	
	for ( i = 0; i < this.items.length; i++ ) {
		var itemObject = this.items[i];
		if ( itemObject.name == itemName ) {
			//console.log("_GroupDragPane.renameItem    Renaming item: " + i + ":");
			//console.log("_GroupDragPane.renameItem    itemObject: ");
			//console.dir({itemObject:itemObject});

			// REPLACE name AND path VALUES
			itemObject.name = newItemName;
			itemObject.path = newItemName;
			
			// REPLACE parentPath IN CHILDREN
				if ( itemObject.children.length ) {
					for ( var i = 0; i < itemObject.children.length; i++ ) {
						var parentPath = itemObject.children[i].parentPath;
						//console.log("_GroupDragPane.renameItem    child " + i + " parentPath: " + parentPath);
						var re = new RegExp(itemName + "$");
						parentPath = parentPath.replace(re, newItemName);
						//console.log("_GroupDragPane.renameItem    child " + i + " NEW parentPath: " + parentPath);
						itemObject.children[i].parentPath = parentPath;
					}
				}
			
			break;
		}
	}
},
deleteItem : function (dndItem) {
	//console.log("_GroupDragPane.deleteItem    dndItem: ");
	//console.dir({dndItem:dndItem});

	for ( i = 0; i < this.items.length; i++ ) {
		var itemObject = this.items[i];
		//console.log("_GroupDragPane.deleteItem    itemObject: ");
		//console.dir({itemObject:itemObject});
		if ( itemObject.name == dndItem.item.name ) {
			this.items.splice(i, 1);
			break;
		}
	}
	
	// DESTROY DND ITEM
	dojo.destroy(dndItem);

	// ADD 'EMPTY' ITEM IF NEEDED
	if ( ! this.items.length )	{
		this.addEmptyItem();
		//console.log("_GroupDragPane.deleteItem    Doing this.onItems()");
		this.onItems();
	}
	
	// REMOVE ALL DOWNSTREAM DRAG PANES
	var fileDrag = this.parentWidget;
	var children = fileDrag.getChildren();
	var index = children.length;
	for ( var i = 0; i < children.length; i++ ) {
		//console.log("_GroupDragPane.deleteItem    child " + i);
		//console.dir({child:children[i]});
		if ( children[i] == this ) {
			index  = i;
			break;
		}
	}
	//console.log("_GroupDragPane.deleteItem    children.length: " + children.length);
	//console.log("_GroupDragPane.deleteItem    index: " + index);
	
	// QUIT IF THIS IS THE LAST PANE
	if ( index == children.length )	return;
	
	// OTHERWISE, REMOVE ALL DOWNSTREAM PANES
	//console.log("_GroupDragPane.deleteItem    Doing fileDrag._removAfter(" + index + ")");
	fileDrag._removeAfter(index);
},
removeEmptyItem : function () {
    var nodes = this._dragSource.getAllNodes();
    //console.log("_GroupDragPane.removeEmptyItem    nodes:");
    //console.dir({nodes:nodes});
    var nodesCopy = dojo.clone(this._dragSource.getAllNodes());
    //console.dir({nodesCopy:nodesCopy});

    //console.log("_GroupDragPane.removeEmptyItem    nodes[0].item.name:");
    //console.dir({item:nodes[0].item.name});

    if ( nodes[0].item.name != "<EMPTY>" ) return;

	//console.log("_GroupDragPane.removeEmptyItem    Doing dndItems.splice(0, 1)");

	this.items.splice(0, 1);
	dojo.destroy(nodes[0]);
},
addEmptyItem : function () {
// INSERT A FAKE ITEM WITH NAME <EMPTY>
	//console.log("_GroupDragPane.addEmptyItem    this.parentPath: " + this.parentPath);
	//console.log("_GroupDragPane.addEmptyItem    this.path: " + this.path);

	if ( this.items.length ) return;

	var item = new Object;
	item.name = "<EMPTY>";
	item.parentPath = this.path;
	//console.log("_GroupDragPane.addEmptyItem    item: ");
	//console.dir({item:item});

	this.items.push(item);
},
inItems : function (itemName) {
// RETURN TRUE IF FILE NAME EXISTS IN THIS GROUP DRAG PANE, ELSE RETURN FALSE
	//console.log("_GroupDragPane.inItems    itemName: " + itemName);
	if ( itemName == null )	return;
	
	var dndItems = this._dragSource.getAllNodes();
	//console.log("_GroupDragPane.inItems    dndItems: ");
	//console.dir({dndItems:dndItems});
	
	for ( var i = 0; i < dndItems.length; i++ )
	{
		//console.log("_GroupDragPane.inItems    dndItems[i].innerHTML: " + dndItems[i].innerHTML);
		if ( itemName == dndItems[i].innerHTML )	return true;
	}
	
	return false;
},
onItems : function() {
//	called after a fetch or load - at this point, this.items should be set and loaded.
	//////console.log("_GroupDragPane.onItems    this.items.length: " + this.items.length);
	////////console.log("_GroupDragPane.onItems    this.items: " + dojo.toJson(this.items));	

	var thisObject = this;
	
	for ( var i = 0; i < this.items.length; i++)
	{			
		this.items[i].path = this.items[i].name;
	}	
	
	var selectItem, hadChildren = false;
	
	this._dragSource = this._getDragSource(
		{
			path: this.path,
			parentPath: this.parentPath
		}
	);

	// ADD THE STORE'S parentPath TO THE MENU
	this._dragSource.store = this.store;

	// IF THERE ARE NO ITEMS FOR THIS DIRECTORY,
	// INSERT A FAKE ITEM WITH NAME <EMPTY> 
	if ( ! this.items.length )	this.addEmptyItem()

	var child, selectMenuItem;
	if ( this.items.length )
	{
		dojo.forEach(
			this.items,
			function(item)
		{
			child = this.parentWidget._getMenuItemForItem(item, this);
			if ( child )
			{
				this._dragSource.insertNodes(false, [child]);
				var insertedNodes = this._dragSource.getAllNodes();
				var lastNode = insertedNodes[insertedNodes.length - 1];
				
				// ADD DATA STORE TO ITEM'S CHILDREN
				if ( item.children )
				{
					for ( var i = 0; i < item.children.length; i++ )
					{
						item.children[i]._S = item._S;
						var childParentPath;
						var fullPath = '';
						if ( item.parentPath )	fullPath = item.parentPath;
						if ( item.path )	{
							if ( fullPath )
								fullPath += "/" + item.path;
							else
								fullPath = item.path;
						}
						if ( fullPath )
							item.children[i].parentPath = fullPath;
					}
					////console.log("_GroupDragPane.onItems    [] []  [] [] [] [] [] [] [] [] [] [] Setting item.directory = true");
					item.directory = true;
				}

				// ADD ITEM TO THIS NODE
				lastNode.item = item;
				
				// SET CLASS
				dojo.hasClass(lastNode, "dojoxRollingListItemSelected");

				var applicationName = lastNode.innerHTML;
	
				// GET indexInParent - THE LEVEL OF THIS MENU IN THE PARENT
				var indexInParent = this.getIndexInParent();
	
				// SET nodeType BASED ON THE indexInParent TO COINCIDE WITH accept PARAMETER
				// OF DND SOURCE OF SAME LEVEL (E.G., Workflows CAN BE DRAGGED NEXT TO OTHER
				// WORKFLOWS BUT NOT INTO THE LOWER FILE DIRECTORIES)
				var nodeType;
				if ( indexInParent == 0 )
				{
					nodeType = 'workflow';
				}
				else
				{
					if ( item.directory == false || item.directory == "false" )
						nodeType = "file";
					else
						nodeType = "folder";
				}
				////console.log("_GroupDragPane.onItems    [] [] [] [] [] [] [] [] [] [] [] item: ");
				////console.dir({item:item});
				////console.log("_GroupDragPane.onItems    [] [] [] [] [] [] [] [] [] [] [] nodeType: " + nodeType);

				// GENERATE DYNAMIC DHTML MENU
				// AND BIND MENU TO THE DND NODE
				var dynamicMenu = thisObject.createMenu(nodeType);
				//////console.log("_GroupDragPane.onItems    dynamicMenu: " + dynamicMenu);
				if ( dynamicMenu != null )
				{
					dynamicMenu.bindDomNode( lastNode );
				}
				lastNode.setAttribute("dndType", nodeType);					

				// CONNECT ONCLICK
				dojo.connect(lastNode, "onclick", this, "onclickHandler");

				var _dragSource = this._dragSource;
				this._dragSource.onDropExternal = function(source, nodes, copy) {
					thisObject.onDropExternal(source, nodes, copy, _dragSource, item, lastNode);
				};
				
			} // if(child)
			
		}, this); // dojo.forEach(this.items, function(item)

	} // if ( this.items.length )
	
	// ADD dojo.connect TO DND SOURCE NODES
	//////console.log("_GroupDragPane.onItems    Adding dojo.connect to DND source nodes");
	var allNodes = this._dragSource.getAllNodes();
	//////console.log("_GroupDragPane.onItems    allNodes.length: " + allNodes.length);
	for ( var i = 0; i < allNodes.length; i++ ) {
		var node = allNodes[i];
		dojo.addClass(node, "fileDrag");

		if ( ! node.item.directory || node.item.directory == "false" )
		{
			dojo.addClass(node, "file");
			dojo.addClass(node, "fileClosed");
		}
		else
		{
			dojo.addClass(node, "directory");
			dojo.addClass(node, "directoryClosed");
		}
		
		var applicationName = node.innerHTML;

		// GET indexInParent - THE LEVEL OF THIS MENU IN THE PARENT
		var indexInParent = this.getIndexInParent();

		// SET nodeType BASED ON THE indexInParent TO COINCIDE WITH accept PARAMETER
		// OF DND SOURCE OF SAME LEVEL (E.G., Workflows CAN BE DRAGGED NEXT TO OTHER
		// WORKFLOWS BUT NOT INTO THE LOWER FILE DIRECTORIES)
		var nodeType;
		if ( indexInParent == 0 )
		{
			nodeType = 'workflow';
		}
		else
		{
			nodeType = "file";
		}
		node.setAttribute("dndType", nodeType);
	}	

	this.containerNode.innerHTML = "";		
	this.containerNode.appendChild(this.menuNode);
	this.parentWidget.scrollIntoView(this);
	
	//////console.log("_GroupDragPane.onItems    END");
	
	//////console.log("_GroupDragPane.onItems    BEFORE this.inherited(arguments)");
	this.inherited(arguments);
	//////console.log("_GroupDragPane.onItems    AFTER this.inherited(arguments)");

	////////console.log("_GroupDragPane.onItems    END OF SUB");
},
onDropExternal : function (source, nodes, copy, _dragSource, item, lastNode) {
/*
	OVERRIDE dojo.dnd.Source.onDropExternal TO NOTIFY SERVER OF CHANGES.

	COMPLETE THE COPY ON THE REMOTE FILESYSTEM AS FOLLOWS:
	
		1. CARRY OUT DND COPY
	   
		2. CHECK IF FILENAME ALREADY EXISTS, IF SO
			   DO POPUP TO CONFIRM OVERWRITE	
	   
		3. MESSAGE SERVER TO COPY FILES
	   
		4. SHOW ANIMATED 'COPYING' DIALOGUE
	   
		5. POLL SERVER FOR STATUS AND WAIT UNTIL COMPLETE
	   
		6. RELOAD THE PANE TO SHOW THE NEW FILE SYSTEM
*/

	//console.log("_GroupDragPane.onDropExternal    plugins.files._GroupDragPane.onDropExternal(source, nodes, copy, _dragSource, item, lastNode, childScope)");
	//console.log("_GroupDragPane.onDropExternal     source: " + source);
	//console.dir({node:nodes});
	//console.dir({_dragSource:_dragSource});
	//console.dir({item:item});
	//console.log("_GroupDragPane.onDropExternal     copy: " + copy);

	// SET this.lastNode
	this.lastNode = lastNode;
	this._dragSource = _dragSource;

	// RESET URL
	var location	=	this.store.putData.location;
	//console.log("_GroupDragPane.onDropExternal     location: " + location);
	
	var file = nodes[0].item.parentPath + "/" + nodes[0].item.path;
	var destination = this.path;
	if ( location && ! destination.match(/^\//) )
		destination = location + "/" + this.path;
	
	// DO copyFile
	//console.log("_GroupDragPane.onDropExternal     Doing this.checkFilePresent(file, destination)");
	this.checkFilePresent(file, destination);
},
checkFilePresent : function (file, destination) {
	//console.log("_GroupDragPane.checkFilePresent     file: " + file);
	//console.log("_GroupDragPane.checkFilePresent     destination: " + destination);

	// CHECK IF A FILE OR FOLDER WITH THE SAME NAME AS THE DROPPED 
	// FILE/FOLDER ALREADY EXISTS IN THIS FOLDER
	if ( this.inItems(file) ) {
		//console.log("_GroupDragPane.checkFilePresent     file ALREADY EXISTS: " + file);
		thisObject.confirmOverwrite(file, destination);
	}
	else {
		this.prepareCopy(file, destination);
		this.copyFile();
		this.delayedPollCopy();
	}
},
prepareCopy : function (file, destination) {
	// SET this.putData
	var putData = this.store.putData;
	//console.log("_GroupDragPane.prepareCopy     BEFORE putData: ");
	//console.dir({putData:putData});
	putData.mode 			=	"copyFile";
	putData.module 			=	"Folders";
	putData.sessionid		=	Agua.cookie('sessionid');
	putData.username		=	Agua.cookie('username');
	putData.file			=	file;
	putData.destination		=	destination;
	this.putData 	= 	putData;
	//console.log("_GroupDragPane.prepareCopy     this.putData: ");
	//console.dir({this_putData:this.putData});
},
confirmOverwrite : function(file, destination) {
	//console.log("_GroupDragPane.confirmOverwrite    file: " + file);
	//console.log("_GroupDragPane.confirmOverwrite    destination: " + destination);
	
	// SET CALLBACKS
	var thisObject = this;
	var yesCallback = function() {
		thisObject.prepareCopy(file, destination);
		thisObject.copyFile();
		thisObject.delayedPollCopy();
	};
	var noCallback = function() {};
	var title = "Delete file: " + file + "?";
	var message = "File already exists<br>Do you want to overwrite it?<br><span style='color: #222;'>Click 'Yes' to delete or 'No' to cancel</span>";
	//console.log("_GroupDragPane.confirmOverwrite    title: " + title);
	//console.log("_GroupDragPane.confirmOverwrite    message: " + message);

	// REFRESH CONFIRM WIDGET
	if ( this.confirm != null ) 	this.confirm.destroy();

	// SHOW DIALOGUE
	this.confirm = new plugins.dijit.Confirm({
		parentWidget : this,
		title: title,
		message : message,
		yesCallback : yesCallback,
		noCallback : noCallback
	});
	this.confirm.show();
},
copyFile : function () {
//	2. CHECK IF FILENAME ALREADY EXISTS AND IF SO CONFIRM OVERWRITE
	var putData = this.putData;
	//console.log("_GroupDragPane.copyFile    putData: ");
	//console.dir({putData:putData});

	var url = Agua.cgiUrl + "agua.cgi?";
	//console.log("_GroupDragPane.copyFile    url: " + url);

	// SHOW STANDBY
	this.standby.show();

	var thisObject = this;
	dojo.xhrPut({
		url: url,
		handleAs: "json-comment-optional",
		sync: false,
		putData: dojo.toJson(putData),
		handle: function(response){
			//console.log("_GroupDragPane.copyFile    response: ");
			//console.dir({response:response});
			if ( ! response || ! response.error ) {
				//console.log("_GroupDragPane.copyFile    Doing startPollCopy");
				thisObject.pollCopy();
			}
			else if ( response.error ) {
				// HIDE STANDBY
				thisObject.standby.hide();
	
				Agua.toastMessage({
					message: response.error,
					type: "error"
				});
			}
		}
	});
},
delayedPollCopy : function (delay) {
	//console.log("_GroupDragPane.delayedPollCopy    Doing this.sequence.go(commands, ...)");
	if ( ! delay ) delay = 6000;
	var commands = [
		{ func: [this.showMessage, this, "_GroupDragPane.delayedPollCopy"], pauseAfter: delay },
		{ func: this.pollCopy } // no array, just a function to call 
	];
	//console.log("_GroupDragPane.delayedPollCopy    commands: " + commands);
	//console.dir({commands:commands});
	
	this.sequence.go(commands, function(){ });	
},
showMessage : function (message)  {
	//console.log(message);
},
pollCopy : function() {
// 5. POLL SERVER FOR STATUS AND WAIT UNTIL COMPLETE
	if ( ! this.putData ) {
		if ( this.standby )
			this.standby.hide();
		return;
	}
	
	this.putData.modifier = "status";
	//console.log("_GroupDragPane.pollCopy    this.putData: ");
	//console.dir({this_putData:this.putData});

	var url = Agua.cgiUrl + "agua.cgi?";
	//console.log("_GroupDragPane.copyFile    url: " + url);

	var thisObject = this;
	var completed = false;
	dojo.xhrPut({
		url			: 	url,
		handleAs	: 	"json-comment-optional",
		sync		: 	false,
		putData		:	dojo.toJson(this.putData),
		handle		: 	function (response) {
			//console.log("_GroupDragPane.pollCopy    this.response: ");
			//console.dir({response:response});
			
			if ( response.status == 'completed' ) {
				thisObject.polling = false;
				thisObject.standby.hide();
				
				// DELETE EXISTING FILECACHE
				Agua.setFileCache(thisObject.putData.username, thisObject.putData.destination, null);
				
				// RELOAD PANE
				var putData = new Object;
				putData.mode 			=	"fileSystem";
				putData.module 			=	"Folders";
				putData.sessionid		=	Agua.cookie('sessionid');
				putData.username		=	thisObject.putData.username;
				putData.url				=	Agua.cgiUrl + "agua.cgi?";
				putData.path			=	putData.destination;
				thisObject.parentWidget.store.putData		=	putData;
				
				//console.log("_GroupDragPane.pollCopy    AFTER putData:");
				//console.dir({putData:putData});
			
				// SET this.url AND this.putData
				thisObject.url 		= 	putData.url;
				thisObject.putData 	= 	putData;
				
				thisObject.reloadPane();
			}
			else if ( response.error ) {
				thisObject.polling = false;
				thisObject.standby.hide();
			}
			else
				thisObject.delayedPollCopy();
		}
	});
},
setSequence : function () {
	this.sequence = new dojox.timing.Sequence({});
},
setStandby : function () {
	//console.log("_GroupDragPane.setStandby    _GroupDragPane.setStandby()");
	//if ( this.standby )	return this.standby;
	
	var id = dijit.getUniqueId("dojox_widget_Standby");
	this.standby = new dojox.widget.Standby ({
		target: this.parentWidget.domNode,
		//onClick: "reload",
		text: "Copying",
		id : id,
		url: "plugins/core/images/agua-biwave-24.png"
	});
	document.body.appendChild(this.standby.domNode);
	//console.log("_GroupDragPane.setStandby    this.standby: " + this.standby);

	return this.standby;
},
reloadPane : function() {
	//console.group("_GroupDragPane-" + this.id + "    reloadPane");
	
	//console.log("_GroupDragPane.reloadPane    plugins.files._GroupDragPane.reloadPane()");
	var item = this.lastNode.item;
	//console.log("_GroupDragPane.reloadPane    item: ");
	//console.dir({item:item});
	
	var children = item.children;
	if ( ! children )
		children = item.items;
	
	// CHANGE item PATH, NAME AND PARENTPATH TO ONE FOLDER UP
	item = this.itemParent(item);
	
	var itemPane = this.parentWidget._getPaneForItem(item, this._dragSource, children);
	this.query = itemPane.store.query;
	if ( itemPane )
	{
		var paneIndex = this.getIndexInParent();
		this.parentWidget.addChild( itemPane, this.getIndexInParent() );
	}

	//console.groupEnd("_GroupDragPane-" + this.id + "    reloadPane");
},
itemParent : function(item) {
	//console.log("_GroupDragPane.itemParent(item)");
	//console.dir({item:item});
	
	// SET DIRECTORY = TRUE
	item.directory = true;
	
	// CHANGE NAME, PATH AND PARENTPATH
	//
	// 1. IF PARENTPATH CONTAINS MULTIPLE LEVELS,
	// 		E.G., 'Project1/Workflow1-assembly'
	if ( item.parentPath.match(/^.+\/([^\/]+)$/) )
	{
		item.path = item.parentPath.match(/^(.+?)\/([^\/]+)$/)[2];
		item.parentPath = item.parentPath.match(/^(.+?)\/([^\/]+)$/)[1];
	}

	// 2. IF PARENTPATH IS AT THE TOP LEVEL, E.G., 'Project1',
	// 		SET PATH = PARENTPATH AND PARENTPATH = '' 
	else if ( item.parentPath.match(/\/*[^\/]+$/) )
	{
		item.path = item.parentPath;
		item.parentPath = '';
	}						
	item.name = item.path;
	//item.parentPath = item.parentPath.match(/^(.+?)\/[^\/]+$/)[1];

	//console.log("_GroupDragPane.itemParent    Returning item:");
	//console.dir({item:item});
	return item;
},
onclickHandler : function (e) {
// HANDLE CLICK ON FILE OR FOLDER
	//console.group("_GroupDragPane-" + this.id + "    onClickHandler");
	//console.log("_GroupDragPane._onClickHandler    XXXXXXXXXXXXXXXXXXXXXXXXXxx e.target.item: ");

	//console.dir({e_target_item:e.target.item});
	//console.log("_GroupDragPane._onClickHandler    XXXXXXXXXXXXXXXXXXXXXXXXXxx this: " + this);

	
	// GET THE CLICKED DND SOURCE ITEM NODE
	var item = e.target.item;
	var children = item.children || item.items;

	
	var itemPane = this.parentWidget._getPaneForItem(item, this, children);

	// SET this.query TO itemPane.store.query
	this.query = itemPane.store.query;
	//console.log("_GroupDragPane._onClickHandler    this.query: " + dojo.toJson(this.query, true));
	
	if(itemPane)
	{
		// CALLS addChild IN FileDrag
		// summary: adds a child to this rolling list - if passed an insertIndex,
		//  then all children from that index on will be removed and destroyed
		//  before adding the child.
		//console.log("_GroupDragPane._onClickHandler    Doing this.parentWidget.addChild(itemPane, " + (this.getIndexInParent() + 1) + ")");
		
		this.parentWidget.addChild(itemPane, this.getIndexInParent() + 1);
	}
	else
	{
		this.parentWidget(this);
		this.parentWidget._onItemClick(null, this, selectMenuItem.item, selectMenuItem.children);
	}

	//console.groupEnd("_GroupDragPane-" + this.id + "    onClickHandler");
},
focus: function (force){
	// summary: sets the focus to this current widget

	
	if(this._dragSource){
		if(this._pendingFocus){
			this.disconnect(this._pendingFocus);
		}
		delete this._pendingFocus;
		
		// We focus the right widget - either the focusedChild, the
		//   selected node, the first menu item, or the menu itself
		var focusWidget = this._dragSource.focusedChild;
		if(!focusWidget){
			var focusNode = dojo.query(".dojoxRollingListItemSelected", this.domNode)[0];
			if(focusNode){
				focusWidget = dijit.byNode(focusNode);
			}
		}
		
		if(!focusWidget){
			focusWidget = this._dragSource.getAllNodes()[0] || this._dragSource;
		}

		this._focusByNode = false;

		if(focusWidget.focusNode){
			if(!this.parentWidget._savedFocus || force){
				try{focusWidget.focusNode.focus();}catch(e){}
			}
			window.setTimeout(function(){
				try{
					dijit.scrollIntoView(focusWidget.focusNode);
				}catch(e){}
			}, 1);
		}else if(focusWidget.focus){
			if(!this.parentWidget._savedFocus || force){
				focusWidget.focus();
			}
		}else{
			this._focusByNode = true;
		}
		this.inherited(arguments);
	}else if(!this._pendingFocus){
		this._pendingFocus = this.connect(this, "onItems", "focus");
	}
	else
	{
	}
	
},
_getDragSource: function(){
	// summary: returns a widget to be used for the container widget.
	// GET UNIQUE ID FOR THIS MENU TO BE USED IN DND SOURCE LATER
	var objectName = "dojo.dnd.Source";
	var id = dijit.getUniqueId(objectName.replace(/\./g,"_"));
	//var id = dijit.getUniqueId(this.declaredClass.replace(/\./g,"_"));

	// SET THE MENU NODE'S ID TO THIS NEW ID
	this.menuNode.id = id;

	// GET indexInParent - THE LEVEL OF THIS DRAG SOURCE IN THE PARENT
	var indexInParent = this.getIndexInParent();
	
	// SET accept BASED ON THE indexInParent
	
	var acceptType;
	if ( indexInParent == 0 )
	{
		acceptType = 'workflow';
	}
	else
	{
		acceptType = "file";
	}

	// GENERATE DND SOURCE WITH UNIQUE ID
	var dragSource = new dojo.dnd.Source(
		id,
		{
			accept: [ acceptType ],
			copyOnly: true
		}
	);
		
	// SET baseClass
	this.menuNode.setAttribute('class', 'fileDrag');
	
	// SET PARENTPATH AND PATH
	if ( this.path )
	{
		dragSource.path = this.path;
	}
	if ( this.parentPath )
	{
		dragSource.parentPath = this.parentPath;
	}

	if(!dragSource._started){
		dragSource.startup();
	}

	return dragSource;
},
getPreviousPane : function () {
// RETURN THE PREVIOUS DRAG PANE IN THE FILE DRAG

	var fileDrag = this.parentWidget;
	//console.log("fileMenu.getPreviousPane    fileDrag: ");
	//console.dir({fileDrag:fileDrag});
	//console.dir({fileDrag:fileDrag});
	
	var index = 0;
	var children = fileDrag.getChildren();
	//console.log("fileMenu.getPreviousPane    children.length: " + children.length);
	
	for ( var i = 0; i < children.length; i++ ) {
		if ( children[i] == this ) {
			index = i;
			break;
		}
	}

	if ( index == 0 )    return null;
	return children[index - 1];
}

});

