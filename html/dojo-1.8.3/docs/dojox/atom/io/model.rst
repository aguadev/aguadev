.. _dojox/atom/io/model:

===================
dojox.atom.io.model
===================

:Project owner: Benjamin Schell
:since: V1.3

.. contents ::
   :depth: 2

The *dojox.atom.io.model* module is a JavaScript model of an ATOM feed.

Introduction
============

This module handles the parsing of the ATOM XML into a JavaScript structure that can be easily modified and then serialized out as XML.  This set of classes handles browser idiosyncrasies when parsing the XML, making it very cross-browser compatible and is far simpler to work with than using DOM apis to walk the ATOM XML document.

Classes defined in the model
============================

When the model file is loaded, several classes are defined that represent ATOM tags.  Please refer to the following table for the class names and a description of what they represent.  Each entry in the class name table also acts as a link to specific documentation about that class and what core functions it provides.

::ref:`dojox.atom.io.model.AtomItem <dojox/atom/io/model/AtomItem>`:
  A generic superclass used to represent specific ATOM details that are common for many ATOM tags

::ref:`dojox.atom.io.model.Category <dojox/atom/io/model/Category>`:
  Model to represent the Category tag of an ATOM document.  Contains all Category properties and a toString function for serializing it back to XML

::ref:`dojox.atom.io.model.Content <dojox/atom/io/model/Content>`:
  Model to represent the Content style tags in an ATOM document.  This is used to represent Summary, Content, Title, and Subtitle elements in an ATOM
  feed.  In other words, it represents any element that can contain Text, HTML, XHTML, etc as content format.  It also has a toString function used to
  generate the corresponding XML tag

::ref:`dojox.atom.io.model.Link <dojox/atom/io/model/Link>`:
  Atom link element.  Used for representing link attributes.  Handles multiple link types (edit, alt, etc.)

::ref:`dojox.atom.io.model.Person  <dojox/atom/io/model/Person>`:
  Atom person element. Used to represent authors and contributors.

::ref:`dojox.atom.io.model.Entry <dojox/atom/io/model/Entry>`:
  Atom entry element. Represents an Atom entry, including storing the authors, contributors, title, content, and so on.

::ref:`dojox.atom.io.model.Feed <dojox/atom/io/model/Feed>`:
  Atom feed element. Represents an Atom Feed, including the feed elements such as the title and author, and also represents the entry list.

::ref:`dojox.atom.io.model.Generator <dojox/atom/io/model/Generator>`:
  Atom generator element

::ref:`dojox.atom.io.model.Service <dojox/atom/io/model/Service>`:
  Atom service element

::ref:`dojox.atom.io.model.Workspace <dojox/atom/io/model/Workspace>`:
  Atom workspace element

::ref:`dojox.atom.io.model.Collection <dojox/atom/io/model/Collection>`:
  Atom collection element


Utility Functions
=================

There are also several utility functions defined by the model.  These functions are used by all of the subclasses and can be useful in standalone cases as well.  Please refer to the following table for function name and description:

+-----------------------------------------------------+----------------------------------------------------------------------------------------+
| **Function**                                        | **Description**                                                                        |
+-----------------------------------------------------+----------------------------------------------------------------------------------------+
| dojox.atom.io.model.util.createDate(DOMNode)        | A function for parsing the text content of a DOM node and creating a Date object from  |
|                                                     | it.                                                                                    |
+-----------------------------------------------------+----------------------------------------------------------------------------------------+
| dojox.atom.io.model.util.escapeHtml(String)         | A function for escaping HTML control and entity characters in a string so that it can  |
|                                                     | be handled as text without the markup affecting the XML document.                      |
+-----------------------------------------------------+----------------------------------------------------------------------------------------+
| dojox.atom.io.model.util.unEscapeHtml(String)       | A function for restoring the HTML control and tag characters to a string.  Useful when |
|                                                     | you wish to unEscape the content of an entry and display it in a Content Pane.         |
+-----------------------------------------------------+----------------------------------------------------------------------------------------+
| dojox.atom.io.model.util.getNodename(Node)          | A function for getting the node name of an XML node.  This function exists to handle   |
|                                                     | browser quirks.  Specifically things such as Internet Explorer's poor namespace        |
|                                                     | handling.                                                                              |
+-----------------------------------------------------+----------------------------------------------------------------------------------------+


Usage
=====

The model is intended for creating, parsing, and working with ATOM feeds in JavaScript and being able to easily serialize them out.  Generally to create a Feed you would use dojo.xhrGet() to load an XML document into a DOM, then pass that dom Object to buildFromDom() of a newly instantiated Atom Feed model class.  It will then construct all its subclasses and set its attributes correctly.  For specific usage, please refer to the examples section.

Examples
========

Example 1: Create an ATOM Feed model from an existing ATOM document
-------------------------------------------------------------------

*Note that this demonstrates that the XML document is converted into a JS object structure as shown by displaying the 'feed' by converting it to JSON.  The XML form is also displayed underneath it, demonstrating toString() rebuilding the XML form for submission or whatnot.*

.. code-example ::
  
  .. js ::

      dojo.require("dojox.atom.io.model");

      // This function performs some basic dojo initialization and will do the load calling for this example
      // Set the init function to run when dojo loading and page parsing has completed.
      dojo.ready(function(){
        var xhrArgs = {
           url: "{{dataUrl}}dojox/atom/tests/widget/samplefeedEdit.xml",
           preventCache: true,
           handleAs: "xml"
        };
 
        var deferred = dojo.xhrGet(xhrArgs);
       
        deferred.then(
            // Okay, on success we'll process the ATOM doc and generate the JavaScript model
            function(xmlDoc, ioargs){
                var feedRoot = xmlDoc.getElementsByTagName("feed");
                var feed = new dojox.atom.io.model.Feed();
                feed.buildFromDom(xmlDoc.documentElement);

                // Emit both the XML (As reconstructed from the Feed object and as a JSON form.
                var xml = dojo.byId("simpleAtomXml");
                xml.innerHTML = "";
                xml.appendChild(dojo.doc.createTextNode(feed.toString()));

                var json = dojo.byId("simpleAtomJson");
                json.innerHTML = "";
                json.appendChild(dojo.doc.createTextNode(dojo.toJson(feed, true)));
            },
 
            function(error){
                console.debug(e);
            }
        );
      });

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
    </span>

Example 2: Create a new ATOM Feed
---------------------------------

*Note that this demonstrates using the model to create a new Feed document with a single entry*

.. code-example ::
  
  .. js ::

      dojo.require("dojox.atom.io.model");

      // This function performs some basic dojo initialization and will do the main work for this example
      function initSimpleCreateAtom(){
        // Create a feed with some basic attributes set.
        var feed = new dojox.atom.io.model.Feed();
        feed.id = "This_Is_A_New_Feed_0";
        feed.addAuthor("John Doe", "johndoe@nowhere.org", "http://johndoeshomepage.org");
        feed.rights = "Copyright Dojo";
        feed.updated = new Date();
        feed.published = new Date();
        feed.setTitle("This <i>is</i> my Feed title!", "xhtml");

        // Create an entry
        var entry = feed.createEntry();
        entry.addAuthor("Jane Doe", "janedoe@nowhere.org", "http://johndoeshomepage.org");
        entry.setTitle("This <i>is</i> my entry title!", "xhtml");
        entry.id="entry_1";

        // Add the feed entry to the current feed.
        feed.addEntry(entry);

        // Emit The XML form of the feed.
        var xml = dojo.byId("simpleAtomCreate");
        xml.innerHTML = "";
        xml.appendChild(dojo.doc.createTextNode(feed.toString()));
      }
      // Set the init function to run when dojo loading and page parsing has completed.
      dojo.ready(initSimpleCreateAtom );

  .. html ::

    <div style="height: 400px; overflow: auto;">
      <b>As XML</b>
      <pre id="simpleAtomCreate">
      </pre>
    </span>

Example 3: Modify a loaded feed
-------------------------------

.. code-example ::
  
  .. js ::

      dojo.require("dojox.atom.io.model");

      // This function performs some basic dojo initialization and will do the load calling for this example
      // Set the init function to run when dojo loading and page parsing has completed.
      dojo.ready(function(){
        var xhrArgs = {
           url: "{{dataUrl}}dojox/atom/tests/widget/samplefeedEdit.xml",
           preventCache: true,
           handleAs: "xml"
        };
 
        var deferred = dojo.xhrGet(xhrArgs);
       
        deferred.then(
           // Okay, on success we'll process the ATOM doc and generate the JavaScript model
           function(xmlDoc, ioargs){
               var feedRoot = xmlDoc.getElementsByTagName("feed");
               var feed = new dojox.atom.io.model.Feed();
               feed.buildFromDom(xmlDoc.documentElement);

               // Emit XML of the modified feed.
               var xml = dojo.byId("simpleAtomXmlPristine");
               xml.innerHTML = "";
               xml.appendChild(dojo.doc.createTextNode(feed.toString()));

               // Remove an entry.
               var entry = feed.getFirstEntry();
               feed.removeEntry(entry);
               feed.updated = new Date();

               // Emit XML of the modified feed.
               xml = dojo.byId("simpleAtomXmlModified");
               xml.innerHTML = "";
               xml.appendChild(dojo.doc.createTextNode(feed.toString()));
            },
 
            function(error){
                console.debug(e);
            }
        );
      });

  .. html ::

    <div style="height: 400px; overflow: auto;">
      <b>Pristine XML</b>
      <pre id="simpleAtomXmlPristine">
      </pre>
      <br>
      <br>
      <b>Modified XML</b>
      <pre id="simpleAtomXmlModified">
      </pre>
    </span>



See Also
========

* :ref:`dojox.atom.io.Connection <dojox/atom/io/Connection>`: An IO class that simplifies doing APP for an ATOM feed.
* :ref:`dojox.data.AppStore <dojox/data/AppStore>`: A datastore built upon the *io* modules and provides full APP support.
