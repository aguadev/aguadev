require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/unit/doh/util",
	"plugins/form/Select",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, Select, ready) {

console.log("# plugins.form.Select");
	
/////}}}}}}

doh.register("plugins.form.Select", [

/////}}}}}}

{

/////}}}}}}

	name: "instantiate",
	setUp: function(){
	},
	runTest : function(){

		console.log("# instantiate");
		
		ready( function() {

			var tests = [
				{
					pattern	: 	"^.{0,250}$",
					label	: 	"Build Version",
					options	:	[
						{ label: "NCBI36", value: "NCBI36", selected: true },
						{ label: "NCBI37", value: "NCBI37" }
					],
					expected :	"NCBI36"
				}
			];
			
			for ( var i in tests ) {
				var test = tests[i];

				var select = new Select({
					label: test.label,
					options: test.options
				});
				console.log("instantiate    select:");
				console.dir({select:select});
				
				// VERIFY RETURNED CLASS NAME
				var className = util.getClassName(select);
				console.log("instantiate    className is '" + className + "'");
				doh.assertEqual(className, "plugins.form.Select");
				
				// ATTACH GRID TO PAGE
				var attachPoint = dom.byId("attachPoint");
				attachPoint.appendChild(select.containerNode);

				var value = select.input.value;
				//console.log("instantiate    value: " + value);
				var expected = test.expected;
				
				console.log("instantiate    selectedValue");
				doh.assertEqual(value, expected);
			}
		});
			
	},
	tearDown: function () {}
}
	
]);

// Execute D.O.H.
doh.run();

});
