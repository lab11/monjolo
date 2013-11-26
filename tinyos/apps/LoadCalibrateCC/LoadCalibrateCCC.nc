/* Control the light bulb test rig to calibrate coilcubes.
 *
 * @author: Sam DeBruin <sdebruin@umich.edu>
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration LoadCalibrateCCC {}
implementation {

	components MainC;
  components LoadCalibrateCCP as App;
  components LedsC;
  components BusyWaitMicroC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;

  App.BusyWait -> BusyWaitMicroC;

  components new TimerMilliC() as Timer1;
  App.Timer1 -> Timer1.Timer;
  components new TimerMilliC() as Timer2;
  App.Timer2 -> Timer2.Timer;
  components new TimerMilliC() as WattageUpdateTimer;
  App.WattageUpdateTimer -> WattageUpdateTimer.Timer;
  components new TimerMilliC() as LoadIncrementTimer;
  App.LoadIncrementTimer -> LoadIncrementTimer.Timer;

  components HplMsp430GeneralIOC as Control1C;
  components HplMsp430GeneralIOC as Control2C;
  components HplMsp430GeneralIOC as Control3C;
  components HplMsp430GeneralIOC as Control4C;
  components HplMsp430GeneralIOC as Control5C;
  components HplMsp430GeneralIOC as Control6C;
  components HplMsp430GeneralIOC as Control7C;
  components HplMsp430GeneralIOC as Control8C;
  components HplMsp430GeneralIOC as Control9C;
  App.Control1 -> Control1C.Port51;
  App.Control2 -> Control2C.Port52;
  App.Control3 -> Control3C.Port12;
  App.Control4 -> Control4C.Port15;
  App.Control5 -> Control5C.Port17;
  App.Control6 -> Control6C.Port16;
  App.Control7 -> Control7C.Port53;
  App.Control8 -> Control8C.Port21;
  App.Control9 -> Control9C.Port20;

  components HplMsp430GeneralIOC as ButUpG;
  components HplMsp430InterruptC as ButUpC;
  components HplMsp430GeneralIOC as ButDownG;
  components HplMsp430InterruptC as ButDownC;
  App.UpGPIO -> ButUpG.Port26;
  App.ButUp -> ButUpC.Port26;
  App.DownGPIO -> ButDownG.Port23;
  App.ButDown -> ButDownC.Port23;

  components CC2420RadioC;
  App.RadioControl -> CC2420RadioC.SplitControl;
  App.Send -> CC2420RadioC.BareSend;
  App.Receive -> CC2420RadioC.BareReceive;
  App.Packet -> CC2420RadioC.BarePacket;

}
