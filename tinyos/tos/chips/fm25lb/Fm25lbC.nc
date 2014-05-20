/**
 * Implementation of the FM25LxxxB serial FRAM
 *
 * @author Samuel DeBruin <sdebruin@umich.edu>
 */

generic configuration Fm25lbC () {
  provides {
    interface Fm25lb;
  }
  uses {
    interface GeneralIO as CSN;
    interface GeneralIO as Hold;
    interface GeneralIO as WP;
  }
}
implementation {
  components new Fm25lbP() as FramP;
  Fm25lb = FramP.Fm25lb;

  components MainC;
  FramP.Init <- MainC.SoftwareInit;

  components new Msp430Spi0C() as SpiC;
  FramP.SpiResource -> SpiC.Resource;
  FramP.SpiByte -> SpiC.SpiByte;
  FramP.SpiPacket -> SpiC.SpiPacket;

//  components HplFm25lbPinsC as FramC;
//  FramP.CSN -> FramC.CSN;
//  FramP.Hold -> FramC.Hold;
//  FramP.WP -> FramC.WP;

  FramP.CSN = CSN;
  FramP.Hold = Hold;
  FramP.WP = WP;
}
