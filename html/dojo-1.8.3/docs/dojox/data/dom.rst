.. _dojox/data/dom:

===============
dojox.data.dom
===============

:Project owner: ?--
:since: V?

.. contents ::
   :depth: 2

A set of DOM manipulation functions.

Introduction
============

When working with DOM objects, these additional functions can come in extremely handy.  Their relationship to each other is loose and they are basically a catch-all for functions not found elsewhere.


Usage
=====

createDocument
--------------
Cross-browser implementation of creating an XML document object.

.. js ::

  var foo:DOMDocument = dojox.data.dom.createDocument(str:String?, mimetype:String?);

innerXML
--------
Serialize an XML document to a string.


.. js ::

  var foo:String = dojox.data.dom.innerXML(node:Node);

removeChildren
--------------
Removes all children from node and returns the count of children removed. The children nodes are not destroyed.

.. js ::

  var foo:Integer = dojox.data.dom.removeChildren(node:Element);

replaceChildren
---------------
Removes all children of node and appends newChild. All the existing children will be destroyed.

.. js ::

  var foo = dojox.data.dom.replaceChildren(node:Element, newChildren:Node|Array);

textContent
-----------
Implementation of the DOM Level 3 attribute; scan node for text.  This function can also update the text of a node by replacing all child content of the node.

.. js ::

  var foo:String|empty string = dojox.data.dom.textContent(node:Node, text:String?);
