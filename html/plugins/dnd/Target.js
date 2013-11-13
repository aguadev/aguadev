dojo.provide("plugins.dnd.Target");

// SUMMARY: A Target DnD object that accepts dropped apps and converts them to stages

dojo.require("dojo.dnd.Source");
dojo.require("dojo.dnd.Target");

dojo.declare("plugins.dnd.Target", [ dojo.dnd.Target ], {

// contextMenu: dijit.Menu OBJECT. CONTEXT MENU FOR ALL NODES
contextMenu : null,

// parentWidget: plugins.workflow.Workflows OBJECT.	
parentWidget : null,

// droppingApp : string
// Flag to prevent multiple drops
droppingApp : null,

// dragType: array
// List of permitted dragged items allowed to be dropped
dragTypes : ["draggableItem"],

/////}}}

constructor: function(node, params) {
	console.log("Target.constructor    params: " + params);
	console.log("Target.constructor    params.contextMenu: " + params.contextMenu);
	console.log("Target.constructor    params.this.parentWidget: " + params.parentWidget);

	this.contextMenu = params.contextMenu;
	this.parentWidget = params.parentWidget;
	this.core = params.core;
	if ( params && params.dragTypes )
		this.dragTypes = params.dragTypes
	
	// summary:
	//		a constructor of the Target --- see the `dojo.dnd.Source.constructor` for details
	this.isSource = false;
	dojo.removeClass(this.node, "dojoDndSource");
},

resetDropping : function () {
// RESET this.droppingApp TO FALSE
	this.droppingApp = false;
},

onDndDrop : function(source, nodes, copy) {
// USE dojo.connect TO ADD EVENT TO NEW ITEM
// NB: DROPPED NODES MUST HAVE AN application SLOT

	// RETURN IF DROP FLAG IS SET
	console.log("Target.onDndDrop    XXXXXXXXXXXXXXXXXXXXXXXX this.droppingApp: " + this.droppingApp);
	var acceptance = this.checkAcceptance(source, nodes);
	console.log("Target.onDndDrop    XXXXXXXXXXXXXXXXXXXXXXXX acceptance: " + acceptance);
	if ( ! acceptance ) {
		console.log("Target.onDndDrop    acceptance is FALSE. Returning");
		return;
	}
	
	


	if ( ! this.accept || this.accept.length < 1 ) {
		console.log("Target.onDndDrop    this.accept is empty. Returning");
		return;
	}
	
	if ( this.droppingApp ) {
		console.log("Target.onDndDrop    this.droppingApp is true. Returning");
		return;
	}
	else {
		this.droppingApp = true;
	}

	// SET DROP FLAG
	console.log("Target.onDndDrop    Set this.droppingApp: " + this.droppingApp);
	
	console.log("Target.onDndDrop    this: " + this);
	console.log("Target.onDndDrop    source: ");
	console.dir({source:source});
	console.log("Target.onDndDrop    nodes.length: " + nodes.length);
	console.log("Target.onDndDrop    nodes[0].data: " + nodes[0].data);
	console.dir({nodes_0:nodes[0]});

	
	var thisObject = this;


	// SANITY
	if ( nodes[0].data == null )	return;
	
	// summary: topic event processor for /dnd/drop,
	// called to finish the DnD operation break box
	var newNode;
	do
	{ 
		if ( this.containerState != "Over" )
		{
			break;
		}

		var oldCreator = this._normalizedCreator;

		// transferring nodes from the source to the target
		if ( this != source )
		{
			// CLONE THE DROPPED NODE AND ADD THE
			// CLONE TO THE DROP TARGET
			this._normalizedCreator = function(node, hint)
			{
				var t = source.getItem(node.id);
				var n = node.cloneNode(true);
				n.parentWidget = node.parentWidget;
				n.id = dojo.dnd.getUniqueId();
				return {node: n, data: t.data, type: t.type};
			};
		}  
		
		// CLEAN UP - REMOVE SELECTION AND ANCHOR STYLE
		this._removeSelection();
		if ( this != source )
		{
			this._removeAnchor();
		}

		if ( this != source && !copy && !this.creator )
		{
			source.selectNone();
		}

		// INSERT DROPPED NODE INTO DROP TARGET
		this.insertNodes(true, nodes, this.before, this.current);
		this.sync();

		// COMPLETE THE NODE COPY:
		//
		// 1. TRANSFER THE METADATA FROM THE DROPPED NODE TO
		// THE CLONED NODE.
		// 
		// 2. INCREMENT BY ONE THE number OF THE NODES AFTER
		// THE INSERTION POINT OF THE NEW NODE.
		var belowInsertedNode = false;
		var allNodes = this.getAllNodes();
		console.log("Target.onDndDrop    allNodes: " + allNodes);
		console.log("Target.onDndDrop    allNodes.length: " + allNodes.length);

		dojo.forEach(allNodes, function(node, i)
		{
			if ( node.application == null )
			{
				// CLONE THIS OTHERWISE GET AN INTERESTING ERROR
				// WHEN DUPLICATE COPIES OF THE SAME APPLICATION
				// ARE DROPPED (SHARING THE SAME application OBJECT)
				node.application = dojo.clone(nodes[0].data);
				console.log("Target.onDndDrop    Setting node.application: ");
				console.dir({node_application:node.application});

				// ADD appname TO APPLICATION
				node.application.appname = node.application.name;
				
				// ADD NUMBER TO APPLICATION
				// CAST number TO STRING FOR LATER SORTING
				node.application.appnumber = (i + 1).toString();
				node.application.number = (i + 1).toString();
				node.number = (i + 1).toString();

				// SET DEFAULT CLUSTER IS EMPTY
				if ( node.application["cluster"] == null )	node.application["cluster"] = '';
				
				// ADD PROJECT AND WORKFLOW TO node's APPLICATION
				var project = thisObject.core.userWorkflows.getProject();
				var workflow = thisObject.core.userWorkflows.getWorkflow();
				node.application.project = project;
				node.application.workflow = workflow;
				
				// SET WORKFLOWNUMBER
				var workflowobject = Agua._getWorkflow({name:workflow,project:project});
				console.log("Target.onDndDrop    workflowobject: ");
				console.dir({workflowobject:workflowobject});
				var workflownumber = workflowobject.number;
				console.log("Target.onDndDrop    workflownumber: " + workflownumber);
				node.application.workflownumber = dojo.clone(workflownumber);
				
				// SET USERNAME
				node.application.username = Agua.cookie('username');
				console.log("Target.onDndDrop    node.application: ");
				console.dir({application:node.application});
				
				// INSTANTIATE SOURCE ROW 
				var stageRow = new plugins.workflow.StageRow(node.application);
				console.log("Target.onDndDrop    stageRow: " + stageRow);
				console.log("Target.onDndDrop    stageRow.domNode: " + stageRow.domNode);
				console.log("Target.onDndDrop    stageRow.application: " + dojo.toJson(stageRow.application));

				// SET CORE WORKFLOW OBJECTS
				stageRow.core = thisObject.core;
	
				stageRow.workflowWidget = thisObject.core.userWorkflows.parentWidget;
	
				// CLEAR NODE CONTENT
				node.innerHTML = '';
	
				// APPEND stageRow WIDGET TO NODE
				node.appendChild(stageRow.domNode);
				
				// ADD CONTEXT MENU TO NODE
				thisObject.contextMenu.bind(node);

				// SET stageRow AS node.parentWidget ATTRIBUTE FOR ACCESS LATER:
				// --- (ALSO ADDED this.name.parentWidget = this IN StageRow.startup())
				//
				// 1. WHEN CALLING Workflow.loadParametersPane SO THAT THE CORRECT
				// StageRow HAS ITS validInputs SET ACCORDING TO THE OUTCOME
				// OF Workflow.loadParametersPane
				//
				// 2. FOR RESETTING OF number ON REMOVAL OR INSERTION OF NODES
				//
				// REM: remove ONCLICK BUBBLES ON stageRow.name NODE RATHER THAN ON node. 
				// I.E., CONTRARY TO DESIRED, thisObject.name IS THE TARGET INSTEAD OF THE node.
				node.parentWidget = stageRow;

				//NB: NOT THIS: node.parentWidget = dojo.clone(nodes[0].parentWidget);
				console.log("Target.onDndDrop    node.id: " + node.id);
				console.log("Target.onDndDrop    Set node.parentWidget: " + node.parentWidget);	

				// INSERT STAGE INTO thisObject.stage AND ITS STAGE PARAMETERS
				// INTO Agua.stages AND Agua.stageparameters
				console.log("Target.onDndDrop    BEFORE    Agua.insertStage(node.application)");
				var insertOk = Agua.insertStage(node.application);
				if ( ! insertOk )
				{
					console.log("Target.onDndDrop    Failed to add stage to Agua data");
					// UNSET droppingApp FLAG
					console.log("Target.onDndDrop    Setting thisObject.droppingApp to false and returning");
					//thisObject.droppingApp = false;
					setTimeout(thisObject.resetDropping, 1000);
					return;
				}
				console.log("Target.onDndDrop    AFTER    Agua.insertStage(node.application)");

				// ADD ONCLICK TO LOAD APPLICATION INFO
				node.onclick = function(e)
				{
					console.log("Target.onDndDrop    node.onclick fired, calling thisObject.core.userWorkflows.loadParametersPane(node, null)");
					console.log("Target.onDndDrop    node: " + node);
					thisObject.core.userWorkflows.loadParametersPane(node, null);
				}

				// ADD CONTEXT MENU
				thisObject.contextMenu.bind(node);
				
				// SET THE DEFAULT CHAINED VALUES FOR INPUTS AND OUTPUTS FOR THE
				// APPLICATION BASED ON THOSE OF THE PREVIOUS APPLICATIONS
				thisObject.core.userWorkflows.getChainedValues(node);

				// SET belowInsertedNode FLAG TO TRUE
				belowInsertedNode = true;
				
				// UNSET droppingApp FLAG
				console.log("Target.onDndDrop    Setting thisObject.droppingApp = false");
				thisObject.droppingApp = false;

				// SET NEW NODE FOR LOAD INFO PANE LATER
				newNode = node;
				

				return;
			}
			console.log("Target.onDndDrop    belowInsertedNode: " + belowInsertedNode); 
							
			// IF WE ARE BELOW THE INSERTED NODE, CHAIN THE STAGE
			if ( belowInsertedNode == true )
			{
				console.log("Target.onDndDrop    node " + i + " is belowInsertedNode");
				console.log("Target.onDndDrop    DOING thisObject.core.io.chainStage(node.application, force)");
				console.log("Target.onDndDrop    thisObject.core.userWorkflows: " + thisObject.core.userWorkflows);
				
				var force = true;
				console.log("Target.onDndDrop    Doing thisObject.core.io.chainStage(node.application, force)");
				thisObject.core.io.chainStage(node.application, force);
			}
		});

		// UNSET droppingApp FLAG
		console.log("Target.onDndDrop    BEFORE thisObject.droppingApp = false");
		console.log("Target.onDndDrop    thisObject.core.userWorkflows: " + thisObject.core.userWorkflows);
		thisObject.droppingApp = false;

		thisObject._normalizedCreator = oldCreator;
	}
	while(false);
	// end of 'do'

	// SET THE APPLICATION.NUMBER AND .APPNUMBER FOR EACH NODE AND ITS WIDGET
	setTimeout(function() {
		console.log("Target.onDndDrop    Doing this.core.userWorkflows.resetNumbers()");
		thisObject.core.userWorkflows.resetNumbers();

		console.log("Target.onDndDrop    Setting this.core.runStatus.polling TO FALSE");
		if ( thisObject.core.runStatus )
			thisObject.core.runStatus.polling = false;

		// SET INFO PANE FOR DROPPED NODE
		console.log("Target.onDndDrop    Doing this.core.userWorkflows.loadParametersPane(newNode)");
		console.dir({thisObject:thisObject});
		thisObject.core.userWorkflows.loadParametersPane(newNode);
	}, 100);


// ******************* DISABLED FOR DEBUGGING ***********************
// ******************* DISABLED FOR DEBUGGING ***********************


	console.log("Target.onDndDrop    BEFORE this.onDndCancel");
	this.onDndCancel();

	console.log("Target.onDndDrop    END OF this.onDndCancel");
}	// OVERRIDE onDndDrop TO USE dojo.connect TO ADD EVENT TO NEW ITEM







});
