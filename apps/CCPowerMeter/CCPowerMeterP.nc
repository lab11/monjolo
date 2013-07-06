#include "Timer.h"
#include "Msp430Adc12.h"
#include "CoilCube.h"
#include "message.h"
#include "Ieee154.h"
#include "ieee154_header.h"

#define PANID 0x0022
#define COUNT_ADDR 0
#define SEQ_ADDR 1

module CCPowerMeterP {
	uses {
		interface Leds;
    interface Boot;

    interface Timer<TMilli> as Timer0;

    interface SplitControl as RadioControl;
    interface Packet as RadioPacket;
    interface Send as RadioSend;
    interface Receive as RadioReceive;

    interface HplMsp430Interrupt as Interrupt;
    interface HplMsp430GeneralIO as InterruptGPIO;
    interface HplMsp430GeneralIO as FlagGPIO;
    interface Fm25lb as Fram;

    interface Msp430Adc12SingleChannel as ReadSingleChannel;
    interface Resource as AdcResource;

    interface HplMsp430GeneralIO as TimeGPIO;
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

  void sendMsg();

  event void Boot.booted() {
    call FlagGPIO.makeOutput();
    //call TimeGPIO.makeInput();
    counter = 0;
    i = 0;
    m_init = FALSE;

    call RadioControl.start();
  }

  void sendMsg(){
    error_t  error;
    uint8_t* payload_data;

    call RadioPacket.clear(&msg);

    call TimeGPIO.makeOutput();
    call TimeGPIO.set();

    // setup outgoing frame
    out_frame.ieee_dstpan = PANID;
    out_frame.ieee_src.i_saddr = TOS_NODE_ID;
    out_frame.ieee_src.ieee_mode = IEEE154_ADDR_SHORT;

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
    call FlagGPIO.set();
    m_addr = COUNT_ADDR;
    call Fram.read(m_addr, m_buf, m_len);
  }

  event void Timer0.fired(){
    call FlagGPIO.set();
    m_addr = COUNT_ADDR;
    call Fram.read(m_addr, m_buf, m_len);
  }

  event void Fram.readDone(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len, error_t err) {
    //if(!m_init) {
    //  m_init = TRUE;
    //  call RadioControl.start();
    //  return;
    //}
    if(addr == SEQ_ADDR) {
      sequence = *buf;
      sequence = sequence + 1;
      m_buf[0] = sequence;
      call Fram.write(m_addr, m_buf, m_len);
    }
    else {
      counter = *buf;
      counter = counter + 1;
      m_buf[0] = counter;
      call Fram.write(m_addr, m_buf, m_len);
    }
  }

  event void Fram.writeDone(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len, error_t err) {
    if(addr == SEQ_ADDR) {
      sendMsg();
    }
    else {
      call AdcResource.request();
    }
  }

  event void Fram.writeEnableDone() {
    call Fram.readStatus(m_buf);
  }

  event void Fram.readStatusDone(uint8_t* buf, error_t err) {
    if(!m_init) {
      m_addr = COUNT_ADDR;
      call Fram.read(m_addr, m_buf, m_len);
    }
    else {
      call Fram.write(m_addr, m_buf, m_len);
    }
  }

  event void Fram.writeStatusDone(uint8_t* buf, error_t err) {}

  event void RadioSend.sendDone (message_t* message, error_t error) {
    call TimeGPIO.clr();
  }


  async event void Interrupt.fired() {}

  event message_t* RadioReceive.receive(message_t* packet,
                                        void* payload, uint8_t len) {
    return packet;
  }

  event void RadioControl.stopDone (error_t error) { }

  event void AdcResource.granted () {
    call ReadSingleChannel.configureSingle(&config);
    call ReadSingleChannel.getData();
  }

  async event error_t ReadSingleChannel.singleDataReady (uint16_t data) {
    call FlagGPIO.clr();
    call AdcResource.release();
    call Timer0.startOneShot(1000);
    if ((data >> 8) <= 2) {
      //sendMsg();
      m_addr = SEQ_ADDR;
      call Fram.read(m_addr, m_buf, m_len);
    } else {
      call TimeGPIO.clr();
    }
    return SUCCESS;
  }

  async event uint16_t* COUNT_NOK(numSamples) ReadSingleChannel.multipleDataReady(uint16_t *COUNT(numSamples) buffer, uint16_t numSamples) {
    return NULL;
  }
}
