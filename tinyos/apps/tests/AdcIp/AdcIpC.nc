configuration AdcIpC { }
implementation {
  components AdcIpP as App;

  components MainC;
  App.Boot -> MainC.Boot;

  components new TimerMilliC();
  App.Timer -> TimerMilliC.Timer;

  components HplVTimerC;
  App.TimeControlGPIO -> HplVTimerC.TimeControlGPIO;
  App.VTimerAdcConfig -> HplVTimerC.VTimerAdcConfig;

  // ADC for time approximation
  components new Msp430Adc12ClientC() as Adc;
  App.ReadSingleChannel -> Adc.Msp430Adc12SingleChannel;
  App.AdcResource -> Adc.Resource;

  // IPv6 Stack
  components IPStackC;
  components new UdpSocketC() as UDPService;
  App.BlipControl -> IPStackC;
  App.UDPService   -> UDPService;

  components StaticIPAddressC;
}
