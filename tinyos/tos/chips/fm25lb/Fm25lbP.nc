/**
 * @author Samuel DeBruin <sdebruin@umich.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

#include "Fm25lb.h"

generic module Fm25lbP () {
  provides {
    interface Init @exactlyonce();
    interface Fm25lb;
  }
  uses {
    interface Resource as SpiResource;
    interface GeneralIO as CSN;
    interface GeneralIO as Hold;
    interface GeneralIO as WP;
    interface SpiByte;
    interface SpiPacket;
  }
}
implementation {


  fm25lb_state_e _state;

  // Current command state for persisting through callbacks
  uint8_t  _cmd_buf[2];
  uint8_t* _buf;
  uint16_t _len;
  error_t  _err;

  void write_enable ();

  task void state_machine ();



  // Send a the command byte to the FRAM. Must have access to the spi bus.
  void write_enable () {
    call SpiByte.write(FM25LB_CMD_WRITE_ENABLE);
  }

  // Called to initialize the GPIO pins for the FRAM
  command error_t Init.init() {
    call CSN.makeOutput();
    call Hold.makeOutput();
    call WP.makeOutput();
    call CSN.set();
    call Hold.set();
    call WP.set();
    return SUCCESS;
  }

  ////////////////////////
  // PUBLIC FUNCTIONS
  ////////////////////////

  command error_t Fm25lb.read (uint16_t addr, uint8_t* buf, uint16_t len) {
    // Setup the read call by setting the state and filling the command buffer
    _state      = FM25LB_STATE_READ_GOT_SPI;
    _cmd_buf[0] = FM25LB_ADD_ADDRESS_BIT(addr, FM25LB_CMD_READ);
    _cmd_buf[1] = (uint8_t) addr;
    _buf        = buf;
    _len        = len;

    return call SpiResource.request();
  }

  command error_t Fm25lb.write (uint16_t addr, uint8_t* buf, uint16_t len) {
    _state      = FM25LB_STATE_WRITE_GOT_SPI;
    _cmd_buf[0] = FM25LB_ADD_ADDRESS_BIT(addr, FM25LB_CMD_WRITE);
    _cmd_buf[1] = (uint8_t) addr;
    _buf        = buf;
    _len        = len;

    return call SpiResource.request();
  }

  command error_t Fm25lb.readStatus () {
    _state      = FM25LB_STATE_READ_STATUS_GOT_SPI;
    _cmd_buf[0] = FM25LB_CMD_READ_STATUS;

    return call SpiResource.request();
  }

  command error_t Fm25lb.writeStatus (uint8_t status) {
    _state      = FM25LB_STATE_READ_STATUS_GOT_SPI;
    _cmd_buf[0] = FM25LB_CMD_WRITE_STATUS;
    _cmd_buf[1] = status;

    return call SpiResource.request();
  }

  command error_t Fm25lb.blockingRead (uint16_t addr,
                                       uint8_t* buf,
                                       uint16_t len) {
    int i;

    // First get access to the SPI bus
    while (1) {
      error_t err = call SpiResource.immediateRequest();
      if (err == SUCCESS) break;
    }

    // Now set CS low
    call CSN.clr();

    // Send the command and address
    call SpiByte.write(FM25LB_ADD_ADDRESS_BIT(addr, FM25LB_CMD_READ));
    call SpiByte.write(addr);

    for (i=0; i<len; i++) {
      buf[i] = call SpiByte.write(0);
    }

    call CSN.set();
    call SpiResource.release();
  }

  command error_t Fm25lb.blockingWrite (uint16_t addr,
                                       uint8_t* buf,
                                       uint16_t len) {
    int i;

    // First get access to the SPI bus
    while (1) {
      error_t err = call SpiResource.immediateRequest();
      if (err == SUCCESS) break;
    }

    // Now set CS low
    call CSN.clr();

    call SpiByte.write(FM25LB_CMD_WRITE_ENABLE);

    // Toggle the CS bit between the write enable and write command
    call CSN.set();
    call CSN.clr();

    // Send the command and address
    call SpiByte.write(FM25LB_ADD_ADDRESS_BIT(addr, FM25LB_CMD_WRITE));
    call SpiByte.write(addr);

    for (i=0; i<len; i++) {
      call SpiByte.write(buf[i]);
    }

    call CSN.set();
    call SpiResource.release();
  }

  ////////////////////////
  // EVENTS
  ////////////////////////

  event void SpiResource.granted () {
    post state_machine();
  }

  async event void SpiPacket.sendDone (uint8_t* txBuf,
                                       uint8_t* rxBuf,
                                       uint16_t len,
                                       error_t error) {
    atomic _err = error;
    post state_machine();
  }


  ////////////////////////
  // TASKS
  ////////////////////////

  task void state_machine () {

    error_t local_error;

    atomic local_error = _err;

    switch (_state) {
      // READ
      case FM25LB_STATE_READ_GOT_SPI:
        _state = FM25LB_STATE_READ_SENT_CMD;
        call CSN.clr();
        call SpiPacket.send(_cmd_buf, NULL, FM25LB_READ_CMD_LEN);
        break;

      case FM25LB_STATE_READ_SENT_CMD:
        _state = FM25LB_STATE_READ_DONE;
        call SpiPacket.send(NULL, _buf, _len);
        break;

      case FM25LB_STATE_READ_DONE:
        _state = FM25LB_STATE_DONE;
        call CSN.set();
        call SpiResource.release();
        signal Fm25lb.readDone(FM25LB_GET_ADDRESS(_cmd_buf[0], _cmd_buf[1]),
                               _buf, _len, local_error);
        break;

      // WRITE
      case FM25LB_STATE_WRITE_GOT_SPI:
        _state = FM25LB_STATE_WRITE_SENT_CMD;
        call CSN.clr();
        call WP.set();
        write_enable();
        // Toggle the chp select line between the write enable bit and the
        // actual write command
        call CSN.set();
        call CSN.clr();
        call SpiPacket.send(_cmd_buf, NULL, FM25LB_WRITE_CMD_LEN);
        break;

      case FM25LB_STATE_WRITE_SENT_CMD:
        _state = FM25LB_STATE_WRITE_DONE;
        call SpiPacket.send(_buf, NULL, _len);
        break;

      case FM25LB_STATE_WRITE_DONE:
        _state = FM25LB_STATE_DONE;
        call WP.clr();
        call CSN.set();
        call SpiResource.release();
        signal Fm25lb.writeDone(FM25LB_GET_ADDRESS(_cmd_buf[0], _cmd_buf[1]),
                                _buf, _len, local_error);
        break;

      // READ STATUS
      case FM25LB_STATE_READ_STATUS_GOT_SPI:
        _state = FM25LB_STATE_READ_STATUS_DONE;
        call CSN.clr();
        call SpiPacket.send(_cmd_buf, _cmd_buf, FM25LB_READ_STATUS_CMD_LEN+
                                                FM25LB_READ_STATUS_DATA_LEN);
        break;

      case FM25LB_STATE_READ_STATUS_DONE:
        _state = FM25LB_STATE_DONE;
        call CSN.set();
        call SpiResource.release();
        signal Fm25lb.readStatusDone(_cmd_buf[1], local_error);
        break;

      // WRITE STATUS
      case FM25LB_STATE_WRITE_STATUS_GOT_SPI:
        _state = FM25LB_STATE_WRITE_STATUS_DONE;
        call CSN.clr();
        call SpiPacket.send(_cmd_buf, NULL, FM25LB_WRITE_STATUS_CMD_LEN+
                                            FM25LB_WRITE_STATUS_DATA_LEN);
        break;

      case FM25LB_STATE_WRITE_STATUS_DONE:
        _state = FM25LB_STATE_DONE;
        call CSN.set();
        call SpiResource.release();
        signal Fm25lb.writeStatusDone(local_error);
        break;

      case FM25LB_STATE_DONE:
        break;

    }

  }

  default event void Fm25lb.readDone(uint16_t addr, uint8_t* buf,
    uint16_t len, error_t err) {}
  default event void Fm25lb.writeDone(uint16_t addr, uint8_t* buf,
    uint16_t len, error_t err) {}
  default event void Fm25lb.readStatusDone(uint8_t status, error_t err) {}
  default event void Fm25lb.writeStatusDone(error_t err) {}

}
