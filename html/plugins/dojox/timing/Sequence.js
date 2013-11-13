dojo.provide("plugins.dojox.timing.Sequence");

dojo.require("dojox.timing.Sequence");

dojo.declare("plugins.dojox.timing.Sequence", [ dojox.timing.Sequence ], {
	// summary:
	// ADDED clear METHOD TO CLEAR _defsResolved SLOT
	// TO ALLOW A FRESH START WITH go METHOD

	clear: function () {
		//console.log("Sequence.clear()    plugins.dojox.timing.Sequence");

		this._defsResolved = [];
	}

});
