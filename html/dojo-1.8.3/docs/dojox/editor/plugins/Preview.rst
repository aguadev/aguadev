.. _dojox/editor/plugins/Preview:

============================
dojox.editor.plugins.Preview
============================

:Authors: Jared Jurkiewicz
:Project owner: Jared Jurkiewicz
:since: V1.4

.. contents ::
    :depth: 2

Have you ever wanted to see how the contents of the editor would look outside the editor or styled with a different set of CSS styles.  If so, then this plugin is for you!  This plugin provides a 'preview' capability, a way to view the contents of the editor outside the editable frame and with different styles applied.

Features
========

Once required in and enabled, this plugin provides the following features to dijit.Editor.

* Button with icon in toolbar for previewing the content outside of the editor framedocument.
* The ability to define a set of CSS styles or stylesheets to apply to the content in the preview view.

Usage
=====

Basic Usage
-----------
Usage of this plugin is quite simple and painless.

First include the CSS for it.  For example:

.. css ::

    @import "dojox/editor/plugins/resources/css/Preview.css";


Then require it into the page where you're using the editor:

.. js ::
 
    dojo.require("dijit.Editor");
    dojo.require("dojox.editor.plugins.Preview");


Once it has been required in, all you have to do is include it in the list of extraPlugins (or the plugins property if you're reorganizing the toolbar) for you want to load into the editor.  For example:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:['preview']"></div>



And that's it.  The editor instance you can reference by 'dijit.byId("editor")' is now enabled with the Preview plugin!

Configuring CSS styles
======================

The CSS styling is configured in the plugin instantiation.  It can take two optional parameters, *styles* and *stylesheets* to define a set of CSS styles and/or stylesheets to import into the preview when it is rendered.  Please note that to use stylesheets, you *must* pass full urls to the stylesheets, such as **http://example.com/foo.css**, for it to be able to properly load them.


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
      dojo.require("dojox.editor.plugins.Preview");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/Preview.css";
    
  .. html ::

    <b>Enter whatever you like in the editor, then press the 'Preview' button.  A new window will open with the contents.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:['preview']">
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

Applying styles to preview content
----------------------------------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.4

  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.Preview");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/Preview.css";
    
  .. html ::

    <b>Enter whatever you like in the editor, then press the 'Preview' button.  A new window will open with the contents.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:[{name: 'preview', styles: 'body {background-color: lightgray;} table {border-style: groove; border-width: 3px; border-color: darkgray;} table tr {border-style: outset; border-width: 3px;} table tr td {border-style: inset; border-width: 3px;}'}]">
    <div>
    <br>
    blah blah & blah!
    <br>
    </div>
    <br>
    <table>
    <tbody>
    <tr>
    <td>One cell</td>
    <td>
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


Applying stylesheets to preview content
---------------------------------------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.4

  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.Preview");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/Preview.css";
    
  .. html ::

    <b>Enter whatever you like in the editor, then press the 'Preview' button.  A new window will open with the contents.</b>
    <br>
    <div data-dojo-type="dijit/Editor" height="250px" id="input" data-dojo-props="extraPlugins:[{name: 'preview', stylesheets: ['{{dataUrl}}dojox/editor/tests/testBodySheet.css', '{{dataUrl}}dojox/editor/tests/testContentSheet.css']}]">
    <div>
    <p>
    blah blah & blah!
    </p>
    </div>
    <br>
    <table>
    <tbody>
    <tr>
    <td>One cell</td>
    <td>
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
