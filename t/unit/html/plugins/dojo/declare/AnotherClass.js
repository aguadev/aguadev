define([
	"dojo/_base/declare"
],
    function (declare) {
        return declare(null, {
                color: "purple",
                
                anotherText : "another text",
             
                anotherClassMethod : function () {
                    console.log("Doing anotherClassMethod")
                }
            }
        );
    }
);
