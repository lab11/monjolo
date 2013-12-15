/**
 * Implementation of the FM24LxxxB serial FRAM
 *
 * @author Samuel DeBruin <sdebruin@umich.edu>
 */

configuration Fm25lbC {
  provides{
    interface Fm25lb;
  }
}
implementation {
  components Fm25lbP as FramP;
  Fm25lb = FramP;

  components MainC;
  FramP.Init <- MainC.SoftwareInit;

  components new Msp430Spi0C() as SpiC;
  FramP.SpiResource -> SpiC.Resource;
  FramP.SpiByte -> SpiC.SpiByte;
  FramP.SpiPacket -> SpiC.SpiPacket;

  components HplFm25lbPinsC as FramC;
  FramP.CSN -> FramC.CSN;
  FramP.Hold -> FramC.Hold;
  FramP.WP -> FramC.WP;
}
