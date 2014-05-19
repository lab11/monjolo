
/* Wire the RV-3049-C3 to the correct pins for BigBen.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration RV3049C3C {
  provides RVRTC;
}
implementation {

  components RV3049C as RtcC;

  // Wire to the correct pin for the chip select line.
  components HplMsp430GeneralIOC as HplGeneralIOC;
  components new Msp430GpioC() as CSM;
  CSM.HplGeneralIO  -> HplGeneralIOC.Port17;

  // Wire all the CS pin to the  driver
  RtcC.CS -> CSM.GeneralIO;

  // Connect the main interface
  RVRTC = RtcC.RVRTC;
}

