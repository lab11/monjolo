
configuration AirflowDetectC {}
implementation {

	components MainC;
  components AirflowDetectP as App;
  App.Boot -> MainC.Boot;

  components LedsC;
  App.Leds -> LedsC.Leds;

  // FRAM
  components FM25L04BC as FramC;
  App.Fram -> FramC.Fm25lb;


  // IPv6 Stack
  components IPStackC;
  components StaticIPAddressC;
  App.BlipControl -> IPStackC.SplitControl;
  App.ForwardingTable -> IPStackC.ForwardingTable;
  components new UdpSocketC() as Udp;
  App.Udp -> Udp.UDP;

  // Allow the app to pick the sequence number
  components CC2420FbDriverLayerP as CC2420Fb;
  App.SeqNoControl -> CC2420Fb.SeqNoControl;

  // Platform specific pin for debugging
  components HplFlagC;
  App.FlagGPIO -> HplFlagC.FlagGPIO;

  components HplVTimerC;
  App.TimeControlGPIO -> HplVTimerC.TimeControlGPIO;

  components new AdcReadClientC() as VTimerReadAdc;
  App.VTimerAdcRead -> VTimerReadAdc.Read;
  App.VTimerAdcConfigure <- VTimerReadAdc.AdcConfigure;

  components new TimerMilliC() as AirflowWaitTimer;
  App.AirflowWaitTimer -> AirflowWaitTimer.Timer;

  components new AdcReadClientC() as AirflowReadAdc;
  App.AirflowAdcRead -> AirflowReadAdc.Read;
  App.AirflowAdcConfigure <- AirflowReadAdc.AdcConfigure;

  components HplMsp430GeneralIOC as MspGPIO;
  App.AirflowCtrl -> MspGPIO.Port17;


  components CC2420FbDriverLayerC;
  App.RadioInit -> CC2420FbDriverLayerC.Init;
}
