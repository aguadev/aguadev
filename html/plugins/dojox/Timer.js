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
interval : 3000,

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

// ATTENUATION VARIABLES
attenuate: false,
currentInterval : false,
stepInterval: 2000,
maxInterval: 10000,
tick: 1,

////}}}}}

constructor : function(args) {
	console.log("plugins.dojox.Timer.constructor     plugins.dojox.Timer.constructor");			
	if ( args == null )	return;
	
	if (args.interval != null)	this.interval = args.interval;
	if (args.attenuate != null)	this.attenuate = args.attenuate;
	if (args.stepInterval != null)	this.stepInterval = args.stepInterval;
	if (args.maxInterval != null)	this.maxInterval = args.maxInterval;

	this.poll 		= args.poll || function () {
		console.log("plugins.dojox.Timer.constructor    poll function is empty");
	}
	this.onStart 		= args.onStart || function () {
		console.log("plugins.dojox.Timer.constructor    onStart function is empty");
	}
	this.onEnd 		= args.onEnd || function () {
		console.log("plugins.dojox.Timer.constructor    onEnd function is empty");
	}

	this.currentInterval = this.interval;

	// INSTANTIATE NEW TIMER
	this.setTimer();
},

setTimer : function () {
	if ( this.timer != null )	return;
	
	if ( this.checkParent && ! this.parentWidget ) {
		console.log("plugins.dojox.Timer.setTimer    no parentWidget. Doing this.destroy()");
		this.destroy();
	}
	
	this.timer = new dojox.timing.Timer;
	this.setInterval(this.interval);
	
	var thisObject = this;
	this.timer.onTick = function() {
		console.log("plugins.dojox.Timer.setTimer     ONTICK this.timer.interval: " + this.interval);

		// STOP POLLING WHEN this.completed == true
		if ( thisObject.completed == true )
		{
			console.log("plugins.dojox.Timer.setTimer     Stopping timer because thisObject.completed: " + thisObject.completed);
			thisObject.stop();
			return;
		}

        setTimeout(function() {
            try {
				thisObject.completed = thisObject.poll(thisObject);		
				console.log("plugins.dojox.Timer.setTimer     Returned thisObject.completed: " + thisObject.completed);

				// STOP POLLING WHEN this.completed == true
				if ( thisObject.completed == true ) {
					console.log("plugins.dojox.Timer.setTimer     Stopping timer because thisObject.completed: " + thisObject.completed);
					thisObject.stop();
					return;
				}
				
            } catch(error) {
                console.log("plugins.dojox.Timer.setTimer     ERROR doing thisObject.poll(thisObject):" + dojo.toJson(error));
            }

	
			// INCREMENT TIMER DELAY IF attenuate IS TRUE
			if ( thisObject.attenuate == true && thisObject.tick != 1 ) {
				//thisObject.timer.stop();
				thisObject.currentInterval += thisObject.stepInterval;
				if ( thisObject.currentInterval > thisObject.maxInterval )
					thisObject.currentInterval = thisObject.maxInterval;
		
				console.log("plugins.dojox.Timer.setPoll    new thisObject.currentInterval: " + thisObject.currentInterval);
		
				thisObject.timer.setInterval(thisObject.currentInterval);
				//thisObject.timer.start();
			}
			else {
				thisObject.tick++;
			}

        }, 100);

	};	//	timer.onTick

},

setInterval : function (interval) {
	if ( interval == null )	return;
	this.timer.setInterval(interval);
},

setOnEnd : function (onEnd) {
	this.onEnd 	= onEnd || function () {
		console.log("plugins.dojox.Timer.setOnEnd    onEnd function is empty");
	}
},

setPoll : function (poll) {
	console.log("plugins.dojox.Timer.setPoll    poll: " + poll);
	this.poll 	= poll || function () {
		console.log("plugins.dojox.Timer.setPoll    poll function is empty");
	}
},

start : function () {
	console.log("plugins.dojox.Timer.start()");
	this.completed = false;
	this.onStart(this);
	this.timer.start();	
	this.polling = true;
},

stop : function () {
	console.log("plugins.dojox.Timer.stop()");
	this.timer.stop();
	this.polling = false;
	console.log("plugins.dojox.Timer.stop    this.polling: " + this.polling);
	
	this.onEnd(this);
}


});


