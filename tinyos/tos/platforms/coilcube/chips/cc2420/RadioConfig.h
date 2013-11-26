/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai, Miklos Maroti
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <Timer.h>
//#include <MicaTimer.h>
#include <CC2420FbDriverLayer.h>

/* This is the default value of the PA_POWER field of the TXCTL register. */
#ifndef CC2420X_DEF_RFPOWER
#define CC2420X_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the FSCTRL register. */
#ifndef CC2420X_DEF_CHANNEL
#define CC2420X_DEF_CHANNEL	11
#endif

/* The number of microseconds a sending micaz mote will wait for an acknowledgement */
#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	24
#endif

/**
 * This is the timer type of the radio alarm interface
 */
typedef T32khz TRadio;
typedef TMicro TRadioAlarm;
typedef uint16_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond (0.9216).
 * We use integers and no parentheses just to make deputy happy.
 * Ok, further hacks were required for deputy, I removed 00 from the
 * beginning and end to be able to handle longer wait periods.
 */
//#define RADIO_ALARM_MICROSEC	(73728UL / MHZ) * (1 << MICA_DIVIDE_THREE_FOR_MICRO_LOG2) / 10000UL
#define RADIO_ALARM_MICROSEC	1

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	2

/**
 * Timing defines that change as the clocks on the platform change
 */
enum cc2420X_timing_enums {
  MICRO_SEC = 8, // 8Mhz clock (TMicro)

  CC2420X_SYMBOL_TIME = 1, // 16us (used with T32Khz)
  //CC2420X_SYMBOL_TIME = 16*MICRO_SEC, // 16us (used with TMicro)

  PD_2_IDLE_TIME = 10, // 0.86ms (used with T32Khz)
  //PD_2_IDLE_TIME = 9000, // ~0.86ms (used with TMicro)

  IDLE_2_RX_ON_TIME = 2 * CC2420X_SYMBOL_TIME,

  STROBE_TO_TX_ON_TIME = 2 * CC2420X_SYMBOL_TIME,
  // TX SFD delay is computed as follows:
  // a.) STROBE_TO_TX_ON_TIME is required for preamble transmission to
  // start after TX strobe is issued
  // b.) the SFD byte is the 5th byte transmitted (10 symbol periods)
  // c.) there's approximately a 25us delay between the strobe and reading
  // the timer register
  TX_SFD_DELAY = STROBE_TO_TX_ON_TIME + 10 * CC2420X_SYMBOL_TIME - 25*MICRO_SEC,
  // TX SFD is captured in hardware
  RX_SFD_DELAY = 0,
};

#endif//__RADIOCONFIG_H__
