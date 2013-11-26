#include "ieee154_header.h"


module RpiCalibrateCCP {
  uses {
    interface Boot;
    interface Leds;

    interface SplitControl as RadioControl;
    interface Receive;
    interface Send;

    interface UartBuffer;
  }
}
implementation {

#define STD_COILCUBE_PKT_LENGTH 18

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone (error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
  }


  event message_t* Receive.receive (message_t* msg,
                                    void* payload,
                                    uint8_t len) {
    uint8_t* pkt_buf = (uint8_t*) msg;
    uint8_t* data;
    uint8_t seq_no, counter;
    uint8_t i;
    uint64_t id = 0;

    struct ieee154_frame_addr in_frame;

    timestamp_metadata_t* meta_timestamp;
    uint64_t timestamp;

    // need to update this to get it from the meta data from the packet
    meta_timestamp = &(((cc2520packet_metadata_t*) msg->metadata)->timestamp);
    timestamp = meta_timestamp->timestamp_micro;

    // Check that the length is correct for a coilcube packet
    if (pkt_buf[0] != STD_COILCUBE_PKT_LENGTH) {
      printf("Received a non coilcube packet (bad length).\n");
      return msg;
    }

    // Get all of the address fields
    data = unpack_ieee154_hdr(pkt_buf, &in_frame);

    // Check if extended source addressing was used
    // If not, disregard this packet
    if (in_frame.ieee_src.ieee_mode != IEEE154_ADDR_EXT) {
      return msg;
    }

    // get seq number
    seq_no = pkt_buf[3];
    counter = data[0];

    for (i=0; i<8; i++) {
      id += ((uint64_t) in_frame.ieee_src.i_laddr.data[i]) << (8*(7-i));
    }

    // Print a JSON blob of the data
    printf("{\"type\":\"coilcube\",");
    printf("\"id\":%llu,", id);
    printf("\"timestamp\":%llu,", timestamp);
    printf("\"seq_no\":%i,", seq_no);
    printf("\"counter\":%i}\n", counter);

    return msg;
  }

  event void UartBuffer.receive (uint8_t* buf,
                                 uint8_t len,
                                 uint64_t timestamp) {
    buf[len] = '\0';
    printf("plm: %llu %s", timestamp, buf);
  }

  event void RadioControl.stopDone (error_t err) { }
  event void Send.sendDone (message_t* msg, error_t err) { }
}

