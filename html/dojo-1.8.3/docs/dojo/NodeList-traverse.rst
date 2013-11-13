.. _dojo/NodeList-traverse:

========================
dojo.NodeList-traverse
========================

:Project owner: James Burke
:since: 1.4

.. contents ::
   :depth: 2

Method extensions to :ref:`dojo.NodeList <dojo/NodeList>`/:ref:`dojo.query <dojo/query>` for traversing the DOM. These methods are intended to match the API naming and behavior as the similarly named methods in jQuery.

Introduction
============

Doing a dojo.require("dojo.NodeList-traverse") (since Dojo 1.7 you're suggested to use AMD-style module loading, e.g. require(["dojo/NodeList-traverse"])) will add some addition methods to :ref:`dojo.NodeList <dojo/NodeList>` (the return object from a :ref:`dojo.query <dojo/query>` call) that allow easier traversal of the DOM as it relates to the nodes in the dojo.NodeList.


Usage
=====

Here is a simple example showing how dojo.NodeList-traverse adds a "children" method to dojo.NodeList that can be called via the normal method chaining done with a dojo.query result:

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // Grabs all child nodes of all divs
  // and returns a dojo.NodeList object
  // to allow further chaining operations
  dojo.query("div").children();


[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // Grabs all child nodes of all divs
    // and returns a dojo.NodeList object
    // to allow further chaining operations
    query("div").children();
  });


Methods added by dojo.NodeList-traverse
=========================================

children
---------
Returns all immediate child elements for nodes in this dojo.NodeList.
Optionally takes a query to filter the child elements.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue">Blue One</div>
    <div class="red">Red Two</div>
    <div class="blue">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the four child divs in a dojo.NodeList:
  dojo.query(".container").children();

  // This code returns the two divs that have the class "red" in a dojo.NodeList:
  dojo.query(".container").children(".red");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the four child divs in a dojo.NodeList:
    query(".container").children();

    // This code returns the two divs that have the class "red" in a dojo.NodeList:
    query(".container").children(".red");
  });

closest
---------
Returns closest parent that matches query, **including** current node in this
dojo.NodeList if it matches the query. Optionally takes a query to filter the closest nodes.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue">Blue One</div>
    <div class="red">Red Two</div>
    <div class="blue">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the div with class "container" in a dojo.NodeList:
  dojo.query(".red").closest(".container");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the div with class "container" in a dojo.NodeList:
    query(".red").closest(".container");
  });


parent
---------
Returns immediate parent elements for nodes in this dojo.NodeList.
Optionally takes a query to filter the parent elements.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    <div class="blue first"><span class="text">Blue One</span></div>
    <div class="red">Red Two</div>
    <div class="blue"><span class="text">Blue Two</span></div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two divs with class "blue" in a dojo.NodeList:
  dojo.query(".text").parent();

  // This code returns the one div with class "blue" and "first" in a dojo.NodeList:
  dojo.query(".text").parent(".first");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two divs with class "blue" in a dojo.NodeList:
    query(".text").parent();

    // This code returns the one div with class "blue" and "first" in a dojo.NodeList:
    query(".text").parent(".first");
  });


parents
---------
Returns all parent elements for nodes in this dojo.NodeList.
Optionally takes a query to filter the parent elements.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    <div class="blue first"><span class="text">Blue One</span></div>
    <div class="red">Red Two</div>
    <div class="blue"><span class="text">Blue Two</span></div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two divs with class "blue" and the div with class "container" in a dojo.NodeList:
  dojo.query(".text").parents();

  // This code returns the one div with class "container" in a dojo.NodeList:
  dojo.query(".text").parents(".container");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two divs with class "blue" and the div with class "container" in a dojo.NodeList:
    query(".text").parents();

    // This code returns the one div with class "container" in a dojo.NodeList:
    query(".text").parents(".container");
  });

siblings
---------
Returns all sibling elements for nodes in this dojo.NodeList.
Optionally takes a query to filter the sibling elements.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue first">Blue One</div>
    <div class="red">Red Two</div>
    <div class="blue">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two div with class "red" and the other div
  // with class "blue" that does not have "first". in a dojo.NodeList:
  dojo.query(".first").siblings();

  // This code returns the two div with class "red" in a dojo.NodeList:
  dojo.query(".first").siblings(".red");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two div with class "red" and the other div
    // with class "blue" that does not have "first". in a dojo.NodeList:
    query(".first").siblings();

    // This code returns the two div with class "red" in a dojo.NodeList:
    query(".first").siblings(".red");
  });

next
---------
Returns the next element for nodes in this dojo.NodeList.
Optionally takes a query to filter the next elements.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue first">Blue One</div>
    <div class="red">Red Two</div>
    <div class="blue last">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the div with class "red" and has innerHTML of "Red Two" in a dojo.NodeList:
  dojo.query(".first").next();

  // This code does not match any nodes so it returns an empty dojo.NodeList:
  dojo.query(".last").next(".red");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the div with class "red" and has innerHTML of "Red Two" in a dojo.NodeList:
    query(".first").next();

    // This code does not match any nodes so it returns an empty dojo.NodeList:
    query(".last").next(".red");
  });


nextAll
---------
Returns all sibling elements that come after the nodes in this dojo.NodeList.
Optionally takes a query to filter the sibling elements.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue first">Blue One</div>
    <div class="red next">Red Two</div>
    <div class="blue next">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two divs with class of "next":
  dojo.query(".first").nextAll();

  // This code returns the one div with class "red" and innerHTML "Red Two".
  dojo.query(".first").nextAll(".red");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two divs with class of "next":
    query(".first").nextAll();

    // This code returns the one div with class "red" and innerHTML "Red Two".
    query(".first").nextAll(".red");
  });

prev
---------
Returns the previous element for nodes in this dojo.NodeList.
Optionally takes a query to filter the previous elements.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue first">Blue One</div>
    <div class="red">Red Two</div>
    <div class="blue last">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the div with class "red" and has innerHTML of "Red One" in a dojo.NodeList:
  dojo.query(".first").prev();

  // This code does not match any nodes so it returns an empty dojo.NodeList:
  dojo.query(".first").prev(".blue");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the div with class "red" and has innerHTML of "Red One" in a dojo.NodeList:
    query(".first").prev();

    // This code does not match any nodes so it returns an empty dojo.NodeList:
    query(".first").prev(".blue");
  });


prevAll
---------
Returns all sibling elements that come before the nodes in this dojo.NodeList.
Optionally takes a query to filter the previous elements.

The returned nodes will be in reverse DOM order -- the first node in the list will be the node closest to the original node/NodeList.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red prev">Red One</div>
    Some Text
    <div class="blue prev">Blue One</div>
    <div class="red second">Red Two</div>
    <div class="blue last">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two divs with class of "prev":
  dojo.query(".first").prevAll();

  // This code returns the one div with class "red prev" and innerHTML "Red One":
  dojo.query(".first").prevAll(".red");

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two divs with class of "prev":
    query(".first").prevAll();

    // This code returns the one div with class "red prev" and innerHTML "Red One":
    query(".first").prevAll(".red");
  });


andSelf
---------
Adds the nodes from the previous dojo.NodeList to the current dojo.NodeList.

.end() can be used on the returned dojo.NodeList to get back to the
original dojo.NodeList.

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red prev">Red One</div>
    Some Text
    <div class="blue prev">Blue One</div>
    <div class="red second">Red Two</div>
    <div class="blue">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two divs with class of "prev", as well as the div with class "second":
  dojo.query(".second").prevAll().andSelf();

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two divs with class of "prev", as well as the div with class "second":
    query(".second").prevAll().andSelf();
  });


first
---------
Returns the first node in this dojo.NodeList as a dojo.NodeList.

This method is provided due to a difference in the Acme query engine used by default in Dojo. The Acme engine does not support ":first" queries, since it is not part of the CSS3 spec. This method can be used to give the same effect. For instance, instead of doing dojo.query("div:first"), you can do dojo.query("div").first().

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue first">Blue One</div>
    <div class="red">Red Two</div>
    <div class="blue last">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the div with class "blue" and "first" in a dojo.NodeList:
  dojo.query(".blue").first();

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the div with class "blue" and "first" in a dojo.NodeList:
    query(".blue").first();
  });


last
---------
Returns the last node in this dojo.NodeList as a dojo.NodeList.

This method is provided due to a difference in the Acme query engine used by default in Dojo. The Acme engine does not support ":last" queries, since it is not part of the CSS3 spec. This method can be used to give the same effect. For instance, instead of doing dojo.query("div:last"), you can do dojo.query("div").last().

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="red">Red One</div>
    Some Text
    <div class="blue first">Blue One</div>
    <div class="red">Red Two</div>
    <div class="blue last">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the last div with class "blue" in a dojo.NodeList:
  dojo.query(".blue").last();

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the last div with class "blue" in a dojo.NodeList:
    query(".blue").last();
  });


even
---------
Returns the even nodes in this dojo.NodeList as a dojo.NodeList.

This method is provided due to a difference in the Acme query engine used by default in Dojo. The Acme engine does not support ":even" queries, since it is not part of the CSS3 spec. This method can be used to give the same effect. For instance, instead of doing dojo.query("div:even"), you can do dojo.query("div").even().

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="interior red">Red One</div>
    <div class="interior blue">Blue One</div>
    <div class="interior red">Red Two</div>
    <div class="interior blue">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two divs with class "blue" in a dojo.NodeList:
  dojo.query(".interior").even();

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two divs with class "blue" in a dojo.NodeList:
    query(".interior").even();
  });


odd
---------
Returns the odd nodes in this dojo.NodeList as a dojo.NodeList.

This method is provided due to a difference in the Acme query engine used by default in Dojo. The Acme engine does not support ":odd" queries, since it is not part of the CSS3 spec. This method can be used to give the same effect. For instance, instead of doing dojo.query("div:odd"), you can do dojo.query("div").odd().

**Example**

Assume a DOM created by this markup:

.. html ::
  
  <div class="container">
    <div class="interior red">Red One</div>
    <div class="interior blue">Blue One</div>
    <div class="interior red">Red Two</div>
    <div class="interior blue">Blue Two</div>
  </div>

[ Dojo 1.6 and earlier ]

.. js ::
  
  dojo.require("dojo.NodeList-traverse");
  
  // This code returns the two divs with class "red" in a dojo.NodeList:
  dojo.query(".interior").odd();

[ Dojo 1.7 AMD ]

.. js ::
  
  require(["dojo/query", "dojo/NodeList-traverse"], function(query){
    // This code returns the two divs with class "red" in a dojo.NodeList:
    query(".interior").odd();
  });
