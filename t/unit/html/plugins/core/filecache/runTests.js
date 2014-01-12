// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t/unit");	

// DOJO TEST MODULES
dojo.require("dijit.dijit");
//dojo.require("dojox.robot.recorder");
//dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.folders.Folders");
dojo.require("plugins.folders.ProjectFiles");

var Agua;

dojo.addOnLoad(function(){

	Agua = new plugins.core.Agua({
		cgiUrl : dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
		, dataUrl: dojo.moduleUrl("t", "json/getData-111127.json")
	});

	Agua.cookie('username', 'testuser');
	Agua.cookie('sessionid', '9999999999.9999.999');

    Agua.setFileCaches("../../../json/fileCaches.json");

	doh.register("t.plugins.core.common.test",
	[	
		{
			name: "fileCache",
			runTest: function(){

				// SET DEFERRED OBJECT
				var deferred = new doh.Deferred();
				

				setTimeout(function() {
					try {
						var filecache = Agua.getFileCache("/data/sequence/demo");
						console.log("filecache (/data/sequence/demo): ");
						console.dir({filecache:filecache});
		
						deferred.callback(true);
		
					} catch(e) {
					  deferred.errback(e);
					}
				}, 15000);

				return deferred;
			},
			
			timeout: 45000 
		}

	]);	// doh.register
	
	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

