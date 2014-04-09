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

#define RECEIVER_ADDR "2001:470:1f10:1320::2"
#define RECEIVER_PORT 4001
#define PROFILE_ID "1234567890"

#define AIRFLOW_VERSION 0

// Prefix for this node, just set it blank as we have no idea what the prefix
// will be.
#define IN6_PREFIX "::"

// Maximum number of airflow samples we store
#define MAX_NUM_AIRFLOW_SAMPLES 200


typedef struct {
  uint32_t version_hash;
  uint32_t wakeup_counter;
  uint8_t  seq_no;
  uint16_t sample_count;
} fram_data_t;

#define FRAM_ADDR_BASE    8 // offset past DS2411 id
#define FRAM_ADDR_SAMPLES 8+sizeof(fram_data_t)

typedef struct {
  char profile[10]; // GATD profile ID
  uint8_t version;  // version of the coilcube
  uint8_t seq_no;   // copy of the 15.4 sequence number as this will be lost (udp)
  uint32_t wakeup_counter;  // number of wakeups of the coilcube
  uint32_t airflow_sample_total;
  uint16_t sample_count;
  uint16_t samples[5];
} __attribute__((packed)) pkt_data_t;

typedef enum {
  STATE_INITIAL_READ,
  STATE_INITIAL_READ_DONE,
  STATE_CHECK_PKT_DELAY_DONE,
  STATE_SEND_PACKET,
  STATE_SEND_PACKET_READ_SAMPLES_DONE,
  STATE_SEND_PACKET_START_BLIP_DONE,
  STATE_SAMPLE_AIRFLOW,
  STATE_SAMPLE_AIRFLOW_RECORD,
  STATE_SAMPLE_AIRFLOW_UPDATE_COUNT,
  STATE_DONE
} cc_state_e;


#endif
