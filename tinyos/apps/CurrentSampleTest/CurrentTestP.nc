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

  //  interface Read<uint16_t> as VTimerRead;

    interface HplMsp430GeneralIO as TimeControlGPIO;

  //  interface ReadStream<uint16_t> as CoilAdcStream;

    interface GpioCapture as SfdCapture;

    interface Timer<TMilli> as sendWaitTimer;

  //  interface HplAdc12 as HplAdc;
    interface Counter<T32khz,uint16_t> as ConversionTimeCapture;
    interface HplMsp430GeneralIO as CoilIn;

    interface Msp430Timer as TimerA;;
    interface Msp430TimerControl as ControlA1;
    interface Msp430Compare as CompareA1;
  }
//  provides{
//    interface AdcConfigure<const msp430adc12_channel_config_t*> as CoilAdcConfigure;
//  }
}
implementation {

  struct sockaddr_in6 voltage_dest;
  struct in6_addr     voltage_next_hop;
  struct sockaddr_in6 gatd_dest;
  struct sockaddr_in6 gatd_dest2;
  struct in6_addr     gatd_next_hop;

  pkt_hello_t pkt_hello = {0};
  pkt_data_t  pkt_data = {PROFILE_ID, 2, 0, 0, 0, 0, 0, 0};
  pkt_samples_t pkt_samp = {PROFILE_ID, 2, 0, 0, 0, {0}};

  // 16000 us period sine wave sampled every 40.375 us
  // scaled by 32767
  int16_t SIN_SAMPLES[396] = {
  0, 519, 1039, 1559, 2078, 2596, 3114, 3631, 4148, 4663, 5177, 5689, 6201,
  6710, 7218, 7725, 8229, 8731, 9231, 9729, 10224, 10717, 11206, 11694, 12178,
  12659, 13137, 13611, 14083, 14550, 15014, 15474, 15931, 16383, 16831, 17275,
  17715, 18150, 18580, 19006, 19427, 19844, 20255, 20661, 21062, 21457, 21848,
  22232, 22611, 22985, 23352, 23714, 24070, 24420, 24763, 25100, 25431, 25756,
  26074, 26386, 26691, 26989, 27280, 27565, 27842, 28113, 28377, 28633, 28882,
  29124, 29359, 29586, 29805, 30018, 30222, 30419, 30609, 30790, 30964, 31130,
  31289, 31439, 31582, 31716, 31843, 31961, 32072, 32174, 32269, 32355, 32433,
  32503, 32565, 32618, 32663, 32701, 32729, 32750, 32762, 32767, 32762, 32750,
  32729, 32701, 32663, 32618, 32565, 32503, 32433, 32355, 32269, 32174, 32072,
  31961, 31843, 31716, 31582, 31439, 31289, 31130, 30964, 30790, 30609, 30419,
  30222, 30018, 29805, 29586, 29359, 29124, 28882, 28633, 28377, 28113, 27842,
  27565, 27280, 26989, 26691, 26386, 26074, 25756, 25431, 25100, 24763, 24420,
  24070, 23714, 23352, 22985, 22611, 22232, 21848, 21457, 21062, 20661, 20255,
  19844, 19427, 19006, 18580, 18150, 17715, 17275, 16831, 16383, 15931, 15474,
  15014, 14550, 14083, 13611, 13137, 12659, 12178, 11694, 11206, 10717, 10224,
  9729, 9231, 8731, 8229, 7725, 7218, 6710, 6201, 5689, 5177, 4663, 4148, 3631,
  3114, 2596, 2078, 1559, 1039, 519, 0, -519, -1039, -1559, -2078, -2596, -3114,
  -3631, -4148, -4663, -5177, -5689, -6201, -6710, -7218, -7725, -8229, -8731,
  -9231, -9729, -10224, -10717, -11206, -11694, -12178, -12659, -13137, -13611,
  -14083, -14550, -15014, -15474, -15931, -16383, -16831, -17275, -17715,
  -18150, -18580, -19006, -19427, -19844, -20255, -20661, -21062, -21457,
  -21848, -22232, -22611, -22985, -23352, -23714, -24070, -24420, -24763,
  -25100, -25431, -25756, -26074, -26386, -26691, -26989, -27280, -27565,
  -27842, -28113, -28377, -28633, -28882, -29124, -29359, -29586, -29805,
  -30018, -30222, -30419, -30609, -30790, -30964, -31130, -31289, -31439,
  -31582, -31716, -31843, -31961, -32072, -32174, -32269, -32355, -32433,
  -32503, -32565, -32618, -32663, -32701, -32729, -32750, -32762, -32767,
  -32762, -32750, -32729, -32701, -32663, -32618, -32565, -32503, -32433,
  -32355, -32269, -32174, -32072, -31961, -31843, -31716, -31582, -31439,
  -31289, -31130, -30964, -30790, -30609, -30419, -30222, -30018, -29805,
  -29586, -29359, -29124, -28882, -28633, -28377, -28113, -27842, -27565,
  -27280, -26989, -26691, -26386, -26074, -25756, -25431, -25100, -24763,
  -24420, -24070, -23714, -23352, -22985, -22611, -22232, -21848, -21457,
  -21062, -20661, -20255, -19844, -19427, -19006, -18580, -18150, -17715,
  -17275, -16831, -16383, -15931, -15474, -15014, -14550, -14083, -13611,
  -13137, -12659, -12178, -11694, -11206, -10717, -10224, -9729, -9231, -8731,
  -8229, -7725, -7218, -6710, -6201, -5689, -5177, -4663, -4148, -3631, -3114,
  -2596, -2078, -1559, -1039, -519
  };

  uint16_t timing_cap_val;

  uint16_t sfd_capture_time = 0;

  uint16_t adc_current_samples[NUM_CURRENT_SAMPLES];
 // uint16_t time_samples[NUM_CURRENT_SAMPLES];

  int32_t power[396] = {0};

  uint16_t tdelta0 = 45;

  uint32_t voltage_ac_max = 0;


  fram_data_t fram_data;
  cc_state_e state;

  bool adc_started = FALSE;
  uint8_t sfds = 0;

  uint16_t sample_index = 0;
  uint16_t write_index = 0;



  int64_t power_average = 0;

  task void state_machine();
/*
  msp430adc12_channel_config_t coiladc_config = {
    inch:         INPUT_CHANNEL_A2,
    sref:         REFERENCE_AVcc_AVss,
   // sref:         REFERENCE_VREFplus_VREFnegterm,
    ref2_5v:      REFVOLT_LEVEL_NONE,
    adc12ssel:    SHT_SOURCE_SMCLK,
    adc12div:     SHT_CLOCK_DIV_1,
    sht:          SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id:   SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* CoilAdcConfigure.getConfiguration () {
    return &coiladc_config;
  }
*/
  event void Boot.booted() {
    call FlagGPIO.makeOutput();
    call FlagGPIO.clr();

    call CoilIn.selectModuleFunc();
    call CoilIn.makeInput();

    // Add the address and route to send to GATD
    inet_pton6(GATD_ADDR, &gatd_dest.sin6_addr);
    gatd_dest.sin6_port = htons(GATD_PORT);
    inet_pton6(GATD_ADDR, &gatd_dest2.sin6_addr);
    gatd_dest2.sin6_port = htons(6002);
    inet_pton6(ADDR_ALL_ROUTERS, &gatd_next_hop);
    call ForwardingTable.addRoute(gatd_dest.sin6_addr.s6_addr,
                                  128,
                                  &gatd_next_hop,
                                  ROUTE_IFACE_154);

    // Add the address and route to send to the neighboring voltage node
#if 1
    inet_pton6(ACME_ADDR, &voltage_dest.sin6_addr);
    voltage_dest.sin6_port = htons(VOLTAGE_REQUEST_PORT);
    inet_pton6(ACME_ADDR_LINKL, &gatd_next_hop);
    call ForwardingTable.addRoute(voltage_dest.sin6_addr.s6_addr,
                                  128,
                                  &gatd_next_hop,
                                  ROUTE_IFACE_154);
#else
    inet_pton6(CC2538_ADDR, &voltage_dest.sin6_addr);
    voltage_dest.sin6_port = htons(VOLTAGE_REQUEST_PORT);
    inet_pton6(CC2538_ADDR_LINKL, &gatd_next_hop);
    call ForwardingTable.addRoute(voltage_dest.sin6_addr.s6_addr,
                                  128,
                                  &gatd_next_hop,
                                  ROUTE_IFACE_154);
#endif
    // Want to be able to receive packets from the voltage nodes
    call Udp.bind(VOLTAGE_REQUEST_PORT);

    // We need to know when packets go in and out
    call SfdCapture.captureRisingEdge();

    state = STATE_START;
    call BlipControl.start();
  }

  // Let the ACme++ nodes know I'm alive and they should send the recent
  // voltage
  void send_hello_message () {
    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    // Send a "hello" message to the voltage meter
    call Udp.sendto(&voltage_dest, &pkt_hello, sizeof(pkt_hello_t));

    post state_machine();
  }

  void send_power_message () {
    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    // Set the payload as the pkt data
    pkt_data.pkt_type       = PKT_TYPE_POWER;
    pkt_data.seq_no         = fram_data.seq_no;
    pkt_data.wakeup_counter = fram_data.wakeup_counter;
    pkt_data.power          = htonl((uint32_t) power_average);
    pkt_data.power_factor   = fram_data.power_factor;
    pkt_data.power_factor   = 0xAABBEEDD;

    call Udp.sendto(&gatd_dest2, &pkt_data, sizeof(pkt_data_t));

    post state_machine();
  }

  void send_samples () {
    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    // Set the payload as the pkt data
    pkt_samp.pkt_type       = PKT_TYPE_SAMPLES;
    pkt_samp.seq_no         = fram_data.seq_no;
    memcpy(pkt_samp.samples, adc_current_samples, sample_index);

    call Udp.sendto(&gatd_dest2, &pkt_samp, 14+(2*30));

    //post state_machine();
  }

  event void sendWaitTimer.fired () {
  //  sfd_capture_time++;
  //  call SfdCapture.captureRisingEdge();
  }

  event void Udp.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) {

    call FlagGPIO.toggle();
    post state_machine();

  }



  void start_adc () {

// Setup ADC
/* try 1
    // Automatically do the next conversion after the last completed
    ADC12CTL0 = 0;
    ADC12CTL0 = (1<<7);
    // Sample as fast as possible
    ADC12CTL0 &= ~(0xFF<<8);
    // Single channel multiple, SMCLK, clock divider of 1, SAMPCON from the
    // sampling timer
    ADC12CTL1 = (1<<9) | (0x3<<3) | (0x2<<1);
    // Use channel A2, VCC/GND, and end of sequence (only one channel)
    ADC12MCTL0 = (1<<7) | (0x2);
    // Enable interrupt
    ADC12IE = 1;
    // Enable and start
    ADC12CTL0 |= (1<<4) | (1<<1) | 1;

    adc_started = TRUE;*/


    msp430_compare_control_t com_ctrl = {
      ccifg : 0, cov : 0, out : 1, cci : 0, ccie : 0,
      outmod : 4, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };


    call TimerA.setMode(MSP430TIMER_STOP_MODE);
    call TimerA.clear();
    call TimerA.disableEvents();
    call TimerA.setClockSource(0x2);
    call TimerA.setInputDivider(0);
    call CompareA1.setEvent(40);
    call ControlA1.setControl(com_ctrl);
    call TimerA.setMode(MSP430TIMER_UP_MODE);


    // Sample as fast as possible, no auto start after each conversion
    ADC12CTL0 = 0;
    // Single channel multiple, SMCLK, clock divider of 1, SAMPCON from the
    // sampling timer, sample and hold from timer A, conversion address 0
    ADC12CTL1 = (0x1<<10) | (1<<9) | (0x3<<3) | (0x2<<1);
    // Use channel A2, VCC/GND, and end of sequence (only one channel)
    ADC12MCTL0 = (1<<7) | (0x2);
    // Enable interrupt
    ADC12IE = 1;
    // Enable and start
    ADC12CTL0 |= (1<<4) | (1<<1) | 1;

    adc_started = TRUE;

    // Setup DMA
/*
    // Set the DMA trigger select to be the ADC interrupt
    // Use channel 0
    DMACTL0 &= ~(0xF << 0);
//    DMACTL0 |= (0x6 << 0);
    // Nothing interesting here
    DMACTL1 = 0;
    // Enable interrupt, edge sensitive trigger, word level transfers,
    // destination is a word, increment
    // the destination address, use repeated single transfer
    DMA0CTL = DMADT2 | DMADSTINCR1 | DMADSTINCR0 | DMAIE;
    // Set the source address to the ADC memory
    DMA0SA = ADC12MEM;
    // Set the destination address to be an array in this app
    DMA0DA = current_samples;
    // Set the size to 1
    DMA0SZ = 1;
    // Enable DMA
    DMA0CTL |= DMAEN;
*/


  }
/*
  TOSH_SIGNAL(DACDMA_VECTOR) {
    if (DMA0CTL & DMAIFG) {
      DMA0CTL &= ~DMAIFG;
      DMA0CTL &= ~DMAABORT;
      // DMA done
    }
      call FlagGPIO.toggle();
   // }
  }*/

  TOSH_SIGNAL(ADC12_VECTOR) {
    if (ADC12IV > 4) {
      P5OUT ^= 0x20;
      adc_current_samples[0] = ADC12MEM[0];
    }
  }


  void stop_adc () {
    uint16_t ctl1 = ADC12CTL1;
    ADC12CTL1 &= ~(CONSEQ0 | CONSEQ1);
    ADC12CTL0 &= ~(ADC12SC + ENC);
    ADC12CTL0 &= ~(ADC12ON);
    ADC12CTL1 |= (ctl1 & (CONSEQ0 | CONSEQ1));

 //   DMA0CTL = 0;

    adc_started = FALSE;
  }
/*
  async event void HplAdc.conversionDone(uint16_t iv) {
  //  ADC12CTL0 |= 1;
  //  call FlagGPIO.toggle();
  //  time_samples[sample_index] = call ConversionTimeCapture.get();
    atomic {
      if (sample_index < NUM_CURRENT_SAMPLES-50) {
        adc_current_samples[sample_index++] = ADC12MEM[0];
      }
    }
    //ADC12MEM
  //  DMA0CTL |= DMAREQ;
  }*/


  task void state_machine () {
    switch (state) {

      case STATE_START:
        state = STATE_FRAM_READ;
        call Fram.read(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
        break;

      case STATE_FRAM_READ:
        if (fram_data.version_hash == IDENT_UIDHASH) {
          fram_data.wakeup_counter++;
 //         state = STATE_READ_TIMING_CAP_DONE;
 //         call VTimerRead.read();

          if (1) {
          //if ((timing_cap_val >> 8) <= 2) {
            fram_data.seq_no++;
            state = STATE_SEND_HELLO_MESSAGE;
          } else {
            if (fram_data.power > 0) {
              fram_data.seq_no++;
              state = STATE_SEND_POWER;
            } else {
              state = STATE_DONE;
            }
          }

          call Fram.write(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));



        } else {
          // Initialize
          fram_data.version_hash = IDENT_UIDHASH;
          fram_data.wakeup_counter = 0;
          fram_data.seq_no = 0;
          fram_data.power = 0;
          fram_data.power_factor = 0;
          state = STATE_DONE;
          call Fram.write(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
        }

        break;

  /*    case STATE_READ_TIMING_CAP:
        state = STATE_READ_TIMING_CAP_DONE;
        call VTimerRead.read();
        break;*/

      case STATE_READ_TIMING_CAP_DONE: {

        if (1) {
        //if ((timing_cap_val >> 8) <= 2) {
          fram_data.seq_no++;
          state = STATE_SEND_HELLO_MESSAGE;
        } else {
          if (fram_data.power > 0) {
            fram_data.seq_no++;
            state = STATE_SEND_POWER;
          } else {
            state = STATE_DONE;
          }
        }

        call Fram.write(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));

        break;

      }

      case STATE_SEND_HELLO_MESSAGE:

        state = STATE_SENT_HELLO_MESSAGE;
        send_hello_message();
        break;

      case STATE_SENT_HELLO_MESSAGE: {
        // Sample the ADC


        state = STATE_SAMPLE_CURRENT_DONE;

        start_adc();




    //    call FlagGPIO.toggle();

    //    for (i=0; i<NUM_CURRENT_SAMPLES; i+=64) {
    //      call CoilAdcStream.postBuffer(current_samples+i, 64);
    //    }

       // call CoilAdcStream.postBuffer(current_samples, NUM_CURRENT_SAMPLES);
    //    call CoilAdcStream.read(0);
        break;
      }



      case STATE_SAMPLE_CURRENT_DONE: {
        int i;

        // Find the index of the current sample that was taken closest to when
        // the voltage waveform had a rising zero crossing.
        uint16_t zero_cross_index;
        uint16_t local_sample_index;

        int64_t power_total = 0;

        atomic {
          local_sample_index = sample_index;
        }

zero_cross_index =  local_sample_index - 1 - tdelta0;


        state = STATE_DONE;

        for (i=0; i<local_sample_index; i++) {
          int32_t adc_current_no_bias;




          // Find the sample of the current waveform that we need to multiply
          // with.
          uint16_t current_index = (zero_cross_index + i) % local_sample_index;

          if (i > 395) {
            break;
          }



          // Shift the ADC value down from our bias offset
          adc_current_no_bias = ((int32_t) (adc_current_samples[current_index])) - 2048;

          // Get some crazy scaled value for the instantaneous power
          // at this point in the voltage waveform (that always starts at 0);
          power[i] = ((int32_t) SIN_SAMPLES[i]) * voltage_ac_max * adc_current_no_bias;



          power_total += (int64_t) power[i];

          call FlagGPIO.toggle();

        }

        power_average =  power_total / (int64_t) local_sample_index;

        call FlagGPIO.toggle();

        send_power_message();


      }



/*
      case STATE_SAMPLE_CURRENT_DONE: {
        uint16_t to_write = 50;



        if (write_index >= sample_index) {
          state = STATE_CALCULATE_CURRENT2;
          write_index = 0;
          // done

          call Fram.write(30, (uint8_t*) (time_samples+write_index), to_write);

          write_index += to_write;

        } else {
          state = STATE_SAMPLE_CURRENT_DONE;

          if (sample_index-write_index < to_write) {
            to_write = sample_index-write_index;
          }

          call Fram.write(30, (uint8_t*) (current_samples+write_index), to_write);

          write_index += to_write;

        }


        // Wait for packet
    //    state = STATE_CALCULATE_CURRENT;



    //    call Fram.write(30, (uint8_t) (time_samples), sample_index);

        break;
}
      case STATE_CALCULATE_CURRENT:



        break;




      case STATE_CALCULATE_CURRENT2:{
        uint16_t to_write = 50;

        if (write_index >= sample_index) {
          state = STATE_SEND_SAMPLES;
          call Fram.write(2, (uint8_t*) &sfd_capture_time, 2);
        } else {

          state = STATE_CALCULATE_CURRENT2;
          // done

          if (sample_index-write_index < to_write) {
            to_write = sample_index-write_index;
          }

          call Fram.write(30, (uint8_t*) (time_samples+write_index), to_write);

          write_index += to_write;

        }



        break;

}


      case STATE_SEND_SAMPLES:
        state = STATE_DONE;
        send_samples();
        break;

*/

      case STATE_SEND_POWER:
        state = STATE_CLEAR_POWER;
        send_power_message();
        break;

      case STATE_CLEAR_POWER:
        state = STATE_DONE;
        fram_data.power = 0;
        fram_data.power_factor = 0;
        call Fram.write(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
        break;




//      case STATE_READ_FRAM_DONE:
//        fram_data.seq_no++;
//        state = STATE_WRITE_FRAM_DONE;
//        call Fram.write(FRAM_ADDR_COUNT, &fram_data.counter, sizeof(fram_data_t));
//        break;

 //     case STATE_WRITE_FRAM_DONE: {
 //       error_t e;

//        state = STATE_DONE;
//        sendMsg();


  //      state = STATE_SAMPLE_CURRENT_DONE;
  //      call CoilAdcStream.postBuffer(pkt_data.samples, NUM_CURRENT_SAMPLES);
  //      call CoilAdcStream.read(0);

//        break;
//      }
//      case STATE_SAMPLE_CURRENT_DONE:
//        state = STATE_DONE;
//        call TimeControlGPIO.makeOutput();
//        call TimeControlGPIO.set();
//        sendMsg();

//        break;

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
    uint8_t sfds_local;
  //  call FlagGPIO.toggle();
    atomic sfd_capture_time = time;

    atomic {
      sfds++;
      sfds_local = sfds;
    }

 //   call FlagGPIO.toggle();

    // stop adc
    if (sfds_local > 1) {
      stop_adc();
    }

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

//  event void VTimerRead.readDone (error_t result, uint16_t val) {
//    timing_cap_val = val;
//    post state_machine();
//  }

//  event void CoilAdcStream.readDone (error_t result, uint32_t usActualPeriod) {
  //  if (result == SUCCESS) {
   //   pkt_data.counter = 1;
  //  } else {
  //    pkt_data.counter = 2;
 ///   }
   // pkt_data.counter = (uint8_t) (usActualPeriod & 0xFF);
   // pkt_data.counter = (uint8_t) (result);
//    post state_machine();
//  }

  event void Fram.readStatusDone (uint8_t status, error_t err) {
    post state_machine();
  }

  event void Fram.writeStatusDone(error_t err) {
    post state_machine();
  }

  event void BlipControl.stopDone (error_t error) {
    post state_machine();
  }

//  event void CoilAdcStream.bufferDone (error_t result, uint16_t* buf,
//    uint16_t count) {
//    post state_machine();
//  }

  async event void ConversionTimeCapture.overflow(){}

  async event void TimerA.overflow() {}
  async event void CompareA1.fired(){}


}
