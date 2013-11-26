/*
 * File to allow customizing which pin the Timing Cap is connected to.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

#include "Msp430Adc12.h"

module HplVTimerP {
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t*> as VTimerAdcConfig;
  }
}

implementation {

  msp430adc12_channel_config_t config = {
    inch:         INPUT_CHANNEL_A0,
    sref:         REFERENCE_AVcc_AVss,
    ref2_5v:      REFVOLT_LEVEL_NONE,
    adc12ssel:    SHT_SOURCE_ACLK,
    adc12div:     SHT_CLOCK_DIV_1,
    sht:          SAMPLE_HOLD_16_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_ACLK,
    sampcon_id:   SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* VTimerAdcConfig.getConfiguration () {
    return &config;
  }
}
