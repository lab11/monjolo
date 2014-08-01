TinyOS
======

Most of the code for Monjolo sensors is written in TinyOS. There are a
few steps you must complete to be able to compile the TinyOS apps.


Step 1: Get TinyOS
------------------

This repo will only compile against the latest version of tinyos. For now,
you need to compile the tools as well.

    git clone https://github.com/lab11/tinyos-main.git
    cd tinyos-main
    cd tools
    ./Bootstrap
    ./configure
    make
    sudo make install

You also need this repository, of course:

    git clone https://github.com/lab11/monjolo.git

Now you need to tell the TinyOS build tools where to find the Monjolo specific
TinyOS code. Add the following to `bash.rc`:

    export TINYOS_ROOT_DIR_ADDITIONAL=~/git/monjolo/tinyos:$TINYOS_ROOT_DIR_ADDITIONAL
    export TINYOS_ROOT_DIR=~/git/tinyos-main

This should setup enough TinyOS infrastructure to enable you to compile the
Monjolo applications.


Step 2: Setup the RaspberryPi
-----------------------------

The receiving code is designed for the Raspberry Pi platform. You need the
[Linux CC2520 Driver](https://github.com/ab500/linux-cc2520-driver) for the RPi.
Instead of installing that by hand I suggest using my preinstalled image you
can download from the [torrent](https://github.com/lab11/raspberrypi-cc2520/tree/master/torrents).

You also need the RPi TinyOS code.

    git clone https://github.com/lab11/raspberrypi-cc2520

Add this to `bash.rc`:

    export TINYOS_ROOT_DIR_ADDITIONAL=~/git/raspberrypi-cc2520/tinyos:$TINYOS_ROOT_DIR_ADDITIONAL


Step 3: Get the Compilers
-------------------------

In order to compile the TinyOS code you need the msp430 and the ARM compilers


Step 4: Compile the Applications
--------------------------------

### Monjolo Node

The application for the Monjolo sensors is simply called Monjolo. To compile
for coilcube:

    make coilcube blip


### Receiver

The receiver just uses the default BorderRouter app from raspberrypi-cc2520 with
the makefile in this repository.

    cd git/raspberrypi-cc2520/apps/BorderRouter
    make -f git/monjolo/tinyos/apps/BorderRouter/Makefile rpi blip
