
configuration CCFakeDataIpC {}
implementation {

	components MainC;
  components CCFakeDataIpP as App;
  components LedsC;
  components Ieee154BareC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC.Leds;

  components Fm25lbC as FramC;
  App.Fram -> FramC.Fm25lb;

  components new TimerMilliC() as Timer0;
  App.Timer0 -> Timer0.Timer;

  // IPv6 Stack
  components IPStackC;
  components StaticIPAddressC;
  App.BlipControl -> IPStackC.SplitControl;
  App.ForwardingTable -> IPStackC.ForwardingTable;
  components new UdpSocketC() as Udp;
  App.Udp -> Udp.UDP;

  components CC2420FbDriverLayerP as CC2420Fb;
  App.SeqNoControl -> CC2420Fb.SeqNoControl;

  components HplMsp430GeneralIOC as FlagGPIOC;
  App.FlagGPIO -> FlagGPIOC.Port55;

  components HplMsp430GeneralIOC as TimeControlGPIOC;
  App.TimeControlGPIO -> TimeControlGPIOC.Port54;

  // ADC for time approximation
  components new Msp430Adc12ClientC() as Adc;
  App.ReadSingleChannel -> Adc.Msp430Adc12SingleChannel;
  App.AdcResource -> Adc.Resource;
}
