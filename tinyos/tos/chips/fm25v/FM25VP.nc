/**
 * @author Brad Campbell <bradjc@umich.edu>
 */

#include "fm25v.h"

generic module FM25VP () {
  provides {
    interface Init @exactlyonce();
    interface FM25V;
  }
  uses {
    interface Resource as SpiResource;
    interface SpiByte;
    interface SpiPacket;

    interface GeneralIO as CSN;
    interface GeneralIO as Hold;
    interface GeneralIO as WP;
  }
}
implementation {


  fm25v_state_e state;

  // Current command state for persisting through callbacks
  uint32_t cmd_addr;
  uint32_t cmd_len;
  uint8_t* cmd_buf;
  uint8_t  cmd[4];

  error_t _err;


  void write_enable ();

  task void state_machine ();



  // Send a the command byte to the FRAM. Must have access to the spi bus.
  void write_enable () {
    call SpiByte.write(FM25V_CMD_WRITE_ENABLE);
  }

  void fill_cmd_buffer (uint8_t fm25v_command, uint32_t addr) {
    cmd[0] = fm25v_command;
    cmd[1] = (addr >> 16) & 0x3;
    cmd[2] = (addr >> 8) & 0xFF;
    cmd[3] = addr & 0xFF;
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

  command error_t FM25V.read (uint32_t addr, uint8_t* buf, uint32_t len) {
    state      = FM25V_STATE_READ;
    cmd_addr   = addr;
    cmd_len    = len;
    cmd_buf    = buf;

    return call SpiResource.request();
  }

  command error_t FM25V.write (uint32_t addr, uint8_t* buf, uint32_t len) {
    state      = FM25V_STATE_WRITE;
    cmd_addr   = addr;
    cmd_len    = len;
    cmd_buf    = buf;

    return call SpiResource.request();
  }




  ////////////////////////
  // TASKS
  ////////////////////////

  task void state_machine () {

    error_t local_error;

    atomic local_error = _err;

    switch (state) {
      // READ
      case FM25V_STATE_READ:
        state = FM25V_STATE_READ_SENT_CMD;
        call CSN.clr();
        fill_cmd_buffer(FM25V_CMD_READ, cmd_addr);
        call SpiPacket.send(cmd, NULL, 4);
        break;

      case FM25V_STATE_READ_SENT_CMD:
        state = FM25V_STATE_READ_DONE;
        call SpiPacket.send(NULL, cmd_buf, cmd_len);
        break;

      case FM25V_STATE_READ_DONE:
        state = FM25V_STATE_DONE;
        call CSN.set();
        call SpiResource.release();
        signal FM25V.readDone(cmd_addr, cmd_buf, cmd_len, local_error);
        break;

      // WRITE
      case FM25V_STATE_WRITE:
        state = FM25V_STATE_WRITE_SENT_CMD;
        call CSN.clr();
        call WP.set();
        write_enable();
        // Toggle the chip select line between the write enable bit and the
        // actual write command
        call CSN.set();
        call CSN.clr();
        fill_cmd_buffer(FM25V_CMD_WRITE, cmd_addr);
        call SpiPacket.send(cmd, NULL, 4);
        break;

      case FM25V_STATE_WRITE_SENT_CMD:
        state = FM25V_STATE_WRITE_DONE;
        call SpiPacket.send(cmd_buf, NULL, cmd_len);
        break;

      case FM25V_STATE_WRITE_DONE:
        state = FM25V_STATE_DONE;
        call WP.clr();
        call CSN.set();
        call SpiResource.release();
        signal FM25V.writeDone(cmd_addr, cmd_buf, cmd_len, local_error);
        break;

      case FM25V_STATE_DONE:
        break;

    }

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

  default event void FM25V.readDone(uint32_t addr, uint8_t* buf,
    uint32_t len, error_t err) {}
  default event void FM25V.writeDone(uint32_t addr, uint8_t* buf,
    uint32_t len, error_t err) {}

}
