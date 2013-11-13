dojo.provide("t.plugins.core.bookmark.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.core.bookmark.test", 
          dojo.moduleUrl("t", "plugins/bookmark/test.html"));
}
