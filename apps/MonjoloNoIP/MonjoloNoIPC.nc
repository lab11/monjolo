#include "monjolo.h"

/* TinyOS application for Monjolo Energy-Harvesting Sensors.
 *
 * @author Sam DeBruin <sdebruin@umich.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration MonjoloNoIPC {}
implementation {

	components MainC;
  components MonjoloNoIPP as App;

  App.Boot -> MainC.Boot;

  components LedsC;
  App.Leds -> LedsC.Leds;

  // FRAM for keeping state between wakeups
  components Fm25lbC as FramC;
  App.Fram -> FramC.Fm25lb;

  // Radio
  // Uses a very bare radio interface.
  components Ieee154BareC;
  App.RadioControl -> Ieee154BareC.SplitControl;
  App.RadioSend -> Ieee154BareC.BareSend;
  App.RadioReceive -> Ieee154BareC.BareReceive;
  App.RadioPacket -> Ieee154BareC.BarePacket;

  // Use a platform specific pin for debugging
  components HplFlagC;
  App.FlagGPIO -> HplFlagC.FlagGPIO;

  // Timing approximation
  // Wire up the platform specific vtimer and vcap pins
  components HplVTimerC;
  components new Msp430Adc12ClientC() as Adc;
  App.TimeControlGPIO -> HplVTimerC.TimeControlGPIO;
  App.AdcResource -> Adc.Resource;
  App.VTimerAdcConfig -> HplVTimerC.VTimerAdcConfig;
  App.VTimerRead -> Adc.Msp430Adc12SingleChannel;

}
