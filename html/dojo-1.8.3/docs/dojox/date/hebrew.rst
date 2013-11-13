.. _dojox/date/hebrew:

=================
dojox.date.hebrew
=================

:Project owner: Tomer Mahlin
:Contributors: Helena Halperin, Moshe Wajnberg
:since: V1.4

.. contents ::
   :depth: 2

Implements the traditional Hebrew calendar. This is the civil calendar in Israel and the liturgical calendar of the Jewish faith worldwide.

Introduction
============

The Hebrew calendar is lunisolar and thus has a number of interesting properties that distinguish it from the Gregorian. Months start on the day of (an arithmetic approximation of) each new moon. Since the solar year (approximately 365.24 days) is not an even multiple of the lunar month (approximately 29.53 days) an extra "leap month" is inserted in 7 out of every 19 years. To make matters even more interesting, the start of a year can be delayed by up to three days in order to prevent certain holidays from falling on the Sabbath and to prevent certain illegal year lengths. Finally, the lengths of certain months can vary depending on the number of days in the year.

Usage
=====

Code snippet below illustrates a common usage of Hebrew Date code with the Dijit Calendar widget.

.. html ::
 
  <head>
      <script type="text/javascript">
        dojo.require("dojox.date.hebrew");
        dojo.require("dojox.date.hebrew.Date");
        dojo.require("dojox.date.hebrew.locale");
      </script>
      <title>Hebrew calendar</title>
  </head>
  <body>
        <input name="hebcal"
           value="2009-03-10"
           data-dojo-type="dijit.form.DateTextBox"
           datePackage = "dojox.date.hebrew">
  </body>

Hebrew calendar package
-----------------------

The Hebrew calendar package is comprised of following three files:

    * dojox.date.hebrew.Date implements logic of Hebrew calendar and provides support for date conversion between Gregorian and Hebrew calendars
    * dojox.date.hebrew.locale includes implementation of functions responsible for conversion between two possible representations of Hebrew date: String representation and Date object. It also provides date formatting capabilities.
    * dojox.date.hebrew.numerals - provides support for Hebrew numerals.

Hebrew calendar and DateTextBox
-------------------------------

The Hebrew calendar implemented in this package can be used in conjunction with DateTextBox in order to provide graphical date picker for Hebrew calendar. For example, the image below illustrates DateTextBox using a Hebrew calendar with the default language set to Hebrew.

.. image :: hebrew.png

Examples
========

Programmatic example
--------------------

The code snippet below illustrates conversion between two possible representations of Hebrew date: String and Date object.

.. js ::

   var options = {datePattern:'EEEE dd MMMM yyyy HH:mm:ss', selector:'date'};

   // converts string representation of Hebrew date to Date object
   var dateHeb = dojox.date.hebrew.locale.parse("י"ד אדר שני תשס"ט", options);

   // formats Hebrew date object and serialize it into a string
   var dateHebString = dojox.date.hebrew.locale.format(dateHeb, options);


Declarative example
-------------------

Code snippet below illustrates usage of Hebrew calendar in the context of graphical date picker - DateTextBox


.. html ::
 
  <head>
  <script type="text/javascript">
    dojo.require("dojox.date.hebrew");
    dojo.require("dojox.date.hebrew.Date");
    dojo.require("dojox.date.hebrew.locale");
  </script>
  <title> Hebrew calendar </title>
  </head>
  <body>
    <input name="hebcal"
       value="2009-03-10"
       data-dojo-type="dijit.form.DateTextBox"
       datePackage = "dojox.date.hebrew"
       constraints="{min:'2008-03-01',max:'2009-04-01',datePattern:'dd MMMM yyyy'}">
  </body>


See also
========

    *  "Calendrical Calculations", by Nachum Dershowitz & Edward Reingold, Cambridge University Press, 1997, pages 85-91.
    * Hebrew Calendar Science and Myths, http://www.geocities.com/Athens/1584/
    * The Calendar FAQ, http://www.faqs.org/faqs/calendars/faq/
    * General overview of Hebrew numerals
          * http://en.wikipedia.org/wiki/Hebrew_numerals
          * http://www.i18nguy.com/unicode/hebrew-numbers.html
          * http://smontagu.org/writings/HebrewNumbers.html
