require([
	"dojo/_base/declare",
	"dojo/dom",
	"doh/runner",
	"t/doh/util",
	"plugins/form/TextArea",
	"dojo/ready",
	"dojo/domReady!"
],

function (declare, dom, doh, util, TextArea, ready) {

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
					pattern: "^.{0,250}$",
					label: "Description",
					invalidMessage: "Must be less than 250 characters",
					invalidPrompt: "Input up to 250 characters",
					required: true,
					cols: 40,
					rows: 5,
					subtests :[
						{
							value: "lessthan250charactersAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
							valid: true
						},
						{
							value: "251characterszzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
							valid: false
						},
						{
							value: "",
							valid: true
						}
					]
				}
			];
			
			for ( var i in tests ) {
				var test = tests[i];

				var textarea = new TextArea({
					label: test.label,
					invalidMessage: test.invalidMessage,
					invalidPrompt: test.invalidPrompt,
					pattern: test.pattern,
					required: true,
					cols: 40,
					rows: 5
				});
				//console.log("instantiate    textarea: " + textarea);
				//console.dir({textarea:textarea});
				
				// VERIFY RETURNED CLASS NAME
				var className = util.getClassName(textarea);
				console.log("instantiate    className is '" + className + "'");
				doh.assertEqual(className, "plugins.form.TextArea");
				
				// ATTACH GRID TO PAGE
				var attachPoint = dom.byId("attachPoint");
				attachPoint.appendChild(textarea.containerNode);
				
				var subtests = test.subtests;
				for ( var x in subtests ) {
					var subtest = subtests[x];
					var length = subtest.value.length;
					
					// SET CONTENT OF TEXTAREA
					textarea.input.value = subtest.value;
					textarea.input.set("value", subtest.value);
					
					var valid = textarea.isValid();
					var expected = subtest.valid;

					console.log("instantiate    " + subtest.valid + ": " + subtest.value);
					doh.assertEqual(valid, expected);
					
					// DO FAKE onBlur
					textarea.input.onBlur();
					
					var letterCount = textarea.letterCount.innerHTML;	
					console.log("instantiate    length " + length + " == letterCount " + letterCount);
					doh.assertEqual(length, letterCount);
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
