.. _dojox/color/Palette:

===================
dojox.color.Palette
===================

:Author: Tom Trenka
:since: Dojo Toolkit 1.1+

The Palette is a constructor that allows to create a 5-color palette either from a
single base color and a color theory, or a set of passed colors.  In addition to
generating a color palette, it can also *transform* the colors in that palette,
similar to the way one can transform graphics using dojox.gfx.

Within DojoX, the Palette is used extensively within the :ref:`dojox.charting <dojox/charting>`
project for themes.

To create a Palette based on a set of colors, simply pass them into the constructor:

.. js ::
  
  var p = new dojox.color.Palette("#f1c4d2");
  var p = new dojox.color.Palette([ c1, c2, c3, c4, c5 ]);
  var p = new dojox.color.Palette(myColor);  // instanceof dojo.Color
  var p1 = new dojox.color.Palette(p);       // clone the last palette

To access the colors in the palette, simply iterate through the ``.colors`` property:

.. js ::
  
  var p = dojox.color.Palette.generate("#789abc", "splitComplementary");
  dojo.forEach(p.colors, function(c){
      // do something with each dojo.Color object
  });

To perform a *translation* on a palette, pass a keyword arguments object to the ``transform``
method of the palette.  The keyword arguments object takes the form of:

.. js ::
  
  var args = {
      use: "rgb" || "rgba" || "hsl" || "hsv" || "cmy" || "cmyk",
      dr, dg, db, da,
      dc, dm, dy, dk,
      dh, ds, dl, dv
  };

All keywords are optional, including the ``use`` keyword--though you'll probably want to pass it
anyways.

The *use* keyword specifies which color model you are using for the transform.  If you don't pass it,
``transform`` will attempt to "best guess" the model based on the passed parameters.

The parameters beginning with **d** all specify the change to the particular attribute of the color
model in question.  For example, to increase the hue on all colors in a palette, you'd do this:

.. js ::
  
  var transformed = myPalette.transform({
      use: "hsv",
      dh: 20
  });

This will shift all colors in the palette using the HSV model (Hue/Saturation/Value), and add 20 degrees
to the hue angle of the color in question.  Note that the ``.transform`` method returns a new instance
of dojox.color.Palette, and leaves the original alone.

In addition, all Palettes can be cloned using the ``.clone`` method:

.. js ::
  
  var cloned = myPalette.clone();

If you would like to generate a palette using a specific color theory, you can do so through the "static"
``generate`` method, implemented directory on ``dojox.color.Palette``.  For example, if you want to generate
a palette based on complimentary color theory:

.. js ::
  
  var p = dojox.color.Palette.generate("#a245f9", "complementary");

Available color theory models (based on the color rules at `Adobe Kuler <http://kuler.adobe.com>`_) are:

* ``analogous``
* ``monochromatic``
* ``triadic``
* ``complementary``
* ``splitComplementary``
* ``compound``
* ``shades``

Example
========

Color palettes based on color theory models
-------------------------------------------

Create palettes based on a color theory by looping through all available models programmatically:

.. code-example ::

  .. js ::

        require([
          "dojo/_base/array",
          "dojo/dom-construct",
          "dojox/color/Palette"
        ], function(array, domConstruct, Palette){
          var tbl = domConstruct.create('table', {
            style: { borderSpacing: '0 3px' }
          }, 'palette');
	  for (palette in Palette.generators) {
            var tr = domConstruct.create('tr', null, tbl);
            var p = Palette.generate("#A62F00", palette);
            domConstruct.create('td', {
              innerHTML: palette,
              style: {
                verticalAlign: 'middle',
                paddingRight: '4px'
              }
            }, tr);
            array.forEach(p.colors, function(color) {
              domConstruct.create('td', {
                style: {
                  height: '24px',
                  width: '18px',
                  border: '1px solid black',
                  backgroundColor: color.toHex()
                }
              }, tr);
            });
          }
        });

  .. html ::

    <div id="palette"></div>
