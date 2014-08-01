/* Monjolo style sensing app for Buzz.
 *
 * On boot, it reads the FRAM and updates a counter, reads the ADC line for the
 * timing capacitor, and if the timing cap is discharged enough, sends a packet
 * with the counter information.
 *
 * @author Samuel DeBruin <sdebruin@umich.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration BuzzC {}
implementation {

	components MainC;
  components BuzzP as App;
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

  components GeckoPowerSupplyC;
  App.ShutdownGPIO -> GeckoPowerSupplyC.Shutdown;
}
