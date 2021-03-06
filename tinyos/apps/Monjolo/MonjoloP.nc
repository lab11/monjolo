#include "Timer.h"
#include "Msp430Adc12.h"
#include "monjolo.h"
#include "monjolo_platform.h"
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

/* Monjolo application with IPv6/6LoWPAN
 *
 * @author Sam DeBruin <sdebruin@umich.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

module MonjoloP {
	uses {
		interface Leds;
    interface Boot;

    interface SplitControl as BlipControl;
    interface UDP as Udp;
    interface ForwardingTable;
    interface SeqNoControl;

    interface Fm25lb as Fram;

    interface HplMsp430GeneralIO as FlagGPIO;

    interface Resource as AdcResource;
    interface AdcConfigure<const msp430adc12_channel_config_t*> as VTimerAdcConfig;
    interface Msp430Adc12SingleChannel as VTimerRead;

    interface HplMsp430GeneralIO as TimeControlGPIO;
  }
}
implementation {

  struct sockaddr_in6 dest; // Where to send the packet
  struct in6_addr next_hop; // for default route setup

  pkt_data_t pkt_data = {PROFILE_ID, MONJOLO_VERSION, 0, 0};

  uint16_t timing_cap_val;

  fram_data_t fram_data;
  cc_state_e state;

  event void Boot.booted() {
    // Get binary version of the ip address to send the packets to
    inet_pton6(RECEIVER_ADDR, &dest.sin6_addr);
    dest.sin6_port = htons(RECEIVER_PORT);

    // Setup a default broadcast route for that destination
    inet_pton6(ADDR_ALL_ROUTERS, &next_hop);
    call ForwardingTable.addRoute(dest.sin6_addr.s6_addr, 128, &next_hop,
      ROUTE_IFACE_154);

    state = STATE_INITIAL_READ;
    call BlipControl.start();
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

  task void state_machine () {
    switch (state) {
      case STATE_INITIAL_READ:
        // Read in the status from the FRAM
        state = STATE_INITIAL_READ_DONE;
        call Fram.read(FRAM_ADDR_COUNT, (uint8_t*) &fram_data, sizeof(fram_data_t));
        break;

      case STATE_INITIAL_READ_DONE:
        // Just got the id and whatnot from FRAM
        // Now since this is a wakeup increment the counter
        fram_data.counter++;
        // And check if we should send a packet too
        state = STATE_CHECK_PKT_DELAY;
        call AdcResource.request();
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
