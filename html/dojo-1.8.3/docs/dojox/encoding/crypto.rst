.. _dojox/encoding/crypto:

=====================
dojox.encoding.crypto
=====================

:Author: Tom Trenka

The crypto module of DojoX Encoding brings common symmetrical cryptography to your application/web pages.
At the time of writing (Dojo Toolkit 1.3 release), 2 algorithms are available:

* dojox.encoding.crypto.Blowfish
* :ref:`dojox.encoding.crypto.SimpleAES <dojox/encoding/crypto/SimpleAES>`

However, more are planned for future releases, including the following:

* AES (straight implementation)
* FastAES (implementation using table lookups for super-fast crypto)
* Rjindael
* RSA

All crypto implementations follow the same API; there is an encrypt and a decrypt method with an optional
keyword arguments object passed. For example:

.. js ::
  
  dojo.require("dojox.encoding.crypto.SimpleAES");
  var ciphertext = dojox.encoding.crypto.SimpleAES.encrypt(myMessage, myPassword);

  // later on in the program
  var plaintext = dojox.encoding.crypto.SimpleAES.decrypt(ciphertext, myPassword);

In general, the returned text is encoded using the base64 algorithm; however, SimpleAES is hard-coded
to only return Hex-formatted strings (there is a reason for this, please see the :ref:`SimpleAES <dojox/encoding/crypto/SimpleAES>`
page).

As with :ref:`dojox.encoding.digests <dojox/encoding/digests>`, there is a common arguments object that all implementations within
crypto should allow for.  This object takes the following form:

.. js ::
  
  var args = {
      outputType: dojox.encoding.crypto.outputTypes.Base64,
      cipherMode: dojox.encoding.crypto.cipherModes.CBC,
      iv: someByteArray[]
  };

All are optional (as is passing the object itself); crypto algorithms should default to Base64 encoding, using the ECB
(Electronic Code Book) cipher mode (for those of you versed in crypto, this is because if the mode is CBC then an
initialization vector (the iv property) **must** be present).

The *SimpleAES* implementation differs from all other crypto algorithms in that it operates using a fixed/modified CBC
mode, generates it's own initialization vector (a nonce), and includes it at the head of the encrypted text--as well
as separating each encrypted block using a space.  This makes it non-standard and only really useful for self-consumption
(for things such as encrypted storage).
