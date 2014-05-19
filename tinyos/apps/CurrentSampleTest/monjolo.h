#ifndef __COILCUBE_IP_H__
#define __COILCUBE_IP_H__

#include "Ieee154.h"

// Address of all voltage monitors (ideally) (TODO)
#define ADDR_ALL_ROUTERS "ff02::2"

// Address for the ACme++
#define ACME_ADDR       "2607:f018:800:103:60f:7db8:12:4b00"
#define ACME_ADDR_LINKL "fe80::60f:7db8:12:4b00"

// Address for the CC2538 EVM
#define CC2538_ADDR       "2607:f018:800:103:1034:5678:90ab:cdef"
#define CC2538_ADDR_LINKL "fe80::1034:5678:90ab:cdef"

// GATD information
#define GATD_ADDR "2001:470:1f10:1320::2"
#define GATD_PORT 4001
#define PROFILE_ID "jjAZl032Np"

// Constants for the packet type field
#define PKT_TYPE_POWER 0
#define PKT_TYPE_POWER_DEBUG 1

// Constants for hello message types
#define HELLO_MESSAGE_TYPE_VOLTAGE 0

// Port the voltage monitor operates on
#define VOLTAGE_REQUEST_PORT 39888U

// Maximum number of current samples to take
#define NUM_CURRENT_SAMPLES 500

// Prefix for this node, just set it blank as we have no idea what the prefix
// will be.
#define IN6_PREFIX "::"

// Make sure the base address is past the stored EUI64. We store the EUI64
// in FRAM so we don't have to rely on the DS2411 successfully working.
#define FRAM_ADDR_BASE  8

// States of the power meter state machine
typedef enum {
  STATE_START,
  STATE_FRAM_READ_DONE,
  STATE_READ_TIMING_CAP_DONE,
  STATE_SEND_HELLO_MESSAGE,
  STATE_SENT_HELLO_MESSAGE,
  STATE_SAMPLE_CURRENT,
  STATE_SAMPLE_CURRENT_DONE,
  STATE_SEND_POWER,
  STATE_CLEAR_POWER,
  STATE_DONE
} cc_state_e;

typedef enum {
  ADC_STATE_OFF,
  ADC_STATE_TIMING,
  ADC_STATE_COIL
} adc_state_e;

// The data structure stored in the FRAM
typedef struct {
  uint32_t version_hash;   // IDENT_UIDHASH. If this doesn't match the FRAM data is invalid
  uint32_t wakeup_counter; // Count of activations. (Useful for also doing Monjolo operation)
  uint8_t  seq_no;         // 802.15.4 seq no so it can increment as the spec expects
  int32_t  power;          // Stored power value from the last wakeup
  uint32_t power_factor;   // Stored power factor from the last wakeup (not used yet)
  uint32_t voltage;        // Peak AC voltage in mV
} fram_data_t;

// The data structure transmitted to the voltage monitor requesting
// voltage information
typedef struct {
  uint8_t msg_type;
} __attribute__((packed)) pkt_hello_t;

// The data transmitted to a server (GATD)
typedef struct {
  char        profile[10];    // GATD profile ID
  nx_uint8_t  version;        // version of the coilcube
  nx_uint8_t  pkt_type;       // what data this packet contains
  nx_uint8_t  seq_no;         // copy of the 15.4 sequence number as this will be lost (udp)
  nx_uint8_t  reserved;       // align to 16 bit
  nx_uint32_t wakeup_counter; // number of wakeups of the coilcube
  nx_int32_t  power;          // power of the load from the last activation
  nx_uint32_t power_factor;   // power factor of the load from the last activation (not used yet)
  nx_uint32_t voltage;        // voltage in millivolts of the circuit (from voltage monitor)
} __attribute__((packed)) pkt_data_t;

// The data transmitted to a server (GATD) for debugging
typedef nx_struct {
  nx_uint8_t  profile[10]; // GATD profile ID
  nx_uint8_t  version;     // version of the coilcube
  nx_uint8_t  pkt_type;    // what data this packet contains
  nx_uint8_t  seq_no;      // copy of the 15.4 sequence number as this will be lost (udp)
  nx_uint8_t  reserved;
  nx_uint32_t wakeup_counter;  // number of wakeups of the coilcube
  nx_int32_t power;
  nx_uint32_t power_factor;
  nx_uint16_t tdelta;
  nx_uint32_t voltage;
  nx_uint32_t ticks;
} __attribute__((packed)) pkt_data_debug_t;

// The data structure of the response from the voltage monitor
typedef nx_struct {
  nx_uint32_t vpeak;              // max voltage of AC waveform
  nx_uint32_t ticks_since_rising; // time from rising zero-crossing of AC signal to SFD
  nx_uint16_t chksum_balance;     // 16 bits to compensate for checksum
  nx_uint8_t  ending;             // Magic byte to identify these packets
} __attribute__ ((__packed__)) voltage_data_t;




#endif
