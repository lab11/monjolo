#ifndef __COILCUBE_PACKET_H__
#define __COILCUBE_PACKET_H__

#define DATA_TYPE_RAW 1
#define DATA_TYPE_CALCULATED 2

#define GATD_PROFILEID_LEN 10

typdef struct {
  char    profile[GATD_PROFILEID_LEN]; // ID of the GATD profile for coilcube
  uint8_t type;                        // Which data packet this is
} __attribute__((packed)) cc_gatd_pkt_header_t;

// Struct to hold and send raw coilcube packets to the server
typedef struct {
  ieee_eui64_t id;        // 64 bit id of the transmitting coilcube
  uint64_t     timestamp; // When the cc packet was received (in us)
  uint8_t      seq_no;    // 802.15.4 packet sequence number
  uint8_t      counter;   // Coilcube wakeup counter
} __attribute__((packed)) cc_raw_pkt_t;

#endif
