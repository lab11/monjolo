#include "coilcube_packet.h"

module RpiCoilcubeReceiverP {
  uses {
    interface Boot;
    interface Leds;

    interface SplitControl as RadioControl;
    interface Receive;
    interface Send;

    interface TcpSocket as GatdSocket;

    interface Queue<cc_raw_pkt_t> as RawPacketQueue;
  }
}
implementation {

#define COILCUBE_ADDR 2
#define TEST_LOAD_ADDR 3

  char gatd_host[] = "inductor.eecs.umich.edu";
  uint16_t gatd_port = 4002;
  char gatd_profile[] = "abcdefghij"

  cc_gatd_pkt_header_t pkt_header;

  event void Boot.booted() {
    error_t err;

    // Connect to the GATD server to store the coilcube data
    err = call GatdSocket.connect(gatd_host, gatd_port);
    if (err != SUCCESS) {
      fprintf(stderr, "Unable to connect to the storage server.\n");
      fprintf(stderr, "Exiting.\n");
      exit(1);
    }

    // Set up the packet structs
    strncpy(pkt_header.profile, gatd_profile, GATD_PROFILEID_LEN);

    call RadioControl.start();
  }

  event void RadioControl.startDone (error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
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

  task void process_queue_task () {
    cc_raw_pkt_t raw;

    if (RawPacketQueue.size == 0) return;

    raw = RawPacketQueue.dequeue();

    // Send raw to GATD

    // process the packet for the power measurement
    // send that result to gatd

    // Re post task to process the rest of the queue
    post process_queue_task();
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

    cc_raw_pkt_t raw_pkt;

    // Get the timestamp from the radio driver
    meta_timestamp = &(((cc2520packet_metadata_t*) msg->metadata)->timestamp);
    raw_pkt.timestamp = meta_timestamp->timestamp_micro;

    // Check if extended source addressing was used
    // If not, disregard this packet

    // Copy the id into the raw struct
    // Copy the seq_no into the raw struct
    // Copy the counter into the raw struct

    // Enqueue the raw packet

    post process_queue_task();

    return msg;

/*
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
*/

    return msg;
  }

  event void GatdSocket.receive (uint8_t* msg, int len) { }

  event void RadioControl.stopDone (error_t err) { }
  event void Send.sendDone (message_t* msg, error_t err) { }
}

