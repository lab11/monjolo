COMPONENT=RpiCoilcubeReceiverIpC

PFLAGS += -DCC2520_DEF_CHANNEL=18

# Just need to define this so that blip doesn't compile in DHCP
# This #def never gets used.
PFLAGS += -DIN6_PREFIX="\"::\""

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
