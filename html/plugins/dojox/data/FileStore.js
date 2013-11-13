dojo.provide("plugins.dojox.data.FileStore");

dojo.require("dojox.data.FileStore");

dojo.declare("plugins.dojox.data.FileStore", [dojox.data.FileStore], {
// path: string
// full path to file
path : '',

// putdata: object
// data for xhrPut
putData: null,

////}}}}	

constructor: function (args){
	this.inherited(arguments);

	//console.log("FileStore.constructor    caller: " + this.constructor.caller.nom);
	
	//console.log("FileStore.constructor    args:");
	//console.dir({args:args});
	if ( ! args ) {
		//console.log("FileStore.constructor    args not defined. Returning:");
		return;
	}
	this.core 		= 	args.core;
	this.path		=	args.path;
	this.putData	=	args.putData;
	this.parentPath	=	args.parentPath;

	// SET _processResult CALLBACK
	this.processResultCallback = dojo.hitch(this, "_processResult");
},
_assertIsItem: function(/* item */ item){
	// summary:
	//      This function tests whether the item passed in is indeed an item in the store.
	// item:
	//		The item to test for being contained by the store.

	//console.log("plugins.dojox.data.FileStore._assertIsItem    caller: " + this._assertIsItem.caller.nom);
	////console.log("plugins.dojox.data.FileStore._assertIsItem    item: " + dojo.toJson(item));

	if(!this.isItem(item)){
		//console.warn("dojox.data.FileStore: a function was passed an item argument that was not an item");
	
		//throw new Error("dojox.data.FileStore: a function was passed an item argument that was not an item");
	}
},
_assertIsAttribute: function(/* attribute-name-string */ attribute){
	// summary:
	//		This function tests whether the item passed in is indeed a valid 'attribute' like type for the store.
	// attribute:
	//		The attribute to test for being contained by the store.
	if(typeof attribute !== "string"){
		throw new Error("dojox.data.FileStore: a function was passed an attribute argument that was not an attribute name string");
	}
},
loadItem: function(keywordArgs){
	// summary:
	//      See dojo.data.api.Read.loadItem()
	var item = keywordArgs.item;
	var self = this;
	var scope = keywordArgs.scope || dojo.global;

	var content = {};

	if(this.options.length > 0){
		content.options = dojo.toJson(this.options);
	}

	if(this.pathAsQueryParam){
		content.path = item.parentPath + this.pathSeparator + item.name;
	}

	var xhrData = {
		url: this.pathAsQueryParam? this.url : this.url + "/" + item.parentPath + "/" + item.name,
		handleAs: "json-comment-optional",
		content: content,
		preventCache: this.urlPreventCache,
		failOk: this.failOk
	};

	var deferred = dojo.xhrGet(xhrData);
	deferred.addErrback(function(error){
			if(keywordArgs.onError){
				keywordArgs.onError.call(scope, error);
			}
	});
	
	deferred.addCallback(function(data){
		delete item.parentPath;
		delete item._loaded;
		dojo.mixin(item, data);
		self._processItem(item);
		if(keywordArgs.onItem){
			keywordArgs.onItem.call(scope, item);
		}
	});
},
isItem: function(item){
	// summary:
	//      See dojo.data.api.Read.isItem()
	//console.log("plugins.dojox.data.FileStore.isItem    caller: " + this.isItem.caller.nom);
	////console.log("plugins.dojox.data.FileStore.isItem    item: " + dojo.toJson(item));
	
	if(item && item[this._storeRef] === this){
		return true;
	}
	return false;
},
close: function(request){
	// summary:
	//      See dojo.data.api.Read.close()
},
fetch: function(request){
	//console.log("plugins.dojox.data.FileStore.fetch    caller: " + this.fetch.caller.nom);
	//console.log("plugins.dojox.data.FileStore.fetch    request: " );
	//console.dir({request:request});

	request = request || {};
	if(!request.store){
		request.store = this;
	}

	var self = this;
	var scope = request.scope || dojo.global;
	
	//console.log("plugins.dojox.data.FileStore.fetch    this.path: " );
	//console.dir({this_path:this.path});
	//console.dir({this_parentPath:this.parentPath});
	//console.dir({this_name:this.name});

	//console.log("plugins.dojox.data.FileStore.fetch    BEFORE request.query: ");
	//console.dir({request_query:request.query});

	// Generate request parameters
	var reqParams = {};
	if ( request.query ) {
		//request.query = request.query.replace(/^\//, '');
		reqParams.query = request.query;
	}
	//console.log("plugins.dojox.data.FileStore.fetch    AFTER request.query: " );
	//console.dir({request_query:request.query});

	var putData = this.putData;
	if ( request.query )
		putData.query = request.query;

	//console.log("plugins.dojox.data.FileStore.fetch    putData:");
	//console.dir({putData:putData});

	var callback = this.processResultCallback;
	Agua.getFileSystem(putData, callback, request);

},
fetchItemByIdentity: function(keywordArgs){
	// summary:
	//      See dojo.data.api.Read.loadItem()
	var path = keywordArgs.identity;
	var self = this;
	var scope = keywordArgs.scope || dojo.global;

	var content = {};

	if(this.options.length > 0){
		content.options = dojo.toJson(this.options);
	}

	if(this.pathAsQueryParam){
		content.path = path;
	}
	
	var xhrData = {
		url: this.pathAsQueryParam? this.url : this.url + "/" + path,
		handleAs: "json-comment-optional",
		content: content,
		preventCache: this.urlPreventCache,
		failOk: this.failOk
	};

	var deferred = dojo.xhrGet(xhrData);
	deferred.addErrback(function(error){
			if(keywordArgs.onError){
				keywordArgs.onError.call(scope, error);
			}
	});
	
	deferred.addCallback(function(data){
		var item = self._processItem(data);
		if(keywordArgs.onItem){
			keywordArgs.onItem.call(scope, item);
		}
	});
},
_processResult: function(data, request){
	//console.log("FileStore._processResult    caller: " + this._processResult.caller.nom);
	//console.log("FileStore._processResult    data: ")
	//console.dir({data:data});
	//console.log("FileStore._processResult    request: ")
	//console.dir({request:request});
	
	if ( ! request ) {
		//console.log("FileStore._processResult    Returning because request is null");
		return;
	}

	 var scope = request.scope || dojo.global;
	 try{

		 //If the data contains a path separator, set ours
		 if(data.pathSeparator){
			 this.pathSeparator = data.pathSeparator;
		 }

	//console.log("FileStore._processResult    ONE");

			
		 //Invoke the onBegin handler, if any, to return the
		 //size of the dataset as indicated by the service.
		 if(request.onBegin){
			 request.onBegin.call(scope, data.total, request);
		 }

	//console.log("FileStore._processResult    TWO");

		 //Now process all the returned items thro
		 var items = this._processItemArray(data.items);

		 if(request.onItem){
			var i;
			for(i = 0; i < items.length; i++){
				request.onItem.call(scope, items[i], request);
			}
			items = null;
		 }

	//console.log("FileStore._processResult    THREE");

		 if(request.onComplete){
			
		////console.log("FileStore._processResult    items:");
		////console.dir({items:items});
		////console.log("FileStore._processResult    request.onComplete: " + request.FileStore);
		////console.log("FileStore._processResult    request.onComplete.toString(): " + request.onComplete.toString());
		//
		////console.log("FileStore._processResult    Doing request.onComplete.call(scope, items, request)");
		
			 request.onComplete.call(scope, items, request);
		 }
		 
		 
	//console.log("FileStore._processResult    FOUR");

	 }catch (e){
		 if(request.onError){
			 request.onError.call(scope, e, request);
		 }else{
			 //console.log(e);
		 }
	 }
	 
	////console.log("FileStore._processResult    END");
	////console.log("FileStore._processResult    this.core.folders: " + this.core.folders);
	////console.log("FileStore._processResult    Doing this.core.folders.roundRobin(): ");
	//this.core.folders.roundRobin();
},
_processItemArray : function(itemArray) {
	// Internal function for processing an array of items for return.
	
	if ( ! itemArray ) {
		//console.log("plugins.dojox.data.FileStore._processItemArray    itemArray is null. Returning empty array []");
		return [];
	}
	
	var i;
	for(i = 0; i < itemArray.length; i++){
		this._processItem(itemArray[i]);
	}
	return itemArray;
},
_processItem: function(item){
	//	summary:
	//		Internal function for processing an item returned from the store.
	//		It sets up the store ref as well as sets up the attributes necessary
	//		to invoke a lazy load on a child, if there are any.
	if(!item){return null;}
	item[this._storeRef] = this;
	if(item.children && item.directory){
		if(dojo.isArray(item.children)){
			var children = item.children;
			var i;
			for(i = 0; i < children.length; i++ ){
				var name = children[i];
				if(dojo.isObject(name)){
					children[i] = this._processItem(name);
				}else{
					children[i] = {name: name, _loaded: false, parentPath: item.path};
					children[i][this._storeRef] = this;
				}
			}
		}else{
			delete item.children;
		}
	}
	return item;
}


});

