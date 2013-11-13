.. _dojox/html/entities:

===================
dojox.html.entities
===================

:Authors: Jared Jurkiewicz
:Developers: Jared Jurkiewicz
:since: V1.4

.. contents ::
    :depth: 2

**dojox.html.entities** offers basic entity mapping for HTML and LATIN-1 (8859-1) characters, as well as helper functions for encoding and decoding entities in text strings

Features
========

* Complete entity map for HTML.
* Complete entity map for LATIN-1 (8859-1)
* Simple to use encode and decode functions.

Entity Map Format
=================

Users can use their own entity maps with the encode and decode functions, which makes them highly flexible.  So, how do users go about defining their own entity maps.  Simple, the format is an array of arrays and is as follows:

.. js ::

  [
     ["<UTF-8 character", "Entity encoding minus & and  ;"]
     ... // Any number of other mappings
  ];

So, for example say you want to *just* encode & characters to an entity representation.  You would define the map as follows:

.. js ::

  [
     ["\u0026", "amp"]
  ];

Then call the encode and decode functions with that as the map to use instead of the default maps.

Functions
=========

* :ref:`dojox.html.entities.encode <dojox/html/entities/encode>` - A function for encoding entity (special) characters in a text string
* :ref:`dojox.html.entities.decode <dojox/html/entities/decode>` - A function for decoding entity (special) characters in a text string

See Also
========

* :ref:`dojox.html <dojox/html>`
