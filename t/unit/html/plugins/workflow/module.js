dojo.provide("t.unit.plugins.workflow.module");

try{
    dojo.require("t.unit.plugins.workflow.io.test");
    dojo.require("t.unit.plugins.workflow.runworkflow.test");
    //dojo.require("t.unit.plugins.workflow.runstatus.module");
    dojo.require("t.unit.plugins.workflow.runstatus.duration.test");
    dojo.require("t.unit.plugins.workflow.runstatus.status.test");
    dojo.require("t.unit.plugins.workflow.runstatus.startup.test");
    dojo.require("t.unit.plugins.workflow.apps.adminpackages.test");
    dojo.require("t.unit.plugins.workflow.apps.aguapackages.test");
}
catch(e) {
    doh.debug(e);
}
