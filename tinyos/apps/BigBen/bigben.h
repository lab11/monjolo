#ifndef __BIGBEN_H__
#define __BIGBEN_H__

#define FRAM_ADDR_START  8 // make room for ds2411 id

typedef struct {
  uint32_t version_hash;
  uint32_t wakeup_counter;
  uint8_t  last_seconds;  // last wakeup values
  uint8_t  last_minutes;
  uint8_t  last_hours;
  uint8_t  last_days;
  uint8_t  last_month;
  uint16_t last_year;
  uint32_t last_rate;     // average wakeup rate from before
  uint16_t storage_pointer; // where the next item in storage fram should go
  uint16_t storage_count;   // how many valid items in FRAM
} fram_data_t;

typedef enum {
  STATE_INITIAL_READ, // Get the starting seq no, counter and id from FRAM
  STATE_INITIAL_READ_DONE,
  STATE_CHECK_PKT_DELAY, // Check how long it has been since a packet
  STATE_CHECK_PKT_DELAY_DONE,
  STATE_SEND_PACKET,
  STATE_SEND_PACKET_DONE,
  STATE_DONE
} bb_state_e;


#endif
