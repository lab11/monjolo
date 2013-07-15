#include "coilcube.h"

configuration CCPowerMeterIpC {}
implementation {

	components MainC;
  components CCPowerMeterIpP as App;
  components LedsC;
  components Ieee154BareC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC.Leds;

  components Fm25lbC as FramC;
  App.Fram -> FramC.Fm25lb;

  // IPv6 Stack
  components IPStackC;
  App.RadioControl -> IPStackC.SplitControl;
  components new UdpSocketC() as Udp;
  App.Udp -> Udp.UDP;

  components HplMsp430GeneralIOC as FlagGPIOC;
  App.FlagGPIO -> FlagGPIOC.Port55;

  components HplMsp430GeneralIOC as TimeControlGPIOC;
  App.TimeControlGPIO -> TimeControlGPIOC.Port54;

  // ADC for time approximation
  components new Msp430Adc12ClientC() as Adc;
  App.ReadSingleChannel -> Adc.Msp430Adc12SingleChannel;
  App.AdcResource -> Adc.Resource;
}
