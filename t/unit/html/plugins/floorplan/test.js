dojo.provide("t.plugins.floorplan.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.floorplan.test", 
          dojo.moduleUrl("t", "plugins/floorplan/test.html"));
}
