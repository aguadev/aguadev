dojo.provide("t.plugins.core.common.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.core.common.test", 
          dojo.moduleUrl("t", "plugins/core/common/test.html"));
}
