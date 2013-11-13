dojo.provide("dojox.widget.RollingList");
dojo.experimental("dojox.widget.RollingList");

dojo.require("dijit._Templated");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.Menu");
dojo.require("dojox.html.metrics");

dojo.require("dojo.i18n"); 
dojo.requireLocalization("dojox.widget", "RollingList"); 

dojo.declare("dojox.widget._RollingListPane",
	[dijit.layout.ContentPane, dijit._Templated, dijit._Contained], {
	startup: function()
	{

		if(this._started){ return; }
	},

	_focusKey: function(/*Event*/e)
	
	{

		// summary: called when a keypress happens on the widget
	},
	
	DUMMY: function(/*Event*/e)
	{

		// summary: called when a keypress happens on the widget
	}

});