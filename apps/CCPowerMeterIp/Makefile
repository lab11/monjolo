COMPONENT=CCPowerMeterIpC

CFLAGS += -DCC2420X_DEF_CHANNEL=19

PFLAGS += -I$(TINYOS_ROOT_DIR)/tools/tinyos/c/blip/lib6lowpan
PFLAGS += $(TINYOS_ROOT_DIR)/tools/tinyos/c/blip/lib6lowpan/ieee154_header.c

CFLAGS += -DASSERT_NONE

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
