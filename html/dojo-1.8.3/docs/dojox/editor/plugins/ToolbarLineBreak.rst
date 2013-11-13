.. _dojox/editor/plugins/ToolbarLineBreak:

=====================================
dojox.editor.plugins.ToolbarLineBreak
=====================================

:Authors: Jared Jurkiewicz
:Project owner: Jared Jurkiewicz
:since: V1.4

.. contents ::
    :depth: 2

Have you ever wanted to force the editor toolbar to line break/wrap to a new line?  I've often found myself with that wish, particularly when there are a lot of buttons/icons enabled in the toolbar.  It provides a visual way to separate the toolbar into 'sections', much like how you can use the dijit.ToolbarSeparator to put a vertical separator bar into the editor toolbar.

Features
========
Once required in and enabled, this plugin provides the following features to dijit.Editor.

* A plugin that can be declared multiple times in your 'plugins' or 'extraPlugins' options of Editor that lets you wrap the toolbar at the indicated points

Usage
=====

Basic Usage
-----------
Usage of this plugin is quite simple and painless.
The first thing you need to do is require it into the page where you're using the editor:

.. js ::
 
    dojo.require("dijit.Editor");
    dojo.require("dojox.editor.plugins.ToolbarLineBreak");


Once it has been required in, all you have to do is include it in the list of extraPlugins (or the plugins property if you're reorganizing the toolbar) for you want to load into the editor.  For example:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['||', 'fontSize', 'formatBlock', '||', 'hiliteColor']"></div>


And that's it.  Every point in that definition where '||' is encountered, the plugin inserts a 'line break' into the toolbar between the indicated plugin buttons.  Note you can also use it inside the 'plugins=""' definition of editor too.

Limitations
===========

The background images of the toolbar need to be able to handle line-wrapping toolbars for the effect to look reasonable.  All the provided themes of dojo work reasonably well for a several line toolbar.


AllY Considerations
===================

From a key nav A11Y perspective, the toolbar line break plugin works just like the ToolbarSeparator, it doesn't impact the key nav.  Left and right arrow keys will still move between the buttons fine.

Examples
========

Basic Usage
-----------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.4

  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.Editor");
      dojo.require("dijit._editor.plugins.FontChoice");
      dojo.require("dijit._editor.plugins.TextColor");
      dojo.require("dojox.editor.plugins.ToolbarLineBreak");

  .. html ::

    <b>Look at the toolbar, the font manipulation options are wrapped to a new line in the toolbar.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['||', 'fontName', '||', 'fontSize', '||', 'formatBlock', '||', 'foreColor', 'hiliteColor']">
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
