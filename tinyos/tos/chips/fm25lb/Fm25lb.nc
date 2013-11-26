/**
 * Serial abstraction for the FM25LxxxB family of fram chips.
 *
 * @author Samuel DeBruin <sdebruin@umich.edu>
 */

#include "Fm25lb.h"

interface Fm25lb {
  command error_t read(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len);
  command error_t write(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len);

  command error_t readStatus(uint8_t* buf);
  command error_t writeStatus(uint8_t* buf);

  event void readDone(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len, error_t err);
  event void writeDone(fm25lb_addr_t addr, uint8_t* buf, fm25lb_len_t len, error_t err);

  event void readStatusDone(uint8_t* buf, error_t err);
  event void writeStatusDone(uint8_t* buf, error_t err);

  command error_t writeEnable();
  event void writeEnableDone();
}
