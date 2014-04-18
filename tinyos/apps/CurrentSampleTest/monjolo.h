#ifndef __COILCUBE_IP_H__
#define __COILCUBE_IP_H__

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

#define ACME_ADDR "2607:f018:800:103:60f:7db8:12:4b00"

#define CC2538_ADDR "2607:f018:800:103:1034:5678:90ab:cdef"
#define CC2538_ADDR_LINKL "fe80::1034:5678:90ab:cdef"

#define RECEIVER_ADDR "2001:470:1f10:1320::2"
#define RECEIVER_PORT 4001
#define PROFILE_ID "xxxXXXxxxX"

#define VOLTAGE_PORT 39888

#define NUM_CURRENT_SAMPLES 100

// Prefix for this node, just set it blank as we have no idea what the prefix
// will be.
#define IN6_PREFIX "::"

#define FRAM_ADDR_BASE  8

typedef struct {
  uint32_t version_hash;
  uint32_t wakeup_counter;
  uint8_t  seq_no;
} fram_data_t;

typedef struct {
  char profile[10]; // GATD profile ID
  uint8_t version;  // version of the coilcube
  uint8_t counter;  // number of wakeups of the coilcube
  uint8_t seq_no;   // copy of the 15.4 sequence number as this will be lost (udp)
  uint8_t reserved;
  uint16_t recv_count;
  uint16_t sfd_capture;
  uint16_t samples[NUM_CURRENT_SAMPLES]; // must be 16bit aligned
} __attribute__((packed)) pkt_data_t;

typedef enum {
  STATE_READ_TIMING_CAP,
  STATE_READ_TIMING_CAP_DONE,
  STATE_READ_FRAM_DONE,
  STATE_WRITE_FRAM_DONE,
  STATE_SAMPLE_CURRENT_DONE,
  STATE_DONE
} cc_state_e;


#endif
