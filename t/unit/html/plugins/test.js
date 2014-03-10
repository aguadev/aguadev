console.log("hello");

var semver = require('semver');
var tap = require('tap');
var test = tap.test;
var old_console = console;

test('\nnegative range tests', function(t) {

	t.ok(semver.valid('1.2.3'), "1.2.3 is valid"); // true
	t.ok(!semver.valid('a.b.c'), "a.b.c is not valid"); // false

	t.ok(semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3'), "satisfies"); // true
	t.ok(!semver.gt('1.2.3', '9.8.7'), "greater than"); // false
	t.ok(semver.lt('1.2.3', '9.8.7'), "less than"); // true
	
	//var cleaned = semver.clean('  =v1.2.3   '); // '1.2.3'
	//console.log("cleaned: " + cleaned);
	//console.dir({cleaned:cleaned});
	//t.ok(cleaned === "1.2.3", "cleaned"); 

	t.end();
});