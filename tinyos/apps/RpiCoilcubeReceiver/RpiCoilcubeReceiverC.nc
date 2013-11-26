#include "coilcube_packet.h"

configuration RpiCoilcubeReceiverC {}
implementation {
  components MainC;
  components RpiCoilcubeReceiverP as App;
  components LedsC;

  components Ieee154BareC;

  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;

  App.RadioControl -> Ieee154BareC.SplitControl;
  App.Receive -> Ieee154BareC.BareReceive;
  App.Send -> Ieee154BareC.BareSend;

  components new PersistentTcpConnectionC() as TcpConn;
  App.GatdSocket -> TcpConn.TcpSocket;

  components new QueueC(cc_raw_pkt_t, 100) as RawPacketQueue;
  App.RawPacketQueue -> RawPacketQueue.Queue;
}
