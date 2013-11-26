/* Run this app on the RPi to generate the file that will create the coilcube
 * calibration data.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration RpiCalibrateCCIpC {}
implementation {
  components MainC;
  components RpiCalibrateCCIpP as App;
  components LedsC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;

  // IPv6 Stack
  components IPStackC;
  components StaticIPAddressC;
  App.BlipControl -> IPStackC.SplitControl;

  components UartC;
  App.UartBuffer -> UartC.UartBuffer;

  components CalibrateBorderC;
}
