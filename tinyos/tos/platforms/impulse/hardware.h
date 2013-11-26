/**
 * Hardware definition for the Coilcube platform.
 *
 * @author Brad Campbell
 */
#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"

// enum so components can override power saving,
// as per TEP 112.
enum {
  TOS_SLEEP_NONE = MSP430_POWER_ACTIVE,
};

// internal flash is 16 bits in width
typedef uint16_t in_flash_addr_t;
// external flash is 32 bits in width
typedef uint32_t ex_flash_addr_t;

void wait(uint16_t t) {
  for ( ; t > 0; t-- );
}

// LEDS
TOSH_ASSIGN_PIN(RED_LED, 6, 1);
TOSH_ASSIGN_PIN(GREEN_LED, 4, 3);
TOSH_ASSIGN_PIN(YELLOW_LED, 4, 7);

// CC2420 RADIO
TOSH_ASSIGN_PIN(RADIO_CSN, 4, 2);
TOSH_ASSIGN_PIN(RADIO_VREF, 4, 5);
TOSH_ASSIGN_PIN(RADIO_RESET, 4, 6);
TOSH_ASSIGN_PIN(RADIO_FIFOP, 1, 0);
TOSH_ASSIGN_PIN(RADIO_SFD, 4, 1);
TOSH_ASSIGN_PIN(RADIO_GIO0, 1, 3);
TOSH_ASSIGN_PIN(RADIO_FIFO, 1, 3);
TOSH_ASSIGN_PIN(RADIO_GIO1, 1, 4);
TOSH_ASSIGN_PIN(RADIO_CCA, 1, 4);

TOSH_ASSIGN_PIN(CC_FIFOP, 1, 0);
TOSH_ASSIGN_PIN(CC_FIFO, 1, 3);
TOSH_ASSIGN_PIN(CC_SFD, 4, 1);
TOSH_ASSIGN_PIN(CC_VREN, 4, 5);
TOSH_ASSIGN_PIN(CC_RSTN, 4, 6);

// USART0
TOSH_ASSIGN_PIN(SIMO0, 3, 1);
TOSH_ASSIGN_PIN(SOMI0, 3, 2);
TOSH_ASSIGN_PIN(UCLK0, 3, 3);

// USART1
TOSH_ASSIGN_PIN(SIMO1, 5, 1);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(UCLK1, 5, 3);

// UART1
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);
TOSH_ASSIGN_PIN(UTXD1, 3, 6);
TOSH_ASSIGN_PIN(URXD1, 3, 7);

// User Interupt Pin
TOSH_ASSIGN_PIN(USERINT, 2, 7);

// FLASH
TOSH_ASSIGN_PIN(FLASH_CS, 4, 4);

// 1-Wire
TOSH_ASSIGN_PIN(ONEWIRE, 2, 4);


void TOSH_SET_PIN_DIRECTIONS(void)
{
  P3SEL = 0x0E; // set SPI and I2C to mod func

  P1DIR = 0xe0;
  P1OUT = 0x00;

  P2DIR = 0x7b;
  P2OUT = 0x10;

  P3DIR = 0xf1;
  P3OUT = 0x00;

  P4DIR = 0xfd;
  P4OUT = 0xdd;

  P5DIR = 0xff;
  P5OUT = 0xff;

  P6DIR = 0xff;
  P6OUT = 0x00;
}

// need to undef atomic inside header files or nesC ignores the directive
#undef atomic

#endif // _H_hardware_h
