.. _dojox/color:

===========
dojox.color
===========

:Project owner: Tom Trenka, Cal Henderson
:since: 1.0+

The DojoX Color project both adds functionality to dojo.color and includes a pair of modules for
generating color palettes (``dojox.color.Palette``) as well as advanced colorspace functions
(``dojox.color.Colorspace``), making more advanced functionality available for use.

:ref:`dojox.color.Palette <dojox/color/Palette>` will generate a set of colors based on a single color
and a chosen color theory rule.

``dojox.color.Colorspace`` provides a slew of functionality to convert
colors to various advanced models (such as XYZ, xyY, Lab, Luv, LCHab) as well as working with
various color profiles (such as Adobe RGB, ColorMatch RGB, NTSC, PAL and more).

Including the ``dojox.color`` module will add the following functions to ``dojo.color``, with
an alias to ``dojox.color`` and ``dojox.color.Color``:

.. js ::
  
  var c = dojox.color.fromCmy(c, m, y);
  var c = dojox.color.fromCmyk(c, m, y, k);
  var c = dojox.color.fromHsl(h, s, l);
  var c = dojox.color.fromHsv(h, s, v);

  // myColor is an instance of dojo.Color.
  var cmy = myColor.toCmy();
  var cmyk = myColor.toCmyk();
  var hsl = myColor.toHsl();
  var hsv = myColor.toHsv();

Note that these are the most common color models (other than RGB, which is implemented by dojo.Color);
the methods should be self-explanatory except that Lightness (l) and Value (v) expect values from 0-100 and not 0-1.  To create a ``dojo.Color`` or ``dojox.color.Color`` instance,
use the *from* methods, directly on ``dojox.color``; to convert an existing ``dojo.Color`` or
``dojox.color.Color`` object to a specific model, use the *to* methods.

For more information on the Palette, please visit the :ref:`Palette <dojox/color/Palette>` page.
