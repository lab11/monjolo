
module RpiCoilcubeReceiverIpP @safe() {
  uses {
    interface Boot;
    interface Leds;

    interface SplitControl as BlipControl;
  }
}
implementation {

  event void Boot.booted() {
    call BlipControl.start();
  }

  event void BlipControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call BlipControl.start();
    }
  }

  event void BlipControl.stopDone (error_t e) { }

}
