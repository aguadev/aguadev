.. _dijit/form/Textarea:

===================
dijit/form/Textarea
===================

:Authors: Doug Hays, Bill Keese, Nikolai Onken
:Developers: Doug Hays, Bill Keese
:since: V1.0

.. contents ::
    :depth: 2

A Textarea widget is like a regular HTML textarea element, but it dynamically resizes to fit the content of the text inside.
It takes nearly all the parameters (*name*, *value*, etc.) that a vanilla textarea takes.
The attribute *rows* is not supported since this widget adjusts the height.
It is especially useful in an :ref:`InlineEditBox <dijit/InlineEditBox>`.
Note that when declaring a Textarea in markup you should use a <textarea> node to preserve the newline formatting.


Examples
========

Programmatic example
--------------------

First we will create a Textarea widget programmatically.
Notice how we pass the *name*, *style* and *value* parameters into the object creation.

.. code-example ::
  :djConfig: async: true

  .. js ::

    require(["dijit/form/Textarea", "dojo/domReady!"], function(Textarea){
        var textarea = new Textarea({
            name: "myarea",
            value: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.",
            style: "width:200px;"
        }, "myarea").startup();;
    });

  .. html ::

    <textarea id="myarea"></textarea>

Declarative example
-------------------

Here we'll create a Textarea widget declaratively.
In this instance, the initial *value* is the child text node of the textarea element.

.. code-example ::
  :djConfig: async: true, parseOnLoad: true

  .. js ::

      require(["dojo/parser", "dijit/form/Textarea"]);

  .. html ::

    <textarea id="textarea2" name="textarea2" data-dojo-type="dijit/form/Textarea" style="width:200px;">Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.</textarea>


Accessibility
=============

Keyboard
--------

The Textarea widget uses native HTML textarea controls.


Known Issues (1.2 and before)
=============================

* On Firefox 2, the user must press the Tab key twice before keyboard focus moves to the next widget. (There is no problem when using Shift+Tab.)

* The attribute "cols" was not supported, but the CSS style *width* could be used instead.
