
/* Wire the FM25V20 to the correct pins for BigBen.
 *
 * Use some null GPIOs for Hold and Write Protect since those
 * aren't wired to anything.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration FM25V20C {
  provides {
    interface FM25V;
  }
}
implementation {
  components new NullGpioP() as HoldNull;
  components new NullGpioP() as WPNull;

  // Wire to a copy of the main driver
  components new FM25VC() as FramC;

  // Wire to the correct pin for the chip select line.
  components HplMsp430GeneralIOC as HplGeneralIOC;
  components new Msp430GpioC() as CSNM;
  CSNM.HplGeneralIO  -> HplGeneralIOC.Port21;

  // Wire all the pins (real and fake) to the FRAM driver
  FramC.CSN -> CSNM.GeneralIO;
  FramC.Hold -> HoldNull.GeneralIO;
  FramC.WP -> WPNull.GeneralIO;

  // Connect the main interface
  FM25V = FramC.FM25V;
}

