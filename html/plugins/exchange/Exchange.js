console.log("plugins.exchange.Exchange    LOADING");

define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/connect",
	"dojo/_base/lang",
	"dojo/ready",
	"plugins/exchange/socketio",
],

function (declare, arrayUtil, JSON, on, connect, lang, ready) {

////}}}}}

return declare("plugins.exchange.Exchange", null, {

// listeners : Function[]
// 		Array of event listeners
listeners : [],

// port : Integer
//		Port on which SocketIO is communicating
port : "8080",

// host : String
//		Absolute URL of host SocketIO is running on
host : null,

// socketJs : String
//		Location of socketio.js file
socketJs : require.toUrl("plugins/exchange/socketio.js"),

// delayConnect : Integer
//		Length of time (milliseconds) to delay in setTimeout before calling this.connect()
delayConnect : 500,

// callback : Function reference
// 		Call this with 'object' argument when message is received
callback : function(object) {},

//////}}

constructor : function(args) {	
    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD SOCKET.IO
	this.loadSocketIO();
	
	// SET HOST URL
	this.setHost();
},
loadSocketIO : function () {
	var script = document.createElement("script");
	script.type = "text/javascript";
	script.src = this.socketJs;
	document.getElementsByTagName('head')[0].appendChild(script);	
},
setHost : function () {
	var host = window.location.host;

	this.host = host;
},
connect : function () {
	console.log("Exchange.connect    caller: " + this.connect.caller.nom);

	console.log("Exchange.connect    this.id: " + this.id);
	console.log("Exchange.connect    io: " + io);
	console.dir({io:io});
	
	// CONNECT WITH SOCKET.IO VERSION 0.9.11
	this.conn = io.connect(this.host, { port: this.port} );
	console.log("Exchange.connect    CONNECTED, this.conn: " + this.conn);
	console.dir({this_conn:this.conn});

	// REMOVE LISTENERS
	//console.log("Exchange.connect    this.listeners: " + this.listeners);
	console.dir({this_listeners:this.listeners});
	for ( var i = 0; i < this.listeners.length; i++ ) {
		connect.disconnect(this.listeners[i]);
	}
	this.listeners = [];
	//console.log("Exchange.connect    AFTER DISCONNECT, this.listeners: " + this.listeners);
	//console.dir({this_listeners:this.listeners});
	
	// ADD LISTENER
	var thisObject = this;
	var listener = on(this.conn, 'message', function(object){
		console.log("Exchange.connect    on(this.conn, message, ...) FIRED");
	    thisObject.onMessage(object);
	});
	this.listeners.push(listener);

	return this.conn;
},
sendMessage : function (message) {
    console.log("Exchange.sendMessage    message: " + message);
	console.dir({message:message});
	
	this.send({
		message : message
	});
},
send : function (data) {
	console.log("Exchange.send    caller: " + this.send.caller.nom);

	console.log("Exchange.send    this.id: " + this.id);
    console.log("Exchange.send    data: ");
	console.dir({data:data});
	console.log("Exchange.send    this.conn: " + this.conn);
	console.dir({this_conn:this.conn});

	// SET TOKEN
	data.token		=	Agua.token;
	
	// SET SENDTYPE
	data.sendtype	=	"request";
	
	// SET DATABASE
	data.database 	= 	data.database || Agua.database;

	// SET USERNAME		
	data.username 	= 	data.username || Agua.cookie('username');

	// SET USERNAME		
	data.sessionid 	= 	data.sessionid || Agua.cookie('sessionid');

	//if ( ! this.conn ) {
	//	console.log("Exchange.send    ! this.conn. REDOING this.connect()");
	//	this.connect();
	//}
	
	var json = JSON.stringify(data);
	
	var thisObject = this;
	setTimeout(function () {
		console.log("Exchange.send    DOING thisObject.conn.send(json)");
	    thisObject.conn.send(json);
	},
	20);
	
},
// OVERRIDE THIS TO FIRE callback WITH RECEIVED DATA
onMessage : function (object) {
	console.log("YOU DID NOT OVERRIDE Exchange.onMessage    object: " + object);
	console.dir({object:object});
	if ( object && object.type && object.type == "request" ) {
		console.log("Exchange.onMessage    object.type is 'request'. Returning");
		return;
	}
	
	this.callback(object);
}

}); 	//	end declare

});		//	end define


console.log("plugins.exchange.Exchange    COMPLETE");