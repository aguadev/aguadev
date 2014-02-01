define([
	"dojo/_base/declare",
	"dojo/on",
],

function (
	declare,
	on
) {

/////}}}}}

return declare("plugins.core.Common.Util",
	[], {

/////}}}}}
cookie : function (name, value) {

// SET OR GET COOKIE-CONTAINED USER ID AND SESSION ID

	//console.log("Util.core.Common.Util.cookie     plugins.core.Agua.cookie(name, value)");
	//console.log("Util.core.Common.Util.cookie     name: " + name);
	//console.log("Util.core.Common.Util.cookie     value: " + value);		
	if ( value != null ) {
		this.cookies[name] = value;
	}
	else if ( name != null ) {
		return this.cookies[name];
	}

	//console.log("Util.core.Common.Util.cookie     this.cookies: " + dojo.toJson(this.cookies));

	return 0;
},
setLoadPanels : function (args) {
	if ( ! args.inputs )	return;
	
	this.inputs = args.inputs;
	var array = args.inputs.split(";");
	console.log("Common.Util.setLoadPanels    array: ");
	console.dir({array:array});

	var loadPanels = {};
	for ( i = 0; i < array.length + 1; i++ ) {
		console.log("Common.Util.setLoadPanels    array: ");
		loadPanels[array[i]] = 1;
	}
	console.log("Common.Util.setLoadPanels    loadPanels: ");
	console.dir({loadPanels:loadPanels});
	
	this.loadPanels = loadPanels;
},
// XHR
doPut : function (inputs) {
	return this.doXhr(inputs, "xhrPut");
},
doGet : function (inputs) {
	return this.doXhr(inputs, "xhrGet");
},
doXhr : function (inputs, xhrType) {
	console.log("    Common.Util.doXhr    xhrType: " + xhrType);
	console.log("    Common.Util.doXhr    inputs: ");
	console.dir({inputs:inputs});
	var callback = function (){}
	if ( inputs.callback != null )	callback = inputs.callback;
	//console.log("    Common.Util.doXhr    inputs.callback: " + inputs.callback);
	var doToast = true;
	if ( inputs.doToast != null )	doToast = inputs.doToast;
	var url = inputs.url;
	url += "?";
	url += Math.floor(Math.random()*100000);
	var query = inputs.query;
	var timeout = inputs.timeout ? inputs.timeout : null;
	var handleAs = inputs.handleAs ? inputs.handleAs : "json";
	var sync = inputs.sync ? inputs.sync : false;
	//console.log("    Common.Util.doXhr     doToast: " + doToast);
	
	// SEND TO SERVER
	dojo[xhrType](
		{
			url: url,
			contentType: "text",
			preventCache : true,
			sync: sync,
			handleAs: handleAs,
			putData: dojo.toJson(query),
			timeout: timeout,
			load: function(response, ioArgs) {
				console.log("    Common.Util.doXhr    response: ");
				console.dir({response:response});

				if ( response.error ) {
					if ( doToast ) {
						console.log("    Common.Util.doXhr    DOING Agua.toastMessage ERROR");
						Agua.toastMessage({
							message: response.error,
							type: "error",
							duration: 10000
						});
					}
				}
				else {
					if ( response.status ) {
						if ( doToast ) {
						console.log("    Common.Util.doXhr    DOING Agua.toastMessage STATUS");
							Agua.toastMessage({
								message: response.status,
								type: "warning",
								duration: 10000
							})
							if ( Agua.loader != null )	Agua.loader._hide();
						}
					}
					
					//console.log("    Common.Util.doXhr    callback: " + callback);
					if ( callback ) {
						console.log("    Common.Util.doXhr    DOING callback(response, inputs)");
						callback(response, inputs);
					}
				}
			},
			error: function(response, ioArgs) {
				console.log("    Common.Util.doXhr    Error with put. Response: " + response);
				return response;
			}
		}
	);	
},
// CLASS NAME
getClassName : function (object) {
	console.log("    Common.Util.getClassName    object: " + object);
	console.dir({object:object});
	var className = new String(object);
	console.log("    Common.Util.getClassName    className: " + className);
	
	if ( className.match(/^\[Widget\s+(\S+),/) ) {
		return className.match(/^\[Widget\s+(\S+),/)[1];
	}
	else if ( className.match(/^\[object/) ) {
		if ( object.declareClass ) {
			return object.declaredClass.replace("\.", "_");
		}
		else if ( object.type ) {
			return object.type
		}
		else if ( object.tagName ) {
			return object.tagName
		}
		else {
			return ""
		}
	}

	return "";
},
// MESSAGE
showMessage : function (message, putData) {
	console.log("    Common.Util.showMessage    Polling message: " + message)	
},
// DOWNLOAD
downloadFile : function (filepath, username) {
	//console.log("ParameterRow.downloadFile     plugins.workflow.ParameterRow.downloadFile(filepath, shared)");
	//console.log("ParameterRow.downloadFile     filepath: " + filepath);
	var query = "?mode=downloadFile";

	// SET requestor = THIS_USER IF PROVIDED
	if ( username != null )
	{
		query += "&username=" + username;
		query += "&requestor=" + Agua.cookie('username');
	}
	else
	{
		query += "&username=" + Agua.cookie('username');
	}

	query += "&sessionid=" + Agua.cookie('sessionid');
	query += "&filepath=" + filepath;
	//console.log("ParameterRow.downloadFile     query: " + query);
	
	var url = Agua.cgiUrl + "download.cgi";
	//console.log("ParameterRow.downloadFile     url: " + url);
	
	var args = {
		method: "GET",
		url: url + query,
		handleAs: "json",
		timeout: 10000,
		load: this.handleDownload
	};
	console.log("ParameterRow.downloadFile     args: ", args);

	console.log("ParameterRow.downloadFile     Doing dojo.io.iframe.send(args))");
	var value = dojo.io.iframe.send(args);
},
// ATTACHPANE
attachPane : function (childNode) {
	if ( ! childNode ) {
		childNode = this.mainTab;
	}

	console.log("Common.Util.attachPane    this: " + this);
	console.dir({this:this});
	console.log("Common.Util.attachPane    this.mainTab: " + this.mainTab);
	console.dir({this_mainTab:this.mainTab});
	console.log("Common.Util.attachPane    childNode: " + childNode);
	console.dir({childNode:childNode});
	console.log("Common.Util.attachPane    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
	
	if ( ! this.attachPoint ) {
		console.log("Common.Util.attachPane    this.attachPoint is not defined. Returning");
		return;
	}

	if ( this.attachPoint.addChild ) {
		console.log("Common.Util.attachPane    DOING this.attachPoint.addChild");
		this.attachPoint.addChild(childNode);
		this.attachPoint.selectChild(childNode);
	}
	else if ( this.attachPoint.appendChild ) {
		if ( childNode.domNode ) {
			console.log("Common.Util.attachPane    DOING this.attachPoint.appendChild(childNode.domNode)");

			this.attachPoint.appendChild(childNode.domNode);
		}
		else {
			console.log("Common.Util.attachPane    DOING this.attachPoint.appendChild(childNode)");

			this.attachPoint.appendChild(childNode);
		}
	}	
	
	console.log("Common.Util.attachPane    AFTER this.attachPoint.addChild");
},
// CSS
loadCSS : function (cssFiles) {
// LOAD EITHER this.cssFiles OR A SUPPLIED ccsFiles ARRAY OF FILES ARGUMENT

	//console.log("    Common.Util.loadCSS");
	
	if ( cssFiles == null )
	{
		cssFiles = this.cssFiles;
	}
	//console.log("    Common.Util.loadCSS     cssFiles: " +  dojo.toJson(cssFiles, true));
	
	// LOAD CSS
	for ( var i in cssFiles )
	{
		//console.log("    Common.Util.loadCSS     Loading CSS file: " + this.cssFiles[i]);
		
		this.loadCSSFile(cssFiles[i]);
	}
},
loadCSSFile : function (cssFile) {
// LOAD A CSS FILE IF NOT ALREADY LOADED, REGISTER IN this.loadedCssFiles

	//console.log("    Common.Util.loadCSSFile    *******************");
	//console.log("    Common.Util.loadCSSFile    plugins.core.Common.loadCSSFile(cssFile)");
	//console.log("    Common.Util.loadCSSFile    cssFile: " + cssFile);
	//console.log("    Common.Util.loadCSSFile    this.loadedCssFiles: " + dojo.toJson(this.loadedCssFiles));

	if ( Agua.loadedCssFiles == null || ! Agua.loadedCssFiles )
	{
		//console.log("    Common.Util.loadCSSFile    Creating Agua.loadedCssFiles = new Object");
		Agua.loadedCssFiles = new Object;
	}
	
	if ( ! Agua.loadedCssFiles[cssFile] )
	{
		//console.log("    Common.Util.loadCSSFile    Loading cssFile: " + cssFile);
		
		var cssNode = document.createElement('link');
		cssNode.type = 'text/css';
		cssNode.rel = 'stylesheet';
		cssNode.href = cssFile;
		document.getElementsByTagName("head")[0].appendChild(cssNode);

		Agua.loadedCssFiles[cssFile] = 1;
	}
	else
	{
		//console.log("    Common.Util.loadCSSFile    No load. cssFile already exists: " + cssFile);
	}

	//console.log("    Common.Util.loadCSSFile    Returning Agua.loadedCssFiles: " + dojo.toJson(Agua.loadedCssFiles));
	
	return Agua.loadedCssFiles;
},
// RANDOM
randomiseUrl : function (url) {
	url += "?dojo.preventCache=1266358799763";
	url += Math.floor(Math.random()*1000000000000);
	
	return url;
},
killPopup : function (combo) {
	//console.log("    Common.Util.killPopup    core.Common.killPopup(combo)");
	var popupId = "widget_" + combo.id + "_dropdown";
	var popup = dojo.byId(popupId);
	if ( popup != null )
	{
		var popupWidget = dijit.byNode(popup.childNodes[0]);
		dijit.popup.close(popupWidget);
	}	
},
// FETCH
fetchSyncJson : function(url, timeout) {
	if ( ! timeout )	timeout = 5000;

    var jsonObject;
    dojo.xhrGet({
        // The URL of the request
        url: url,
		// Make synchronous so we wait for the data
		sync: true,
		// Long timeout
		timeout: timeout,
        // Handle as JSON Data
        handleAs: "json",
        // The success callback with result from server
        load: function(response) {
			jsonObject = response;
	    },
        // The error handler
        error: function() {
            console.log("t.doh.util.fetchJson    Error, response: " + dojo.toJson(response));
        }
    });

	return jsonObject;
},
fetchSyncText : function(url, timeout) {
	if ( ! timeout )	timeout = 5000;

    var jsonObject;
    dojo.xhrGet({
        // The URL of the request
        url: url,
		// Make synchronous so we wait for the data
		sync: true,
		// Long timeout
		timeout: timeout,
        // Handle as JSON Data
        handleAs: "text",
        // The success callback with result from server
        load: function(response) {
			jsonObject = response;
	    },
        // The error handler
        error: function() {
            console.log("t.doh.util.fetchJson    Error, response: " + dojo.toJson(response));
        }
    });

	return jsonObject;
},
// SELECT LIST
setSelect : function(select, optionsList) {
	console.log("Common.Util.setSelect    select:");
	console.dir({select:select});
	console.log("Common.Util.setSelect    optionsList: ");
	console.dir({optionsList:optionsList});
	

	var options = this.setOptions(optionsList);
	select.options 	=	options;

	select.startup();	
},
setOptions : function (array) {
	var options = [];
	if ( ! array || array.length == 0 )	return options;

	for ( var i = 0; i < array.length; i++ ) {
		var hash = {
			label	:	array[i],
			value	:	array[i]
		};
		if ( i == 0 ) {
			hash.selected	=	true;
		}
		
		options.push(hash);
	}
	
	return options;
},
// LISTENERS
setOnkeyListener : function (object, key, callback) {
	console.log("Common.Util.setOnKeyListener    object: " + object);
	console.log("Common.Util.setOnKeyListener    key: " + key);

	on(object, "keypress", dojo.hitch(this, "_onKey", key, callback));
},
_onKey : function(key, callback, event){
	//console.log("Common.Util._onKey    key: " + key);
	//console.log("Common.Util._onKey    callback: " + callback);
	
	var eventKey = event.keyCode;			
	//console.log("Common.Util._onKey    eventKey: " + eventKey);
	if ( eventKey == key ) {
		this[callback]();
	}
}

}); //	end declare

});	//	end define

// TOGGLE
//toggle : function (togglePoint) {
//	if ( togglePoint.style.display == 'inline-block' )	{
//		togglePoint.style.display='none';
//		dojo.removeClass(this.toggler, "open");
//		dojo.addClass(this.toggler, "closed");
//	}
//	else {
//		togglePoint.style.display = 'inline-block';
//		dojo.removeClass(this.toggler, "closed");
//		dojo.addClass(this.toggler, "open");
//	}
//},

