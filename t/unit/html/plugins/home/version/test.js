dojo.provide("t.plugins.home.version.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.home.version.test", 
          dojo.moduleUrl("t", "plugins/home/version/test.html"));
}
