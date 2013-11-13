dojo.provide("plugins.sharing.Access");

// ALLOW THE ADMIN USER TO ADD, REMOVE AND MODIFY USERS

// NEW USERS MUST HAVE username AND email

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");
dojo.require("plugins.core.Common");

// FORM VALIDATION
dojo.require("plugins.form.TextArea");

// HAS A
dojo.require("plugins.sharing.UserRow");

dojo.declare("plugins.sharing.Access",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
	//Path to the template of this widget. 
	templatePath: dojo.moduleUrl("plugins", "sharing/templates/access.html"),

	// Calls dijit._Templated.widgetsInTemplate
	widgetsInTemplate : true,
	
	// Calls dijit._Templated.widgetsInTemplate
	widgetsInTemplate : true,
	
	//title : "<span class='sharingHeader'> Access </span> Manage Access to Groups",        
	objectStore : null,
	tableId : "sharingAccessTable",
	tableRowConnections: new Array,
	deleteRadioId : "sharingAccessDeleteRadio",
	
	// OR USE @import IN HTML TEMPLATE
	cssFiles : [ "plugins/sharing/css/access.css" ],
	
	// PARENT WIDGET
	parentWidget : null,

	constructor : function (args) {
		//console.log("Access.constructor     plugins.sharing.Access.constructor()");

		// GET INFO FROM ARGS
		this.parentWidget = args.parentWidget;
		this.tabContainer = args.tabContainer;

		this.loadCSS();
	},

	postMixInProperties: function() {
	},

	postCreate: function() {
		this.startup();
	},

	startup : function () {
		//console.log("Clusters.startup    plugins.sharing.Clusters.startup()");

		// COMPLETE CONSTRUCTION OF OBJECT
		this.inherited(arguments);	 

		// ADD ADMIN TAB TO TAB CONTAINER		
		this.attachPoint.addChild(this.accessTab);
		this.attachPoint.selectChild(this.accessTab);

		////////console.log("Access.++++ plugins.sharing.Access.postCreate()");
		this.buildTable();

	},

	groupTable : function () {
		//console.log("Access.groupTable    plugins.sharing.Access.groupTable()");
		
	},
	// BUILD USERS TABLE
	buildTable : function () {
		//console.log("Access.buildTable     plugins.sharing.Access.buildTable()");
		
		// GET ACCESS TABLE DATA
		var accessArray = Agua.getAccess();
	
		// SET STORE
		var data = {identifier: "project", items: []};
		for ( var i = 0; i < accessArray.length; i++ )
		{
			data.items[i] = accessArray[i];
		}
		//console.log("Access.buildTable     data: " + dojo.toJson(data));
	
		var objectStore = new dojo.data.ItemFileWriteStore(	{	data: data	}	);
		this.objectStore = objectStore;
		//console.log("Access.buildTable     this.objectStore: " + dojo.toJson(this.objectStore));
		
		//General Structure
		// http://dojotoolkit.org/reference-guide/dojo.store.Memory.html		
		//The ItemFileReadStore expects a specific structure to its data, as defined below:		
		//{
		//	"label": "some attribute",   //Optional attribute used to indicate which attribute on an item should act as a human-readable label for display purposes.
		//	
		//	
		//	"identifier": "some attribute",  //Optional attribute used to indicate which attribute on an item acts as a unique identifier for that item. If it is not defined, then the ItemFileReadStore will simply number the items and use that number as a unique index to the item.
		//	
		//	
		//	"items:" [  //The array of JavaScript objects that act as the root items of the data store
		//			{ /* Some set of name/value attributes */ },
		//			{ /* ... */ },
		//			...
		//	]
		//}

		// WRITE TABLE BASED ON ITEMS IN STORE REQUEST
		var sharingAccess = this;
		var groupTable = function(items, request)
		{
				//console.log("Access.buildTable::groupTable     groupTable(items, request)");
				//console.log("Access.buildTable::groupTable     items.length: " + items.length);
			
			// CREATE TABLE sharingAccessTable 
			if ( document.getElementById(sharingAccess.tableId) )
			{
//					//////console.log("Access.buildTable::groupTable     table exists: " + sharingAccess.tableId);
				sharingAccess.domNode.removeChild(document.getElementById(sharingAccess.tableId));
//					//////console.log("Access.buildTable::groupTable     table removed: " + document.getElementById(sharingAccess.tableId));
			}
			
			var table = document.createElement("table");
			table.setAttribute('class', 'sharingTable');
			table.id = sharingAccess.tableId;
			//console.log("Access.buildTable::groupTable     table: " + table);

				
			// APPEND TABLE TO RIGHT PANE
			//console.log("Access.buildTable::groupTable     sharingAccess: " + sharingAccess);
			//console.log("Access.buildTable::groupTable     sharingAccess.domNode: " + sharingAccess.domNode);

			sharingAccess.domNode.appendChild(table);
			//console.log("Access.buildTable::groupTable     AFTER sharingAccess.domNode.appendChild(table)");

			// CREATE HEADER ROW
			var headerRow = document.createElement("tr");
			headerRow.setAttribute('class', 'sharingHeaderRow');
			var headers = [ "Group", "Project", "Owner rights", "Group rights" , "World rights" ];
			var cols = [ 1, 1, 3, 3, 3 ];
			for ( var i = 0; i < headers.length; i++ )
			{
				var tableData = document.createElement("td");
				tableData.setAttribute('colspan', cols[i]);
				//tableData.setAttribute('class', 'sharingAccessTableHeader');
				var text = document.createTextNode(headers[i]);
				tableData.appendChild(text);
				headerRow.appendChild(tableData);
			}
			table.appendChild(headerRow);	

			var subHeaderRow = document.createElement("tr");
			subHeaderRow.setAttribute('class', 'sharingHeaderRow');
			var subHeaders = [ "", "", "Edit", "Copy", "View", "Edit", "Copy", "View", "Edit", "Copy", "View" ];
			for ( var i = 0; i < subHeaders.length; i++ )
			{
				var tableData = document.createElement("td");
				var text = document.createTextNode(subHeaders[i]);
				tableData.setAttribute('class', 'sharingAccessTableSubHeader');
				tableData.appendChild(text);
				subHeaderRow.appendChild(tableData);
			}
			table.appendChild(subHeaderRow);	

			//console.log("Access.buildTable::groupTable     after append headerRow to table");

			// SHOW PROJECT ACCESS INFO
			//console.log("Access.buildTable::groupTable     Doing group rows, items.length: " + items.length);
			for ( var rowCounter = 0; rowCounter < items.length; rowCounter++)
			{
				// CREATE TABLE ROW FOR EACH USER
				var tableRow = document.createElement("tr");
				tableRow.setAttribute('class', 'sharingAccessTableRow');
				tableRow.setAttribute('id', 'sharingAccessTableRow' + rowCounter);
				var item = items[rowCounter];
//					//////console.log("Access.buildTable::groupTable     item " + rowCounter + ": " + item);
				var data = [ sharingAccess.objectStore.getValue(item, 'groupname'), sharingAccess.objectStore.getLabel(item), sharingAccess.objectStore.getValue(item, 'ownerrights'), sharingAccess.objectStore.getValue(item, 'grouprights'), sharingAccess.objectStore.getValue(item, 'worldrights')];
//					//////console.log("Access.buildTable::groupTable     data: " + dojo.toJson(data));
				
				var columns = [];
				columns.push(data[0]);
				columns.push(data[1]);
				for ( var i = 2; i < data.length; i++ )
				{
					if ( data[i] == 7 )	{	columns.push(true, true, true);		}
					if ( data[i] == 6 )	{	columns.push(true, true, false);	}
					if ( data[i] == 5 )	{	columns.push(true, false, true);	}
					if ( data[i] == 4 )	{	columns.push(true, false, false);	}
					if ( data[i] == 3 )	{	columns.push(false, true, true);	}
					if ( data[i] == 2 )	{	columns.push(false, true, false);	}
					if ( data[i] == 1 )	{	columns.push(false, false, true);	}
					if ( data[i] == 0 )	{	columns.push(false, false, false);	}
				}
				
//					//////console.log("Access.buildTable::groupTable     item " + rowCounter + " columns: " + dojo.toJson(columns));

				// SHOW COLUMNS: USERNAME, FULL NAME, PASSWORD
				for ( var columnCounter = 0; columnCounter < columns.length; columnCounter++ )
				{
					var tableData = document.createElement("td");
					
					if ( columnCounter == 0 || columnCounter == 1 )
					{
						tableData.setAttribute('class', 'sharingAccessTableData');	
						var text = document.createTextNode(columns[columnCounter]);
						tableData.appendChild(text);
					}
					else
					{
						if ( columns[columnCounter] == true )
						{
							tableData.setAttribute('class', 'sharingAccessAllowed');	
						}
						else
						{
							tableData.setAttribute('class', 'sharingAccessDenied');	
						}
						
						// ADD ONCLICK TO TOGGLE CLASS
						dojo.connect(tableData, "onclick", function(event){
							sharingAccess.togglePermission(event);
						});
					}

					// APPEND TABLE DATA TO TABLE ROW
					tableRow.appendChild(tableData);							
				}

				// APPEND TABLE DATA TO TABLE ROW
				tableRow.appendChild(tableData);			
				
				// APPEND ROW TO TABLE
				table.appendChild(tableRow);
			}
		}; // groupTable

		//console.log("Access.buildTable     BEFORE store.fetch-> groupTable");
		var returned = this.objectStore.fetch( { query: "*", onComplete: groupTable});
		//var returned = this.objectStore.fetch( { query: {}, onComplete: groupTable});
		////console.log("Access.buildTable     returned: " + dojo.toJson(returned));
		//console.log("Access.buildTable     AFTER store.fetch-> groupTable");
		
	},	// buildTable


	togglePermission : function (event) {
//			//////console.log("Access.togglePermission     plugins.sharing.Access.togglePermission(event)");
		
		var target = event.target;
//			//////console.log("Access.togglePermission     target: " + target);
		
		var nodeClass = target.getAttribute('class');
		if ( nodeClass == 'sharingAccessAllowed' )
		{
			target.setAttribute('class', 'sharingAccessDenied');
		}
		else
		{
			target.setAttribute('class', 'sharingAccessAllowed');
		}
	},


	//// MAKE SURE THAT PERMISSIONS ARE NUMERIC AND BETWEEN 1 AND 7
	//checkPermissions : function (text)
	//{
	//	if ( ! text.match(/^\d+$/) ) return 1;
	//	if ( text < 1 )	return 1;
	//	if ( text > 7 ) return 1;
	//	
	//	return text;
	//},

	// CURRENTLY UNUSED CALLBACK FOR saveRow
	updateAccess : function (json) {
//			//////console.log("Access.updateAccess     plugins.sharing.Access.updateAccess(json)");
//			//////console.log("Access.updateAccess     json: " + json);
	},
	

	

	saveStore : function () {
//			//////console.log("Access.saveStore     plugins.sharing.Access.saveStore()");

		// COLLECT DATA HERE
		var dataArray = new Array;

		var rights = [ "ownerrights", "grouprights", "worldrights" ];
		var table = dojo.byId(this.tableId);
		var rows = table.childNodes;
		for ( var i = 2; i < rows.length; i++ )
		{
			var data = new Object;
			var tableDatas = rows[i].childNodes;
			data.project = tableDatas[0].innerHTML.toString();
			var rightsCounter = 0;
			for ( var j = 1; j < tableDatas.length; j++ )
			{
				var value = 0;
				var values = [ 4, 2, 1];
				for ( var k = 0; k < 3; k++ )
				{
					var node = tableDatas[(j + k)];
//						////////console.log("Access.saveStore    node " + k + ": " + node);
					var nodeClass = node.getAttribute('class').toString();
//						////////console.log("Access.saveStore    nodeClass " + k + ": " + nodeClass);
					if ( nodeClass == 'sharingAccessAllowed' )
					{
						value += values[k];
//							////////console.log("Access.saveStore    nodeClass == 'sharingAccessAllowed'. Adding to value: " + values[k]);
					}
				}
				
				data[rights[rightsCounter]] = value;
				rightsCounter++;
//					////////console.log("Access.saveStore    nodeClass: " + nodeClass);
				
				j+=2;
			}
			
			dataArray.push(data);
		}

		

		// SAVE FOR LATER: DO IT USING THE STORE			
		////////// print out for debugging
		////////var sharingAccess = this;
//			//////////////console.log("Access.saveStore     sharingAccess: " + sharingAccess);
		////////
		////////var store = this.objectStore;
//			//////////////console.log("Access.saveStore     store: " + store);
		////////
		////////for ( var i = 0; i < store._arrayOfTopLevelItems.length; i++ )
		////////{
//			////////	////////console.log("Access.saveDone    item " + i + ": " + store.getLabel(store._arrayOfTopLevelItems[i]));
		////////}
		////////
		////////// SEND TO SERVER AS RAW XHR POST
		////////var dataArray = new Array;
		////////for ( var i = 0; i < store._arrayOfTopLevelItems.length; i++ )
		////////{
//			////////	////////console.log("Access.saveDone    Processing item " + i + ": " + store.getLabel(store._arrayOfTopLevelItems[i]));
		////////	
		////////	var data = new Object;
		////////	var item = store._arrayOfTopLevelItems[i];
		////////	var attributes = store.getAttributes(item);
		////////	if (attributes && attributes.length > 0)
		////////	{
		////////		for ( var j = 0; j < attributes.length; j++ )
		////////		//for ( var j = 0; j < 1; j++ )
		////////		{
//			////////			////////console.log("Access.saveDone     attributes[" + j + "]: " + attributes[j]);
		////////			var values = store.getValues(item, attributes[j]);
//			////////			////////console.log("Access.saveDone     values: " + values);
//			////////			////////console.log("Access.saveDone     values.length: " + values.length );
		////////
		////////			if ( values )
		////////			{
//			////////				////////console.log("Access.saveDone     values is defined: " + values);
		////////				
		////////				// MULTI-VALUE ATTRIBUTE
		////////				if (values.length > 1 )
		////////				{
		////////					data[attributes[i]] = [];
		////////					for ( var k = 0; k < values.length; k++ )
		////////					{
		////////						var value = values[k];
//			////////						////////console.log("Access.saveDone     value: " + value);
		////////						data[attributes[j]].push(value);
		////////					}
//			////////					////////console.log("Access.saveDone     data: " + dojo.toJson(data));
		////////				}
		////////				// SINGLE VALUE ATTRIBUTE
		////////				else
		////////				{
//			////////					////////console.log("Access.saveDone     single value: " + values);
		////////					data[attributes[j]] = values[0];
//			////////					////////console.log("Access.saveDone     data: " + dojo.toJson(data));
		////////				}
		////////			}
		////////		}
		////////		
//			////////		////////console.log("Access.saveDone     Finished attributes loop");
		////////	}
		////////	dataArray.push(data);
		////////}
//			//////////////console.log("Access.saveStore     dataArray: " + dojo.toJson(dataArray));

		var url = Agua.cgiUrl + "agua.cgi";
//			//////console.log("Access.saveStore     url: " + url);		

		// CREATE JSON QUERY
		var query = new Object;
		query.username = Agua.cookie('username');
		query.sessionid = Agua.cookie('sessionid');
		query.mode = "saveAccess";
		query.module = "Agua::Sharing";
		query.data = dojo.toJson(dataArray);
//			//////console.log("Access.saveStore     query: " + dojo.toJson(query));
		
		// SEND TO SERVER
		dojo.xhrPut(
			{
				url: url,
				contentType: "text",
				putData: dojo.toJson(query),
				timeout: 3000,
				load: function(response, ioArgs) {
//						//////console.log("Access.JSON Post worked.");
					return response;
				},
				error: function(response, ioArgs) {
//						//////console.log("Access.Error with JSON Post, response: " + response + ", ioArgs: " + ioArgs);
					return response;
				}
			}
		);
		
	}


}); // plugins.sharing.Access

