.. _dojox/grid/pluginAPI:

=====================
dojox Grid Plugin API
=====================

:Project owner: Nathan Toone, Bryan Forbes
:since: V1.4

.. contents ::
   :depth: 2

Introduction
============

We are working out a plugin api for the grid - this page will be updated with information on the various hooks, processes, and APIs available for extending the grid.

NOTE: This document is a living document - and will change at any time. It is also intended more for dojo developers than it is for end users.


Extension points
================

* You can set _layoutClass on a subclass of grid if you want to subclass a layout.
* You can set _headerBuilderClass or _contentBuilderClass on a subclass of a view if you want to subclass the builders.
