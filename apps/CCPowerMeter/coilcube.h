#ifndef __COILCUBE_H__
#define __COILCUBE_H__

#include "Ieee154.h"

#define PANID 0x0022

#define ADDR_ID     0
#define ADDR_COUNT  8
#define ADDR_SEQ_NO 9

typedef struct {
  ieee_eui64_t id;
  uint8_t counter;
  uint8_t seq_no;
} __attribute__((packed)) fram_data_t;

typedef struct {
  uint8_t version; // version of the coilcube
  uint8_t counter; // number of wakeups of the coilcube
} __attribute__((packed)) pkt_data_t;

typedef enum {
  STATE_INITIAL_READ, // Get the starting seq no, counter and id from FRAM
  STATE_INITIAL_READ_DONE,
  STATE_CHECK_PKT_DELAY, // Check how long it has been since a packet
  STATE_CHECK_PKT_DELAY_DONE,
  STATE_SEND_PACKET,
  STATE_SEND_PACKET_DONE,
  STATE_DONE
} cc_state_e;

#endif
