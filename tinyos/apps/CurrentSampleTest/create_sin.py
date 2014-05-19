#!/usr/bin/env python3

import math

SAMPLE_INTERVAL = 40.375 # microseconds

PERIOD = 16666 # microseconds


SCALE = 32767

LINE_WIDTH = 78


NUM_SAMPLES = int(PERIOD / SAMPLE_INTERVAL)


vals = []

for i in range(NUM_SAMPLES):
	sin_val = math.sin((2*math.pi*i)/NUM_SAMPLES)

	uint_val = int(sin_val*SCALE)

	vals.append(uint_val)



print('// {} us period sine wave sampled every {} us'.format(PERIOD, SAMPLE_INTERVAL))
print('// scaled by {}'.format(SCALE))
print("uint16_t SIN_SAMPLES[{}] = {{".format(NUM_SAMPLES))

i=0
chars = 0
for val in vals:
	out = str(val)

	if chars + len(out) + 2 > LINE_WIDTH:
		print('')
		chars = 0

	if i == len(vals)-1:
		if chars == 0:
			print('{}'.format(out), end='')
			chars += len(out)
		else:
			print(' {}'.format(out), end='')
			chars += len(out) + 1
		print('\n};', end='')


	else:

		if chars == 0:
			print('{},'.format(out), end='')
			chars += len(out) + 1
		else:
			print(' {},'.format(out), end='')
			chars += len(out) + 2

	i += 1




print('')