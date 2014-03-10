/*
 * @author: Brad Campbell <bradjc@umich.edu>
 */

#include "border.h"
#include "monjolo.h"

module CalibrateBorderP {
  provides {
    interface Init as SoftwareInit @exactlyonce();
    interface IPForward;
  }
  uses {
    interface ForwardingTable;
    interface UnixTime;
  }
}

implementation {

  command error_t SoftwareInit.init() {
    // add a default "route" to the printout
    call ForwardingTable.addRoute(NULL,
                                  0,
                                  NULL,
                                  ROUTE_IFACE_CALIB);

    return SUCCESS;
  }

  command error_t IPForward.send (struct in6_addr *next_hop,
                                  struct ip6_packet *msg,
                                  void *data) {
    size_t len;
    uint8_t buf[4096];
    uint8_t* d;
    pkt_data_t* ccpkt;
    uint64_t timestamp;
    uint8_t i;
    uint64_t id = 0;
    char mac[25];

    timestamp = call UnixTime.getMicroseconds();

    len = iov_len(msg->ip6_data);

    iov_read(msg->ip6_data, 0, len, buf);

    d = (uint8_t*) (((struct udp_hdr*) buf) + 1);

    ccpkt = (pkt_data_t*) d;

    msg->ip6_hdr.ip6_src.s6_addr[8] = msg->ip6_hdr.ip6_src.s6_addr[8] ^ 0x02;

    for (i=8; i<16; i++) {
      id += ((uint64_t) msg->ip6_hdr.ip6_src.s6_addr[i]) << (8*(15-i));
      sprintf(mac+((i-8)*3), "%02x:", msg->ip6_hdr.ip6_src.s6_addr[i]);
    }
    mac[23] = '\0';

    printf("{\"type\":\"coilcube\",");
    printf("\"id\":%llu,", id);
    printf("\"mac\":\"%s\",", mac);
    printf("\"timestamp\":%llu,", timestamp);
    printf("\"version\":%i,", ccpkt->version);
    printf("\"seq_no\":%i,", ccpkt->seq_no);
    printf("\"counter\":%i}\n", ccpkt->counter);

    return SUCCESS;
  }

}
