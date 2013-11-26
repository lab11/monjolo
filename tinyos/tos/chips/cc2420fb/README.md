CC2420FB
========

Driver for the cc2420, fast boot style.

This radio driver contains very little. You should not expect it to handle
really anything any of the other radio drivers do. Calling send on this driver
basically puts bits on the wire. All header, seq no, etc must be filled in by
you.

This driver is designed for energy-harvesting devices that wake up and send a
packet, and not much else.

To do:

1. write ieee154Bare that wraps the low level send in the nice abstraction
2. write ieee154 that wraps that with a packet layer that understands actual
   15.4 headers

