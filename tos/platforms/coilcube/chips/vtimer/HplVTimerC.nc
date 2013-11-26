/*
 * File to allow customizing which pin the Timing Cap is connected to.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration HplVTimerC {
  provides {
    interface HplMsp430GeneralIO as TimeControlGPIO;

    interface AdcConfigure<const msp430adc12_channel_config_t*> as VTimerAdcConfig;
  }
}
implementation {
  components HplMsp430GeneralIOC as TimeControlGPIOC;
  TimeControlGPIO = TimeControlGPIOC.Port54;

  // ADC for time approximation
  components HplVTimerP;
  VTimerAdcConfig = HplVTimerP.VTimerAdcConfig;
}

