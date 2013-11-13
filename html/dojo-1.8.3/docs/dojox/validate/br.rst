.. _dojox/validate/br:

=================
dojox.validate.br
=================

:Authors: Jared Jurkiewicz
:Developers: Jared Jurkiewicz
:since: V1.4

.. contents ::
    :depth: 2

The dojox.validate.br package is a package to contain helper functions for validating Brazilian specific formats, such as CNPJ and CPF numbers, numbers used to identify corporations and individuals.   Similar to the concept of the United States Social Security number for tax purposes.

Features
========

Once required in the following functions are available:

* dojox.validate.br.isValidCnpf(String) - Validate a string to see if it conforms to CNPF format and calculates the proper checksum.
* dojox.validate.br.isValidCpf(String) - Validate a string to see if it conforms to CPF format and calculates the proper checksum.
* dojox.validate.br.computeCnpfDv(String) - Compute a DV number for a base CNPF number.
* dojox.validate.br.computeCpfDv(String) - Compute a DV number for a base CPF number.

Usage
=====

Call the desired validator with the String you wish to process.  It will return if it is valid or not.  And in the case of compute*Dv, it will return the DV calculation, or empty string, if it isn't a valid number to compute a DV for.

Basic Usage
-----------
Usage of this code is quite simple and painless.  The only thing you have to do is require it in the page and the functions will be available.  For Example:

.. js ::
 
    dojo.require("dojox.validator.br");


Examples
========

Basic Usage
-----------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.4

  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.form.TextBox");
      dojo.require("dojox.validate.br");

    
  .. html ::

    <b>Enter a CNPF like number and it will tell you if it is valid or not.</b>

See Also
========

* :ref:`dojox.validate <dojox/validate>`
