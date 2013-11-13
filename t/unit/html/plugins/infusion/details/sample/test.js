dojo.provide("t.plugins.infusion.detailed.sample.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.infusion.detailed.sample.test", 
          dojo.moduleUrl("t", "plugins/infusion/detailed/sample/test.html"));
}
