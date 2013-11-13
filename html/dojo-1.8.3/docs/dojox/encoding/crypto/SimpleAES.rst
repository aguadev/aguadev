.. _dojox/encoding/crypto/SimpleAES:

===============================
dojox.encoding.crypto.SimpleAES
===============================

:Author: Tom Trenka, Brad Neuberg

Unlike other crypto implementations within DojoX Encoding, the SimpleAES implementation is hard-coded using
a modified version of CBC (Cipher Block Chaining) mode, along with a non-standard formatting.  The reasons
for this are because of eventual plans to use this implementation, modified from the implementation by
Brad Neuberg for :ref:`dojox.off <dojox/off>` (within the "private" :ref:`dojox.sql <dojox/sql>` project) to refactor
and replace dojox.sql.

This implementation differs from the dojox.sql implementation in the following ways:

1. The dojox.encoding.crypto version uses Hex encoding (2 numbers for every byte in the cipher text); the
   dojox.sql version uses straight String encoding, which can be problematic for a number of reasons.
2. The dojox.encoding.crypto version uses a space (" ") to delimit each ciphertext block/word.  The dojox.sql
   version uses a dash ("-").

Both versions preserve the way the original implementation (from Chris Veness, http://www.movable-type.co.uk/scripts/aes.html)
uses a nonce as a hard-coded initialization vector. This nonce is included as the first block of the resulting
ciphertext--which is why this implementation is not as useful as one might think, especially if the purpose of
using SimpleAES is for cross-platform encrypted communication.  Because of this reason, SimpleAES is generally
**only useful for purposes where the application/web page is the only consumer of the algorithm** (i.e. encrypting
and decrypting with this implementation only).
