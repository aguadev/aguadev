define([
	"dojo/_base/declare",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"plugins/exchange/Exchange",
	"plugins/data/Controller",
	"dojo/ready",
],

function (declare, JSON, on, lang, Exchange, DataController, ready) {

////}}}}}

return declare("t.plugins.exchange.routing.Exchange", [Exchange, DataController], {

//////}}
startup : function(args) {		
	// SET INPUT
	console.log("routingExchange.startup    DOING this.setInput()");
	this.setInput();
	
	// SET SUBMIT
	console.log("routing.Exchange.constructor    DOING this.setSubmitOnClick()");
	this.setSubmitOnClick();
},
setInput : function () {
	this.input = dojo.byId("input");
	console.log("routing.Exchange.setInput   this.input: " + this.input);
	console.dir({this_input:this.input});
},
setSubmitOnClick : function () {
	console.log("routing.Exchange.setSubmitOnClick");
	this.submit = dojo.byId("submit");
	console.log("routing.Exchange.setInput   this.submit: " + this.submit);
	console.dir({this_submit:this.submit});

	var thisObject = this;
	on(this.submit, "click", function () {
		console.log("routing.Exchange.setInput    submit FIRED");
		console.log("routing.Exchange.setInput    this.input:");
		console.dir({this_input:thisObject.input});
		thisObject.send(thisObject.input.value);
	});
},
// OVERRIDE onMessage
onMessage : function (json) {
	console.log("routing.Exchange.message    json:");
	console.dir({json:json});

    var el = document.createElement('p');
    el.innerHTML = '<em>' + this.esc(json) + '</em>'
    document.getElementById('chat').appendChild(el);
    document.getElementById('chat').scrollTop = 1000000;
	
	var data = JSON.parse(json);
	console.log("routing.Exchange.message    data:");
	console.dir({data:data});
	
	var callback = data.callback;
	console.log("routing.Exchange.message    callback: " + callback);
	
	if ( ! callback ) {
		return;
	}
	
	this[callback](data);
},
esc : function (msg) {
    return msg.replace(/</g, '&lt;').replace(/>/g, '&gt;');
},
openProjectDialog : function (data) {
	console.log("routing.Exchange.openProjectDialog   data:");
	console.dir({data:data});

	console.log("routing.Exchange.openProjectDialog   DOING Agua.getData()");
	this.getTable();
}



}); 	//	end declare

});		//	end define

