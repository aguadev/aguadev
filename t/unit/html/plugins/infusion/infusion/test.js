dojo.provide("t.plugins.infusion.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.infusion.infusion.test", 
          dojo.moduleUrl("t", "plugins/infusion/infusion/test.html"));
}
