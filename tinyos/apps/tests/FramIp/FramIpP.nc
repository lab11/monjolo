#include "Timer.h"
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

module FramIpP {
  uses {
    interface Boot;
    interface Fm25lb as Fram;
    interface Timer<TMilli>;

    interface SplitControl as BlipControl;
    interface UDP as UDPService;
    interface ForwardingTable;
  }
}

implementation {

#define RECEIVER "2001:470:1f10:1320::2"
#define PORT 4001
//uint16_t PORT = 0xf0AA;

#define ALL_ROUTERS "ff02::2"

  struct sockaddr_in6 dest; // Where to send the packet
  struct in6_addr next_hop;

#define BYTES_TO_READ 64

  uint8_t buffer[BYTES_TO_READ];

  void send () {
    call Fram.read(0, buffer, BYTES_TO_READ);
  }

  event void Boot.booted () {
    inet_pton6("ff02::1", &dest.sin6_addr);
    dest.sin6_port = htons(PORT);

    call BlipControl.start();
  }

  event void BlipControl.startDone (error_t error) {
    call Fram.read(0, buffer, BYTES_TO_READ);
  }

  event void Fram.readDone(fm25lb_addr_t addr, uint8_t* buf,
    fm25lb_len_t len, error_t err) {

    buffer[0]++;
    buffer[2]++;
    buffer[3]++;
    buffer[6]++;
    buffer[8]+=2;

    call Fram.write(0, buffer, BYTES_TO_READ);
  }

  event void Fram.writeDone(fm25lb_addr_t addr,
                            uint8_t* buf,
                            fm25lb_len_t len,
                            error_t err) {
    err = call UDPService.sendto(&dest, buffer, 10);
    call Timer.startOneShot(10000);
  }

  event void Timer.fired () {
    call Fram.read(0, buffer, BYTES_TO_READ);
  }

  event void Fram.readStatusDone(uint8_t* buf, error_t err) {}
  event void Fram.writeStatusDone(uint8_t* buf, error_t err) {}
  event void Fram.writeEnableDone() {}

  event void BlipControl.stopDone (error_t error) {
  }

  event void UDPService.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) { }

}
