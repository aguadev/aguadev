.. _dojox/editor/plugins/CollapsibleToolbar:

=======================================
dojox.editor.plugins.CollapsibleToolbar
=======================================

:Authors: Jared Jurkiewicz
:Project owner: Jared Jurkiewicz
:since: V1.5

.. contents ::
    :depth: 2

Have you ever wanted to collapse the editor toolbar out of the way?  This is desirable in cases where the editor occupies a small section of a page and the toolbar has wrapped, limiting the editing area.  If this is a situation your users encounter, then this plugin is for you.

Features
========

Once required in and enabled, this plugin provides the following features to dijit.Editor.

* A nicely styled minimize/maximize button on the editor toolbar.
* Full a11y support.  The button is properly read by screen-readers and works in keyboard tab order.
* The button works perfectly in high-contrast mode,
* Styles for Tundra, Nihilo, and soria themes.

Limitations
===========

* This plugin should be instantiated as the first plugin in the plugins list to ensure that it adapts the toolbar before other plugins modify it (such as FindReplace does).


Usage
=====

Basic Usage
-----------
Usage of this plugin is quite simple and painless.

First include the CSS for it:

.. css ::

    @import "dojox/editor/plugins/resources/css/CollapsibleToolbar.css";

Then require it into the page where you're using the editor:

.. js ::
 
    dojo.require("dijit.Editor");
    dojo.require("dojox.editor.plugins.CollapsibleToolbar");


Once it has been required in, all you have to do is include it in the list of extraPlugins as the first plugin (or the first plugin of the plugins property if you're reorganizing the toolbar) to enable it in your editor instance.  For example:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['collapsibletoolbar']"></div>



And that's it.  The editor instance you can reference by 'dijit.byId("editor")' is now enabled with the CollapsibleToolbar plugin!  You can click the collapse icon to collapse the toolbar, and the expand icon to bring it back

Examples
========

Basic Usage
-----------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.5

  .. js ::

      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.CollapsibleToolbar");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/CollapsibleToolbar.css";
    
  .. html ::

    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['collapsibletoolbar']">
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
