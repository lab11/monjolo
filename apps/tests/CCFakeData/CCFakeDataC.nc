
configuration CCFakeDataC {}
implementation {

	components MainC;
  components CCFakeDataP as App;
  components LedsC;
  components Ieee154BareC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC.Leds;

  components new TimerMilliC() as Timer0;
  App.Timer0 -> Timer0.Timer;

  // Radio
  // Uses a very bare radio interface.
  App.RadioControl -> Ieee154BareC.SplitControl;
  App.RadioSend -> Ieee154BareC.BareSend;
  App.RadioReceive -> Ieee154BareC.BareReceive;
  App.RadioPacket -> Ieee154BareC.BarePacket;

  components LocalIeeeEui64C;
  App.LocalIeeeEui64 -> LocalIeeeEui64C.LocalIeeeEui64;
}
