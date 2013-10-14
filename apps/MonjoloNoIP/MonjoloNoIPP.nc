#include "Timer.h"
#include "Msp430Adc12.h"
#include "monjolo.h"
#include "monjolo_platform.h"
#include "message.h"
#include "Ieee154.h"
#include "ieee154_header.h"

module MonjoloNoIPP {
	uses {
		interface Leds;
    interface Boot;

    interface SplitControl as RadioControl;
    interface Packet as RadioPacket;
    interface Send as RadioSend;
    interface Receive as RadioReceive;

    interface Fm25lb as Fram;

    interface HplMsp430GeneralIO as FlagGPIO;

    interface Resource as AdcResource;
    interface AdcConfigure<const msp430adc12_channel_config_t*> as VTimerAdcConfig;
    interface Msp430Adc12SingleChannel as VTimerRead;

    interface HplMsp430GeneralIO as TimeControlGPIO;
  }
}
implementation {

  message_t msg;
  struct ieee154_frame_addr out_frame;
  struct ieee154_frame_addr ack_frame;
  uint8_t* payload_buf = (uint8_t*) &msg;
  pkt_data_t pkt_data;

  uint16_t timing_cap_val;

  fram_data_t fram_data;
  cc_state_e state;

  event void Boot.booted() {
  //  call FlagGPIO.makeOutput();

    pkt_data.version = MONJOLO_VERSION;

    state = STATE_INITIAL_READ;
    call RadioControl.start();
  }

  void sendMsg () {
    error_t  error;
    uint8_t* data;

    call RadioPacket.clear(&msg);

    // setup outgoing frame
    out_frame.ieee_dstpan        = PAN_ID;
    memcpy(&out_frame.ieee_src.i_laddr, fram_data.id.data, 8);
    out_frame.ieee_src.ieee_mode = IEEE154_ADDR_EXT;
    out_frame.ieee_dst.i_saddr   = IEEE154_BROADCAST_ADDR;
    out_frame.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;

    // put header in payload
    data = pack_ieee154_header(payload_buf, 22, &out_frame);

    // add seq no
    payload_buf[3] = fram_data.seq_no;

    // set length
    // length is always tricky because of what gets counted. Here we must count
    // the two crc bytes but not the length byte.
    payload_buf[0] = (data - payload_buf + 1) + sizeof(pkt_data_t);

    // Set the payload as the pkt data
    pkt_data.counter = fram_data.counter;
    memcpy(data, &pkt_data, sizeof(pkt_data_t));

    // send the packet
    error = call RadioSend.send(&msg, payload_buf[0]);
  }

  task void state_machine () {
    switch (state) {
      case STATE_INITIAL_READ:
        // Read in the status from the FRAM
        state = STATE_INITIAL_READ_DONE;
        call Fram.read(ADDR_ID, (uint8_t*) &fram_data, sizeof(fram_data_t));
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

        if ((timing_cap_val_local >> 8) <= 2) {
          // The capacitor is low enough to send a packet
          // Update the sequence number and store it and the count value
          state = STATE_SEND_PACKET;
          fram_data.seq_no++;
          call Fram.write(ADDR_COUNT, &fram_data.counter, 2);

        } else {
          // Just store the counter value and be done
          state = STATE_DONE;
          call Fram.write(ADDR_COUNT, &fram_data.counter, 1);
        }
        break;
      }

      case STATE_SEND_PACKET:
        state = STATE_SEND_PACKET_DONE;
        // Recharge the timing capacitor
        call TimeControlGPIO.makeOutput();
        call TimeControlGPIO.set();
        sendMsg();
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

  event void RadioControl.startDone (error_t error) {
    //call FlagGPIO.set();

    post state_machine();
  }

  event void Fram.readDone(fm25lb_addr_t addr,
                           uint8_t* buf,
                           fm25lb_len_t len,
                           error_t err) {
    post state_machine();
  }

  event void Fram.writeDone(fm25lb_addr_t addr,
                            uint8_t* buf,
                            fm25lb_len_t len,
                            error_t err) {
    post state_machine();
  }

  event void AdcResource.granted () {
    // Go ahead and sample the timing capacitor
    post state_machine();
  }

  async event error_t VTimerRead.singleDataReady (uint16_t data) {
  //  call FlagGPIO.clr();
    timing_cap_val = data;
    post state_machine();
    return SUCCESS;
  }

  event void Fram.writeEnableDone() {
    post state_machine();
  }

  event void Fram.readStatusDone(uint8_t* buf, error_t err) {
    post state_machine();
  }

  event void Fram.writeStatusDone(uint8_t* buf, error_t err) {
    post state_machine();
  }

  event void RadioSend.sendDone (message_t* message, error_t error) {
    post state_machine();
  }

  event message_t* RadioReceive.receive(message_t* packet,
                                        void* payload, uint8_t len) {
    return packet;
  }

  event void RadioControl.stopDone (error_t error) {
    post state_machine();
  }

  async event uint16_t* COUNT_NOK(numSamples)
  VTimerRead.multipleDataReady(uint16_t *COUNT(numSamples) buffer,
    uint16_t numSamples) {
    return NULL;
  }
}
