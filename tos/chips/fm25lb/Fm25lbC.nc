/**
 * Implementation of the FM24LxxxB serial FRAM
 *
 * @author Samuel DeBruin <sdebruin@umich.edu>
 */

configuration Fm25lbC {
  provides{
    interface Init;
    interface Fm25lb;
  }
}
implementation {
  components Fm25lbP as FramP;
  Init = FramP;
  Fm25lb = FramP;

  components new Msp430Spi0C() as SpiC;
  FramP.SpiResource -> SpiC;
  FramP.SpiByte -> SpiC;
  FramP.SpiPacket -> SpiC;

  components HplFm25lbPinsC as FramC;
  FramP.CSN -> FramC.CSN;
  FramP.Hold -> FramC.Hold;
  FramP.WP -> FramC.WP;
}
