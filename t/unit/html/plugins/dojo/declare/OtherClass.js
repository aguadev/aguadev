define([
	"dojo/_base/declare"
],
    function (declare) {
        return declare(null, {
                color: "red",
             
                otherText: "other text",
                
                otherClassMethod : function () {
                    console.log("Doing otherClassMethod")
                }
            }
        );
    }
);

