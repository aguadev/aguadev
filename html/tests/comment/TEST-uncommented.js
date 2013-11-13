dojo.provide("plugins.admin.Access");


 // // console.log("TEST");

dojo.require("dijit.dijit"); // optimize: load dijit layer

dojo.require("dijit.form.CheckBox");
////dojo.require("dijit.form.ValidationTextBox");
//dojo.require("dijit.form.RadioButton");
//dojo.require("dijit.form.ComboBox");

dojo.require("dijit.form.Slider");
dojo.require("dijit.form.FilteringSelect");
dojo.require("dijit.form.Button");

dojo.require("dijit.form.NumberSpinner");
dojo.require("dijit.Editor");
dojo.require("dijit.form.DateTextBox");
dojo.require("dijit.form.Textarea");

dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.ValidationTextBox");
dojo.require("dijit.form.NumberTextBox");
dojo.require("dijit.form.CurrencyTextBox");
dojo.require("dojo.currency");
dojo.require("dijit.Dialog");

dojo.require("dojo.data.ItemFileWriteStore");
dojo.require("dojox.grid.Grid");
dojo.require("dojo.parser");
//dojo.require("dojox.grid._data.model"); 


//http://www.ensembl.org/biomart/martview/e61a39e4e8e306354f8f2a7a70bbc53c/e61a39e4e8e306354f8f2a7a70bbc53c
//http://localhost:8080/Bioptic0.2.5/html/dojo.1.2.2/demos/
//http://localhost:8080/Bioptic0.2.5/html/dojo.1.2.2/dojox/form/tests/test_SelectStack.html
//Real World Dojo part 5: Custom Components
//http://www.dotnetmafia.com/blogs/jamesashley/archive/2008/10/28/761.aspx


dojo.require("plugins.core.form.Template");

dojo.declare(
    "plugins.admin.Access",
    plugins.core.form.Template,
    {
        //Path to the template of this widget. 
        templatePath: dojo.moduleUrl("", "../plugins/admin/templates/access.html"),

        // Calls dijit._Templated.widgetsInTemplate
        widgetsInTemplate : true,
        
        title : "<span class='adminHeader'> Access </span> Manage Access to Groups",        
        url : '',
        id : '',
		filename: '',
        loading : null,
		rightPaneId : '',
		groupStore : null,
		groupCombo : null,
		tableId : "adminAccessTable",
		tableRowConnections: new Array,
		deleteRadioId : "adminAccessDeleteRadio",
        
        // OR USE @import IN HTML TEMPLATE
        cssFiles : [ "plugins/admin/css/access.css" ],

		// ARRAY OF WIDGETS
        widgets : [ "loading"],
		// ARRAY OF WIDGET OBJECT
        widgetObjects : [],

        // Any initialization code would go here in the constructor.
		// plugins.report.Template and its superclasses dijit._Widget and
        // dijit._Templated do not have parameters in their constructors, so
        // there wouldn't be any multiple-inheritance complications
        // if you were to include some paramters here.
        constructor : function (args)
        {
			//plugins.admin.Access.superclass.constructor (args);
             //console.log("++++ plugins.admin.Access.constructor(args)");

			this.rightPaneId = args.rightPaneId;
			
 			console.log("constructor     plugins.admin.Users.constructor()");
 			console.log("constructor     this.rightPaneId: " + this.rightPaneId);
			this.loadCSS();
			this.buildTable();
        },

        //Inherited from dijit._Widget and called just before template
        //instantiation in buildRendering. This method is especially useful
        //for manipulating the template before it becomes visible.
        postMixInProperties: function()
        {
 			//console.log("++++ plugins.admin.Access.postMixInProperties()");
            //this.popup = new dijit.Dialog({});
        },


        //You can override this method to manipulate widget once it is
        //placed in the UI, but be warned that any child widgets contained
        //in it may not be ready yet.        
        postCreate: function()
        {
 			//console.log("++++ plugins.admin.Access.postCreate()");
        },



		// BUILD USERS TABLE
		buildTable : function ()
		{
 			console.log("buildTable     plugins.admin.Access.buildTable()");

			// GET GROUP STORE JSON
			var adminAccess = this;	
			var url = "http://localhost:8080/cgi-bin/agua/admin.cgi?";
			var query = new Object;
			query.username = Agua.cookie('username');
			query.sessionId = Agua.cookie('sessionId');
			query.mode = "getAccess";
 			console.log("buildTable     query: " + dojo.toJson(query));

 			console.log("buildTable     Getting store...");
			if ( ! this.groupStore )
			{
				// SEND TO SERVER
				dojo.xhrPut(
					{
						url: url,
						contentType: "text",
						sync : true,
						handleAs: "json",
						putData: dojo.toJson(query),
						timeout: 3000,
						load: function(data)
						{
 							console.log("buildTable     JSON Post worked.");
 							console.log("buildTable     data: " + dojo.toJson(data));
							var groupStore = new dojo.data.ItemFileWriteStore(	{	data: data	}	);
							adminAccess.groupStore = groupStore;
						},
						error: function(response, ioArgs) {
 							console.log("Error with JSON Post, response: " + response + ", ioArgs: " + ioArgs);
							return response;
						}
					}
				);
			}
 			console.log("buildTable     check this.groupStore: " + this.groupStore);
 			console.log("buildTable     this.groupStore._arrayOfTopLevelItems.length: " + this.groupStore._arrayOfTopLevelItems.length);
			
			// WRITE TABLE BASED ON ITEMS IN STORE REQUEST
			var groupTable = function(items, request)
			{
 				console.log("buildTable::groupTable     groupTable(items, request)");
 				console.log("buildTable::groupTable     items.length: " + items.length);
				
				// SET RIGHT PANE FOR APPENDING LATER
				var rightPaneId = adminAccess.rightPaneId;
				var rightPane = dijit.byId(rightPaneId);
 				console.log("buildTable::groupTable     rightPaneId: " + rightPaneId);
 				console.log("buildTable::groupTable     rightPane: " + rightPane);

				// CREATE TABLE adminAccessTable 
				if ( document.getElementById(adminAccess.tableId) )
				{
 					console.log("buildTable::groupTable     table exists: " + adminAccess.tableId);
					rightPane.domNode.removeChild(document.getElementById(adminAccess.tableId));
 					console.log("buildTable::groupTable     table removed: " + document.getElementById(adminAccess.tableId));
				}
				
				var table = document.createElement("table");
				table.setAttribute('class', 'adminAccessTable');
				table.id = adminAccess.tableId;
 				console.log("buildTable::groupTable     table: " + table);

					
				// APPEND TABLE TO RIGHT PANE
				rightPane.domNode.appendChild(table);
 				console.log("buildTable::groupTable     AFTER rightPane.domNode.appendChild(table)");


				// CREATE HEADER ROW
				var headerRow = document.createElement("tr");
				headerRow.setAttribute('class', 'adminHeaderRow');
				var headings = [ "Project", "Owner rights", "Group rights" , "World rights" ];
				for ( var i = 0; i < headings.length; i++ )
				{
					var tableData = document.createElement("td");
					tableData.setAttribute('class', 'adminDeleteButton');
					//if ( i == 0 )
					//{
					//	// REMOVE OLD BUTTON IF EXISTS
					//	var deleteButtonId = "adminDeleteButton";
					//	if ( dijit.byId(deleteButtonId) )
					//	{
					//		dijit.byId(deleteButtonId).destroy();
					//	}
					//
					//	// CREATE NEW DELETE BUTTON
					//	var deleteButton = new dijit.form.Button( { id: deleteButtonId } );
					//	deleteButton.attr('label', "Delete");
					//	deleteButton.attr('iconClass', "dijitEditorIcon dijitEditorIconDelete");
					//	deleteButton.attr("class", "deleteButton");
					//	dojo.connect( deleteButton, "onClick", function(event)
					//	{
					//		adminAccess.deleteAccess(event);
					//	});
					//
					//	tableData.appendChild(deleteButton.domNode);
					//}
					//else
					//{
						var text = document.createTextNode(headings[i]);
						tableData.appendChild(text);
					//}
					
					// APPEND TABLE DATA TO TABLE ROW
					headerRow.appendChild(tableData);
				}
				table.appendChild(headerRow);	

 				console.log("buildTable::groupTable     after append headerRow to table");


				// SHOW EACH USER'S DATA
 				console.log("buildTable::groupTable     Doing group rows, items.length: " + items.length);
				for ( var rowCounter = 0; rowCounter < items.length; rowCounter++)
				{
					// CREATE TABLE ROW FOR EACH USER
					var tableRow = document.createElement("tr");
					tableRow.setAttribute('class', 'adminAccessTableRow');
					tableRow.setAttribute('id', 'adminAccessTableRow' + rowCounter);
					var item = items[rowCounter];
 					console.log("buildTable::groupTable     item " + rowCounter + ": " + item);
					//var groupDesc = adminAccess.groupStore.getValue(item, 'groupdesc');
 					//console.log("buildTable::groupTable     groupDesc: " + groupDesc);
					//
					//var groupName = adminAccess.groupStore.getLabel(item);
 					//console.log("buildTable::groupTable     groupName: " + groupName);


					var columns = [ adminAccess.groupStore.getLabel(item), adminAccess.groupStore.getValue(item, 'ownerrights'), adminAccess.groupStore.getValue(item, 'grouprights'), adminAccess.groupStore.getValue(item, 'worldrights')];
					
 				console.log("buildTable::groupTable     item " + rowCounter + " columns: " + dojo.toJson(columns));

					// SHOW COLUMNS: USERNAME, FULL NAME, PASSWORD
					for ( var columnCounter = 0; columnCounter < columns.length; columnCounter++ )
					{
						var tableData = document.createElement("td");
						tableData.setAttribute('class', 'adminAccessTableData');	
						var text = document.createTextNode(columns[columnCounter]);
						tableData.appendChild(text);

						if ( columnCounter != 0 )
						{
							tableData.setAttribute('class', 'adminAccessTableNarrowColumn');
						}

						// APPEND TABLE DATA TO TABLE ROW
						tableRow.appendChild(tableData);							
					}


					// ADD 'Edit' BUTTON TO END OF ROW
					//var editButton = new dijit.form.Button( { id: editButtonId } );
					//editButton.attr('label', "Edit");
					//editButton.domNode.setAttribute("class", "editButton");
					
					
					// DO DOJO.CONNECT
					adminAccess.tableRowConnections.push(
						dojo.connect( tableRow, "onclick", function(e)
						{
							adminAccess.editRow(e, adminAccess.tableId, headings, 'updateAccess');
						})
					);

					// APPEND TABLE DATA TO TABLE ROW
					tableRow.appendChild(tableData);								
					
					// APPEND ROW TO TABLE
					table.appendChild(tableRow);
				}
			}; // groupTable

 			console.log("buildTable     BEFORE store.fetch-> groupTable");
			this.groupStore.fetch( { query: {	project : "*" }, onComplete: groupTable});
 			console.log("buildTable     AFTER store.fetch-> groupTable");
			
		},	// buildTable


		editRow : function (event, tableId, columns, callbackFunction)
		{
 			console.log("editRow     plugins.admin.Access.editRow(event, tableId, columns, callbackFunction)");
 			//console.log("editRow     tableId: " + tableId);
 			//console.log("editRow     columns: " + columns);
 			//console.log("editRow     callbackFunction: " + callbackFunction);
			
			var adminAccess = this;
			
			var rowId;
			if ( event && event.target
				&& event.target.parentNode && event.target.parentNode.id )
			{
				rowId = event.target.parentNode.id;
			}
 			console.log("editRow     rowId: " + rowId);
			
			// RETURN IF event.target.id NOT DEFINED
			// I.E., (CLICKED ON span AROUND BUTTON)
			if ( ! rowId )
			{
				return;
			}

			// GET TABLE NODE	
			var table = dojo.byId(tableId);
			
			// GET ROW INDEX FROM BUTTON ID
			var rowIndex = rowId.match(/(\d+)$/)[1];
			if ( ! rowIndex )
			{
				return;
			}

			// INCREMENT ROW INDEX (COLUMN HEADERS ARE FIRST ROW)
			rowIndex++;

			// DISCONNECT THE DOJO.CONNECT
			dojo.disconnect(adminAccess.tableRowConnections[rowIndex - 1]);

			// GET THE ROW NODE
			var row = table.childNodes[rowIndex];
			if ( ! row )
			{
				return;
			}
		
			// FOR EACH TABLE DATA, REPLACE THE innerHTML
			// WITH AN INPUT BOX CONTAINING THE TEXT		
			for ( var columnCounter = 1; columnCounter < row.childNodes.length; columnCounter++ )
			{
				var text = row.childNodes[columnCounter].innerHTML;

				// RETURN IF THIS IS A DOUBLE-CLICK
				if ( text.match(/^<input/) )	return;

				var input = new dijit.form.TextBox( { value: text } );
	
				if ( columnCounter == 0 )
				{
					input.attr('class', 'adminAccessInput');
				}
				else
				{
					input.attr('class', 'adminAccessTableNarrowColumn');
				}

				row.childNodes[columnCounter].innerHTML = '';
				row.childNodes[columnCounter].appendChild(input.domNode);
			}
	
			// ADD A 'Save' BUTTON AT THE END OF THE ROW
			var saveButtonId = 'adminAccessSaveButton' + rowIndex;
			if ( dijit.byId(saveButtonId) )
			{
				dijit.byId(saveButtonId).destroy();
			}
	
			// ADD SAVE BUTTON
			var saveButton = new dijit.form.Button({ id: saveButtonId });
			saveButton.attr('label', "Save");
			var adminAccess = this;
			dojo.connect( saveButton, "onClick", function(e)
			{
				adminAccess.saveRow(e, tableId, columns, callbackFunction);
			});
	
			var tableData = document.createElement("td");
			tableData.setAttribute('class', 'adminAccessTableData');
			tableData.appendChild(saveButton.domNode);

 			console.log("editRow     BEFORE row.appendChild(tableData)");
			row.appendChild(tableData);
 			console.log("editRow     AFTER row.appendChild(tableData)");

		}, // editRow
	
	
	
		
		// saveRow: SEND A JSON OBJECT OF THE CHANGED STORE DATA TO THE SERVER

		saveRow     : function (event, tableId, columns, callbackFunction)
		{
 			console.log("saveRow     plugins.admin.Access.saveRow(event, tableId, columns, callbackFunction)");
 			//console.log("saveRow     event.target: " + event.target);
 			//console.log("saveRow     event.target.id: " + event.target.id);

	
			var adminAccess = this;
 			//console.log("saveRow     adminAccess: " + adminAccess);
			var table = dojo.byId(this.tableId);
			
			// QUIT IF NO NUMERIC MATCH
			if ( ! event.target.id.match(/(\d+)$/) )
			{
				return;
			}
			
			// GET ROW
			var rowIndex = event.target.id.match(/(\d+)$/)[1];			
			var row = table.childNodes[rowIndex];
 			//console.log("saveRow     childNodes[0]: " + row.childNodes[0]);
 			//console.log("saveRow     childNodes[0].innerHTML: " + row.childNodes[0].innerHTML);
 			//console.log("saveRow     childNodes[0].value: " + row.childNodes[0].value);

			// REPLACE THE VALUES IN THE ITEM IN THE STORE WITH THE NEW VALUES
			var thisItem = {
				project: row.childNodes[0].innerHTML,
				ownerrights: row.childNodes[1].firstChild.value,
				grouprights: row.childNodes[2].firstChild.value,
				worldrights: row.childNodes[3].firstChild.value
			};

			// CHECK VALUES
			var keys =  [];
			for ( var i in thisItem )
			{
				keys.push(i);
			}
			
 			//console.log("saveRow     thisItem BEFORE checkPermissions: " + dojo.toJson(thisItem));
 			//console.log("saveRow     keys: " + dojo.toJson(keys));
			for ( var i = 1; i < keys.length; i++ )
			{
 				//console.log("saveRow     keys[" + i + "]: " + keys[i]);
 				//console.log("saveRow     thisItem[keys[" + i + "]]: " + thisItem[keys[i]]);
				thisItem[keys[i]] = adminAccess.checkPermissions(thisItem[keys[i]]);
			}
 			//console.log("saveRow     thisItem AFTER checkPermissions: " + dojo.toJson(thisItem));

			// GET INDEX OF ITEM IN STORE
			var itemIndex = this.getItemIndex(this.groupStore, thisItem, ["project"]);
 			//console.log("saveRow     itemIndex: " + itemIndex);

			// ADD ITEM TO STORE
			var store = this.groupStore;
 			//console.log("saveRow     store._arrayOfTopLevelItems.length: " + store._arrayOfTopLevelItems.length);

			// ADD SUBSTITUTE VALUES IN thisItem TO EXISTING ITEM IN STORE
			for ( var i = 1; i < keys.length; i++ )
			{
 				//console.log("saveRow     keys[" + i + "] " + keys[i] + ": " + thisItem[keys[i]]);
 				//console.log("saveRow     BEFORE setValue. store.getValue(store._arrayOfTopLevelItems[" + itemIndex + "]." + keys[i] + "): " + store.getValue(store._arrayOfTopLevelItems[itemIndex], keys[i]) );
				store.setValue(store._arrayOfTopLevelItems[itemIndex], keys[i], thisItem[keys[i]]);
 				//console.log("saveRow     AFTER setValue. store.getValue(store._arrayOfTopLevelItems[" + itemIndex + "]." + keys[i] + "): " + store.getValue(store._arrayOfTopLevelItems[itemIndex], keys[i]) );
 				//console.log("saveRow     AFTER setValue. store._arrayOfTopLevelItems[itemIndex].getValue(" + keys[i] + "): " + store._arrayOfTopLevelItems[itemIndex].getValue(keys[i]) );
			}

			// SAVE THE STORE TO THE SERVER
			adminAccess.saveStore();

			// FOR EACH TABLE DATA, RESTORE THE TEXT VALUES AND REMOVE THE INPUT BOX
			for ( var i = 1; i < row.childNodes.length - 1; i++ )
			{
				var text = row.childNodes[i].firstChild.value;
 				//console.log("saveRow     text " + i + ": " + text);

				// CHECK VALUE IS BETWEEN 1 AND 7 AND NUMERIC
				text = adminAccess.checkPermissions(text);
				
				row.childNodes[i].innerHTML	= text;
			}

			// REMOVE 'Save' BUTTON AT END OF ROW 
			row.removeChild(row.childNodes[row.childNodes.length - 1]);

			// ADD BACK DOJO.CONNECT
			adminAccess.tableRowConnections.push(
				dojo.connect( row, "onclick", function(e)
				{
					adminAccess.editRow(e, adminAccess.tableId, columns, 'updateAccess');
				})
			);

		}, // saveRow
	
	
		// MAKE SURE THAT PERMISSIONS ARE NUMERIC AND BETWEEN 1 AND 7
		checkPermissions : function (text)
		{
			if ( ! text.match(/^\d+$/) ) return 1;
			if ( text < 1 )	return 1;
			if ( text > 7 ) return 1;
			
			return text;
		},

		// CURRENTLY UNUSED CALLBACK FOR saveRow
		updateAccess : function (json)
		{
 			console.log("updateAccess     plugins.admin.Access.updateAccess(json)");
 			console.log("updateAccess     json: " + json);
		},


		getItemIndex : function (store, item, keys)
		{
 			 console.log("getItemIndex     plugins.admin.Access.getItemIndex(store, item, keys)");
 			//// console.log("???? ???? store: " + store);
 			//// console.log("???? ???? item: " + dojo.toJson(item));
 			//// console.log("???? ???? store._arrayOfAllItems: " + store._arrayOfAllItems);
 			//// console.log("???? ???? store._arrayOfAllItems[" + item.name + "]: " + store._arrayOfAllItems[item.name]);

			// OVERRIDE String TO ADD EQUALITY FUNCTIONS
			String.prototype.equalsIgnoreCase=myEqualsIgnoreCase;
			String.prototype.equals=myEquals;
			function myEquals(arg){
				return (this.toString()==arg.toString());
			}
			function myEqualsIgnoreCase(arg)
			{               
				return (new String(this.toLowerCase())==(new String(arg)).toLowerCase());
			}

			// MATCH ITEM NAME AGAINST NAMES OF ITEMS IN STORE
			if ( ! keys || keys == null )
			{
				for (var k in item) keys.push(k);
			}
 			// console.log("getItemIndex     keys: " + dojo.toJson(keys));			
			var hasMatch = 1;
			for ( var i = 0; i < store._arrayOfTopLevelItems.length; i++ )
			{
				for ( var j = 0; j < keys.length; j++ )
				{
					var itemValue = item[keys[j]].toString();
					var existingValue = store._arrayOfTopLevelItems[i][keys[j]].toString();
 					// console.log("getItemIndex     itemValue: " + itemValue);
 					// console.log("getItemIndex     existingValue: " + existingValue);
					
					if ( ! itemValue.equalsIgnoreCase(existingValue) )
					{
						hasMatch = 0;
					}
				}

 				 console.log("getItemIndex     Returning index: " + i);
				if ( hasMatch ) return i;
			}

 			 console.log("getItemIndex     Returning false");
			return false;
		},
		
		
		saveStore : function ()
		{
 			console.log("saveStore     plugins.admin.Access.saveStore()");

			var adminAccess = this;
 			console.log("saveStore     adminAccess: " + adminAccess);

			var store = this.groupStore;
 			console.log("saveStore     store: " + store);

 			console.log("saveStore()");
 			//console.log("saveDone    store._arrayOfTopLevelItems.length: " + store._arrayOfTopLevelItems.length);
			
			// print out for debugging
			for ( var i = 0; i < store._arrayOfTopLevelItems.length; i++ )
			{
 				//console.log("saveDone    item " + i + ": " + store.getLabel(store._arrayOfTopLevelItems[i]));
			}
			
			// SEND TO SERVER AS RAW XHR POST
			var dataArray = new Array;
			for ( var i = 0; i < store._arrayOfTopLevelItems.length; i++ )
			{
 				//console.log("saveDone    Processing item " + i + ": " + store.getLabel(store._arrayOfTopLevelItems[i]));
				
				var data = new Object;
				var item = store._arrayOfTopLevelItems[i];
				var attributes = store.getAttributes(item);
				if (attributes && attributes.length > 0)
				{
					for ( var j = 0; j < attributes.length; j++ )
					//for ( var j = 0; j < 1; j++ )
					{
 						//console.log("saveDone     attributes[" + j + "]: " + attributes[j]);
						var values = store.getValues(item, attributes[j]);
 						//console.log("saveDone     values: " + values);
 						//console.log("saveDone     values.length: " + values.length );

						if ( values )
						{
 							//console.log("saveDone     values is defined: " + values);
							
							// MULTI-VALUE ATTRIBUTE
							if (values.length > 1 )
							{
								data[attributes[i]] = [];
								for ( var k = 0; k < values.length; k++ )
								{
									var value = values[k];
 									//console.log("saveDone     value: " + value);
									data[attributes[j]].push(value);
								}
 								//console.log("saveDone     data: " + dojo.toJson(data));
							}
							// SINGLE VALUE ATTRIBUTE
							else
							{
 								//console.log("saveDone     single value: " + values);
								data[attributes[j]] = values[0];
 								//console.log("saveDone     data: " + dojo.toJson(data));
							}
						}
					}
					
 					//console.log("saveDone     Finished attributes loop");
				}
				dataArray.push(data);
			}
 			console.log("saveStore     dataArray: " + dojo.toJson(dataArray));

			var url = "http://localhost:8080/cgi-bin/agua/admin.cgi?";
 			console.log("saveStore     url: " + url);		
	
			// CREATE JSON QUERY
			var query = new Object;
			query.username = "admin";
			query.sessionId = "1228791394.7868.158";
			query.mode = "saveAccess";
			query.data = dojo.toJson(dataArray);
 			console.log("saveStore     query: " + dojo.toJson(query));
			
			// SEND TO SERVER
			dojo.xhrPut(
				{
					url: url,
					contentType: "text",
					putData: dojo.toJson(query),
					timeout: 3000,
					load: function(response, ioArgs) {
 						console.log("JSON Post worked.");
						return response;
					},
					error: function(response, ioArgs) {
 						console.log("Error with JSON Post, response: " + response + ", ioArgs: " + ioArgs);
						return response;
					}
				}
			);
			
		},

        loadingFunction : function (widget, name, id){
            
        }
	}
    
); // plugins.admin.Access


