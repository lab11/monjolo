/* Wake to an advertising packet, Monjolo style.
 */

#include <stdbool.h>
#include <stdint.h>
#include "nrf_gpio.h"
#include "ble_advdata.h"
// #include "boards.h"
#include "nordic_common.h"
#include "softdevice_handler.h"
#include "ble_debug_assert_handler.h"
#include "app_timer.h"

#define DEVICE_NAME                      "monjolo"

#define LED0          18
#define LED1          19
#define LED2          20

#define IS_SRVC_CHANGED_CHARACT_PRESENT  0                                 /**< Include or not the service_changed characteristic. if not enabled, the server's database cannot be changed for the lifetime of the device*/
#define ADVERTISING_LED_PIN_NO           LED0                             /**< Is on when device is advertising. */
#define ASSERT_LED_PIN_NO                LED1                            /**< Is on when application has asserted. */

#define USE_LEDS                         1

// Set advertisement interval and whatnot. This doesn't really matter for
// monjolo style apps.

// THIS MUST NOT BE 0 IF YOU WANT TO SET A NAME IN THE ADVERTISEMENT
#define APP_CFG_NON_CONN_ADV_TIMEOUT    180                                 /**< Time for which the device must be advertising in non-connectable mode (in seconds). 0 disables timeout. */
#define NON_CONNECTABLE_ADV_INTERVAL    MSEC_TO_UNITS(100, UNIT_0_625_MS)   /**< The advertising interval for non-connectable advertisement (100 ms). This value can vary between 100ms to 10.24s). */


// Some constants about timers
#define APP_TIMER_PRESCALER              0                                  /**< Value of the RTC1 PRESCALER register. */
#define APP_TIMER_MAX_TIMERS             4                                  /**< Maximum number of simultaneously created timers. */
#define APP_TIMER_OP_QUEUE_SIZE          4                                  /**< Size of timer operation queues. */

// How long before the timer fires.
#define WAIT_FOR_ADV_TIMER               APP_TIMER_TICKS(50, APP_TIMER_PRESCALER) /**< Battery level measurement interval (ticks). */



// Some manufacturing specific stuff that we don't use right now

#define APP_BEACON_INFO_LENGTH          0x17                              /**< Total length of information advertised by the Beacon. */
#define APP_ADV_DATA_LENGTH             0x15                              /**< Length of manufacturer specific data in the advertisement. */
#define APP_DEVICE_TYPE                 0x02                              /**< 0x02 refers to Beacon. */
#define APP_MEASURED_RSSI               0xC3                              /**< The Beacon's measured RSSI at 1 meter distance in dBm. */
#define APP_COMPANY_IDENTIFIER          0x0033                            /**< Company identifier for Nordic Semiconductor ASA. as per www.bluetooth.org. */
#define APP_MAJOR_VALUE                 0x01, 0x02                        /**< Major value used to identify Beacons. */
#define APP_MINOR_VALUE                 0x03, 0x04                        /**< Minor value used to identify Beacons. */
#define APP_BEACON_UUID                 0xff, 0xaa, 0xbb, 0x34, \
                                        0x45, 0x56, 0x67, 0x78, \
                                        0x89, 0x9a, 0xab, 0xbc, \
                                        0xcd, 0xde, 0xef, 0xf0            /**< Proprietary UUID for Beacon. */

#if defined(USE_UICR_FOR_MAJ_MIN_VALUES)
#define MAJ_VAL_OFFSET_IN_BEACON_INFO   18                                /**< Position of the MSB of the Major Value in m_beacon_info array. */
#define UICR_ADDRESS                    0x10001080                        /**< Address of the UICR register used by this example. The major and minor versions to be encoded into the advertising data will be picked up from this location. */
#endif


#define DEAD_BEEF                       0xDEADBEEF                        /**< Value used as error code on stack dump, can be used to identify stack location on stack unwind. */

// information about the advertisement
ble_advdata_t                           advdata;
static ble_gap_adv_params_t m_adv_params;                               /**< Parameters to be passed to the stack when starting advertising. */

// Timer data structure
static app_timer_id_t                   m_avd_timer_id;                        /**< Battery timer. */

// more manufacturer specific stuff
static uint8_t m_beacon_info[APP_BEACON_INFO_LENGTH] =                  /**< Information advertised by the Beacon. */
{
    APP_DEVICE_TYPE,     // Manufacturer specific information. Specifies the device type in this
                         // implementation.
    APP_ADV_DATA_LENGTH, // Manufacturer specific information. Specifies the length of the
                         // manufacturer specific data in this implementation.
    APP_BEACON_UUID,     // 128 bit UUID value.
    APP_MAJOR_VALUE,     // Major arbitrary value that can be used to distinguish between Beacons.
    APP_MINOR_VALUE,     // Minor arbitrary value that can be used to distinguish between Beacons.
    APP_MEASURED_RSSI    // Manufacturer specific information. The Beacon's measured TX power in
                         // this implementation.
};


/**@brief Function for error handling, which is called when an error has occurred.
 *
 * @warning This handler is an example only and does not fit a final product. You need to analyze
 *          how your product is supposed to react in case of error.
 *
 * @param[in] error_code  Error code supplied to the handler.
 * @param[in] line_num    Line number where the handler is called.
 * @param[in] p_file_name Pointer to the file name.
 */
void app_error_handler(uint32_t error_code, uint32_t line_num, const uint8_t * p_file_name)
{
#if USE_LEDS
    nrf_gpio_pin_set(ASSERT_LED_PIN_NO);
#endif

    // This call can be used for debug purposes during application development.
    // @note CAUTION: Activating this code will write the stack to flash on an error.
    //                This function should NOT be used in a final product.
    //                It is intended STRICTLY for development/debugging purposes.
    //                The flash write will happen EVEN if the radio is active, thus interrupting
    //                any communication.
    //                Use with care. Un-comment the line below to use.
    // ble_debug_assert_handler(error_code, line_num, p_file_name);

    // On assert, the system can only recover on reset.
    NVIC_SystemReset();
}


/**@brief Callback function for asserts in the SoftDevice.
 *
 * @details This function will be called in case of an assert in the SoftDevice.
 *
 * @warning This handler is an example only and does not fit a final product. You need to analyze
 *          how your product is supposed to react in case of Assert.
 * @warning On assert from the SoftDevice, the system can only recover on reset.
 *
 * @param[in]   line_num   Line number of the failing ASSERT call.
 * @param[in]   file_name  File name of the failing ASSERT call.
 */
void assert_nrf_callback(uint16_t line_num, const uint8_t * p_file_name)
{
    app_error_handler(DEAD_BEEF, line_num, p_file_name);
}


/**@brief Function for the LEDs initialization.
 *
 * @details Initializes all LEDs used by this application.
 */
static void leds_init(void)
{
    nrf_gpio_cfg_output(ADVERTISING_LED_PIN_NO);
    nrf_gpio_cfg_output(ASSERT_LED_PIN_NO);
    nrf_gpio_cfg_output(LED2);

    nrf_gpio_pin_set(LED0);
    nrf_gpio_pin_set(LED1);
    nrf_gpio_pin_set(LED2);
}


static void gap_params_init(void)
{
    uint32_t                err_code;
    ble_gap_conn_sec_mode_t sec_mode;


    // Set the power. Using really low (-30) doesn't really work
    sd_ble_gap_tx_power_set(4);

    // Configure something about the gap
    // Make the connection open cause yea
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&sec_mode);

    // Set the name of the device so its easier to find
    err_code = sd_ble_gap_device_name_set(&sec_mode,
                                          (const uint8_t *)DEVICE_NAME,
                                          strlen(DEVICE_NAME));
    APP_ERROR_CHECK(err_code);

    // Set an appearance; we don't use this
    //err_code = sd_ble_gap_appearance_set(BLE_APPEARANCE_GENERIC_WATCH);
    //APP_ERROR_CHECK(err_code);

    // memset(&gap_conn_params, 0, sizeof(gap_conn_params));

    // gap_conn_params.min_conn_interval = MIN_CONN_INTERVAL;
    // gap_conn_params.max_conn_interval = MAX_CONN_INTERVAL;
    // gap_conn_params.slave_latency     = SLAVE_LATENCY;
    // gap_conn_params.conn_sup_timeout  = CONN_SUP_TIMEOUT;

    // err_code = sd_ble_gap_ppcp_set(&gap_conn_params);
    // APP_ERROR_CHECK(err_code);
}



/**@brief Function for initializing the Advertising functionality.
 *
 * @details Encodes the required advertising data and passes it to the stack.
 *          Also builds a structure to be passed to the stack when starting advertising.
 */
static void advertising_init(void)
{
    uint32_t        err_code;

    // Use the simplest send adv packets only mode
    // uint8_t         flags = BLE_GAP_ADV_FLAG_BR_EDR_NOT_SUPPORTED;


    // More manufacturing only stuff that might get added back in
    ble_advdata_manuf_data_t manuf_specific_data;
    manuf_specific_data.company_identifier = APP_COMPANY_IDENTIFIER;

#if defined(USE_UICR_FOR_MAJ_MIN_VALUES)
    // If USE_UICR_FOR_MAJ_MIN_VALUES is defined, the major and minor values will be read from the
    // UICR instead of using the default values. The major and minor values obtained from the UICR
    // are encoded into advertising data in big endian order (MSB First).
    // To set the UICR used by this example to a desired value, write to the address 0x10001080
    // using the nrfjprog tool. The command to be used is as follows.
    // nrfjprog --snr <Segger-chip-Serial-Number> --memwr 0x10001080 --val <your major/minor value>
    // For example, for a major value and minor value of 0xabcd and 0x0102 respectively, the
    // the following command should be used.
    // nrfjprog --snr <Segger-chip-Serial-Number> --memwr 0x10001080 --val 0xabcd0102
    uint16_t major_value = ((*(uint32_t *)UICR_ADDRESS) & 0xFFFF0000) >> 16;
    uint16_t minor_value = ((*(uint32_t *)UICR_ADDRESS) & 0x0000FFFF);

    uint8_t index = MAJ_VAL_OFFSET_IN_BEACON_INFO;

    m_beacon_info[index++] = MSB(major_value);
    m_beacon_info[index++] = LSB(major_value);

    m_beacon_info[index++] = MSB(minor_value);
    m_beacon_info[index++] = LSB(minor_value);
#endif

    manuf_specific_data.data.p_data        = (uint8_t *) m_beacon_info;
    manuf_specific_data.data.size          = APP_BEACON_INFO_LENGTH;

    // Build and set advertising data.
    memset(&advdata, 0, sizeof(advdata));

    advdata.name_type               = BLE_ADVDATA_FULL_NAME;
    advdata.include_appearance      = false;
    // advdata.flags              = BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE;
    advdata.flags              = BLE_GAP_ADV_FLAG_BR_EDR_NOT_SUPPORTED;
    // advdata.flags.size              = sizeof(flags);
    // advdata.flags.p_data            = &flags;
    //advdata.p_manuf_specific_data   = &manuf_specific_data;

    err_code = ble_advdata_set(&advdata, NULL);
    APP_ERROR_CHECK(err_code);

    // Initialize advertising parameters (used when starting advertising).
    memset(&m_adv_params, 0, sizeof(m_adv_params));

    m_adv_params.type        = BLE_GAP_ADV_TYPE_ADV_NONCONN_IND;
    //m_adv_params.type      = BLE_GAP_ADV_TYPE_ADV_IND;
    m_adv_params.p_peer_addr = NULL;                             // Undirected advertisement.
    m_adv_params.fp          = BLE_GAP_ADV_FP_ANY;
    m_adv_params.interval    = NON_CONNECTABLE_ADV_INTERVAL;
    m_adv_params.timeout     = APP_CFG_NON_CONN_ADV_TIMEOUT;
}


/**@brief Function for starting advertising.
 */
static void advertising_start(void)
{
    uint32_t err_code;

    err_code = sd_ble_gap_adv_start(&m_adv_params);
    APP_ERROR_CHECK(err_code);

#if USE_LEDS
    nrf_gpio_pin_set(ADVERTISING_LED_PIN_NO);
#endif
}


/**@brief Function for initializing the BLE stack.
 *
 * @details Initializes the SoftDevice and the BLE event interrupt.
 */
static void ble_stack_init(void)
{

    // Initialize the SoftDevice handler module.
    // Use a really crappy clock because we want fast start
    SOFTDEVICE_HANDLER_INIT(NRF_CLOCK_LFCLKSRC_RC_250_PPM_8000MS_CALIBRATION, false);

    // Enable BLE stack
    uint32_t err_code;
    ble_enable_params_t ble_enable_params;
    memset(&ble_enable_params, 0, sizeof(ble_enable_params));
    ble_enable_params.gatts_enable_params.service_changed = IS_SRVC_CHANGED_CHARACT_PRESENT;
    err_code = sd_ble_enable(&ble_enable_params);
    APP_ERROR_CHECK(err_code);
}

// Timer callback
static void adv_wait_handler (void * p_context)
{
    sd_ble_gap_adv_stop();
}

// Setup timers
static void timers_init(void)
{
    uint32_t err_code;

    // Initialize timer module.
    APP_TIMER_INIT(APP_TIMER_PRESCALER,  APP_TIMER_OP_QUEUE_SIZE, false);

    // Create timers.
    err_code = app_timer_create(&m_avd_timer_id,
                                APP_TIMER_MODE_SINGLE_SHOT,
                                adv_wait_handler);
    APP_ERROR_CHECK(err_code);
}

// Start a one-shot timer
static void application_timers_start(void)
{
    uint32_t err_code;
    uint32_t rsc_meas_timer_ticks;

    // Start application timers.
    err_code = app_timer_start(m_avd_timer_id, WAIT_FOR_ADV_TIMER, NULL);
    APP_ERROR_CHECK(err_code);

}

/**@brief Function for doing power management.
 */
static void power_manage(void)
{
    uint32_t err_code = sd_app_evt_wait();
    APP_ERROR_CHECK(err_code);
}


/**
 * @brief Function for application main entry.
 */
int main(void)
{
    // Initialize.
    leds_init();



    timers_init();



    ble_stack_init();


    gap_params_init();



    advertising_init();



    // Start execution.
    advertising_start();



//     application_timers_start();

// nrf_gpio_pin_clear(LED0);
// while (1);

   // sd_ble_gap_adv_stop();

    //advertising_start();
    //sd_ble_gap_adv_stop();

    // Enter main loop.
    for (;;)
    {
        power_manage();
    }
}

