.. _util/checkstyle:

===============
util.checkstyle
===============

:Project owner: Shane O'Sullivan
:since: V1.4

.. contents ::
   :depth: 2

Introduction
============

Checkstyle is a command line tool that generates a report of all JavaScript files that violate :ref:`the Dojo code style guidelines <developer/styleguide>`. It also includes an interactive online tool to automatically fix most style guide issues.


Usage of Command Line
=====================

Open a command window in the util/checkstyle folder.  The commands listed below all use '''checkstyle.bat''', which is for MS Windows, but users of Linux and Macs can use '''checkstyle.sh'''.

Run Checkstyle on all Dojo folders
----------------------------------

checkstyle.bat

Run Checkstyle on a specific folder
-----------------------------------

checkstyle.bat dir=dijit/form

Run Checkstyle on a custom namespace
------------------------------------

checkstyle.bat dir=myCustomNs

Show Checkstyle help
--------------------

checkstyle help

Usage of Online Tool
====================

The Checkstyle Online Tool can be used to look at the style guide violations and to fix them.  Open the file util/checkstyle/checkstyleReport.html, which will display the errors to be fixed.  Note that this file should be opened using a web server, and not from the file system, as browser security issues will cause problems if loaded from the file system.


.. image :: checkstyle_scrnshot.png
   :alt: Checkstyle Tool
