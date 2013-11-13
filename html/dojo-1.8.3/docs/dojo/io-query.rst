.. _dojo/io-query:

=============
dojo/io-query
=============


.. contents ::
    :depth: 2

**dojo/io-query** defines query string processing functions which contain ``objectToQuery`` and ``queryToObject``.

Introduction
============

``dojo/io-query`` provides two utility functions for converting between JavaScript objects and query strings that are 
part of a URL.

Usage
=====

.. _dojo/io-query#objecttoquery:

objectToQuery()
---------------

Takes a name/value mapping object and returns a string representing a URL-encoded version of that object.

This function is one of many helpers used by the ``dojo/request`` subsystem for handling AJAX style requests.  This 
particular function takes a JavaScript object and converts it to a query string suitable to append onto a URI.  This 
function is useful in constructing URIs quickly and cleanly, with the proper special character encoding.  The resulting 
query string can be converted back to a JavaScript object by the function ``queryToObject()``.

Usage is simple and straightforward, you pass the object you wish converted to a query string and the function will 
return the query string.

.. js ::

  require(["dojo/io-query"], function(ioQuery){
    var uri = "http://some.server.org/somecontext/";
    var query = {
      foo: ["bar", "baz"],
      bit: "byte"
    };

    // Assemble the new uri with its query string attached.
    var queryStr = ioQuery.objectToQuery(query);
    uri = uri + "?" + queryStr;

    // The uri should look like:
    // http://some.server.org/somecontext/?foo=bar&foo=bar2&bit=byte
  });

.. _dojo/io-query#querytoobject:

queryToObject()
===============

Helper function for converting a URI query string to a JavaScript Object.

This function is one of many helpers used by the ``dojo/request`` subsystem for handling AJAX style requests.  This 
particular function takes the query portion of a URI and returns a JavaScript object of the name/value pairs.  It 
handles both single and multi-valued query parameters.  This function is useful in deconstructing URIs for display in 
page forms and the like.  It can also be used as a way to modify a query by converting to JavaScript, making changes to 
parameters, then converting it back to a query string via ``objectToQuery()``.

Usage is simple and straightforward, you pass the query string of the URI as the parameter to the function and it will 
return it in JavaScript object form.

.. js ::

  require(["dojo/io-query"], function(ioQuery){
    var uri = "http://some.server.org/somecontext/?foo=bar&foo=bar2&bit=byte";
    var query = uri.substring(uri.indexOf("?") + 1, uri.length);
    var queryObject = ioQuery.queryToObject(query);

    // The structure of queryObject will be:
    // {
    //   foo: ["bar", "bar2],
    //   bit: "byte"
    // }
  });

Examples
========

.. code-example ::
  :djConfig: async: true, parseOnLoad: false

  Using ``objectToQuery()`` to create a query string and assign it to a URI

  .. js ::

    require(["dojo/dom", "dojo/io-query", "dojo/on", "dojo/domReady!"], 
    function(dom, ioQuery, on){
      on(dom.byId("convertQuery"), "click", function(){
        var uri =  "http://uri.some.org/context";
        var query = {
          foo: ["bar", "bar2"],
          bit: "byte"
        };

        // Assemble the new URI.
        var queryStr = ioQuery.objectToQuery(query);
        uri = uri + "?" + queryStr;

        // Attach it into the dom
        dom.byId("query").innerHTML = uri;
      });
    });

  .. html ::

    <button type="button" id="convertQuery">
        Click to update the URI with a query generated from an object</button>
    <p><strong>The URI</strong></p>
    <pre>http://uri.some.org/context</pre>
    <p><strong>The modified URI with a query string.:</strong></p>
    <pre id="query"></pre>

.. code-example ::
  :djConfig: async: true, parseOnLoad: false

  Using ``queryToObject()`` to create a JavaScript form of a query

  .. js ::

    require(["dojo/dom", "dojo/io-query", "dojo/json", "dojo/on", "dojo/domReady!"],
    function(dom, ioQuery, JSON, on){
      on(dom.byId("convertQuery"), "click", function(){
        var uri =  "http://uri.some.org/context?foo=bar&foo=bar2&bit=byte";

        // Isolate the query portion of the URI and convert it.
        var query = uri.substring(uri.indexOf("?") + 1, uri.length);
        query = ioQuery.queryToObject(query);

        // Attach it into the don as pretty-printed text.
        dom.byId("query").innerHTML = JSON.stringify(query, true);
      });
    });

  .. html ::

    <button id="convertQuery" type="button">
        Click to convert query portion of URI</button>
    <p><strong>The URI</strong></p>
    <pre>http://uri.some.org/context?foo=bar&foo=bar2&bit=byte</pre>
    <p><strong>The Query converted to a JavaScript Object:</strong></p>
    <pre id="query"></pre>

.. code-example ::
  :djConfig: async: true, parseOnLoad: false

  Using queryToObject and objectToQuery to alter query strings

  .. js ::

    require(["dojo/dom", "dojo/io-query", "dojo/json", "dojo/on", "dojo/domReady!"],
    function(dom, ioQuery, JSON, on){
        on(dom.byId("alterQuery"), "click", function(){
           var uri = "http://uri.some.org/context?foo=bar&foo=bar2&bit=byte";

           // Isolate the query portion of the URI and convert it.
           var query = uri.substring(uri.indexOf("?") + 1, uri.length);
           query = ioQuery.queryToObject(query);

           // let's make some changes.
           query.foo = "alteredFoo";
           query.newParam = "I'm new!";

           // Write the new URI out.
           dom.byId("alteredQuery").innerHTML = uri.substring(0, uri.indexOf("?") + 1) + ioQuery.objectToQuery(query);
        });
    });

  .. html ::

    <button id="alterQuery">Click to alter the query string</button>
    <p><strong>The URI</strong></p>
    <pre>http://uri.some.org/context?foo=bar&foo=bar2&bit=byte</pre>
    <strong>The modified query string in the URI:</strong>
    <pre id="alteredQuery"></pre>

See also
========

* :ref:`dojo/dom-form <dojo/dom-form>` - HTML form conversion utility functions.

* :ref:`dojo/hash <dojo/hash>` - Manage and control the browsers hash.
