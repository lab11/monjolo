/**
 * Implementation of the SPI based Micro Crystal RTC
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration RV3049C {
  provides {
    interface RVRTC;
  }
  uses {
    interface GeneralIO as CS;
  }
}
implementation {
  components RV3049P as RtcP;

  components MainC;
  RtcP.Init <- MainC.SoftwareInit;

  components new Msp430Spi0C() as SpiC;
  RtcP.SpiResource -> SpiC.Resource;
  RtcP.SpiByte -> SpiC.SpiByte;
  RtcP.SpiPacket -> SpiC.SpiPacket;

  RtcP.CS = CS;

  RVRTC = RtcP.RVRTC;
}
