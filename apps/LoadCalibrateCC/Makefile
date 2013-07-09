COMPONENT=LoadCalibrateCCC

CFLAGS += -DCC2420_DEF_CHANNEL=18

PFLAGS += -I$(TINYOS_ROOT_DIR)/tools/tinyos/c/blip/lib6lowpan
PFLAGS += $(TINYOS_ROOT_DIR)/tools/tinyos/c/blip/lib6lowpan/ieee154_header.c

CFLAGS += -DASSERT_NONE

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
