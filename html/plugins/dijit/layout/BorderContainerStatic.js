dojo.provide("plugins.dijit.layout.BorderContainerStatic");

dojo.require("dijit.layout.BorderContainer");
dojo.require("dojo.cookie");

dojo.declare("plugins.dijit.layout.BorderContainerStatic",
//	[dijit._Widget, dijit._Container, dijit._Contained],
	[ dijit.layout.BorderContainer ],
{


	resize: function(newSize, currentSize){

		this.inherited(arguments);

	},

	layout : function(changedRegion, changedChild, type){
	},

	_layoutChildren : function(/*String?*/changedRegion, changedChild, type){
	}

//
//	startup: function(){
//	    //console.log("dijit.layout.BorderContainerStatic.startup	dijit.layout.BorderContainerStatic.startup()");
//return;
//
//		this.inherited(arguments);
//
//		//this.resize();
//
//		dojo.connect(window, "onresize", this, "resize");
//
//	},
//
//

//	resize: function(newSize, currentSize){
//	    //console.log("plugins.dijit.layout.BorderContainerStatic.resize	plugins.dijit.layout.BorderContainerStatic.resize(newSize, currentSize)");
//		// resetting potential padding to 0px to provide support for 100% width/height + padding
//		// TODO: this hack doesn't respect the box model and is a temporary fix
//		//if (!this.cs || !this.pe){
//
//		    //console.log("plugins.dijit.layout.BorderContainerStatic.resize	!this.cs || !this.pe");
//
//			var node = this.domNode;
//			this.cs = dojo.getComputedStyle(node);
//			this.pe = dojo._getPadExtents(node, this.cs);
//			this.pe.r = dojo._toPixelValue(node, this.cs.paddingRight);
//			this.pe.b = dojo._toPixelValue(node, this.cs.paddingBottom);
//
//			dojo.style(node, "padding", "0px");
//		//}
//
//		this.inherited(arguments);
//	},
//
//
//	layout : function(changedRegion, changedChild, type){
//
//		//console.log("BorderContainerStatic.layout    plugins.dijit.layout.BorderContainerStatic.layout(changedRegion, changedChild, type)");
//		//console.log("BorderContainerStatic.layout    changedRegion: " + changedRegion);
//		//console.log("BorderContainerStatic.layout    changedChild: " + changedChild);
//		if ( changedChild && changedChild.expand )
//		{
//			//console.log("BorderContainerStatic.layout    changedChild.expand: " + changedChild.expand);
//		}
//		//console.log("BorderContainerStatic.layout    type: " + type);
//
//		for(var region in this._splitters){ this._computeSplitterThickness(region); }
//		this._layoutChildren(changedRegion, changedChild, type);
//	},
//
//
//
//	// type argument is "hide" or "show"
//	_layoutChildren : function(/*String?*/changedRegion, changedChild, type){
//
//		//console.log("BorderContainerStatic._layoutChildren    plugins.dijit.layout.BorderContainerStatic._layoutChildren(changedRegion, changedChild, type)");
//		//console.log("BorderContainerStatic._layoutChildren    DOING: " + type + " " + changedRegion);
//
//		if ( changedChild != null )
//		{
//			////console.log("BorderContainerStatic._layoutChildren    dojo.marginBox(changedChild.domNode).w: " + dojo.marginBox(changedChild.domNode).w);
//			//console.log("BorderContainerStatic._layoutChildren    changedChild.width: " + changedChild.width);
//
//			// ADDED type ARGUMENT: "hide" OR "show"
//			if ( type == "hide" )
//			{
//				if ( /left|right|center/.test(changedRegion) && changedChild.minWidth )
//				{
//					//console.log("BorderContainerStatic._layoutChildren    Setting changedChild width: " + changedChild.minWidth + "px" );
//					dojo.style(changedChild, "width", changedChild.minWidth + "px");
//					dojo.marginBox(changedChild).w = changedChild.minWidth;
//
//
//					changedChild.style.width = changedChild.minWidth + "px";
//				}
//				else if ( /top|bottom/.test(changedRegion) && changedChild.minHeight )
//				{
//					changedChild.style.height = changedChild.minHeight + "px";
//				}
//			}
//
//			else if ( type == "show" )
//			{
//				if ( /left|right|center/.test(changedRegion) && changedChild.width )
//				{
//				//console.log("BorderContainerStatic._layoutChildren    Setting changedChild width: " + changedChild.width + "px" );
//					changedChild.style.width = changedChild.width + "px";
//				}
//				else if ( /top|bottom/.test(changedRegion) && changedChild.height )
//				{
//					//changedChild.style.height = changedChild.height + "px";
//					dojo.style(changedChild, "width", changedChild.width + "px");
//					dojo.marginBox(changedChild).w = changedChild.width;
//				}
//			}
//
//			//console.log("BorderContainerStatic._layoutChildren    changedChild.style.width: " + changedChild.style.width);
//
//		}
//		
//		
//		
//		//console.log("BorderContainerStatic._layoutChildren    this._center: " + this._center);
//		//console.log("BorderContainerStatic._layoutChildren    this._center.style: " + this._center.style);
//
//		var sidebarLayout = (this.design == "sidebar");
//		var topHeight = 0, bottomHeight = 0, leftWidth = 0, centerWidth = 0, rightWidth = 0;
//		var topStyle = {}, leftStyle = {}, rightStyle = {}, bottomStyle = {},
//			centerStyle = (this._center && this._center.style) || {};
//
//		var changedSide = /left|right|center/.test(changedRegion);
//
//		var layoutSides = !changedRegion || (!changedSide && !sidebarLayout);
//		var layoutTopBottom = !changedRegion || (changedSide && sidebarLayout);
//
//		layoutSides = !changedRegion;
//
//		//console.log("BorderContainerStatic._layoutChildren    layoutSides: " + layoutSides);
//
//		// Ask browser for width/height of side panes.
//		// Would be nice to cache this but height can change according to width
//		// (because words wrap around).  I don't think width will ever change though
//		// (except when the user drags a splitter). 
//		if(this._top){
//			topStyle = layoutTopBottom && this._top.style;
//			topHeight = dojo.marginBox(this._top).h;
//		}
//		if(this._left){
//			leftStyle = layoutSides && this._left.style;
//			leftWidth = dojo.marginBox(this._left).w;
//		}
//		if(this._center){
//			//centerStyle = layoutSides && this._center.style;
//			centerWidth = dojo.marginBox(this._center).w;
//		}
//		if(this._right){
//			rightStyle = layoutSides && this._right.style;
//			rightWidth = dojo.marginBox(this._right).w;
//		}
//		if(this._bottom){
//			bottomStyle = layoutTopBottom && this._bottom.style;
//			bottomHeight = dojo.marginBox(this._bottom).h;
//		}
//
//
//		//console.log("BorderContainerStatic._layoutChildren    leftWidth: " + leftWidth);
//		//console.log("BorderContainerStatic._layoutChildren    centerWidth: " + centerWidth);
//		//console.log("BorderContainerStatic._layoutChildren    rightWidth: " + rightWidth);
//
//
//		if ( centerStyle )
//		{
//			//console.log("BorderContainerStatic._layoutChildren    centerStyle.left: " + dojo.toJson(centerStyle.left));
//		}
//
//
//		var splitters = this._splitters;
//		
//		var topSplitter = splitters.top, bottomSplitter = splitters.bottom,
//			leftSplitter = splitters.left, rightSplitter = splitters.right,
//			centerSplitter = splitters.center;
//
//		var splitterThickness = this._splitterThickness;
//		var topSplitterThickness = splitterThickness.top || 0,
//			leftSplitterThickness = splitterThickness.left || 0,
//			rightSplitterThickness = splitterThickness.right || 0,
//			bottomSplitterThickness = splitterThickness.bottom || 0,
//			centerSplitterThickness = splitterThickness.center || 0;
//
//		// Check for race condition where CSS hasn't finished loading, so
//		// the splitter width == the workflowport width (#5824)
//		if(leftSplitterThickness > 50 || rightSplitterThickness > 50){
//			setTimeout(dojo.hitch(this, function(){
//				// Results are invalid.  Clear them out.
//				this._splitterThickness = {};
//
//				for(var region in this._splitters){
//					this._computeSplitterThickness(region);
//				}
//				this._layoutChildren();
//			}), 50);
//			return false;
//		}
//
//		var pe = this.pe;		
//
//		var containerWidth = this._borderBox.w - pe.l - pe.r;
//		
//		// USE WINDOW WIDTH IF BORDER BOX HAS NOT BEEN ACTIVATED BY RESIZE
//		if ( containerWidth <= 0 )
//		{
//			containerWidth = document.body.offsetWidth;
//		}
//		
//		//console.log("BorderContainerStatic._layoutChildren    containerWidth: " + containerWidth);
//		//console.log("BorderContainerStatic._layoutChildren    this.minWidth: " + this.minWidth);
//		//console.log("BorderContainerStatic._layoutChildren    this.containerNode.style: " + this.containerNode.style);
//		//console.log("BorderContainerStatic._layoutChildren    this.containerNode.style.width: " + this.containerNode.style.width);
//		
//		//console.log("BorderContainerStatic._layoutChildren    window.innerWidth: " + window.innerWidth);
//		//console.log("BorderContainerStatic._layoutChildren    window.innerHeight: " + window.innerHeight);
//
//		//console.log("BorderContainerStatic._layoutChildren    document.body.offsetWidth: " + document.body.offsetWidth);
//		//console.log("BorderContainerStatic._layoutChildren    document.body.offsetHeight: " + document.body.offsetHeight);
//
//
//		
//		// FOR ANY CHANGES OF THE LEFT OR MIDDLE PANES,
//		// THE RIGHT PANE ABSORBS THE DIFFERENCE IN WIDTH
//		var middleWidth;
//		if ( changedChild != null )
//		{
//			if ( this._center == changedChild.domNode )
//			{
//				//console.log("BorderContainerStatic._layoutChildren    CENTER WIDGET");
//	
//				var leftPane = dijit.byNode(this._left);
//				var centerPane = dijit.byNode(this._center);
//				var rightPane = dijit.byNode(this._right);
//
//				// BIAS LEFT PANE FIRST 
//				if ( leftPane.expand )
//				{
//					//console.log("BorderContainerStatic._layoutChildren    leftPane.expand: " + leftPane.expand);
//
//					middleWidth = centerWidth;
//					leftWidth = containerWidth - (rightWidth  + rightSplitterThickness + centerWidth + centerSplitterThickness);
//				}
//				else if ( rightPane.expand )
//				{
//					//console.log("BorderContainerStatic._layoutChildren    changedChild.expand: " + rightPane.expand);
//					middleWidth = centerWidth;
//					rightWidth = containerWidth - (leftWidth  + leftSplitterThickness + centerWidth + centerSplitterThickness);
//				}
//				else
//				{
//					//console.log("BorderContainerStatic._layoutChildren    NEITHER leftPane.expand NOR rightPane.expand ARE TRUE. DEFAULT = expand RIGHT PANE.");
//					middleWidth = centerWidth;
//					rightWidth = containerWidth - (leftWidth  + leftSplitterThickness + centerWidth + centerSplitterThickness);
//				}
//		
//				if ( type == "hide" )
//				{
//					dojo.removeClass(this._right, "dojoxExpandoClosed");
//					dojo.style(dijit.byNode(this._right).cwrapper, "visibility", "visible");
//					dojo.style(dijit.byNode(this._right).cwrapper, "opacity", "1");
//					dijit.byNode(this._right)._showing = true; 
//
//				}
//
//				// ADJUST LEFT WIDTH DUE TO GROWTH
//				if ( dojo.hasClass(this._left, "dojoxExpandoClosed") )
//				{
//					leftWidth = leftWidth - 2;
//				}
//			}
//			else if ( this._right == changedChild.domNode )
//			{
//				//console.log("BorderContainerStatic._layoutChildren    RIGHT WIDGET ");
//				middleWidth = containerWidth - (leftWidth  + leftSplitterThickness + rightWidth + rightSplitterThickness);
//				
//				if ( type == "hide" )
//				{
//					dojo.removeClass(this._center, "dojoxExpandoClosed");
//					dojo.style(dijit.byNode(this._center).cwrapper, "visibility", "visible");
//					dojo.style(dijit.byNode(this._center).cwrapper, "opacity", "1");
//					dijit.byNode(this._center)._showing = true; 
//				}
//
//				// ADJUST LEFT WIDTH DUE TO GROWTH
//				if ( dojo.hasClass(this._left, "dojoxExpandoClosed") )
//				{
//					leftWidth = leftWidth - 2;
//				}
//			}
//			else
//			{
//				//console.log("BorderContainerStatic._layoutChildren    LEFT WIDGET");
//
//				// IF RIGHT PANE IS CLOSED, ADJUST THE MIDDLE PANE
//				if ( dojo.hasClass(this._right, "dojoxExpandoClosed") )
//				{
//					//console.log("BorderContainerStatic._layoutChildren    rightPane is closed");
//					middleWidth = containerWidth - (leftWidth  + leftSplitterThickness + rightWidth + rightSplitterThickness);
//
//					// ADJUST RIGHT WIDTH DUE TO GROWTH
//					rightWidth = rightWidth - 2;
//				}
//				else
//				{
//					middleWidth = centerWidth;
//					rightWidth = containerWidth - (leftWidth  + leftSplitterThickness + centerWidth + centerSplitterThickness);
//				}
//				
//
//				//if ( rightWidth < 1 )
//				//{
//				//	rightWidth = tempRightWidth;
//				//	middleWidth = containerWidth - (leftWidth  + leftSplitterThickness + rightWidth + rightSplitterThickness);
//				//}
//			}
//		}
//		else
//		{
//			middleWidth = containerWidth - (leftWidth  + leftSplitterThickness + rightWidth + rightSplitterThickness);
//			var centerPane = dijit.byNode(this._center);
//
//			// EXPAND MIDDLE PANE BY DEFAULT, UNLESS THE WIDTH IS GREATER
//			// THAN IT'S MAXWIDTH, IN WHICH CASE, EXPAND THE RIGHT PANE
//			if ( centerPane && centerPane.maxWidth )
//			{
//				//console.log("BorderContainerStatic._layoutChildren    centerPane.maxWidth: " + centerPane.maxWidth);
//				middleWidth = containerWidth - (leftWidth  + leftSplitterThickness + rightWidth + rightSplitterThickness);
//				if ( middleWidth > centerPane.maxWidth )
//				{
//					//console.log("BorderContainerStatic._layoutChildren    middleWidth > centerPane.maxWidth");
//					rightWidth += middleWidth - centerPane.maxWidth;
//					middleWidth = centerPane.maxWidth;
//					//console.log("BorderContainerStatic._layoutChildren    middleWidth: " + middleWidth);
//					//console.log("BorderContainerStatic._layoutChildren    rightWidth: " + rightWidth);
//
//				}
//				else if ( centerPane.minWidth )
//				{
//					var minWidth = centerPane.minWidth;
//					if ( middleWidth < minWidth )
//					{
//						//console.log("BorderContainerStatic._layoutChildren    middleWidth < minWidth");
//						middleWidth = minWidth;
//						rightWidth = containerWidth - (leftWidth  + leftSplitterThickness + middleWidth + rightSplitterThickness);
//						//console.log("BorderContainerStatic._layoutChildren    middleWidth: " + middleWidth);
//						//console.log("BorderContainerStatic._layoutChildren    containerWidth: " + containerWidth);
//						//console.log("BorderContainerStatic._layoutChildren    leftWidth: " + leftWidth);
//						//console.log("BorderContainerStatic._layoutChildren    rightWidth: " + rightWidth);
//					}
//				}
//			}
//
//			// EXPAND MIDDLE PANE BY DEFAULT, UNLESS THE WIDTH IS GREATER
//			// THAN IT'S MAXWIDTH, IN WHICH CASE, EXPAND THE RIGHT PANE
//			if ( dijit.byNode(this._center) && dijit.byNode(this._center).maxWidth )
//			{
//				var maxWidth = dijit.byNode(this._center).maxWidth;
//				middleWidth = containerWidth - (leftWidth  + leftSplitterThickness + rightWidth + rightSplitterThickness);
//				if ( middleWidth > maxWidth )
//				{
//					rightWidth += middleWidth - maxWidth;
//					middleWidth = maxWidth;
//				}
//			}
//
//
//
//
//
//
//				//////else if ( centerPane.minWidth )
//				//////{
//				//////	var minWidth = centerPane.minWidth;
//				//////	if ( middleWidth < minWidth )
//				//////	{
//				//////		////console.log("BorderContainerStatic._layoutChildren    middleWidth < minWidth");
//				//////
//				//////		middleWidth = minWidth;
//				//////		rightWidth += middleWidth - maxWidth;
//				//////		rightWidth = containerWidth - (leftWidth  + leftSplitterThickness + middleWidth + rightSplitterThickness);
//				//////		////console.log("BorderContainerStatic._layoutChildren    middleWidth: " + middleWidth);
//				//////		////console.log("BorderContainerStatic._layoutChildren    rightWidth: " + rightWidth);
//				//////	}
//				//////}
//
//
//
//		}
//
//		//console.log("BorderContainerStatic._layoutChildren    AFTER leftWidth: " + leftWidth);
//		//console.log("BorderContainerStatic._layoutChildren    AFTER middleWidth: " + middleWidth);
//		//console.log("BorderContainerStatic._layoutChildren    AFTER rightWidth: " + rightWidth);
//
//		if ( centerStyle )
//		{
//			//console.log("BorderContainerStatic._layoutChildren    centerStyle.left: " + dojo.toJson(centerStyle.left));
//		}
//
//
//		var sidebarWidth = sidebarLayout ? middleWidth : containerWidth;
//
//
//		// New margin-box size of each pane
//		var dim = {
//			top:	{ w: sidebarWidth, h: topHeight },
//			bottom: { w: sidebarWidth, h: bottomHeight },
//			left:	{ w: leftWidth, h: sidebarHeight },
//			right:	{ w: rightWidth, h: sidebarHeight },
//			center:	{ h: middleHeight, w: middleWidth }
//		};
//
//		var splitterBounds = {
//			left: (sidebarLayout ? leftWidth + leftSplitterThickness: 0) + pe.l + "px",
//			center: (sidebarLayout ? centerWidth + centerSplitterThickness: 0) + pe.l + "px",
//			right: (sidebarLayout ? rightWidth + rightSplitterThickness: 0) + pe.r + "px"
//		};
//
//		if(topSplitter){
//			dojo.mixin(topSplitter.style, splitterBounds);
//			topSplitter.style.top = topHeight + pe.t + "px";
//		}
//
//		if(bottomSplitter){
//			dojo.mixin(bottomSplitter.style, splitterBounds);
//			bottomSplitter.style.bottom = bottomHeight + pe.b + "px";
//		}
//
//		splitterBounds = {
//			top: (sidebarLayout ? 0 : topHeight + topSplitterThickness) + pe.t + "px",
//			bottom: (sidebarLayout ? 0 : bottomHeight + bottomSplitterThickness) + pe.b + "px"
//		};
//
//		if(leftSplitter){
//			dojo.mixin(leftSplitter.style, splitterBounds);
//			leftSplitter.style.left = leftWidth + pe.l + "px";
//		}
//
//		if(centerSplitter){
//			dojo.mixin(centerSplitter.style, splitterBounds);
//			centerSplitter.style.center = centerWidth + pe.r +  "px";
//		}
//
//		if(rightSplitter){
//			dojo.mixin(rightSplitter.style, splitterBounds);
//			rightSplitter.style.right = rightWidth + pe.r +  "px";
//		}
//
//		dojo.mixin(centerStyle, {
//			top: pe.t + topHeight + topSplitterThickness + "px",
//			left: pe.l + leftWidth + leftSplitterThickness + "px",
//			center: pe.l + centerWidth + centerSplitterThickness + "px",
//			right: pe.r + rightWidth + rightSplitterThickness + "px",
//			bottom: pe.b + bottomHeight + bottomSplitterThickness + "px"
//		});
//
//		var bounds = {
//			top: sidebarLayout ? pe.t + "px" : centerStyle.top,
//			bottom: sidebarLayout ? pe.b + "px" : centerStyle.bottom
//		};
//		dojo.mixin(leftStyle, bounds);
//		dojo.mixin(rightStyle, bounds);
//		
//		
//		leftStyle.left = pe.l + "px";
//		rightStyle.right = pe.r + "px";
//		topStyle.top = pe.t + "px";
//		bottomStyle.bottom = pe.b + "px";
//		
//		if(sidebarLayout){
//			topStyle.left = bottomStyle.left = leftWidth + leftSplitterThickness + pe.l + "px";
//			topStyle.right = bottomStyle.right = rightWidth + rightSplitterThickness + pe.r + "px";
//		}
//		else
//		{
//			topStyle.left = bottomStyle.left = pe.l + "px";
//			topStyle.right = bottomStyle.right = pe.r + "px";
//		}
//
//		// More calculations about sizes of panes
//		var containerHeight = this._borderBox.h - pe.t - pe.b;
//		var middleHeight = containerHeight - ( topHeight + topSplitterThickness + bottomHeight + bottomSplitterThickness);
//		var sidebarHeight = sidebarLayout ? containerHeight : middleHeight;
//
//		// Nodes in IE don't respond to t/l/b/r, and
//		// TEXTAREA doesn't respond in any browser
//		var janky = dojo.isIE || dojo.some(this.getChildren(), function(child){
//			return child.domNode.tagName == "TEXTAREA" || child.domNode.tagName == "INPUT";
//		});
//
//
//		if(janky){
//			
//			// Set the size of the children the old fashioned way, by setting
//			// CSS width and height
//			var resizeWidget = function(widget, changes, result){
//				if(widget){
//					(widget.resize ? widget.resize(changes, result) : dojo.marginBox(widget.domNode, changes));
//				}
//			};
//
//			if(leftSplitter){ leftSplitter.style.height = sidebarHeight; }
//			if(rightSplitter){ rightSplitter.style.height = sidebarHeight; }
//
//			resizeWidget(this._leftWidget, {h: sidebarHeight}, dim.left);
//			resizeWidget(this._rightWidget, {h: sidebarHeight}, dim.right);
//
//			if(topSplitter){ topSplitter.style.width = sidebarWidth; }
//			if(bottomSplitter){ bottomSplitter.style.width = sidebarWidth; }
//			resizeWidget(this._topWidget, {w: sidebarWidth}, dim.top);
//			resizeWidget(this._bottomWidget, {w: sidebarWidth}, dim.bottom);
//
//			// CHANGED:
//			//resizeWidget(this._centerWidget, dim.center);
//			resizeWidget(this._centerWidget, {h: sidebarHeight}, dim.center);
//		}
//
//
//		else
//		{
//			// We've already sized the children by setting
//			// style.top/bottom/left/right...
//			// Now just need to call resize() on those children
//			// telling them their new size,
//			// so they can re-layout themselves
//
//			// Calculate which panes need a notification
//			var resizeList = {};
//			if(changedRegion){
//
//				//console.log("BorderContainerStatic._layoutChildren    changedRegion: " + changedRegion);
//				
//				resizeList[changedRegion] = resizeList.center = true;
//				if ( /left|right|center/.test(changedRegion) ){
//					resizeList.left = resizeList.right = true;
//				}
//				else if ( /top|bottom|center/.test(changedRegion) ){
//					resizeList.top = resizeList.bottom = true;
//				}
//			}
//
//			//console.log("BorderContainerStatic._layoutChildren    resizeList: " + dojo.toJson(resizeList));
//
//			dojo.forEach(this.getChildren(), function(child){
//				//console.log("BorderContainerStatic._layoutChildren    DOING resize on child: " + child.region);
//				//console.log("BorderContainerStatic._layoutChildren    dim[child.region]: " + dojo.toJson(dim[child.region]));
//
//				if(child.resize && (!changedRegion || child.region in resizeList)){
//					child.resize(null, dim[child.region]);
//				}
//			}, this);
//		}
//	}

});

