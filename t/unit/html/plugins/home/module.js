dojo.provide("t.unit.plugins.home.module");

try{
    dojo.require("t.unit.plugins.home.github.test");
    dojo.require("t.unit.plugins.home.version.test");
    dojo.require("t.unit.plugins.home.progresspane.test");
}
catch(e) {
    doh.debug(e);
}
