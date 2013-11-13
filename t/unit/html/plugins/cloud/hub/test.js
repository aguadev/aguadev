dojo.provide("t.plugins.admin.settings.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.admin.settings.test", 
          dojo.moduleUrl("t", "plugins/admin/settings/test.html"));
}
