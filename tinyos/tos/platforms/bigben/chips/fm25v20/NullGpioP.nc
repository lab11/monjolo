/* Dummy GPIO
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

generic module NullGpioP () {
  provides {
    interface GeneralIO;
  }
}
implementation {
  async command void GeneralIO.set() {}
  async command void GeneralIO.clr() {}
  async command void GeneralIO.toggle() {}
  async command bool GeneralIO.get() { return FALSE; }
  async command void GeneralIO.makeInput() {}
  async command bool GeneralIO.isInput() { return FALSE; }
  async command void GeneralIO.makeOutput() {}
  async command bool GeneralIO.isOutput() { return FALSE; }
}