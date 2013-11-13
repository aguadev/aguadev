dojo.provide("t.plugins.data.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.infusion.data.test", 
          dojo.moduleUrl("t", "plugins/infusion/data/test.html"),
          20000
     );
}
