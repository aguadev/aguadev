/* SUMMARY: STORE conf FILE KEYPAIRS */

define([
	"dojo/_base/declare"
],

function (declare) {

/////}}}}}

return declare("plugins.core.Conf",
	[], {

// conf HASH
data : null,

// Parent, i.e., Agua
parent : null,

constructor : function (args) {
    this.parent = args.parent;
},

postCreate : function () {
},

startup : function () {
    //console.log("core.Conf.startup    caller: " + this.startup.caller.nom);
},

setData : function () {
	this.data = this.parent.getData("conf");
},
getKey : function (sectionName, key) {	
    console.log("Conf.getKey    sectionName: " + sectionName);
    console.log("Conf.getKey    key: " + key);
	if ( ! this.data ) 	this.setData(); 
	
    console.log("Conf.getKey    this.data:");
    console.dir({this_data:this.data});    

	if ( ! this.data ) return "";
	if ( ! this.data[sectionName] ) return "";
	
	return this.data[sectionName][key];
},

setKey : function (sectionName, key, value) {
	// TO DO: ENABLE UPDATE CONF FILE ON REMOTE
}


}); //	end declare

});	//	end define


