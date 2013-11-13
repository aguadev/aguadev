.. _dojox/data/AtomReadStore:

==========================
dojox.data.AtomReadStore
==========================

:Author: Shane O'Sullivan
:since: V1.2

.. contents ::
  :depth: 3


The AtomReadStore is a store designed to provide read-only access to `Atom XML <http://en.wikipedia.org/wiki/Atom_(standard)>`_ documents. Atom XML is a common document format for web feeds providing lists of data. It is similar in many respects to RSS, but provides much more flexibility.

API Support
===========

* :ref:`dojo.data.api.Read <dojo/data/api/Read>`

Constructor Params
==================

The following parameters are supported by the GoogleFeedStore implementation.

+---------------+------------------------------------------------------------------------------------------+----------------------+
| **name**      | **description**                                                                          | **type**             |
+---------------+------------------------------------------------------------------------------------------+----------------------+
|label          |The attribute of the search returns to use as the item's label. Defaults to               |string                |
|               |titleNoFormatting.                                                                        |                      |
+---------------+------------------------------------------------------------------------------------------+----------------------+
|url            |The url to a service or an XML document that represents the store                         |string                |
+---------------+------------------------------------------------------------------------------------------+----------------------+
|sendQuery      |A boolean indicate to add a query string to the service URL.                              | string               |
+---------------+------------------------------------------------------------------------------------------+----------------------+
|unescapeHTML   |A boolean to specify whether or not to unescape HTML text.                                | string               |
+---------------+------------------------------------------------------------------------------------------+----------------------+
|urlPreventCache|Parameter that allows enabling the xhrGet flag preventCache.  Defaults to false.          | boolean              |
|               |**New in Dojo 1.4.**                                                                      |                      |
+---------------+------------------------------------------------------------------------------------------+----------------------+

Item Attributes
===============

The following attributes are available on items returned from the AtomReadStore:

+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|**Attribute**    |**Description**                                                                                                                                                                                                                                                                             |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|title            |The feed entry title.                                                                                                                                                                                                                                                                       |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|link             |The URL for the HTML version of the feed entry.                                                                                                                                                                                                                                             |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|content          |The full content of the blog post. If unescapeHTML is true, this is returned in HTML. Otherwise it is returned in plain  text.                                                                                                                                                              |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|summary          |A snippet of information about the feed entry. If unescapeHTML is true, this is returned in HTML. Otherwise it is returned in plain text.                                                                                                                                                   |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|published        |The string date on which the entry was published.                                                                                                                                                                                                                                           |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|category         |An array of tags for the entry. Each category is a JSON object containing two values, 'scheme' and 'term'. E.g. '''store.getValue(item, 'category').term''' gives the category, or tag, value.                                                                                              |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|author           |A JSON object containing one or two elements, '''name''' and '''uri'''. The former is the name of the author, the latter is the authors personal uri, or web page. E.g. '''var author = store.getValue(item, 'author'); alert("Name is " + author.name + " and homepage is " + author.uri); |
+-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

Query Syntax
============

The query syntax for this store is simple. If the data source is a static url, e.g. an XML file, then no query syntax is used. The store simply reads the URL specified in the constructor. If the URL must have some parameters added to it, e.g. ''feed.php?user=1234'', then these parameters can be added in the query.

Query Example With One Parameter
--------------------------------

.. js ::

  {
    user: '1234'
  }


Example Usage of using AtomReadStore with a DataGrid
====================================================

.. code-example ::
  
  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.form.TextBox");
      dojo.require("dijit.layout.TabContainer");
      dojo.require("dijit.layout.ContentPane");
      dojo.require("dojox.data.AtomReadStore");
      dojo.require("dojox.grid.DataGrid");

      function hrefFormatter(value){
        return "<a href=\"" + value["href"] + "\" target=\"_blank\">Link</a>";
      }
      function textFormatter(value){
            return value["text"];
      }

      var layoutResults = [
        [
          { field: "title", name: "Title", width: 20 , formatter: textFormatter},
          { field: "link", name: "URL", width: 5, formatter: hrefFormatter},
          { field: "summary", name: "Summary", width: 'auto' , formatter: textFormatter}
        ]
      ];

  .. html ::

    <div data-dojo-type="dojox.data.AtomReadStore" data-dojo-id="feedStore" data-dojo-props="url:'{{dataUrl}}dojox/data/tests/stores/atom1.xml'"></div>
    <div id="feedGrid"
      data-dojo-id="feedGrid"
      style="width: 750px; height: 300px;"
      data-dojo-type="dojox.grid.DataGrid"
      data-dojo-props="store:feedStore,
      structure:'layoutResults',
      query:{},
      rowsPerPage:40">
    </div>

  .. css ::

      @import "{{baseUrl}}dojox/grid/resources/Grid.css";
      @import "{{baseUrl}}dojox/grid/resources/nihiloGrid.css";

      .dojoxGrid table {
        margin: 0;
      }
