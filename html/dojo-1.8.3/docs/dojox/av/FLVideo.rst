.. _dojox/av/FLVideo:

================
dojox.av.FLVideo
================

:Project owner: Mike Wilcox
:Author: Mike Wilcox
:since: 1.2

.. contents ::
   :depth: 2

dojo.av.FLVideo provides the ability to play Flash movie files (FLVs) within the dojo environment. It Also plays the H264/M4V codec (high definition) with a little trickery: change the '.M4V' extension to '.flv'.


Introduction
============

dojo.av.FLVideo is a very full featured class that provides the ability to play FLV videos. Playlists are not currently supported, but different videos can be played with the same instance by passing a new URL in through the play() method. To initialize, pass in a few option arguments along with the video URL, and include the target node by id:

.. js ::
 
 var myVideo = new dojox.av.FLVideo({initialVolume:.1, mediaUrl:"video/Grog.flv", autoPlay:true, isDebug:false}, "vid");

FLVideo has the expected methods to control it:

* play( newUrl? ),
* seek( milliseconds ),
* and pause().

There is also volume() which is used as a getter/setter.

There are also a large amount of events that are triggered. These events can be viewed in the base class of dojox.av._Media. Ky events are: onLoad() for when the SWF is ready, onBuffer() which is checking if there is enough video downloaded to play, onDownloaded() for the amount of the movie downloaded, onMetaData() which contains the video properties, and onPlay(), onStart(), onEnd(), etc. See the source code or http://dojotoolkit.org/api/dojox/av/FLVideo for full details.


Examples
========

For examples, please refer to the test file in the SDK: dojox/av/tests/testFLVideo.html


See also
========

* :ref:`dojox.av <dojox/av>`
* :ref:`dojox.av.FLAudio <dojox/av/FLAudio>`
* :ref:`dojox.av.widget <dojox/av/widget>`
