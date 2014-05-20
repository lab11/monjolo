#include <stdint.h>
#include <stdio.h>

typedef enum {
  JANUARY   = 1,
  FEBRUARY  = 2,
  MARCH     = 3,
  APRIL     = 4,
  MAY       = 5,
  JUNE      = 6,
  JULY      = 7,
  AUGUST    = 8,
  SEPTEMBER = 9,
  OCTOBER   = 10,
  NOVEMBER  = 11,
  DECEMBER  = 12
} month_e;

typedef struct {
  uint8_t  then_seconds;
  uint8_t  then_minutes;
  uint8_t  then_hours;
  uint8_t  then_days;  // 1 indexed
  month_e  then_month; // 1 indexed
  uint16_t then_year;
  uint8_t  now_seconds;
  uint8_t  now_minutes;
  uint8_t  now_hours;
  uint8_t  now_days;  // 1 indexed
  month_e  now_month; // 1 indexed
  uint16_t now_year;
  uint32_t answer;
} test_t;


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


int main () {

  uint8_t i;

#define NUMBER_OF_TESTS sizeof tests / sizeof tests[0]

  test_t tests[] = {
    {23, 33, 16, 18, 12, 2012, 33, 43,  3, 14,  1, 2013, 2286610},
    {25, 44,  7,  4,  3, 2012, 48, 22, 17, 13,  3, 2012, 812303},
    {48, 22, 17, 13,  3, 2012, 48, 33,  3, 27,  8, 2012, 14379060},
    {59, 59, 23, 31,  3, 2014, 58,  3, 18, 19,  5, 2015, 35748239},
    {43, 32,  6,  1,  2, 2014, 58,  3, 18, 19,  5, 2015, 40822275},
    {20,  1, 14, 20,  5, 2014, 23,  1, 14, 20,  5, 2014, 3}
  };


  for (i=0; i<NUMBER_OF_TESTS; i++) {
    uint32_t result;

    result = calculate_time_diff(tests[i].then_seconds,
                                 tests[i].then_minutes,
                                 tests[i].then_hours,
                                 tests[i].then_days,
                                 tests[i].then_month,
                                 tests[i].then_year,
                                 tests[i].now_seconds,
                                 tests[i].now_minutes,
                                 tests[i].now_hours,
                                 tests[i].now_days,
                                 tests[i].now_month,
                                 tests[i].now_year);

    printf("RESULT: ours: %i, correct: %i\t", result, tests[i].answer);

    if (tests[i].answer == result) {
      printf("YES\n");
    } else {
      printf("NO\n");
    }
  }


  return 0;
}
