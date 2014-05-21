#ifndef __MONJOLO_H__
#define __MONJOLO_H__

#include "Ieee154.h"

// MONJOLO_VERSION
// Constant to keep track of which revision of monjolo sent the packet.
// 0: unused
// 1: coilcube rev a, rev b, rev c
// 2: sEHnsor
// 3: impulse rev a, rev b
// 4: coilcube/splitcore with impulse
// 5: gecko power supply + impulse

#define ADDR_ALL_ROUTERS "ff02::2"

#define RECEIVER_ADDR "2001:470:1f10:1320::2"
#define RECEIVER_PORT 4001
#define PROFILE_ID "7aiOPJapXF"

// Prefix for this node, just set it blank as we have no idea what the prefix
// will be.
#define IN6_PREFIX "::"

#define FRAM_ADDR_COUNT  8 // make room for ds2411 id
#define FRAM_ADDR_SEQ_NO 9

typedef struct {
//  ieee_eui64_t id;
  uint8_t counter;
  uint8_t seq_no;
} __attribute__((packed)) fram_data_t;

typedef struct {
  char profile[10]; // GATD profile ID
  uint8_t version;  // version of the coilcube
  uint8_t counter;  // number of wakeups of the coilcube
  uint8_t seq_no;   // copy of the 15.4 sequence number as this will be lost (udp)
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
