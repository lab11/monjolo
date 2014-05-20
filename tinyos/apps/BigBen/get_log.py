#!/usr/bin/env python3

import serial
import sys


s = serial.Serial('/dev/ttyUSB0', 115200, timeout=2)

#s.write('start'.encode())


vals = []

g = s.read(1)

print('got null')
print(g)

hello = s.read(5)
print(hello)

s.write('start'.encode('ascii'))

print('sent start')


while True:
	b = s.read(14)

	if len(b) < 2:
		break

	print(b)
