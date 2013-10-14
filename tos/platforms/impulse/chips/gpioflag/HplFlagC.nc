/*
 * Choose which pin should be a debug flag.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration HplFlagC {
  provides {
    interface HplMsp430GeneralIO as FlagGPIO;
  }
}
implementation {
  components HplMsp430GeneralIOC as FlagGPIOC;
  FlagGPIO = FlagGPIOC.Port55;
}
