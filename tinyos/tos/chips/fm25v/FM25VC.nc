/**
 * Implementation of the FM25Vxx serial FRAM
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

generic configuration FM25VC () {
  provides {
    interface FM25V;
  }
  uses {
    interface GeneralIO as CSN;
    interface GeneralIO as Hold;
    interface GeneralIO as WP;
  }
}
implementation {
  components new FM25VP() as FramP;
  FM25V = FramP.FM25V;

  components MainC;
  FramP.Init <- MainC.SoftwareInit;

  components new Msp430Spi0C() as SpiC;
  FramP.SpiResource -> SpiC.Resource;
  FramP.SpiByte -> SpiC.SpiByte;
  FramP.SpiPacket -> SpiC.SpiPacket;

  FramP.CSN = CSN;
  FramP.Hold = Hold;
  FramP.WP = WP;
}
