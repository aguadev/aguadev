define(
	[
		"dojo/_base/declare"
		,"plugins/core/Agua/Aws"
		,"plugins/core/Agua/Data"
		,"plugins/core/Agua/Feature"
		,"plugins/core/Agua/Hub"
		,"plugins/core/Agua/Parameter"
		,"plugins/core/Agua/Project"
		,"plugins/core/Agua/Request"
		,"plugins/core/Common/Array"
		,"plugins/core/Common/Sort"
		,"plugins/core/Common/Toast"
		,"plugins/core/Common/Util"
	],

//function(declare, Data, Feature, Parameter, Project, Request, Array, Sort, Util){	
//	var Agua = new declare("t.doh.Agua", [Data, Feature, Parameter, Project, Request, Array, Sort, Util], {


function(declare,
	Aws,
	Data,
	Feature,
	Hub,
	Parameter,
	Project,
	Request,

	Array,
	Sort,
	Toast,
	Util
){	
	var Agua = new declare("t.doh.Agua", [
		Aws, 
		Data,
		Feature,
		Hub,
		Parameter,
		Project,
		Request,
	
		Array,
		Sort,
		Toast,
		Util
	], {
	
		cookies : []
	});

	return new Agua({});
}

);
