from cocotbext.eth import XgmiiFrame
from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP
from scapy.all import Ether, IP, UDP
import socket
import struct

def xgmii_eth_frame(src_mac, dst_mac, src_ip, dst_ip,  eth_type, sport, dport, op, payload = b''):
	"""
	Create an XGMII frame with Ethernet header and payload.

	Parameters
	----------
	src_mac : str
		Source MAC address (e.g. '5a:51:52:53:54:55')
	dst_mac : str
		Destination MAC address (e.g. '02:00:00:00:00:00')
	eth_type : int
		Ethernet type field (default = 0x0800 for IPv4)
	payload : bytes
		Payload data (default = empty)

	Returns
	-------
	list of (data, ctrl)
		Encoded XGMII data and control words
	"""

	eth = Ether(src=src_mac, dst=dst_mac, type=eth_type)
	ip = IP(src=src_ip, dst=dst_ip, id=0,flags=2)
	udp = UDP(sport=sport, dport=dport)
	print(eth_type)
	if eth_type == 0x0800:  # IPv4
		pkt = eth / ip / udp / payload

	elif eth_type == 0x0806:  # ARP
		if op == 2:  # ARP Reply
			arp = ARP(
			hwtype=1, ptype=0x0800, hwlen=6, plen=4, op=2,
			hwsrc=src_mac, psrc=src_ip,
			hwdst=dst_mac, pdst=dst_ip
			)
			pkt = eth / arp

		elif op == 1:  # ARP Request
			eth = Ether(src=src_mac, dst="ff:ff:ff:ff:ff:ff", type=0x0806)
			arp = ARP(
			hwtype=1, ptype=0x0800, hwlen=6, plen=4, op=1,
			hwsrc=src_mac, psrc=src_ip,
			hwdst="00:00:00:00:00:00", pdst=dst_ip
			)
			pkt = eth / arp
	# Create XGMII frame from packet
	frame = XgmiiFrame.from_payload(pkt.build())
	# Normalize and patch frame for XGMII
	frame.normalize()
	frame.start_lane = 0

	# Replace first PRE with 0xFB
	assert frame.data[0] == 0x55
	assert frame.ctrl[0] == 0
	frame.data[0] = 0xFB
	frame.ctrl[0] = 1

	# Append TERM at the end
	frame.data.append(0xFD)
	frame.ctrl.append(1)

	result = []
	frame_offset = 0
	length = len(frame.data)

	while frame_offset < length:
		d_val = 0
		c_val = 0

		for k in range(8):
			if frame_offset < length:
				d = frame.data[frame_offset]
				c = frame.ctrl[frame_offset]
				d_val |= d << (8 * k)
				c_val |= c << k
				frame_offset += 1
			else:
				# pad with IDLE if frame ends before filling 64-bit
				d_val |= 0x07 << (8 * k)
				c_val |= 1 << k

		result.append((d_val, c_val))

	# Append IFG as IDLE words
	idle_bytes = 12
	while idle_bytes > 0:
		d_val = 0
		c_val = 0
		for k in range(8):
			d_val |= 0x07 << (8 * k)
			c_val |= 1 << k
		result.append((d_val, c_val))
		idle_bytes -= 8

	# for data, ctrl in result:
	# 	print(f"data = 0x{data:016x}, ctrl = 0x{ctrl:1x}")	
	return result

def ip_to_int(ip_str):
    return struct.unpack("!I", socket.inet_aton(ip_str))[0]
def mac_to_int(mac_str):
    return int(mac_str.replace(":", ""), 16)

def decode_xgmii_frame(xgmii_words) -> dict:
    

    # Flatten XGMII into raw bytes
	raw_bytes = b""
	for data, ctrl in xgmii_words:
		for i in range(8):  # 8 bytes per 64-bit word
			byte = (data >> (8 * i)) & 0xFF
			cbit = (ctrl >> i) & 0x1
			if cbit == 1 and byte == 0xFB:  # valid byte
				break
			if cbit == 0:  # valid byte
				raw_bytes += bytes([byte])
			# print(f"Raw byte: {byte:02x} \t Ctrl byte: {cbit:02x}")
		# print(f"Intermediate raw bytes: {data:016x} \t Ctrl: {ctrl:02x}")
	# print("Raw Ethernet frame:", raw_bytes.hex())
	# Strip preamble + SFD if present
	if raw_bytes.startswith(bytes.fromhex("555555555555d5")):
		print("Stripping preamble and SFD")
		raw_bytes = raw_bytes[7:]
	# Decode with scapy
    # Decode with scapy
	pkt = Ether(raw_bytes)
	eth = pkt[Ether]
	# pkt.show2()
	# Declare all possible fields first
	fields = {
		# Ethernet
		"dst_mac": 0,
		"src_mac": 0,
		"eth_type": 0,

		# ARP
		"hwtype": 0,
		"ptype": 0,
		"hwlen": 0,
		"plen": 0,
		"op": 0,

		# IP
		"version": 0,
		"ihl": 0,
		"tos_dscp": 0,
		"tos_ecn": 0,
		"length": 0,
		"identification": 0,
		"flags": 0,
		"fragment_offset": 0,
		"ttl": 0,
		"protocol": 0,
		"header_checksum": 0,
		"source_ip": 0,
		"dest_ip": 0,

		# UDP
		"source_port": 0,
		"dest_port": 0,
		"udp_length": 0,
		"udp_checksum": 0,
		"payload": b"",
	}

	# Always fill Ethernet
	fields["dst_mac"] = mac_to_int(eth.dst)
	fields["src_mac"] = mac_to_int(eth.src)
	fields["eth_type"] = eth.type

	# If ARP
	if eth.type == 0x0806 and ARP in pkt:
		arp = pkt[ARP]
		fields["hwtype"] = arp.hwtype
		fields["ptype"] = arp.ptype
		fields["hwlen"] = arp.hwlen
		fields["plen"] = arp.plen
		fields["op"] = arp.op
		fields["source_ip"] = ip_to_int(arp.psrc)
		fields["dest_ip"] = ip_to_int(arp.pdst)

	# If IPv4 + UDP
	elif eth.type == 0x0800 and IP in pkt and UDP in pkt:
		ip = pkt[IP]
		udp = pkt[UDP]
		fields["version"] = ip.version
		fields["ihl"] = ip.ihl
		fields["tos_dscp"] = ip.tos >> 2
		fields["tos_ecn"] = ip.tos & 0x3
		fields["length"] = ip.len
		fields["identification"] = ip.id
		fields["flags"] = int(ip.flags)
		fields["fragment_offset"] = ip.frag
		fields["ttl"] = ip.ttl
		fields["protocol"] = ip.proto
		fields["header_checksum"] = ip.chksum
		fields["source_ip"] = ip_to_int(ip.src)
		fields["dest_ip"] = ip_to_int(ip.dst)

		fields["source_port"] = udp.sport
		fields["dest_port"] = udp.dport
		fields["udp_length"] = udp.len
		fields["udp_checksum"] = udp.chksum
		fields["payload"] = bytes(udp.payload)[: (udp.len - 8)]  # exclude UDP header
	# return 0
	# print the payload
	# print("Payload:", fields["payload"].hex())
	print(fields)

	return fields

if __name__ == "__main__":
	datas = xgmii_eth_frame(src_mac="5a:51:52:53:54:55",
							dst_mac="02:00:00:00:00:00",
							src_ip="192.168.1.100",
							dst_ip="192.168.1.128",
							eth_type=0x0806,
							sport=5678,
							dport=1234,
							payload=bytes([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
							op=2
							)
	for data, ctrl in datas:
		print(f"data = 0x{data:016x}, ctrl = 0x{ctrl:1x}")	


	# fields = decode_xgmii_frame(datas)
	# for k, v in fields.items():
	# 	print(f"{k:20} = {v!r} \t(type: {type(v).__name__})")