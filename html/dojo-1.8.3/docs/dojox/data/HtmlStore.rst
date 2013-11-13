.. _dojox/data/HtmlStore:

=========================
dojox.data.HtmlStore
=========================

:Project owner: Jared Jurkiewicz
:since: V1.1

.. contents ::
  :depth: 2


HtmlStore is an improved version of the older :ref:`dojox.data.HtmlTableStore <dojox/data/HtmlTableStore>`. It is a simple read-only store provided by Dojo and contained in the DojoX project. HtmlTableStore is a read interface to work with HTML tables, Lists, and collections of DIV and SPAN tags with a generally set format. HTML tables, lists and DIV collections are common ways for Web data to be displayed. In Ajax applications they also remain extremely useful as an alternate representation of data that is displayed in a charting, dynamic grid, or gauge widget. This store was created so that widgets, that can use dojo.data data stores, can read their input from existing HTML structures (data islands) in the current page or in a remote page URL.


API Support
===========

* :ref:`dojo.data.api.Read <dojo/data/api/Read>`
* :ref:`dojo.data.api.Identity <dojo/data/api/Identity>`


Example data input
==================

The following examples are HTML structures that can be easily read by HtmlStore:


HTML table
----------

.. html ::
 
  <html>
  <head>
    <title>Books2.html</title>
  </head>
  <body>
  <table id="books2">
    <thead>
        <tr>
            <th>isbn</th>
            <th>title</th>
            <th>author</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>A9B57C</td>
            <td>Title of 1</td>
            <td>Author of 1</td>
        </tr>
        <tr>
            <td>A9B57F</td>
            <td>Title of 2</td>
            <td>Author of 2</td>
        </tr>
        <tr>
            <td>A9B577</td>
            <td>Title of 3</td>
            <td>Author of 3</td>
        </tr>
        <tr>
            <td>A9B574</td>
            <td>Title of 4</td>
            <td>Author of 4</td>
        </tr>
        <tr>
            <td>A9B5CC</td>
            <td>Title of 5</td>
            <td>Author of 5</td>
        </tr>
    </tbody>
  </table>
  </body>
  </html>

**Note:** The table rows in the <tbody> tag are the items. The <thead> tag is used for defining the attribute name for each column in the table row for an item.


List
----

.. html ::
  
  <ul id="myList">
    <li>Item 1</li>
    <li>Item 2</li>
    <li>Item 3</li>
    <li>Item 4</li>
    <li>Item 5</li>
    <li>Item 6</li>
    <li>Item 7</li>
    <li>Item 8</li>
    <li>Item 9</li>
    <li>Item 10</li>
  </ul>

**Note:** The <LI> entries are the items. Each has a single attribute 'name' which corresponds to the text content of the <LI>.


DIV Collection
--------------

.. html ::
  
  <div id="divList">
    <div>Item 1</div>
    <div>Item 2</div>
    <div>Item 3</div>
    <div>Item 4</div>
    <div>Item 5</div>
    <div>Item 6</div>
    <div>Item 7</div>
    <div>Item 8</div>
    <div>Item 9</div>
    <div>Item 10</div>
  </div>

**Note:** The <DIV> entries are the items. Each has a single attribute 'name' which corresponds to the text content of the <DIV>.


Constructor params
==================

The constructor for HtmlTableStore takes the following possible parameters in its keyword arguments:

+--------------+------------------------------------------------------------------------------------------+----------------------+
| **name**     | **description**                                                                          | **type**             |
+--------------+------------------------------------------------------------------------------------------+----------------------+
|url           |The URL from which to load the HTML file containing the HTML table. This is optional.     | string               |
+--------------+------------------------------------------------------------------------------------------+----------------------+
|dataId        |The id of the HTML tag that contains the table to read from, in either a remote page (if  | string               |
|              |the URL was passed) or in the current HTML DOM if the url parameter is null. This is      |                      |
|              |required.                                                                                 |                      |
+--------------+------------------------------------------------------------------------------------------+----------------------+
|trimWhitespace|**New to Dojo 1.4** Pre 1.4, the surrounding whitespace inside an attribute element, such | boolean              |
|              |as <td> in a table was treated as part of the attribute value.  This could potentially    |                      |
|              |cause problems if the tables were reformatted to include more whitespace, particularly in |                      |
|              |the header where attribute names are read.  So this store attribute was added.  If set to |                      |
|              |true HtmlStore ignores that whitespace (strips it off), when it indexes the attribute     |                      |
|              |headers and when it retrieves values.  The default is false for backwards compatibility.  |                      |
+--------------+------------------------------------------------------------------------------------------+----------------------+
|fetchOnCreate |**New to Dojo 1.6** Pre 1.6, the store populated itself on creation.  This cause issues   | boolean              |
|              |the target node was in a dialog.  So population was deferred to later.  This flag allows  |                      |
|              |to get the old behavior back if they need it.                                             |                      |
+--------------+------------------------------------------------------------------------------------------+----------------------+


Item Attributes
===============

The item attributes are defined by the type of tag set being referenced.

HTML Table:
  The <thead>  tag of the referenced table. Each column name becomes the attribute name for that column when generating the data store view of the data.

DIV collection:
  In a DIV collection, the items only contain one attribute/value pair, the text content. Use the attribute 'name' to acquire it.

List:
  In a list, the list items have one value, the text content. Use the attribute Use the attribute 'name' to acquire it.


Query Syntax
============

The query syntax is identical to :ref:`dojo.data.ItemFileReadStore <dojo/data/ItemFileReadStore>`. Please refer to it for the format of the queries.


Examples
========

Connecting HtmlStore to dijit.form.ComboBox
-------------------------------------------

.. code-example ::
  
  .. js ::

      dojo.require("dojox.data.HtmlStore");
      dojo.require("dijit.form.ComboBox");

  .. html ::

    <table id="myData" style="display: none;">
    <thead>
        <tr>
            <th>isbn</th>
            <th>title</th>
            <th>author</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>A9B57C</td>
            <td>Title of 1</td>
            <td>Author of 1</td>
        </tr>
        <tr>
            <td>A9B57F</td>
            <td>Title of 2</td>
            <td>Author of 2</td>
        </tr>
        <tr>
            <td>A9B577</td>
            <td>Title of 3</td>
            <td>Author of 3</td>
        </tr>
        <tr>
            <td>A9B574</td>
            <td>Title of 4</td>
            <td>Author of 4</td>
        </tr>
        <tr>
            <td>A9B5CC</td>
            <td>Title of 5</td>
            <td>Author of 5</td>
        </tr>
    </tbody>
    </table>

    <b>Combo lookup of isbn</b><br>
    <div data-dojo-type="dojox.data.HtmlStore" data-dojo-props="dataId:'myData', trimWhitespace:true" data-dojo-id="comboStore"></div>
    <div data-dojo-type="dijit.form.ComboBox" data-dojo-props="store:comboStore, searchAttr:'isbn'"></div>


Connecting HtmlStore to dojox.grid.DataGrid
-------------------------------------------

.. code-example ::
  
  .. js ::

      dojo.require("dojox.data.HtmlStore");
      dojo.require("dojox.grid.DataGrid");

      var layoutBooks = [
        [
          { field: "isbn", name: "ISBN", width: 10 },
          { field: "author", name: "Author", width: 10 },
          { field: "title", name: "Title", width: 'auto' }
        ]
      ];


  .. html ::

    <b>Standard HTML table:</b><br>
    <table id="myData2">
    <thead>
        <tr>
            <th>isbn</th>
            <th>title</th>
            <th>author</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>A9B57C</td>
            <td>Title of 1</td>
            <td>Author of 1</td>
        </tr>
        <tr>
            <td>A9B57F</td>
            <td>Title of 2</td>
            <td>Author of 2</td>
        </tr>
        <tr>
            <td>A9B577</td>
            <td>Title of 3</td>
            <td>Author of 3</td>
        </tr>
        <tr>
            <td>A9B574</td>
            <td>Title of 4</td>
            <td>Author of 4</td>
        </tr>
        <tr>
            <td>A9B5CC</td>
            <td>Title of 5</td>
            <td>Author of 5</td>
        </tr>
    </tbody>
    </table>
    <br>
    <br>

    <b>dojox.grid.DataGrid connected to the above table:</b><br>
    <div data-dojo-type="dojox.data.HtmlStore" data-dojo-props="dataId:'myData2', trimWhitespace:true" data-dojo-id="gridStore"></div>
    <div style="width: 400px; height: 200px;">
      <div id="grid"
        data-dojo-type="dojox.grid.DataGrid"
        data-dojo-props="store:gridStore,
        structure:layoutBooks,
        query:{},
        rowsPerPage:40">
      </div>
    </div>

  .. css ::

      @import "{{baseUrl}}dojox/grid/resources/Grid.css";
      @import "{{baseUrl}}dojox/grid/resources/nihiloGrid.css";

      .dojoxGrid table {
        margin: 0;
      }


Connecting HtmlStore with List to dijit.form.ComboBox
-----------------------------------------------------

.. code-example ::
  
  .. js ::

      dojo.require("dojox.data.HtmlStore");
      dojo.require("dojox.grid.DataGrid");
      dojo.require("dijit.form.ComboBox");

  .. html ::

    <b>Standard HTML Ordered List:</b><br>
    <ul id="myList2">
      <li>Item 1</li>
      <li>Item 2</li>
      <li>Item 3</li>
      <li>Item 4</li>
      <li>Item 5</li>
      <li>Item 6</li>
      <li>Item 7</li>
      <li>Item 8</li>
      <li>Item 9</li>
      <li>Item 10</li>
    </ul>
    <br>
    <br>

    <b>dijit.form.ComboBox connected to the above list:</b><br>
    <div data-dojo-type="dojox.data.HtmlStore" data-dojo-props="dataId:'myList2', trimWhitespace:true" data-dojo-id="comboStore2"></div>
    <div data-dojo-type="dijit.form.ComboBox" data-dojo-props="store:comboStore2, searchAttr:'name'"></div>


Connecting HtmlStore with DIV collection to dijit.form.ComboBox
---------------------------------------------------------------

.. code-example ::
  
  .. js ::

      dojo.require("dojox.data.HtmlStore");
      dojo.require("dojox.grid.DataGrid");
      dojo.require("dijit.form.ComboBox");

  .. html ::

    <b>DIV collection:</b><br>
    <div id="divList2">
      <div>Item 1</div>
      <div>Item 2</div>
      <div>Item 3</div>
      <div>Item 4</div>
      <div>Item 5</div>
      <div>Item 6</div>
      <div>Item 7</div>
      <div>Item 8</div>
      <div>Item 9</div>
      <div>Item 10</div>
    </div>
    <br>
    <br>

    <b>dijit.form.ComboBox connected to the above list:</b><br>
    <div data-dojo-type="dojox.data.HtmlStore" data-dojo-props="dataId:'divList2', trimWhitespace:true" data-dojo-id="comboStore3"></div>
    <div data-dojo-type="dijit.form.ComboBox" data-dojo-props="store:comboStore3, searchAttr:'name'"></div>
