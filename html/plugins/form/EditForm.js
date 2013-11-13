dojo.provide("plugins.form.EditForm");

// PROVIDES FORM INPUT AND ROW EDITING WITH VALIDATION
// INHERITING CLASSES MUST IMPLEMENT saveInputs AND deleteItem METHODS
// THE dnd DRAG SOURCE MUST BE this.dragSourceWidget IF PRESENT

// EXTERNAL MODULES
dojo.require("dojo.dnd.Source");

// INTERNAL MODULES
dojo.require("plugins.form.DndSource");
dojo.require("plugins.core.Common");
dojo.require("plugins.form.EditRow");
dojo.require("plugins.form.DndTrash");
dojo.require("plugins.form.Inputs");

dojo.declare("plugins.form.EditForm",
	[ plugins.form.EditRow, plugins.form.Inputs, plugins.form.DndTrash, plugins.form.DndSource ],
{

////}}}

constructor : function(args) {
	////console.log("EditForm.constructor     plugins.form.EditForm.constructor");			
},

postCreate : function() {
	////console.log("EditForm.postCreate    ");
	this.startup();
},

startup : function () {
	////console.log("EditForm.startup    plugins.form.EditForm.startup()");
	this.inherited(arguments);	
}

}); // plugins.form.EditForm

