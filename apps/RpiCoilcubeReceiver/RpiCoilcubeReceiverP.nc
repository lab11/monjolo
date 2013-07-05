
module RpiCoilcubeReceiverP {
  uses {
    interface Boot;
    interface Leds;

    interface SplitControl as RadioControl;
    interface Receive;
    interface Send;

   // interface UartBuffer;
  }
}
implementation {

#define COILCUBE_ADDR 2
#define TEST_LOAD_ADDR 3

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone (error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    printf("started\n");
  }

  // Ground truth
  uint16_t actual_wattage = 0;

  // State of the system when the last packet arrived
  uint64_t previous_timestamp = 0;
  uint8_t  previous_count = 0;

  // Returns a guess of the primary wattage based on a model of how coilcube
  // works.
  //
  // timestamp: microsecond resolution unix time stamp of the current packet
  //            from coilcube.
  // count:     the current count value returned from coilcube
  uint32_t calculate_wattage (uint64_t timestamp, uint8_t count) {
    uint64_t interval; // microseconds between packets
    uint8_t  wakeups;  // count of wakeups between packets
    uint32_t wattage;

    interval = timestamp - previous_timestamp;

    if (count >= previous_count) {
      wakeups = count - previous_count;
    } else {
      wakeups = count + (256-previous_count);
    }

    wattage = ((uint32_t) (interval/1000)) / ((uint32_t) wakeups);

    return wattage;
  }

  // sets global actual_wattage to an actual wattage value given a count from
  // the test load.
  void update_actual_wattage (uint16_t val) {
    actual_wattage = val;
  }

  // Rough outline of what this function will be when everything is filled in
  // correctly.
  event message_t* Receive.receive (message_t* msg,
                                    void* payload,
                                    uint8_t len) {
    uint8_t* pkt_buf = (uint8_t*) msg;
    uint8_t seq;
    uint8_t val, val2;
    uint16_t src;
    timestamp_metadata_t* meta_timestamp;
    uint64_t timestamp;

    // need to update this to get it from the meta data from the packet
    meta_timestamp = &(((cc2520packet_metadata_t*) msg->metadata)->timestamp);
    timestamp = meta_timestamp->timestamp_micro;

    // get seq number
    seq = pkt_buf[3];

    val = pkt_buf[10];
    val2 = pkt_buf[11];

    src = pkt_buf[8] | (pkt_buf[9] << 8);


    switch (src) {
      case COILCUBE_ADDR:
        {
          uint8_t count = val;
          uint32_t wattage;

          wattage = calculate_wattage(timestamp, count);

          printf("Current wattage: estimated: %i, actual: %i\n",
                 wattage, actual_wattage);

          previous_timestamp = timestamp;
          previous_count = count;
        }
        break;

      case TEST_LOAD_ADDR:
        update_actual_wattage((((uint16_t) val) << 8) | val2);
        printf("got load measurement\n");
        break;

      default:
        break;
    }


    return msg;
  }

//  event void UartBuffer.receive (uint8_t* buf, uint8_t len) {
//    printf("%s", buf);
//  }

  event void RadioControl.stopDone (error_t err) { }
  event void Send.sendDone (message_t* msg, error_t err) { }
}

