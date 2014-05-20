 /*
 * @author Brad Campbell <bradjc@umich.edu>
 */

#ifndef __FM25V_H__
#define __FM25V_H__

#define FM25V_CMD_WRITE_ENABLE  0x06
#define FM25V_CMD_WRITE_DISABLE 0x04
#define FM25V_CMD_READ_STATUS   0x05
#define FM25V_CMD_WRITE_STATUS  0x01
#define FM25V_CMD_READ          0x03
#define FM25V_CMD_WRITE         0x02

typedef enum {
  FM25V_STATE_READ,
  FM25V_STATE_READ_SENT_CMD,
  FM25V_STATE_READ_DONE,
  FM25V_STATE_WRITE,
  FM25V_STATE_WRITE_SENT_CMD,
  FM25V_STATE_WRITE_DONE,
  FM25V_STATE_DONE
} fm25v_state_e;

#endif
