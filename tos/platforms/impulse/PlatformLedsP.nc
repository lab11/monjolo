#include "hardware.h"

/* Fixes the fact that I made the led on impulse active high, instead of active
 * low.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

module PlatformLedsP {
  provides {
    interface GeneralIO as FixedLed;
  }
  uses {
    interface GeneralIO as BackwardsLed;
  }
}
implementation {

  async command void FixedLed.set() {
    call BackwardsLed.clr();
  }
  async command void FixedLed.clr() {
    call BackwardsLed.set();
  }
  async command void FixedLed.toggle() {
    call BackwardsLed.toggle();
  }
  async command bool FixedLed.get() {
    return call BackwardsLed.get();
  }
  async command void FixedLed.makeInput() {
    call BackwardsLed.makeInput();
  }
  async command bool FixedLed.isInput() {
    return call BackwardsLed.isInput();
  }
  async command void FixedLed.makeOutput() {
    call BackwardsLed.makeOutput();
  }
  async command bool FixedLed.isOutput() {
    return call BackwardsLed.isOutput();
  }

}
