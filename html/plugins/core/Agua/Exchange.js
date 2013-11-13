//dojo.provide("plugins.core.Agua.Exchange");
//
///* SUMMARY: THIS CLASS IS INHERITED BY Agua.js AND CONTAINS 
//	
//	FEATURE METHODS  
//*/
//dojo.declare( "plugins.core.Agua.Exchange",	[  ], {
//
///////}}}

/* Listen and respond to socket.IO messages */


define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dijit/registry",
	"dojo/when"
],
	   
function (
	declare,
	arrayUtil,
	JSON,
	on,
	registry,
	when
) {

////}}}}}

return declare("plugins/core/Agua/Exchange", [], {

////}}}}}

lastMessage : null,

// EXCHANGE
setExchange : function (Exchange) {
	console.log("Agua.Exchange.setExchange    Exchange:");
	console.dir({Exchange:Exchange});

	// SET TOKEN
	this.setToken();

	// INSTANTIATE EXCHANGE...
	var promise = when(this.exchange = new Exchange({}));
	console.log(".......................... Agua.setExchange    this.exchange:");
	console.dir({this_exchange:this.exchange});

	//// ... THEN CONNECT
	//promise.then(this.exchange.connect());

	//// SET onMessage LISTENER
	var thisObject = this;
	this.exchange.onMessage = function (json) {
		console.log("Agua.Exchange.setExchange    this.exchange.onMessage FIRED    json:");
		console.dir({json:json});
		var data = JSON.parse(json);
		
		thisObject.onMessage(data);
	};
	
	//try {
	//	this.exchange.connect();
	//} catch(e) {
	//	console.log("Agua.Exchange.setExchange    *** CAN'T CONNECT TO SOCKET ***");;
	//}
	
	// CONNECT
	var thisObject = this;
	setTimeout(function(){
		thisObject.exchange.connect();
	},
	1000);	

	return this.exchange;
},
setToken : function () {
	if ( this.token ) {
		console.log("Agua.Exchange.setToken    USING PRESET TOKEN this.token: " + this.token);
		return;
	}

	this.token = this.randomString(16, 'aA#');
	console.log("Agua.Exchange.setToken    this.token: " + this.token);
},
getTaskId : function () {
	return this.randomString(16, 'aA');
},
randomString : function (length, chars) {
    var mask = '';
    if (chars.indexOf('a') > -1) mask += 'abcdefghijklmnopqrstuvwxyz';
    if (chars.indexOf('A') > -1) mask += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (chars.indexOf('#') > -1) mask += '0123456789';
    if (chars.indexOf('!') > -1) mask += '~`!@#$%^&*()_+-={}[]:";\'<>?,./|\\';
    var result = '';
    for (var i = length; i > 0; --i) result += mask[Math.round(Math.random() * (mask.length - 1))];
    return result;
},
onMessage : function (message) {

// summary:
//		Process the data in the client based on the type of message queue, whether the
//		client is the original sender, filtering by topic pattern, etc.
//		The following inputs are required:
//			queue		:	Type of message queue: fanout, routing, publish, topic and request
//				fanout	:	Run callback on all clients except the sender
//				routing	:	Run callback only in the sender client
//				publish	:	Run callback in all clients that have subscribed to the topic
//				topic	:	Run callback in all clients that pattern match the topic
//				request	:	Ignore (destined for server)
//			token		:	Token of the originating client
//			callback	:	Function to be called
//			data		:	A data hash to be passed to the callback function
//
//		NB: The above queues will be gradually implemented and may be changed or added to

	console.log("Agua.Exchange.onMessage    message: " + message);
	console.dir({message:message});
	console.log("Agua.Exchange.onMessage    this.lastMessage: " + this.lastMessage);
	console.dir({this_lastMessage:this.lastMessage});

	var identical = this._identicalHashes(message, this.lastMessage);
	console.log("Agua.Exchange.onMessage    identical: " + identical);

	if ( this._identicalHashes(message, this.lastMessage) ) {
		console.log("Agua.Exchange.onMessage    SKIPPING REPEAT MESSAGE");
		return;
	}
	else {
		this.lastMessage = message;
		var thisObj = this;
		setTimeout(function() {
			thisObj.lastMessage = null;
		},
		1000);
	}
	
	// GET INPUTS	
	var queue 		=	message.queue;
	var token 		=	message.token;
	var sourceid 	=	message.sourceid;
	var widget		=	registry.byId(sourceid);
	console.log("Agua.Exchange.onMessage    queue: " + queue);
	console.log("Agua.Exchange.onMessage    token: " + token);
	console.log("Agua.Exchange.onMessage    widget: " + widget);
	console.dir({widget:widget});

	// RETURN IF NO TOKEN MATCH
	if ( token != this.token ) {
		console.log("Agua.Exchange.onMessage    token: " + widget + " does not match this.token: " + this.token + ". RETURNING");
		return;
	}
	
	var callback	=	message.callback;
	console.log("Agua.Exchange.onMessage    DOING widget[" + callback + "](" + JSON.stringify(message) + ")");
	widget[callback](message);
	
	//var sender = false;
	//if ( message.token == this.token )	sender = true;	
	//var callback	=	message.callback;
	//console.log("Agua.Exchange.onMessage    queue: " + queue);
	//console.log("Agua.Exchange.onMessage    sender: " + sender);
	//console.log("Agua.Exchange.onMessage    callback: " + callback);
	
	//if ( sender && queue == "fanout" ) return;
	//if ( sender && queue == "routing" ) {
	//	console.log("Agua.Exchange.onMessage    DOING this[" + callback + "](message)");
	//	this[callback](message);
	//}

	console.log("Agua.Exchange.onMessage    END");
}


});

});