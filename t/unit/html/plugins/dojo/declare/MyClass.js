define([
	"dojo/_base/declare"
],
    function (declare) {
        return declare(null, {
                color: "red",
             
                text : "text", 
             
                classMethod : function () {
                    console.log("Doing classMethod")
                }    
            }
        );
    }
);
