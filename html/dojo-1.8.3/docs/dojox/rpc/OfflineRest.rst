.. _dojox/rpc/OfflineRest:

=======================
dojox.rpc.OfflineRest
=======================

:Authors: Kris Zyp
:Project owner: Kris Zyp
:since: V1.2

.. contents ::
   :depth: 2

dojox.rpc.OfflineRest provides automatic offline capabilities to the JsonRest/JsonRestStore modules.


Introduction
============

dojox.rpc.OfflineRest augments dojox.rpc.JsonRest and dojox.data.JsonRestStore such that all data modifications are persisted locally using any available local storage mechanism (via dojox.storage) and when connectivity is available, the changes are persisted to the server using the standard REST interface. This page contains `more information about using OfflineRest <http://www.sitepen.com/blog/2008/09/23/effortless-offline-with-offlinerest/>`_.


Usage
=====

To use OfflineRest, first load the OfflineRest module before your JsonRestStore:

.. js ::

   dojo.require("dojox.rpc.OfflineRest");
   dojo.require("dojox.data.JsonRestStore");

In order to indicate that a store should have offline support, simply add that store to the set of offline stores:

.. js ::
 
 trailStore = new dojox.data.JsonRestStore({url:"/Trail"});
 dojox.rpc.OfflineRest.addStore(trailStore, "");
