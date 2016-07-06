/*
 * Monjolo over BLE
 */

// Global libraries
#include <stdint.h>

// Nordic libraries
#include "ble_advdata.h"

// nrf5x-base libraries
#include "simple_ble.h"
#include "eddystone.h"
// #include "simple_adv.h"


// Define constants about this beacon.
#define DEVICE_NAME "monjolo"
#define PHYSWEB_URL "goo.gl/bbbCCC"

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
    uint8_t monjolo_version;
    uint32_t counter;
    uint32_t seq_no;
} __attribute__((packed)) monjolo_mandata_t;

static monjolo_mandata_t monjolo_mandata = {
    UMICH_MANDATA_SERVICE_MONJOLO,
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
    .adv_interval      = MSEC_TO_UNITS(20, UNIT_0_625_MS), // fast
    .min_conn_interval = MSEC_TO_UNITS(500, UNIT_1_25_MS),
    .max_conn_interval = MSEC_TO_UNITS(1000, UNIT_1_25_MS)
};

// main is essentially two library calls to setup all of the Nordic SDK
// API calls.
int main(void) {

    // Setup BLE
    simple_ble_init(&ble_config);

    // EddyStone + Device Name
    eddystone_with_manuf_adv(PHYSWEB_URL, &mandata);

    while (1) {
        power_manage();
    }
}
