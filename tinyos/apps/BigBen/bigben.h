#ifndef __BIGBEN_H__
#define __BIGBEN_H__

#define FRAM_ADDR_START  8 // make room for ds2411 id

#define DIFF_THRESHOLD 30

typedef struct {
  uint32_t version_hash;
  uint32_t wakeup_counter;
  uint8_t  last_seconds;  // last wakeup values
  uint8_t  last_minutes;
  uint8_t  last_hours;
  uint8_t  last_days;
  uint8_t  last_month;
  uint16_t last_year;
  uint32_t last_diff;       // time between previous two wakeups
  uint16_t storage_pointer; // where the next item in storage fram should go
  uint16_t storage_count;   // how many valid items in FRAM
} fram_data_t;

typedef struct {
  uint32_t wakeup_counter;
  uint8_t  seconds;
  uint8_t  minutes;
  uint8_t  hours;
  uint8_t  days;
  uint8_t  month;
  uint8_t  year;   // plus 2000
  uint32_t last_diff;
} fram_log_t;

typedef enum {
  STATE_INITIAL_READ,
  STATE_INITIAL_READ_DONE,
  STATE_READ_RTC_DONE,
  STATE_WRITE_SCRATCH,
  STATE_DONE
} bb_state_e;


#endif
