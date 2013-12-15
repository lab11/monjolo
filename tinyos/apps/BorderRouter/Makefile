COMPONENT=BorderRouterC

PFLAGS += -DCC2520_DEF_CHANNEL=18

PFLAGS += -I%T/../apps/BorderRouter

# Set the prefix to just be blank. We don't really care about the address
# of the wireless side.
PFLAGS += -DIN6_PREFIX="\"::\""

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
