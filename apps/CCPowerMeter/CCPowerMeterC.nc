#include "CoilCube.h"

configuration CCPowerMeterC {}
implementation {

	components MainC;
  components CCPowerMeterP as App;
  components LedsC;
  components Ieee154BareC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC.Leds;

  components new TimerMilliC() as Timer0;
  App.Timer0 -> Timer0.Timer;

  components Fm25lbC as FramC;
  App.Fram -> FramC.Fm25lb;

  // Radio
  // Uses a very bare radio interface.
  App.RadioControl -> Ieee154BareC.SplitControl;
  App.RadioSend -> Ieee154BareC.BareSend;
  App.RadioReceive -> Ieee154BareC.BareReceive;
  App.RadioPacket -> Ieee154BareC.BarePacket;

  components HplMsp430InterruptC as Interrupt;
  components HplMsp430GeneralIOC as GPIO;
  App.InterruptGPIO -> GPIO.Port17;
  App.Interrupt -> Interrupt.Port17;

  components HplMsp430GeneralIOC as FlagGPIOC;
  App.FlagGPIO -> FlagGPIOC.Port55;

  components HplMsp430GeneralIOC as TimeGPIOC;
  App.TimeGPIO -> TimeGPIOC.Port54;

  // ADC for time approx.
  components new Msp430Adc12ClientC() as Adc;
  App.ReadSingleChannel -> Adc.Msp430Adc12SingleChannel;
  App.AdcResource -> Adc.Resource;
}
