COMPONENT=RpiCalibrateCCC

PFLAGS += -DCC2420_DEF_CHANNEL=18
PFLAGS += -DCC2520_DEF_CHANNEL=18

PFLAGS += -I$(TINYOS_ROOT_DIR)/tools/tinyos/c/blip/lib6lowpan
PFLAGS += $(TINYOS_ROOT_DIR)/tools/tinyos/c/blip/lib6lowpan/ieee154_header.c

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
