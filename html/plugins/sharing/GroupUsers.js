dojo.provide("plugins.sharing.GroupUsers");

dojo.require("dijit.dijit"); // optimize: load dijit layer

// GENERAL FORM MODULES
dojo.require("dijit.form.Button");
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.form.ComboBox");
dojo.require("dojo.data.ItemFileWriteStore");

// DRAG N DROP
dojo.require("dojo.dnd.Source");

// SLIDER
dojo.require("dijit.form.Slider");

// PARSE
dojo.require("dojo.parser");

// INHERITS
dojo.require("plugins.core.Common");

// HAS A
dojo.require("plugins.sharing.GroupUserRow");


dojo.declare("plugins.sharing.GroupUsers",

	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/groupusers.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,
	
//addingSource STATE
addingSource : false,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ "plugins/sharing/css/groupusers.css" ],

// PARENT WIDGET
parentWidget : null,

// MAX. NO. OF USERS TO DISPLAY AT ANY ONE TIME IN DRAG SOURCE
maxDisplayedUsers : 24,

/////}}}

constructor : function(args) {
	// LOAD CSS
	this.loadCSS();		
},

postCreate : function() {
	this.startup();
},
startup : function () {
	//console.log("GroupUsers.startup    plugins.sharing.GroupUsers.start()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD ADMIN TAB TO TAB CONTAINER
	this.attachPoint.addChild(this.groupusersTab);
	this.attachPoint.selectChild(this.groupusersTab);

	// SET GROUP COMBO
	this.setGroupCombo();

	// SET DRAG SOURCE - LIST OF SOURCES
	this.setDragSource();

	// SET DRAG SOURCE SLIDER
	this.setDragSourceSlider();
	
	// SET DROP TARGET - SOURCES ALREADY IN THE GROUP
	this.setDropTarget();
	
	// SET TRASH DROP TARGET
	this.setTrash();
	
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateGroups");

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateUsers");
},

updateGroups : function (args) {
	//console.log("sharing.GroupUsers.updateGroups    sharing.GroupUsers.updateGroups(args)");
	//console.log("sharing.GroupUsers.updateGroups    args:");
	//console.dir(args);
	this.reload();
},

updateUsers : function (args) {
	//console.log("sharing.GroupUsers.updateUsers    sharing.GroupUsers.updateUsers(args)");
	//console.log("sharing.GroupUsers.updateUsers    args:");
	//console.dir(args);
	this.reload();
},

reload : function () {
// RELOAD THE GROUP COMBO AND DRAG SOURCE
// (CALLED AFTER CHANGES TO SOURCES OR GROUPS DATA IN OTHER TABS)

	//console.log("sharing.GroupUsers.reload    sharing.GroupUsers.reload()");

	// SET GROUP COMBO
	this.setGroupCombo();

	// SET DRAG SOURCE - LIST OF USERS
	this.setDragSource();

	// SET DROP TARGET - USERS ALREADY IN THE GROUP
	this.setDropTarget();
},

setGroupCombo : function () {
	//console.log("GroupUsers.setGroupCombo     plugins.sharing.GroupUsers.setGroupCombo()");

	// GET GROUP NAMES		
	var itemArray = Agua.getGroupNames();
	console.log("GroupUsers.setGroupCombo     itemArray");
	console.dir({itemArray:itemArray});
	
	var store = this.createStore(itemArray);
	
	// SET COMBO
	this.groupCombo.store = store;
	this.groupCombo.startup();
	//console.log("GroupUsers.setGroupCombo::setCombo     AFTER this.groupCombo.startup()");

	// SET COMBO VALUE
	var firstValue = itemArray[0];
	this.groupCombo.setValue(firstValue);
	//console.log("GroupUsers.setGroupCombo::setCombo     AFTER this.groupCombo.setValue(firstValue)");

	// CONNECT ONCLICK WITH dojo.connect TO BUILD TABLE
	var thisObject = this;
	dojo.connect(this.groupCombo, "onChange", function(event) {
		thisObject.setDropTarget();
	});
},

setDragSource : function (position) {
	//console.log("GroupUsers.setDragSource     plugins.sharing.GroupUsers.setDragSource(position)");
	//console.log("GroupUsers.setDragSource     position: " + position);

	// REMOVE ALL EXISTING CONTENT
	while ( this.dragSourceContainer.firstChild )
	{
		if ( dijit.byNode(this.dragSourceContainer)
			&& dijit.byNode(this.dragSourceContainer).destroy )
		{
			dijit.byNode(this.dragSourceContainer).destroy();
		}
		this.dragSourceContainer.removeChild(this.dragSourceContainer.firstChild);
	}

	// SET position IF NOT DEFINED
	if ( position == null )	position = 0;

	var dataArray = new Array;
	var userArray = Agua.getUsers();
	//console.log("GroupUsers.setDragSource     userArray: " + dojo.toJson(userArray));
	//console.log("GroupUsers.setDragSource     userArray.length: " + userArray.length);

	// RETURN IF USER ARRAY IS NULL OR EMPTY
	if ( userArray == null || userArray.length == 0 )
	{
		//console.log("GroupUsers.setDragSource     userArray is null or empty. Returning.");
		return;
	}

	var MAXUSERS = this.maxDisplayedUsers;
	var MULTIPLE = ( userArray.length - MAXUSERS ) / 100;
	MULTIPLE = MULTIPLE ? MULTIPLE : 1;
	var start = parseInt(position * MULTIPLE);
	var end = parseInt( (position * MULTIPLE) + MAXUSERS );
	if ( ! end || end > userArray.length )	end = userArray.length;
	if ( ! start || start < 0 )	start = 0;
	//console.log("GroupUsers.setDragSource     start: " + start);
	//console.log("GroupUsers.setDragSource     end: " + end);

	// GENERATE USER DATA TO INSERT INTO DND USER TABLE
	for ( var j = start; j < end; j++ )
	{
		var data = userArray[j];				
		dataArray.push( { data: data, type: ["draggableUser"] } );
	}
	//console.log("GroupUsers.setDragSource     dataArray: " + dojo.toJson(dataArray));

	// GENERATE DND SOURCE
	var dragSource = new dojo.dnd.Source(
		this.dragSourceContainer,
		{
			copyOnly: true,
			selfAccept: false,
			accept : [ "none" ]
		}
	);
	dragSource.insertNodes(false, dataArray);
	//console.log("GroupUsers.setDragSource     dragSource: " + dragSource);

	// users TABLE QUERY:
	// SELECT DISTINCT username, firstname, lastname, email, description FROM users ORDER BY username};

	// SET TABLE ROW STYLE IN dojDndItems
	var allNodes = dragSource.getAllNodes();
	for ( var k = 0; k < allNodes.length; k++ )
	{
		//console.dir({datarrayK:dataArray[k]});
		
		// ADD CLASS FROM type TO NODE
		var node = allNodes[k];

		// SET NODE name AND description
		node.username = dataArray[k].data["username"] ? dataArray[k].data["username"]: '';
		node.firstname = dataArray[k].data["firstname"] ? dataArray[k].data["firstname"]: '';
		node.lastname = dataArray[k].data["lastname"] ? dataArray[k].data["lastname"]: '';
		node.email = dataArray[k].data["email"] ? dataArray[k].data["email"]: '';
		node.description = dataArray[k].data["description"] ? dataArray[k].data["description"]: '';
		node.firstname = this.firstLetterUpperCase(node.firstname);
		node.lastname = this.firstLetterUpperCase(node.lastname);

		// CHECK ATTRIBUTES ARE NOT NULL
		if ( node.description == null )
			node.description = '';

		if ( node.username != null && node.username != '' )
		{
			var user = {
				username 	: node.username,
				email 		: node.email,
				firstname 	: node.firstname,
				lastname 	: node.lastname,
				description : node.description
			};
			//console.log("GroupUsers.setDragSource     user: " + dojo.toJson(user));
			user.parentWidget = this;			

			var groupUserRow = new plugins.sharing.GroupUserRow(user);
			node.innerHTML = '';
			node.appendChild(groupUserRow.domNode);
		}
	}

	var groupObject = this;
	dragSource.creator = function (item, hint)
	{
		//console.log("GroupUsers.setDragSource dragSource.creator         item: " + dojo.toJson(item));
		var node = dojo.doc.createElement("div");
		node.username = item["username"];
		node.firstname = item["firstname"];
		node.lastname = item["lastname"];
		node.email = item["email"];
		node.description = item["description"];
		node.id = dojo.dnd.getUniqueId();
		node.className = "dojoDndItem";

		// SET FANCY FORMAT IN NODE INNERHTML
		node.innerHTML = "<table> <tr><td><strong style='color: darkred'>" + item["username"] + "</strong></td></tr><tr><td> " + item["email"] + "</td></tr></table>";
		//console.log("GroupUsers.setDragSource dragSource.creator         node: " + node);

		return {node: node, data: item, type: ["text"]};
	};
},

setDragSourceSlider : function () {
	//console.log("GroupUsers.setDragSourceSlider     plugins.sharing.GroupUsers.setDragSourceSlider()");
	//console.log("GroupUsers.dragSourceSourceSlider     this.dragSourceSlider: " + this.dragSourceSlider);

	// ONMOUSEUP
	dojo.connect(this.dragSourceSlider, "onMouseUp", dojo.hitch(this, function(e)
	{
		var position = parseInt(this.dragSourceSlider.getValue());
		this.setDragSource(position);
	}));
},


setDropTarget : function () {
	//console.log("GroupUsers.setDropTarget     plugins.sharing.GroupUsers.setDropTarget()");

	// DELETE EXISTING CONTENTS OF DROP TARGET
	while ( this.dropTargetContainer.firstChild )
	{
		this.dropTargetContainer.removeChild(this.dropTargetContainer.firstChild);
	}
	//console.log("GroupUsers.setDropTarget     AFTER removeChild");

	//// GET THE SOURCES IN THIS GROUP
	var groupname = this.groupCombo.get('value');
	var sourceArray = Agua.getGroupUsers();
	//console.log("GroupUsers.setDropTarget     sourceArray: " + dojo.toJson(sourceArray));
	//console.log("GroupUsers.setDropTarget     groupname: " + groupname);
	sourceArray = this.filterByKeyValues(sourceArray, ["groupname"], [groupname]);
	sourceArray = this.filterByKeyValues(sourceArray, ["groupname"], [groupname]);
	//console.log("GroupUsers.setDropTarget     sourceArray: " + dojo.toJson(sourceArray));
	//sourceArray = this.sortHasharray(sourceArray, "name");
	
	if ( sourceArray == null )
	{
		//console.log("GroupUsers.setDropTarget     sourceArray is null or empty. Returning.");
		return;
	}		

	var dataArray = new Array;
	for ( var j = 0; j < sourceArray.length; j++ )
	{
		var data = sourceArray[j];				
		var description = sourceArray[j].description;
		dataArray.push( { data: data, type: ["draggableUser"], description: description  } );
	}
	//console.log("GroupUsers.setDropTarget     dataArray: " + dojo.toJson(dataArray));
	//console.log("GroupUsers.setDropTarget     dataArray.length: " + dataArray.length);

	// GENERATE DROP TARGET
	var dropTarget = new dojo.dnd.Source(
		this.dropTargetContainer,
		{
			accept : ["draggableUser"]
		}
	);
	dropTarget.insertNodes(false, dataArray );

	// SET TABLE ROW STYLE IN dojDndItems
	var allNodes = dropTarget.getAllNodes();
	for ( var k = 0; k < allNodes.length; k++ )
	{
		//console.log("GroupUsers.setDropTarget     GroupUsers.setDropTarget    dataArray[" + k + "]: " + dojo.toJson(dataArray[k]));

		// ADD CLASS FROM type TO NODE
		var node = allNodes[k];
		var nodeClass = dataArray[k].type;
		dojo.addClass(node, nodeClass);

		// SET NODE ATTRIBUTES
		node.username = dataArray[k].data.name;
		node.description = dataArray[k].data.description;

		// SWAP OUT location FOR email
		node.email = dataArray[k].data.location;

		var user = {
			username 	: node.username,
			email 		: node.email,
			firstname 	: '',
			lastname 	: '',
			description : node.description
		};
		//console.log("GroupUsers.setDropTarget     user: " + dojo.toJson(user));
		user.parentWidget = this;			

		var groupUserRow = new plugins.sharing.GroupUserRow(user);
		node.innerHTML = '';
		node.appendChild(groupUserRow.domNode);
	}
	
	var thisObject = this;
	dropTarget.creator = function (item, hint)
	{
		//console.log("GroupUsers.setDropTarget dropTarget.creator(item, hint)");
		//console.log("GroupUsers.setDropTarget dropTarget.creator         item: " + dojo.toJson(item));
		//console.log("GroupUsers.setDropTarget dropTarget.creator         hint: " + hint);

		// ADD VALUES TO NODE SO THAT THEY GET PASSED TO
		// this.addToGroup
		// NB: CONVERT name TO username
		var node = dojo.doc.createElement("div");
		node.name 			= item.username || item.name; 
		node.username 		= item.username || item.name;
		node.description 	= item.description || '';
		node.email 			= item.email || item.location;
		node.id 			= dojo.dnd.getUniqueId();
		node.className = "dojoDndItem";

		var user = {
			username 	: item.username || item.name,
			email 		: item.email || item.location,
			firstname 	: '',
			lastname 	: '',
			description : ''
		};
		//console.log("GroupUsers.setDropTarget    dropTarget.creator    user: " + dojo.toJson(user));
		user.parentWidget = this;			
		var groupUserRow = new plugins.sharing.GroupUserRow(user);

		//console.log("GroupUsers.setDropTarget    dropTarget.creator    groupUserRow: " + groupUserRow);
		node.innerHTML = '';
		node.appendChild(groupUserRow.domNode);

		// ACCEPTABLE NODE DROPPED ONTO SELF --> ADD TO USER GROUP.
		if ( hint != 'avatar' )
		{
			thisObject.addToGroup(node.username, node.description, node.email);
		}

		return {node: node, data: item, type: ["draggableUser"]};
	};
	
	// ADD NODE IF DROPPED FROM OTHER SOURCE, DELETE IF DROPPED FROM SELF
	dojo.connect(dropTarget, "onDndDrop", function(source, nodes, copy, target){
		//console.log("GroupUsers.setDropTarget dojo.connect onDndDrop    Checking if source == this && target != this");
		
		// NODE DROPPED FROM SELF --> DELETE NODE
		if ( source == this && target != this )
		{
			//console.log("GroupUsers.setDropTarget dojo.connect(onDndDrop)    source == this && target != this. Node has been moved to trash. Remove the user from the group object.");
			for ( var i = 0; i < nodes.length; i++ )
			{
				var node = nodes[i];
				thisObject.removeFromGroup(node.username, node.description, node.email);
			}
		}
		else {
			// DO NOTHING IF NODE WAS DROPPED FROM DRAG SOURCE
			// ( IT HAS ALREADY BEEN GENERATED BY dropTarget.creator() )
		}
		
		// REMOVE DUPLICATE NODES
		var currentNodes = dropTarget.getAllNodes();
		//console.log("GroupUsers.setDropTarget dojo.connect onDndDrop    currentNodes: " + currentNodes);
		if ( currentNodes == null || ! currentNodes )
		{
			//console.log("GroupUsers.setDropTarget dojo.connect onDndDrop    currentNodes is null or empty. Returning");
			return;
		}

		// DELETE DUPLICATE NODES
		var names = new Object;
		//console.log("GroupUsers.setDropTarget dojo.connect onDndDrop    Checking for duplicate nodes");
		for ( var i = 0; i < currentNodes.length; i++ )
		{
			var node = currentNodes[i];
			if ( ! names[node.username] )
			{
				names[node.username] = 1;
			}
			else
			{
				//console.log("GroupUsers.setDropTarget dojo.connect onDndDrop    Node " + node.username + " already in nodes. Removing.");
				
				// HACK TO AVOID THIS ERROR: node.parentNode is null
				try {
					//console.log("GroupUsers.setDropTarget dojo.connect onDndDrop    Removing duplicate node: " + node.username );
					node.parentNode.removeChild(node)
				}
				catch (e) {
					//console.log("GroupUsers.setDropTarget dojo.connect onDndDrop    INSIDE catch");
				}
			}

		}
	});
},

addToGroup : function (name, description, email ) {
	//console.log("GroupUsers.addToGroup    plugins.sharing.GroupUsers.addToGroup(name, description, email)");
	//console.log("GroupUsers.addToGroup    name: " + name);
	//console.log("GroupUsers.addToGroup    description: " + description);
	//console.log("GroupUsers.addToGroup    email: " + email);
	
	var groupObject = new Object;
	groupObject.username = Agua.cookie('username');
	groupObject.name = name;
	groupObject.description = description;
	groupObject.location = email;
	
	// ADD SOURCE OBJECT TO THE SOURCES IN THIS GROUP
	var groupName = this.groupCombo.get('value');
	//console.log("GroupUsers.addToGroup     groupName: " + groupName);

	if ( Agua.addUserToGroup(groupName, groupObject) == false )
	{
		//console.log("GroupUsers.addToGroup     Failed to add source to group: " + groupObject.name + ". Returning.");
		return;
	}

	// ADD THE SOURCE INTO THE groupusers TABLE ON THE SERVER
	var data = new Object;
	data.name 			= name;
	data.description 	= description	|| '';;
	data.location 		= email			|| '';
	data.groupname 		= groupName		|| '';
	data.type 			= "user";
	
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username = Agua.cookie('username');
	query.sessionid = Agua.cookie('sessionid');
	query.data = data;
	query.mode = "addToGroup";
	query.module = "Agua::Sharing";

	//var queryString = dojo.toJson(query).replace(/undefined/g, '""');
	//console.log("GroupUsers.addToGroup    queryString: " + queryString);

	this.doPut({ url: url, query: query, sync: false, timeout: 15000 });
},

removeFromGroup : function (name, description, email ) {
	//console.log("GroupUsers.removeFromGroup    plugins.sharing.GroupUsers.removeFromGroup(name, description, email)");
	//console.log("GroupUsers.removeFromGroup    name: " + name);
	//console.log("GroupUsers.removeFromGroup    description: " + description);
	//console.log("GroupUsers.removeFromGroup    email: " + email);

	// REMOVE SOURCE FROM THE SOURCES IN THIS GROUP
	var groupName = this.groupCombo.get('value');
	//console.log("GroupUsers.removeFromGroup     groupName: " + groupName);

	var groupObject = new Object;
	groupObject.name = name;
	groupObject.description = description;
	groupObject.email = email;
	//console.log("GroupUsers.addToGroup     groupObject: " + dojo.toJson(groupObject));

	if ( Agua.removeUserFromGroup(groupName, groupObject) == false )
	{
		//console.log("GroupUsers.removeFromGroup     Failed to remove source from group: " + groupObject.name + ". Returning.");
		return;
	}

	// REMOVE THE SOURCE FROM THE groupusers TABLE ON THE SERVER
	var data = new Object;
	data.name 			= String(name)	|| '';
	data.description 	= description	|| '';
	data.email 			= email			|| '';
	data.groupname 		= groupName		|| '';
	data.type 			= "user";
	
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username = Agua.cookie('username');
	query.sessionid = Agua.cookie('sessionid');
	query.data = data;
	query.mode = "removeFromGroup";
	query.module = "Agua::Sharing";

	this.doPut({ url: url, query: query, sync: false, timeout: 15000 });
},


setTrash : function () {
//	DELETE NODE IF DROPPED INTO TRASH. 
//	REMOVAL OF DATA IS ACCOMPLISHED IN THE
// onDndDrop LISTENER OF THE SOURCE
//console.log("GroupUsers.setTrash     plugins.sharing.GroupUsers.setTrash()");

	var trash = new dojo.dnd.Source(
		this.trashContainer,
		{
			accept : [ "draggableUser" ]
		}
	);

	// REMOVE DUPLICATE NODES
	dojo.connect(trash, "onDndDrop", function(source, nodes, copy, target){
		// NODE DROPPED ON SELF --> DELETE THE NODE
		if ( target == this )
		{
			var currentNodes = trash.getAllNodes();
			for ( var i = 0; i < currentNodes.length; i++ )
			{
				var node = currentNodes[i];
				// HACK TO AVOID THIS ERROR: node.parentNode is null
				try {
					node.parentNode.removeChild(node)
				}
				catch (e) {
				}
			}
		}
	});
}


}); // plugins.sharing.GroupUsers
