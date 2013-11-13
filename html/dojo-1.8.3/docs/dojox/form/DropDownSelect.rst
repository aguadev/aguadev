.. _dojox/form/DropDownSelect:

=========================
dojox.form.DropDownSelect
=========================

:Project owner: Nathan Toone
:since: V1.2

.. contents ::
   :depth: 2

A styleable drop down select box (similar to html select element)

Migration Note
==============
As of version 1.4, dojox.form.DropDownSelect has been deprecated, as it has now been moved to :ref:`dijit.form.Select <dijit/form/Select>`.  Please update your code!

Introduction
============

HTML Select tags are problematic when it comes to styling - they are not very styleable, not to mention nearly impossible to get a consistent cross-browser widget.  This widget aims to resolve that issue.


Usage
=====

The DropDownSelect is designed to replace existing HTML select elements with minimal effort.  You can also create them programmatically.

Examples
========

A simple DropDownSelect
-----------------------

This example shows a simple DropDownSelect widget - converted from a select tag.

.. code-example ::

  .. js ::

      dojo.require("dojox.form.DropDownSelect");

  .. html ::

    <select name="select" data-dojo-type="dojox.form.DropDownSelect">
        <option value="TN">Tennessee</option>
        <option value="VA" selected="selected">Virginia</option>
        <option value="WA">Washington</option>
        <option value="FL">Florida</option>
        <option value="CA">California</option>
    </select>

  .. css ::

      @import "{{baseUrl}}dojox/form/resources/DropDownSelect.css";

A "styled" DropDownSelect
-------------------------

When styling the entries of a DropDownSelect, you must use div and span tags, instead of select and option tags - as IE will strip out any HTML within the option tags.

.. code-example ::

  .. js ::

      dojo.require("dojox.form.DropDownSelect");

  .. html ::

    <div name="select" value="AK" data-dojo-type="dojox.form.DropDownSelect">
        <span value="AL"><b>Alabama</b></span>
        <span value="AK"><font color="red">A</font><font color="orange">l</font><font color="yellow">a</font><font color="green">s</font><font color="blue">k</font><font color="purple">a</font></span>
        <span value="AZ"><i>Arizona</i></span>
        <span value="AR"><span class="ark">Arkansas</span></span>
        <span value="CA"><span style="font-size:25%">C</span><span style="font-size:50%">a</span><span style="font-size:75%">l</span><span style="font-size:90%">i</span><span style="font-size:100%">f</span><span style="font-size:125%">o</span><span style="font-size:133%">r</span><span style="font-size:150%">n</span><span style="font-size:175%">i</span><span style="font-size:200%">a</span></span>
        <span value="NM" disabled="disabled">New<br>&nbsp;&nbsp;Mexico</span>
    </div>

  .. css ::

      @import "{{baseUrl}}dojox/form/resources/DropDownSelect.css";
      .ark { text-decoration: underline; }
