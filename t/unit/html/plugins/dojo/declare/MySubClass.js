define([
	"dojo/_base/declare",
	"t/plugins/dojo/declare/MyClass"
],
    function (declare, MyClass) {
        return declare("MySubClass", [MyClass], {
                color: "blue",
                
                subClassMethod : function () {
                    console.log("Doing subClassMethod")
                }
    
    // MySubClass now has all of MyClass's properties and methods
    // These properties and methods override parent's
 
            }
        );
    }
);