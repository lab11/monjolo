#include "Timer.h"

#include "Ieee154.h"
#include "ieee154_header.h"

#define CC_LOAD_PANID 0x0022

module LoadCalibrateCCP {
	uses {
		interface Leds;
    interface Boot;

    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
    interface Timer<TMilli> as WattageUpdateTimer;
    interface Timer<TMilli> as LoadIncrementTimer;

    interface HplMsp430GeneralIO as Control1;
    interface HplMsp430GeneralIO as Control2;
    interface HplMsp430GeneralIO as Control3;
    interface HplMsp430GeneralIO as Control4;
    interface HplMsp430GeneralIO as Control5;
    interface HplMsp430GeneralIO as Control6;
    interface HplMsp430GeneralIO as Control7;
    interface HplMsp430GeneralIO as Control8;
    interface HplMsp430GeneralIO as Control9;

    interface HplMsp430Interrupt as ButUp;
    interface HplMsp430GeneralIO as UpGPIO;
    interface HplMsp430Interrupt as ButDown;
    interface HplMsp430GeneralIO as DownGPIO;

    interface HplMsp430GeneralIO as FanPin;

    interface BusyWait<TMicro, uint16_t>;

    interface SplitControl as RadioControl;
    interface Packet;
    interface Send;
    interface Receive;
	}
}
implementation {

  uint16_t load_value;

  void set_load(uint16_t value);
  void increment();
  void decrement();
  void set_relays(uint16_t value);

  message_t msg;
  struct ieee154_frame_addr out_frame;
  struct ieee154_frame_addr ack_frame;
  uint8_t* payload_buf = (uint8_t*) &msg;

  uint8_t seq_no = 8;

  uint16_t temp_value;

  #define LOAD_INCREMENT_INTERVAL 60000
  #define LOAD_REPORT_INTERVAL 10000

	event void Boot.booted() {
    load_value = 0;

    call Control1.makeOutput();
    call Control2.makeOutput();
    call Control3.makeOutput();
    call Control4.makeOutput();
    call Control5.makeOutput();
    call Control6.makeOutput();
    call Control7.makeOutput();
    call Control8.makeOutput();
    call Control9.makeOutput();

    call UpGPIO.selectIOFunc();
    call UpGPIO.makeInput();
    call ButUp.edge(FALSE);
    call ButUp.enable();
    call DownGPIO.selectIOFunc();
    call DownGPIO.makeInput();
    call ButDown.edge(FALSE);
    call ButDown.enable();

    set_load(0);

    call Leds.set(0x7);

    call RadioControl.start();
  }

  event void RadioControl.startDone (error_t error) {
    //call WattageUpdateTimer.startPeriodic(LOAD_REPORT_INTERVAL);
    call LoadIncrementTimer.startPeriodic(LOAD_INCREMENT_INTERVAL);
  }

  void sendMsg(){
    error_t  error;
    uint8_t* payload_data;

    call Packet.clear(&msg);

    // setup outgoing frame
    out_frame.ieee_dstpan = CC_LOAD_PANID;
    out_frame.ieee_src.i_saddr = TOS_NODE_ID;
    out_frame.ieee_src.ieee_mode = IEEE154_ADDR_SHORT;

    out_frame.ieee_dst.i_saddr = IEEE154_BROADCAST_ADDR;
    out_frame.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;

    // put header in payload
    payload_data = pack_ieee154_header(payload_buf, 22, &out_frame);

    // add seq no
    payload_buf[3] = seq_no++;

    // set length
    // length is always tricky because of what gets counted. Here we must count
    // the two crc bytes but not the length byte.
    payload_buf[0] = (payload_data - payload_buf + 1) +
                     sizeof(uint16_t);

    // Put the load value in the data packet
    payload_data[0] = (load_value >> 8);
    payload_data[1] = (load_value & 0xff);

    // send the packet
    error = call Send.send(&msg, payload_buf[0]);
  }

  event void WattageUpdateTimer.fired () {
    //call Leds.led2Toggle();
    //sendMsg();
  }

  event void LoadIncrementTimer.fired () {
    call Leds.led0Toggle();
    increment();
  }

  event void Timer1.fired() {
    if(call UpGPIO.get() == FALSE) {
      increment();
      call Timer2.startOneShot(50);
    }
    else if(call DownGPIO.get() == FALSE) {
      decrement();
      call Timer2.startOneShot(50);
    }
    else {
      call ButUp.enable();
      call ButDown.enable();
    }
  }

  event void Timer2.fired() {
    if(call UpGPIO.get() == FALSE) {
      increment();
      call Timer2.startOneShot(50);
    }
    else if(call DownGPIO.get() == FALSE) {
      decrement();
      call Timer2.startOneShot(50);
    }
    else {
      call ButUp.enable();
      call ButDown.enable();
    }
  }

  async event void ButUp.fired() {
    call ButUp.clear();

    call ButUp.disable();
    call ButDown.disable();

    increment();

    call Timer1.startOneShot(1000);
  }

  async event void ButDown.fired() {
    call ButDown.clear();

    call ButUp.disable();
    call ButDown.disable();

    decrement();

    call Timer1.startOneShot(1000);
  }

  event message_t* Receive.receive(message_t* m, void* payload, uint8_t len) {
    uint8_t val1, val2;
    uint8_t* p;
    uint16_t new_value;

    call Leds.led0Toggle();
    call Leds.led1Toggle();
    call Leds.led2Toggle();

    p = (uint8_t*) payload;

    val1 = p[10];
    val2 = p[11];
/*
    new_value = (val1 << 8) | val2;

    if (new_value == 0xFFFF) {
      // auto increment
      increment();
    } else {
      set_load(new_value);
    }
*/
    return m;
  }


/*****************
 * RELAY CONTROL *
 *****************/

  void set_load (uint16_t value) {
    load_value = value;
    set_relays(value);
  }

  void increment () {
    load_value++;
    if (load_value > 0x1FF) {
      load_value = 0x1FF;
    }

    set_relays(load_value);
  }

  void decrement () {
    if (load_value > 0) {
      load_value--;
    }

    set_relays(load_value);
  }

  void set_relays (uint16_t value) {
    if (value & 0x01) call Control9.set();
    else call Control9.clr();

    if (value & 0x02) call Control8.set();
    else call Control8.clr();

    if (value & 0x04) call Control7.set();
    else call Control7.clr();

    if (value & 0x08) call Control6.set();
    else call Control6.clr();

    if (value & 0x10) call Control5.set();
    else call Control5.clr();

    if (value & 0x20) call Control4.set();
    else call Control4.clr();

    if (value & 0x40) call Control3.set();
    else call Control3.clr();

    if (value & 0x80) call Control2.set();
    else call Control2.clr();

    if (value & 0x100) call Control1.set();
    else call Control1.clr();
  }

  event void RadioControl.stopDone(error_t error) {}
  event void Send.sendDone(message_t* m, error_t error) {}

}
