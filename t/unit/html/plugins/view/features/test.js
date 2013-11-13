dojo.provide("t.plugins.view.exchange.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl("t.plugins.view.exchange.test", 
                         dojo.moduleUrl("t", "plugins/view/browser/test.html"));
}
