define(
	[
		"dojo/_base/declare"
		,"plugins/core/Agua/App"
		,"plugins/core/Agua/Aws"
		,"plugins/core/Agua/Data"
		,"plugins/core/Agua/Feature"
		,"plugins/core/Agua/Group"
		,"plugins/core/Agua/Hub"
		,"plugins/core/Agua/Package"
		,"plugins/core/Agua/Parameter"
		,"plugins/core/Agua/Project"
		,"plugins/core/Agua/Request"
		
		,"plugins/core/Common/Array"
		,"plugins/core/Common/Sort"
		,"plugins/core/Common/Toast"
		,"plugins/core/Common/Util"
		
		,"plugins/core/Updater"
		,"plugins/core/Conf"
	],

function(declare,
	App,
	Aws,
	Data,
	Feature,
	Group,
	Hub,
	Parameter,
	Project,
	Request,

	Array,
	Sort,
	Toast,
	Util,
	
	Updater,
	Conf
){	
	var Agua = new declare("t.doh.Agua", [
		App,
		Aws, 
		Data,
		Feature,
		Group,
		Hub,
		Parameter,
		Project,
		Request,
	
		Array,
		Sort,
		Toast,
		Util,
		
		Updater,
		Conf
	], {
	
		cookies : 	[],
		
		conf	:	new Conf({}),
	
		updater	:	new Updater({}),

		doPut	:	function (args) {
			console.log("t.unit.doh.Agua.doPut    args: ");
			console.dir({args:args});
			
			if ( args.callback ) {
				console.log("t.unit.doh.Agua.doPut    DOING callback()");
				args.callback();
			}
			
			return args;
		},
		constructor : function (args) {
			this.conf.parent	=	this;
		}
	});
	
	return new Agua({});
}

);
