dojo.provide("t.plugins.workflow.workflows.test");

if(dojo.isBrowser){
     //Define the HTML file/module URL to import as a 'remote' test.
     doh.registerUrl(
          "t.plugins.workflow.workflows.test", 
          dojo.moduleUrl("t", "plugins/workflow/workflows/test.html"));
}
