#include "Timer.h"
#include "Msp430Adc12.h"
#include "monjolo.h"
#include "monjolo_platform.h"
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>


module AirflowDetectP {
	uses {
		interface Leds;
    interface Boot;

    interface Init as RadioInit;

    interface SplitControl as BlipControl;
    interface UDP as Udp;
    interface ForwardingTable;
    interface SeqNoControl;

    interface Fm25lb as Fram;

    interface HplMsp430GeneralIO as FlagGPIO;

    interface Read<uint16_t> as VTimerAdcRead;
    interface HplMsp430GeneralIO as TimeControlGPIO;

    interface Timer<TMilli> as AirflowWaitTimer;
    interface Read<uint16_t> as AirflowAdcRead;

    interface HplMsp430GeneralIO as AirflowCtrl;

  }
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t*> as VTimerAdcConfigure;
    interface AdcConfigure<const msp430adc12_channel_config_t*> as AirflowAdcConfigure;
  }
}
implementation {

  struct sockaddr_in6 dest; // Where to send the packet
  struct in6_addr next_hop; // for default route setup

  pkt_data_t pkt_data = {PROFILE_ID, AIRFLOW_VERSION, 0, 0, 0, 0, {0}};

  uint16_t timing_cap_val;

  fram_data_t fram_data;
  cc_state_e state;

  uint16_t sample_count_to_send;

  uint16_t airflow_sample;
  uint16_t airflow_samples[MAX_NUM_AIRFLOW_SAMPLES] = {0};

  task void state_machine ();

  msp430adc12_channel_config_t vtimeradc_config = {
    inch:         INPUT_CHANNEL_A2,
    sref:         REFERENCE_AVcc_AVss,
    ref2_5v:      REFVOLT_LEVEL_NONE,
    adc12ssel:    SHT_SOURCE_SMCLK,
    adc12div:     SHT_CLOCK_DIV_1,
    sht:          SAMPLE_HOLD_16_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id:   SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* VTimerAdcConfigure.getConfiguration () {
    return &vtimeradc_config;
  }

  msp430adc12_channel_config_t airflowadc_config = {
    inch:         INPUT_CHANNEL_A5,
    sref:         REFERENCE_AVcc_AVss,
   // sref:         REFERENCE_VREFplus_VREFnegterm,
    ref2_5v:      REFVOLT_LEVEL_NONE,
    adc12ssel:    SHT_SOURCE_SMCLK,
    adc12div:     SHT_CLOCK_DIV_1,
    sht:          SAMPLE_HOLD_16_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id:   SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* AirflowAdcConfigure.getConfiguration () {
    return &airflowadc_config;
  }

  event void Boot.booted() {
    // Get binary version of the ip address to send the packets to
    inet_pton6(RECEIVER_ADDR, &dest.sin6_addr);
    dest.sin6_port = htons(RECEIVER_PORT);

    // Setup a default broadcast route for that destination
    inet_pton6(ADDR_ALL_ROUTERS, &next_hop);
    call ForwardingTable.addRoute(dest.sin6_addr.s6_addr, 128, &next_hop,
      ROUTE_IFACE_154);

    // Set a timer to sample the ADC for the airflow sensor 10 milliseconds
    // from now
   // call AirflowWaitTimer.startOneShot(1);

    //call RadioInit.init();

    state = STATE_INITIAL_READ;
    //call BlipControl.start();
    post state_machine();
  }

  void sendMsg () {

    uint16_t i;
    uint32_t total = 0;
    uint8_t over = 0;

    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    for (i=0; i<sample_count_to_send; i++) {
      total += airflow_samples[i];

      if (airflow_samples[i] > 0x500) {
        over++;
      }
    }

    for (i=sample_count_to_send-5; i<sample_count_to_send; i++) {
      pkt_data.samples[i-(sample_count_to_send-5)] = htons(airflow_samples[i]);
    }

  //  for (i=6; i<11; i++) {
  //    pkt_data.samples[i-6] = htons(airflow_samples[i]);
  //  }

    // Set the payload as the pkt data
    pkt_data.wakeup_counter       = htonl(fram_data.wakeup_counter);
    //pkt_data.seq_no               = fram_data.seq_no;
    pkt_data.seq_no               = over;
    pkt_data.airflow_sample_total = htonl(total);
    pkt_data.sample_count         = htons(sample_count_to_send);

    call Udp.sendto(&dest, &pkt_data, sizeof(pkt_data_t));
    // Not much we can do if this returns an error
  }

  void store_fram_base () {
    call Fram.write(FRAM_ADDR_BASE,
                    (uint8_t*) &fram_data,
                    sizeof(fram_data_t));
  }

  task void state_machine () {
    switch (state) {
      case STATE_INITIAL_READ:
        // Read in the status from the FRAM
        state = STATE_INITIAL_READ_DONE;
        call Fram.read(FRAM_ADDR_BASE,
                       (uint8_t*) &fram_data,
                       sizeof(fram_data_t));
        break;

      case STATE_INITIAL_READ_DONE:
        // Just got the id and whatnot from FRAM

        // Check if the last time we wrote the FRAM we were running the same
        // version of the code.
        if (fram_data.version_hash == IDENT_UIDHASH) {
          // We're good, the data should match

          // Increment the wakeup counter because this counts as a wakeup
          fram_data.wakeup_counter++;

          // Check if we have any airflow samples
          // If we do not, don't bother sending a packet but rather sample
          // the airflow sensor so we can get some data after recording our
          // wakeup
          if (fram_data.sample_count == 0) {
            state = STATE_SAMPLE_AIRFLOW;
            call AirflowCtrl.clr();
            store_fram_base();

          } else {
            // We have data, but we still don't want to transmit packets
            // too quickly. Check the timing capacitor to know if this should be
            // a radio transmission wakeup or an airflow sampling wakeup
            state = STATE_CHECK_PKT_DELAY_DONE;
            call VTimerAdcRead.read();
          }

        } else {
          call Leds.led0On();
          // This is old FRAM data
          fram_data.version_hash = IDENT_UIDHASH;
          fram_data.wakeup_counter = 0;
          fram_data.seq_no = 0;
          fram_data.sample_count = 0;

          // Just write back the new configuration and call it quits
          state = STATE_DONE;
          store_fram_base();
        }

        break;

      case STATE_CHECK_PKT_DELAY_DONE: {
        // Got the ADC sample back

        //if (1) {
        //if (0) {
        if ((timing_cap_val >> 8) <= 2) {
          // The capacitor is low enough to send a packet
          // Update the sequence number and store it and the count value
          // Not the number of samples but then reset the count so we start
          // fresh on the next wakeup
          state = STATE_SEND_PACKET;
          sample_count_to_send = fram_data.sample_count;
          fram_data.seq_no++;
          fram_data.sample_count = 0;
          store_fram_base();

         call RadioInit.init();

        } else {
          // Start sampling airflow
          state = STATE_SAMPLE_AIRFLOW;
          call AirflowCtrl.clr();
          store_fram_base();
        }
        break;
      }

      // State that goes down the path of transmitting airflow samples
      // we have already collected
      case STATE_SEND_PACKET:
        state = STATE_SEND_PACKET_READ_SAMPLES_DONE;

        // Read out the airflow samples from FRAM
        call Fram.read(FRAM_ADDR_SAMPLES,
                       (uint8_t*) airflow_samples,
                       sample_count_to_send * sizeof(uint16_t));
        break;

      // Called after we have read the samples from the fram so we can
      // now transmit them
      case STATE_SEND_PACKET_READ_SAMPLES_DONE:
        state = STATE_SEND_PACKET_START_BLIP_DONE;
        call BlipControl.start();
        break;

      // BLIP is ready to go, send a packet
      case STATE_SEND_PACKET_START_BLIP_DONE:
        state = STATE_DONE;
        // Recharge the timing capacitor
        call TimeControlGPIO.makeOutput();
        call TimeControlGPIO.set();
        sendMsg();
        call Leds.led0On();
        break;


      // State to start a read of the airflow ADC line
      case STATE_SAMPLE_AIRFLOW:

        // Check if we can fit any more samples
        if (fram_data.sample_count >= MAX_NUM_AIRFLOW_SAMPLES) {
          // Full of samples. Just quit and wait until we can transmit a packet
          // to clear out our store
          state = STATE_DONE;

        } else {
          state = STATE_SAMPLE_AIRFLOW_RECORD;
          call AirflowAdcRead.read();
        }
        break;

      // Called after an airflow ADC sample has been taken. First writes
      // the sample to FRAM and then updates the sample count
      // Record the adc value and the sample count each time because we don't
      // know when energy will run out
      case STATE_SAMPLE_AIRFLOW_RECORD:

   //   call AirflowCtrl.toggle();

        // Check if this sample is useful
  //      if (airflow_sample < 20) {
  //        // Too low!
  //        state = STATE_SAMPLE_AIRFLOW_RECORD;
  //        call AirflowAdcRead.read();

  //      } else {
          // This is a useful sample
          state = STATE_SAMPLE_AIRFLOW_UPDATE_COUNT;

          // Write the new sample back to the correct place in the FRAM
          call Fram.write(FRAM_ADDR_SAMPLES + (sizeof(uint16_t) * fram_data.sample_count),
                          (uint8_t*) &airflow_sample,
                          sizeof(airflow_sample));
  //      }

        break;

      // Update the number of samples
      case STATE_SAMPLE_AIRFLOW_UPDATE_COUNT:
        state = STATE_SAMPLE_AIRFLOW;

        fram_data.sample_count++;
        call Fram.write(FRAM_ADDR_BASE+offsetof(fram_data_t, sample_count),
                        (uint8_t*) &fram_data.sample_count,
                        sizeof(fram_data.sample_count));
        break;



      case STATE_DONE:
        break;

      default:
        break;

    }

  }

  event void AirflowWaitTimer.fired () {
    call AirflowAdcRead.read();
  }

  event void VTimerAdcRead.readDone (error_t result, uint16_t val) {
    timing_cap_val = val;
    post state_machine();
  }

  event void AirflowAdcRead.readDone (error_t result, uint16_t val) {
    airflow_sample = val;
    post state_machine();
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

  event void Fram.readStatusDone (uint8_t status, error_t err) {
    post state_machine();
  }

  event void Fram.writeStatusDone(error_t err) {
    post state_machine();
  }

  event void BlipControl.stopDone (error_t error) {
    post state_machine();
  }


  event void Udp.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) { }
}
