import IPy
import json
import Queue
import socket
import sys
import threading

try:
	import socketIO_client as sioc
except ImportError:
	print('Could not import the socket.io client library.')
	print('sudo pip install socketIO-client')
	sys.exit(1)

# List of ccid_macs that should included in the queue
ids = []
q = Queue.Queue()

####
# Class that implements the various functions for retrieving monjolo data
####
class MonjoloData:

	SOCKETIO_HOST      = 'gatd.eecs.umich.edu'
	SOCKETIO_PORT      = 8080
	SOCKETIO_NAMESPACE = 'stream'

	MONJOLO_PID = '7aiOPJapXF'

	versions = {1: 'coilcube'}

	####
	# Gets data from GATD that correspond to coilcubes and puts it in the queue
	#
	# dict format:
	# KEY        VALUE
	# counter    the wakeup counter stored on the monjolo
	# seq_no     the 802.15.4 sequence number for the packet
	# ccid       an integer that represents the monjolo's unique id
	# ccid_mac   a string version of the monjolo id (ex: 00:11:22:33:44:55:66:77)
	# address    integer representing the ip address of the monjolo
	# ip         a string of the ipv6 address of the node
	# profile_id the GATD profile id that marks monjolo nodes as special
	# port       an integer of the port on the monjolo the packet came from
	# version    an integer representing the version of monjolo
	# time       unix timestamp in milliseconds
	# type       the type of packet in GATD land. always going to be 'coilcube_raw'
	# public     whether the packet should be viewable by all. Always True
	####
	class stream_receiver (sioc.BaseNamespace):
		def on_data (self, *args):
			global ids, q
			pkt = args[0]

			pkt['ip'] = str(IPy.IP(pkt['address']))

			if pkt['ccid_mac'] in ids:
				q.put(pkt)

	def socketio (self):
		socketIO = sioc.SocketIO(self.SOCKETIO_HOST, self.SOCKETIO_PORT)
		stream_namespace = socketIO.define(self.stream_receiver,
			'/{}'.format(self.SOCKETIO_NAMESPACE))

		stream_namespace.emit('query', {'profile_id': self.MONJOLO_PID,
			                            'type':       'coilcube_raw'
						               })
		socketIO.wait()

	####
	# Call this to specify which nodes you would like data for. ids should be a list
	# of strings, where each string is the ccid_mac of the monjolos to be used.
	#
	# example:  register_ids(['00:12:6d:43:4f:e1:b2:64', '00:12:6d:43:4f:e2:81:b6'])
	####
	def register_ids (self, id_list):
		global ids
		ids = list(id_list)

	####
	# Call this to get the next item from the queue
	#
	# Returns none if there is no new data
	####
	def next_data (self):
		global q
		try:
			return q.get(block=False)
		except Queue.Empty:
			return None

	####
	# Call this to send the formatted data back to GATD
	#
	# Need to implement this.
	####
	def transmit (self, ccid, watts):
		pass

	####
	# Call this to start the threads and to start filling the queue
	####
	def start (self, processing_function):
		global q
		# Start the threads
		a = threading.Thread(target=self.socketio)
		a.deamon = True
		a.start()

		b = threading.Thread(target=processing_function)
		b.deamon = True
		b.start()

		q.join()
