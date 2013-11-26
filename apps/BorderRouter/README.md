Border Router
=============

To receive coilcube packets there must be a border router application
running. Because coilcubes just use IPv6 packets, there does not
need to be a coilcube specific border router app. Instead, use
the BorderRouter app from the raspberypi-cc2520 repository, just with
this Makefile.

    cd raspberrypi-cc2520/tinyos/apps/BorderRouter
    make -f coilcube/tinyos/apps/BorderRouter/Makefile rpi blip

