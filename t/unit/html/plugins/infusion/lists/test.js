dojo.provide("t.plugins.filter.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.infusion.filter.test", 
          dojo.moduleUrl("t", "plugins/infusion/filter/test.html"));
}
