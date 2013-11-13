.. _dojox/editor/plugins/TextColor:

==============================
dojox.editor.plugins.TextColor
==============================

:Authors: Jared Jurkiewicz
:Developers: Jared Jurkiewicz
:since: V1.5

.. contents ::
    :depth: 2

Have you wanted a better text color selection plugin that allows for colors that span the entire RGB color space instead of the selected colors provided by :ref:`the dijit TextColor Plugin <dijit/_editor/plugins/TextColor>`  If so, then this plugin is for you.  The dijit._editor.plugins.TextColor plugin provides two action buttons on the editor toolbar that make use of the dojox.widget.ColorPicker instead of the dijit.ColorPalette for color selection.

Features
========

Once required in and enabled, this plugin provides the following features to dijit.Editor.

* Button with icon in toolbar for changing the color of the selected text.
* Button with icon in toolbar for changing the background color of the selected text.
* Use of dojox.widget.ColorPicker for complex color selection.
* The plugins are registrable in the editor via the following commands:

    foreColor - Enable the text color plugin.

    hiliteColor - Enable the text background color plugin.


Usage
=====

Basic Usage
-----------
Usage of this plugin is quite simple and painless.

First include the CSS for it:

.. css ::

    @import "dojox/editor/plugins/resources/css/TextColor.css";

Then require it into the page where you're using the editor:

.. js ::
 
    dojo.require("dijit.Editor");
    dojo.require("dojox.editor.plugins.TextColor");


Once it has been required in, all you have to do is include it in the list of extraPlugins (or the plugins property if you're reorganizing the toolbar) for you want to load into the editor.  For example:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['foreColor', 'hiliteColor']"></div>


And that's it.  The editor instance you can reference by 'dijit.byId("editor")' is now enabled with the dojox variant of the TextColor plugin!  You can use the buttons to alter the colors of selected text.

Limitations
===========

* The dojox.widget.ColorPicker has some CSS issues when combined with certain themes on certain browsers.  For example, claro theme on Google Chrome renders a bit off.
* The plugin is **not** A11Y (accessibility) compliant since the dojox.widget.ColorPicker is not A11Y compliant.

Examples
========

Basic Usage: foreColor (Text Color)
-----------------------------------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.5

  .. js ::

      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.TextColor");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/InsertAnchor.css";
    
  .. html ::

    <b>Enter some text and select it, or select existing text, then push the TextColor button to select a new color for it.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['foreColor']">
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


Basic Usage: hiliteColor (Text Background Color)
------------------------------------------------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.5

  .. js ::

      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.TextColor");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/InsertAnchor.css";
    
  .. html ::
    
  .. html ::

    <b>Enter some text and select it, or select existing text, then push the Text Background Color button to select a new background color for it.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['hiliteColor']">
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


Basic Usage: Both foreground and background color buttons together
------------------------------------------------------------------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.5

  .. js ::

      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.TextColor");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/InsertAnchor.css";
    
  .. html ::
    
  .. html ::

    <b>Enter some text and select it, or select existing text, then change its colors via the text color and text background color buttons.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['foreColor', 'hiliteColor']">
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
* :ref:`dijit._editor.plugins.TextColor <dijit/_editor/plugins/TextColor>`
* :ref:`dojox.editor.plugins <dojox/editor/plugins>`
