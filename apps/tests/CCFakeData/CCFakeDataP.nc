#include "Timer.h"
#include "message.h"
#include "Ieee154.h"
#include "ieee154_header.h"

#define PANID 0x0022
#define COUNT_ADDR 0
#define SEQ_ADDR 1

module CCFakeDataP {
	uses {
		interface Leds;
    interface Boot;

    interface Timer<TMilli> as Timer0;

    interface SplitControl as RadioControl;
    interface Packet as RadioPacket;
    interface Send as RadioSend;
    interface Receive as RadioReceive;

    interface LocalIeeeEui64;
  }
}
implementation {

  message_t msg;
  struct ieee154_frame_addr out_frame;
  struct ieee154_frame_addr ack_frame;
  uint8_t* payload_buf = (uint8_t*) &msg;

  uint8_t counter;
  uint8_t sequence;
  uint8_t i;
  bool m_busy = TRUE;

  bool m_init;

  uint8_t m_addr;
  uint8_t m_buf[50];
  uint8_t m_len = 1;

  ieee_eui64_t id;

  void sendMsg();

  event void Boot.booted() {
    counter = 0;
    i = 0;
    m_init = FALSE;
    id = call LocalIeeeEui64.getId();

    call RadioControl.start();
  }

  void sendMsg(){
    error_t  error;
    uint8_t* payload_data;

    call RadioPacket.clear(&msg);

    // setup outgoing frame
    out_frame.ieee_dstpan = PANID;
    memcpy(&out_frame.ieee_src.i_laddr, id.data, 8);
    out_frame.ieee_src.ieee_mode = IEEE154_ADDR_EXT;

    out_frame.ieee_dst.i_saddr = IEEE154_BROADCAST_ADDR;
    out_frame.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;

    // put header in payload
    payload_data = pack_ieee154_header(payload_buf, 22, &out_frame);

    // add seq no
    payload_buf[3] = sequence;

    // set length
    // length is always tricky because of what gets counted. Here we must count
    // the two crc bytes but not the length byte.
    payload_buf[0] = (payload_data - payload_buf + 1) + sizeof(counter);

    // Set the payload as just the counter for now.
    payload_data[0] = counter;

    // send the packet
    error = call RadioSend.send(&msg, payload_buf[0]);
  }

  event void RadioControl.startDone (error_t error) {
    call Timer0.startPeriodic(1000);
  }

  event void Timer0.fired(){
    // Simulate coilcube wakeups
    sequence++;
    counter++;
    sendMsg();
  }

  event void RadioSend.sendDone (message_t* message, error_t error) {
  }

  event message_t* RadioReceive.receive(message_t* packet,
                                        void* payload, uint8_t len) {
    return packet;
  }

  event void RadioControl.stopDone (error_t error) { }

}
