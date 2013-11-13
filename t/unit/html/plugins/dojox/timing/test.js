dojo.provide("t.plugins.dojox.timing.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.dojox.timing.test", 
          dojo.moduleUrl("t", "plugins/dojox/timing/test.html")
     );
}
