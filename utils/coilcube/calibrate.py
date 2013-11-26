#!/usr/bin/env python
# -*- coding: utf-8 -*-

LOAD_ID = 3
CUBE_ID = 2

from glob import glob
import json
import string
import sys


cc_packets = {}
plm_msgs = []

def byte_subtract (a, b):
    if (a >= b):
        return a-b
    else:
        return a + (256-b)

def estimate_power (freq):
    return 41.5

def frange(x, y, jump):
    while x < y:
        yield x
        x += jump
        x = round(x, 2)


if len(sys.argv) != 2:
    print("Usage: {} <filename of calibration data>".format(sys.argv[0]))
    sys.exit(1)

filename = sys.argv[1]

try:
    f = open(filename)
except IOError:
    print("Could not open {}.".format(filename))
    sys.exit(1)

# Iterate over the calibration data file and calculate the relevant data to
# understand wakeups -> watts.
while True:
    l = f.readline()
    if len(l) == 0:
        break

    if l[0:4] == "plm:":
        try:
            garbage, timestamp, plm_data = string.split(l, maxsplit=2)
            v_rms, v_peak, i_rms, i_peak, w, w_peak, va, pf, wh, h, w_ta = plm_data.split(',')
        except ValueError:
            continue

        plm_data_point = {}
        plm_data_point['timestamp'] = int(timestamp)
        plm_data_point['v_rms'] = v_rms
        plm_data_point['v_peak'] = v_peak
        plm_data_point['i_rms'] = i_rms
        plm_data_point['i_peak'] = i_peak
        plm_data_point['watts'] = float(w)
        plm_data_point['w_peak'] = w_peak
        plm_data_point['va'] = va
        plm_data_point['pf'] = pf
        plm_data_point['wh'] = wh
        plm_data_point['h'] = h
        plm_data_point['w_ta'] = w_ta

        plm_msgs.append(plm_data_point)

    else:

        try:
            ccpkt = json.loads(l)
        except ValueError:
            continue

        # insert into list of cc_packets
        if ccpkt['id'] not in cc_packets:
            cc_packets[ccpkt['id']] = []

        cc_packets[ccpkt['id']].append(ccpkt)

f.close()


for nodeid in cc_packets:

    f_out = open('{:0>16x}.json'.format(nodeid), 'w')
    freq_watt = []


    prev_count = 0
    prev_time = 0
    for pkt in cc_packets[nodeid]:
        if prev_time == 0:
            prev_time = pkt['timestamp']
            prev_count = pkt['counter']
            continue

        count_diff = byte_subtract(pkt['counter'], prev_count)
        time_diff = pkt['timestamp'] - prev_time

        freq = float(count_diff) / (float(time_diff)/1000000.0)

        last_wattage = 0
        for plm in plm_msgs:
            if plm['timestamp'] > pkt['timestamp']:
                break
            else:
                last_wattage = plm['watts']

        freq_watt.append((freq, last_wattage))


        prev_time = pkt['timestamp']
        prev_count = pkt['counter']

    # Put all the results into bins.
    # Each bin is a list of wattages.
    min_freq = 9999999.9
    max_freq = 0.0
    freq_watt_binned = {}
    for fw in freq_watt:
        freq_rounded = round(fw[0], 2)
        freq_watt_binned.setdefault(freq_rounded, [])
        freq_watt_binned[freq_rounded].append(fw[1])

        if freq_rounded > max_freq:
            max_freq = freq_rounded
        if freq_rounded < min_freq:
            min_freq = freq_rounded

    # Average all of the wattages for each bin
    for f in freq_watt_binned:
        avg = sum(freq_watt_binned[f])/len(freq_watt_binned[f])
        freq_watt_binned[f] = avg

    # Fill in all of the rest
    for i in frange(round(min_freq+0.01,2), max_freq, 0.01):
        if i not in freq_watt_binned:
            first = freq_watt_binned[round(i-0.01,2)]
            j = round(i+0.01,2)
            while True:
                if j in freq_watt_binned:
                    space = round(j-i+0.01,2)
                    second = freq_watt_binned[j]
                    new = (((second - first) * 0.01) / space) + first
                    freq_watt_binned[round(i, 2)] = new
                    break
                j += 0.01
                j = round(j, 2)


    f_out.write(json.dumps(freq_watt_binned))

    f_out.close()
