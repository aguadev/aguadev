dojo.provide("plugins.dojox.layout.Dock");

dojo.require("dojox.layout.FloatingPane");

dojo.declare("plugins.dojox.layout.Dock",
	[dijit._Widget,dijit._Templated], {

// summary:
//		A widget that attaches to a node and keeps track of incoming / outgoing FloatingPanes
// 		and handles layout

templateString: '<div class="dojoxDock"><ul dojoAttachPoint="containerNode" class="dojoxDockList"></ul></div>',

// private _docked: array of panes currently in our dock
_docked: [],

_inPositioning: false,

autoPosition: false,

// CSS class of dock node. Default is 'dojoxDockNode' 
// dockClass: string
dockClass: "dojoxDockNode",

/////}}}}

addNode: function(refNode){
	// summary: Instert a dockNode refernce into the dock
	
	var div = dojo.create('li', null, this.containerNode);
	//console.log("Dock.addNode    this:");
	//console.dir({this_ie_Dock:this});
	//console.log("Dock.addNode    this.dockClass: " + this.dockClass);
	var	node = new plugins.dojox.layout._DockNode({
			title: refNode.title,
			paneRef: refNode,
			dockClass: refNode.dockClass
		}, div)
	;
	node.startup();
	return node;
},
startup: function(){
			
	if (this.id == "dojoxGlobalFloatingDock" || this.isFixedDock) {
		// attach window.onScroll, and a position like in presentation/dialog
		this.connect(window, 'onresize', "_positionDock");
		this.connect(window, 'onscroll', "_positionDock");
		if(dojo.isIE){
			this.connect(this.domNode, "onresize", "_positionDock");
		}
	}
	this._positionDock(null);
	this.inherited(arguments);

},
_positionDock: function(/* Event? */e){
	if(!this._inPositioning){
		if(this.autoPosition == "south"){
			// Give some time for scrollbars to appear/disappear
			setTimeout(dojo.hitch(this, function() {
				this._inPositiononing = true;
				var viewport = dojo.window.getBox();
				var s = this.domNode.style;
				s.left = viewport.l + "px";
				s.width = (viewport.w-2) + "px";
				s.top = (viewport.h + viewport.t) - this.domNode.offsetHeight + "px";
				this._inPositioning = false;
			}), 125);
		}
	}
}

});

dojo.declare("plugins.dojox.layout._DockNode",
    [ dojox.layout.Dock ], {

// summary:
//		dojox.layout._DockNode is a private widget used to keep track of
//		which pane is docked.
//

templateString:
	'<li dojoAttachEvent="onclick: restore" class="dojoxDockNode">'+
		'<span dojoAttachPoint="restoreNode" class="dojoxDockRestoreButton" dojoAttachEvent="onclick: restore"></span>'+
		'<span class="dojoxDockTitleNode" dojoAttachPoint="titleNode">${title}</span>'+
	'</li>',

// CSS class of dock node. Default is 'dojoxDockNode' 
// dockClass: string
dockClass: null,

/////}}}}

postCreate: function(){
	//console.log("DockNode.postCreate    this.dockClass: " + this.dockClass)
	//console.log("DockNode.postCreate    this.templateString: " + this.templateString)
	var dockClass = this.dockClass;
	if ( dockClass ) {
		//console.log("DockNode.postCreate    DOING dojo.addClass(this.domNode, dockClass)");
		dojo.attr(this.domNode, 'class', dockClass);
	}
	
	if ( this.dockClass ) {
		this.templateString = '<li dojoAttachEvent="onclick: restore" class="dojoxDockNode ' + this.dockClass + '">'+
			'<span dojoAttachPoint="restoreNode" class="dojoxDockRestoreButton" dojoAttachEvent="onclick: restore"></span>'+
			'<span class="dojoxDockTitleNode" dojoAttachPoint="titleNode">${title}</span>'+
		'</li>'
	}

	//console.log("DockNode.postCreate    this.templateString: " + this.templateString)

},
restore: function(){
	// summary: remove this dock item from parent dock, and call show() on reffed floatingpane
	this.paneRef.show();
	this.paneRef.bringToTop();
	this.destroy();
}

});
