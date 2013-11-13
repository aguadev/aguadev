require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"plugins/form/ValidationTextBox",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, ValidationTextBox, ready) {

console.log("# plugins.form.ValidationTextBox");
	
/////}}}}}}

doh.register("plugins.form.ValidationTextBox", [

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
					pattern: "[A-Za-z]\\w+",
					subtests :[
						{
							value: 99999,
							valid: false
						},
						{
							value: "a-a",
							valid: false
						},
						{
							value: "a_a",
							valid: true
						},
						{
							value: "a990",
							valid: true
						}
					]
				}
			]
			
			for ( var i in tests ) {
				var test = tests[i];
				
				var textbox = new ValidationTextBox({
					label: "Project Name",
					pattern: test.pattern,
					invalidMessage: "HELP ME",
					invalidPrompt: "I'M ALIVE",
					required: true
				});
				
				// MAKE SURE IT WORKS
				var className = util.getClassName(textbox);
				console.log("instantiate    className is '" + className + "'");
				doh.assertEqual(className, "plugins.form.ValidationTextBox");
				
				// ATTACH GRID TO PAGE
				var attachPoint = dom.byId("attachPoint");
				attachPoint.appendChild(textbox.containerNode);
			
				var subtests = test.subtests;
				for ( var x in subtests ) {
					var subtest = subtests[x];
					
					textbox.input.textbox.value = subtest.value;
					var valid = textbox.input.isValid();
					var expected = subtest.valid;
					//console.log("instantiate    subtest.value: " + subtest.value);
					//console.log("instantiate    subtest.valid: " + subtest.valid);
					//console.log("instantiate    valid: " + valid);
					console.log("instantiate    value '" + subtest.value + "' is " + subtest.valid);
					doh.assertEqual(valid, expected);
				}
			}
			//console.log("# constructor    END");
		});
			
	},
	tearDown: function () {}
}
	
]);

// Execute D.O.H.
doh.run();

});
