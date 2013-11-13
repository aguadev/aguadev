dojo.provide("plugins.project.Project");

// DISPLAY THE USER'S PROJECTS DIRECTORY AND ALLOW
// THE USER TO BROWSE FILES AND MANIPULATE WORKFLOW
// FOLDERS AND FILES

dojo.require("plugins.project.FileDrag");
dojo.require("dojox.data.FileStore");

// DnD
dojo.require("dojo.dnd.Source"); // Source & Target
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");

// FILE UPLOAD
dojo.require("plugins.project.FileInput");	
dojo.require("plugins.project.FileInputAuto");	


// WidgetFramework ancestor
dojo.require("plugins.core.WidgetFramework");

dojo.declare( "plugins.project.Project", plugins.core.WidgetFramework,
{
	// PANE IDENTIFIER
	paneId : '',
		
	// LAYOUT TO GENERATE WORKFLOW PANE
	layout: '',
	
	// STORE DND SOURCE ID AND DND TARGET ID
	sourceId: '',
	targetId: '',

 	// CONSTRUCTOR	
	constructor : function(args) {
////		console.log("++++ plugins.project.Project.constructor");

		if ( ! args.paneId )
		{
////			console.log("No paneId in workflow args");
			return;
		}
		
		// SET PANE ID
		this.paneId = args.paneId;
////		//console.log("this.paneId: " + this.paneId);

		// SET IDS IN LAYOUT USING PANE ID
		this.setIds();
		
		// SET TAB CONTAINER NODE ID ( THE SAME AS THE ID SET ABOVE IN this.setIds() )
		var tabContainerNodeId = this.paneId + "tabContainer";
		
		// CREATE TARGET NODE
		var targetNode = document.createElement('div');
////		console.log("targetNode: " + targetNode);
		targetNode.id = 'tab' + this.paneId;
////		console.log("targetNode.id: " + targetNode.id);
		document.body.appendChild(targetNode);
		
		// CREATE FRAMEWORK USING INHERITED create FROM WidgetFramework
////		console.log("BEFORE create");
		this.create(this.layout, { root: tabContainerNodeId, target: 'tab' + this.paneId } );
////		console.log("AFTER create");

		// APPEND TAB TO TABS CONTAINER
		var tabsNodeId = args.tabsNodeId;
////		console.log("tabsNodeId: " + tabsNodeId);
////		console.log("dojo.byId(tabsNodeId): " + dojo.byId(tabsNodeId));
		var tabsNode = dijit.byId(args.tabsNodeId);
		
////		//console.log("tabsNode: " + tabsNode);
		var tabNode = dijit.byId(tabContainerNodeId);
////		console.log("tabNode: " + tabNode);
		tabsNode.addChild(tabNode);

		// SELECT THIS CHILD IN TABS
		tabsNode.selectChild(tabNode);

////	//console.log("Debugging... Ending before loadCSS() and loadProjectTab().");
	//return;


        // LOAD SORIA AND FILEPICKER CSS
        this.loadCSS();



		// LOAD APPLICATIONS DND SOURCE AND TARGET INTO FRAMEWORK
		this.loadProjectTab();
	},

	projects: function()
	{
////		console.log("oOoOoOoOoOoOoOoOoOoOoOoOoOoO plugins.project.Project.projects()");

		var projects;
		
		var username = "admin";
		var sessionId = "1228791394.7868.158";
		var url = cgiurl + "project.cgi?";
		var query = "mode=projects";
		query += "&sessionId=" + sessionId;
		query += "&username=" + username;		
////		//console.log("oOoOoOoOoOoOoOoOoOoOoOoOoOoO query: " + query);

		projects = this.getSyncJson(url + query);
////		//console.log("oOoOoOoOoOoOoOoOoOoOoOoOoOoO projects: " + dojo.toJson(projects));

		return projects;
	},



	loadProjectTab: function ()	
	{	
////		console.log("*O*O*O*O*O*O*O*O*O*O*O*O*O*O plugins.project.Project.loadProjectTab()");
		var sourceId = this.paneId + "leftPane";
		var targetId = this.paneId + "middlePane";
		var infoId = this.paneId + "rightPane";


		var projects = this.projects();
////		console.log("*O*O*O*O*O*O*O*O*O*O*O*O*O*O projects: " + dojo.toJson(projects));

		var sources = projects.sources;
		projects = projects.projects;

	
		// POPULATE PROJECTS PANE
		for ( var i = 0; i < projects.length; i++ )
		//for ( var i = 0; i < 1; i++ )
		{
			var project = projects[i].project;
			var owner = projects[i].owner;
			
			//var project = projectPath.match(/^\.*\/*(.+)$/)[1];

////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
			
			// CREATE 'PROJECTS' FILE DRAGGER
			var paneNodeId = dojo.dnd.getUniqueId();
			
			//var paneNodeId = project + "-" + owner;
			var paneNode = document.createElement('div');
////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& paneNodeId: " + paneNodeId);
			paneNode.id = paneNodeId;
			document.body.appendChild(paneNode);

			var containerNode = document.createElement('div');
			containerNode.id = paneNodeId + "-projectContainer";
			containerNode.innerHTML = project + "<BR>";
			paneNode.appendChild(containerNode);

			var projectStore = new dojox.data.FileStore(
				{
					id: paneNodeId + "-fileStore",
					url: cgiurl + "project.cgi?mode=fileSystem&sessionId=1228319084.3060.776&username=admin",
					pathAsQueryParam: true
				}
			);
			
			// SET FILE STORE path TO project
			projectStore.preamble = function()
			{
				this.store.path = this.arguments[0].path;                        
			};

			// GENERATE NEW FileDrag OBJECT
			var ProjectDrag = new plugins.project.FileDrag(
				{
					id: paneNodeId + "-ProjectDrag",
					style: "height: 100px; width: 90%;",
					store: projectStore
				}
			);
			
			// SET PATH FOR THIS PROJECT
			ProjectDrag.path = project;                    
			
			// START UP FileDrag
			ProjectDrag.startup();

			paneNode.appendChild(ProjectDrag.domNode);
			
			// APPEND FileDrag TO PANE
			dojo.byId(sourceId).appendChild(paneNode);
		
		} // for loop on projects.length		



		// POPULATE SOURCES PANE
		//for ( var i = 0; i < sources.length; i++ )
		for ( var i = 0; i < 1; i++ )
		{
			var project = sources[i].project;
			var owner = sources[i].owner;
			
			//var project = projectPath.match(/^\.*\/*(.+)$/)[1];

////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& " + project);
			
			// CREATE 'PROJECTS' FILE DRAGGER
			//var paneNodeId = project + "-" + owner;
			var paneNodeId  = dojo.dnd.getUniqueId();

////			console.log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& paneNodeId: " + paneNodeId);
			var paneNode = document.createElement('div');
			paneNode.id = paneNodeId;
			document.body.appendChild(paneNode);

			var containerNode = document.createElement('div');
			containerNode.id = paneNodeId + "-projectContainer";
			containerNode.innerHTML = project;
			paneNode.appendChild(containerNode);

			
			var projectStore = new dojox.data.FileStore(
				{
					id: paneNodeId + "-fileStore",
					url: cgiurl + "project.cgi?mode=fileSystem&sessionId=1228319084.3060.776&username=admin",
					pathAsQueryParam: true
				}
			);
			
			// SET FILE STORE path TO project
			projectStore.preamble = function()
			{
				this.store.path = this.arguments[0].path;                        
			};

			// GENERATE NEW FileDrag OBJECT
			var ProjectDrag = new plugins.project.FileDrag(
				{
					id: paneNodeId + "-ProjectDrag",
					style: "height: 100px; width: 90%;",
					store: projectStore
				}
			);
			
			// SET PATH FOR THIS PROJECT
			ProjectDrag.path = "owner:" + owner + "/" + project;                    
			
			// START UP FileDrag
			ProjectDrag.startup();
			
			// APPEND FileDrag TO PANE
			paneNode.appendChild(ProjectDrag.domNode);

			// APPEND FileDrag TO PANE
			dojo.byId(targetId).appendChild(paneNode);
		
		} // for loop on sources.length		

		this.sourceId = sourceId;
		this.targetId = targetId;
	},
 


	loadRightPaneTabs : function ( containerId )
	{
		// GET APPLICATION GRID CONTAINER
		var uploadContainer = dojo.byId(containerId);


		// REMOVE EXISTING GRID NODE FROM GRID CONTAINER
		while(uploadContainer.firstChild)
		{
		   uploadContainer.removeChild(uploadContainer.firstChild);
		}


		var sampleCallback = function(data,ioArgs,widgetRef){
			// this function is fired for every programatic FileUploadAuto
			// when the upload is complete. It uses dojo.io.iframe, which
			// expects the results to come wrapped in TEXTAREA tags.
			// this is IMPORTANT. to utilize FileUploadAuto (or Blind)
			// you have to pass your respose data in a TEXTAREA tag.
			// in our sample file (if you have php5 installed and have
			// file uploads enabled) it _should_ return some text in the
			// form of valid JSON data, like:
			// { status: "success", details: { size: "1024" } }
			// you can do whatever.
			//
			// the ioArgs is the standard ioArgs ref found in all dojo.xhr* methods.
			//
			// widget is a reference to the calling widget. you can manipulate the widget
			// from within this callback function 
			if(data){
				if(data.status && data.status == "success"){
					widgetRef.overlay.innerHTML = "success!";
				}else{
					widgetRef.overlay.innerHTML = "error? ";
////					console.log('error',data,ioArgs);
				}
			}else{
				// debug assist
////				console.log('ugh?',arguments);
			}
		}

		var i = 0;
		function addNewUpload(dynamicUploadId)
        {
////			console.log("dynamicUploadId: " + dynamicUploadId);
            var node = document.createElement('input');
			dojo.byId(dynamicUploadId).appendChild(node);
			var widget = new plugins.project.FileInputAuto({
				id: "dynamic"+(++i),
				url: "plugins/projects/FileInput/ReceiveFile.php",
				//url:"http://archive.dojotoolkit.org/nightly/checkout/dojox/widget/FileInput/ReceiveFile.php",
				name: "dynamic"+i,
				onComplete: sampleCallback
			},node);
			widget.startup();
		}

        var projects = this;
		var uploadButton = new dijit.form.Button( { label: "Add new file upload", style: "height: 20px; font-weight: bold", onClick: function (e) { addNewUpload(dynamicUploadId)(e, containerId) } } );
		uploadContainer.appendChild(uploadButton.domNode);
////		console.log("added uploadButton to uploadContainer");

		// SET 'Add new file upload' BUTTON
        var dynamicUpload = document.createElement('div');
        var dynamicUploadId = containerId + "-dynamic";
        dynamicUpload.id = dynamicUploadId;
        uploadContainer.appendChild(dynamicUpload);
////        console.log("dynamicUpload.id: " + dynamicUpload.id);

        
	//<button onclick="addNewUpload()">add new file upload</button>
	//<br><br>
	//<div id="dynamic" class="tundra"></div>



		//// SET Save BUTTON
		//var saveButton = new dijit.form.Button( { label: "Save", style: "height: 20px; font-weight: bold", onClick: function (e) { workflow.saveGrid(e, containerId) } } );
		//gridContainer.appendChild(saveButton.domNode);
////		////console.log("added saveButton to gridContainer");
		//
		//
		//
		//
		//
		//// SET defaults BUTTON
		//var defaultsButton = new dijit.form.Button( { label: "Defaults", style: "height: 20px; font-weight: bold", onClick: function (e) { workflow.defaultsGrid(e, containerId) } } );
		//gridContainer.appendChild(defaultsButton.domNode);
////		////console.log("added DefaultsButton to gridContainer");
		//
		
		
	},


	
	// GENERATE UNIQUE IDS FOR THE Projects PANE BY ADDING INCREMENTED PANE ID
	setIds : function()
	{
		// LAYOUT TEMPLATE
		var layout = {
			widgetType: "dijit.layout.SplitContainer",
			//params: {id: "tabContainer", closable: "true", title: this.paneId, style:'height:450px; width:850px;'},
			params: { id: "tabContainer", closable: "true", title: '', orientation: 'vertical' },
			innerHTML: this.paneId + " ContentPane"
			,
			children:
			[
				{
					widgetType: "dijit.layout.ContentPane",
					params: {id: "leftPane", sizeShare:  40, style: "background: #EEEEFF;" },
					style: "background: #EEEEFF;",
					innerHTML: "Project folders"
				},
				{
					widgetType: "dijit.layout.ContentPane",
					params: {id: "middlePane", sizeShare:  40, style: "background: #EEEEFF;" },
					style: "background: #EEEEFF;",
					innerHTML: "Source folders"
				},
				{
					widgetType: "dijit.layout.TabContainer",
					params: {id: "rightTabContainer", sizeShare: 20 },
					children:
					[
						{
							widgetType: "dijit.layout.ContentPane",
							params: {id: "rightPane-upload", title: 'Upload', style: "background: #EEEEFF;" },
							style: "background: #EEEEFF;",
							innerHTML: ""
						},
						{
							widgetType: "dijit.layout.ContentPane",
							params: {id: "rightPane-arguments", title: 'Link', style: "background: #EEEEFF;" },
							style: "background: #EEEEFF;",
							innerHTML: ""
						}
					]
				}
			]
		};
		
		// SET UNIQUE IDS USING this.paneId
		if ( this.paneId.match(/^(.)(\D+)(\d+)$/) )
		{
			var firstLetter = this.paneId.match(/^(.)(\D+)(\d*)$/)[1];
			firstLetter = firstLetter.toUpperCase();
			var rest = this.paneId.match(/^(.)(\D+)(\d+)$/)[2];
			var number = this.paneId.match(/^(.)(\D+)(\d+)$/)[3];		
			layout.params.title = firstLetter + rest + " " + number;
		}
		
		layout.params.id = this.paneId + layout.params.id;
		for ( var i in layout.children )
		{
			layout.children[i].params.id = this.paneId + layout.children[i].params.id;

			for ( var j in layout.children[i].children )
			{
				layout.children[i].children[j].params.id = this.paneId + layout.children[i].children[j].params.id;
			}
		}

////		console.log("plugins.project.Project.setIds layout: " + dojo.toJson(layout));
		this.layout = layout;		
	},
	

    loadCSS : function ()
    {
        
		// LOAD CSS
		var cssFiles = [ "dojo.1.2.2/dojo/resources/dojo.css", "dojo.1.2.2/dijit/tests/css/dijitTests.css" ];
		for ( var i in cssFiles )
		{
			var cssFile = cssFiles[i];
			var cssNode = document.createElement('link');
			cssNode.type = 'text/css';
			cssNode.rel = 'stylesheet';
			cssNode.href = cssFile;
			cssNode.media = 'screen';
			cssNode.title = 'loginCSS';
			document.getElementsByTagName("head")[0].appendChild(cssNode);
		}

        // THIS CSS FILE PROVIDES THE ICONS AND FORMATTING FOR INDIVIDUAL FILES/DIRECTORIES
		var cssFile1 = "dojo.1.2.2/dijit/themes/soria/soria.css";
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile1;
		cssNode.media = 'screen';
		cssNode.title = 'loginCSS';
		cssNode.id = "themeStyles";
		document.getElementsByTagName("head")[0].appendChild(cssNode);

//        // THIS CSS FILE PROVIDES THE ICONS AND FORMATTING FOR INDIVIDUAL FILES/DIRECTORIES
//		var cssFile2 = "dojo.1.2.2/dojox/widget/FilePicker/FilePicker.css";
//		var cssNode = document.createElement('link');
//		cssNode.type = 'text/css';
//		cssNode.rel = 'stylesheet';
//		cssNode.href = cssFile2;
//		cssNode.media = 'screen';
//		cssNode.title = 'loginCSS';
//		cssNode.id = "widgetStyle";
//		document.getElementsByTagName("head")[0].appendChild(cssNode);
// 
 
        // THIS CSS FILE PROVIDES THE ICONS AND FORMATTING FOR INDIVIDUAL FILES/DIRECTORIES
		var cssFile3 = "plugins/project/FileDrag/FileDrag.css";
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile3;
		cssNode.media = 'screen';
		cssNode.title = 'loginCSS';
		cssNode.id = "widgetStyle";
		document.getElementsByTagName("head")[0].appendChild(cssNode);
    },


	loadJson : function (url)
	{
		var json;
		dojo.xhrGet(
			{
				url: url,
				handleAs: "json",
					//handleAs: "json-comment-optional",
				sync: true,
				handle: function(response){
					json = response.data;
////					//console.log("applicationJson (INSIDE): " + dojo.toJson(applicationJson));
				}
			}
		);
	
		return json;
	},
	
	getSyncJson : function (url)
	{
		var json;
		dojo.xhrGet(
			{
				url: url,
				//handleAs: "json",
				handleAs: "json-comment-optional",
				sync: true,
				handle: function(response){
////					//console.log("getSyncJson(url), response: " + response);
					json = response;
				}
			}
		);
	
		return json;
	}


}); // end of Login

