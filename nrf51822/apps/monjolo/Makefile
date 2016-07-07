PROJECT_NAME = $(shell basename "$(realpath ./)")

APPLICATION_SRCS = $(notdir $(wildcard ./*.c))
APPLICATION_SRCS += softdevice_handler.c
APPLICATION_SRCS += ble_advdata.c
APPLICATION_SRCS += ble_debug_assert_handler.c
APPLICATION_SRCS += ble_srv_common.c
APPLICATION_SRCS += app_timer.c

# DEVICE = NRF51
# BOARD = BOARD_PCA10001

# USE_SOFTDEVICE = s110

# SDK_PATH ?= $(HOME)/git/nrf5x-base/sdk/nrf51_sdk_9.0.0/
# TEMPLATE_PATH ?= ../../nrf51-pure-gcc-setup/template/

# CFLAGS = -Os
# GDB_PORT_NUMBER = 2331

# include $(TEMPLATE_PATH)Makefile



# platform-level headers and source files
# LIBRARY_PATHS += ../../include
# SOURCE_PATHS += ../../src

# Set the softdevice needed for the application
SOFTDEVICE_MODEL = s110
SDK_VERSION = 10

# Include the main Makefile
NRF_BASE_PATH ?= $(HOME)/git/nrf5x-base
include $(NRF_BASE_PATH)/make/Makefile