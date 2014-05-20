#include "rv3049.h"
#include "bigben.h"

/* BigBen app for logging events.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

module BigBenP {
	uses {
		interface Leds;
    interface Boot;

    interface Fm25lb as FramScratch;
    interface Fm25lb as FramStorage;

    interface RVRTC as RTC;

    interface HplMsp430GeneralIO as FlagGPIO;
  }
}
implementation {

  // Time saved between event and state machine
  uint8_t  seconds;
  uint8_t  minutes;
  uint8_t  hours;
  uint8_t  days;
  month_e  month;
  uint16_t year;

  fram_data_t fram_data;
  fram_log_t  log_data;
  bb_state_e state;

  task void state_machine();

  event void Boot.booted() {
    state = STATE_INITIAL_READ;
    post state_machine();
  }

  void read_scratch () {
    call FramScratch.read(FRAM_ADDR_START,
                          (uint8_t*) &fram_data,
                          sizeof(fram_data_t));
  }

  void write_scratch () {
    call FramScratch.write(FRAM_ADDR_START,
                           (uint8_t*) &fram_data,
                           sizeof(fram_data_t));
  }

  void write_log () {
    uint16_t storage_pointer;

    storage_pointer = fram_data.storage_pointer;

    fram_data.storage_pointer += sizeof(fram_log_t);
    fram_data.storage_count++;

    call FramStorage.write(storage_pointer,
                           (uint8_t*) &log_data,
                           sizeof(fram_log_t));
  }

  // calculate time difference between now and then in seconds
  uint32_t calculate_time_diff (uint8_t  then_seconds,
                                uint8_t  then_minutes,
                                uint8_t  then_hours,
                                uint8_t  then_days,  // 1 indexed
                                month_e  then_month, // 1 indexed
                                uint16_t then_year,
                                uint8_t  now_seconds,
                                uint8_t  now_minutes,
                                uint8_t  now_hours,
                                uint8_t  now_days,  // 1 indexed
                                month_e  now_month, // 1 indexed
                                uint16_t now_year) {


    uint32_t month_lengths[12] = {2678400, // jan
                                  2419200, // feb
                                  2678400, // mar
                                  2592000, // apr
                                  2678400, // may
                                  2592000, // jun
                                  2678400, // jul
                                  2678400, // aug
                                  2592000, // sep
                                  2678400, // oct
                                  2592000, // nov
                                  2678400}; // dec

    uint32_t month_seconds_now, month_seconds_then;
    uint32_t diff_seconds;


    // calculate the number of seconds since the beginning of the month
    month_seconds_now = (((uint32_t)(now_days-1))*86400) +
                        (((uint32_t) now_hours)*3600) +
                        (((uint32_t) now_minutes)*60) +
                        (uint32_t) now_seconds;
    month_seconds_then = (((uint32_t)(then_days-1))*86400) +
                         (((uint32_t) then_hours)*3600) +
                         (((uint32_t) then_minutes)*60) +
                         (uint32_t) then_seconds;

    // calculate based on a few cases
    if (now_year == then_year && now_month == then_month) {
      // same month
      // this is simple, just subtract
      diff_seconds = month_seconds_now - month_seconds_then;

    } else {
      uint8_t now_month_adjusted, then_month_adjusted;
      uint32_t remaining_previous_month;
      uint32_t middle_months = 0;
      uint8_t i;

      // find the number of seconds from the previous timestamp and the
      // end of its month
      remaining_previous_month = month_lengths[then_month-1] -
                                 month_seconds_then;

      // Compensate for the year changing
      then_month_adjusted = then_month - 1;
      now_month_adjusted = (now_month - 1) + (12 * (now_year-then_year));

      // Sum the time in the months between the two months
      for (i=then_month_adjusted+1; i<now_month_adjusted; i++) {
        middle_months += month_lengths[i%12];
      }

      // Difference is now the sum
      diff_seconds = month_seconds_now +
                     middle_months +
                     remaining_previous_month;

    }

    return diff_seconds;
  }

  task void state_machine () {
    switch (state) {
      case STATE_INITIAL_READ:
        // Read in the status from the FRAM
        state = STATE_INITIAL_READ_DONE;
        read_scratch();
        break;

      case STATE_INITIAL_READ_DONE:
        if (fram_data.version_hash == IDENT_UIDHASH) {
          // FRAM hash matches, data is valid
          state = STATE_READ_RTC_DONE;
          fram_data.wakeup_counter++;
          call RTC.readTime();
        } else {
          state = STATE_WRITE_SCRATCH;
          // FRAM hash does not match, reset everything
          memset(&fram_data, 0, sizeof(fram_data_t));
          fram_data.version_hash = IDENT_UIDHASH;

          // set RTC time with constants acquired at compile time
          call RTC.setTime(RTC_SECONDS,
                           RTC_MINUTES,
                           RTC_HOURS,
                           RTC_DAYS,
                           RTC_MONTH,
                           RTC_YEAR,
                           RTC_WEEKDAY);
        }
        break;

      case STATE_READ_RTC_DONE:

        if (fram_data.last_year == 0) {
          // first wakeup
          fram_data.last_seconds = seconds;
          fram_data.last_minutes = minutes;
          fram_data.last_hours   = hours;
          fram_data.last_days    = days;
          fram_data.last_month   = month;
          fram_data.last_year    = year;

          log_data.wakeup_counter = fram_data.wakeup_counter;
          log_data.seconds = seconds;
          log_data.minutes = minutes;
          log_data.hours   = hours;
          log_data.days    = days;
          log_data.month   = month;
          log_data.year    = (uint8_t) (year-2000);

          state = STATE_WRITE_SCRATCH;
          write_log();

        } else {
          // calculate time difference between now and the last wakeup
          uint32_t diff_seconds;
          uint32_t diff_from_last_interval;

          diff_seconds = calculate_time_diff(fram_data.last_seconds,
                                             fram_data.last_minutes,
                                             fram_data.last_hours,
                                             fram_data.last_days,
                                             fram_data.last_month,
                                             fram_data.last_year,
                                             seconds,
                                             minutes,
                                             hours,
                                             days,
                                             month,
                                             year);

          if (diff_seconds > fram_data.last_diff) {
            diff_from_last_interval = diff_seconds - fram_data.last_diff;
          } else {
            diff_from_last_interval = fram_data.last_diff - diff_seconds;
          }

          // Make sure scratch fram gets updated
          fram_data.last_seconds = seconds;
          fram_data.last_minutes = minutes;
          fram_data.last_hours   = hours;
          fram_data.last_days    = days;
          fram_data.last_month   = month;
          fram_data.last_year    = year;
          fram_data.last_diff    = diff_seconds;

          if (diff_from_last_interval > DIFF_THRESHOLD) {
            // this is a change! record it!
            state = STATE_WRITE_SCRATCH;

            log_data.wakeup_counter = fram_data.wakeup_counter;
            log_data.seconds = seconds;
            log_data.minutes = minutes;
            log_data.hours   = hours;
            log_data.days    = days;
            log_data.month   = month;
            log_data.year    = (uint8_t) (year-2000);

            write_log();

          } else {
            // just updated scratch fram
            state = STATE_DONE;
            write_scratch();
          }
        }

        break;

      case STATE_WRITE_SCRATCH:
        state = STATE_DONE;
        write_scratch();
        break;

      case STATE_DONE:
        break;

      default:
        break;

    }

  }


  event void FramScratch.readDone(uint16_t addr,
                           uint8_t* buf,
                           uint16_t len,
                           error_t err) {
    post state_machine();
  }

  event void FramScratch.writeDone(uint16_t addr,
                            uint8_t* buf,
                            uint16_t len,
                            error_t err) {
    post state_machine();
  }

  event void FramStorage.readDone(uint16_t addr,
                           uint8_t* buf,
                           uint16_t len,
                           error_t err) {
    post state_machine();
  }

  event void FramStorage.writeDone(uint16_t addr,
                            uint8_t* buf,
                            uint16_t len,
                            error_t err) {
    post state_machine();
  }

  event void FramScratch.readStatusDone (uint8_t status, error_t err) {
    post state_machine();
  }

  event void FramScratch.writeStatusDone(error_t err) {
    post state_machine();
  }

  event void FramStorage.readStatusDone (uint8_t status, error_t err) {
    post state_machine();
  }

  event void FramStorage.writeStatusDone(error_t err) {
    post state_machine();
  }

  event void RTC.readTimeDone (error_t error,
                               uint8_t rtcseconds,
                               uint8_t rtcminutes,
                               uint8_t rtchours,
                               uint8_t rtcdays,
                               month_e rtcmonth,
                               uint16_t rtcyear,
                               day_e rtcweekday) {
    seconds = rtcseconds;
    minutes = rtcminutes;
    hours   = rtchours;
    days    = rtcdays;
    month   = rtcmonth;
    year    = rtcyear;

    post state_machine();
  }

  event void RTC.setTimeDone (error_t error) {
    post state_machine();
  }


}
