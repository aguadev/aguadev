.. _dojox/image/Magnifier:

=====================
dojox.image.Magnifier
=====================

:Project owner: ?--
:since: 1.0

.. contents ::
   :depth: 2

A dojox.gfx-based version of the :ref:`MagnifierLite widget <dojox/image/MagnifierLite>`.


Introduction
============

The dojox.image.Magnifier widget is experimental and places an SVG "viewport" over an image and
magnifies the image underneath. The widget is an unobtrusive way to add an unstyled overlay above
the srcNode image element.  The overlay is a scaled version of the src image.  You might use this
widget to magnify a larger image which was scaled down.

Over-ride the _createGlass method to create your custom surface, being sure to create an img node on
that surface.

      

Examples
========

Programmatic example
--------------------
The following code fragment is from
`Dojo nightly archive <http://archive.dojotoolkit.org/nightly/checkout/dojox/image/tests/test_Magnifier.html>`_
and shows how dojox.image.Magnifier can be programmatically created.  The code fragment creates two buttons, the
first button with id="foob" creates a dojox.image.Magnifier and associates it with the image.  The second button
destroys it.

.. js ::
 

  <button data-dojo-type="dijit.form.Button" id="foob">Make It
  
    <script type="dojo/method" data-dojo-event="onClick">
       this.setAttribute("disabled", true);
       dijit.byId("foobd").setAttribute("disabled", false);
       new dojox.image.Magnifier({ scale:4.2, glassSize:200 }, "foobar");
    </script>
  </button>

  <button data-dojo-type="dijit.form.Button" id="foobd" disabled="disabled">Destroy It
    <script type="dojo/method" data-dojo-event="onClick">
        this.setAttribute("disabled", true);
        dijit.byId("foobar").destroy();
        console.log('layout changed:');
        dijit.byId("after1")._adjustScale();
        dijit.byId("after2")._adjustScale();
    </script>
  </button>

  
  <img id="foobar" style="width:300px; height:195px;" src="images/spanke.jpg" />



Declarative example
-------------------
The code fragment creates a dojox.image.Magnifier and associates it with the src image.

.. js ::
 
  Scale= 2.34, 5.67, and 8.90: <br>
  <img id="testImage" data-dojo-type="dojox.image.Magnifier" src="images/spanke.jpg"
    style="width:200px; height:130px;" scale="2.34" />
    
  <img id="testImage4" data-dojo-type="dojox.image.Magnifier" src="images/spanke.jpg"
    style="width:200px; height:130px;" scale="5.67" />

  <img id="testImage5" data-dojo-type="dojox.image.Magnifier" src="images/spanke.jpg"
    style="width:200px; height:130px;" scale="8.90" />

    

See also
========

* http://archive.dojotoolkit.org/nightly/checkout/dojox/image/tests/test_Magnifier.html
