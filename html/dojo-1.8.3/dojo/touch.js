define(["./_base/kernel", "./aspect", "./dom", "./dom-class", "./_base/lang", "./on", "./has", "./mouse", "./domReady", "./_base/window"],
function(dojo, aspect, dom, domClass, lang, on, has, mouse, domReady, win){

	// module:
	//		dojo/touch

	var hasTouch = has("touch");

	var ios4 = has("ios") && has("ios") < 5;
	
	var msPointer = navigator.msPointerEnabled;

	// Click generation variables
	var clicksInited, clicked, clickTarget, clickX, clickY, clickDx, clickDy, clickTime;

	// Time of most recent touchstart, touchmove, or touchend event
	var lastTouch;

	function dualEvent(mouseType, touchType, msPointerType){
		// Returns synthetic event that listens for both the specified mouse event and specified touch event.
		// But ignore fake mouse events that were generated due to the user touching the screen.
		if(msPointer && msPointerType){
			// IE10+: MSPointer* events are designed to handle both mouse and touch in a uniform way,
			// so just use that regardless of hasTouch.
			return function(node, listener){
				return on(node, msPointerType, listener);
			}
		}else if(hasTouch){
			return function(node, listener){
				var handle1 = on(node, touchType, listener),
					handle2 = on(node, mouseType, function(evt){
						if(!lastTouch || (new Date()).getTime() > lastTouch + 1000){
							listener.call(this, evt);
						}
					});
				return {
					remove: function(){
						handle1.remove();
						handle2.remove();
					}
				};
			};
		}else{
			// Avoid creating listeners for touch events on performance sensitive older browsers like IE6
			return function(node, listener){
				return on(node, mouseType, listener);
			}
		}
	}

	function marked(/*DOMNode*/ node){
		// Test if a node or its ancestor has been marked with the dojoClick property to indicate special processing,
		do{
			if(node.dojoClick){ return node.dojoClick; }
		}while(node = node.parentNode);
	}
	
	function doClicks(e, moveType, endType){
		// summary:
		//		Setup touch listeners to generate synthetic clicks immediately (rather than waiting for the browser
		//		to generate clicks after the double-tap delay) and consistently (regardless of whether event.preventDefault()
		//		was called in an event listener. Synthetic clicks are generated only if a node or one of its ancestors has
		//		its dojoClick property set to truthy.
		
		clicked  = marked(e.target); // click threshold = true, number or x/y object
		if(clicked){
			
			clickTarget = e.target;
			clickX = e.touches ? e.touches[0].pageX : e.clientX;
			clickY = e.touches ? e.touches[0].pageY : e.clientY;
			clickDx = (typeof clicked == "object" ? clicked.x : (typeof clicked == "number" ? clicked : 0)) || 4;
			clickDy = (typeof clicked == "object" ? clicked.y : (typeof clicked == "number" ? clicked : 0)) || 4;

			// add move/end handlers only the first time a node with dojoClick is seen,
			// so we don't add too much overhead when dojoClick is never set.
			if(!clicksInited){
				clicksInited = true;

				win.doc.addEventListener(moveType, function(e){
					clicked = clicked &&
						e.target == clickTarget &&
						Math.abs((e.touches ? e.touches[0].pageX : e.clientX) - clickX) <= clickDx &&
						Math.abs((e.touches ? e.touches[0].pageY : e.clientY) - clickY) <= clickDy;
				}, true);

				win.doc.addEventListener(endType, function(e){
					if(clicked){
						clickTime = (new Date()).getTime();
						setTimeout(function(){
							on.emit(e.target, "click", {
								target: e.target,
								bubbles : true,
								cancelable : true,
								_dojo_click : true
							});
						});
					}
				}, true);

				function stopNativeEvents(type){
					win.doc.addEventListener(type, function(e){
						// Stop native events when we emitted our own click event.
						// The time test is for cases when we clicked on a marked widget like a menu item,
						// which caused the menu to disappear, and then (~300ms later) the browser sends a click
						// event which could be dispatched to a non-marked widget underneath the menu.
						// To avoid this we also stop all native events sent shortly after ours, similar to
						// what is done in dualEvent.
						// The INPUT.dijitOffScreen test is for offscreen inputs used in dijit/form/Button, on which
						// we call click() explicitly, we don't want to stop this event.
						if(!e._dojo_click &&
							(marked(e.target) ||
								((new Date()).getTime() <= clickTime + 1000 &&
									!(e.target.tagName == "INPUT" && domClass.contains(e.target, "dijitOffScreen"))))){
							e.stopImmediatePropagation();
							//e.preventDefault();	preventDefault() breaks <input> on android, keyboard doesn't popup
						}
					}, true);
				}

				stopNativeEvents("click");

				// We also stop mousedown/up since these would be sent well after with our "fast" click (300ms),
				// which can confuse some dijit widgets.
				stopNativeEvents("mousedown");
				stopNativeEvents("mouseup");
			}
		}
	}

	var dojotouchmove, nativeTouchMoveEvent, hoveredNode;

	if(hasTouch){
		if(msPointer){
			 // MSPointer (IE10+) already has support for over and out, so we just need to init click support
			domReady(function(){
				win.doc.addEventListener("MSPointerDown", function(evt){
					doClicks(evt, "MSPointerMove", "MSPointerUp");
				}, true);
			});		
		}else{
			domReady(function(){
				// Keep track of currently hovered node
				hoveredNode = win.body();	// currently hovered node

				win.doc.addEventListener("touchstart", function(evt){
					lastTouch = (new Date()).getTime();

					// Precede touchstart event with touch.over event.  DnD depends on this.
					// Use addEventListener(cb, true) to run cb before any touchstart handlers on node run,
					// and to ensure this code runs even if the listener on the node does event.stop().
					var oldNode = hoveredNode;
					hoveredNode = evt.target;
					on.emit(oldNode, "dojotouchout", {
						target: oldNode,
						relatedTarget: hoveredNode,
						bubbles: true
					});
					on.emit(hoveredNode, "dojotouchover", {
						target: hoveredNode,
						relatedTarget: oldNode,
						bubbles: true
					});
				
					doClicks(evt, "touchmove", "touchend"); // init click generation
				}, true);

				on(win.doc, "touchmove", function(evt){
					lastTouch = (new Date()).getTime();
					nativeTouchMoveEvent = evt;

					var newNode = win.doc.elementFromPoint(
						evt.pageX - (ios4 ? 0 : win.global.pageXOffset), // iOS 4 expects page coords
						evt.pageY - (ios4 ? 0 : win.global.pageYOffset)
					);

					if(newNode){
						// Fire synthetic touchover and touchout events on nodes since the browser won't do it natively.
						if(hoveredNode !== newNode){
							// touch out on the old node
							on.emit(hoveredNode, "dojotouchout", {
								target: hoveredNode,
								relatedTarget: newNode,
								bubbles: true
							});

							// touchover on the new node
							on.emit(newNode, "dojotouchover", {
								target: newNode,
								relatedTarget: hoveredNode,
								bubbles: true
							});

							hoveredNode = newNode;
						}

						// Emit synthetic "dojotouchmove" as a way of triggering listeners to synthetic dojotouchmove event
						// defined below.
						on.emit(newNode, "dojotouchmove", {
							target: newNode,
							bubbles: true
						});
					}
				});

				// Fire a dojotouchend event on the node where the finger was before it was removed from the screen.
				// This is different than the native touchend, which fires on the node where the drag started.
				on(win.doc, "touchend", function(evt){
					lastTouch = (new Date()).getTime();
					var node = win.doc.elementFromPoint(
						evt.pageX - (ios4 ? 0 : win.global.pageXOffset), // iOS 4 expects page coords
						evt.pageY - (ios4 ? 0 : win.global.pageYOffset)
					) || win.body(); // if out of the screen

					on.emit(node, "dojotouchend", lang.delegate(evt, {
						target: node,
						bubbles: true
					}));
				});
			});


			// Unlike a listener on "touchmove", on(node, dojotouchmove, listener) fires when the finger
			// drags over the specified node, regardless of which node the touch started on.
			// The listener is called with the native touchmove event object, so that evt.preventDefault() works,
			// but target is set to the node currently being dragged over, and stopPropagation() refers to the synthetic
			// event.
			dojotouchmove = function(node, listener){
				return on(node, "dojotouchmove", function(syntheticEvent){
					listener(lang.delegate(nativeTouchMoveEvent, {
						target: syntheticEvent.target,
						stopPropagation: function(){
							syntheticEvent.stopPropagation();
						}
					}));
				});
			};
		}
	}

	//device neutral events - touch.press|move|release|cancel/over/out
	var touch = {
		press: dualEvent("mousedown", "touchstart", "MSPointerDown"),
		move: dualEvent("mousemove", dojotouchmove, "MSPointerMove"),
		release: dualEvent("mouseup", "dojotouchend", "MSPointerUp"),
		cancel: dualEvent(mouse.leave, "touchcancel", hasTouch?"MSPointerCancel":null),
		over: dualEvent("mouseover", "dojotouchover", "MSPointerOver"),
		out: dualEvent("mouseout", "dojotouchout", "MSPointerOut"),
		enter: mouse._eventHandler(dualEvent("mouseover","dojotouchover", "MSPointerOver")),
		leave: mouse._eventHandler(dualEvent("mouseout", "dojotouchout", "MSPointerOut"))
	};

	/*=====
	touch = {
		// summary:
		//		This module provides unified touch event handlers by exporting
		//		press, move, release and cancel which can also run well on desktop.
		//		Based on http://dvcs.w3.org/hg/webevents/raw-file/tip/touchevents.html
		//		Also, if the dojoClick property is set to true on a DOM node, dojo/touch generates
		//		click events immediately for this node and its descendants, to avoid the
		//		delay before native browser click events, and regardless of whether evt.preventDefault()
		//		was called in a touch.press event listener.
		//
		// example:
		//		Used with dojo.on
		//		|	define(["dojo/on", "dojo/touch"], function(on, touch){
		//		|		on(node, touch.press, function(e){});
		//		|		on(node, touch.move, function(e){});
		//		|		on(node, touch.release, function(e){});
		//		|		on(node, touch.cancel, function(e){});
		// example:
		//		Used with touch.* directly
		//		|	touch.press(node, function(e){});
		//		|	touch.move(node, function(e){});
		//		|	touch.release(node, function(e){});
		//		|	touch.cancel(node, function(e){});
		// example:
		//		Have dojo/touch generate clicks without delay, with a default move threshold of 4 pixels
		//		|	node.dojoClick = true;
		// example:
		//		Have dojo/touch generate clicks without delay, with a move threshold of 10 pixels horizontally and vertically
		//		|	node.dojoClick = 10;
		// example:
		//		Have dojo/touch generate clicks without delay, with a move threshold of 50 pixels horizontally and 10 pixels vertically
		//		|	node.dojoClick = {x:50, y:5};
		

		press: function(node, listener){
			// summary:
			//		Register a listener to 'touchstart'|'mousedown' for the given node
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		},
		move: function(node, listener){
			// summary:
			//		Register a listener that fires when the mouse cursor or a finger is dragged over the given node.
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		},
		release: function(node, listener){
			// summary:
			//		Register a listener to releasing the mouse button while the cursor is over the given node
			//		(i.e. "mouseup") or for removing the finger from the screen while touching the given node.
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		},
		cancel: function(node, listener){
			// summary:
			//		Register a listener to 'touchcancel'|'mouseleave' for the given node
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		},
		over: function(node, listener){
			// summary:
			//		Register a listener to 'mouseover' or touch equivalent for the given node
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		},
		out: function(node, listener){
			// summary:
			//		Register a listener to 'mouseout' or touch equivalent for the given node
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		},
		enter: function(node, listener){
			// summary:
			//		Register a listener to mouse.enter or touch equivalent for the given node
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		},
		leave: function(node, listener){
			// summary:
			//		Register a listener to mouse.leave or touch equivalent for the given node
			// node: Dom
			//		Target node to listen to
			// listener: Function
			//		Callback function
			// returns:
			//		A handle which will be used to remove the listener by handle.remove()
		}
	};
	=====*/

	has("extend-dojo") && (dojo.touch = touch);

	return touch;
});
