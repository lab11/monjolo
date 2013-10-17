#!/usr/bin/env python

"""
Generate pdfs of labels for Coilcube Cases
"""

import os
import sys

try:
	import qrcode
	import qrcode.image.svg
except ImportError as e:
	print('Could not import qrcode.')
	print('sudo pip install qrcode')
	sys.exit(1)

import svgutils.transform as sg

import sh
from sh import pdftk
from sh import pdf2svg

CASE_LABEL = 'case_label.pdf'

def validate (rawid):
	rawid = rawid.strip()
	# see if it just nicely formated
	bytes = rawid.split(':')
	if len(bytes) == 8:
		for b in bytes:
			try:
				int(b, 16)
			except:
				print('Chunk {} in {} not hex!'.format(b, rawid))
				return None
		return rawid.upper()
	elif len(bytes) == 1:
		try:
			int(rawid, 16)
		except:
			print('ID not hex: {}'.format(rawid))
			return None
		return (':'.join([rawid[i:i+2] for i in range(0, 16, 2)])).upper()

	else:
		print('Invalid ID: {}'.format(rawid))
		return None


x = 0
y = 0
def get_coordinates ():
	global x, y

	offset_x = 18
	gap_x = 9
	width_x = 108
	offset_y = 36
	gap_y = 0
	height_y = 72

	xpx = offset_x + (x*(gap_x + width_x))
	ypx = offset_y + (y*(gap_y + height_y))

	y += 1

	if y > 9:
		y = 0
		x += 1

	return (xpx, ypx)

# List of ids to make QR codes of
ids = []

if len(sys.argv) != 2:
	print('Usage: {} <64 bid id|file of ids>'.format(__file__))
	sys.exit(1)

if os.path.exists(sys.argv[1]):
	with open(sys.argv[1]) as f:
		for l in f:
			nodeid = validate(l)
			if nodeid:
				ids.append(nodeid)
else:
	nodeid = validate(sys.argv[1])
	if nodeid:
		ids.append(nodeid)

if len(ids) == 0:
	print('No IDs to make QR codes of!')
	sys.exit(1)

label_sheet = sg.SVGFigure('612', '792')
labels = []

for nodeid in ids:
	nodeidstr = nodeid.replace(':', '')

	# Create the QR code
	img = qrcode.make(nodeid,
		image_factory=qrcode.image.svg.SvgPathImage,
		border=0)
	img.save('qr_{}.svg'.format(nodeidstr))

	# Create the node specific svg
	fig = sg.SVGFigure('108px', '72px')

	rawlabel = sg.fromfile('case_label2.svg')
	rawlabelr = rawlabel.getroot()

	qr = sg.fromfile('qr_{}.svg'.format(nodeidstr))
	qrr = qr.getroot()
	qrr.moveto('58', '6', 1.7) # position correctly (hand tweaked)

	#txt = sg.TextElement(100,318, nodeid, size=28, font='Courier')
	txt = sg.TextElement('19','64', nodeid, size=6, font='Courier')
	fig.append([rawlabelr, qrr, txt])
	fig.save('label_{}.svg'.format(nodeidstr))

#	labels.append(fig)

	# Convert the id specific image to pdf
	sh.rsvg_convert('-f', 'pdf', '-o', 'label_{}.pdf'.format(nodeidstr),
		'label_{}.svg'.format(nodeidstr))

	# Stamp the label with id specific image
#	pdftk(CASE_LABEL, 'stamp', 'unique_{}.pdf'.format(nodeidstr), 'output',
#		'label_{}.pdf'.format(nodeidstr))

#	pdf2svg('label_{}.pdf'.format(nodeidstr), 'label_{}.svg'.format(nodeidstr))

	lbl = sg.fromfile('label_{}.svg'.format(nodeidstr))
	lblr = lbl.getroot()
	pos = get_coordinates()
	lblr.moveto(pos[0], pos[1], 1) # position correctly (hand tweaked)

	labels.append(lblr)

label_sheet.append(labels)
label_sheet.save('all.svg')
sh.rsvg_convert('-f', 'pdf', '-d', '100', '-p', '100', '-o', 'all.pdf', 'all.svg')










