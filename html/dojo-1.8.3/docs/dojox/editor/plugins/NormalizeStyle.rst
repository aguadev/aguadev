.. _dojox/editor/plugins/NormalizeStyle:

===================================
dojox.editor.plugins.NormalizeStyle
===================================

:Project owner: Jared Jurkiewicz
:Authors: Jared Jurkiewicz
:since: V1.5

.. contents ::
    :depth: 2

Have you ever encountered a situation where the editor was inconsistent about how it handled bolding, italics, underline, etc, of a particular set of text in the editor?   Have you ever wanted to be able to force the editor to use <span> with style instead of semantic tags, or vice-versa?  If so, then this plugin may meet your needs.  It is a very experimental plugin that attempts to 'standardize' the output as either CSs-style, or semantic tag style, based on the configuration.

This plugin is 'headless', meaning it adds no toolbar button nor does it require any work to get decent output from it.  All you do is load it and register it as an extraPlugin for your editor and you're good to go.  Calls to get the value of the editor (editor.get("value")) will return HTML that has hopefully been processed and 'standardized'.

Features
========

This plugin cleans up the output from dijit.Editor in the following ways:

* Converts CSS styles to b, i, u, etc, tags or vice-versa, depending on the option.
* Uses 'internal editor format' when putting content in, meaning it coverts to CSS or semantic, based on which the native RTE code works best with.
* Very useful when paired with :ref:`dojox.editor.plugins.PrettyPrint <dojox/editor/plugins/PrettyPrint>`.

Usage
=====

Basic Usage
-----------
Usage of this plugin is quite simple and painless.  The first thing you need to do is require it into the page where you're using the editor:

.. js ::
 
    dojo.require("dijit.Editor");
    dojo.require("dojox.editor.plugins.NormalizeStyle");


Once it has been required in, all you have to do is include it in the list of extraPlugins you want to load into the editor.  For example:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['normalizestyle']"></div>

And that's it.  The editor instance you can reference by 'dijit.byId("editor")' is now enabled with the NormalizeStyle plugin!

Configuring NormalizeStyle Options
----------------------------------

The NormalizeStyle plugin supports two options that control how it formats the text.  The options are defined below:

+-----------------------------------+---------------------------------------------------------------------+------------------------+
| **option**                        | **Description**                                                     | **Required**           |
+-----------------------------------+---------------------------------------------------------------------+------------------------+
| mode                              |String indicating whether to use semantic or css styling.            | NO                     |
|                                   |Allowed values are: 'semantic' or 'css'.  The default is 'semantic'  |                        |
+-----------------------------------+---------------------------------------------------------------------+------------------------+
| condenseSpans                     |A boolean flag indicating that it should try to condense span tags   | NO                     |
|                                   |with styles where possible.  The default is true.                    |                        |
+-----------------------------------+---------------------------------------------------------------------+------------------------+

How do I configure the options?  Glad you asked.  You do it where you declare the plugin.  See the following example, which configures an editor with css mode, and not condensing spans.

.. html ::

  <div data-dojo-type="dijit/Editor"
       id="editor" data-dojo-props="extraPlugins:[{name: 'normalizestyle', mode: "css", condenseSpans: false}]">
  </div>


Examples
========

Basic Usage
-----------

.. code-example::
  :djConfig: parseOnLoad: true

  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.PrettyPrint");
      dojo.require("dojox.editor.plugins.NormalizeStyle");
      function showContent(){
           dojo.byId("output").innerHTML = dijit.byId("input").get("value");
      }

  .. html ::

    <b>Enter some text, then press the button to see it in encoded format</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="100px" id="input" data-dojo-props="extraPlugins:['normalizestyle']">
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
    <button id="eFormat" data-dojo-type="dijit/form/Button" onClick="showContent();">Press me to format!</button>
    <br>
    <textarea style="width: 100%; height: 100px;" id="output" readonly="true">
    </textarea>


Configured css mode
-------------------

.. code-example::
  :djConfig: parseOnLoad: true

  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.NormalizeStyle");
      function showContent2(){
           dojo.byId("output").innerHTML = dijit.byId("input").get("value");
      }

  .. html ::

    <b>Enter some text, then press the button to see it in encoded format</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="100px" id="input" data-dojo-props="extraPlugins:[{name:'normalizestyle', mode: 'css'}]">
    <div>
    <br>
    blah blah & blah!  This is a line longer than <b>twenty</b> characters, so it should wrap!
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
    <button id="eFormat" data-dojo-type="dijit/form/Button" onClick="showContent2();">Press me to format!</button>
    <br>
    <textarea style="width: 100%; height: 100px;" id="output" readonly="true">
    </textarea>


See Also
========

* :ref:`dijit.Editor <dijit/Editor>`
* :ref:`dijit._editor.plugins <dijit/_editor/plugins>`
* :ref:`dojox.editor.plugins <dojox/editor/plugins>`
* :ref:`dojox.editor.plugins.PrettyPrint <dojox/editor/plugins/PrettyPrint>`
