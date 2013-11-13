.. _dojox/form/manager/_ClassMixin:

==============================
dojox.form.manager._ClassMixin
==============================

:Project owner: Eugene Lazutkin
:since: 1.3

.. contents ::
   :depth: 3

Introduction
============

This class is the component of the form manager. It should be used together with :ref:`\_Mixin <dojox/form/manager/_Mixin>`.

The mixin provides commonly used methods to add/remove a CSS class, or detect its presence. It operates only on form nodes and attached nodes (see :ref:`controlled elements <dojox/form/manager/index>` for more classification details).

Methods and properties
======================

This section describes all public methods and properties of the *dojox.form.manager._ClassMixin* class.

gatherClassState
~~~~~~~~~~~~~~~~

This method collects the presence of the specified CSS class in a dictionary object as Boolean values (``true`` means the CSS class is present). It is loosely modeled after :ref:`\_EnableMixin's gatherFromValues() <dojox/form/manager/_EnableMixin>`.

There are three ways to use this method:

1. Call it with the CSS class name and the array of names (represented by strings):

  .. js ::

    var names = ["firstName", "lastName"], cssClass = "marker"
    var state = fm.gatherClassState(cssClass, names);

  Only supplied names will be inspected for the presence of ``cssClass``.

2. Call it with the CSS class name and a dictionary (an object). Only keys will be used, values will be ignored:

  .. js ::

    var names = {firstName: 1, lastName: 1}, cssClass = "marker";
    var state = fm.gatherClassState(cssClass, names);

  Only supplied names will be inspected for the presence of ``cssClass``.

  This form is especially useful when we already collected values, and want to check them for a presence of a certain CSS class:

  .. js ::

    var names = ["firstName", "lastName"], cssClass = "marker";
    var values = fm.gatherFormValues(names);
    // later in the code
    var state  = fm.gatherClassState(cssClass, values);

3. The second parameter is ``null``, or ``undefined``, or missing. In this case all known form elements will be inspected:

  .. js ::

    var cssClass = "marker";
    var state = fm.gatherClassState(cssClass);

addClass
~~~~~~~~

This method works exactly like gatherClassState_ but instead of collecting the presence information it assigns a CSS class to listed elements. It always returns the form manager widget for easy chaining.

Example:

.. js ::

  // highlight firstName, use red background for lastName,
  // place black border around all elements:
  fm.addClass("hilite", ["firstName"]).
     addClass("redBg",  {lastName: 1}).
     addClass("blackBorder");

removeClass
~~~~~~~~~~~

This method works exactly like addClass_ but instead of adding a class it removes the specified class from listed elements.

Example:

.. js ::

  // undo the previous example:
  fm.removeClass("hilite", ["firstName"]).
     removeClass("redBg",  {lastName: 1}).
     removeClass("blackBorder");

Tips
====

Note that the dictionary form of addClass_ and removeClass_ methods always ignores values. While there is a way to collect the presence of a class, there is no direct way to reflect it back. If you want to do that you can use :ref:`inspect() <dojox/form/manager/_Mixin>` method of :ref:`_Mixin <dojox/form/manager/_Mixin>`:

.. js ::

  // make the inspector function
  var reflectClass = function(cssClass){
    // we use this approach for a closure to hide our CSS class
    return dojox.form.manager.actionAdapter(function(name, node, value){
      if(value){
        dojo.addClass(node, cssClass);
      }else{
        dojo.removeClass(node, cssClass);
      }
    });
  };

  // collect the presence of the "marker" class
  var state = fm.gatherClassState("marker");

  // reflect it back
  fm.inspect(reflectClass("marker"));
