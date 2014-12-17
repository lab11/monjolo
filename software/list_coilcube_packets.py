#!/usr/bin/env python

import IPy
import json
import socket
import sys

try:
	import socketIO_client as sioc
except ImportError:
	print('Could not import the socket.io client library.')
	print('sudo pip install socketIO-client')
	sys.exit(1)

SOCKETIO_HOST      = 'gatd.eecs.umich.edu'
SOCKETIO_PORT      = 8080
SOCKETIO_NAMESPACE = 'stream'

query = {'profile_id': '7aiOPJapXF',
         'type': 'coilcube_raw',
         'description': {'$exists': True}}

versions = {1: 'coilcube'}

s = """Packet: {}
	mac: {}
	addr: {}
"""

if len(sys.argv) > 1:
	query['ccid_mac'] = sys.argv[1]

class stream_receiver (sioc.BaseNamespace):
	def on_data (self, *args):
		global ids, q
		pkt = args[0]

		pkt['ip'] = str(IPy.IP(pkt['address']))

		print(pkt)

socketIO = sioc.SocketIO(SOCKETIO_HOST, SOCKETIO_PORT)
stream_namespace = socketIO.define(stream_receiver,
	'/{}'.format(SOCKETIO_NAMESPACE))

stream_namespace.emit('query', query)
socketIO.wait()
