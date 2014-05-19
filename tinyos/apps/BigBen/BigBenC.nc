/* Monjolo + BigBen style sensing app.
 *
 * Designed to track wakeups and store interesting events in the long-term
 * storage FRAM.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration BigBenC {}
implementation {

	components MainC;
  components BigBenP as App;
  App.Boot -> MainC.Boot;

  components LedsC;
  App.Leds -> LedsC.Leds;

  // FRAM
  components FM25L04BC as FramScratchC;
  App.FramScratch -> FramScratchC.Fm25lb;

  components FM25V20C as FramStorageC;
  App.FramStorage -> FramStorageC.Fm25lb;

  // RTC
  components RV3049C3C as RtcC;
  App.RTC -> RtcC.RVRTC;

  // Platform specific pin for debugging
  components HplFlagC;
  App.FlagGPIO -> HplFlagC.FlagGPIO;

}
