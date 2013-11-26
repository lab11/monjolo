/**
 * \addtogroup cc2538
 * @{
 *
 * \defgroup cc2538-examples cc2538dk Example Projects
 * @{
 *
 * \defgroup cc2538-demo cc2538dk Demo Project
 *
 *   Example project demonstrating the cc2538dk functionality
 *
 *
 * @{
 *
 * \file
 *     Example demonstrating the cc2538dk platform
 */
#include "coilcube_ip.h"
#include "contiki.h"
#include "cpu.h"
#include "sys/etimer.h"
#include "sys/rtimer.h"
#include "dev/leds.h"
#include "dev/uart.h"
#include "dev/button-sensor.h"
#include "dev/watchdog.h"
#include "dev/serial-line.h"
#include "dev/sys-ctrl.h"
#include "net/rime/broadcast.h"
#include "net/uip.h"
#include "net/uip-udp-packet.h"
#include "net/uiplib.h"
#include "net/uip-ds6-route.h"
#include "net/uip-ds6-nbr.h"
#include "adc.h"
#include "gpio.h"
#include "fm25lb.h"
#include "ioc.h"

#include <stdio.h>
#include <stdint.h>

/*---------------------------------------------------------------------------*/
#define MACDEBUG 0

#define DEBUG 1
#if DEBUG
#include <stdio.h>
#define PRINTF(...) printf(__VA_ARGS__)
#define PRINT6ADDR(addr) PRINTF(" %02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x ", ((uint8_t *)addr)[0], ((uint8_t *)addr)[1], ((uint8_t *)addr)[2], ((uint8_t *)addr)[3], ((uint8_t *)addr)[4], ((uint8_t *)addr)[5], ((uint8_t *)addr)[6], ((uint8_t *)addr)[7], ((uint8_t *)addr)[8], ((uint8_t *)addr)[9], ((uint8_t *)addr)[10], ((uint8_t *)addr)[11], ((uint8_t *)addr)[12], ((uint8_t *)addr)[13], ((uint8_t *)addr)[14], ((uint8_t *)addr)[15])
#define PRINTLLADDR(lladdr) PRINTF(" %02x:%02x:%02x:%02x:%02x:%02x ",lladdr->addr[0], lladdr->addr[1], lladdr->addr[2], lladdr->addr[3],lladdr->addr[4], lladdr->addr[5])
#else
#define PRINTF(...)
#define PRINT6ADDR(addr)
#endif


static uip_ipaddr_t my_addr;
static uip_ipaddr_t dest_addr;
static uip_ipaddr_t bcast_ipaddr;
static uip_lladdr_t bcast_lladdr = {{0, 0, 0, 0, 0, 0, 0, 0}};
static struct uip_udp_conn *client_conn;

pkt_data_t pkt_data = {PROFILE_ID, SEHNSOR_VERSION, 0, 0};
fram_data_t fram_data;

PROCESS(ipv6_process, "IPv6 process");
AUTOSTART_PROCESSES(&ipv6_process);

/*---------------------------------------------------------------------------*/
PROCESS_THREAD(ipv6_process, ev, data)
{
  uint16_t timing_value;
  uint32_t val;

  PROCESS_BEGIN();

  GPIO_SET_OUTPUT(GPIO_B_BASE, GPIO_PIN_MASK(4));
  GPIO_CLR_PIN(GPIO_B_BASE, GPIO_PIN_MASK(4));

  // Set the local address
  uip_ip6addr(&my_addr, 0, 0, 0, 0, 0, 0, 0, 0);
  uip_ds6_set_addr_iid(&my_addr, &uip_lladdr);
  uip_ds6_addr_add(&my_addr, 0, ADDR_MANUAL);

  // Setup the destination address
  uiplib_ipaddrconv(RECEIVER_ADDR, &dest_addr);

  // Add a "neighbor" for our custom route
  // Setup the default broadcast route
  uiplib_ipaddrconv(ADDR_ALL_ROUTERS, &bcast_ipaddr);
  uip_ds6_nbr_add(&bcast_ipaddr, &bcast_lladdr, 0, NBR_REACHABLE);
  uip_ds6_route_add(&dest_addr, 128, &bcast_ipaddr);

  // Setup a udp "connection"
  client_conn = udp_new(&dest_addr, UIP_HTONS(RECEIVER_PORT), NULL);
  if (client_conn == NULL) {
    // Too many udp connections
    // not sure how to exit...stupid contiki
  }
  udp_bind(client_conn, UIP_HTONS(3001));

  GPIO_SET_PIN(GPIO_B_BASE, GPIO_PIN_MASK(4));

  // Read the FRAM to get the previous state
  fm25lb_read(FRAM_ADDR_COUNT, sizeof(fram_data_t), (uint8_t*) &fram_data);

  GPIO_CLR_PIN(GPIO_B_BASE, GPIO_PIN_MASK(4));

  // We wokeup so increment the counter
  fram_data.counter++;

  // 32 MHz baby!
//  val = SYS_CTRL_CLOCK_CTRL_OSC32K |
//        SYS_CTRL_CLOCK_CTRL_OSC_PD |
//        SYS_CTRL_CLOCK_CTRL_IO_DIV_8MHZ |
//        SYS_CTRL_CLOCK_CTRL_SYS_DIV_8MHZ;
//  REG(SYS_CTRL_CLOCK_CTRL) = val;
//  while((REG(SYS_CTRL_CLOCK_STA) & SYS_CTRL_CLOCK_STA_OSC) != 0);

  // Read the timing capacitor
  adc_configure_single(ADC_12_BIT, ADC_REF_INTERNAL);
  timing_value = adc_sample_single(ADC_CHANNEL_AIN0);
  //timing_value = adc_sample_single(ADC_CHANNEL_AIN7);

  ioc_set_over(GPIO_A_NUM, 0, IOC_OVERRIDE_ANA);
  //ioc_set_over(GPIO_A_NUM, 7, IOC_OVERRIDE_ANA);
  GPIO_SET_OUTPUT(GPIO_C_BASE, GPIO_PIN_MASK(0));
  //GPIO_SET_PIN(GPIO_C_BASE, GPIO_PIN_MASK(0));
  GPIO_CLR_PIN(GPIO_C_BASE, GPIO_PIN_MASK(0));

  GPIO_SET_PIN(GPIO_B_BASE, GPIO_PIN_MASK(4));

  // check adc reading
  if (timing_value < 0x200 || 1) {
    // send packet
    fram_data.seq_no++;

    pkt_data.counter = (uint8_t) (timing_value >> 8);
    pkt_data.seq_no = fram_data.seq_no;

    GPIO_CLR_PIN(GPIO_B_BASE, GPIO_PIN_MASK(4));

    uip_udp_packet_send(client_conn, (uint8_t*) &pkt_data, sizeof(pkt_data_t));

    GPIO_SET_PIN(GPIO_B_BASE, GPIO_PIN_MASK(4));

    fm25lb_write(FRAM_ADDR_COUNT, sizeof(fram_data_t), (uint8_t*) &fram_data);

    GPIO_CLR_PIN(GPIO_B_BASE, GPIO_PIN_MASK(4));

  } else {
    // Just write the counter back
    fm25lb_write(FRAM_ADDR_COUNT, 1, (uint8_t*) &fram_data.counter);
  }




  PROCESS_END();
}
/*---------------------------------------------------------------------------*/