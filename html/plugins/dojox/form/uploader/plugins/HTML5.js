dojo.provide("plugins.dojox.form.uploader.plugins.HTML5");

dojo.declare("plugins.dojox.form.uploader.plugins.HTML5", [dojox.form.uploader.plugins.HTML5], {
	createXhr: function(){
		
		console.log("plugins.dojox.form.Uploader.HTML5.createXhr()");

		var xhr = new XMLHttpRequest();
		var timer;
        xhr.upload.addEventListener("progress", dojo.hitch(this, "_xhrProgress"), false);
        xhr.addEventListener("load", dojo.hitch(this, "_xhrProgress"), false);
        xhr.addEventListener("error", dojo.hitch(this, function(evt){
			this.onError(evt);
			clearInterval(timer);
		}), false);
        xhr.addEventListener("abort", dojo.hitch(this, function(evt){
			this.onAbort(evt);
			clearInterval(timer);
		}), false);
        xhr.onreadystatechange = dojo.hitch(this, function() {
			if (xhr.readyState === 4) {
				console.info("plugins.dojox.form.uploader.plugins.HTML5    COMPLETE")
				clearInterval(timer);
				//this.onComplete(dojo.eval(xhr.responseText));
				this.onComplete({});
			}
		});
        xhr.open("POST", this.getUrl());

		timer = setInterval(dojo.hitch(this, function(){
			try{
				if(typeof(xhr.statusText)){} // accessing this error throws an error. Awesomeness.
			}catch(e){
				//this.onError("Error uploading file."); // not always an error.
				clearInterval(timer);
			}
		}),250);

		return xhr;
	},

});
//plugins.dojox.form.addUploaderPlugin(plugins.dojox.form.uploader.plugins.HTML5);
