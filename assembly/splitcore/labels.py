#!/usr/bin/env python2

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

CC_LABEL_PDF = 'case_label.pdf'
CC_LABEL_SVG = 'case_label.svg'

SC_LABEL_PDF = 'split_core_label.pdf'
SC_LABEL_SVG = 'split_core_label.svg'

QR_CODE_STR = '{}|coilcube|A|http://lab11.eecs.umich.edu/projects/monjolo'

QR_COLOR = '#2A388F'

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

POSITION_START_X = 4
POSITION_START_Y = 0
x = POSITION_START_X
y = POSITION_START_Y

label_specs = {}
label_specs['cc'] = {}
label_specs['cc']['offset_x'] = 18
label_specs['cc']['gap_x']    = 9
label_specs['cc']['width_x']  = 108
label_specs['cc']['offset_y'] = 36
label_specs['cc']['gap_y']    = 0
label_specs['cc']['height_y'] = 72
label_specs['cc']['y_count']  = 10
label_specs['cc']['x_count']  = 5
label_specs['sc'] = {}
label_specs['sc']['offset_x'] = 34
label_specs['sc']['gap_x']    = 8.5
label_specs['sc']['width_x']  = 54
label_specs['sc']['offset_y'] = 35.5
label_specs['sc']['gap_y']    = 0
label_specs['sc']['height_y'] = 72
label_specs['sc']['y_count']  = 10
label_specs['sc']['x_count']  = 9

def get_coordinates (ltype='cc'):
	global x, y

	xpx = label_specs[ltype]['offset_x'] + (x*(label_specs[ltype]['gap_x'] + label_specs[ltype]['width_x']))
	ypx = label_specs[ltype]['offset_y'] + (y*(label_specs[ltype]['gap_y'] + label_specs[ltype]['height_y']))

	y += 1

	if y > label_specs[ltype]['y_count']-1:
		y = 0
		x += 1

	return (round(xpx), round(ypx))

# List of ids to make QR codes of
ids = []

if len(sys.argv) != 3:
	print('Usage: {} <64 bid id|file of ids> <type>'.format(__file__))
	print('type: cc or splitcore')
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

if sys.argv[2] == 'cc':
	ltype = 'cc'
	label_pdf = CC_LABEL_PDF
	label_svg = CC_LABEL_SVG
	label_pixels_x = 108
	label_pixels_y = 72
	label_qr_pos_x = 69
	label_qr_pos_y = 13
	label_qr_scale = 1
	label_id_pos_x = 19
	label_id_pos_y = 63
	label_id_font = 6
	label_id_letterspacing = 0
	label_rotate = False
elif sys.argv[2] == 'splitcore':
	ltype = 'sc'
	label_pdf = SC_LABEL_PDF
	label_svg = SC_LABEL_SVG
	label_pixels_x = 72
	label_pixels_y = 54
	label_qr_pos_x = 4
	label_qr_pos_y = 18.5
	label_qr_scale = 1.0
	label_id_pos_x = 7
	label_id_pos_y = 49.2
	label_id_font  = 5
	label_id_letterspacing = -0.5
	label_rotate = True
else:
	print('not a type')
	sys.exit(1)

label_sheet = sg.SVGFigure('612', '792') # 8.5"x11" paper at 72dpi
labels = []

# Convert the base label pdf to svg
pdf2svg(label_pdf, label_svg)

for nodeid in ids:
	nodeidstr = nodeid.replace(':', '')

	# Create the QR code
	img = qrcode.make(QR_CODE_STR.format(nodeid),
		image_factory=qrcode.image.svg.SvgPathImage,
		box_size=7,
		version=4,
		border=0)
	img.save('qr_{}.svg'.format(nodeidstr))

	# Color the QR code
	with open('qr_{}.svg'.format(nodeidstr), 'r+') as f:
		svg = f.read()
		f.seek(0)
		svg = svg.replace('fill:#000000;', 'fill:{};'.format(QR_COLOR))
		f.write(svg)

	# Create the node specific svg
	fig = sg.SVGFigure('{}px'.format(label_pixels_x), '{}px'.format(label_pixels_y))

	rawlabel = sg.fromfile(label_svg)
	rawlabelr = rawlabel.getroot()

	qr = sg.fromfile('qr_{}.svg'.format(nodeidstr))
	qrr = qr.getroot()
	# position correctly (hand tweaked)
	qrr.moveto(label_qr_pos_x, label_qr_pos_y, label_qr_scale)

	#txt = sg.TextElement(100,318, nodeid, size=28, font='Courier')
	txt = sg.TextElement(label_id_pos_x,
	                     label_id_pos_y, nodeid,
	                     size=label_id_font,
	                     font='Courier',
	                     letterspacing=label_id_letterspacing)
	fig.append([rawlabelr, qrr, txt])
	fig.save('label_{}.svg'.format(nodeidstr))

	if label_rotate:
		fig = sg.SVGFigure('{}px'.format(label_pixels_y), '{}px'.format(label_pixels_x))
		dlabel = sg.fromfile('label_{}.svg'.format(nodeidstr))
		dlabelr = dlabel.getroot()
		dlabelr.rotate(90, x=0, y=0)
		dlabelr.moveto(0, -1*label_pixels_y)
		fig.append([dlabelr])
		fig.save('label_{}.svg'.format(nodeidstr))

#	labels.append(fig)

	# Convert the id specific image to pdf
#	sh.rsvg_convert('-f', 'pdf', '-o', 'label_{}.pdf'.format(nodeidstr),
#		'label_{}.svg'.format(nodeidstr))

	# Stamp the label with id specific image
#	pdftk(CASE_LABEL, 'stamp', 'unique_{}.pdf'.format(nodeidstr), 'output',
#		'label_{}.pdf'.format(nodeidstr))

#	pdf2svg('label_{}.pdf'.format(nodeidstr), 'label_{}.svg'.format(nodeidstr))

	lbl = sg.fromfile('label_{}.svg'.format(nodeidstr))
	lblr = lbl.getroot()
	pos = get_coordinates(ltype)
	lblr.moveto(pos[0], pos[1], 1) # position correctly (hand tweaked)

	labels.append(lblr)

label_sheet.append(labels)
label_sheet.save('all_{}.svg'.format(ltype))
sh.rsvg_convert('-f', 'pdf', '-d', '72', '-p', '72', '-o',
	'all_{}.pdf'.format(ltype), 'all_{}.svg'.format(ltype))










