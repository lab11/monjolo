/*
 * Monjolo over BLE
 */

// Global libraries
#include <stdint.h>

// Nordic libraries
#include "ble_advdata.h"
#include "nrf_drv_spi.h"
#include "nrf_gpio.h"
#include "nrf_delay.h"
#include "nrf_drv_adc.h"
#include "app_util_platform.h"

// nrf5x-base libraries
#include "simple_ble.h"
#include "eddystone.h"

// FRAM
#include "fm25l04b.h"
// LEDs
#include "led.h"

/******************************************************************************/
// BLE
/******************************************************************************/

// Define constants about this beacon.
#define DEVICE_NAME "ligeiro"
#define PHYSWEB_URL "j2x.us/ligeir"

// Manufacturer specific data setup
#define UMICH_COMPANY_IDENTIFIER 0x02E0
#define UMICH_MANDATA_SERVICE_MONJOLO 0x18

// Monjolo Version
// 0: unused
// 1: coilcube rev a, rev b, rev c
// 2: sEHnsor
// 3: impulse rev a, rev b
// 4: coilcube/splitcore with impulse
// 5: gecko power supply + impulse
// 6: gecko power supply + impulse + buzz
// 7: hot spring + impulse

typedef struct {
    uint8_t service;
    uint8_t version;
    uint8_t monjolo_version;
    uint32_t counter;
    uint32_t seq_no;
} __attribute__((packed)) monjolo_mandata_t;

static monjolo_mandata_t monjolo_mandata = {
    UMICH_MANDATA_SERVICE_MONJOLO,
    1, // Version 1 of this packet structure
    5, // Gecko power supply
    0,
    0
};

static ble_advdata_manuf_data_t mandata = {
    UMICH_COMPANY_IDENTIFIER,
    {
        sizeof(monjolo_mandata_t),
        (uint8_t*) &monjolo_mandata
    }
};

// Intervals for advertising and connections
static simple_ble_config_t ble_config = {
    .platform_id       = 0xd0,              // used as 4th octect in device BLE address
    .device_id         = DEVICE_ID_DEFAULT,
    .adv_name          = DEVICE_NAME,
    .adv_interval      = MSEC_TO_UNITS(30, UNIT_0_625_MS), // fast
    .min_conn_interval = MSEC_TO_UNITS(500, UNIT_1_25_MS),
    .max_conn_interval = MSEC_TO_UNITS(1000, UNIT_1_25_MS)
};


/******************************************************************************/
// FRAM
/******************************************************************************/

#define FM25L04B_nCS 30

static nrf_drv_spi_t _spi = NRF_DRV_SPI_INSTANCE(0);

fm25l04b_t fm25l04b = {
    .spi      = &_spi,
    .sck_pin  = SPI0_CONFIG_SCK_PIN,
    .mosi_pin = SPI0_CONFIG_MOSI_PIN,
    .miso_pin = SPI0_CONFIG_MISO_PIN,
    .ss_pin   = FM25L04B_nCS
};

/******************************************************************************/
// ADC
/******************************************************************************/

static nrf_drv_adc_config_t _adc_config = NRF_DRV_ADC_DEFAULT_CONFIG;
static nrf_drv_adc_channel_t _adc_channel_config = NRF_DRV_ADC_DEFAULT_CHANNEL(NRF_ADC_CONFIG_INPUT_7);

#define TIMER_CTL_PIN 7

/******************************************************************************/
// Monjolo
/******************************************************************************/

#define MAGIC_ID 0x63F2BA02

#define FRAM_ADDR_MAGIC   4
#define FRAM_ADDR_COUNTER FRAM_ADDR_MAGIC + 4
#define FRAM_ADDR_SEQ_NO  FRAM_ADDR_COUNTER + 4

typedef struct {
    uint32_t magic;
    uint32_t counter;
    uint32_t seq_no;
} __attribute__((packed)) monjolo_fram_t;

static monjolo_fram_t monjolo_fram;

#define LED_FRONT         14
#define LED_BACK          15



int main (void) {

    // Init LEDs
    led_init(LED_FRONT);
    led_init(LED_BACK);
    led_off(LED_FRONT);
    led_off(LED_BACK);

    // Setup BLE
    simple_ble_init(&ble_config);

    // Start by reading the FRAM
    fm25l04b_read(&fm25l04b, FRAM_ADDR_MAGIC, (uint8_t*) &monjolo_fram, sizeof(monjolo_fram_t));

    // See if this is our first wakeup
    if (monjolo_fram.magic != MAGIC_ID) {
        // If so, write the magic id
        monjolo_fram.magic = MAGIC_ID;
        fm25l04b_write(&fm25l04b, FRAM_ADDR_MAGIC, (uint8_t*) &monjolo_fram, 4);

        // And reset the counter and seq no just in case something happened
        monjolo_fram.counter = 0;
        monjolo_fram.seq_no = 0;
    }

    // Now because we woke up we increment the counter
    monjolo_fram.counter++;

    // Now setup ADC so we can read the timing capacitor
    nrf_adc_value_t timer_val;
    nrf_drv_adc_init(&_adc_config, NULL);

    // Execute a single ADC read.
    // Scale 1/3 because our input reference is 1.2 V.
    _adc_channel_config.config.config.input = NRF_ADC_CONFIG_SCALING_INPUT_ONE_THIRD;
    nrf_drv_adc_sample_convert(&_adc_channel_config, &timer_val);

    // Now check to see if we should suppress transmission or not.
    // Threshold of 400 selected to be about 5 seconds.
    if (timer_val < 400) {

        // Timing cap is low, transmit a packet
        monjolo_fram.seq_no++;

        // Save the current state
        fm25l04b_write(&fm25l04b, FRAM_ADDR_COUNTER, ((uint8_t*) &monjolo_fram)+4, 8);

        // Update outgoing packet
        monjolo_mandata.counter = monjolo_fram.counter;
        monjolo_mandata.seq_no = monjolo_fram.seq_no;

        // EddyStone + Device Name
        eddystone_with_manuf_adv(PHYSWEB_URL, &mandata);

        // Reset timing cap
        nrf_gpio_cfg_output(TIMER_CTL_PIN);
        nrf_gpio_pin_set(TIMER_CTL_PIN);

        // Blip LEDs
        led_on(LED_FRONT);
        led_on(LED_BACK);
        nrf_delay_ms(100);
        led_off(LED_FRONT);
        led_off(LED_BACK);

    } else {
        // Save the counter
        fm25l04b_write(&fm25l04b, FRAM_ADDR_COUNTER, ((uint8_t*) &monjolo_fram)+4, 4);

        // Waste energy on an LED
        led_on(LED_FRONT);
        led_on(LED_BACK);
    }

    while (1) {
        power_manage();
    }
}
