/**
 * Serial abstraction for the FM25Vxx family of FRAM chips.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

#include "fm25v.h"

interface FM25V {
  command error_t read (uint32_t addr, uint8_t* buf, uint32_t len);
  command error_t write (uint32_t addr, uint8_t* buf, uint32_t len);

  event void readDone (uint32_t addr, uint8_t* buf, uint32_t len, error_t err);
  event void writeDone (uint32_t addr, uint8_t* buf, uint32_t len, error_t err);

}
