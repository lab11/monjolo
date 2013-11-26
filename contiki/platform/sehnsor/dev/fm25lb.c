/**
* \defgroup sehnsor
* @{
*/

#include "contiki.h"
#include "fm25lb.h"
#include "spi.h"

#include <stdio.h>

/**
* \file   Driver for the FM25LB series of flash chips
* \author Brad Campbell <bradjc@umich.edu>
*/

/**
 * \brief Initialize the fm25lb.
 */
void
fm25lb_init()
{
  /* Set the HOLD_N and WP_N pins to outputs and high */
  GPIO_SET_OUTPUT(GPIO_PORT_TO_BASE(FM25LB_HOLD_N_PORT_NUM),
                  GPIO_PIN_MASK(FM25LB_HOLD_N_PIN));
  GPIO_SET_OUTPUT(GPIO_PORT_TO_BASE(FM25LB_WP_N_PORT_NUM),
                  GPIO_PIN_MASK(FM25LB_WP_N_PIN));
  GPIO_SOFTWARE_CONTROL(GPIO_PORT_TO_BASE(FM25LB_HOLD_N_PORT_NUM),
                        GPIO_PIN_MASK(FM25LB_HOLD_N_PIN));
  GPIO_SOFTWARE_CONTROL(GPIO_PORT_TO_BASE(FM25LB_WP_N_PORT_NUM),
                        GPIO_PIN_MASK(FM25LB_WP_N_PIN));
  GPIO_SET_PIN(GPIO_PORT_TO_BASE(FM25LB_HOLD_N_PORT_NUM),
               GPIO_PIN_MASK(FM25LB_HOLD_N_PIN));
  GPIO_SET_PIN(GPIO_PORT_TO_BASE(FM25LB_WP_N_PORT_NUM),
               GPIO_PIN_MASK(FM25LB_WP_N_PIN));
}

/**
 * \brief         Read from the FRAM chip.
 * \param address The index of the byte to start reading from.
 * \param len     The number of bytes to read.
 * \param buf     A buffer to put the return data in.
 * \return        0 on success, -1 on error
 *
 *                Reads len bytes from the FRAM chip starting at address.
 */
int
fm25lb_read(uint16_t address, uint16_t len, uint8_t *buf)
{
  uint16_t i, j;
  uint16_t c;
  uint16_t cycles = (len / 6) + 1;
  uint16_t index = 0;
  uint16_t current_address = address;

  /* Flush the RX FIFO to start */
  while (REG(SSI0_BASE + SSI_O_SR) & SSI_SR_RNE) {
    SPI_RXBUF;
  }

  /* Read 6 bytes in at a time.
   * This allows us to use the 8 slots in the RX FIFO. Any sort of delay
   * when transmitting causes the CS_N line to go back high, ending our
   * transaction with the FM25LB. */
  for (c=0; c<cycles; c++) {
    uint16_t reads_this_cycle = 6;

    /* Don't read the full 6 bytes on the last portion */
    if (c*6 + 6 > len) {
      reads_this_cycle = len - c*6;
    }

    /* Send the READ command and the address to the FRAM */
    SPI_WRITE_FAST(FM25LB_ADD_ADDRESS_BIT(current_address, FM25LB_READ_COMMAND));
    SPI_WRITE_FAST(current_address & 0xFF);

    /* Write 0s so the chip can respond with the data */
    for(i=0; i<reads_this_cycle; i++) {
      SPI_WRITE_FAST(0);
    }
    SPI_WAITFOREOTx();

    /* Copy from the RX FIFO. Skip the invalid bytes from when we sent the
     * command. */
    i=0;
    while (REG(SSI0_BASE + SSI_O_SR) & SSI_SR_RNE) {
      if (i < 2) {
        SPI_RXBUF;
      } else {
        buf[index++] = (uint16_t) SPI_RXBUF;
      }
      i++;
    }

    current_address += 6;
  }

  return 0;
}

/**
 * \brief         Write to the FRAM chip.
 * \param address The index of the byte to start writing to.
 * \param len     The number of bytes to write.
 * \param buf     A buffer of values to write.
 * \return        0 on success, -1 on error
 *
 *                Writes len bytes to the FRAM chip starting at address.
 */
int
fm25lb_write(uint16_t address, uint16_t len, uint8_t *buf)
{
  uint16_t i;

  /* Send the WRITE ENABLE command to allow writing to the FRAM */
  SPI_WRITE(FM25LB_WRITE_ENABLE_COMMAND);

  /* Clear the RX FIFO so that CS_N will go back high so we can write a new
   * command. */
  while (REG(SSI0_BASE + SSI_O_SR) & SSI_SR_RNE) {
    SPI_RXBUF;
  }

  /* Send the WRITE command and the address to the FRAM */
  SPI_WRITE_FAST(FM25LB_ADD_ADDRESS_BIT(address, FM25LB_WRITE_COMMAND));
  SPI_WRITE_FAST(address & 0xFF);

  /* Send the data to write */
  for(i=0; i<len; i++) {
    SPI_WRITE_FAST(buf[i]);
  }
  SPI_WAITFOREOTx();

  /* Flush anything read while sending the write */
  while (REG(SSI0_BASE + SSI_O_SR) & SSI_SR_RNE) {
    SPI_RXBUF;
  }

  return 0;
}



