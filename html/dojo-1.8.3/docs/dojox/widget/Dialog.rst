.. _dojox/widget/Dialog:

===================
dojox.widget.Dialog
===================

:Project owner: Peter Higgins
:since: 1.2

.. contents ::
   :depth: 2

This is an extension to the :ref:`dojox.widget.DialogSimple <dojox/widget/DialogSimple>` providing additional sizing options, animations, and styling.

Introduction
============

This widget's usage is nearly identical to the Dijit Dialog. show() and hide() change the display state, set("title", "new title") will manipulate the title (if visible), and so on. The difference comes in the creation parameters set.

Usage
=====

You will need the CSS, as well as a Theme CSS file. For instance, tundra:

.. html ::

    <link rel="stylesheet" href="dojotoolkit/dijit/themes/claro/claro.css" />
    <link rel="stylesheet" href="dojotoolkit/dojox/widget/Dialog/Dialog.css" />

And to require the module in:

.. js ::

    dojo.require("dojox.widget.Dialog");

Examples
========

``TODOC:`` show off some of the sizing options.

Resize an existing Dialog:

.. html ::

    dlg.set("dimensions", [400, 200]); // [width, height]
    dlg.layout(); // starts the resize


Notes
=====

* An API change between 1.2 and 1.3 exists: the property ``fixedSized`` in 1.2 was renamed to ``sizeToViewport`` in 1.3 for clarity

See also
========

* :ref:`dijit.Dialog <dijit/Dialog>`
* :ref:`dojox.widget.DialogSimple <dojox/widget/DialogSimple>`
* `Nightly Test <http://archive.dojotoolkit.org/nightly/dojotoolkit/dojox/widget/tests/test_Dialog.html>`_
