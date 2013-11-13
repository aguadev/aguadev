dojo.provide("plugins.core.Updater");

// UPDATE SUBSCRIBING OBJECTS, E.G., IN RESPONSE TO INFORMATION
// CHANGES THAT AFFECT THE SUBSCRIBING OBJECTS
dojo.declare( "plugins.core.Updater",
    null,
{    
// HASH OF LOADED CSS FILES
loadedCssFiles : null,

updates : null,

constructor : function () {
	//////console.log("core.Updater.constructor    plugins.core.Updater.constructor()");
	this.startup();
},

startup : function () {
	this.updates = new Object;
},

/////}}}
subscribe : function (subscriber, subscription) {
	//console.log("core.Updater.subscribe    plugins.core.Updater.subscribe(subscriber, subscription)");
	//console.log("core.Updater.subscribe    subscriber: " + subscriber);
	//console.log("core.Updater.subscribe    subscription: " + subscription);

	// CHECK SUBSCRIBER IMPLEMENTS SUBSCRIPTION METHOD
	if ( subscriber[subscription] == null )
	{
		//console.error("core.Updater.subscribe    subscriber " + subscriber + " doesn't implement subscription method: " + subscription);
		return;
	}

	if ( this.updates[subscription] == null )
		this.updates[subscription] = new Array;
	
	for ( currentSubscriber in this.updates[subscription] )
	{
		if ( currentSubscriber == subscriber )
		{
			//console.log("core.Updater.subscribe    subscriber " + subscriber + " is already subscribed to subscription: " + subscription);
			return;	
		}
	}

	//console.log("core.Updater.subscribe    subscribers.length BEFORE subscribe: " + this.updates[subscription].length);
	this.updates[subscription].push(subscriber);
	//console.log("core.Updater.subscribe    subscribers.length AFTER subscribe: " + this.updates[subscription].length);
},
update : function (subscription, args) {
	console.log("core.Updater.update    subscription: " + subscription);
	console.log("core.Updater.update    args: ");
	console.dir(args);
	
	var subscribers = this.getSubscribers(subscription);
	console.log("core.Updater.update    subscribers: ");
	console.dir({subscribers:subscribers});
	for ( var i in subscribers ) {
		var subscriber = subscribers[i];
		console.log("core.Updater.update    [][][][][][] DOING subscription '" + subscription + "' - subscriber." + subscription + "()");
		console.dir({subscriber:subscriber});
		subscriber[subscription](args);
	}
},
getSubscribers : function (subscription) {
	return this.updates[subscription]
},
unsubscribe : function (subscriber, subscription) {
	////console.log("core.Updater.unsubscribe    plugins.core.Updater.unsubscribe(subscriber, subscription)");
	////console.log("core.Updater.unsubscribe    subscriber: " + subscriber);
	////console.log("core.Updater.unsubscribe    subscription: " + subscription);

	// CHECK SUBSCRIBER IMPLEMENTS SUBSCRIPTION METHOD
	if ( subscriber[subscription] == null )
	{
		////console.error("core.Updater.unsubscribe    subscriber " + subscriber + " doesn't implement subscription method: " + subscription);
		return;
	}

	if ( this.updates[subscription] == null )
		this.updates = new Array;
	
	////console.log("core.Updater.unsubscribe    subscribers.length BEFORE unsubscribe: " + updates[subscription].length);
	for ( var i = 0; i < this.updates[subscription].length; i++ )
	{
		if ( this.updates[subscription][i] == subscriber )
		{
			////console.log("core.Updater.unsubscribe    Removing subscriber " + subscriber);
			this.updates[subscription].splice(i, 1);
			break;	
		}
	}
	////console.log("core.Updater.unsubscribe    subscribers.length AFTER unsubscribe: " + updates[subscription].length);
},
removeSubscriptions : function (subscriber) {
	console.log("core.Updater.removeSubscriptions    subscriber: ");
	console.dir({subscriber:subscriber});

	console.log("core.Updater.removeSubscriptions    this.updates: ");
	console.dir({this_updates:this.updates});
	console.log("core.Updater.removeSubscriptions    this.updates.length: " + this.updates.length);
    
    for ( var key in this.updates ) {
    	console.log("core.Updater.removeSubscriptions    key: " + key);
    	console.log("core.Updater.removeSubscriptions    this.updates[key]: " + this.updates[key]);
    	console.dir({this_updates_key:this.updates[key]});
    	
    	for ( var j = 0; j < this.updates[key].length; j++ ) {
    	    var currentSubscriber = this.updates[key][j];
        	console.log("core.Updater.removeSubscriptions    currentSubscriber: ");
        	console.dir({currentSubscriber:currentSubscriber});
    	    
    	    if ( currentSubscriber == subscriber ) {
            	console.log("core.Updater.removeSubscriptions    MATCHED. Splicing");
            	this.updates[key].splice(j, 1);
    	        break;
    	    }
    	}
        
    }

    
}

});

