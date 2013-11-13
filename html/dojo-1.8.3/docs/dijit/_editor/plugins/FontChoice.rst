.. _dijit/_editor/plugins/FontChoice:

================================
dijit/_editor/plugins/FontChoice
================================

:Authors: Jared Jurkiewicz
:Developers: Bill Keese, Jared Jurkiewicz
:since: V1.1

.. contents ::
    :depth: 2

Have you ever wanted to change the font size, font face, or block type containing the text in your document?
If so, then this plugin is for you!
It provides three drop down menu items for manipulating those aspects of your document.

Features
========

Once required in and enabled, this plugin provides the following features to dijit.Editor.

* Drop-Down select of Font names to style text with.  The font names by default are basic ones supported by all browsers.  Users can customize this list to include other font names.
* Drop-Down select of Font sizes (xx-small to xx large) to style text with.  The font sizes are the basic HTML named font sizes (1 through 7), that all browsers support natively through the fontSize command.
* Drop-Down select of text container types, such as <p>, <pre>, <h1>, <h2> ... and so on.
* Preview mode in the dropdowns to show what the size or style type would appear like in the document.
* Auto-updating of view of the current style, size, and name settings as the user moves through the document to sections with different styles.

Usage
=====

Basic Usage
-----------
Usage of this plugin is quite simple and painless.
The first thing you need to do is require into the page you're using the editor.
This is done in the same spot as your require() call is made, usually the head script tag.
For example:

.. js ::
 
    require(["dojo/parser", "dijit/Editor", "dijit/_editor/plugins/FontChoice"]);


Once it has been required in, all you have to do is include the control names in the list of extraPlugins (or the plugins property if you're reorganizing the toolbar) for you want to load into the editor.
For example:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['fontName', 'fontSize', 'formatBlock']"></div>



And that's it.
The editor instance you can reference by 'dijit.byId("editor")' is now enabled with all the toolbar actions provided by the FontChoice plugin.

Plugin Options
==============

The FontChoice plugin allows certain options to control how the plugin displays state to the user.
This is primarily to enable or disable the style 'preview' in the button.
The default mode for style preview is enabled for backwards compatibility.

+-----------------------------------+---------------------------------------------------------------------+------------------------+
| **option**                        | **Description**                                                     | **Required**           |
+-----------------------------------+---------------------------------------------------------------------+------------------------+
| plainText                         |Boolean indicator if the displayed values in the dropdowns should be |NO                      |
|                                   |styled or not.  The default value is false, which means they are     |                        |
|                                   |styled.  **This option is new to Dojo Toolkit 1.4**                  |                        |
+-----------------------------------+---------------------------------------------------------------------+------------------------+


An example of disabling it is below:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:[{name: 'fontName', plainText: true}, {name: 'fontSize', plainText: true}, {name: 'formatBlock', plainText: true}]"></div>

With the preview disabled, the selects show basic text only.

Examples
========

Basic Usage
-----------

.. code-example::
  :djConfig: parseOnLoad: true

  .. js ::

    require(["dojo/parser", "dijit/Editor", "dijit/_editor/plugins/FontChoice"]);

    
  .. html ::

    <b>Select any of the text below and experiment with the font options</b>
    <br />
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['fontName', 'fontSize', 'formatBlock']">
        <br />
        <br />
        <h1>This is a header</h1>
        <p>This is some basic paragraph text.</p>
        <p><font style="font-family: 'Comic Sans MS'">This is some basic paragraph text in Comic font.</font></p>
        <br />
    </div>


Basic Usage: Plain Text Previews
--------------------------------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.4

  .. js ::

    require(["dojo/parser", "dijit/Editor", "dijit/_editor/plugins/FontChoice"]);

    
  .. html ::

    <b>Select any of the text below and experiment with the font options</b>
    <br />
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:[{name: 'fontName', plainText: true}, {name: 'fontSize', plainText: true}, {name: 'formatBlock', plainText: true}]">
        <br />
        <br />
        <h1>This is a header</h1>
        <p>This is some basic paragraph text.</p>
        <p><font style="font-family: 'Comic Sans MS'">This is some basic paragraph text in Comic font.</font></p>
        <br />
    </div>


See Also
========

* :ref:`dijit/Editor <dijit/Editor>`
* :ref:`dijit/_editor/plugins <dijit/_editor/plugins>`
* :ref:`dojox/editor/plugins <dojox/editor/plugins>`
