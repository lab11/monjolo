#include "Timer.h"
#include "Msp430Adc12.h"
#include "monjolo.h"
//#include "monjolo_platform.h"
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>


module CurrentTestP {
	uses {
		interface Leds;
    interface Boot;

    interface SplitControl as BlipControl;
    interface UDP as Udp;
    interface ForwardingTable;
    interface SeqNoControl;

    interface Fm25lb as Fram;

    interface HplMsp430GeneralIO as FlagGPIO;

    interface Read<uint16_t> as VTimerRead;

    interface HplMsp430GeneralIO as TimeControlGPIO;

    interface ReadStream<uint16_t> as CoilAdcStream;

    interface GpioCapture as SfdCapture;

    interface Timer<TMilli> as sendWaitTimer;
  }
  provides{
    interface AdcConfigure<const msp430adc12_channel_config_t*> as CoilAdcConfigure;
  }
}
implementation {

  struct sockaddr_in6 dest; // Where to send the packet
  struct in6_addr next_hop; // for default route setup

  pkt_data_t pkt_data = {PROFILE_ID, 2, 0, 0, 0, 0, {0}};

  uint16_t timing_cap_val;

  uint16_t sfd_capture_time = 0;

  uint16_t current_samples[500];


  fram_data_t fram_data;
  cc_state_e state;

  msp430adc12_channel_config_t coiladc_config = {
    inch:         INPUT_CHANNEL_A2,
    sref:         REFERENCE_AVcc_AVss,
   // sref:         REFERENCE_VREFplus_VREFnegterm,
    ref2_5v:      REFVOLT_LEVEL_NONE,
    adc12ssel:    SHT_SOURCE_ACLK,
    adc12div:     SHT_CLOCK_DIV_1,
    sht:          SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id:   SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* CoilAdcConfigure.getConfiguration () {
    return &coiladc_config;
  }

  event void Boot.booted() {
    call FlagGPIO.makeOutput();
    call FlagGPIO.clr();
    // Get binary version of the ip address to send the packets to
  //  inet_pton6(RECEIVER_ADDR, &dest.sin6_addr);
  //  dest.sin6_port = htons(RECEIVER_PORT);

    inet_pton6(CC2538_ADDR, &dest.sin6_addr);
    dest.sin6_port = htons(VOLTAGE_PORT);

    // Setup a default broadcast route for that destination
    inet_pton6(CC2538_ADDR_LINKL, &next_hop);
    //inet_pton6(ADDR_ALL_ROUTERS, &next_hop);
    call ForwardingTable.addRoute(dest.sin6_addr.s6_addr, 128, &next_hop,
      ROUTE_IFACE_154);

    call Udp.bind(VOLTAGE_PORT);

    call SfdCapture.captureRisingEdge();

//    state = STATE_READ_TIMING_CAP;
    state = STATE_READ_TIMING_CAP_DONE;
    call BlipControl.start();
  }

  void sendMsg () {
    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    // Set the payload as the pkt data
   // pkt_data.counter = fram_data.counter;
    pkt_data.seq_no = fram_data.seq_no;

    pkt_data.recv_count = fram_data.recv_count;
    pkt_data.sfd_capture = fram_data.sfd_capture;

    call Udp.sendto(&dest, &pkt_data, sizeof(pkt_data_t));
    // Not much we can do if this returns an error

 //   call sendWaitTimer.startOneShot(50);
   // call SfdCapture.captureRisingEdge();
  }

  event void sendWaitTimer.fired () {
  //  sfd_capture_time++;
  //  call SfdCapture.captureRisingEdge();
  }

  event void Udp.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) {
    fram_data.recv_count++;
    fram_data.sfd_capture = htons(sfd_capture_time);

    state = STATE_DONE;
  //  call Fram.write(FRAM_ADDR_BASE, &fram_data.counter, sizeof(fram_data_t));
  }



  task void state_machine () {
    switch (state) {

      case STATE_START:
        state = STATE_FRAM_READ;
        call Fram.read(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
        break;

      case STATE_FRAM_READ:
        if (fram_data.version_hash == IDENT_UIDHASH) {
          fram_data.wakeup_counter++;
          state = STATE_READ_TIMING_CAP_DONE;
          call VTimerRead.read();
        } else {
          // Initialize
          fram_data.version_hash = IDENT_UIDHASH;
          fram_data.wakeup_counter = 0;
          fram_data.seq_no = 0;
          state = STATE_DONE;
          call Fram.write(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
        }

        break;

      case STATE_READ_TIMING_CAP:
        state = STATE_READ_TIMING_CAP_DONE;
        call VTimerRead.read();
        break;

      case STATE_READ_TIMING_CAP_DONE: {

        if (1) {
        //if ((timing_cap_val >> 8) <= 2) {
          fram_data.seq_no++;
          state = STATE_SEND_HELLO_MESSAGE;
          call Fram.write(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
        } else {
          state = STATE_DONE;
        }

        call Fram.read(FRAM_ADDR_COUNT, (uint8_t*) &fram_data, sizeof(fram_data_t));

        break;

      }

      case STATE_SEND_HELLO_MESSAGE:

        state = STATE_SENT_HELLO_MESSAGE;
        send_hello_message();
        break;

      case STATE_SENT_HELLO_MESSAGE:
        // Sample the ADC

        state = STATE_SAMPLE_CURRENT_DONE;
        call CoilAdcStream.postBuffer(current_samples, NUM_CURRENT_SAMPLES);
        call CoilAdcStream.read(0);
        break;

      case STATE_SAMPLE_CURRENT_DONE:
        // Wait for packet
        break;



      case STATE_READ_FRAM_DONE:
        fram_data.seq_no++;
        state = STATE_WRITE_FRAM_DONE;
        call Fram.write(FRAM_ADDR_COUNT, &fram_data.counter, sizeof(fram_data_t));
        break;

      case STATE_WRITE_FRAM_DONE: {
        error_t e;

        state = STATE_DONE;
        sendMsg();


  //      state = STATE_SAMPLE_CURRENT_DONE;
  //      call CoilAdcStream.postBuffer(pkt_data.samples, NUM_CURRENT_SAMPLES);
  //      call CoilAdcStream.read(0);

        break;
      }
      case STATE_SAMPLE_CURRENT_DONE:
        state = STATE_DONE;
        call TimeControlGPIO.makeOutput();
        call TimeControlGPIO.set();
        sendMsg();

        break;

/*
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
*/
      case STATE_DONE:
        break;

      default:
        break;

    }

  }

  async event void SfdCapture.captured (uint16_t time) {
    call FlagGPIO.toggle();
    atomic sfd_capture_time = time;

    //atomic sfd_capture_time++;
    //call SfdCapture.disable();
    //call SfdCapture.captureFallingEdge();
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

  event void VTimerRead.readDone (error_t result, uint16_t val) {
    timing_cap_val = val;
    post state_machine();
  }

  event void CoilAdcStream.readDone (error_t result, uint32_t usActualPeriod) {
  //  if (result == SUCCESS) {
   //   pkt_data.counter = 1;
  //  } else {
  //    pkt_data.counter = 2;
 ///   }
    pkt_data.counter = (uint8_t) (usActualPeriod & 0xFF);
   // pkt_data.counter = (uint8_t) (result);
 //   post state_machine();
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

  event void CoilAdcStream.bufferDone (error_t result, uint16_t* buf,
    uint16_t count) {
post state_machine();
  }


}
