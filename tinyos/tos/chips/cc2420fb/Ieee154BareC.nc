
/* Provides an abstraction layer for complete access to an 802.15.4 packet
 * buffer. Packets provided to this module will be interpreted as 802.15.4
 * frames and will NOT have the sequence number set. All other fields must be set
 * by upper layers.
 */

configuration Ieee154BareC {
  provides {
    interface SplitControl;

    interface Packet as BarePacket;
    interface Send as BareSend;
    interface Receive as BareReceive;
  }
}

implementation {
  components CC2420FbRadioC;
  components Ieee154BareP;

  Ieee154BareP.RadioState -> CC2420FbRadioC.RadioState;
  Ieee154BareP.RadioSend -> CC2420FbRadioC.RadioSend;
  Ieee154BareP.RadioReceive -> CC2420FbRadioC.RadioReceive;
  Ieee154BareP.RadioPacket -> CC2420FbRadioC.RadioPacket;

  SplitControl = Ieee154BareP.SplitControl;

  BarePacket = Ieee154BareP.BarePacket;
  BareSend = Ieee154BareP.BareSend;
  BareReceive = Ieee154BareP.BareReceive;
}
