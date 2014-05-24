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

///////}}}}}}

return declare("plugins/core/Agua/Exchange", [], {

///////}}}}}}}

lastMessage : null,

connectTimeout : 2000, 

///////}}}}}}}

// EXCHANGE
setExchange : function (Exchange) {

	return this._milestoneFunction( 'setExchange', function( deferred ) {

		console.log("Agua.Exchange.setExchange    Exchange:");
		console.dir({Exchange:Exchange});
	
		// SET TOKEN
		this.setToken();
		
		// SET exchange
		this.exchange = new Exchange({});
		console.dir({this_exchange:this.exchange});
	
		//// SET onMessage LISTENER
		var thisObject = this;
		this.exchange.onMessage = function (json) {
			console.log("Agua.Exchange.setExchange    this.exchange.onMessage FIRED    json.toString().substring(0,100):" + json.toString().substring(0,100));
			console.log("Agua.Exchange.setExchange    this.exchange.onMessage FIRED    typeof json:" + typeof json);
			console.dir({json:json});
			var data = json;
			if ( typeof json != "object") {
				data = JSON.parse(json);
			}
			
			if ( data && data.sendtype && data.sendtype == "request" ) {
				console.log("Agua.Exchange.setExchange    this.exchange.onMessage FIRED    data type is 'request'. Returning");
				return;
			}
			
			thisObject.onMessage(data);
			
		};
		
		// CONNECT
		var connectTimeout = this.connectTimeout;
		setTimeout(function(){
			try {
				console.log("Agua.Exchange.setExchange    thisObject: " + thisObject);
				console.log("Agua.Exchange.setExchange    thisObject.exchange: " + thisObject.exchange);
				thisObject.exchange.connect();

				console.log("Agua.Exchange.setExchange    {} {} {} CONNECTED {} {} {}");

				deferred.resolve({success:true});
			}
			catch(error) {
				console.log("Agua.Exchange.setExchange    *** CAN'T CONNECT TO SOCKET ***");
				console.log("Agua.Exchange.setExchange    error: " + error);
			}
		},
		connectTimeout);	
	});
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

onMessage : function (data) {
	console.log("Agua.Exchange.onMessage    data:");
	console.dir({data:data});
	console.log("Agua.Exchange.onMessage    this.lastMessage: " + this.lastMessage);
	console.dir({this_lastMessage:this.lastMessage});

	var identical = this._identicalHashes(data, this.lastMessage);
	console.log("Agua.Exchange.onMessage    identical: " + identical);

	if ( this._identicalHashes(data, this.lastMessage) ) {
		console.log("Agua.Exchange.onMessage    SKIPPING REPEAT MESSAGE");
		return;
	}
	else {
		this.lastMessage = data;
		var thisObj = this;
		setTimeout(function() {
			thisObj.lastMessage = null;
		},
		1000);
	}
	
	// GET INPUTS	
	var queue 		=	data.queue;
	var token 		=	data.token;
	var sourceid 	=	data.sourceid;
	var widget		=	registry.byId(sourceid);
	console.log("Agua.Exchange.onMessage    data.sourceid: " + data.sourceid);
	console.log("Agua.Exchange.onMessage    queue: " + queue);
	console.log("Agua.Exchange.onMessage    token: " + token);
	console.log("Agua.Exchange.onMessage    widget: " + widget);
	console.dir({widget:widget});

	// RETURN IF NO TOKEN MATCH
	if ( token != this.token ) {
		console.log("Agua.Exchange.onMessage    token: " + token + " does not match this.token: " + this.token + ". RETURNING");
		return;
	}
	
	var callback	=	data.callback;
	console.log("Agua.Exchange.onMessage    DOING widget[" + callback + "](" + JSON.stringify(data).substring(0,500) + ")");
	widget[callback](data);
	
	//var sender = false;
	//if ( data.token == this.token )	sender = true;	
	//var callback	=	data.callback;
	//console.log("Agua.Exchange.onMessage    queue: " + queue);
	//console.log("Agua.Exchange.onMessage    sender: " + sender);
	//console.log("Agua.Exchange.onMessage    callback: " + callback);
	
	//if ( sender && queue == "fanout" ) return;
	//if ( sender && queue == "routing" ) {
	//	console.log("Agua.Exchange.onMessage    DOING this[" + callback + "](data)");
	//	this[callback](data);
	//}

	console.log("Agua.Exchange.onMessage    END");
}


});

});