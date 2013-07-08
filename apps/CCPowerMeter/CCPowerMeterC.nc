#include "coilcube.h"

configuration CCPowerMeterC {}
implementation {

	components MainC;
  components CCPowerMeterP as App;
  components LedsC;
  components Ieee154BareC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC.Leds;

  components Fm25lbC as FramC;
  App.Fram -> FramC.Fm25lb;

  // Radio
  // Uses a very bare radio interface.
  App.RadioControl -> Ieee154BareC.SplitControl;
  App.RadioSend -> Ieee154BareC.BareSend;
  App.RadioReceive -> Ieee154BareC.BareReceive;
  App.RadioPacket -> Ieee154BareC.BarePacket;

  components HplMsp430GeneralIOC as FlagGPIOC;
  App.FlagGPIO -> FlagGPIOC.Port55;

  components HplMsp430GeneralIOC as TimeControlGPIOC;
  App.TimeControlGPIO -> TimeControlGPIOC.Port54;

  // ADC for time approx.
  components new Msp430Adc12ClientC() as Adc;
  App.ReadSingleChannel -> Adc.Msp430Adc12SingleChannel;
  App.AdcResource -> Adc.Resource;
}
