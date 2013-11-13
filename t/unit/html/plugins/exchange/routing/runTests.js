require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"t/doh/Agua",
	"t/plugins/exchange/routing/Exchange",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Agua, Exchange, ready) {

// SET GLOBAL
window.Agua = Agua;
Agua.cgiUrl = "../../../../../cgi-bin/infusiondev/";

// NEW EXCHANGE
var exchange = new Exchange({});

// CONNECT
setTimeout(function(){
    exchange.connect();
},
200);

// STARTUP HTML LISTENERS
setTimeout(function(){
    exchange.startup();
},
200);

// SET COOKIE
Agua.cookie("username", "admin");
Agua.cookie("sessionid", "0000000000.0000.000");

doh.register("plugins.exchange.routing",
[
	
{
	name: "connect",
	setUp: function(){
	},
	runTest : function(){   
        setTimeout(function(){
            doh.assertTrue(exchange.conn != null);
        },
        500);
    }
}
,
{
	name: "runTests.send",
	setUp: function(){
	},
	runTest : function () {        
        // OPEN POPUP
        var url = window.location;
        popup = open( "popup.html", "popup", "width=500,height=400" );
        popup.focus();
        console.log("runTests.send    popup: ");
        console.dir({popup:popup});

        // VERIFY CHAT LIST IS EMPTY
        setTimeout(function(){
            //console.log("runTests.send    DOING exchange.send()");
            var chat = popup.document.body.childNodes[0];
            //console.log("runTests.send    chat:");
            console.dir({chat:chat});
            var chatList = chat.childNodes;
            //console.log("runTests.send    chatList.length: " + chatList.length);
            console.dir({chatLength:chatList.length});
            var chatListLength = chatList.length;
            //console.log("runTests.send    chatListLength: " + chatListLength);
            
            console.log("runTests.send    chatList empty");
            doh.assertEqual(chatListLength, 0);
        },
        700);

        // SEND MESSAGE
        var message = "{\"message\":\"TEST MESSAGE\"}";
        setTimeout(function(){
            console.log("runTests.send    DOING exchange.send()");
            exchange.send(message);
        },
        1000);
        
        // VERIFY POPUP RECEIVES MESSAGE SENT FROM WINDOW
        setTimeout(function(){
            var chat = popup.document.body.childNodes[0];
            console.log("runTests.send    chat:");
            console.dir({chat:chat});
            var chatList = chat.childNodes;
            console.log("runTests.send    chatList:");
            console.dir({chatList:chatList});
        
            var receivedMessage = chatList[chatList.length - 1].innerText;
            console.log("runTests.send    receivedMessage: " + receivedMessage);
            
            doh.assertEqual(message, receivedMessage);
        },
        3000);

        // VERIFY WINDOW RECEIVES MESSAGE SENT FROM POPUP
        setTimeout(function(){
            var chat = popup.document.body.childNodes[0];
            //console.log("runTests.send    chat:");
            //console.dir({chat:chat});
            var chatList = chat.childNodes;
            //console.log("runTests.send    chatList:");
            //console.dir({chatList:chatList});
        
            var message = "{\"message\":\"POPUP MESSAGE\"}";
            var input = popup.document.body.children[1][0];
            console.log("runTests.send    input:");
            console.dir({input:input});
            input.value = message;
            var submit = popup.document.body.children[1][1];
            submit.click();
        
            //console.log("runTests.send    receivedMessage: " + receivedMessage);
            
            //console.log("runTests.send    receivedMessage")
            //doh.assertEqual(message, receivedMessage);
        },
        3000);
    }
}


]);

	//Execute D.O.H. in this remote file.
	doh.run();
});



