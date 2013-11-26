configuration FramIpC { }
implementation {
  components FramIpP as App;

  components MainC;
  App.Boot -> MainC.Boot;

  components Fm25lbC;
  App.Fram -> Fm25lbC.Fm25lb;

  components new TimerMilliC();
  App.Timer -> TimerMilliC.Timer;

  // IPv6 Stack
  components IPStackC;
  components new UdpSocketC() as UDPService;
  App.BlipControl -> IPStackC;
  App.UDPService   -> UDPService;

  components StaticIPAddressC;
}
