dojo.provide("plugins.dojox.Timer");

/* 

	1. REPEATEDLY POLL WHILE WAITING FOR EVENTS TO FINISH
	
	2. CARRY OUT A SPECIFIED ACTION ON COMPLETION
	
	3. PASS ARGUMENTS TO poll AND onEnd CALLBACKS BY
	
		STORING THEM IN Timer OBJECT. NOTE: THIS MEANS
		
		THAT CARE MUST BE TAKEN TO AVOID OVERRIDING
		
		ANY OF Timer's METHODS OR SLOTS.
	
*/

// TIMER
dojo.require("dojox.timing");

dojo.declare( "plugins.dojox.Timer", null, {

// TIMING INTERVAL IN 1000ths OF A SECOND
interval : 5000,

// TRUE WHILE POLLING
polling : false,

// END POLLING WHEN TRUE
completed : false,

// CALLBACK TO BE FIRED BEFORE STARTING TIMER
onStart : null,

// CALLBACK TO BE FIRED AT EACH onTick EVENT
poll: null,

// CALLBACK TO BE FIRED WHEN POLLING HAS ENDED
onEnd : null,

////}}}}}

constructor : function(args) {
	console.log("plugins.dojox.Timer.constructor     plugins.dojox.Timer.constructor");			
	if ( args == null )	return;
	
	if (args.interval != null)	this.interval = args.interval;
	this.poll 		= args.poll || function () {
		console.log("plugins.dojox.Timer.constructor    poll function is empty");
	}
	this.onStart 		= args.onStart || function () {
		console.log("plugins.dojox.Timer.constructor    onStart function is empty");
	}
	this.onEnd 		= args.onEnd || function () {
		console.log("plugins.dojox.Timer.constructor    onEnd function is empty");
	}

	// INSTANTIATE NEW TIMER
	this.setTimer();
},

setTimer : function () {
	console.log("plugins.dojox.Timer.setTimer    this.timer: " + this.timer);	
	if ( this.timer != null ) {
		return;
	}
	this.timer = new dojox.timing.Timer;
	this.setInterval(this.interval);
},

setInterval : function (interval) {
	console.log("plugins.dojox.Timer.setInterval    interval: " + interval);
	if ( interval == null )	return;

	console.log("plugins.dojox.Timer.setInterval    this.timer: " + this.timer);
	console.dir({timer:this.timer});
	console.log("plugins.dojox.Timer.setInterval    Doing this.timer.setInterval(" + interval + ")");
	this.timer.setInterval(interval);
	console.log("plugins.dojox.Timer.setInterval    AFTER");
},

setOnEnd : function (onEnd) {
	console.log("OnEnd.setOnEnd    onEnd: " + onEnd);
	if ( onEnd == null ) this.onEnd = function () {
		console.log("plugins.dojox.Timer.setPoll    Inside onEnd");
	}
	else {
		this.onEnd = onEnd;
	}
},

setPoll : function (poll) {
	console.log("plugins.dojox.Timer.setInterval    poll: " + poll);
	var thisObject = this;	
	var onEnd = this.onEnd || function () {
		console.log("plugins.dojox.Timer.setPoll    Inside onEnd");
	}

	this.timer.onTick = function() {
		console.log("plugins.dojox.Timer.setTimer    onTick: " + new Date().toTimeString());

		// STOP POLLING WHEN this.completed == true
		//console.log("plugins.dojox.Timer.setTimer     thisObject.completed: " + dojo.toJson(thisObject.completed));
		if ( thisObject.completed == true )
		{
			console.log("plugins.dojox.Timer.setTimer     Stopping timer because thisObject.completed: " + thisObject.completed);
			thisObject.stop();
			thisObject.onEnd(thisObject);
			return;
		}

        setTimeout(function() {
            try {
                console.log("plugins.dojox.Timer.setTimer     Doing thisObject.poll(thisObject)");
				thisObject.completed = thisObject.poll(thisObject);		
            } catch(error) {
                console.log("plugins.dojox.Timer.setTimer     ERROR doing thisObject.poll(thisObject):" + dojo.toJson(error));
            }
        }, 100);

	};	//	timer.onTick
},

start : function () {
	//this.onStart(this);
	this.timer.start();	
	this.polling = true;
},

stop : function () {
	this.timer.stop();
	this.polling = false;
}


});


