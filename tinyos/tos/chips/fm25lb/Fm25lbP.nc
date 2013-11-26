/**
 * @author Samuel DeBruin <sdebruin@umich.edu>
 */

#include "Fm25lb.h"

module Fm25lbP {
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

  uint8_t m_cmd[3];
  uint8_t m_cmd_len;
  uint8_t* m_buf;
  fm25lb_len_t m_len;

  uint8_t* tx_buf_spidone;

  typedef enum {
    WREN = 0x06,
    WRDI = 0x04,
    RDSR = 0x05,
    WRSR = 0x01,
    READ = 0x03,
    WRITE = 0x02,
  } fm25lb_cmd_t;

  void signalDone(error_t err);

  void sendCmd(uint8_t cmd) {
    call CSN.clr();
    call SpiByte.write(cmd);
    call CSN.set();
    return;
  }

  command error_t Init.init() {
    call CSN.makeOutput();
    call Hold.makeOutput();
    call WP.makeOutput();
    call CSN.set();
    call Hold.set();
    call WP.set();
    return SUCCESS;
  }

  event void SpiResource.granted() {
    if(m_cmd[0] == WRITE || m_cmd[0] == WRSR) {
      sendCmd(WREN);
    }

    call CSN.clr();
    call SpiPacket.send(m_cmd, NULL, m_cmd_len);
  }

  command error_t Fm25lb.writeEnable() {
    error_t err = SUCCESS;
    m_cmd[0] = WREN;
    m_cmd_len = 1;

    call SpiResource.request();

    return err;
  }

  command error_t Fm25lb.read(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len) {
    error_t err = SUCCESS;
    m_cmd[0] = READ;
    m_cmd[1] = addr;
    //m_cmd[2] = 0x00;  //Second address byte does not apply to 4KB FRAM
    //m_cmd_len = 3;
    m_cmd_len = 2;
    m_buf = buf;
    m_len = len;

    call SpiResource.request();

    return err;
  }

  command error_t Fm25lb.write(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len) {
    error_t err = SUCCESS;
    m_cmd[0] = WRITE;
    m_cmd[1] = addr;
    //m_cmd[2] = 0x00;  //Second address byte does not apply to 4KB FRAM
    //m_cmd_len = 3;
    m_cmd_len = 2;
    m_buf = buf;
    m_len = len;

    call WP.set();

    call SpiResource.request();

    return err;
  }

  command error_t Fm25lb.readStatus(uint8_t* buf) {
    error_t err = SUCCESS;
    m_cmd[0] = RDSR;
    m_cmd_len = 1;
    m_buf = buf;
    m_len = 1;

    call SpiResource.request();

    return err;
  }

  command error_t Fm25lb.writeStatus(uint8_t* buf) {
    error_t err = SUCCESS;
    m_cmd[0] = WRSR;
    m_cmd_len = 1;
    m_buf = buf;
    m_len = 1;

    call SpiResource.request();

    return err;
  }

  task void spiSendDone () {
    uint8_t* txBuf;

    atomic txBuf = tx_buf_spidone;

    if(txBuf == m_cmd) {
      if(m_cmd[0] == WREN) {
        call CSN.set();
        call SpiResource.release();
        signalDone(SUCCESS);
      }
      else if(m_cmd[0] == READ || m_cmd[0] == RDSR) {
        call SpiPacket.send(NULL, m_buf, m_len);
      }
      else {
        call SpiPacket.send(m_buf, NULL, m_len);
      }
    }
    else {
      call CSN.set();
      call SpiResource.release();
      signalDone(SUCCESS);
    }
  }

  async event void SpiPacket.sendDone(uint8_t* txBuf,
                                      uint8_t* rxBuf,
                                      uint16_t len,
                                      error_t error) {
    atomic tx_buf_spidone = txBuf;
    post spiSendDone();
  }

  void signalDone(error_t err) {
    switch(m_cmd[0]) {
    case WREN:
      signal Fm25lb.writeEnableDone();
      break;
    case RDSR:
      signal Fm25lb.readStatusDone(m_buf, err);
      break;
    case WRSR:
      signal Fm25lb.writeStatusDone(m_buf, err);
      break;
    case READ:
      signal Fm25lb.readDone(m_cmd[1], m_buf, m_len, err);
      break;
    case WRITE:
      call WP.clr();
      signal Fm25lb.writeDone(m_cmd[1], m_buf, m_len, err);
      break;
    }
  }

  default event void Fm25lb.readDone(fm25lb_addr_t addr, uint8_t* buf,
    fm25lb_len_t len, error_t err) {}
  default event void Fm25lb.writeDone(fm25lb_addr_t addr, uint8_t* buf,
    fm25lb_len_t len, error_t err) {}
  default event void Fm25lb.readStatusDone(uint8_t* buf, error_t err) {}
  default event void Fm25lb.writeStatusDone(uint8_t* buf, error_t err) {}
  default event void Fm25lb.writeEnableDone() {}

}
