/*
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration CurrentTestC {}
implementation {

	components MainC;
  components CurrentTestP as App;
  App.Boot -> MainC.Boot;

  components LedsC;
  App.Leds -> LedsC.Leds;

  // FRAM
  components Fm25lbC as FramC;
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

//  components HplVTimerC;
//  components new AdcReadClientC() as Adc;
//  App.TimeControlGPIO -> HplVTimerC.TimeControlGPIO;
//  App.VTimerRead -> Adc.Read;
//  Adc.AdcConfigure -> HplVTimerC.VTimerAdcConfig;

//  components new AdcReadStreamClientC() as CoilAdc;
//  App.CoilAdcStream -> CoilAdc.ReadStream;
//  App.CoilAdcConfigure <- CoilAdc.AdcConfigure;


  components new GpioCaptureC() as SfdCapture;
  components HplMsp430GeneralIOC as MspGpio;
  components Msp430TimerC as MspTimer;
  SfdCapture.Msp430TimerControl -> MspTimer.ControlB0;
  SfdCapture.Msp430Capture -> MspTimer.CaptureB0;
  SfdCapture.GeneralIO -> MspGpio.Port40;
  App.SfdCapture -> SfdCapture.Capture;

  //components HplCC2420FbC;
  //App.SfdCapture -> HplCC2420FbC.SfdCapture;


  components new TimerMilliC();
  App.sendWaitTimer -> TimerMilliC.Timer;

  //components HplAdc12P as HplAdc;
  //App.HplAdc -> HplAdc.HplAdc12;
  components Counter32khz16C ;
  App.ConversionTimeCapture -> Counter32khz16C.Counter;
  App.CoilIn -> MspGpio.Port62;



/*
  components Msp430TimerC;
  App.TimerA -> Msp430TimerC.TimerA;
  App.ControlA1 -> Msp430TimerC.ControlA1;
  App.CompareA1 -> Msp430TimerC.CompareA1;*/
}
