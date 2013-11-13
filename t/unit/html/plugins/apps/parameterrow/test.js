dojo.provide("t.plugins.admin.parameters.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.admin.parameters.test", 
          dojo.moduleUrl("t", "plugins/admin/parameters/test.html"));
}
