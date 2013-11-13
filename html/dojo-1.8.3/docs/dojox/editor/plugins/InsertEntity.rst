.. _dojox/editor/plugins/InsertEntity:

=================================
dojox.editor.plugins.InsertEntity
=================================

:Authors: Jared Jurkiewicz
:Project owner: Jared Jurkiewicz
:since: V1.4

.. contents ::
    :depth: 2

Have you ever wanted to easily insert the copyright symbol, the trademark symbol, or any of a variety of mathematical symbols into the document you're editing in the dijit.Editor?   If so, then this plugin is for you!  This plugin provides a subset of entity characters that can be inserted into your documents.  The symbols provided are primarily the non-ascii 8859 characters and a large set of greek symbols used in mathematics.

Features
========

Once required in and enabled, this plugin provides the following features to dijit.Editor.

* Button with icon in toolbar for inserting a symbol from a subset of entity characters at the current location in the document.
* Keyboard hotkey: CTRL-SHIFT-S for inserting a symbol at the current location in the editor.  (Note that this is a similar keybind to those used by commercial word processors, so it will hopefully be familiar and easy to pick up.).
* A key-navigable grid of symbols to select the one to insert.

Usage
=====

Basic Usage
-----------
Usage of this plugin is quite simple and painless.

First include the CSS for it:

.. css ::

    @import "dojox/editor/plugins/resources/css/InsertEntity.css";

Then require it into the page where you're using the editor:

.. js ::
 
    dojo.require("dijit.Editor");
    dojo.require("dojox.editor.plugins.InsertEntity");


Once it has been required in, all you have to do is include it in the list of extraPlugins (or the plugins property if you're reorganizing the toolbar) for you want to load into the editor.  For example:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['insertEntity']"></div>


And that's it.  The editor instance you can reference by 'dijit.byId("editor")' is now enabled with the InsertEntity plugin!  You can use the button or hotkey to insert entity characters as you desire.

Limitations
===========

Something to be aware of is that if you also use the :ref:`dojox.editor.plugins.PrettyPrint <dojox/editor/plugins/PrettyPrint>` plugin is that you will need to reconfigure PrettyPrint to escape more entities.  Otherwise, entity encoding will not be preserved when the value is retrieved from the editor.  This can be done as follows:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['insertEntity', {name: 'prettyprint', entityMap: dojox.html.entities.html.concat(dojox.html.entities.latin)}]"></div>

The above configures prettyprint to escape all the same entities that the InsertEntity plugin can insert.

Examples
========

Basic Usage
-----------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.4

  .. js ::

      dojo.require("dijit.Editor");
      dojo.require("dijit._editor.plugins.ViewSource");
      dojo.require("dojox.editor.plugins.InsertEntity");
      dojo.require("dojox.editor.plugins.PrettyPrint");
      dojo.require("dojox.html.entities");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/InsertEntity.css";
    
  .. html ::

    <b>Enter some text or select a position, then push the InsertEntity button or use CTRL-SHIFT-S, to insert an entity character of your choosing at that point. Note that viewsource and prettyprint are also enabled so that you can see the entities and their encodings.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['insertentity', 'viewsource', {name: 'prettyprint', indentBy: 3, entityMap: dojox.html.entities.html.concat(dojox.html.entities.latin)}]">
    <div>
    <br>
    blah blah & blah!
    <br>
    </div>
    <br>
    <table>
    <tbody>
    <tr>
    <td style="border-style:solid; border-width: 2px; border-color: gray;">One cell</td>
    <td style="border-style:solid; border-width: 2px; border-color: gray;">
    Two cell
    </td>
    </tr>
    </tbody>
    </table>
    <ul>
    <li>item one</li>
    <li>
    item two
    </li>
    </ul>
    </div>

See Also
========

* :ref:`dijit.Editor <dijit/Editor>`
* :ref:`dijit._editor.plugins <dijit/_editor/plugins>`
* :ref:`dojox.editor.plugins <dojox/editor/plugins>`
