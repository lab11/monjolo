
module RV3049P {
  provides {
    interface Init @exactlyonce();
    interface RVRTC;
  }
  uses {
    interface GeneralIO as CS;
    interface Resource as SpiResource;
    interface SpiByte;
    interface SpiPacket;
  }
}

implementation {

  rv3049_state_e state;

  uint8_t buf_out[8];
  uint8_t buf_in[8];

  uint8_t binary_to_bcd (uint8_t binary) {
    uint8_t out = 0;

    if (binary > 40) {
      out |= 0x40;
      binary -= 40;
    }
    if (binary > 20) {
      out |= 0x20;
      binary -= 20;
    }
    if (binary > 10) {
      out |= 0x10;
      binary -= 10;
    }
    out |= binary;
    return out;
  }

  command error_t Init.init () {
    call CS.makeOutput();
    call CS.clr();
    return SUCCESS;
  }

  command error_t RVRTC.readTime () {
    state = RV3049_STATE_READ_TIME;
    call SpiResource.request();
    return SUCCESS;
  }

  command error_t RVRTC.setTime (uint8_t seconds,
                                 uint8_t minutes,
                                 uint8_t hours,
                                 uint8_t days,
                                 month_e month,
                                 uint16_t year,
                                 day_e weekday) {

    buf_out[0] = RV3049_SET_WRITE_BIT(RV3049_PAGE_ADDR_CLOCK);
    buf_out[1] = binary_to_bcd(seconds);
    buf_out[2] = binary_to_bcd(minutes);
    buf_out[3] = binary_to_bcd(hours); // 24 hour mode
    buf_out[4] = binary_to_bcd(days);
    buf_out[5] = weekday;
    buf_out[6] = month;
    buf_out[7] = binary_to_bcd(year - 2000);

    state = RV3049_STATE_SET_TIME;
    call SpiResource.request();
    return SUCCESS;
  }


  task void state_machine () {
    switch (state) {
      case RV3049_STATE_READ_TIME:
        state = RV3049_STATE_READ_TIME_DONE;

        buf_out[0] = RV3049_SET_READ_BIT(RV3049_PAGE_ADDR_CLOCK);

        call CS.set();
        call SpiPacket.send(buf_out, buf_in, RV3049_READ_LEN_TIME);
        break;

      case RV3049_STATE_READ_TIME_DONE: {
        uint8_t seconds, minutes, hours, days;
        uint16_t year;
        month_e month;
        day_e day;

        state = RV3049_STATE_DONE;
        call CS.clr();
        call SpiResource.release();

        // Convert output of RTC to something reasonable
        seconds  = BCD_TO_BINARY(buf_in[1]);
        minutes  = BCD_TO_BINARY(buf_in[2]);
        hours    = BCD_TO_BINARY((buf_in[3])&0x3F);
        days     = BCD_TO_BINARY(buf_in[4]);
        day      = buf_in[5];
        month    = buf_in[6];
        year     = BCD_TO_BINARY(buf_in[7])+2000;

        signal RVRTC.readTimeDone(SUCCESS, seconds, minutes, hours, days,
                                  month, year, day);
        break;
      }

      case RV3049_STATE_SET_TIME:
        state = RV3049_STATE_SET_TIME_DONE;

        call CS.set();
        call SpiPacket.send(buf_out, NULL, RV3049_WRITE_LEN_TIME);
        break;

      case RV3049_STATE_SET_TIME_DONE:
        call CS.clr();
        call SpiResource.release();
        signal RVRTC.setTimeDone(SUCCESS);
        break;

      case RV3049_STATE_DONE:
        break;

      default:
        break;
    }
  }



  event void SpiResource.granted () {
    post state_machine();
  }

  async event void SpiPacket.sendDone (uint8_t* txBuf,
                                       uint8_t* rxBuf,
                                       uint16_t len,
                                       error_t error) {
    post state_machine();
  }

}


