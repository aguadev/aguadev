define([
	"dojo/_base/declare",
	"t/plugins/dojo/declare/MyClass",
	"t/plugins/dojo/declare/OtherClass",
	"t/plugins/dojo/declare/AnotherClass",
],
    function (declare, MySubClass, OtherClass, AnotherClass) {
        return declare(null, [
                MySubClass,
                OtherClass,
                AnotherClass
            ], {
 
    // MyMultiSubClass now has all of the properties and methods from:
    // MySubClass, OtherClass, and MyMixinClass

            }
        );
    }
);