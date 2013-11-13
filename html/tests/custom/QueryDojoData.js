dojo.require("dojox.data.QueryReadStore");
dojo.require("dojox.grid.Grid");
//dojo.require("dojox.grid._data.model");
dojo.require("dojox.grid.DataGrid");

dojo.provide("custom.QueryDojoData");
dojo.declare("custom.QueryDojoData", dojox.grid.data.DojoData,
{
	startItem: 0,
	itemsPerPage: 0,
	markupFactory: function(params, domNode, constructorFunction) // Used to create the object instance rather than the constructor
	{
			var instance = new custom.QueryDojoData(null, null, params);
			// Do any initialisation here
			this.serverQueryFilterParams = {};
			return instance;
	},
	
	requestRows: function (inRowIndex, inCount) // Fetch rows of the grid
	{  // Return from the server is in JSON format
			//this.cache = null;
		   console.warn("requestRows: fired");
			var row = this.startItem || 0;
			var date = new Date();
			var timestamp = date.getTime();
			
			var serverQueryParams = {
				"reqCode":"gridGetList", 
				startRow: row, 
				countRow: this.itemsPerPage, 
				sort:(this.sortColumn || ''),
				preventCache: timestamp
			};
			serverQueryParams = dojo.mixin(serverQueryParams, this.serverQueryFilterParams);
			
			var params =
			{
					start: 0, // Always 0 since start of model, display the first item at row 0
					count: inCount || this.rowsPerPage,
					serverQuery: dojo.mixin(serverQueryParams, this.query),
					query: this.query,
					//preventCache: true,
					onComplete: dojo.hitch(this, "processRows")
			}
			
			this.store.fetch(params);
	},
	
	getRowCount: function () // Returns the total number of records for the query   
	{ 
			console.warn("getRowCount: fired");
			var serverURL = this.store.url;
			var date = new Date();
			var timestamp = date.getTime();
			var rowCount;
			var serverQueryParams = {
				"reqCode": "gridGetRowCount", 
				startRow: this.startItem, 
				start: this.startItem, 
				countRow: (this.itemsPerPage || ''), 
				sort:(this.sortColumn || ''),
				preventCache: timestamp
			};
			serverQueryParams = dojo.mixin(serverQueryParams, this.serverQueryFilterParams);
			dojo.xhrGet(
			{
					url: serverURL  ,
					content: dojo.mixin(serverQueryParams, this.query ),
					handleAs: "json",
					sync: true,
					load: dojo.hitch(this,function(response, ioArgs) // The LOAD function will be called on a successful response.
					{
						var data = new dojo.data.ItemFileReadStore({data: response});
						data.fetchItemByIdentity({
							identity: "response", 
							sync: true,
							onItem: dojo.hitch(this,function(item){
								var message = data.getValue(item,"text");
								if(message == ""){
									console.warn("no response from the server");
								}else{
									rowCount = parseInt(message);
									console.info("recieved : " + rowCount);
								}
							})
						});
					}),
					error: function(response, ioArgs)  // The ERROR function will be called in an error case.
					{
						console.error("HTTP status code: ", ioArgs.xhr.status);
						return response;
					}
			}
			);
			this.requestRows(null,null);
			 // The return value is a simple number
			return rowCount;
	},

     refresh:function(){
		console.warn("refresh: fired");
		toggleLoad();
     	this.inherited(arguments);
		this.cache = null;
		toggleLoad();
		console.warn("refresh: end");
     },


	sort: function(colIndex) // Called when user clicks on grid header to change sort order
	{
		console.warn("sort: fired");
		toggleLoad();
		this.clearData(true); // Clear the grids data
		this.sortColumn = colIndex; // set the sort order
		this.requestRows(); // fetch the new data
		toggleLoad();
	},

	canSort: function () // Determines if clicking on the grid header will resort the data
	{
		return true;
	}
} );