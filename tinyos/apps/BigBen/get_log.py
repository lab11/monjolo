#!/usr/bin/env python3

import serial
import sys
import struct
import datetime


s = serial.Serial('/dev/ttyUSB0', 115200, timeout=2)

# Make sure BigBen/impulse is there
n = s.read(1)
h = s.read(5)

hello = h.decode('utf-8')

if (hello == 'hello'):
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

