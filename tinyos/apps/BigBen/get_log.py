#!/usr/bin/env python3


################################################################################
##
## Download the data from the storage flash of a BigBen node.
##
## Usage: 1. Set the switch so the epic-multi-prog is in UART mode.
##        2. Run this script. Something like:
##              ./get_log.py | tee node1.data
##        3. Connect the impulse to an epic-multi-prog board with a
##           tag connect cable within two seconds of starting the script.
##
##
################################################################################


import serial
import sys
import struct
import datetime


s = serial.Serial('/dev/ttyUSB0', 115200, timeout=2)

welcome = 'hello'
welcome_index = 0

# Make sure BigBen/impulse is there
while True:
	c = s.read(1)
	if len(c) == 0:
		break

	if c.decode('utf-8') == welcome[welcome_index]:
		welcome_index += 1

	if welcome_index == len(welcome):
		break

if welcome_index >= len(welcome):
	print('Found BigBen')
else:
	print('No response from BigBen')
	sys.exit(1)

# Tell BigBen to start dumping its data
s.write('start'.encode('ascii'))
print('Requested data...')


while True:
	b = s.read(14)

	if len(b) == 4:
		break

	if len(b) < 2:
		break;

	if len(b) == 14:
		values = struct.unpack('<LBBBBBBL', b)

		wakeups = values[0]
		seconds = values[1]
		minutes = values[2]
		hours   = values[3]
		days    = values[4]
		month   = values[5]
		year    = values[6]+2000
		diff    = values[7]

		d = datetime.datetime(year, month, days, hours, minutes, seconds)

		print('{}: {}'.format(d, diff))

