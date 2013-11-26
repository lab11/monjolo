/* Run this app on the RPi to generate the file that will create the coilcube
 * calibration data.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration RpiCalibrateCCC {}
implementation {
  components MainC;
  components RpiCalibrateCCP as App;
  components LedsC;

  components Ieee154BareC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;

  App.RadioControl -> Ieee154BareC.SplitControl;
  App.Receive -> Ieee154BareC.BareReceive;
  App.Send -> Ieee154BareC.BareSend;

  components UartC;
  App.UartBuffer -> UartC.UartBuffer;
}
