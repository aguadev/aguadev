.. _dojox/grid/EnhancedGrid/plugins/Cookie:

======================================
dojox.grid.EnhancedGrid.plugins.Cookie
======================================

:Authors: Oliver Zhu
:Project owner: Evan Huang
:since: V.1.6

Cookie plugin provides a convenient ways to persist grid properties like column width, sorting order, etc, so the grid will look same when the page is reloaded, or when the grid is re-created with the same id.

.. contents ::
   :depth: 2

Introduction
============

Cookie is a plugin for dojox.grid.EnhancedGrid. It is used to persist grid properties in browser cookie.

Configuration
=============

Prerequisites
-------------

This cookie plugin is only available for EnhancedGrid, so use the following statement in the head of your HTML file:

.. js ::
  
  dojo.require("dojox.grid.EnhancedGrid");
  dojo.require("dojox.grid.enhanced.plugins.Cookie");


Plugin Declaration
------------------

The declaration name of this plugin is ``cookie`` . It is declared in the ``plugins`` property of grid.

If your grid is created declaratively:

.. html ::
  
  <div id="grid" data-dojo-type="dojox.grid.EnhancedGrid"
    data-dojo-props="store:mystore, structure:'mystructure',
    plugins:{
      cookie: /* a Boolean value or an configuration object */{}
  }" ></div>

If your grid is created in JavaScript:

.. js ::
  
  var grid = new dojox.grid.EnhancedGrid({
    id:"grid",
    store:"mystore",
    structure:"mystructure",
    plugins:{
      cookie: /* a Boolean value or an configuration object */{}
    }
  });

The available configuration properties are:

==============  ==================  ===============  ==============================================
Property        Type                Default Value    Description
==============  ==================  ===============  ==============================================
cookieProps     dojo.__cookieProps  {}               Set the cookie properties. See dojo.cookie.js
==============  ==================  ===============  ==============================================

All the persistable grid features will be stored in cookie by default. If you'd like to disable some of them, you can declare in the configuration object:

.. js ::
  
  var grid = new dojox.grid.EnhancedGrid({
    id:"grid",
    store:"mystore",
    structure:"mystructure",
    plugins:{
      cookie: {
        cellWidth: false  // Do not persist column width.
      }
    }
  });

The cookie names of currently supported grid features are:

* **cellWidth**
* **sortProps**
* **columnOrder**
* **nestedSortProps**  (only available when nestedSorting plugin is used)

Usage
=====

This plugin exposes the following methods to the grid:

setCookieEnabled(cookieName, toEnable):
    If a grid feature (maybe a plugin) wants to persist something in the cookie, it will provide a name for this feature. Users can use this name to enable/disable the persistence of this feature.

==============  ==================  ==========================  ==============================================================================================
Arguments       Type                Optional/Mandatory          Description
==============  ==================  ==========================  ==============================================================================================
cookieName      String              Mandatory                   A name of a grid feature. If null or undefined, this function will apply to all supported
                                                                grid features.
toEnable        Boolean             Mandatory                   To enable cookie for a grid feature or not.
==============  ==================  ==========================  ==============================================================================================

getCookieEnabled(cookieName):
    Check whether the cookie support of a particular grid feature is enabled.

==============  ==================  ==========================  ==============================================================================================
Arguments       Type                Optional/Mandatory          Description
==============  ==================  ==========================  ==============================================================================================
cookieName      String              Optional                    A name of a grid feature. If omitted, this function will apply to all supported grid features.
[return]        Boolean                                         If cookieName is valid, return whether the cookie of this grid feature is enabled.
                                                                If no arguments exist, return whether cookie is enabled for this grid.
==============  ==================  ==========================  ==============================================================================================


removeCookie():
    Clear the grid cookie.


Here is some examples on how to use the API:

.. js ::
    
  // Do not persist column width
  grid.cookieEnabled("cellWidth", false);
  
  // Check whether cookie is used in this grid
  var isEnabled = grid.cookieEnabled();

See Also
========

* :ref:`dojox.grid.DataGrid <dojox/grid/DataGrid>` - The base grid
* :ref:`dojox.grid.EnhancedGrid <dojox/grid/EnhancedGrid>` - The enhanced grid supporting plugins
* :ref:`dojox.grid.EnhancedGrid.plugins <dojox/grid/EnhancedGrid/plugins>` - Overview of the plugins of enhanced grid
* :ref:`dojox.grid.TreeGrid <dojox/grid/TreeGrid>` - Grid with collapsible rows and model-based (:ref:`dijit.tree.ForestStoreModel <dijit/tree/ForestStoreModel>`) structure
