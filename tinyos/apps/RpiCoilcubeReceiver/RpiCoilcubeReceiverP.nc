#include "coilcube_packet.h"
#include "ieee154_header.h"
#include "byteswap.h"

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

#define STD_COILCUBE_PKT_LENGTH 19

  char gatd_host[] = "gatd.eecs.umich.edu";
  uint16_t gatd_port = 4002;
  char gatd_profile[] = "7aiOPJapXF";

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
    uint8_t buf[4096];
    uint8_t* buf_ptr = buf;

    if (call RawPacketQueue.size() == 0) return;

    raw = call RawPacketQueue.dequeue();

    {
      uint8_t i;
      printf("id: ");
      for (i=0; i<8; i++) {
        printf("%02x:", raw.id.data[i]);
      }
      printf("\n");
      printf("seq_no: %i\n", raw.seq_no);
      printf("counter: %i\n", raw.counter);
      printf("version: %i\n", raw.version);
    }

    // Send raw to GATD
    pkt_header.type = DATA_TYPE_RAW;
    memcpy(buf_ptr, (uint8_t*) &pkt_header, sizeof(pkt_header));
    buf_ptr += sizeof(pkt_header);
    memcpy(buf_ptr, (uint8_t*) &raw, sizeof(raw));
    call GatdSocket.send(buf, sizeof(pkt_header) + sizeof(raw));

    // process the packet for the power measurement
    // send that result to gatd

    // Re post task to process the rest of the queue
    post process_queue_task();
  }

  // Got a new packet from the 802.15.4 radio from hopefully a coilcube node
  event message_t* Receive.receive (message_t* msg,
                                    void* payload,
                                    uint8_t len) {
    uint8_t* pkt_buf = (uint8_t*) msg;
    uint8_t* data;
    error_t err;
    cc_pkt_data_t* cc_pkt_data;

    timestamp_metadata_t* meta_timestamp;
    struct ieee154_frame_addr in_frame;

    cc_raw_pkt_t raw_pkt;

    // Check that the length is correct for a coilcube packet
    if (pkt_buf[0] != STD_COILCUBE_PKT_LENGTH) {
      printf("Received a non coilcube packet (bad length).\n");
      return msg;
    }

    // Get the timestamp from the radio driver
    meta_timestamp = &(((cc2520packet_metadata_t*) msg->metadata)->timestamp);
    raw_pkt.timestamp = bswap_64(meta_timestamp->timestamp_micro);

    // Get all of the address fields
    data = unpack_ieee154_hdr(pkt_buf, &in_frame);

    // Check if extended source addressing was used
    // If not, disregard this packet
    if (in_frame.ieee_src.ieee_mode != IEEE154_ADDR_EXT) {
      uint8_t i;
      printf("Received a non coilcube packet (bad address).\n");
      for (i=0; i<16; i++) {
        printf("%02x ", pkt_buf[i]);
      }
      printf("\n");
      return msg;
    }

    // Copy the id into the raw struct
    memcpy(raw_pkt.id.data, &in_frame.ieee_src.i_laddr, sizeof(ieee_eui64_t));

    // Copy the seq_no into the raw struct
    raw_pkt.seq_no = pkt_buf[3];

    // Get the payload data
    cc_pkt_data = (cc_pkt_data_t*) data;
    raw_pkt.version = cc_pkt_data->version;
    raw_pkt.counter = cc_pkt_data->counter;

    // Enqueue the raw packet
    err = call RawPacketQueue.enqueue(raw_pkt);
    if (err != SUCCESS) {
      // Queue was full
      fprintf(stderr, "Error enqueuing new raw packet, queue was full.\n");
    }

    // Post a task to start processing the queue
    post process_queue_task();

    return msg;

  }

  event void GatdSocket.receive (uint8_t* msg, int len) { }

  event void RadioControl.stopDone (error_t err) { }
  event void Send.sendDone (message_t* msg, error_t err) { }
}

