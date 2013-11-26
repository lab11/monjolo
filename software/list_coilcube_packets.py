import IPy
import json
import socket
import sys

HOST, PORT = "inductor.eecs.umich.edu", 22500
query = {'profile_id': '7aiOPJapXF'}

versions = {1: 'coilcube'}

s = """Packet: {}
	mac: {}
	addr: {}
"""

# Create a socket (SOCK_STREAM means a TCP socket)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
	# Connect to server and send the query for all monjolo sensors
	sock.connect((HOST, PORT))
	sock.sendall(json.dumps(query) + "\n")

	# Receive data from the server and shut down
	while True:
		r = sock.recv(1024)

		pkt = json.loads(r)

		if 'type' not in pkt:
			continue

		if pkt['type'] != 'coilcube_raw':
			continue

		ccid = '{:0>16x}'.format(pkt['ccid'])
		ccid_mac = ':'.join([ccid[i:i+2] for i in range(0, 16, 2)])
		ip_str = IPy.IP(pkt['address'])

		print(s.format(versions[pkt['version']], ccid_mac, ip_str))



finally:
	print "closeit"
	sock.close()
