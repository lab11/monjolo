#include "PlatformIeeeEui64.h"

module LocalIeeeEui64P {
  provides {
    interface LocalIeeeEui64;
  }
  uses {
    interface ReadId48;
    interface Fm25lb as Fram;
  }
}

implementation {
  ieee_eui64_t eui = {{0x00}};

  bool have_id = FALSE;

  #define FRAM_ID_ADDR 0

  command ieee_eui64_t LocalIeeeEui64.getId () {
    uint8_t buf[6] = {0};
    error_t e;

    if (!have_id) {

      // first try the FRAM
      call Fram.blockingRead(FRAM_ID_ADDR, eui.data, 8);
      // Check if it is in FRAM
      if (eui.data[0] == IEEE_EUI64_COMPANY_ID_0 ||
          eui.data[1] == IEEE_EUI64_COMPANY_ID_1 ||
          eui.data[2] == IEEE_EUI64_COMPANY_ID_2) {
        // Got the id and we are good to go
        have_id = TRUE;
        return eui;
      }

      // Need to query the DS2411
      while (1) {
        e = call ReadId48.read(buf);
        if (e == SUCCESS) {
          eui.data[0] = IEEE_EUI64_COMPANY_ID_0;
          eui.data[1] = IEEE_EUI64_COMPANY_ID_1;
          eui.data[2] = IEEE_EUI64_COMPANY_ID_2;

          // 16 bits of the ID is generated by software
          // could be used for hardware model id and revision, for example
          eui.data[3] = IEEE_EUI64_SERIAL_ID_0;
          eui.data[4] = IEEE_EUI64_SERIAL_ID_1;

          // 24 least significant bits of the serial ID read from the DS2411
          eui.data[5] = buf[2];
          eui.data[6] = buf[1];
          eui.data[7] = buf[0];

          // Store the id in FRAM for future wakeups
          call Fram.blockingWrite(FRAM_ID_ADDR, eui.data, 8);

          have_id = TRUE;
          break;
        }
      }

    }

    return eui;
  }

  event void Fram.readDone(uint16_t addr,
                           uint8_t* buf,
                           uint16_t len,
                           error_t err) { }
  event void Fram.writeDone(uint16_t addr,
                            uint8_t* buf,
                            uint16_t len,
                            error_t err) { }
  event void Fram.readStatusDone (uint8_t status, error_t err) { }
  event void Fram.writeStatusDone(error_t err) { }

}
