#ifndef __RV3049_H__
#define __RV3049_H__

// Addresses for the RTC registers
#define RV3049_PAGE_ADDR_CONTROL     0x00
#define RV3049_PAGE_ADDR_CLOCK       0x08
#define RV3049_PAGE_ADDR_ALARM       0x10
#define RV3049_PAGE_ADDR_TIMER       0x18
#define RV3049_PAGE_ADDR_TEMP        0x20
#define RV3049_PAGE_ADDR_EEPROM_USER 0x28
#define RV3049_PAGE_ADDR_EEPROM_CTRL 0x30
#define RV3049_PAGE_ADDR_RAM         0x38

#define RV3049_READ_LEN_TIME 8

#define RV3049_WRITE_LEN_TIME 8

#define RV3049_SET_READ_BIT(command) (0x80 | command)
#define RV3049_SET_WRITE_BIT(command) (0x7F & command)

#define BCD_TO_BINARY(v) ((v & 0x0F) + ((v & 0x10)*10) + ((v & 0x20)*20) + ((v & 0x40)*40))

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

typedef enum {
  SUNDAY    = 1,
  MONDAY    = 2,
  TUESDAY   = 3,
  WEDNESDAY = 4,
  THURSDAY  = 5,
  FRIDAY    = 6,
  SATURDAY  = 7
} day_e;

typedef enum {
  RV3049_STATE_READ_TIME,
  RV3049_STATE_READ_TIME_DONE,
  RV3049_STATE_SET_TIME,
  RV3049_STATE_SET_TIME_DONE,
  RV3049_STATE_DONE
} rv3049_state_e;

#endif