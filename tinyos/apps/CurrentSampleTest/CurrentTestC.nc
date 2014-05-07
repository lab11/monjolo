/*
 * App for measuring an AC current waveform with an energy-harvesting
 * device in order to calculate power
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration CurrentTestC {}
implementation {

	components MainC;
  components CurrentTestP as App;
  App.Boot -> MainC.Boot;

  components HplMsp430GeneralIOC as MspGpio;
  components HplMsp430InterruptC as MspInterrupt;

  // Wire to a interrupt handler on the rising edge of the SFD line
  App.SFDGpio -> MspGpio.Port15;
  App.SFDInt  -> MspInterrupt.Port15;

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



  // Wire to the ADC pin attached to the coil so we can configure it as an
  // ADC input
  App.CoilIn -> MspGpio.Port62;

}
