
module MotePlatformC @safe() {
  provides {
    interface Init;
  }
  uses {
    interface Init as SubInit;
  }
}
implementation {

/*
 * This function gets called automatically by the linker/init sequence.
 * It fits in before the c runtime gets going.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */
/*__attribute__((naked, section(".init3"))) void __low_level_init()  @C() @spontaneous() {
    // enable VREN of radio
    P4DIR |= 1<<5;
    P4OUT |= 1<<5;

    WDTCTL = WDTPW + WDTHOLD; // Stop watchdog timer

    BCSCTL1 = XT2OFF | (0x07); // select highest DCO freq possible
    BCSCTL2 = DIVS0 | DCOR;    // select external resistor
    DCOCTL = 0xE0;             // highest DCOx possible

    CLR_FLAG(IE1, OFIE);
  }*/

  command error_t Init.init() {
    // reset all of the ports to be input and using i/o functionality
    atomic {
      P1SEL = 0;
      P2SEL = 0;
      P3SEL = 0;
      P4SEL = 0;
      P5SEL = 0;
      P6SEL = 0;

      P1OUT = 0x00;
      P1DIR = 0xe0;

      P2OUT = 0x32;
      P2DIR = 0x7b;

      P3OUT = 0x00;
      P3DIR = 0xf1;

      P4OUT = 0xfd;
      P4DIR = 0xdd;

      P5OUT = 0xF7;
      P5DIR = 0xfb;

      P6OUT = 0x30;
      P6DIR = 0xfb;

      P1IE = 0;
      P2IE = 0;

      // the commands above take care of the pin directions
      // there is no longer a need for explicit set pin
      // directions using the TOSH_SET/CLR macros
    }

    return call SubInit.init();
  }

  default command error_t SubInit.init() {
    return SUCCESS;
  }
}
