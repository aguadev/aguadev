dojo.provide("plugins.menu.Menu");

/* SUMMARY:  A CONTEXT MENU THAT IS AWARE OF THE UNDERLYING CLICKED TARGET. 

  ... AND WHICH YOU CAN BIND TO MULTIPLE DIFFERENT TARGETS
*/

dojo.require("dijit.Menu");

dojo.declare("plugins.menu.Menu",
[ dijit.Menu ], {
	////}}
	
// SET TO FALSE TO DISABLE MENU OPEN
enabled : true,
	
_openMyself: function(args){

console.log("Menu._openMyself    plugins.menu.Menu._openMyself(args)");
	// summary:
	//		Internal function for opening myself when the user does a right-click or something similar.
	// args:
	//		This is an Object containing:
	//		* target:
	//			The node that is being clicked
	//		* iframe:
	//			If an <iframe> is being clicked, iframe points to that iframe
	//		* coords:
	//			Put menu at specified x/y position in viewport, or if iframe is
	//			specified, then relative to iframe.
	//
	//		_openMyself() formerly took the event object, and since various code references
	//		evt.target (after connecting to _openMyself()), using an Object for parameters
	//		(so that old code still works).


	// QUIT OPEN IF MENU IS NOT enabled
	if ( this.enabled == false )	return;

	// ADD THIS TO ENABLE IDENTIFICATION OF THE UNDERLYING TARGET
	// NODE WHEN THE MENU IS CLICKED
	this.currentTarget = args.target;

	// SET CURRENT TARGET CSS TO INDICATE ORIGIN OF MENU CLICK
	if ( this.currentTarget ) {
		console.log("plugins.menu.Menu._openMyself    Setting add class 'dojoDndItemOver' to this.currentTarget: " + this.currentTarget);
		console.dir({currentTarget:this.currentTarget});
		dojo.addClass(this.currentTarget, 'dojoDndItemOver');
		
		var classes = dojo.attr(this.currentTarget, 'class');
		console.log("plugins.menu.Menu._openMyself    this.currentTarget classes: " + classes)
	}

	var target = args.target,
		iframe = args.iframe,
		coords = args.coords;

	// Get coordinates to open menu, either at specified (mouse) position or (if triggered via keyboard)
	// then near the node the menu is assigned to.
	if(coords){
		if(iframe){
			// Specified coordinates are on <body> node of an <iframe>, convert to match main document
			var od = target.ownerDocument,
				ifc = dojo.position(iframe, true),
				win = this._iframeContentWindow(iframe),
				scroll = dojo.withGlobal(win, "_docScroll", dojo);

			var cs = dojo.getComputedStyle(iframe),
				tp = dojo._toPixelValue,
				left = (dojo.isIE && dojo.isQuirks ? 0 : tp(iframe, cs.paddingLeft)) + (dojo.isIE && dojo.isQuirks ? tp(iframe, cs.borderLeftWidth) : 0),
				top = (dojo.isIE && dojo.isQuirks ? 0 : tp(iframe, cs.paddingTop)) + (dojo.isIE && dojo.isQuirks ? tp(iframe, cs.borderTopWidth) : 0);

			coords.x += ifc.x + left - scroll.x;
			coords.y += ifc.y + top - scroll.y;
		}
	}else{
		coords = dojo.position(target, true);
		coords.x += 10;
		coords.y += 10;
	}

	var self=this;
	var savedFocus = dijit.getFocus(this);
	function closeAndRestoreFocus(){
		// user has clicked on a menu or popup
		if(self.refocus){
			dijit.focus(savedFocus);
		}
		dijit.popup.close(self);
	}
	dijit.popup.open({
		popup: this,
		x: coords.x,
		y: coords.y,
		onExecute: closeAndRestoreFocus,
		onCancel: closeAndRestoreFocus,
		orient: this.isLeftToRight() ? 'L' : 'R'
	});
	this.focus();

	this._onBlur = function(){

		this.inherited('_onBlur', arguments);
		// Usually the parent closes the child widget but if this is a context
		// menu then there is no parent
		dijit.popup.close(this);
		// don't try to restore focus; user has clicked another part of the screen
		// and set focus there
	};
}


});
