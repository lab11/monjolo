#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include <CC2420FbRadio.h>
//#include <CC2420.h>
#include <Serial.h>

typedef union message_header {
  cc2420_header_t cc2420;
  serial_header_t serial;
} message_header_t;

typedef union TOSRadioFooter {
  cc2420packet_footer_t cc2420;
  //cc2420_footer_t cc2420;
} message_footer_t;

typedef union TOSRadioMetadata {
  cc2420packet_metadata_t cc2420;
  //cc2420_metadata_t cc2420;
} message_metadata_t;

#endif
