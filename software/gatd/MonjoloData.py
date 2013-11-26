import IPy
import json
import Queue
import socket
import sys
import threading


HOST, PORT = "inductor.eecs.umich.edu", 22500

####
# Class that implements the various functions for retrieving monjolo data
####
class MonjoloData:

	query = {'profile_id': '7aiOPJapXF'}

	versions = {1: 'coilcube'}

	# List of ccid_macs that should included in the queue
	id_list = []
	q = Queue.Queue()

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
	def stream_receiver (self):
		# Create a socket (SOCK_STREAM means a TCP socket)
		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

		# Connect to server and send the query for all monjolo sensors
		sock.connect((HOST, PORT))
		sock.sendall(json.dumps(self.query) + "\n")

		# Receive data from the server and shut down
		while True:
			r = sock.recv(1024)

			pkt = json.loads(r)

			try:
				if pkt['type'] != 'coilcube_raw':
					continue
			except KeyError:
				continue

			ccid = '{:0>16x}'.format(pkt['ccid'])
			pkt['ccid_mac'] = ':'.join([ccid[i:i+2] for i in range(0, 16, 2)])
			pkt['ip'] = str(IPy.IP(pkt['address']))

			if pkt['ccid_mac'] in self.id_list:
				self.q.put(pkt)

	####
	# Call this to specify which nodes you would like data for. ids should be a list
	# of strings, where each string is the ccid_mac of the monjolos to be used.
	#
	# example:  register_ids(['00:12:6d:43:4f:e1:b2:64', '00:12:6d:43:4f:e2:81:b6'])
	####
	def register_ids (self, ids):
		self.id_list = list(ids)

	####
	# Call this to get the next item from the queue
	#
	# Returns none if there is no new data
	####
	def next_data (self):
		try:
			return self.q.get(block=False)
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
		# Start the threads
		a = threading.Thread(target=self.stream_receiver)
		a.deamon = True
		a.start()

		b = threading.Thread(target=processing_function)
		b.deamon = True
		b.start()

		self.q.join()