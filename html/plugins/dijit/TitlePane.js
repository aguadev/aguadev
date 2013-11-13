dojo.provide("plugins.dijit.TitlePane");

dojo.require("dijit.TitlePane");

dojo.declare("plugins.dijit.TitlePane",
	[dijit.TitlePane],
{
	// summary:
	//		ADAPTED dijit.TitlePane TO ADD EXTRA ELEMENTS TO TEMPLATE
	
	templateString: dojo.cache("plugins", "dijit/templates/TitlePane.html"),

	// NUMBER APPEARS AT FAR RIGHT OF TITLE
	number: null,

	attributeMap: dojo.delegate(dijit.layout.ContentPane.prototype.attributeMap, {
		title: { node: "titleNode", type: "innerHTML" },
		number: { node: "numberNode", type: "innerHTML" },
		tooltip: {node: "focusNode", type: "attribute", attribute: "title"},	// focusNode spans the entire width, titleNode doesn't
		id:""
	}),
	
	setNumber: function(/*String*/ number){
		// summary:
		//		Deprecated.  Use set('number', ...) instead.
		// tags:
		//		deprecated
		dojo.deprecated("dijit.TitlePane.setNumber() is deprecated.  Use set('number', ...) instead.", "", "2.0");

		this.set("number", number);
	}
	

});
