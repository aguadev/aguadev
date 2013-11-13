.. _dojox/data/GoogleNewsSearchStore:

================================
dojox.data.GoogleNewsSearchStore
================================

:Project owner: Shane O'Sullivan
:since: 1.2?

.. contents ::
   :depth: 2

dojox.data.GoogleNewsSearchStore is a data store that uses Google APIs to search news sources.

Introduction
============

dojox.data.GoogleNewsSearchStore is a read only data store that can be used to search Google.  It implements the 'dojo.data.api.Read API <dojo/data/api/Read>'_, which you should refer to for general usage.

Usage
=====

The pattern of using the GoogleNewsSearchStore is
 * Instantiate the class, passing in whatever variables required, all of which are optional.  These include:

  * **label** The argument to use as the label.  This is used when the **getLabel** function is called to retrieve the correct part of the data item.  You generally shouldn't set this.
  * **key** Your Google API key.  This is optional, and should only be used if you for some reason want Google to track the number of requests made by your code (for analytical purposes maybe)
  * **lang** The language you want the results returned in.  This defaults to the browsers' language.
  * **urlPreventCache** Specifies whether or not to forcibly prevent caching of results.  This defaults to true.

 * Call the **fetch** method, passing it the search query and the function to call when the query is completed.  The only supported attribute of the query is **text**, the text to search for.
 * Iterate over the results, calling the **getValue** function to retrieve values from each result item.  The pieces of data in each result item are

  * **title** The page title in HTML format
  * **titleNoFormatting** The page title in plain text. This is the default field used as the label.
  * **content** A snippet of information about the page
  * **url** The URL for the item.
  * **unescapedUrl** The URL for the item, with URL escaping. This is often more readable.
  * **clusterUrl** A URL pointing to a page listing related stories
  * **publisher** The name of the publisher
  * **publishedDate** The date of publication, in RFC-822 format
  * **relatedStories** An optional array of objects specifying related stories.

.. js ::
 
  dojo.require("dojox.data.GoogleSearchStore");
  var store = new dojox.data.GoogleNewsSearchStore();

  var query = {text: "Ajax"};

  var callbackFunction = function(/*Array*/ items){
    
    console.log("Successfully retrieved " + items.length + " items for the query '" + query.text + "'");
    dojo.forEach(items, function(item){
      console.log ("Title is " + store.getValue(item, "title"));
      console.log ("Url is " + store.getValue(item, "unescapedUrl"));
      console.log ("Summary Content is " + store.getValue(item, "content"));
      console.log ("Publisher is " + store.getValue(item, "publisher"));
    })
  };

  var onErrorFunction = function(){
    console.log("An error occurred getting Google Search data");
  }

  store.fetch({
    query: query,
    count: 20,
    start: 0,
    onComplete: callbackFunction,
    onError: onErrorFunction
  });


Examples
========

Programmatic example
--------------------

.. code-example::

  .. js ::

    dojo.require("dojox.data.GoogleSearchStore");

    function doSearch(){

      var store = new dojox.data.GoogleNewsSearchStore();

      var query = {text: dojo.byId("searchInput").value};

      var callbackFunction = function(/*Array*/ items){

        var table = dojo.byId("resultTable");
        var tableBody = table.tBodies[0];
        dojo.empty(tableBody);

        // Show the table
        dojo.style(table, "display", "");

      
        dojo.forEach(items, function(item, index){
          var row = dojo.create("tr", {}, tableBody);
  
          var numberCell = dojo.create("td", {innerHTML: index}, row);

          var titleCell = dojo.create("td", {innerHTML: store.getValue(item, "titleNoFormatting")}, row);

          var urlCell = dojo.create("td", {}, row);
          dojo.create("a", {
                             href: store.getValue(item, "unescapedUrl"),
                             innerHTML: store.getValue(item, "unescapedUrl")
                           }, urlCell);
        })
      };

      var onErrorFunction = function(){
        console.log("An error occurred getting Google Search data");
      }

      store.fetch({
        query: query,
        count: 20,
        start: 0,
        onComplete: callbackFunction,
        onError: onErrorFunction
      });
      console.log("called fetch with query", query);

    }

  .. html ::

    <div>
      <span>Enter Search Text</span>
      <input type="text" value="Ajax" id="searchInput">
      <button onclick="doSearch()">Search</button>
    </div>

    <table id="resultTable" style="border: 1px solid black; display: none;">
      <thead>
        <th>#</th>
        <th>Title</th>
        <th>URL</th>
      </thead>
      <tbody>
      </tbody>
    </table>

See also
========

* TODO: links to other related articles
