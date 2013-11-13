dojo.provide("plugins.core.Common");

/* 	CLASS SUMMARY: PROVIDE COMMONLY USED METHODS FOR ALL CLASSES.

	ALSO PROVIDE LOW-LEVEL METHODS THAT ACCOMPLISH GENERIC TASKS WHICH
	
	ARE WRAPPED AROUND BY CONTEXT-SPECIFIC METHODS
*/

dojo.require("plugins.core.Common.Array");
dojo.require("plugins.core.Common.BrowserDetect");
dojo.require("plugins.core.Common.ComboBox");
dojo.require("plugins.core.Common.Date");
dojo.require("plugins.core.Common.Sort");
dojo.require("plugins.core.Common.Text");
dojo.require("plugins.core.Common.Toast");
dojo.require("plugins.core.Common.Util");

dojo.declare( "plugins.core.Common", [
	plugins.core.Common.Array,
	plugins.core.Common.ComboBox,
	plugins.core.Common.Date,
	plugins.core.Common.Sort,
	plugins.core.Common.Text,
	plugins.core.Common.Toast,
	plugins.core.Common.Util
], {

// HASH OF LOADED CSS FILES
loadedCssFiles : null,

});

