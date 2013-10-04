#include "Timer.h"
#include "Msp430Adc12.h"
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>

module AdcIpP {
  uses {
    interface Boot;
    interface Timer<TMilli>;

    interface SplitControl as BlipControl;
    interface UDP as UDPService;
    interface ForwardingTable;

    interface AdcConfigure<const msp430adc12_channel_config_t*> as VTimerAdcConfig;
    interface Msp430Adc12SingleChannel as ReadSingleChannel;
    interface Resource as AdcResource;

    interface HplMsp430GeneralIO as TimeControlGPIO;
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

  uint8_t buf[10];


  event void Boot.booted () {
    inet_pton6("ff02::1", &dest.sin6_addr);
    dest.sin6_port = htons(PORT);

    call TimeControlGPIO.makeOutput();
    call TimeControlGPIO.clr();

    call BlipControl.start();
  }

  event void BlipControl.startDone (error_t error) {
    call AdcResource.request();
  }

  event void AdcResource.granted () {
    call ReadSingleChannel.configureSingle(call VTimerAdcConfig.getConfiguration());
    call ReadSingleChannel.getData();
  }

  async event error_t ReadSingleChannel.singleDataReady (uint16_t data) {
    buf[0] = (data >> 8) & 0xFF;
    buf[1] = (data) & 0xFF;
    call UDPService.sendto(&dest, buf, 2);
    call AdcResource.release();
    call Timer.startOneShot(10000);

    if (data < 0x000F) {
      call TimeControlGPIO.set();
      call TimeControlGPIO.clr();
    }
    return SUCCESS;
  }

  event void Timer.fired () {
    call AdcResource.request();
  }

  async event uint16_t* COUNT_NOK(numSamples)
  ReadSingleChannel.multipleDataReady(uint16_t *COUNT(numSamples) buffer,
    uint16_t numSamples) {
    return NULL;
  }

  event void BlipControl.stopDone (error_t error) {
  }

  event void UDPService.recvfrom (struct sockaddr_in6 *from,
                           void *data,
                           uint16_t len,
                           struct ip6_metadata *meta) { }

}
