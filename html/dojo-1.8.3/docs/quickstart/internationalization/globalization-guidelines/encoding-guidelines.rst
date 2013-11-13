.. _quickstart/internationalization/globalization-guidelines/encoding-guidelines:

==================================
Globalization Guidelines: Encoding
==================================

:Authors: ?--
:since: V?

.. contents ::
   :depth: 2

The following guidelines should be used to implement internationalization in encoding.

The UTF-8 Encoding
==================

You should always use UTF-8 for encoding settings wherever applicable.
----------------------------------------------------------------------

This is a general rule for Web application design and development. You should manually set the encoding for files or I/O streams wherever applicable, because the default encoding (usually ISO-8859-1) cannot handle all Unicode characters. UTF-8 is the best choice when you use Dojo in your application, since Dojo only uses UTF-8.

The rest of this guideline describes the details of setting encodings in a Web application.


UTF-8 File Encoding
===================

You should encode all text files in UTF-8.
------------------------------------------

You should encode all text files in UTF-8, including HTML files, CSS files, JavaScript files, etc.

You must specify the UTF-8 encoding in every HTML file before any non-English characters.
-----------------------------------------------------------------------------------------

You must specify the encodings of all HTML files as early as possible. Ideally, this occurs on the server such that the server applies HTTP encoding headers to mark the document, otherwise this must be achieved in the browser using the meta tag. For example:

.. html ::
 
 <html>
     <head>
         <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
         <title>Hello World!</title>
     </head>
     ...
 </html>

This encoding declaration must appear before any non-English characters in a file; otherwise a browser might fail to read it correctly. For example, IE 6.0/7.0 cannot render the following content (encoded in UTF-8):

.. html ::
 
 <html>
     <head>
         <title>???</title>
         <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
     </head>
     <body>Hello!</body>
 </html>

By default, browsers assume that all files referred by an HTML file use the same encoding as the referring HTML file. So if you have the encoding of every HTML file specified, you do not need to declare the encoding setting in each CSS or JavaScript file again, but you can override the encoding anyway when some files are not in the same encoding as the HTML file. For example,

.. html ::
 
 <html>
     <head>
         <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
         <title>Hello World!</title>
         <link rel="stylesheet" href="foo.css" type="text/css" charset="utf-8">
         <script src="bar.js" type="text/javascript" charset="utf-8"></script>
     </head>
     ...
 </html>


Sending and Receiving Requests
==============================

You must use the BOM header for UTF-16 files.
---------------------------------------------

A BOM header consists of 2, 3, or 4 bytes at the very beginning of a text file to indicate its encoding. For example, 0xFF 0xFE means that the file is encoded in UTF-16LE, while 0xEF 0xBB 0xBF means that the encoding is UTF-8. The BOM header can override the encoding settings mentioned above in a browser.

Using UTF-16 is not recommended, but if you choose it for some reason, the BOM header is required. Because UTF-16 is not compatible with ASCII, a browser even does not have a chance to read the encoding setting of the file content.

You must use UTF-8 to decode XHR request parameters.
----------------------------------------------------

The dojo.xhr* functions are the most common way in Dojo to enable Ajax features -- sending an asynchronous request to the server by an XMLHttpRequest object. The typical call to one of these functions can be:

.. js ::

   dojo.xhrGet({
       url: "foo.jsp",
       content: {"name": "\u4e00"} // \u4e00 ("?") is the Chinese character for "one"
   });

The url is where this request will be sent to. The content is the JSON object that will be sent in the request. In Dojo’s implementation, the key and value pairs in the content are encoded by the encodeURIComponent function first, and then converted to a query string like "key=value&key=value&...". The xhrPost function puts the query string into the request content, and other functions like xhrGet append the query string to the end of the url, so the previous code is equal to the following code:

.. js ::

   dojo.xhrGet({
       url: "foo.jsp?name=%e4%b8%80", // %e4%b8%80 are the UTF-8 bytes for \u4e00
   });

Because the encodeURIComponent function always uses UTF-8, you must use UTF-8 at the server side to decode the request parameters both in the URL (xhrGet) and in the request content (xhrPost).

For example, in Tomcat, you can set the encoding of URL by the URIEncoding attribute in server.xml:

.. html ::
 
 <<!-- Define a non-SSL HTTP/1.1 Connector on port 8080 -->
 <Connector port="8080" maxHttpHeaderSize="8192"
     maxThreads="150" minSpareThreads="25" maxSpareThreads="75"
     enableLookups="false" redirectPort="8443" acceptCount="100"
     connectionTimeout="20000" disableUploadTimeout="true"
     URIEncoding="UTF-8" />

You can set the encoding of the request content (xhrPost) by simply calling request.setCharacterEncoding before using the request object:

.. html ::
 
 <%@page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
 <%request.setCharacterEncoding("utf-8");%>
 ...
 name=<%=request.getParameter("name")%>

You MUST manually set the encoding on your server, because almost no Web server uses UTF-8 to decode URLs and request content by default. For example, Tomcat always uses ISO-8859-1 to deal with requests if you do not set the encoding. WebSphere uses a locale-encoding map to determine the request encoding from the client's language, but no locale is mapped to UTF-8 by default.

You must use UTF-8 encoding when using a non-English string in a URL.
---------------------------------------------------------------------

Some browsers like IE always send URLs using the default system encoding. For example, in a Simplified Chinese Windows XP operating system, IE sends a URL encoded in GB2312. If you need to put some non-English parameters in a URL, make sure that you have encoded it first using the encodeURIComponent function. For example, in a Simplified Chinese Windows XP, if you run the following script in IE:

.. js ::

   dojo.xhrPost({
       url: "foo.jsp?name1=\u4e00",
       content: {"name2": "\u4e00"}
   });

You might get different results for name1 and name2 at the server side:

* name1 --> 0xD2 0xBB (in GB2312, Wrong!)
* name2 --> 0xE4 0xB8 0x80 (in UTF-8, Right!)

The right way is to encode name1 first:

.. js ::

   dojo.xhrPost({
       url: "foo.jsp?name1=" + encodeURIComponent("\u4e00"),
       content: {"name2": "\u4e00"}
   });


Sending Responses
=================

You must set Content-Type in an HTTP response header if the response is not encoded in UTF-8.
---------------------------------------------------------------------------------------------

An XMLHttpRequest object first checks the HTTP header of a response to see if there is a Content-Type property that sets the encoding of the response; otherwise, it always uses UTF-8 to decode the response into a string. Web servers usually set the Content-Type property automatically for dynamic files like JSP. However, for static files, Web servers probably do not know the encoding of the files and also do not set the Content-Type property for them.
