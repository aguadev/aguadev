//dojo.provide("plugins.dojox.widget.Toaster");
//
//dojo.require("dojox.widget.Toaster");
//
//dojo.declare("plugins.dojox.widget.Toaster", [dojox.widget.Toaster], {

define("plugins/dojox/widget/Toaster", [
	"dojo/_base/declare",
	"dojox/widget/Toaster",
],

function (
	declare,
	Toaster
) {

/////}}}}}
return declare("plugins/dojox/widget/Toaster",
	[ Toaster ], {

// OVERRIDES
setContent: function(/*String|Function*/message, /*String*/messageType, /*int?*/duration){
	// CHANGED CALL TO _setContent - ADDED messageType ARGUMENT

	duration = duration||this.duration;
	// sync animations so there are no ghosted fades and such
	if(this.slideAnim){
		if(this.slideAnim.status() != "playing"){
			this.slideAnim.stop();
		}
		if(this.slideAnim.status() == "playing" || (this.fadeAnim && this.fadeAnim.status() == "playing")){
			setTimeout(dojo.hitch(this, function(){
				this.setContent(message, messageType, duration);
			}), 50);
			return;
		}
	}

	// determine type of content and apply appropriately
	for(var type in this.messageTypes){
		dojo.removeClass(this.containerNode, "dijitToaster" + this._capitalize(this.messageTypes[type]));
	}

	dojo.style(this.containerNode, "opacity", 1);

    // CHANGED HERE - ADDED messageType ARGUMENT
	this._setContent(message, messageType);

	dojo.addClass(this.containerNode, "dijitToaster" + this._capitalize(messageType || this.defaultType));

	// now do funky animation of widget appearing from
	// bottom right of page and up
	this.show();
	var nodeSize = dojo.marginBox(this.containerNode);
	this._cancelHideTimer();
	if(this.isVisible){
		this._placeClip();
		//update hide timer if no sticky message in stack
		if(!this._stickyMessage) {
			this._setHideTimer(duration);
		}
	}else{
		var style = this.containerNode.style;
		var pd = this.positionDirection;
		// sets up initial position of container node and slide-out direction
		if(pd.indexOf("-up") >= 0){
			style.left=0+"px";
			style.top=nodeSize.h + 10 + "px";
		}else if(pd.indexOf("-left") >= 0){
			style.left=nodeSize.w + 10 +"px";
			style.top=0+"px";
		}else if(pd.indexOf("-right") >= 0){
			style.left = 0 - nodeSize.w - 10 + "px";
			style.top = 0+"px";
		}else if(pd.indexOf("-down") >= 0){
			style.left = 0+"px";
			style.top = 0 - nodeSize.h - 10 + "px";
		}else{
			throw new Error(this.id + ".positionDirection is invalid: " + pd);
		}
		this.slideAnim = dojo.fx.slideTo({
			node: this.containerNode,
			top: 0, left: 0,
			duration: this.slideDuration});
		this.connect(this.slideAnim, "onEnd", function(nodes, anim){
				//we build the fadeAnim here so we dont have to duplicate it later
				// can't do a fadeHide because we're fading the
				// inner node rather than the clipping node
				this.fadeAnim = dojo.fadeOut({
					node: this.containerNode,
					duration: 1000});
				this.connect(this.fadeAnim, "onEnd", function(evt){
					this.isVisible = false;
					this.hide();
				});
				this._setHideTimer(duration);
				this.connect(this, 'onSelect', function(evt){
					this._cancelHideTimer();
					//force clear sticky message
					this._stickyMessage=false;
					this.fadeAnim.play();
				});

				this.isVisible = true;
			});
		this.slideAnim.play();
	}
},

_setContent: function(message, messageType){
	console.log("plugins.core.Common.Toaster._setContent    message: " + message);
	console.log("plugins.core.Common.Toaster._setContent    messageType: " + messageType);

	if(dojo.isFunction(message)){
		message(this);
		return;
	}
	if(message && this.isVisible){
		message = this.contentNode.innerHTML + this.separator + "<span class='" + messageType + "'>" + message + "</span>";
	}
    else {
        message = "<span class='" + messageType + "'>" + message + "</span>";
    }
	console.log("plugins.core.Common.Toaster._setContent    FINAL message: " + message);

	this.contentNode.innerHTML = message;
}

});

});
