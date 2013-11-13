// List constructor for use by the three lists in the top portion of the page
define(
	[
		"dojo/_base/declare",
		"dijit/registry",
		"dgrid/List",
		"dgrid/Selection",
		"dgrid/Keyboard",
	    "dgrid/extensions/DijitRegistry"
	],

function (declare, registry, List, Selection, Keyboard, DijitRegistry) {
	
	return declare("plugins.form.SelectList",
		[List, Selection, Keyboard, DijitRegistry],
		{
			getSelected : function () {
				if ( ! this._lastSelected )	return null;
				
				return this._lastSelected.innerHTML;
			}
		}
	);

}

); // define
	
