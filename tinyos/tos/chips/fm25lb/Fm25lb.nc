/**
 * Serial abstraction for the FM25LxxxB family of fram chips.
 *
 * @author Samuel DeBruin <sdebruin@umich.edu>
 */

#include "Fm25lb.h"

interface Fm25lb {
  command error_t read (uint16_t addr, uint8_t* buf, uint16_t len);
  command error_t write (uint16_t addr, uint8_t* buf, uint16_t len);

  command error_t readStatus ();
  command error_t writeStatus (uint8_t status);

  command error_t blockingRead(uint16_t addr, uint8_t* buf, uint16_t len);
  command error_t blockingWrite(uint16_t addr, uint8_t* buf, uint16_t len);

  event void readDone (uint16_t addr, uint8_t* buf, uint16_t len, error_t err);
  event void writeDone (uint16_t addr, uint8_t* buf, uint16_t len, error_t err);

  event void readStatusDone (uint8_t status, error_t err);
  event void writeStatusDone (error_t err);
}
