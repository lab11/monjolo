

configuration CC2420FbRadioC {
  provides {
    interface RadioState;
    interface RadioSend;
    interface RadioReceive;
    interface RadioPacket;
  }
}

implementation {

  #define UQ_METADATA_FLAGS	"UQ_METADATA_FLAGS"
  #define UQ_RADIO_ALARM		"UQ_RADIO_ALARM"

  components CC2420FbDriverLayerC as RadioDriverLayerC;

// -------- MetadataFlags

  components new MetadataFlagsLayerC() as Meta;
  Meta.SubPacket -> RadioDriverLayerC;

// -------- RadioAlarm

  components new RadioAlarmC();
  RadioAlarmC.Alarm -> RadioDriverLayerC;

// -------- RadioDriver

//  RadioDriverLayerC.TransmitPowerFlag -> Meta.PacketFlag[unique(UQ_METADATA_FLAGS)];
//  RadioDriverLayerC.RSSIFlag -> Meta.PacketFlag[unique(UQ_METADATA_FLAGS)];
//  RadioDriverLayerC.TimeSyncFlag -> Meta.PacketFlag[unique(UQ_METADATA_FLAGS)];
  RadioDriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];


// ---- External
  RadioState = RadioDriverLayerC.RadioState;
  RadioSend = RadioDriverLayerC.RadioSend;
  RadioReceive = RadioDriverLayerC.RadioReceive;
  RadioPacket = RadioDriverLayerC.RadioPacket;
}
