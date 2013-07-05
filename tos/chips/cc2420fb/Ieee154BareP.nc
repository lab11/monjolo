
module Ieee154BareP {
  provides {
    interface SplitControl;

    interface Packet as BarePacket;
    interface Send as BareSend;
    interface Receive as BareReceive;
  }
  uses {
    interface RadioState;
    interface RadioSend;
    interface RadioReceive;
    interface RadioPacket;
  }
}

implementation {

  // ---- SplitControl

  typedef enum {
    TURNING_ON,
    TURNING_OFF,
    DEFAULT_STATE,
  } state_e;

  state_e rstate;

  task void split_control_task () {
    switch (rstate) {
      case TURNING_ON:
        rstate = DEFAULT_STATE;
        signal SplitControl.startDone(SUCCESS);
        break;

      case TURNING_OFF:
        rstate = DEFAULT_STATE;
        signal SplitControl.stopDone(SUCCESS);
        break;
    }
  }

  command error_t SplitControl.start () {
    rstate = TURNING_ON;
    return call RadioState.turnOn();
  }

  command error_t SplitControl.stop () {
    rstate = TURNING_OFF;
    return call RadioState.turnOff();
  }

  tasklet_async event void RadioState.done () {
    post split_control_task();
  }


  // ---- Packet as BarePacket

  command void BarePacket.clear(message_t* msg) {
    call RadioPacket.clear(msg);
  }

  command uint8_t BarePacket.payloadLength(message_t* msg) {
    return call RadioPacket.payloadLength(msg);
  }

  command void BarePacket.setPayloadLength(message_t* msg, uint8_t len) {
    call RadioPacket.setPayloadLength(msg, len);
  }

  command uint8_t BarePacket.maxPayloadLength() {
    return call RadioPacket.maxPayloadLength();
  }

  command void* BarePacket.getPayload(message_t* msg, uint8_t len) {
    return (void*) msg;
  }


  // ---- Send as BareSend

  message_t* BareSend_msg;
  error_t BareSend_err;

  task void send_sendDone () {
    message_t* m;
    error_t e;

    atomic {
      m = BareSend_msg;
      e = BareSend_err;
    }
    signal BareSend.sendDone(m, e);
  }

  command error_t BareSend.send(message_t* msg, uint8_t len) {
    atomic BareSend_msg = msg;
    return call RadioSend.send(msg);
  }

  command error_t BareSend.cancel(message_t* msg) {
    return FAIL;
  }

  tasklet_async event void RadioSend.sendDone(error_t error) {
    atomic BareSend_err = error;
    post send_sendDone();
  }

  tasklet_async event void RadioSend.ready () { }

  command uint8_t BareSend.maxPayloadLength() {
    return call RadioPacket.maxPayloadLength();
  }

  command void* BareSend.getPayload(message_t* msg, uint8_t len) {
    return (void*) msg;
  }


  // ---- Receive as BareReceive

  message_t* BareReceive_msg;

//  task receive_task () {
//    event message_t* receive(message_t* msg, void* payload, uint8_t len);
//  }

  tasklet_async event bool RadioReceive.header(message_t* msg) {
    return TRUE;
  }

  tasklet_async event message_t* RadioReceive.receive(message_t* msg) {
    atomic BareReceive_msg = msg;
   // post receive_task();
    return signal BareReceive.receive(msg, msg, ((uint8_t*) msg)[0]+1);
  }

}
