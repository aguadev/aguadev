var express = require('express');
var https = require('https');
var http = require('http');
var fs = require('fs');

// This line is from the Node.js HTTPS documentation.
var options = {
  key: fs.readFileSync('/etc/apache2/ssl.key/server.key'),
  cert: fs.readFileSync('/etc/apache2/ssl.key/server.crt')
};

// Create a service (the app object is just a callback).
var app = express();

/* serves all the static files */
app.get(/^(.+)$/, function(req, res){ 
	console.log('static file request : ' + req.params);
	res.sendfile( "/var/www/html" + req.params[0]); 
});

// Create an HTTP service.
//http.createServer(app).listen(80);
// Create an HTTPS service identical to the HTTP service.
https.createServer(options, app).listen(443);

