.. _dojox/data/CsvStore:

===================
dojox.data.CsvStore
===================

:Author: Jared Jurkiewicz
:since: V1.0

.. contents ::
  :depth: 2

CsvStore is a simple read-only store provided by Dojo and contained in the DojoX project. CsvStore is a read interface that works with `CSV <http://en.wikipedia.org/wiki/Comma-separated_values>`_ formatted data files. The CSV file format is commonly known to folks who work regularly with spread sheet data. Like ItemFileReadStore, CsvStore reads the contents from an http endpoint or a JavaScript Data object that contains CSV formatted data. The following is an example of a CSV data source:

::
  
  Title, Year, Producer
  City of God, 2002, Katia Lund
  Rain,, Christine Jeffs
  2001: A Space Odyssey, , Stanley Kubrick
  "This is a ""fake"" movie title", 1957, Sidney Lumet
  Alien, 1979   , Ridley Scott
  "The Sequel to ""Dances With Wolves.""", 1982, Ridley Scott
  "Caine Mutiny, The", 1954, "Dymtryk ""the King"", Edward"

Note that in the above data, the first row is always assumed to be the column names. Those are what get assigned as the attribute names for the CSV items. Each row in the CSV data is treated as a single item.

The following dojo.data APIs are implemented by CsvStore

* :ref:`dojo.data.api.Read <dojo/data/api/Read>`
* :ref:`dojo.data.api.Identity <dojo/data/api/Identity>`

Constructor Params
==================

+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| **Parameter**  | **Required** | **Description**                                                                                | **Since** |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| url            | No           |This optional parameter specifies what URL from which to load the Csv data Note                 | 1.0       |
|                |              |that this URL is only loaded one time, as this is an in-memory data store.                      |           |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| data           | No           |A JavaScript String of Csv formatted data to use to populate the store. This parameter can be   | 1.0       |
|                |              |used instead of *url*. when you wish to load data differently then modify it to fit the expected|           |
|                |              |Csv format.                                                                                     |           |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| label          | No           |A string that identifies which column to treat as the human-readable label. It must match one of| 1.0       |
|                |              |the column labels in the file for it to be effective.                                           |           |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| separator      | No           |**New to Dojo Toolkit 1.4** The CsvStore can now take an optional character parameter to        | 1.4       |
|                |              |identify the delimiter of fields.  Comma is not longer required, but merely the default.        |           |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+
| urlPreventCache| No           |This boolean value controls whether dojo attempts to prevent the browser caching mechanism from | 1.4       |
|                |              |caching values loaded from a webserver.                                                         |           |
+----------------+--------------+------------------------------------------------------------------------------------------------+-----------+

Query Syntax
============

The query syntax used by dojox.data.CsvStore is identical to the query syntax used by :ref:`dojo.data.ItemFileReadStore <dojo/data/ItemFileReadStore>`

Query Options
=============

Dojo.data defines support for a 'queryOptions' modifier object that affects the behavior of the query. The two defined options listed by the API are *ignoreCase* and *deep*. CsvStore supports these options. The affect of these options on a query is defined below.

+------------+------------------------------------------------------------------------------------------------------------------------+
| **Option** | **Result**                                                                                                             |
+------------+------------------------------------------------------------------------------------------------------------------------+
| ignoreCase |The default is **false**. When set to true, the match on attributes is done in a case-insensitive fashion. This means   |
|            |with ignoreCase: true, a query of A* would match *Apple* and *acorn*                                                    |
+------------+------------------------------------------------------------------------------------------------------------------------+
| deep       |Ignored. Csv formatted data does not not support hierarchical data.                                                     |
+------------+------------------------------------------------------------------------------------------------------------------------+


Custom Sorting
==============

All fields in the CsvStore are read as strings.  Therefore, they are sorted as strings based on JavaScript's default string comparison algorithm.    This is not always what is desired, as Csv data can have fields which are intended to be numeric.  The good news is, this is easy to deal with.   CsvStore uses the dojo.data.util.sorter helper functions to implement item sorting. These functions provide a mechanism by which end users can customize how attributes are sorted. This is done by defining a *comparatorMap* on the store class. The comparator map maps an attribute name to some sorting function. The sorting function is expected to return 1, -1, or 0, base on whether the value for two items for the attribute was greater than, less than, or equal to, each other. An example of a custom sorter for attribute 'foo' is shown below:

.. js ::

  var csvData = "article,price\n";
  csvData += "1008,4.59\n";
  csvData += "1010,10.09\n";
  csvData += "1011,5.13\n";
  csvData += "1016,16.68\n";
  csvData += "1019,15.5\n";
  csvData += "1022,10.36\n";

  var store = new dojox.data.CsvStore({identifier: "article", data: csvData});

  // Define the comparator function for price, we want to numerically, instead of
  // string based sorting (As all fields in a CsvStore are parsed as strings).
  store.comparatorMap = {};
  store.comparatorMap["price"] = function(a,b){
    a = parseFloat(a);
    b = parseFload(b);
    return (a - b);
  };

  var sortAttributes = [{attribute: "price", descending: true}, { attribute: "article", descending: true}];
  function completed(items, findResult){
    for(var i = 0; i < items.length; i++){
      var value = store.getValue(items[i], "article");
      console.log("Item ID: [" + store.getValue(items[i], "article") + "] with price: [" + store.getValue(items[i], "price") + "]");
    }
  }
  function error(errData, request){
    console.log("Failed in sorting data.");
  }

  // Invoke the fetch.
  store.fetch({onComplete: completed, onError: error, sort: sortAttributes});


Examples
========

Connecting CsvStore to dijit.form.ComboBox
------------------------------------------

.. code-example ::
  
  .. js ::

      dojo.require("dojox.data.CsvStore");
      dojo.require("dijit.form.ComboBox");

      dojo.ready(function(){
          var storeData =   "firstname,lastname,age\n" +
                            "John, Doe, 21\n" +
                            "Jane, Doe, 22\n" +
                            "Richard, Smith, 43\n" +
                            "Sally, Smith, 49\n" +
                            "Lian, Zu, 23\n" +
                            "Ichiro, Kagetsume, 23\n"+
                            "Umeko, Tsuguri, 18\n" +
                            "Alptraum, Reisender, 25\n" +
                            "Thomas, Winthrope, 14\n";

          var personStore = new dojox.data.CsvStore({data: storeData});
          dijit.byId("combo").store = personStore;
      });

  .. html ::

    <div id="combo" data-dojo-type="dijit.form.ComboBox" data-dojo-props="searchAttr:'firstname'"></div>

    
Connecting CsvStore to dojox.grid.DataGrid
------------------------------------------

.. code-example ::

  .. js ::

      dojo.require("dojox.grid.DataGrid");
      dojo.require("dojox.data.CsvStore");

      dojo.ready(function(){
          var peopleData =  "firstname,lastname,age\n" +
                            "John, Doe, 21\n" +
                            "Jane, Doe, 22\n" +
                            "Richard, Smith, 43\n" +
                            "Sally, Smith, 49\n" +
                            "Lian, Zu, 23\n" +
                            "Ichiro, Kagetsume, 23\n"+
                            "Umeko, Tsuguri, 18\n" +
                            "Alptraum, Reisender, 25\n" +
                            "Thomas, Winthrope, 14\n";

          var personStoreForGrid= new dojox.data.CsvStore({data: peopleData});

          var layoutPeople = [
            [
              { field: "firstname", name: "First Name", width: 10 },
              { field: "lastname", name: "Last Name", width: 10 },
              { field: "age", name: "Age", width: 'auto' }
            ]
          ];
          dijit.byId("grid").setStructure(layoutPeople);
          dijit.byId("grid").setStore(personStoreForGrid, {});
      });

  .. html ::

    <div id="grid" style="width: 350px; height: 300px;"
      data-dojo-type="dojox.grid.DataGrid"
      data-dojo-props="query:{},
      rowsPerPage:40">
    </div>

  .. css ::

      @import "{{baseUrl}}dojox/grid/resources/Grid.css";
      @import "{{baseUrl}}dojox/grid/resources/tundraGrid.css";

Connecting CsvStore to dojox.grid.DataGrid where the data used a different separator
------------------------------------------------------------------------------------

.. code-example ::

  .. js ::

      dojo.require("dojox.grid.DataGrid");
      dojo.require("dojox.data.CsvStore");

      dojo.ready(function(){
          var peopleData2 =  "firstname|lastname|age\n" +
                            "John|Doe|21\n" +
                            "Jane|Doe|22\n" +
                            "Richard|Smith|43\n" +
                            "Sally|Smith|49\n" +
                            "Lian|Zu|23\n" +
                            "Ichiro|Kagetsume|23\n"+
                            "Umeko|Tsuguri|18\n" +
                            "Alptraum|Reisender|25\n" +
                            "Thomas|Winthrope|14\n";

          var personStoreForGrid2= new dojox.data.CsvStore({data: peopleData2, separator: '|'});

          var layoutPeople2 = [
            [
              { field: "firstname", name: "First Name", width: 10 },
              { field: "lastname", name: "Last Name", width: 10 },
              { field: "age", name: "Age", width: 'auto' }
            ]
          ];
          dijit.byId("grid2").setStructure(layoutPeople2);
          dijit.byId("grid2").setStore(personStoreForGrid2, {});
      });

  .. html ::

    <div id="grid2" style="width: 350px; height: 300px;"
      data-dojo-type="dojox.grid.DataGrid"
      data-dojo-props="query:{},
      rowsPerPage:40">
    </div>

  .. css ::

      @import "{{baseUrl}}dojox/grid/resources/Grid.css";
      @import "{{baseUrl}}/dojox/grid/resources/tundraGrid.css";
