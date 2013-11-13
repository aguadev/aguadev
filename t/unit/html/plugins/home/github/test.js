dojo.provide("t.plugins.home.github.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.home.github.test", 
          dojo.moduleUrl("t", "plugins/home/github/test.html"));
}
