console.log("hello grunt");
module.exports = function(grunt) {
    console.log("INSIDE Gruntfile.js");


grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    uglify: {
	options: {
	    banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
	},
	dist: {
	    src: 'src/<%= pkg.name %>.js',
	    dest: 'dist/<%= pkg.name %>.min.js'
	}
    }
});

var shell = require('shelljs');

//grunt.registerTask('jquery', "download jquery bundle", function() {

grunt.registerTask('test', 'Run tests', function() {
    shell.exec('node test.js');
});



};    // END OF GRUNT

