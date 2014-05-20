
/* Wire the FM25L04B to the correct pins for Coilcube/Impulse.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration FM25L04BC {
  provides {
    interface Fm25lb;
  }
}
implementation {
  // Wire to a copy of the main driver
  components new Fm25lbC() as FramC;

  // Wire to the correct pin for the chip select line.
  components HplMsp430GeneralIOC as HplGeneralIOC;
  components new Msp430GpioC() as CSNM;
  components new Msp430GpioC() as Hold;
  components new Msp430GpioC() as WP;
  CSNM.HplGeneralIO -> HplGeneralIOC.Port50;
  Hold.HplGeneralIO -> HplGeneralIOC.Port57;
  WP.HplGeneralIO -> HplGeneralIOC.Port34;

  // Wire all the pins to the FRAM driver
  FramC.CSN -> CSNM.GeneralIO;
  FramC.Hold -> Hold.GeneralIO;
  FramC.WP -> WP.GeneralIO;

  // Connect the main interface
  Fm25lb = FramC.Fm25lb;
}
