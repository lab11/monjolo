
configuration RpiCoilcubeReceiverIpC {}
implementation {
  components MainC;
  components RpiCoilcubeReceiverIpP as App;
  components LedsC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;

  // Radio/IP
  components IPStackC;
  App.BlipControl -> IPStackC;

  components BorderC;
  components StaticIPAddressC;
}
