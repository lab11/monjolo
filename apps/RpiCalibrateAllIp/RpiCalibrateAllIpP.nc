
module RpiCalibrateAllIpP {
  uses {
    interface Boot;
    interface Leds;
    interface UnixTime;
    interface BusyWait<TMicro, uint16_t>;

    interface SplitControl as BlipControl;

    interface HplBcm2835GeneralIO as Pin;
    interface GpioInterrupt as Int;

    interface UartBuffer;
  }
}
implementation {

  uint64_t last_light_int = 0;

  event void Boot.booted() {
    call Pin.makeInput();
    call Int.enableRisingEdge();
    call BlipControl.start();
  }

  event void BlipControl.startDone (error_t err) {
    if (err != SUCCESS) {
      call BlipControl.start();
    }
  }

  async event void Int.fired () {
    uint64_t timestamp;

    timestamp = call UnixTime.getMicroseconds();

    if (timestamp - last_light_int < 10000) return;

    call Leds.led0Toggle();

    printf("{\"type\":\"gecko\",");
    printf("\"timestamp\":%llu}\n", timestamp);


    // Clear this wakeup
    call Pin.makeOutput();
    call Pin.clr();
    call BusyWait.wait(50000);
    call BusyWait.wait(50000);
    call BusyWait.wait(50000);
    call BusyWait.wait(50000);
    call BusyWait.wait(50000);
    call BusyWait.wait(50000);
    call Pin.makeInput();

    last_light_int = call UnixTime.getMicroseconds();

  }

  event void UartBuffer.receive (uint8_t* buf,
                                 uint8_t len,
                                 uint64_t timestamp) {
    buf[len] = '\0';
    printf("plm: %llu %s", timestamp, buf);
  }

  event void BlipControl.stopDone (error_t err) { }
}
