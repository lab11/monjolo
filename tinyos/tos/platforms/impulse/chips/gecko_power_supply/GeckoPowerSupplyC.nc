/*
 * Map Gecko pins to Impulse
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration GeckoPowerSupplyC {
  provides {
    interface HplMsp430GeneralIO as Shutdown;
    interface HplMsp430GeneralIO as Overvolt;
    interface HplMsp430GeneralIO as Trigger;
  }
}
implementation {
  components HplMsp430GeneralIOC as GpioC;
  Shutdown = GpioC.Port20;
  Overvolt = GpioC.Port17;
  Trigger  = GpioC.Port21;
}
