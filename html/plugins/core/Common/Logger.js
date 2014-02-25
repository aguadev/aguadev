define([
	"dojo/_base/declare",
	"dojo/sniff",
	"dojo/on",
],

function (
	declare,
	sniff,
	on
) {

/////}}}}}

return declare("plugins.core.Common.Logger",
	[], {

logDebug : function (text, object) {
	if (! this.DEBUG ) {
		return;
	}

	if (! text ) {
		text = "";
	}
    var err = function getErrorObject(){
        try { throw Error('') } catch(err) { return err; }
    }();

    var caller;
	var browser = {};
	browser.mozilla = false;
    if (sniff("mozilla")) {
        caller = err.stack.split("\n")[2];
    } else {
        caller = err.stack.split("\n")[4];
    }
	//console.log("caller: " + caller);
	
    var index = caller.indexOf('.js');
    var className = caller.substr(0, index);
    index = className.lastIndexOf('\.\./');
    className = className.substr(index + 3, className.length);
	className = className.replace(/\//g, '.');	

	var lineNumber;
    if (browser.mozilla) {
        lineNumber = caller;
    } else {
        index = caller.lastIndexOf(':');
        lineNumber = caller.substr(0, index);
    }
    index = lineNumber.lastIndexOf(':');
    lineNumber = lineNumber.substr(index + 1, lineNumber.length);

	var scriptFunction = this.logDebug.caller.nom;
	var message	=	className + "." + scriptFunction + " " + lineNumber + "    " + text;
	if ( ! object ) {
		console.log(message);
	}
	else if ( typeof object == "string" ) {
		message 	+=	 ": " + object;
		console.log(message);
	}
	else {
		message 	+=	 ":"
		console.log(message);
		console.dir({object:object});
	}	
}

}); //	end declare

});	//	end define

