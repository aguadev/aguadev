dojo.provide("t.plugins.workflow.io.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl("t.plugins.workflow.runstatus.test", 
                         dojo.moduleUrl("t", "plugins/workflow/runstatus/test.html"));
}
