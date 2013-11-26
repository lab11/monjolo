
module CCReadFramP {
  uses {
    interface Boot;
    interface Fm25lb as Fram;
    interface Timer<TMilli>;
  }
}

implementation {

#define BYTES_TO_READ 64

  uint8_t buffer[BYTES_TO_READ];

  event void Boot.booted () {
    call Fram.read(0, buffer, BYTES_TO_READ);
  }

  event void Fram.readDone(fm25lb_addr_t addr, uint8_t* buf,
    fm25lb_len_t len, error_t err) {

    call Timer.startPeriodic(2000);
  }

  event void Timer.fired () {
    int i;

    for (i=0; i<BYTES_TO_READ; i++) {
      printf("%02x ", buffer[i]);
    }
    printf("\n");
    printfflush();
  }

  event void Fram.writeDone(fm25lb_addr_t addr,
                            uint8_t* buf,
                            fm25lb_len_t len,
                            error_t err) { }


  event void Fram.readStatusDone(uint8_t* buf, error_t err) {}
  event void Fram.writeStatusDone(uint8_t* buf, error_t err) {}
  event void Fram.writeEnableDone() {}

}
