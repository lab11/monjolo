 /*
 * @author Samuel DeBruin <sdebruin@umich.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

#ifndef __FM25LB_H__
#define __FM25LB_H__

#define FM25LB_CMD_WRITE_ENABLE  0x06
#define FM25LB_CMD_WRITE_DISABLE 0x04
#define FM25LB_CMD_READ_STATUS   0x05
#define FM25LB_CMD_WRITE_STATUS  0x01
#define FM25LB_CMD_READ          0x03
#define FM25LB_CMD_WRITE         0x02

#define FM25LB_READ_CMD_LEN          2
#define FM25LB_WRITE_CMD_LEN         2
#define FM25LB_READ_STATUS_CMD_LEN   1
#define FM25LB_READ_STATUS_DATA_LEN  1
#define FM25LB_WRITE_STATUS_CMD_LEN  1
#define FM25LB_WRITE_STATUS_DATA_LEN 1

typedef enum {
  FM25LB_STATE_READ_GOT_SPI,
  FM25LB_STATE_READ_SENT_CMD,
  FM25LB_STATE_READ_DONE,
  FM25LB_STATE_WRITE_GOT_SPI,
  FM25LB_STATE_WRITE_SENT_CMD,
  FM25LB_STATE_WRITE_DONE,
  FM25LB_STATE_READ_STATUS_GOT_SPI,
  FM25LB_STATE_READ_STATUS_DONE,
  FM25LB_STATE_WRITE_STATUS_GOT_SPI,
  FM25LB_STATE_WRITE_STATUS_DONE,
  FM25LB_STATE_DONE
} fm25lb_state_e;

// adds the 9th bit of the address to a command
#define FM25LB_ADD_ADDRESS_BIT(address, command) \
  (((address & 0x100) >> 5) | command)

#define FM25LB_GET_ADDRESS(cmd_byte, addr_byte) \
  (((uint16_t) addr_byte) | ((((uint16_t) cmd_byte) << 5) & 0x0100))

#endif
