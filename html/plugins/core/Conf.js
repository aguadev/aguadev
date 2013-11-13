dojo.provide("plugins.core.Conf");

/* SUMMARY: STORE conf FILE KEYPAIRS */

dojo.declare( "plugins.core.Conf", null, {    

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
	//console.log("core.Conf.startup    parent:");
	//console.dir({parent:parent});
},

setData : function () {
	//console.log("core.Conf.setData    Agua:");
	//console.dir({Agua:Agua});

	this.data = this.parent.getData("conf");
	//console.log("core.Conf.setData    this.data:");
	//console.dir({this_data:this.data});
},
getKey : function (sectionName, key) {	
    //console.log("Conf.getKey    sectionName: " + sectionName);
    //console.log("Conf.getKey    key: " + key);
	if ( ! this.data ) 	this.setData(); 
	
//    //console.log("Conf.getKey    this.data:");
//    //console.dir({this_data:this.data});    

	if ( ! this.data ) return "";
	if ( ! this.data[sectionName] ) return "";

    //console.log("Conf.getKey    RETURNING :" + this.data[sectionName][key]);
	
	return this.data[sectionName][key];
},

setKey : function (sectionName, key, value) {
	// TO DO: ENABLE UPDATE CONF FILE ON REMOTE
}


});

