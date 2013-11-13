.. _dojox/html/ellipsis:

===================
dojox.html.ellipsis
===================

:Authors: Nathan Toone
:since: V1.4

.. contents ::
    :depth: 2

**dojox.html.ellipsis** offers cross-browser support for `text-overflow: ellipsis`


Usage
=====

To use, just include the ellipsis.css file (found in the dojox/html/resources directory) and dojo.require("dojox.html.ellipsis") in your code.

You can then add "dojoxEllipsis" on any node that you want to ellipsis-ize.  In order to function properly, the node with the dojoxEllipsis class set on it should be a child of a node with a defined width.  It should also be a block-level element (i.e. <div>) - it will not work on td elements.

``NOTE:`` When using the dojoxEllipsis class within tables, the table needs to have the `table-layout: fixed` style


Selecting Text in FF
====================

The XUL description tag that is used to accomplish this functionality in Firefox has a couple of limitations.  First, it does not support any sort of markup within the text that is being truncated.  Second, the text that is displayed is not selectable via mouse cursor.  To overcome these limitations, there is an iframe-based truncation routine that can be used.  This method is much less efficient than the XUL (default) way - but exists for these special cases.  When a node contains markup within it, the iframe-based routine is automatically called.  If you wish to force a text-only node's text content to be selectable via mouse, you can specify an additional class on the node, called "dojoxEllipsisSelectable".

``NOTE:`` All other browsers besides Firefox will automatically handle HTML and the text will be selectable - without any performance hit.


Examples
========

Within a fixed-width div
------------------------

.. code-example ::

  .. js ::

      dojo.require("dojox.html.ellipsis");

  .. html ::

    <div style="width: 100px;">
        <div class="dojoxEllipsis">Long inner text that should be truncated after 100 pixels.</div>
    </div>

  .. css ::

      @import "{{baseUrl}}dojox/html/resources/ellipsis.css";

Forcing selectability in FF
---------------------------

.. code-example ::

  .. js ::

      dojo.require("dojox.html.ellipsis");

  .. html ::

    <div style="width: 100px;">
        <div class="dojoxEllipsis dojoxEllipsisSelectable">Long inner text that should be truncated after 100 pixels.</div>
    </div>

  .. css ::

      @import "{{baseUrl}}dojox/html/resources/ellipsis.css";

Within a table
--------------

.. code-example ::

  .. js ::

      dojo.require("dojox.html.ellipsis");

  .. html ::

    <table style="width: 75%; table-layout: fixed">
        <tr>
            <td width="25%"><div class="dojoxEllipsis">Long inner text that should be truncated if it gets too big.</div></td>
            <td width="75%"><div class="dojoxEllipsis">Long inner text that should be truncated if it gets too big.</div></td>
        </tr>
    </table>

  .. css ::

      @import "{{baseUrl}}dojox/html/resources/ellipsis.css";
