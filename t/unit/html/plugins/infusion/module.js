dojo.provide("t.unit.plugins.infusion.module");

try {
    dojo.require("t.unit.plugins.infusion.data.test");
    dojo.require("t.unit.plugins.infusion.filter.test");
    dojo.require("t.unit.plugins.infusion.detailed.project.test");
    dojo.require("t.unit.plugins.infusion.detailed.sample.test");
    dojo.require("t.unit.plugins.infusion.detailed.flowcell.test");
    dojo.require("t.unit.plugins.infusion.detailed.lane.test");
    dojo.require("t.unit.plugins.infusion.filter.test");
}
catch(e) {
    doh.debug(e);
}
