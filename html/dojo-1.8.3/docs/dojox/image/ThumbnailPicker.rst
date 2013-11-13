.. _dojox/image/ThumbnailPicker:

===========================
dojox.image.ThumbnailPicker
===========================

:Project owner: ?--
:since: 1.0

.. contents ::
   :depth: 2

A :ref:`dojo.data-powered <dojo/data>` ThumbnailPicker.


Introduction
============


The ThumbnailPicker is a widget that displays a series of images either horizontally or vertically, with controls to page through the images. It reads its image data from data stores, that is, implementations of the dojo.data.api.Read API.

When an image is clicked by the user, information regarding that image is published to a dojo topic, which can be used to integrate the ThumbnailPicker with other objects on the page.

The ThumbnailPicker can be configured in a number of ways:

    * Number of visible images
    * Data source
    * Can be horizontal or vertical
    * Enabling/disabling following hyperlinks when an image is selected
    * Notification of load status for images

Examples
========

Number of Visible Images
------------------------

To set the number of visible images, and thereby the width or height of horizontal and vertical widgets respectively,
set the **numberThumbs** attribute, e.g.


.. js ::
  
  <div data-dojo-type="dojox.image.ThumbnailPicker" id="picker1" data-dojo-props="numberThumbs:4"> </div>



Setting the Data Source
-----------------------

To set the data source for the ThumbnailPicker widget, first create one of the available data stores, such
as the dojo.data.ItemFileReadStore or dojox.data.FlickrRestStore. Next, create a request object, which
optionally contains a query. e.g.

.. js ::
  
    dojo.ready(function(){
        // Define the request, saying that 20 records should be fetched at a time,
        // and to start at record 0
        
        var request= {count:20, start:0};
        // Tell the widget to request the "thumb" parameter, as different
        // stores may use different parameter names
        var itemNameMap = {imageThumbAttr: "thumb"};
        
        dijit.byId('picker1').setDataStore(imageItemStore, request, itemNameMap);
    });

.. html ::

    <div data-dojo-type="dojox.image.ThumbnailPicker" id="picker1"></div>
    <div data-dojo-id="imageItemStore" data-dojo-type="dojo.data.ItemFileReadStore" data-dojo-props="url:'images.json'"></div>


Using a Vertical Layout
-----------------------

To make the ThumbnailPicker display itself vertically, set the isHorizontal attribute to "false". To leave it as
horizontal, either omit the isHorizontal attribute, or set it to "true", e.g.


.. html ::
 
  <div data-dojo-type="dojox.image.ThumbnailPicker" id="picker1" data-dojo-props="isHorizontal:false"> </div>


Enabling/disabling following hyperlinks
---------------------------------------

To enable following a hyperlink when a thumbnail image is clicked, set the useHyperlink attribute to "true".
By default it is false. When hyperlinks are enabled, by default the URL is opened is a new window. To open
the link in the current window, set the hyperlinkTarget attribute to "this". e.g.


.. html ::
 
  <div data-dojo-type="dojox.image.ThumbnailPicker" id="picker1" data-dojo-props="useHyperlink:true, hyperlinkTarget:this"> </div>

Notification of load status for images
--------------------------------------

The ThumbnailPicker can display a notification for each image stating whether another version of it has loaded
or not, for example when it is combined with the dojox.image.Slideshow widget. When this is enabled, the
ThumbnailPicker relies on other code calling it's markImageLoaded method to change the notification from
its loading state to loaded state.

To enable the load state notifier, set the useLoadNotifier to "true". By default, it is disabled, since it only
really makes sense to use it in combination with other widgets or elements on a page. e.g.


.. html ::
  
  <div data-dojo-type="dojox.image.ThumbnailPicker" id="picker1" data-dojo-props="useLoadNotifier:true"> </div>


Setting size of thumbnails
--------------------------

Setting size of thumbnails is currently possible with use of CSS style definitions:

.. css ::
  
  .thumbWrapper img {
    height: 200px;
    max-width: 144px;
  }
  .thumbOuter.thumbHoriz, .thumbHoriz .thumbScroller {
    height: 200px;
  }


Example
-------

This example will put a horizontal dojox.image.ThumbnailPicker widget on a page, with a variety
of settings, and uses the FlickrRestStore data store.
 
.. code-example ::
  :djConfig: parseOnLoad: true

  .. js ::

    require(["dojo/_base/kernel"], function(dojo){
        dojo.require("dojo.parser");
        dojo.require("dojox.image.ThumbnailPicker");
        dojo.require("dojox.data.FlickrRestStore");

        dojo.ready(function(){
            // Create a new FlickrRestStore
            var flickrRestStore = new dojox.data.FlickrRestStore();

            // Create a request object, containing a query with the
            // userid, apikey and (optional) sort data.
            // Extra query parameters 'tags' and 'tag_mode' are also
            // used to further filter the results
            var req = {
               query: {
                   userid: "44153025@N00",
                   apikey: "8c6803164dbc395fb7131c9d54843627",
                   sort: [ {descending: true }],
                   tags: ["superhorse", "redbones", "beachvolleyball","dublin","croatia"],
                   tag_mode: "any"
               },
               start: 0, // start at record 0
               count: 20 // request 20 records each time a request is made
            };

            // Set the flickr data store on two of the dojox.image.ThumbnailPicker widgets
            dijit.byId('thumbPicker1').setDataStore(flickrRestStore, req);
        });
    });

  .. html ::

       <h2>From FlickrRestStore:</h2>
       This ThumbnailPicker should have 4 thumbnails, witheach of them linking
       to a URL when clicked on, changing the current page.  The cursor should also change when over an image.
       The widget is laid out in the default horizontal layout.
       <div id="thumbPicker1" data-dojo-type="dojox/image/ThumbnailPicker" data-dojo-props="numberThumbs:4, useHyperlink:true,
       hyperlinkTarget:this"></div>

  .. css ::

       @import "{{ baseUrl }}dojox/image/resources/image.css";


See also
========

* http://archive.dojotoolkit.org/nightly/dojotoolkit/dojox/image/tests/test_ThumbnailPicker.html
