.. _dojox/atom/io/Connection:

========================
dojox.atom.io.Connection
========================

:Project owner: Benjamin Schell
:since: V1.3

.. contents ::
   :depth: 2

The *dojox.atom.io.Connection* module is a IO class for performing APP (ATOM Publishing Protocol) styled IO actions with a server.

Introduction
============

This module simplifies performing APP by handling the configuration of all the necessary xhr parameters as well as selecting the correct xhr 
method for performing a particular type of ATOM action, from getting a Feed (xhrGet), to publishing a new entry (xhrPut).  This class makes use 
of the dojox.atom.io.model class as its backing representation of the ATOM document and elements.

Limitations
===========

Since this module uses the core :ref:`dojo.xhr <dojo/xhr>` functions for performing server communication, it is limited by the browser 
same-domain policy for xhr requests.  This means that it can only issue requests back to the server and port that served the HTML page using 
the API.  For accessing alternate servers, you will need to use a proxy to broker the request to the target server.

Constructor Parameters
======================

+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| **Parameter**  | **Required** | **Description**                                                                                | **Since** |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| sync           | no           |This parameter configures the instance of Connection to issue its requests using the xhr 'sync' | 1.3       |
|                |              |option.  If it is set to true, then all calls will block until the data is returned.  This is   |           |
|                |              |not recommended, but available as an option.  The default is false.                             |           |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| preventCache   | No           |This parameter tells the Connection whether or not to append a query param to the URL to prevent|1.3        |
|                |              |the browser from caching the results of the IO call.  The default is false.                     |           |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+

Functions
=========

+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| **Function**                                                 | **Description**                                                             |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| getFeed(url, callback, errorCallback, scope)                 | Function to load a feed from a URL                                          |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| getService(url, callback, errorCallback, scope)              | Function to load an ATOM service document from a URL                        |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| getEntry(url, callback, errorCallback, scope)                | Function to load an ATOM entry from an ATOM feed                            |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| getEntry(url, callback, errorCallback, scope)                | Function to load an ATOM entry from an ATOM feed                            |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| updateEntry(entry, callback, errorCallback,                  | Function to update an entry via APP (PUT of a modified entry                |
| retrieveUpdated, xmethod, scope)                             |                                                                             |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| addEntry(entry, url, callback, errorCallback,                | Function to add an entry to a feed via APP (POST of a new entry)            |
| retrieveEntry, scope)                                        |                                                                             |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+
| deleteEntry(entry,callback,errorCallback,xmethod,scope)      | Function to delete an entry in a feed via APP (DELETE of an existing entry  |
+--------------------------------------------------------------+-----------------------------------------------------------------------------+

Examples
========

Example 1: Load an ATOM Feed
----------------------------

*Note that this demonstrates that the XML document is converted into a JS object structure as shown by displaying the 'feed' by converting it to JSON.  The XML form is also displayed underneath it, demonstrating toString() rebuilding the XML form for submission or whatnot.*

.. code-example ::
  
  .. js ::

      dojo.require("dojox.atom.io.model");
      dojo.require("dojox.atom.io.Connection");

      // This function performs some basic dojo initialization and will do the load calling for this example
      function initSimpleAtom(){
        var conn = new dojox.atom.io.Connection();

        conn.getFeed("{{dataUrl}}dojox/atom/tests/widget/samplefeedEdit.xml",
          function(feed){
           // Emit both the XML (As reconstructed from the Feed object and as a JSON form.
           var xml = dojo.byId("simpleAtomXml");
           xml.innerHTML = "";
           xml.appendChild(dojo.doc.createTextNode(feed.toString()));

           var json = dojo.byId("simpleAtomJson");
           json.innerHTML = "";
           json.appendChild(dojo.doc.createTextNode(dojo.toJson(feed, true)));
          },
          function(err){
            console.debug(err);
          }
        );
      }
      // Set the init function to run when dojo loading and page parsing has completed.
      dojo.ready(initSimpleAtom);

  .. html ::

    <div style="height: 400px; overflow: auto;">
      <b>As JSON (To show that it is creating a JS structure)</b>
      <pre id="simpleAtomJson">
      </pre>
      <br>
      <br>
      <b>As XML (Showing toString() returning the XML version)</b>
      <pre id="simpleAtomXml">
      </pre>
    </div>


Example 2: Update an entry in a Feed
------------------------------------

*Note that to see the PUT, you can use firebug.  But to see the PUT contents, you will need a debugging proxy like Charles*

.. code-example ::
  
  .. js ::

      dojo.require("dojox.atom.io.model");
      dojo.require("dojox.atom.io.Connection");

      // This function performs some basic dojo initialization and will do the load calling for this example
      function initUpdateAtom(){
        var conn = new dojox.atom.io.Connection();

        conn.getFeed("{{dataUrl}}dojox/atom/tests/widget/samplefeedEdit.xml",
          function(feed){
           // Emit both the XML (As reconstructed from the Feed object and as a JSON form.
           var xml = dojo.byId("simplePristineAtomXml");
           xml.innerHTML = "";
           xml.appendChild(dojo.doc.createTextNode(feed.toString()));

           // Now get an entry for mod.
           var entry = feed.getFirstEntry();

           // Make this updateable by pointing it to the app test pho script so it can properly post.
           entry.setEditHref("{{dataUrl}}dojox/atom/tests/io/app.php");
           entry.updated = new Date();
           entry.setTitle('<h1>New Editable Title!</h1>', 'xhtml');
           conn.updateEntry(entry, function(){
               var xml = dojo.byId("simpleModifiedAtomXml");
               xml.innerHTML = "";
               xml.appendChild(dojo.doc.createTextNode(feed.toString()));
             },
             function(err){
               console.debug(err);
             }
           );
          },
          function(err){
            console.debug(err);
          }
        );
      }
      // Set the init function to run when dojo loading and page parsing has completed.
      dojo.ready(initUpdateAtom );

  .. html ::

    <div style="height: 400px; overflow: auto;">
      <b>XML of Feed (before change)</b>
      <pre id="simplePristineAtomXml">
      </pre>
      <br>
      <br>
      <b>As XML (After modification)</b>
      <pre id="simpleModifiedAtomXml">
      </pre>
    </span>


**Note:** You can see more example usage in the tests file at: dojox/atom/tests/io/module.js


See Also
========

* :ref:`dojox.atom.io.model <dojox/atom/io/model>`: The backing model for the Feed used by this connection API.
* :ref:`dojox.data.AppStore <dojox/data/AppStore>`: A datastore built on top of this API.  Provides full APP support.
