.. _dojo/ioPipelineTopics:

==================
IO Pipeline Topics
==================

:since: V1.4

.. contents ::
   :depth: 2

*Deprecated* - See :ref:`dojo/request/notify <dojo/request/notify>` instead.

Topics that are published via :ref:`dojo.publish <dojo/publish>` that correspond to events in the Input/Output (IO) pipeline used by Dojo.

Introduction
============

As of Dojo 1.4, there are topics that are published for the pipeline used to handle all IO operations. dojo.xhr, dojo.io.script and dojo.io.iframe all use the IO pipeline, so they can all publish the pipeline topics. By default, the topics are turned off. To enable them, set **dojoConfig.ioPublish = true**. After they are globally enabled, you can disable them for specific IO requests by setting **ioPublish: false** in the arg object you pass to dojo.xhr*(), dojo.io.script.get() or dojo.io.iframe.send().

Usage
=====

Here is a list of topics that you can subscribe to, with the parameters they pass:

.. js ::
    
  require(["dojo/topic"], function(topic){
    topic.subscribe("/dojo/io/start", function(){
      // Triggered when there are no outstanding IO requests,
      // and a new IO request is started. No arguments are passed with this topic.
    });

    topic.subscribe("/dojo/io/send", function(/*dojo.Deferred*/ dfd){
      // Triggered whenever a new IO request is started.
      // It passes the dojo.Deferred for the request.
    });

    topic.subscribe("/dojo/io/load", function(/*dojo.Deferred*/ dfd, /*Object*/ response){
      // Triggered whenever an IO request has loaded
      // successfully. It passes the response and the
      // dojo.Deferred for the request.
    });

    topic.subscribe("/dojo/io/error", function(/*dojo.Deferred*/ dfd, /*Object*/ response){
      // Triggered whenever an IO request has errored.
      // It passes the error and the dojo.Deferred
      // for the request with the topic.
    });

    topic.subscribe("/dojo/io/done", function(/*dojo.Deferred*/ dfd, /*Object*/ response){
      // Triggered whenever an IO request has completed,
      // either by loading or by erroring. It passes the error and
      // the dojo.Deferred for the request with the topic.
    });

    topic.subscribe("/dojo/io/stop", function(){
      // Triggered when all outstanding IO requests have
      // finished. No arguments are passed with this topic.
    });
  });

See also
========

* :ref:`dojo/topic <dojo/topic>`
