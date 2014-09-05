Monjolo + nRF51822
==================

This folder contains code to run on the nRF51822 based Monjolo platform.

Setup
=====

1. Get the git repo that has the Makefiles in it.

        git clone https://github.com/hlnd/nrf51-pure-gcc-setup.git

1. Make sure you have the [arm-none-eabi-gcc](https://launchpad.net/gcc-arm-embedded)
toolchain. You just need the binaries for your platform.

1. Get the nRF51822 SDK and S110 soft device from the
[downloads page](https://www.nordicsemi.com/eng/Products/Bluetooth-Smart-Bluetooth-low-energy/nRF51822?resource=20339).
You want the "nRF51 SDK Zip File" and the "S110 nRF51822 SoftDevice (Production ready)".
You do need to buy a nRF51822 evm kit to get access to these, because companies
are the worst.

1. Make sure the SDK path is set correctly in the application Makefile.

1. Get the [Segger flashing tools](http://www.segger.com/jlink-software.html).
On Linux you want the "J-Link software & documentation pack for Linux".



Install an App
==============

1. Just once you need to load the soft device onto the nRF51822.

        make flash-softdevice SOFTDEVICE=/path/to/softdevice/s110_nrf51822_X.X.X_softdevice.hex

2. Now compile and load the application code.

        cd apps/monjolo
        make flash