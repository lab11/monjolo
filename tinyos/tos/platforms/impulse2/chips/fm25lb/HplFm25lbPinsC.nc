/**
 * Pin wiring for the FM25LB FRAM chip on the coilcube platform.
 *
 * @author Samuel DeBruin <sdebruin@umich.edu>
 */

configuration HplFm25lbPinsC {
  provides interface GeneralIO as CSN;
  provides interface GeneralIO as Hold;
  provides interface GeneralIO as WP;
}
implementation {
  components HplMsp430GeneralIOC as HplGeneralIOC;
  components new Msp430GpioC() as CSNM;
  components new Msp430GpioC() as HoldM;
  components new Msp430GpioC() as WPM;

  CSNM -> HplGeneralIOC.Port50;
  HoldM -> HplGeneralIOC.Port57;
  WPM -> HplGeneralIOC.Port34;

  CSN = CSNM;
  Hold = HoldM;
  WP = WPM;
}
