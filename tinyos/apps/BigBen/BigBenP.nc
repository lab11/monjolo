#include "Timer.h"
#include "monjolo.h"

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

  fram_data_t fram_data;
  bb_state_e state;

  event void Boot.booted() {
    state = STATE_INITIAL_READ;
    post state_machine();
  }

  void sendMsg () {
    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    // Set the payload as the pkt data
    pkt_data.counter = fram_data.counter;
    pkt_data.seq_no = fram_data.seq_no;

    call Udp.sendto(&dest, &pkt_data, sizeof(pkt_data_t));
    // Not much we can do if this returns an error
  }

  void read_scratch_fram () {
    call FramScratch.read(FRAM_ADDR_START,
                          (uint8_t*) &fram_data,
                          sizeof(fram_data_t));
  }

  task void state_machine () {
    switch (state) {
      case STATE_INITIAL_READ:
        // Read in the status from the FRAM
        state = STATE_INITIAL_READ_DONE;
        read_scratch_fram();
        break;

      case STATE_INITIAL_READ_DONE:
        if (fram_data.version_hash == IDENT_UIDHASH) {
          // FRAM hash matches, data is valid
        } else {
          state = STATE_DONE;
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

      case STATE_CHECK_PKT_DELAY:
        // Now have access to the adc
        // Sample the timing capacitor
        state = STATE_CHECK_PKT_DELAY_DONE;
        call VTimerRead.configureSingle(call VTimerAdcConfig.getConfiguration());
        call VTimerRead.getData();
        break;

      case STATE_CHECK_PKT_DELAY_DONE: {
        // Got the ADC sample back
        uint16_t timing_cap_val_local;
        atomic timing_cap_val_local = timing_cap_val;

        call AdcResource.release();

        //if (1) {
        if ((timing_cap_val_local >> 8) <= 2) {
          // The capacitor is low enough to send a packet
          // Update the sequence number and store it and the count value
          state = STATE_SEND_PACKET;
          fram_data.seq_no++;
          call Fram.write(FRAM_ADDR_COUNT, &fram_data.counter, 2);

        } else {
          // Just store the counter value and be done
          state = STATE_DONE;
          call Fram.write(FRAM_ADDR_COUNT, &fram_data.counter, 1);
        }
        break;
      }

      case STATE_SEND_PACKET:
        state = STATE_SEND_PACKET_DONE;
        // Recharge the timing capacitor
        call TimeControlGPIO.makeOutput();
        call TimeControlGPIO.set();
        sendMsg();
        call TimeControlGPIO.clr();
        call Leds.led0On();
        break;

      case STATE_SEND_PACKET_DONE:
        state = STATE_DONE;
        // Stop recharing the timing capacitor
        call TimeControlGPIO.clr();
        break;

      case STATE_DONE:
        break;

      default:
        break;

    }

  }

  event void BlipControl.startDone (error_t error) {
    post state_machine();
  }

  event void Fram.readDone(uint16_t addr,
                           uint8_t* buf,
                           uint16_t len,
                           error_t err) {
    post state_machine();
  }

  event void Fram.writeDone(uint16_t addr,
                            uint8_t* buf,
                            uint16_t len,
                            error_t err) {
    post state_machine();
  }

  event void AdcResource.granted () {
    // Go ahead and sample the timing capacitor
    post state_machine();
  }

  async event error_t VTimerRead.singleDataReady (uint16_t data) {
    timing_cap_val = data;
    post state_machine();
    return SUCCESS;
  }

  event void Fram.readStatusDone (uint8_t status, error_t err) {
    post state_machine();
  }

  event void Fram.writeStatusDone(error_t err) {
    post state_machine();
  }

  event void BlipControl.stopDone (error_t error) {
    post state_machine();
  }

  async event uint16_t* COUNT_NOK(numSamples)
  VTimerRead.multipleDataReady(uint16_t *COUNT(numSamples) buffer,
    uint16_t numSamples) {
    return NULL;
  }

  event void Udp.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) { }
}
