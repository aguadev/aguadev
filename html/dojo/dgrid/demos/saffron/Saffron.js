define([
		"dgrid/List",
		"dgrid/OnDemandGrid",
		"dgrid/Selection",
		"dgrid/Keyboard",
		"dgrid/extensions/ColumnHider",
		"dojo/_base/declare",
		"dojo/_base/array",
		"dojo/json",
		"dgrid/demos/saffron/data",
		"dojo/domReady!"
	],

function (List, Grid, Selection, Keyboard, Hider, declare, arrayUtil, JSON) {

return declare("dgrid.demos.saffron.Saffron",[], {

constructor : function () {

	console.log("Saffron.constructor    BEFORE CREATE window.grid");	

	// Create the main grid to appear below the genre/artist/album lists.
	window.grid = new (declare([Grid, Selection, Keyboard, Hider]))({
		store: songStore,
		columns: {
			project: "Project",
			sample: "Sample",
			lane: "sample"
		}
	}, "grid");
	console.log("Saffron.constructor    AFTER CREATE window.grid");	
	
	this.main();
},

main : function (){
	//console.log("Saffron.main    grid:");
	//console.dir({grid:grid});
	
	// define a List constructor with the features we want mixed in,
	// for use by the three lists in the top region
	var TunesList = declare([List, Selection, Keyboard]);

	//	define our three lists for the top.
	window.projects	= new TunesList({ selectionMode: "single" }, "projects");
	window.samples 	= new TunesList({ selectionMode: "single" }, "samples");
	window.lanes= new TunesList({ selectionMode: "single" }, "lanes");

	//	create the unique lists and render them
	console.log("songStore.data:");
	console.dir({data:songStore.data});
	var g = this.unique(arrayUtil.map(songStore.data, function(item){ return item.project; }));
	var samplesArray = this.unique(arrayUtil.map(songStore.data, function(item){ return item.sample; }));
	var lanesArray = this.unique(arrayUtil.map(songStore.data, function(item){ return item.lane; }));
	console.log("projects, g:")
	console.dir({g:g});

	g.unshift("All (" + g.length + " Project" + (g.length != 1 ? "s" : "") + ")");
	samplesArray.unshift("All (" + samplesArray.length + " Sample" + (samplesArray.length != 1 ? "s" : "") + ")");
	lanesArray.unshift("All (" + lanesArray.length + " Lane" + (lanesArray.length != 1 ? "s" : "") + ")");

	console.log("BEFORE projects.renderArray(g)");
	projects.renderArray(g);
	console.log("BEFORE samples.renderArray(g)");
	samples.renderArray(samplesArray);
	console.log("BEFORE lanes.renderArray(g)");
	lanes.renderArray(lanesArray);
	console.log("AFTER lanes.renderArray(g)");

	var currentProject; // updated on genre select

	//	start listening for selections on the lists.
	var thisObject = this;
	projects.on("dgrid-select", function(e) {
		//	filter the lanes, samples and grid
		var
			row = e.rows[0],
			filter = currentProject = row.data,
			samplesArray;
		if(row.id == "0"){
			//	remove filtering
			samplesArray = thisObject.unique(arrayUtil.map(songStore.data, function(item){ return item.sample; }));
			grid.query = {};
		} else {
			//	create filtering
			samplesArray = thisObject.unique(arrayUtil.map(arrayUtil.filter(songStore.data, function(item){ return item.project == filter; }), function(item){ return item.sample; }));
			grid.query = { "Project": filter };
		}
		samplesArray.unshift("All (" + samplesArray.length + " Sample" + (samplesArray.length != 1 ? "s" : "") + ")");
		
		console.log("BEFORE samples.refresh");
		samples.refresh();	//	clear contents
		samples.renderArray(samplesArray);
		samples.select(0); //	reselect "all", triggering lanes+grid refresh
		console.log("AFTER samples.select");
	});

	samples.on("dgrid-select", function(e){
		//	filter the lanes, grid
		var row = e.rows[0];
		var filter = row.data;
		var lanesArray;
		if(row.id == "0"){
			if(projects.selection[0]){
				//	remove filtering entirely
				lanesArray = thisObject.unique(arrayUtil.map(songStore.data, function(item){ return item.lane; }));
			} else {
				//	filter only by project
				lanesArray = thisObject.unique(arrayUtil.map(arrayUtil.filter(songStore.data, function(item){ return item.project == currentProject; }), function(item){ return item.lane; }));
			}
			delete grid.query.sample;
		} else {
			//	create filter based on sample
			lanesArray = thisObject.unique(arrayUtil.map(arrayUtil.filter(songStore.data, function(item){ return item.sample == filter; }), function(item){ return item.lane; }));
			grid.query.sample = filter;
		}
		lanesArray.unshift("All (" + lanesArray.length + " Lane" + (lanesArray.length != 1 ? "s" : "") + ")");

		lanes.refresh(); //	clear contents
		lanes.renderArray(lanesArray);
		lanes.select(0); //	reselect "all" item, triggering grid refresh
	});

	lanes.on("dgrid-select", function(e){
		
		console.log("DOING lanes.on");

		//	filter the grid
		var row = e.rows[0];
		console.log("Saffron.main    e.rows: ");
		console.dir({e_rows:e.rows});
		
		var filter = row.data;
		console.log("Saffron.main    filter: " + filter);

		console.log("Saffron.main    row.id: " + row.id);
		if(row.id == "0"){
			
			console.log("Saffron.main    DOING delete grid.query.lane");
			// show all lanes
			delete grid.query.lane;
		} else {
			grid.query.lane = filter;
		}
		
		console.log("Saffron.main    filter: " + filter);
		console.log("Saffron.main    grid: " + grid);
		console.dir({grid:grid});
		
		console.log("DOING grid.refresh");
		grid.refresh();
		console.log("AFTER grid.refresh");
	});

	//	set the initial selections on the lists.
	projects.select(0);

},	//	end "main" function

unique : function (arr){
	//	create a unique list of items from the passed array
	//	(removing duplicates).  This is quick and dirty.

	//	first, set up a hashtable for unique objects.
	var obj = {};
	for(var i=0,l=arr.length; i<l; i++){
		if(!(arr[i] in obj)){
			obj[arr[i]] = true;
		}
	}

	//	now push the unique objects back into an array, and return it.
	var ret = [];
	for(var p in obj){
		ret.push(p);
	}
	ret.sort();
	
	console.log("unique    returning ret:" + JSON.stringify(ret));
	//console.dir({ret:ret});
	return ret;
}



}); 	//	end declare ***return

//ready(function(){
//	return new dgrid.demos.saffron.Saffron;
//});

});	//	end define
