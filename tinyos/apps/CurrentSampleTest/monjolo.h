#ifndef __COILCUBE_IP_H__
#define __COILCUBE_IP_H__

#include "Ieee154.h"



#define ADDR_ALL_ROUTERS "ff02::2"

#define ACME_ADDR       "2607:f018:800:103:60f:7db8:12:4b00"
#define ACME_ADDR_LINKL "fe80::60f:7db8:12:4b00"

#define CC2538_ADDR       "2607:f018:800:103:1034:5678:90ab:cdef"
#define CC2538_ADDR_LINKL "fe80::1034:5678:90ab:cdef"

#define GATD_ADDR "2001:470:1f10:1320::2"
#define GATD_PORT 4001
#define PROFILE_ID "jjAZl032Np"

#define PKT_TYPE_POWER 0
#define PKT_TYPE_SAMPLES 5

#define VOLTAGE_REQUEST_PORT 39888U

#define NUM_CURRENT_SAMPLES 500

// Prefix for this node, just set it blank as we have no idea what the prefix
// will be.
#define IN6_PREFIX "::"

#define FRAM_ADDR_BASE  8

typedef struct {
  uint32_t version_hash;
  uint32_t wakeup_counter;
  uint8_t  seq_no;
  uint32_t power;
  uint32_t power_factor;
} fram_data_t;

typedef struct {
  uint8_t hello_message;
} __attribute__((packed)) pkt_hello_t;

typedef struct {
  char     profile[10]; // GATD profile ID
  uint8_t  version;  // version of the coilcube
  uint8_t  pkt_type; // what data this packet contains
  uint8_t  seq_no;   // copy of the 15.4 sequence number as this will be lost (udp)
  uint8_t  reserved;
  uint32_t wakeup_counter;  // number of wakeups of the coilcube
  uint32_t power;
  uint32_t power_factor;
} __attribute__((packed)) pkt_data_t;

typedef struct {
  char     profile[10]; // GATD profile ID
  uint8_t  version;  // ver `sion of the coilcube
  uint8_t  pkt_type; // what data this packet contains
  uint8_t  seq_no;   // copy of the 15.4 sequence number as this will be lost (udp)
  uint8_t  reserved;
  uint16_t samples[30];
} __attribute__((packed)) pkt_samples_t;

typedef nx_struct {
  nx_uint32_t vpeak;              // max voltage of AC waveform
  nx_uint32_t ticks_since_rising; // time from rising zero-crossing of AC signal to SFD
  nx_uint16_t chksum_balance;     // 16 bits to compensate for checksum
  nx_uint8_t  ending;             // Magic byte to identify these packets
} __attribute__ ((__packed__)) voltage_data_t;

typedef enum {
  STATE_START,
  STATE_FRAM_READ,
  STATE_READ_TIMING_CAP_DONE,
  STATE_SEND_HELLO_MESSAGE,
  STATE_SENT_HELLO_MESSAGE,
  STATE_SAMPLE_CURRENT_DONE,
  STATE_SEND_POWER,
  STATE_CLEAR_POWER,
  STATE_DONE
} cc_state_e;


#endif
