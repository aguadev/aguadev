dojo.provide("t.plugins.form.status.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.form.status.test", 
         dojo.moduleUrl("t", "plugins/form/status/test.html"),
         20000
     );
}
