define([
	"require",
	"dojo/_base/declare",
	"dojo/window",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-style", 		// domStyle.getComputedStyle
	"dojo/dom-geometry", 	// domStyle.getComputedStyle domGeometry.position
	"dojox/fx",
	"dojo/has",
	"dojo/_base/Deferred",
	"dojox/widget/Dialog",
	"dojo/dom-attr",
	"dojo/ready"
], function (require, declare, winUtils, on, lang, domStyle, domGeometry, fx, has, Deferred, Dialog, domAttr, ready) {

/////}}}}}}

return declare("plugins.dojox.widget.Dialog",
	[Dialog], {

// autofocus: Boolean
//		A Toggle to modify the default focus behavior of a Dialog, which
//		is to focus on the first dialog element after opening the dialog.
//		False will disable autofocusing. Default: true
autofocus: false,

/////}}}}}}

postCreate : function () {
	
	this.inherited(arguments);
	
	var thisObject = this;
	ready(function() {
		domAttr.set(thisObject.closeButtonNode, "title", "Click to close dialog and discard unsaved changes");
	})
	
},
focus: function(){
	//console.log("dojox.widget.Dialog.focus    Skipping focus. RETURN");
	//return;

	this._getFocusItems(this.domNode);
	focus.focus(this._firstFocusItem);
},

onLoad: function(){
	// summary:
	//		Called when data has been loaded from an href.
	//		Unlike most other callbacks, this function can be connected to (via `dojo.connect`)
	//		but should *not* be overridden.
	// tags:
	//		callback

	// when href is specified we need to reposition the dialog after the data is loaded
	// and find the focusable elements

	this._position();
	if(this.autofocus && DialogLevelManager.isTop(this)){
		this._getFocusItems(this.domNode);
		focus.focus(this._firstFocusItem);
	}
	this.inherited(arguments);
},

_size: function(){
	// summary:
	//		If necessary, shrink dialog contents so dialog fits in viewport.
	// tags:
	//		private

	//console.log("plugins.dojox.widget.Dialog._size    caller: " + this._size.caller.nom);

	this._checkIfSingleChild();

	// If we resized the dialog contents earlier, reset them back to original size, so
	// that if the user later increases the viewport size, the dialog can display w/out a scrollbar.
	// Need to do this before the domGeometry.position(this.domNode) call below.
	if(this._singleChild){
		//console.log("plugins.dojox.widget.Dialog._size    INSIDE if ( this._singleChild )");

		if(typeof this._singleChildOriginalStyle != "undefined"){
			//console.log("plugins.dojox.widget.Dialog._size    setting this._singleChild.domNode.style.cssText TO this._singleChildOriginalStyle: " + this._singleChildOriginalStyle);

			this._singleChild.domNode.style.cssText = this._singleChildOriginalStyle;
			delete this._singleChildOriginalStyle;
		}
	}
	else {
		//console.log("plugins.dojox.widget.Dialog._size    domStyle.set(this.containerNode)");

		domStyle.set(this.containerNode, {
			width: "auto",
			height: "auto"
		});
	}

	var bb = domGeometry.position(this.domNode);
	////console.log("plugins.dojox.widget.Dialog._size    bb");
	//console.dir({bb:bb});
	
	// Get viewport size but then reduce it by a bit; Dialog should always have some space around it
	// to indicate that it's a popup.  This will also compensate for possible scrollbars on viewport.
	var viewport = winUtils.getBox(this.ownerDocument);
	viewport.w *= this.maxRatio;
	viewport.h *= this.maxRatio;
	//console.log("plugins.dojox.widget.Dialog._size    viewport.w: " + viewport.w);
	//console.log("plugins.dojox.widget.Dialog._size    viewport.h: " + viewport.h);
	//console.log("plugins.dojox.widget.Dialog._size    bb.w: " + bb.w);
	//console.log("plugins.dojox.widget.Dialog._size    bb.h: " + bb.h);

	if(bb.w >= viewport.w || bb.h >= viewport.h){
		//console.log("plugins.dojox.widget.Dialog._size    dialog is LARGER than viewport. REDUCING dialog contents size");
		
		// Reduce size of dialog contents so that dialog fits in viewport
		var containerSize = domGeometry.position(this.containerNode),
			w = Math.min(bb.w, viewport.w) - (bb.w - containerSize.w),
			h = Math.min(bb.h, viewport.h) - (bb.h - containerSize.h);

		//console.log("plugins.dojox.widget.Dialog._size    w: " + w);
		//console.log("plugins.dojox.widget.Dialog._size    h: " + h);

		if(this._singleChild && this._singleChild.resize){
			//console.log("plugins.dojox.widget.Dialog._size    INSIDE this.singlechild && this._singlechild.resize");

			if(typeof this._singleChildOriginalStyle == "undefined"){
				this._singleChildOriginalStyle = this._singleChild.domNode.style.cssText;
			}
			this._singleChild.resize({w: w, h: h});
		}else{
			//console.log("plugins.dojox.widget.Dialog._size    DOING domStyle.set(this.containerNode, ...");

			domStyle.set(this.containerNode, {
				width: w + "px",
				height: h + "px",
				overflow: "auto",
				position: "relative"    // workaround IE bug moving scrollbar or dragging dialog
			});
		}
	}else{
		//console.log("plugins.dojox.widget.Dialog._size    dialog is smaller than viewport");

		if(this._singleChild && this._singleChild.resize){
			//console.log("plugins.dojox.widget.Dialog._size    DOING this._singleChild.resize()");
			this._singleChild.resize();
		}
	}
},

_position: function(){

	//console.log("plugins.dojox.widget.Dialog._position    caller: " + this._position.caller.nom);
	//console.log("plugins.dojox.widget.Dialog._position    DEBUG RETURN");
	return;

	// summary:
	//		Position the dialog in the viewport.  If no relative offset
	//		in the viewport has been determined (by dragging, for instance),
	//		center the dialog.  Otherwise, use the Dialog's stored relative offset,
	//		adjusted by the viewport's scroll.
	if(!domClass.contains(this.ownerDocumentBody, "dojoMove")){    // don't do anything if called during auto-scroll

		//console.log("plugins.dojox.widget.Dialog._position    DOING MOVE");

		var node = this.domNode,
			viewport = winUtils.getBox(this.ownerDocument),
			p = this._relativePosition,
			bb = p ? null : domGeometry.position(node),
			l = Math.floor(viewport.l + (p ? p.x : (viewport.w - bb.w) / 2)),
			t = Math.floor(viewport.t + (p ? p.y : (viewport.h - bb.h) / 2))
		;

			
		//console.log("Dialog._position    node: " + node);
		//console.dir({node:node});
		//console.log("Dialog._position    this._relativePosition: " + this._relativePosition);
		//console.dir({this_relativePosition:this._relativePosition});
		//console.log("Dialog._position    viewport.t: " + viewport.t);
		//console.log("Dialog._position    viewport.l: " + viewport.l);
		//console.log("Dialog._position    bb: " + bb);
		//console.dir({bb:bb});
		//
		//console.log("Dialog._position    DOING domStyle.set(node), { left: " + l + "px" + ", top: " + t + "px");
		
		domStyle.set(node, {
			left: l + "px",
			top: t + "px"
		});

		//console.log("Dialog._position    l: " + l);
		//console.log("Dialog._position    t: " + t);
	}
},

onMouseUp: function(e){
	console.log("Dialog.onMouseUp    e:");
	console.dir({e:e});

	// summary:
	//		event processor for onmouseup, used only for delayed drags
	// e: Event
	//		mouse event
	for(var i = 0; i < 2; ++i){
		this.events.pop().remove();
	}
	e.stopPropagation();
	e.preventDefault();
},
resize: function(){

	//console.log("plugins.dojox.widget.Dialog.resize    caller: " + this.resize.caller.nom);
	//console.log("plugins.dojox.widget.Dialog.resize    DEBUG RETURN");
	return;

	console.log("plugins.dojox.widget.Dialog.resize    DOING if (this.domNode.style.display != 'none')"); 
	
	// summary:
	//		Called when viewport scrolled or size changed.  Adjust Dialog as necessary to keep it visible.
	// tags:
	//		private
	if(this.domNode.style.display != "none"){
		this._size();
		if(!has("touch")){
			
			return;
			
			// If the user has scrolled the display then reposition the Dialog.  But don't do it for touch
			// devices, because it will counteract when a keyboard pops up and then the browser auto-scrolls
			// the focused node into view.
			this._position();
		}
	}
}

});

});
