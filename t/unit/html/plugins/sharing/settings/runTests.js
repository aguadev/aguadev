// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
//dojo.require("dijit.dijit");
////dojo.require("dojox.robot.recorder");
////dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua")
dojo.require("plugins.admin.Settings");

var data = new Object;
data.headings = {
	leftPane : [ "Access" ],
	middlePane : [],
	rightPane : []
};

data.settings = [
	{
	  'owner' : 'syoung',
	  'worldcopy' : '1',
	  'groupwrite' : '1',
	  'worldwrite' : '1',
	  'groupname' : 'mihg',
	  'groupcopy' : '1',
	  'groupview' : '1',
	  'worldview' : '1'
	},
	{
	  'owner' : 'syoung',
	  'worldcopy' : '1',
	  'groupwrite' : '1',
	  'worldwrite' : '1',
	  'groupname' : 'snp',
	  'groupcopy' : '1',
	  'groupview' : '1',
	  'worldview' : '1'
	}
];


// GLOBAL Agua VARIABLE
var Agua;

dojo.addOnLoad(function(){

// GLOBAL Agua VARIABLE
Agua = new plugins.core.Agua([]);
Agua.stages = data.stages;
console.log("Agua: " + Agua);

// OVERRIDE Agua METHODS TO SUPPLY TEST DATA
Agua.getStageParameters = function(moniker) {
	console.log("Agua.getStageParameters(" + moniker + ")");
	if ( moniker == "current" )	return data.stageParameters;
	else return data.previousStageParameters;
};

var settings = new plugins.admin.Access({});
	


});

