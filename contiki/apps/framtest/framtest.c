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
#include "fm25lb.h"

#include <stdio.h>
#include <stdint.h>
/*---------------------------------------------------------------------------*/
#define LOOP_INTERVAL       CLOCK_SECOND
#define LEDS_OFF_HYSTERISIS (RTIMER_SECOND >> 1)
#define LEDS_PERIODIC       LEDS_YELLOW
#define LEDS_BUTTON         LEDS_RED
#define LEDS_SERIAL_IN      LEDS_ORANGE
#define LEDS_REBOOT         LEDS_ALL
#define LEDS_RF_RX          (LEDS_YELLOW | LEDS_ORANGE)
#define BROADCAST_CHANNEL   129
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

#define PING6_NB 5
#define PING6_DATALEN 16

#define UIP_IP_BUF   ((struct uip_ip_hdr *)&uip_buf[UIP_LLH_LEN])
#define UIP_ICMP_BUF ((struct uip_icmp_hdr *)&uip_buf[uip_l2_l3_hdr_len])

static uip_ipaddr_t my_addr;
static uip_ipaddr_t dest_addr;
static uip_ipaddr_t bcast_ipaddr;
static uip_lladdr_t bcast_lladdr = {{0, 0, 0, 0, 0, 0, 0, 0}};
static struct uip_udp_conn *client_conn;

pkt_data_t pkt_data = {PROFILE_ID, SEHNSOR_VERSION, 0, 0};

static struct etimer periodic_timer;

PROCESS(ipv6_process, "IPv6 process");
AUTOSTART_PROCESSES(&ipv6_process);

uint8_t spibuf[100];

static void
recv_handler(void)
{
  char *str;

  if (uip_newdata()) {
    str = uip_appdata;
    str[uip_datalen()] = '\0';
    printf("Response from the server: '%s'\n", str);
  }
}

/*---------------------------------------------------------------------------*/
static void
send_handler(process_event_t ev, process_data_t data)
{
  int i;
  pkt_data.counter = spibuf[0];
  pkt_data.seq_no = 9;

  PRINTF("Sending UDP!!! packet\n");
  uip_udp_packet_send(client_conn, (uint8_t*) &pkt_data, sizeof(pkt_data_t));

  for (i=0; i<10; i++) {
    spibuf[i]++;
  }

  PRINTF("After sent udp packet.\n");
}

/*---------------------------------------------------------------------------*/
PROCESS_THREAD(ipv6_process, ev, data)
{


  PROCESS_BEGIN();

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

  etimer_set(&periodic_timer, 1*CLOCK_SECOND);

  while(1) {
    PROCESS_YIELD();

    if (etimer_expired(&periodic_timer)) {
      fm25lb_read(0, 10, spibuf);
      send_handler(ev, data);
      fm25lb_write(0, 10, spibuf);
      etimer_restart(&periodic_timer);
    } else if (ev == tcpip_event) {
      recv_handler();
    }
  }

  PROCESS_END();
}
/*---------------------------------------------------------------------------*/