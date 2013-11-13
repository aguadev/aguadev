define(
	[
		"dojo/_base/declare"
		,"plugins/core/Agua/Data"
		,"plugins/core/Agua/Feature"
		,"plugins/core/Agua/Parameter"
		,"plugins/core/Agua/Project"
		,"plugins/core/Agua/Request"
		,"plugins/core/Common/Array"
		,"plugins/core/Common/Sort"
		,"plugins/core/Common/Util"
	],

function(declare, Data, Feature, Parameter, Project, Request, Array, Sort, Util){	
	var Agua = new declare("t.doh.Agua", [Data, Feature, Parameter, Project, Request, Array, Sort, Util], {
	
		cookies : []
	});

	return new Agua({});
}

);
