#include "Timer.h"
#include "Msp430Adc12.h"
#include "coilcube_ip.h"
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

module CCFakeDataIpP {
	uses {
		interface Leds;
    interface Boot;

    interface Timer<TMilli> as Timer0;

    interface SplitControl as BlipControl;
    interface UDP as Udp;
    interface ForwardingTable;

    interface SeqNoControl;

    interface HplMsp430GeneralIO as FlagGPIO;
    interface Fm25lb as Fram;

    interface Msp430Adc12SingleChannel as ReadSingleChannel;
    interface Resource as AdcResource;

    interface HplMsp430GeneralIO as TimeControlGPIO;
  }
}
implementation {

  struct sockaddr_in6 dest; // Where to send the packet
  struct in6_addr next_hop; // for default route setup

  pkt_data_t pkt_data = {PROFILE_ID, COILCUBE_VERSION, 0, 0};

  uint16_t timing_cap_val;

  cc_state_e state;

  uint8_t seq_no = 0;

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

  event void Boot.booted() {
    call FlagGPIO.makeOutput();

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
    call SeqNoControl.set_sequence_number(seq_no);

    // Set the payload as the pkt data
    pkt_data.counter = 5;
    pkt_data.seq_no = seq_no;

    call Udp.sendto(&dest, &pkt_data, sizeof(pkt_data_t));
    // Not much we can do if this returns an error
  }

  task void state_machine () {

  }

  event void BlipControl.startDone (error_t error) {
    call Timer0.startPeriodic(3000);
  }

  event void Timer0.fired () {
    seq_no++;
    sendMsg();
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

  async event error_t ReadSingleChannel.singleDataReady (uint16_t data) {
    call FlagGPIO.clr();
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

  event void BlipControl.stopDone (error_t error) {
    post state_machine();
  }

  async event uint16_t* COUNT_NOK(numSamples)
  ReadSingleChannel.multipleDataReady(uint16_t *COUNT(numSamples) buffer,
    uint16_t numSamples) {
    return NULL;
  }

  event void Udp.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) { }
}
