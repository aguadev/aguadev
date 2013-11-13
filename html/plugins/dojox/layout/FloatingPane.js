dojo.provide("plugins.dojox.layout.FloatingPane");

dojo.require("dojox.layout.FloatingPane");
dojo.require("plugins.dojox.layout.Dock");

dojo.declare("plugins.dojox.layout.FloatingPane",
    [ dojox.layout.FloatingPane ], {

/////}}}}

// CSS class of dock node. Default is 'dojoxDockNode' 
// dockClass: string
dockClass: "dojoxDockNode",

constructor: function(){

	//console.log("FloatingPane.constructor    this.dockClass: " + this.dockClass);
	//console.log("FloatingPane.constructor    arguments: " );
	//console.dir({arguments:arguments});

	this.inherited(arguments);
},

postCreate: function(){

	console.log("FloatingPane.postCreate    this.dockClass: " + this.dockClass);
	this.inherited(arguments);
	new dojo.dnd.Moveable(this.domNode,{ handle: this.focusNode });
	//this._listener = dojo.subscribe("/dnd/move/start",this,"bringToTop");

	if(!this.dockable){ this.dockNode.style.display = "none"; }
	if(!this.closable){ this.closeNode.style.diDocsplay = "none"; }
	if(!this.maxable){
		this.maxNode.style.display = "none";
		this.restoreNode.style.display = "none";
	}
	if(!this.resizable){
		this.resizeHandle.style.display = "none";
	}else{
		this.domNode.style.width = dojo.marginBox(this.domNode).w + "px";
	}
	this._allFPs.push(this);
	this.domNode.style.position = "absolute";
	
	this.bgIframe = new dijit.BackgroundIframe(this.domNode);
	this._naturalState = dojo.coords(this.domNode);

    //// CENTER WHEN MAXIMISED
    //dojo.connect(this, "maximize", this, "_position");        
},

startup: function(){
	if(this._started){ return; }
	
//		this.inherited(arguments);

	if(this.resizable){
		if(dojo.isIE){
			this.canvas.style.overflow = "auto";
		}else{
			this.containerNode.style.overflow = "auto";
		}
		
		this._resizeHandle = new dojox.layout.ResizeHandle({
			targetId: this.id,
			resizeAxis: this.resizeAxis
		},this.resizeHandle);

	}

	if(this.dockable){
		// FIXME: argh.
		var tmpName = this.dockTo;

		if(this.dockTo){
			this.dockTo = dijit.byId(this.dockTo);
		}else{
			this.dockTo = dijit.byId('dojoxGlobalFloatingDock');
		}

		if(!this.dockTo){
			var tmpId, tmpNode;
			// we need to make our dock node, and position it against
			// .dojoxDockDefault .. this is a lot. either dockto="node"
			// and fail if node doesn't exist or make the global one
			// once, and use it on empty OR invalid dockTo="" node?
			if(tmpName){
				tmpId = tmpName;
				tmpNode = dojo.byId(tmpName);
			}else{
				tmpNode = dojo.create('div', null, dojo.body());
				dojo.addClass(tmpNode,"dojoxFloatingDockDefault");
				tmpId = 'dojoxGlobalFloatingDock';
			}
			
			console.log("FloatingPane.startup    this:");
			console.dir({this_ie_FloatingPane:this});
			console.log("FloatingPane.startup    this.dockClass: " + this.dockClass);

			this.dockTo = new plugins.dojox.layout.Dock({
				id: tmpId,
				autoPosition: "south",
				dockClass: this.dockClass,
				paneRef: this
			}, tmpNode);
			this.dockTo.startup();
		}
					
		if((this.domNode.style.display == "none")||(this.domNode.style.visibility == "hidden")){
			// If the FP is created dockable and non-visible, start up docked.
			this.minimize();
		}
	}
	this.connect(this.focusNode,"onmousedown","bringToTop");
	this.connect(this.domNode,	"onmousedown","bringToTop");

	// Initial resize to give child the opportunity to lay itself out
	this.resize(dojo.coords(this.domNode));
	
	this._started = true;
},


//_position : function() {
//// 1. POSITION DIALOG IN CENTER OF PAGE
//// 2. DIALOG STAYS PUT ON PAGE SCROLL
//
//	// SET POSITION
//    this._setPosition();
//   // this._doSizing();
//
//	// ENSURE VISIBILITY
//    dojo.style(this.containerNode, "opacity", 1);
//    dojo.style(this.containerNode, "visibility", "visible");
//    dojo.style(this.containerNode, "hidden", null);	
//
//},
//
//_setPosition : function () {
//// EXTRACTED FROM dijit.Dialog
//    if (!dojo.hasClass(dojo.body(),"dojoMove")) {
//        var node = this.domNode;
//        //console.log("FloatingPane._setPosition    node:");
//        //console.dir({node:node});
//        
//        var viewport = dijit.getViewport();
//        //console.log("FloatingPane._setPosition    viewport:");
//        //console.dir({viewport:viewport});
//        
//        var p = this._relativePosition;
//        var mb = p ? null : dojo.marginBox(node);
//		mb = {
//			h	: 	278,
//			l	: 	-400,
//			t	:	0,
//			w	:	695
//		};
//        //console.log("FloatingPane._setPosition    mb:");
//        //console.dir({mb:mb});
//        
//        var left = Math.floor(viewport.l + (p ? p.l : (viewport.w - mb.w) / 2));
//        //console.log("FloatingPane._setPosition    left: " + left);
//        
//	
//        dojo.style(node,{
//            left: left + "px",
//            top: "100px"
//        });
//    }
//},
//
//_doSizing : function () {
//    if(!this.open){ dojo.style(this.containerNode, "opacity", 0); }
//    var pad = this.viewportPadding * 2; 
//    //console.log("FloatingPane._doSizing    pad: " + pad);
//    
//    var props = {
//        node: this.domNode,
//        duration: this.sizeDuration || dijit._defaultDuration,
//        easing: this.easing,
//        method: this.sizeMethod
//    };
//    //console.log("FloatingPane._doSizing    props:");
//    //console.dir({props:props});
//
//    // CHANGE _displaysize.h FROM "auto" TO 800, IGNORE this._vp 
//    //console.log("FloatingPane._doSizing    this._displaysize:");
//    //console.dir({this__displaysize:this._displaysize});
//    this._displaysize = { h: 0, w: 800 };
//    var ds = this._displaysize;
//    //console.log("FloatingPane._doSizing    ds: ");
//    //console.dir({ds:ds});
//    props['width'] = ds.w;
//    props['height'] = ds.h;
//	
//	// DO SIZING
//    //console.log("FloatingPane._doSizing    FINAL props:");
//    //console.dir({props:props});
//    this._sizing = dojox.fx.sizeTo(props);
//    this._sizing.play();
//}

});
