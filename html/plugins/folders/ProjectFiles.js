dojo.provide("plugins.folders.ProjectFiles");
/*
DISPLAY THE USER'S OWN PROJECTS DIRECTORY AND ALLOW
THE USER TO BROWSE AND MANIPULATE WORKFLOW FOLDERS
AND FILES

LATER FOR MENU: DYNAMICALLY ENABLE / DISABLE MENU ITEM
attr('disabled', bool) 
*/

if ( 1 ) {
dojo.require("plugins.folders.Files");
}

dojo.declare( "plugins.folders.ProjectFiles",
	[ plugins.folders.Files ], {
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "folders/templates/filesystem.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PROJECT NAME 
project : null,

// DEFAULT TIME (milliseconds) TO SLEEP BETWEEN FILESYSTEM LOADS
sleep : 300,

// ARRAY OF PANE NAMES TO BE LOADED IN SEQUENCE [ name1, name2, ... ]
loadingPanes : null,

// STORE FILESYSTEM fileDrag OBJECTS
fileDrags : null,

// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins", "folders/css/dialog.css"),
//	dojo.moduleUrl("plugins", "files/FileDrag/FileDrag.css"),
	dojo.moduleUrl("dojox", "widget/Dialog/Dialog.css")
],

// TYPE OR PURPOSE OF FILESYSTEM
title : "Workflow",

// open: bool
// Whether or not title pane is open on load
open : true,

// self: string
// Name used to represent this object in this.core
self : "projectfiles"


});
