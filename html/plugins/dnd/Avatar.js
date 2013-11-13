dojo.provide("plugins.dnd.Avatar");

dojo.require("dojo.dnd.Avatar");

dojo.declare("plugins.dnd.Avatar", [dojo.dnd.Avatar], {
	// summary:
	//		Object that represents transferred DnD items visually
	// manager: Object
	//		a DnD manager object

	// methods
	
	construct: function(){

		//console.log("plugins.dnd.Avatar.construct    this.manager.copy: " + this.manager.copy);
		//console.log("plugins.dnd.Avatar.construct    this.manager.nodes[0].data: " + dojo.toJson(this.manager.nodes[0].data));


		// summary:
		//		constructor function;
		//		it is separate so it can be (dynamically) overwritten in case of need

		var avatarType = '';
		if ( this.manager.nodes[0].data != null
			&& this.manager.nodes[0].data.avatarType != null )
			avatarType = this.manager.nodes[0].data.avatarType;

		this.isA11y = dojo.hasClass(dojo.body(),"dijit_a11y");
		var a = dojo.create("table", {
				"class": "dojoDndAvatar " + avatarType,
				style: {
					position: "absolute",
					zIndex:   "1999",
					margin:   "0px"
				}
			}),
			source = this.manager.source, node,
			b = dojo.create("tbody", null, a),

			// DISABLE HEADER AND NUMBER SINCE ONLY ONE ITEM DRAGGED AT A TIME
			//
			//tr = dojo.create("tr", null, b),
			//td = dojo.create("td", null, tr),

			//
			//icon = this.isA11y ? dojo.create("span", {
			//			id : "a11yIcon",
			//			innerHTML : this.manager.copy ? '+' : "<"
			//		}, td) : null,
			//span = dojo.create("span", {
			//	innerHTML: source.generateText ? this._generateText() : ""
			//}, td),

			k = Math.min(5, this.manager.nodes.length), i = 0;
		//
		//// we have to set the opacity on IE only after the node is live
		//dojo.attr(tr, {
		//	"class": "dojoDndAvatarHeader",
		//	style: {opacity: 0.9}
		//});
		
		
		for(; i < k; ++i){
			
			if(source.creator){

				// create an avatar representation of the node
				//try {
					node = source._normalizedCreator(source.getItem(this.manager.nodes[i].id).data, "avatar").node;
				//}
				//catch (err) {
					////console.log("dojo.dnd.Avatar    error with getItem(this.manager.nodes[" + i + "].id)");
					//// or just clone the node and hope it works
					//node = this.manager.nodes[i].cloneNode(true);
					//if(node.tagName.toLowerCase() == "tr"){
					//	// insert extra table nodes
					//	var table = dojo.create("table"),
					//		tbody = dojo.create("tbody", null, table);
					//	tbody.appendChild(node);
					//	node = table;
					//}
				//}
			}
			else
			{
				// or just clone the node and hope it works
				node = this.manager.nodes[i].cloneNode(true);
				if(node.tagName.toLowerCase() == "tr"){
					// insert extra table nodes
					var table = dojo.create("table"),
						tbody = dojo.create("tbody", null, table);
					tbody.appendChild(node);
					node = table;
				}
			}
			node.id = "";
			tr = dojo.create("tr", null, b);
			td = dojo.create("td", null, tr);
			td.appendChild(node);
			dojo.attr(tr, {
				"class": "dojoDndAvatarItem",
				style: {opacity: (9 - i) / 10}
			});
		}
		this.node = a;
	}
	
	//,
	//destroy : function ()
	//{
	//	//console.log("plugins.dnd.Avatar.destroy    DEBUG DO NOTHING");
	//}
	
	
});
