/* Run this app on the RPi to generate the file that will print events from
 * gecko power supplies and the plm, as well as forward coilcube packets.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration RpiCalibrateAllIpC {}
implementation {
  components MainC;
  components RpiCalibrateAllIpP as App;
  components LedsC;
  components UnixTimeC;
  components BusyWaitMicroC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;
  App.UnixTime -> UnixTimeC.UnixTime;
  App.BusyWait -> BusyWaitMicroC.BusyWait;

  // IPv6 Stack
  components IPStackC;
  components StaticIPAddressC;
  App.BlipControl -> IPStackC.SplitControl;

  // Gpio for gecko power supply
  components HplBcm2835GeneralIOC as HplGpioC;
  components Bcm2835InterruptC;
  App.Pin -> HplGpioC.Port1_26;
  App.Int -> Bcm2835InterruptC.Port1_26;

  components UartC;
  App.UartBuffer -> UartC.UartBuffer;

  components CalibrateBorderC;
}
