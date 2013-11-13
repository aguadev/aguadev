require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"plugins/form/DateTextBox",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, DateTextBox, ready) {

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
					pattern: "^\\d{1,2}\\/\\d{1,2}\\/\\d\\d\\d\\d$",
					label: "Date Received",
					invalidMessage: "mm/dd/yyyy",
					invalidPrompt: "Invalid date. Use mm/dd/yyyy format",
					required: true,
					subtests :[
						{
							value: "not-correct",
							valid: false
						}
						,
						{
							value: "5/11/2013",
							valid: true
						}
						,
						{
							value: "05/11/2013",
							valid: true
						}
						,
						{
							value: "05-11-2013",
							valid: false
						}
						,
						{
							value: "",
							valid: false
						}
					]
				}
			];
			
			for ( var i in tests ) {
				var test = tests[i];

				// GLOBAL
				textbox = new DateTextBox({
					label: test.label,
					invalidMessage: test.invalidMessage,
					invalidPrompt: test.invalidPrompt,
					pattern: test.pattern,
					required: true
				});
				//console.log("instantiate    textbox: " + textbox);
				//console.dir({textbox:textbox});
				
				// VERIFY RETURNED CLASS NAME
				var className = util.getClassName(textbox);
				console.log("instantiate    className is '" + className + "'");
				doh.assertEqual(className, "plugins.form.DateTextBox");
				
				// ATTACH WIDGET TO PAGE
				var attachPoint = dom.byId("attachPoint");
				attachPoint.appendChild(textbox.containerNode);
				
				var subtests = test.subtests;
				for ( var x in subtests ) {
					var subtest = subtests[x];
					
					//console.log("instantiate    subtest.value: " + subtest.value);								//console.log("instantiate    subtest.valid: " + subtest.valid);				

					// SET CONTENT OF TEXTBOX
					textbox.input.valueNode.value = subtest.value;
					var valid = textbox.isValid();
					var expected = subtest.valid;
					//console.log("instantiate    valid: " + valid);					
					//console.log("instantiate    expected: " + expected);					
					//
					console.log("instantiate    " + subtest.valid + ": " + subtest.value);
					doh.assertEqual(valid, expected);
					
					// DO FAKE onBlur
					textbox.input.onBlur();					
				}
			}
		});
			
	},
	tearDown: function () {}
}
	
]);

// Execute D.O.H.
doh.run();

});
