.. _dojox/atom/io/model/Content:

===========================
dojox.atom.io.model.Content
===========================

:Project owner: Benjamin Schell
:since: V1.3

.. contents ::
   :depth: 2

This object represents Content style elements of the Atom specification, such as title, subtitle, summary, content, etc.


Public properties (and their types)
===================================

+----------------------------+-----------------+---------------------------------------------------------------------------------------------+
| **Type**                   | **Property**    | **Description**                                                                             |
+----------------------------+-----------------+---------------------------------------------------------------------------------------------+
| String                     | tagName         | The name of this element, such as content, summary, and so on.                              |
+----------------------------+-----------------+---------------------------------------------------------------------------------------------+
| String                     | value           | The value of this element                                                                   |
+----------------------------+-----------------+---------------------------------------------------------------------------------------------+
| String                     | src             | The URL that contains the value of this element                                             |
+----------------------------+-----------------+---------------------------------------------------------------------------------------------+
| String                     | type            | The type of content stored in this element. Acceptable values are listed below.             |
|                            |                 |                                                                                             |
|                            |                 |  * HTML                                                                                     |
|                            |                 |  * TEXT                                                                                     |
|                            |                 |  * XHTML                                                                                    |
|                            |                 |  * XML                                                                                      |
+----------------------------+-----------------+---------------------------------------------------------------------------------------------+
| String                     | xmlLang         | The language of the content. This language is included in the output if this element is put |
|                            |                 | to a string.                                                                                |
+----------------------------+-----------------+---------------------------------------------------------------------------------------------+


Public functions (and their return types)
=========================================

Below are all the functions implemented by this model class.


+-------------------+------------------------------------------------------+-------------------------------------------------------------+
| **Return Type**   | **Function**                                         | **Description**                                             |
+-------------------+------------------------------------------------------+-------------------------------------------------------------+
| Boolean           | accept(String)                                       | Returns whether this item accepts the given tag name.       |
|                   |                                                      | Overridden by child classes                                 |
+-------------------+------------------------------------------------------+-------------------------------------------------------------+
| undefined         | buildFromDom(DOMNode)                                | Builds this Content from a given DOMNode.                   |
+-------------------+------------------------------------------------------+-------------------------------------------------------------+
| String            | toString()                                           | Return the XML representation of the Content                |
+-------------------+------------------------------------------------------+-------------------------------------------------------------+


See Also
========

* :ref:`dojox.atom.io.model <dojox/atom/io/model>`
