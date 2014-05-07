#include "Timer.h"
#include "Msp430Adc12.h"
#include "monjolo.h"
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
    interface HplMsp430GeneralIO as TimeControlGPIO;

    interface HplMsp430GeneralIO as SFDGpio;
    interface HplMsp430Interrupt as SFDInt;

    interface HplMsp430GeneralIO as CoilIn;

  }
}
implementation {

  struct sockaddr_in6 voltage_dest;
  struct in6_addr     voltage_next_hop;
  struct sockaddr_in6 gatd_dest;
  struct sockaddr_in6 gatd_dest2;
  struct in6_addr     gatd_next_hop;

  pkt_hello_t       pkt_hello      = {HELLO_MESSAGE_TYPE_VOLTAGE};
  pkt_data_t        pkt_data       = {{PROFILE_ID}, 2, 0, 0, 0, 0, 0, 0, 0};
  pkt_data_debug_t  pkt_data_debug = {{PROFILE_ID}, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0};

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

  uint8_t edges_caught = 0;

  uint16_t adc_current_samples[NUM_CURRENT_SAMPLES];

 // int32_t power[396] = {0};

  // Number of 40 us periods between when the SFD of the voltage info
  // packet and the zero crossing of the AC wave
  uint16_t tdelta0 = 0;

  // Peak AC voltage of the AC wave, in millivolts
  uint32_t voltage_ac_max = 0;
  uint32_t ticks_since_rising = 0;


  fram_data_t fram_data;
  cc_state_e  state;
  adc_state_e adc_state = ADC_STATE_OFF;


  uint16_t sample_index = 0;
  uint16_t write_index = 0;



  int64_t power_average = 0;



  task void state_machine();


  event void Boot.booted() {
    call FlagGPIO.makeOutput();
    call FlagGPIO.clr();

    // Enable falling edge SFD interrupt so we know when the first packet
    // went out
    call SFDGpio.selectIOFunc();
    call SFDGpio.makeInput();
    call SFDInt.edge(FALSE);
    call SFDInt.clear();
    call SFDInt.enable();

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

  // Send the power information to the cloud
  void send_power_message () {
    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    // Set the payload as the pkt data
    pkt_data.pkt_type       = PKT_TYPE_POWER;
    pkt_data.seq_no         = fram_data.seq_no;
    pkt_data.wakeup_counter = fram_data.wakeup_counter;
    pkt_data.power          = fram_data.power;
    pkt_data.power_factor   = fram_data.power_factor;
    pkt_data.voltage        = fram_data.voltage;

    call Udp.sendto(&gatd_dest2, &pkt_data, sizeof(pkt_data_t));

//P5OUT ^= 0x20;
//P5OUT ^= 0x20;
//P5OUT ^= 0x20;
//P5OUT ^= 0x20;

    post state_machine();
  }

  // Send the resulting power measurements and some debug info back to the cloud
  void send_power_debug_message () {
    // Tell the radio driver what sequence number to use
    call SeqNoControl.set_sequence_number(fram_data.seq_no);

    // Set the payload as the pkt data
    pkt_data_debug.pkt_type       = PKT_TYPE_POWER_DEBUG;
    pkt_data_debug.seq_no         = fram_data.seq_no;
    pkt_data_debug.wakeup_counter = fram_data.wakeup_counter;
    pkt_data_debug.power          = (int32_t) power_average;
    //pkt_data_debug.power_factor   = fram_data.power_factor;
    pkt_data_debug.power_factor   = sample_index;
    pkt_data_debug.tdelta         = tdelta0;
    pkt_data_debug.voltage        = voltage_ac_max;
    pkt_data_debug.ticks          = ticks_since_rising;

    call Udp.sendto(&gatd_dest2, &pkt_data_debug, sizeof(pkt_data_debug_t));

//P5OUT ^= 0x20;
//P5OUT ^= 0x20;
//P5OUT ^= 0x20;
//P5OUT ^= 0x20;

    post state_machine();
  }

  // Receive the voltage magnitude and phase
  event void Udp.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) {

    voltage_data_t* volt_data = (voltage_data_t*) data;
    uint32_t time_calc;

    voltage_ac_max = volt_data->vpeak;

    ticks_since_rising = volt_data->ticks_since_rising;

    // Calculate the phase offset in 40 us periods
    // The ticks_since_rising (TSR) is counter ticks of a 32MHz counter
    // between when the ADE7753 ZX line went high and when the SFD line
    // of the packet we just received went high. We sample the current waveform
    // every 40us, so we need to know how many samples ago the rising zero
    // crossing of the voltage waveform occurred.
    // The ADE7753 ZX line has a phase offset from when the voltage actually
    // crosses zero that was empirically measured to be about 1.19ms.
    //
    //
    //             (TSR * 31.25ns) + 1.19ms
    //  tdelta0 =  ------------------------
    //                      40us
    //
    //             (TSR * 3125dps) + 119000000dps
    //          =  ------------------------------
    //                      4000000dps
    //
    time_calc = ((volt_data->ticks_since_rising * 3125) / 4000000) + 30;
    tdelta0 = (uint16_t) time_calc;

    post state_machine();
  }

  // Configure the ADC to sample the timing capacitor
  void adc_sample_timing () {

    // SETUP ADC
    // Sample based on timer a pulses

    atomic adc_state = ADC_STATE_TIMING;

    // Take some clock cycles to think about it
    ADC12CTL0 = (0x2 << 8);
    // Single channel single, SMCLK, clock divider of 1
    ADC12CTL1 = (1<<9) | (0x3<<3);
    // Use channel A0, VCC/GND, and end of sequence (only one channel)
    ADC12MCTL0 = (1<<7) | (0x0);
    // Enable interrupt
    ADC12IE = 1;
    // Enable and start
    ADC12CTL0 |= (1<<4);
    ADC12CTL0 |= (1<<1) | 1;

  }

  // Configure the ADC to sample the current waveform
  void adc_sample_coil () {

//P1SEL |= 0x40;
//P1DIR |= 0x40;

    atomic adc_state = ADC_STATE_COIL;

    // SETUP TIMER A
    // Use timer a to sample the ADC every 40 microseconds

    // Up mode, /1 divider, SMCLK
    TACTL = 0;
    TACTL = TASSEL_2 | ID_0 | MC_1;

    // Toggle mode
    TACCTL1 = 0x0000;
    TACCTL1 = CM0 | CCIS_0 | OUTMOD_4;

    TACCR0 = 20;
    TACCR1 = 20;


    // SETUP ADC
    // Sample based on timer a pulses

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

  }

  // Stop the ADC and the timer
  void adc_stop () {
    uint16_t ctl1 = ADC12CTL1;

    atomic adc_state = ADC_STATE_OFF;

    ADC12CTL1 &= ~(CONSEQ0 | CONSEQ1);
    ADC12CTL0 &= ~(ADC12SC + ENC);
    ADC12CTL0 &= ~(ADC12ON);
    ADC12CTL1 |= (ctl1 & (CONSEQ0 | CONSEQ1));

    TACTL &= ~(0x3<<4);
  }

  // Interrupt callback for the ADC samples
  TOSH_SIGNAL(ADC12_VECTOR) {
    uint16_t reading;

    atomic {
      reading = ADC12MEM[0];
      if (adc_state == ADC_STATE_TIMING) {
        timing_cap_val = reading;
        adc_stop();
        post state_machine();
      } else {
        if (edges_caught < 2) {
          P5OUT ^= 0x20;
          if (sample_index < NUM_CURRENT_SAMPLES) {
            adc_current_samples[sample_index++] = reading;
          }
        }
      }
    }
  }


  void read_fram () {
    call Fram.read(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
  }

  void write_fram () {
    call Fram.write(FRAM_ADDR_BASE, (uint8_t*) &fram_data, sizeof(fram_data_t));
  }

  task void state_machine () {
    switch (state) {

      // On startup sample the FRAM. This will let us increment our wakeup
      // counter and check if the contents of the FRAM are valid.
      case STATE_START:
        state = STATE_FRAM_READ_DONE;
        read_fram();
        break;

      // Verify the UIDHASH matches
      case STATE_FRAM_READ_DONE:
        if (fram_data.version_hash == IDENT_UIDHASH) {
          // Increment the wakeup counter and check the timing capacitor
          fram_data.wakeup_counter++;

          if (fram_data.power != 0) {
            // We just calculated a power measurement
            // Be sure to transmit this to GATD!
            state = STATE_SEND_POWER;
            fram_data.seq_no++;
            write_fram();
          } else {
            // Check the timing capacitor
            state = STATE_READ_TIMING_CAP_DONE;
            adc_sample_timing();
          }

        } else {
          // Just initialize the FRAM and wait for the next activation
          fram_data.version_hash   = IDENT_UIDHASH;
          fram_data.wakeup_counter = 0;
          fram_data.seq_no         = 0;
          fram_data.power          = 0;
          fram_data.power_factor   = 0;
          fram_data.voltage        = 0;
          state = STATE_DONE;
          write_fram();
        }

        break;

      // Check the timing capacitor. If above the threshold, don't do anything
      // else, if below, do a power measurement
      case STATE_READ_TIMING_CAP_DONE:

        if (1) {
        //if ((timing_cap_val >> 8) <= 2) {
          fram_data.seq_no++;
          state = STATE_SEND_HELLO_MESSAGE;
        } else {
          state = STATE_DONE;
        }
        write_fram();

        break;

      // Tell the voltage monitor we need to know about the voltage
      case STATE_SEND_HELLO_MESSAGE:
        state = STATE_SENT_HELLO_MESSAGE;
        send_hello_message();
        break;

      // Sample the current waveform
      case STATE_SENT_HELLO_MESSAGE:
        // Sample the ADC
        state = STATE_SAMPLE_CURRENT_DONE;
        adc_sample_coil();
        break;

      // Calculate power after sampling the current waveform
      case STATE_SAMPLE_CURRENT_DONE: {
        int i;

        // Find the index of the current sample that was taken closest to when
        // the voltage waveform had a rising zero crossing.
        uint16_t zero_cross_index;
        uint16_t local_sample_index;
        uint16_t iterations = 396;

        int64_t power = 0;
        int64_t power_total = 0;

        state = STATE_DONE;

        atomic {
          local_sample_index = sample_index;
        }

        // Calculate where to start in the current waveform array. We start at
        // where the zero crossing of the voltage signal was.
        zero_cross_index =  local_sample_index - 1 - tdelta0;

        if (local_sample_index < iterations) {
          iterations = local_sample_index;
        }

power_average = 0;

        // Iterate over all of the current samples and multiply them by the
        // reconstructed voltage
        for (i=0; i<iterations; i++) {
          int32_t adc_current_no_bias;

          // Find the sample of the current waveform that we need to multiply
          // with.
          uint16_t current_index = (zero_cross_index + i) % local_sample_index;

          // Shift the ADC value down from our bias offset
          adc_current_no_bias = ((int32_t) (adc_current_samples[current_index])) - 2031;
        //  adc_current_no_bias = ((int32_t) adc_current_samples[current_index]);
        //  adc_current_no_bias = -12;

          // Get some crazy scaled value for the instantaneous power
          // at this point in the voltage waveform (that always starts at 0);
          power = ((int32_t) (SIN_SAMPLES[i])) * adc_current_no_bias;
        //  power[i] = adc_current_no_bias;

          // Accumulate the power total
          power_total += power;

      //    call FlagGPIO.toggle();
/*
if (SIN_SAMPLES[i]>0 && adc_current_no_bias < 0) {
  power_average += 1;
} else if (SIN_SAMPLES[i]<0 && adc_current_no_bias > 0) {
  power_average += 1;
} else {
   power_total += power;
}*/
        }

  //      call FlagGPIO.toggle();
  //      call FlagGPIO.toggle();
  //      call FlagGPIO.toggle();
  //      call FlagGPIO.toggle();

        // Calculate an average
      //  power_average = (power_total / (int64_t) iterations) * voltage_ac_max;
//        power_average = (power_total / (int64_t) iterations) * 171000;
        power_average = (power_total / (int64_t) iterations);

        fram_data.power = (int32_t) power_average;
        fram_data.voltage = voltage_ac_max;

        write_fram();

        // Send the result
      //  send_power_debug_message();
        break;
      }

      // Transmit the power reading to the server
      case STATE_SEND_POWER:
        state = STATE_CLEAR_POWER;
        send_power_message();
        break;

      // Reset the power values in the FRAM and store them so we don't
      // re-transmit
      case STATE_CLEAR_POWER:
        state = STATE_DONE;
        fram_data.power = 0;
        write_fram();
        break;

      case STATE_DONE:
        break;

      default:
        break;

    }
  }

  async event void SFDInt.fired () {
    uint8_t edges_caught_local;

    call SFDInt.clear();
    atomic {
      edges_caught++;
      edges_caught_local = edges_caught;
    }

    if (edges_caught_local == 1) {
      call SFDInt.edge(TRUE);
    } else if (edges_caught_local > 1) {
      // Stop sampling ADC
      call SFDInt.disable();
      adc_stop();
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

  event void Fram.readStatusDone (uint8_t status, error_t err) {
    post state_machine();
  }

  event void Fram.writeStatusDone(error_t err) {
    post state_machine();
  }

  event void BlipControl.stopDone (error_t error) {
    post state_machine();
  }

}
