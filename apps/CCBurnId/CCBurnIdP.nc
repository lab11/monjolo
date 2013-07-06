
module CCBurnIdP {
  uses {
    interface Boot;
    interface LocalIeeeEui64;
    interface Fm25lb as Fram;
  }
}

implementation {

  ieee_eui64_t id;

  event void Boot.booted () {
    ieee_eui64_t id_blank = {{0}};

    while (1) {
      id = call LocalIeeeEui64.getId();

      // Check to make sure we got an actual address and not just 0s (which
      // happens if the read of the DS2411 fails.)
      if (memcmp(id.data, id_blank.data, sizeof(ieee_eui64_t)) != 0) {
        break;
      }
    }

    // Setup a write to the first 8 bytes of the FRAM
    call Fram.write(0, id.data, 8);
  }

  event void Fram.writeDone(fm25lb_addr_t addr,
                            uint8_t* buf,
                            fm25lb_len_t len,
                            error_t err) {
    if (err != SUCCESS) {
      // retry
      call Fram.write(0, id.data, 8);
      return;
    }

    // Nothing left to do
  }

  event void Fram.readDone(fm25lb_addr_t addr, uint8_t* buf,
    fm25lb_len_t len, error_t err) {}
  event void Fram.readStatusDone(uint8_t* buf, error_t err) {}
  event void Fram.writeStatusDone(uint8_t* buf, error_t err) {}
  event void Fram.writeEnableDone() {}

}
