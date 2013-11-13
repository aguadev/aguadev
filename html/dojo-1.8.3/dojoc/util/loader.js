dojo.provide("dojoc.util.loader")

//when dojo is loaded, it will remove all registered onload functions, let's 
//hijack the function and save a copy of the register onload handlers so we
//can add them back when the page is reloaded.
if(!dojo._postLoad){
var dojo_loaded=dojo.loaded;
dojo.loaded=function(){
	dojo._initLoaders=dojo._loaders.slice();
	dojo.loaded=dojo_loaded;
	dojo.loaded.apply(dojo,arguments);
};

dojo.reloadPage=function(){
	// summary:
	//		unload the current page and destory all dijits, reset the body content
	//		and call any onloader functions registered when the page first loaded.
	//		Use this function after you reload some modules.

	//console.log("dojoc.util.loader.reloadPage    dojoc.util.loader.reloadPage()");
	
	//call any onunload handlers
	dojo.windowUnloaded();
	//console.log("dojoc.util.loader.reloadPage    AFTER dojo.windowUnloaded()");

	//destroy all dijits
	dijit.registry.forEach(function(widget){ widget.destroy(); });
	//console.log("dojoc.util.loader.reloadPage    AFTER dijit.registry.forEach(function(widget){ widget.destroy(); })");

	//request the current page and retrieve the content between <body> tag, and reset
	//document.body
	dojo.xhrGet({url:window.location.href,sync:true,handleAs:'text',
		handle: function(data){
			var body=data.match(/<body[^>]*>([\S\s]+)<\/body>/)[1];
			document.body.innerHTML=body;
		}
	});
	//console.log("dojoc.util.loader.reloadPage    AFTER dojo.xhrGet");

	//add back onload handlers registered before the initial page load
	dojo._loaders = dojo._initLoaders.slice(0);
	//console.log("dojoc.util.loader.reloadPage    AFTER dojo._loaders = dojo._initLoaders.slice(0);");

	dojo.loaded();
	//console.log("dojoc.util.loader.reloadPage    AFTER dojo.loaded()");

};
}else{
	dojo.reloadPage=function(){
		//console.error('In order to use dojo.reloadPage, this module has to be included in the intial page load');
	}
}
dojo.reload=function(d,nocheck){
	// summary:
	//		reload a module. The module to load can be a partial string of a loaded module, 
	//		and if there is only one matching module, it will be loaded. If there are
	//		multiple modules matches the partial name provided, it will list all possible
	//		modules and error out. If the module to reload references any template (that 
	//		is using templatePath), the template cache in dijit will be reset, so that next
	//		time the dijit is created, the latest template will be pulled directly from 
	//		server. F6 will reload the last reloaded module. (F6 is only available after the
	//		first dojo.reload call)
	//console.log("dojoc.util.loader.reload    dojoc.util.loader.reload(d, nocheck)");
	//console.log("dojoc.util.loader.reload    d: " + d);
	//console.log("dojoc.util.loader.reload    nocheck: " + nocheck);

	if(!dojo._loadedModules[d]){
		//see if d is a partial name

		//console.log("dojoc.util.loader.reload    !dojo._loadedModules[d]");
		//console.log("dojoc.util.loader.reload    Doing 'see if d is a partial name'");

		var partialmatch=[];
		for(var m in dojo._loadedModules){
			if(m.indexOf(d)>=0){
				partialmatch.push(m);
			}
		}
		if(partialmatch.length==1){
			//console.info(d, 'is a partial match to',partialmatch[0]);
			d=partialmatch[0];
		}else if(partialmatch.length>1){
			//console.error("more than one modules match the partial name \"",d,"\" try a more specific module name",partialmatch);
			return;
		}
	}
	
	//remove the module namespace from its parent namespace
	var sym=d.split('.');
	if(sym.length>1){
		var pname=sym.slice(0,-1).join('.');
		var prop=sym[sym.length-1];
		var parent=dojo.getObject(pname,false);
		if(parent){
			//console.log('delete property',prop,'on object',pname,':',delete parent[prop]);
		}
	}
 
	//remove _loadedModules entry so that dojo.require will re-load it
	delete dojo._loadedModules[d];
	//console.log("dojoc.util.loader.reload    AFTER delete dojo._loadedModules[d]");
 
	//tidy up _loadedUrls so that dojo._getText will reload it
	sym=dojo._getModuleSymbols(d);
	//console.log("dojoc.util.loader.reload    AFTER sym=dojo._getModuleSymbols(d)");

	var relpath = sym.join("/") + '.js';
	//copied from dojo._loadUri
	var uri = ((relpath.charAt(0) == '/' || relpath.match(/^\w+:/)) ? "" : dojo.baseUrl) + relpath;
	//console.log("dojoc.util.loader.reload    AFTER var uri = ...");
 
	delete dojo._loadedUrls[uri];
	dojo._loadedUrls.splice(dojo.indexOf(dojo._loadedUrls,uri),1);
	//console.log("dojoc.util.loader.reload    AFTER dojo._loadedUrls.splice(dojo.indexOf(dojo._loadedUrls,uri),1)");
 
	//set cacheBust to make sure we load latest file
	dojo.config.cacheBust=+new Date;
 
 	//F6 shortcut support
	dojo._loadreloaded=d;
	if(!dojo._reloadhotkey){
		dojo._reloadhotkey=dojo.connect(document.documentElement,'onkeydown',function(e){
			if(e.keyCode===dojo.keys.F6){
				dojo.reload(dojo._loadreloaded);
				dojo.stopEvent(e);
			}
		});
	}
	//console.log("dojoc.util.loader.reload    AFTER dojo._reloadhotkey=dojo.connect(...)");
	
	//hijack dojo._getText to search for templatePath and reset any cache if any are found
	var _getText = dojo._getText;
	//copied from util/buildscripts/jslib/buildUtil.js
	var interningDojoUriRegExpString = "(((templatePath|templateCssPath)\\s*(=|:)\\s*)|dojo\\.uri\\.cache\\.allow\\(\\s*)dojo\\.(module)?Url\\(\\s*?[\\\"\\']([\\w\\.\\/]+)[\\\"\\'](([\\,\\s]*)[\\\"\\']([\\w\\.\\/]*)[\\\"\\'])?\\s*\\)",
		interningGlobalDojoUriRegExp = new RegExp(interningDojoUriRegExpString, "g");


	dojo._getText= dojo.hitch(this, function(){

	//console.log("dojoc.util.loader.reload    DOING dojo._getText(...)");
	var d = dojo;
	//console.log("dojoc.util.loader.reload    d: " + d);
	//console.log("dojoc.util.loader.reload    this: " + this);
	////console.dir(d);

		//var content=_getText.apply(dojo,arguments);
		var content=_getText.apply(dojo,arguments);
		//console.log("dojoc.util.loader.reload    AFTER content=_getText.apply(dojo,arguments)");

		var m=content.match(interningGlobalDojoUriRegExp);
		if(m){
			dojo.forEach(m,function(mi){

		//console.log("dojoc.util.loader.reload    DOING dojo._getText   mi: " + mi);

				if(!mi.indexOf('templatePath')){
					var file=dojo.trim(mi.split(':',2)[1]);
					var url=eval(file);
					url=url.toString();
					if(dijit._Templated._templateCache[url]){
						//console.info('Clearing dijit template cache for',url);
						delete dijit._Templated._templateCache[url];
					}
				}
			});
		}
		
		//console.log('dojo._getText',m);

		return content;
	});


	//console.info('reloading module',d);

	
	//console.log("dojoc.util.loader.reload    BEFORE dojo['require'](d,nocheck)");
	//console.log("dojoc.util.loader.reload    d: " + d);
	
	dojo['require'](d,nocheck);
	//console.log("dojoc.util.loader.reload    AFTER dojo['require'](d,nocheck)");

	//set the original _getText back to where it was
	dojo._getText = _getText;
};

dojo.reloadCss=function(cssfile){
	// summary:
	//		reload a css file. if cssfile is '*', all css files are reloaded.
	//		otherwise, any css files which url contains cssfile will be reloaded.
	
	//basically copied from ReCSS in firebug lite in dojo core
	cssfile = cssfile || '*';

	console.log("dojoc.util.loader.reloadCss    cssfile: " + cssfile);

	var links=document.getElementsByTagName('link'),toreload=[];
	dojo.forEach(links,function(l){

	console.log("dojoc.util.loader.reloadCss    links.forEach    l: " + l);

		if((l.getAttribute('type')=='text/css' || l.rel.toLowerCase().indexOf('stylesheet')>=0) && l.href){
			var h=l.getAttribute('href').replace(/(&|%5C|\?)forceReload=\d+/,'');
			if(cssfile==='*' || h.indexOf(cssfile)>=0){
				toreload.push(l);
			}
		}
	});

	
	dojo.forEach(toreload,function(l){

	console.log("dojoc.util.loader.reloadCss    toreload.forEach    cssfile: " + cssfile);

		var h=l.getAttribute('href').replace(/(&|%5C|\?)forceReload=\d+/,'');
		//console.log('reloading css',h);
		h=h+(h.indexOf('?')>=0?'&':'?')+'forceReload='+(+new Date);
		l.setAttribute('href',h);
	});
};
