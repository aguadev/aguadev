dojo.provide("t.unit.plugins.module");

try{
	// TEST UTILS
	dojo.require("t.doh.util");
 
	// TEST MODULES
	dojo.require("t.unit.plugins.core.module");
	dojo.require("t.unit.plugins.dojox.module");
	dojo.require("t.unit.plugins.folders.module");
	dojo.require("t.unit.plugins.home.module");
	dojo.require("t.unit.plugins.view.module");
	dojo.require("t.unit.plugins.workflow.module");
	
}
catch(e) {
    doh.debug(e);
}

 