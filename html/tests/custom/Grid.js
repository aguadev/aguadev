dojo.require("dojox.data.QueryReadStore");
dojo.require("dojox.grid.Grid");
//dojo.require("dojox.grid._data.model");
dojo.require("dojox.grid.DataGrid");
dojo.require("dijit._Widget"); 
dojo.require("dijit._Templated"); 

dojo.provide("custom.Grid");
dojo.declare("custom.Grid", [dijit._Widget,dijit._Templated],
{
	label: "Browse ...",
	name: "customGrid",
	templatePath: dojo.moduleUrl("custom","templates/Grid.html"),
	nonRequired: "",
	widgetsInTemplate: true,
	
	editorTemplatePath: null,
	
	containerNode: null,
	
	webAppPath: null,
	baseAction: null,
	
	// used to id the elements of this dialog
	// templates must name specific elements 
	dialogPrefix: null,
	dialog: null,
	menu: null,

	width: null,
	height: null,
	
	// use View if there is a premade
	// use others if not
	view: null,
	viewFields: null,
	viewNames: null,
	viewWidths: null,
	
	dataStore: null,
	model: null,
	
	// these are order specific
	keyNames: null, 
	dataNames: null,
	filterNames: null,
	
	gridTitle: null,
	grid: null,
	rowBar: null,
	layout: null,
	itemsPerPageSelect: null,
	pageSelect: null,
	
	itemsLabel: null,
	pagesLabel: null,
	filtersLabel: null,
	
	// variables that can be modified
	// create items options with 20,40,60,80,100 by default
	itemsPerPageSelect_beginIndex: 20,
	itemsPerPageSelect_increment: 20,
	itemsPerPageSelect_endIndex: 120, 
	
	// funcions that are passed in relating to events that are handled by certain widgets that should be
	// executed within 'this' scope
	// ex: updating specific widgets on a change ( filtering select )
	// {func: funcPtr, method: "methodName (onClick)", source: "id of trigger", type: "find node by dijit or dojo"}
	//{func: popupMessage1, method: "onClick", source: "glacct_btnClickMe", type: "dijit"},
	passedInFunctions: null,
	
	// add, change delete functions on dialog
	// functions to be executed to allow for any data modification
	// {func: funcPtr, method: "add, change, delete -- preChange"}
	eventFunctions: null,
	
	// if toggleLoad has been called
	loading: false,
	
	// if the additional options should be shown
	showOptions: false,
	
	// the main background color of the header and footer
	bgColor: "#EEEEEE",
	// the background color of the more options
	bgOptionColor: "#C2C0C0",
	// boarder color of the header and footer
	borderColor: "#979797",

	// manage the visibilities of buttons and menu items
	// Note* menu items cannot be shown after they are hidden because they are crea ted programmatically
	btnViewVis: true,
	btnAddVis: true,
	btnEditVis: true,
	btnFilterVis: true,
	btnDeleteVis: true,
	
	mnuViewVis: true,
	mnuAddVis: true,
	mnuEditVis: true,
	mnuFilterVis: true,
	mnuDeleteVis: true,
	
	// the text that should appear on the buttons and menu
	btnViewTxt: "View",
	btnAddTxt: "Add",
	btnEditTxt: "Edit Row(s)",
	btnFilterTxt: "Search",
	btnDeleteTxt: "Delete Row(s)",
	
	mnuViewTxt: "View",
	mnuAddTxt: "Add",
	mnuEditTxt: "Edit Row(s)",
	mnuFilterTxt: "Search",
	mnuDeleteTxt: "Delete Row(s)",
	
	// if this isn't null, add it to the onCellClick of the grid
	onCellClickFunc: null,
	
	// left click editing
	
	toggleLoad: function(){
			if(this.loading)
				dojo.style(this.id + "_loadingNode","display","none");
			else
				dojo.style(this.id + "_loadingNode","display","block");
			this.loading = !this.loading;
		},
		
	toggleMoreOptions: function(){
			if(!this.showOptions){
				dojo.style(this.id + "_btnOptions","background-color","#B0B0B0");
				// disable to button during the animation and enable it again after it is finished
				dijit.byId(this.id + "_btnOptions").setAttribute('disabled',true);
				dojo.fx.wipeIn({node: dojo.byId(this.id + "_optionsButtons"), duration: 300, onEnd: 
					dojo.hitch(this, function(){
						dijit.byId(this.id + "_btnOptions").setAttribute('disabled',false);
					})
					}).play();
				// also change the text that is displayed in the button
				dijit.byId( this.id + "_btnOptions").setLabel("Hide Options");
			}else{
				dijit.byId(this.id + "_btnOptions").setAttribute('disabled',true);
				dojo.fx.wipeOut({node: dojo.byId(this.id + "_optionsButtons"), duration: 300, onEnd: 
					dojo.hitch(this, function(){
						dijit.byId(this.id + "_btnOptions").setAttribute('disabled',false);
					})
					}).play();
				dijit.byId( this.id + "_btnOptions").setLabel("Show Options");
			}
			this.showOptions = !this.showOptions;
		},
		
	toggleOptionButtonShow: function(btnFuncName){
			dojo.style( dojo.byId(this.id + "_btnOption" + btnFuncName + "Div") ,"display", "block" );
		},
	
	toggleOptionButtonHide: function(btnFuncName){
			dojo.style( dojo.byId(this.id + "_btnOption" + btnFuncName + "Div") ,"display", "none" );
		},
	
	// constructor, buildRendering, startup - order of execution upon creation
	constructor: function(params){
			dojo.mixin(this,params);
		},
		
	resize: function(){
		if(this.width == null)
			this.width = 600;
		if(this.height == null)
			this.height = 400;
		this.grid.resize({w: this.width, h: this.height, l: 0, t: 0});
	},
	
	updateStructure: function(){
		this.layout = [ this.rowBar, this.view ];
		this.grid.setStructure(this.layout);
	},
		
	startup: function(){
	
			this.inherited("startup",arguments);
			// Add this widget into the document
			if(this.containerNode == null)
				this.containerNode = dojo.body();
			this.containerNode.appendChild(this.domNode);
			
			// update the loading image from the template with the app path
			dojo.attr(dojo.byId(this.id + "_loadingImage"), "src", this.webAppPath + dojo.attr(dojo.byId(this.id + "_loadingImage"), "src"));
			
			// create the more options menu
			var btnNode = document.createElement('button');
			dojo.attr(btnNode,"id", this.id + "_btnOptions" );
			var dojoBtn = new dijit.form.Button({label: "Show Options"},btnNode); 
			dojo.byId( this.id + "_options" ).appendChild(dojoBtn.domNode);
			
			// define the hiding and showing of the more options div
			dojo.connect(dijit.byId(this.id + "_btnOptions"),"onClick",
				dojo.hitch(this,this.toggleMoreOptions)
			);
			
			// Create the items per page select
			var itemsPerPageNode = document.createElement("select");
			
			dojo.attr(itemsPerPageNode, "dojoType", "dijit.form.FilteringSelect");
			var optionNode;
			for(this.itemsPerPageSelect_beginIndex; 
					this.itemsPerPageSelect_beginIndex != this.itemsPerPageSelect_endIndex; 
					 this.itemsPerPageSelect_beginIndex +=  this.itemsPerPageSelect_increment){
				optionNode = document.createElement("option");
				dojo.attr(optionNode, "value",  this.itemsPerPageSelect_beginIndex);
				optionNode.innerHTML =  this.itemsPerPageSelect_beginIndex;
				itemsPerPageNode.appendChild(optionNode);
			}
			
			dojo.byId(this.id + "_itemsFilter").appendChild(itemsPerPageNode);
			this.itemsPerPageSelect = new dijit.form.FilteringSelect({"id":this.id+"_itemSelect", "style":"width: 75px;"},itemsPerPageNode);
			this.itemsPerPageSelect.startup();
			// update the model when items per page is changed
			dojo.connect(this.itemsPerPageSelect,"onChange",
				dojo.hitch(this,function(){
					if(this.itemsPerPageSelect.isValid()){
						this.toggleLoad();
						this.model.itemsPerPage = parseInt(this.itemsPerPageSelect.getValue());
						this.updatePages(this.model.serverQueryFilterParams);
						this.model.startItem = (parseInt(this.itemsPerPageSelect.getValue()) * parseInt(this.pageSelect.getValue())) - parseInt(this.itemsPerPageSelect.getValue());
						this.model.refresh();
						this.toggleLoad();
					}
				})
			);
			
			this.updatePages(null);
			
			// Finish creating the upper section of the grid
			var tempLabelNode = document.createElement("label");
			if(this.itemsLabel == null)
				this.itemsLabel = "Items per page: ";
			tempLabelNode.innerHTML = this.itemsLabel;
			dojo.byId(this.id + "_itemsLabel").appendChild(tempLabelNode);
	
			tempLabelNode = document.createElement("label");
			if(this.gridTitle == null)
				this.gridTitle = "List of Items";
			tempLabelNode.innerHTML = this.gridTitle;
			dojo.byId(this.id + "_title").appendChild(tempLabelNode);
	
			tempLabelNode = document.createElement("label");
			if(this.pagesLabel == null)
				this.pagesLabel = "Page: ";
			tempLabelNode.innerHTML = this.pagesLabel;
			dojo.byId(this.id + "_pagesLabel").appendChild(tempLabelNode);
			
			tempLabelNode = document.createElement("label");
			if(this.filtersLabel == null)
				this.filtersLabel = "Filters: ";
			tempLabelNode.innerHTML = this.filtersLabel;
			dojo.byId(this.id + "_filtersLabel").appendChild(tempLabelNode);
	
			tempLabelNode = document.createElement("label");
			tempLabelNode.innerHTML = "None";
			dojo.attr(tempLabelNode,"id",this.dialogPrefix + "_filtersText");
			dojo.byId(this.id + "_filters").appendChild(tempLabelNode);
			
			if(this.dataStore == null)
				this.dataStore = new dojox.data.QueryReadStore({
						url: this.webAppPath + this.baseAction
				});
			
			if(this.model == null)
				this.model = new custom.QueryDojoData(null, null, {
					store: this.dataStore,
					rowsPerPage: 100, // not going to be used since using pages
					query: {},
					startItem: 0,
					itemsPerPage: parseInt(this.itemsPerPageSelect.getValue())
				});
			
			if(this.view == null){
				// if the view is not created and passed in, create the view
				// from specified array fields
				var innerArray = [];
				var index = 0;
				for(index; index < this.viewFields.length; index++){
					var tempAArray = {};
				    tempAArray.field = this.viewFields[index];
				    tempAArray.name = this.viewNames[index];
				    tempAArray.width = this.viewWidths[index];
				    	
				   	innerArray[index] = tempAArray;
				}
				
				this.view = {
					cells: [
						innerArray
					]
				};
			}
			
			if(this.rowBar == null)
				this.rowBar = {
					 type: 'dojox.GridRowView', width: '20px'
				};
				
			// a grid layout is an array of views.
			if(this.layout == null)
				this.layout = [ this.rowBar, this.view ];
			
			if(this.grid == null)
				this.grid = new dojox.Grid({
					"id": this.id + "_grid",
					"model": this.model,
					"structure": this.layout
				});
			
			// update the loading image path
			dojo.attr(dojo.byId(this.id + "_loadingImage"), "src", this.webAppPath + "config/ajax-loader.gif");
			
			if(this.width == null)
				this.width = 600;
			if(this.height == null)
				this.height = 400;
			this.grid.resize({w: this.width, h: this.height, l: 0, t: 0});
			
			this.grid.startup();
			this.grid.render();
			dojo.byId(this.id + "_gridContainer").appendChild(this.grid.domNode);
			
			// prevent the grid from messing with our menu
			this.grid.onCellContextMenu = function(e) {
				cellNode = e.cellNode;
			};
			this.grid.onHeaderContextMenu = function(e) {
				cellNode = e.cellNode;
			};
			
			// update the model start 
			dojo.connect(this.grid,"onHeaderCellMouseDown",dojo.hitch(this,
				function(){
					// Update the model which row should be shown when the mouse is clicked to sort
					this.model.startItem = (parseInt(this.itemsPerPageSelect.getValue()) * parseInt(this.pageSelect.getValue())) - parseInt(this.itemsPerPageSelect.getValue());
				})
			);
			
			if(this.onCellClickFunc != null)
			dojo.connect(this.grid,"onCellClick",dojo.hitch(this,
				this.onCellClickFunc)
			);
			
			// create the menu
			this.menu = new dijit.Menu();
			if(this.mnuViewVis)
			this.menu.addChild( //view
				new dijit.MenuItem(
					{label: this.mnuViewTxt, 
					disabled:false,
					iconClass:"viewImage",
					onClick:dojo.hitch(this, this.menuView)
					}
				));
			if(this.mnuAddVis || this.mnuEditVis)
				this.menu.addChild(new dijit.MenuSeparator());
			if(this.mnuAddVis)
			this.menu.addChild( //preAdd
				new dijit.MenuItem(
					{label: this.mnuAddTxt, 
					disabled:false,
					iconClass:"addImage",
					onClick:dojo.hitch(this, this.menuAdd)
					}
				));
			if(this.mnuEditVis)
			this.menu.addChild( //preChange
				new dijit.MenuItem(
					{label: this.mnuEditTxt, 
					disabled:false,
					iconClass:"editImage",
					onClick:dojo.hitch(this, this.menuEdit)
					}
				));
			//this.menu.addChild(new dijit.MenuSeparator());
			if(this.mnuFilterVis && (this.mnuAddVis || this.mnuEditVis || this.mnuViewVis)){
			this.menu.addChild(new dijit.MenuSeparator());
			}
			if(this.mnuFilterVis){
			this.menu.addChild(
				new dijit.MenuItem(
					{label: this.mnuFilterTxt, 
					disabled:false,
					iconClass:"searchImage",
					onClick:dojo.hitch(this, this.menuFilter)
					}
				));
			}
			if(this.mnuDeleteVis && (this.mnuFilterVis || this.mnuEditVis || this.mnuViewVis || this.mnuAddVis)){
			this.menu.addChild(new dijit.MenuSeparator());
			//this.menu.addChild(new dijit.MenuItem({label:"Cancel", disabled:false,iconClass:"exitImage"}));
			}
			if(this.mnuDeleteVis)
			this.menu.addChild(
				new dijit.MenuItem(
					{label: this.mnuDeleteTxt, 
					disabled:false,
					iconClass:"deleteImage",
					onClick:dojo.hitch(this, this.menuDelete)
					}
				));
			
			
			this.menu.bindDomNode(this.grid.domNode);
			this.menu.startup();
			
			var divTableCon = document.createElement('div');
			var tableCon = document.createElement('table');
			dojo.attr(tableCon,"cellpadding", "0px" );
			dojo.attr(tableCon,"cellspacing", "0px" );
			dojo.attr(tableCon,"border", "0px" );
			dojo.attr(tableCon,"width", "0px" );
			var tbodyCon = document.createElement('tbody');
			var trCon = document.createElement('tr');
			var tdCon;
			
			// create the more options menu
			var imagePath = this.webAppPath + "images/application/";
			var divCon;
			tdCon = document.createElement('td');
			divCon = document.createElement('div');
			dojo.attr(divCon,"id", this.id + "_btnOptionViewDiv" );
			btnNode = document.createElement('button');
			dojo.attr(btnNode,"id", this.id + "_btnOptionView" );
			var dojoBtn = new dijit.form.Button({label: "<img src='" + imagePath + "View.png'/> " + this.btnViewTxt},btnNode);
			divCon.appendChild(dojoBtn.domNode);
			tdCon.appendChild(divCon);
			//dojo.byId( this.id + "_optionsButtonsContent" ).appendChild(divCon);
			dojo.connect(dijit.byId(this.id + "_btnOptionView"),"onClick",
				dojo.hitch(this, this.menuView)
			);
			if(this.btnViewVis)
				dojo.style(divCon,"display", "block" );
			else
				dojo.style(divCon,"display", "none" );
			trCon.appendChild(tdCon);
			
			tdCon = document.createElement('td');
			divCon = document.createElement('div');
			dojo.attr(divCon,"id", this.id + "_btnOptionAddDiv" );
			btnNode = document.createElement('button');
			dojo.attr(btnNode,"id", this.id + "_btnOptionAdd" );
			var dojoBtn = new dijit.form.Button({label: "<img src='" + imagePath + "Add.png'/> " + this.btnAddTxt},btnNode);
			divCon.appendChild(dojoBtn.domNode);
			tdCon.appendChild(divCon);
			//dojo.byId( this.id + "_optionsButtonsContent" ).appendChild(divCon);
			dojo.connect(dijit.byId(this.id + "_btnOptionAdd"),"onClick",
				dojo.hitch(this, this.menuAdd)
			);
			if(this.btnAddVis)
				dojo.style(divCon,"display", "block" );
			else
				dojo.style(divCon,"display", "none" );
			trCon.appendChild(tdCon);
			
			tdCon = document.createElement('td');
			divCon = document.createElement('div');
			dojo.attr(divCon,"id", this.id + "_btnOptionEditDiv" );
			btnNode = document.createElement('button');
			dojo.attr(btnNode,"id", this.id + "_btnOptionEdit" );
			var dojoBtn = new dijit.form.Button({label: "<img src='" + imagePath + "Edit.png'/> " + this.btnEditTxt},btnNode);
			divCon.appendChild(dojoBtn.domNode);
			tdCon.appendChild(divCon);
			//dojo.byId( this.id + "_optionsButtonsContent" ).appendChild(divCon);
			dojo.connect(dijit.byId(this.id + "_btnOptionEdit"),"onClick",
				dojo.hitch(this, this.menuEdit)
			);
			if(this.btnEditVis)
				dojo.style(divCon,"display", "block" );
			else
				dojo.style(divCon,"display", "none" );
			trCon.appendChild(tdCon);
			
			tdCon = document.createElement('td');
			divCon = document.createElement('div');
			dojo.attr(divCon,"id", this.id + "_btnOptionFilterDiv" );
			btnNode = document.createElement('button');
			dojo.attr(btnNode,"id", this.id + "_btnOptionFilter" );
			var dojoBtn = new dijit.form.Button({label: "<img src='" + imagePath + "Search.png'/> " + this.btnFilterTxt},btnNode);
			divCon.appendChild(dojoBtn.domNode);
			tdCon.appendChild(divCon);
			//dojo.byId( this.id + "_optionsButtonsContent" ).appendChild(divCon);
			dojo.connect(dijit.byId(this.id + "_btnOptionFilter"),"onClick",
				dojo.hitch(this, this.menuFilter)
			);
			if(this.btnFilterVis)
				dojo.style(divCon,"display", "block" );
			else
				dojo.style(divCon,"display", "none" );
			trCon.appendChild(tdCon);
			
			tdCon = document.createElement('td');
			divCon = document.createElement('div');
			dojo.attr(divCon,"id", this.id + "_btnOptionDeleteDiv" );
			btnNode = document.createElement('button');
			dojo.attr(btnNode,"id", this.id + "_btnOptionDelete" );
			var dojoBtn = new dijit.form.Button({label: "<img src='" + imagePath + "Delete.png'/> " + this.btnDeleteTxt},btnNode);
			divCon.appendChild(dojoBtn.domNode);
			tdCon.appendChild(divCon);
			//dojo.byId( this.id + "_optionsButtonsContent" ).appendChild(divCon);
			dojo.connect(dijit.byId(this.id + "_btnOptionDelete"),"onClick",
				dojo.hitch(this, this.menuDelete)
			);
			if(this.btnDeleteVis)
				dojo.style(divCon,"display", "block" );
			else
				dojo.style(divCon,"display", "none" );
			trCon.appendChild(tdCon);
			
			tbodyCon.appendChild(trCon);
			tableCon.appendChild(tbodyCon);
			divTableCon.appendChild(tableCon);
			dojo.byId( this.id + "_optionsButtonsContent" ).appendChild(divTableCon);

			// create the dialog editor for the grid
			var date = new Date();
			var timestamp = date.getTime();
			dojo.xhrGet({
				url: this.editorTemplatePath,
				handleAs: "text",
				sync: true,
				"preventCache": timestamp,
				load: dojo.hitch(this,function(response, ioArgs){
						
						this.dialog = new dijit.Dialog({id:this.id + "_dialog", title:"Editor"});
						this.dialog.setContent(response);
						dojo.body().appendChild(this.dialog.domNode);
						this.dialog.startup();
						
						// create the dialog cancel button
						btnNode = document.createElement('button');
						dojo.attr(btnNode,"id", this.id + "_btnDialogCancel" );
						dojoBtn = new dijit.form.Button({label: "Close"},btnNode); 
						dojo.byId( this.dialogPrefix + "_dialogCancel" ).appendChild(dojoBtn.domNode);
						dojo.connect(dijit.byId(this.id + "_btnDialogCancel"),"onClick",
							dojo.hitch(this,function(){
								this.dialog.hide();
							})
						);
						
						// set the icons by their id's
						var imagePath = this.webAppPath + "images/application/";
						dojo.attr(dojo.byId(this.dialogPrefix + "_addImage"), "src",  imagePath + "Add.png");
						dojo.attr(dojo.byId(this.dialogPrefix + "_deleteImage"), "src", imagePath + "Delete.png");
						dojo.attr(dojo.byId(this.dialogPrefix + "_exitImage"), "src", imagePath + "Exit.png");
						dojo.attr(dojo.byId(this.dialogPrefix + "_updateImage"), "src", imagePath + "Update.png");
						dojo.attr(dojo.byId(this.dialogPrefix + "_searchImage"), "src", imagePath + "Search.png");
						
						// dialog button events
						// add
						dojo.connect(dijit.byId(this.dialogPrefix + "_btnAdd"), "onClick",
							dojo.hitch(this,function(){
								dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = "";
								this.toggleLoad();
								
								// {func: funcPtr, method: "add, change, delete"}
								dojo.forEach(this.eventFunctions,
									dojo.hitch(this,function(oneItem, index){
										if(oneItem != null && oneItem.method != null && oneItem.method == "add"){
											dojo.hitch(this,oneItem.func)();
										}
									})
								);
								
								var timestamp = date.getTime();
								dojo.xhrPost({
									url: this.webAppPath + this.baseAction,
									content: dojo.mixin({"reqCode":"gridAdd",preventCache: timestamp}),
									form: this.dialogPrefix + "_editorDialogForm",
									handleAs: "json",
									sync: true,
									handle: dojo.hitch(this,function(response, ioArgs){
											this.toggleLoad();
											var data = new dojo.data.ItemFileReadStore({data: response});
											data.fetchItemByIdentity({
												identity: "response", 
												onItem: dojo.hitch(this,function(item){
														var message = data.getValue(item,"text");
														if(message == ""){
															this.dialog.hide();
															this.updatePages(this.model.serverQueryFilterParams);
															this.model.refresh();
															this.grid.refresh();
														}else{
															dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = message;
														}
													 })
											});
										})
								});
							})
						);
						
						// cancel
						dojo.connect(dijit.byId(this.dialogPrefix + "_btnCancel"), "onClick",
							dojo.hitch(this,function(){
								this.dialog.hide();
							})
						);
						
						// change
						dojo.connect(dijit.byId(this.dialogPrefix + "_btnUpdate"), "onClick",
							dojo.hitch(this,function(){
								// clear the error html since not allowing the dialog to close depends on error being shown
								dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = "";
								var batchSize = this.grid.selection.getSelected().length;
								
								if(batchSize == 1){
									this.toggleLoad();
									
									// {func: funcPtr, method: "add, change, delete"}
									dojo.forEach(this.eventFunctions,
										dojo.hitch(this,function(oneItem, index){
											if(oneItem != null && oneItem.method != null && oneItem.method == "change"){
												dojo.hitch(this,oneItem.func)();
											}
										})
									);
									var timestamp = date.getTime();
									dojo.xhrPost({
										url: this.webAppPath + this.baseAction,// + "?reqCode=gridChange",
										content: {"reqCode":"gridChange",preventCache: timestamp},
										form: this.dialogPrefix + "_editorDialogForm",
										handleAs: "json",
										sync: true,
										handle: dojo.hitch(this,function(response, ioArgs){
												this.toggleLoad();
												var data = new dojo.data.ItemFileReadStore({data: response});
												data.fetchItemByIdentity({
													identity: "response", 
													onItem: dojo.hitch(this,function(item){
															var message = data.getValue(item,"text");
															if(message == ""){
																this.dialog.hide();
																this.model.refresh();
																this.grid.refresh();
															}else{
																dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = message;
															}
														 })
												});
											})
									});
									
								}else if(batchSize > 1){
									var rows = this.grid.selection.getSelected();
									dojo.forEach(rows,
										dojo.hitch(this, function(oneRow, index){
											var currentItem = this.grid.model.data[oneRow];
											if(currentItem){
												this.toggleLoad();
												
												// {func: funcPtr, method: "add, change, delete"}
												dojo.forEach(this.eventFunctions,
													dojo.hitch(this,function(oneItem, index){
														if(oneItem != null && oneItem.method != null && oneItem.method == "change"){
															dojo.hitch(this,oneItem.func)();
														}
													})
												);
												
												var currentDojoItem = currentItem.__dojo_data_item;
												// a and b are different in case they are changed
												
												//build the content
												var changeParams = {}; // associative array to hold they keys to be submitted
												var paramKey = 1;
												dojo.forEach(this.keyNames,
													dojo.hitch(this, function(value, index){
														changeParams["" + paramKey] = this.dataStore.getValue(currentDojoItem, value);
														paramKey++;
												}));
												
												dojo.forEach(this.dataNames,
													dojo.hitch(this, function(value, index){
														changeParams["" + paramKey] = dijit.byId(this.dialogPrefix + "_" + value).getValue() || this.dataStore.getValue(currentDojoItem, value);
														paramKey++;
												}));
												
												var timestamp = date.getTime();
												dojo.xhrPost({
													url: this.webAppPath + this.baseAction,// + "?reqCode=gridBatchChange",
													content: dojo.mixin({"reqCode":"gridBatchChange",preventCache: timestamp}, changeParams),
													handleAs: "json",
													sync: true,
													
													handle: dojo.hitch(this,function(response, ioArgs){
															this.toggleLoad();
															var data = new dojo.data.ItemFileReadStore({data: response});
															data.fetchItemByIdentity({
																identity: "response", 
																onItem: dojo.hitch(this,function(item){
																		var message = data.getValue(item,"text");
																		if(message == ""){
																			this.model.refresh();
																			this.grid.refresh();
																		}else{
																			dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = message;
																		}
																	 })
															});
														})
												});
												
											}
										})
									);
									if(dojo.byId(this.dialogPrefix + "_errorTag").innerHTML == "")
										this.dialog.hide();
								}
							})
						);

						// delete
						dojo.connect(dijit.byId(this.dialogPrefix + "_btnDelete"), "onClick",
							dojo.hitch(this,function(){

if (confirm("Do you really want to delete this record?")) {

								dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = "";
								this.toggleLoad();
								
								// {func: funcPtr, method: "add, change, delete"}
								dojo.forEach(this.eventFunctions,
									dojo.hitch(this,function(oneItem, index){
										if(oneItem != null && oneItem.method != null && oneItem.method == "delete"){
											dojo.hitch(this,oneItem.func)();
										}
									})
								);
								
								var changeParams = {}; // associative array to hold they keys to be submitted
								var paramKey = 1;
								dojo.forEach(this.keyNames,
									dojo.hitch(this, function(value, index){
										changeParams["" + paramKey] = dijit.byId(this.dialogPrefix + "_old" + value).getValue();
										paramKey++;
								}));
								
								var timestamp = date.getTime();
								dojo.xhrPost({
									url: this.webAppPath + this.baseAction,
									content: dojo.mixin({"reqCode":"gridDelete",preventCache: timestamp},changeParams),
									handleAs: "json",
									sync: true,
									handle: dojo.hitch(this,function(response, ioArgs){
											this.toggleLoad();
											var data = new dojo.data.ItemFileReadStore({data: response});
											data.fetchItemByIdentity({
												identity: "response", 
												onItem: dojo.hitch(this,function(item){
														var message = data.getValue(item,"text");
														if(message == ""){
												this.dialog.hide();
												this.model.refresh();
												this.grid.refresh();
														}else{
															dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = message;
														}
													 })
											});
										})
								});
} else {
	return;
}
								
							})
						);
					
						// update filter
						dojo.connect(dijit.byId(this.dialogPrefix + "_btnFilter"), "onClick",
							dojo.hitch(this, function(){
							
								// build the filter to be sent to the server
								// also build the text to be displayed to the user
								var filtersText = "";
								var filterParams = {}; // associative array to hold they keys to be submitted
								var paramKey = 1;
								dojo.forEach(this.filterNames,
									dojo.hitch(this, function(value, index){
										// place the filter parameters into an array to be posted
										//console.error("dialogPrefix: " + dijit.byId(this.dialogPrefix + "_filter_" + value).getValue());
										filterParams["filter_" + paramKey] = dijit.byId(this.dialogPrefix + "_filter_" + value).getValue();
										// update the label with the filters that were chosen
										if(dijit.byId(this.dialogPrefix + "_filter_" + value).getValue() != ""){
											if(index != 0 && filtersText != "")
												filtersText = filtersText + " , ";
											filtersText = filtersText + this.viewNames[index] + " = " + dijit.byId(this.dialogPrefix + "_filter_" + value).getValue();
										}
										
										paramKey++;
								}));

								if(filtersText == "")
									filtersText = "None";
								dojo.byId(this.dialogPrefix + "_filtersText").innerHTML = filtersText;
								
								this.model.serverQueryFilterParams = filterParams;
								this.updatePages(this.model.serverQueryFilterParams);
								this.model.refresh();
								this.grid.refresh();
								this.dialog.hide();
							})
						);
					
					})
			});
			
			// create other functions that must be executed within this scope
			// source - the object that fires the event
			// method - the name of the event that is fired
			// func - the function that is to be executed once the event is fired
			// for example, a filtering select in the dialog editor,
			// possibly additional dialog widgets
			dojo.forEach(this.passedInFunctions,
				dojo.hitch(this,function(oneItem, index){
					var source = null;
					if(oneItem.type == "dijit"){
						source = dijit.byId(oneItem.source)
					}else if(oneItem.type == "dojo"){
						source = dojo.byId(oneItem.source)
					}
					if(source != null){
						dojo.connect(source, oneItem.method,
								dojo.hitch(this,oneItem.func)
						);
					}else{
						// if the source is null, then just execute this function
						dojo.hitch(this,oneItem.func)();
					}
				})
			);
			this.model.refresh();
			this.grid.refresh();
		},
	
	// returns denied, admin, user
	authenticateUser: function(){
			var date = new Date();
			var authenticateAction = "login.do"
			var timestamp = date.getTime();
			var retValue;
			dojo.xhrPost({
				url: this.webAppPath + authenticateAction,
				content: dojo.mixin({"reqCode":"authenticateUser",preventCache: timestamp},{}),
				handleAs: "json",
				sync: true,
				handle: dojo.hitch(this,function(response, ioArgs){
						this.toggleLoad();
						var data = new dojo.data.ItemFileReadStore({data: response});
						data.fetchItemByIdentity({
							identity: "response", 
							onItem: dojo.hitch(this,function(item){
									var message = data.getValue(item,"text");
									if(message == ""){
										retValue = "";
									}else{
										retValue = message;
									}
								 })
						});
					})
			});
			return retValue;
		},
		
	hasPermission: function(action){
			var row = this.grid.selection.getSelected()[0];
			var selectedItem = this.grid.model.data[row];
			var keys = {}; // associative array to hold they keys to be submitted
			if(selectedItem){
				var dojoItem = selectedItem.__dojo_data_item;
				var paramKey = 1;
				dojo.forEach(this.keyNames,
					dojo.hitch(this, function(value, index){
						keys["" + paramKey] = this.dataStore.getValue(dojoItem,value)
						paramKey++;
				}));
			}
	
			var date = new Date();
			var timestamp = date.getTime();
			var retValue;
			dojo.xhrPost({
				url: this.webAppPath + this.baseAction,
				content: dojo.mixin({"reqCode":"hasPermission",preventCache: timestamp,"action":action},keys),
				handleAs: "json",
				sync: true,
				handle: dojo.hitch(this,function(response, ioArgs){
						var data = new dojo.data.ItemFileReadStore({data: response});
						data.fetchItemByIdentity({
							identity: "response", 
							onItem: dojo.hitch(this,function(item){
									var message = data.getValue(item,"text");
									if(message == ""){
										retValue = "";
									}else{
										retValue = message;
									}
								 })
						});
					})
			});
			return retValue;
		},
	
	// shows the corresponding divs in the dialog
	dialogShowFilter: function(){
			this.dialogHideAll();
			dojo.style(this.dialogPrefix + "_filter","display","block");
		},
	
	dialogShowEditor: function(action){
			this.dialogHideAll();
			dojo.style(this.dialogPrefix + "_editor","display","block");
			if(action == "preAdd"){
				dojo.style(this.dialogPrefix + "_preAddDiv","display","block");
			}else if(action == "preChange"){
				dojo.style(this.dialogPrefix + "_preChangeDiv","display","block");
			}
		},
	
	dialogShowMessage: function(message){
			this.dialogHideAll();
			dojo.byId(this.dialogPrefix + "_dialogMessage").innerHTML = message;
			dojo.style(this.dialogPrefix + "_message","display","block");
			dojo.style(this.dialogPrefix + "_dialogCancel","display","block");
		},
	
	dialogShowView: function(){
			this.dialogHideAll();
			dojo.style(this.dialogPrefix + "_view","display","block");
			dojo.style(this.dialogPrefix + "_dialogCancel","display","block");
		},
	
	dialogHideAll: function(){
			dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = "";
		
			dojo.style(this.dialogPrefix + "_editor","display","none");
			dojo.style(this.dialogPrefix + "_filter","display","none");
			dojo.style(this.dialogPrefix + "_message","display","none");
			dojo.style(this.dialogPrefix + "_view","display","none");
	
			dojo.style(this.dialogPrefix + "_preChangeDiv","display","none");
			dojo.style(this.dialogPrefix + "_preAddDiv","display","none");
			dojo.style(this.dialogPrefix + "_dialogCancel","display","none");
		},
		
	menuView:function(){
			var date = new Date();
			dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = "";
			
			var row = this.grid.selection.getSelected()[0];
			var selectedItem = this.grid.model.data[row];
			var batchSize = this.grid.selection.getSelected().length;
			
			if(selectedItem){
				var message = this.hasPermission("view");
				if(message != ""){
					this.dialogShowMessage(message);
				}else{
					this.dialogShowView();
				
					this.toggleLoad();
					var dojoItem = selectedItem.__dojo_data_item;

					if(batchSize == 1){
						var getDataStore = new dojox.data.QueryReadStore({
								url: this.webAppPath + this.baseAction
						});
						//console.warn("after getDatastore instance");
						//console.warn("this.webAppPath + this.baseAction: " + this.webAppPath + this.baseAction);
						var preChangeParams = {}; // associative array to hold they keys to be submitted
						var paramKey = 1;
						dojo.forEach(this.keyNames,
							dojo.hitch(this, function(value, index){
								preChangeParams["" + paramKey] = this.dataStore.getValue(dojoItem,value)
								paramKey++;
						}));
						preChangeParams["func"] = "view";
						var timestamp = date.getTime();
						getDataStore.fetch({
							serverQuery: dojo.mixin({
								"reqCode":"gridPreChange",
								preventCache: timestamp
								},preChangeParams),
							onComplete: 
								dojo.hitch(this,function(items, request){
									var retrievedItem = items[0];
									
									dojo.forEach(this.dataNames,
										dojo.hitch(this, function(value, index){
											var dojoDomObject = dojo.byId(this.dialogPrefix + "_view_" + value);
											dojoDomObject.innerHTML = getDataStore.getValue(retrievedItem,value);
									}));
									
									// {func: funcPtr, method: "add, change, delete"}
									dojo.forEach(this.eventFunctions,
										dojo.hitch(this,function(oneItem, index){
											if(oneItem != null && oneItem.method != null && oneItem.method == "view"){
												dojo.hitch(this,oneItem.func)();
											}
										})
									);
									this.toggleLoad();
									this.dialog.show();
								})
						});
					
					}
				}
			}else
				console.warn('--- nothing selected');
		},
	
	menuAdd: function(){
			var message = this.hasPermission("preAdd");
			if(message != ""){
				this.dialogShowMessage(message);
			}else{
				this.dialogShowEditor("preAdd");
		
				dojo.forEach(this.dataNames,
					dojo.hitch(this, function(value, index){
						var dijitWidget = dijit.byId(this.dialogPrefix + "_" + value);
						//if(dijitWidget.declaredClass == "dijit.form.DateTextBox"){
						dijitWidget.setValue("");
				}));
				
				// {func: funcPtr, method: "add, change, delete"}
				dojo.forEach(this.eventFunctions,
					dojo.hitch(this,function(oneItem, index){
						if(oneItem != null && oneItem.method != null && oneItem.method == "preAdd"){
							dojo.hitch(this,oneItem.func)();
						}
					})
				);
			}
			this.dialog.show();
		},
	
	menuEdit:function(){
			var date = new Date();
			dojo.byId(this.dialogPrefix + "_errorTag").innerHTML = "";
			
			var row = this.grid.selection.getSelected()[0];
			var selectedItem = this.grid.model.data[row];
			var batchSize = this.grid.selection.getSelected().length;
			
			if(selectedItem){
				var message = this.hasPermission("preChange");
				if(message != ""){
					this.dialogShowMessage(message);
				}else{
					this.dialogShowEditor("preChange");
				
					this.toggleLoad();
					var dojoItem = selectedItem.__dojo_data_item;

					if(batchSize == 1){
					
						var getDataStore = new dojox.data.QueryReadStore({
								url: this.webAppPath + this.baseAction
						});
				
						var preChangeParams = {}; // associative array to hold they keys to be submitted
						var paramKey = 1;
						dojo.forEach(this.keyNames,
							dojo.hitch(this, function(value, index){
								preChangeParams["" + paramKey] = this.dataStore.getValue(dojoItem,value)
								paramKey++;
						}));
				
						var timestamp = date.getTime();
						getDataStore.fetch({
							serverQuery: dojo.mixin({
								"reqCode":"gridPreChange",
								preventCache: timestamp
								},preChangeParams),
							onComplete: 
								dojo.hitch(this,function(items, request){
									var retrievedItem = items[0];
									
									// Save the original values to edit in case these key values are changed
									dojo.forEach(this.keyNames,
										dojo.hitch(this, function(value, index){
											dijit.byId(this.dialogPrefix + "_old" + value).setValue(getDataStore.getValue(retrievedItem,value));
									}));
									
									dojo.forEach(this.dataNames,
										dojo.hitch(this, function(value, index){
											var dijitWidget = dijit.byId(this.dialogPrefix + "_" + value);
											dijitWidget.setValue(getDataStore.getValue(retrievedItem,value));
									}));
									
									// {func: funcPtr, method: "add, change, delete"}
									dojo.forEach(this.eventFunctions,
										dojo.hitch(this,function(oneItem, index){
											if(oneItem != null && oneItem.method != null && oneItem.method == "preChange"){
												dojo.hitch(this,oneItem.func)(getDataStore, retrievedItem);
											}
										})
									);
									this.toggleLoad();
								})
						});
					
					}else if(batchSize > 1){
						dojo.forEach(this.dataNames,
							dojo.hitch(this, function(value, index){
								var dijitWidget = dijit.byId(this.dialogPrefix + "_" + value);
								dijitWidget.setValue("");
								
								// {func: funcPtr, method: "add, change, delete"}
								dojo.forEach(this.eventFunctions,
									dojo.hitch(this,function(oneItem, index){
										if(oneItem != null && oneItem.method != null && oneItem.method == "preBatchChange"){
											dojo.hitch(this,oneItem.func)();
										}
									})
								);
						}));
					}
				}
				this.dialog.show();
			}else
				console.warn('--- nothing selected');
		},
	
	menuFilter: function(){
			var message = this.hasPermission("filter");
			if(message != ""){
				this.dialogShowMessage(message);
			}else{
				this.dialogShowFilter();
			}
			this.dialog.show();
		},
	
	menuDelete:function(){
			var message = this.hasPermission("delete");
			if(message != ""){
				this.dialogShowMessage(message);
			}else{
				var date = new Date();
				if (confirm("Do you really want to delete this record?")) {
					var rows = this.grid.selection.getSelected();
					dojo.forEach(rows,
						dojo.hitch(this,function(oneRow, index){
							
							var currentItem = this.grid.model.data[oneRow];
							if(currentItem){
								this.toggleLoad();
								var currentDojoItem = currentItem.__dojo_data_item;
	
								var changeParams = {}; // associative array to hold they keys to be submitted
								var paramKey = 1;
								dojo.forEach(this.keyNames,
									dojo.hitch(this, function(value, index){
										changeParams["" + paramKey] = this.dataStore.getValue(currentDojoItem,value)
										paramKey++;
								}));
								
								var timestamp = date.getTime();
								dojo.xhrPost({
									url: this.webAppPath + this.baseAction,
									content: dojo.mixin({"reqCode":"gridDelete",preventCache: timestamp},changeParams),
									handleAs: "text",
									sync: true,
									handle: dojo.hitch(this,function(response, ioArgs){
											this.toggleLoad();
										})
								});
								
							}
						})
					);
					this.model.refresh();
					this.grid.refresh();
				} else {
					return;
				}
			}
	},
	
	// create number of pages 
	updatePages: function(params){
			this.toggleLoad();
			var date = new Date();
			var timestamp = date.getTime();
			dojo.xhrGet(
			{
					url: this.webAppPath + this.baseAction,
					content: dojo.mixin(
						{"reqCode": "gridGetRowCount",
						"preventCache": timestamp
						},params),
					handleAs: "json",
					sync: true,
					load: dojo.hitch(this, function(response, ioArgs) // Use dojo.hitch to execute the function within the same scope
					{
						// create a new page select and new page select from the returned amount of data
						if(this.pageSelect != null){
							this.pageSelect.destroyRecursive();
						}
						var rowCount;// = parseInt(response);
						
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
								}
							})
						});
						
						var numPages = Math.ceil(rowCount / parseInt(this.itemsPerPageSelect.getValue()));
						var optionNode = null;
						var i;
						var pageSelectNode = document.createElement("select");
						dojo.attr(pageSelectNode, "dojoType", "dijit.form.FilteringSelect");
						
						// Create the items per page select
						for(i = 1; i <= numPages; i++){
							var optionNode = document.createElement("option");
							dojo.attr(optionNode, "value", i);
							optionNode.innerHTML = i;
							pageSelectNode.appendChild(optionNode);
						}
						
						// There is no data to be displayed, display page 1 by default
						if(numPages == 0){
							var optionNode = document.createElement("option");
							dojo.attr(optionNode, "value", 1);
							optionNode.innerHTML = 1;
							pageSelectNode.appendChild(optionNode);
							numPages = 1;
						}
						// Update the label
						dojo.byId(this.id + "_totalPages").innerHTML = " of " + numPages + "&nbsp;&nbsp;";
						
						this.pageSelect = new dijit.form.FilteringSelect({"id":this.id + "_pageSelect", "style":"width: 55px;"},pageSelectNode);
						dojo.byId(this.id + "_pagesFilter").appendChild(this.pageSelect.domNode);
						this.pageSelect.startup();
						
						this.toggleLoad();
						
						// Retrieve which row in the data that should be retrieved when page # changes
						dojo.connect(this.pageSelect,"onChange",dojo.hitch(this,
							function(){
								if(this.pageSelect.isValid()){
									this.model.startItem = (parseInt(this.itemsPerPageSelect.getValue()) * parseInt(this.pageSelect.getValue())) - parseInt(this.itemsPerPageSelect.getValue());
									this.model.refresh();
								}
							})
						);
						
					}),
					error: function(response, ioArgs)  // The ERROR function will be called in an error case.
					{
							console.error("HTTP status code: ", ioArgs.xhr.status);
							return response;
					}
			});
		}
} );