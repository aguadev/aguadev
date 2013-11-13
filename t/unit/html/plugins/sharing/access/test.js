dojo.provide("t.plugins.admin.access.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.admin.access.test", 
          dojo.moduleUrl("t", "plugins/admin/access/test.html"));
}
