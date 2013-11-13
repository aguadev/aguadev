dojo.provide("t.plugins.details.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.infusion.details.test", 
          dojo.moduleUrl("t", "plugins/infusion/details/test.html"));
}
