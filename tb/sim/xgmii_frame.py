from cocotbext.eth import XgmiiFrame
from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP

def xgmii_eth_frame(src_mac, dst_mac, src_ip, dst_ip, sport, dport, payload = b''):
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

	
	# Build Ethernet frame using Scapy
	# for i in range(len(payload)):
	# 	print(f"payload[{i}] = {payload[i]}")
	eth = Ether(src=src_mac, dst=dst_mac)
	ip = IP(src=src_ip, dst=dst_ip)
	udp = UDP(sport=sport, dport=dport)
	pkt = eth / ip / udp / payload
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

def xgmii_arp_frame (src_mac, dst_mac, src_ip, dst_ip):
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

	
	# Build Ethernet frame using Scapy
	# for i in range(len(payload)):
	# 	print(f"payload[{i}] = {payload[i]}")
	eth = Ether(src=src_mac, dst=dst_mac)
	ip = IP(src=src_ip, dst=dst_ip)
	arp = ARP(hwsrc=src_mac, psrc=src_ip, hwdst=dst_mac, pdst=dst_ip)
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


if __name__ == "__main__":
	datas = xgmii_eth_frame(src_mac="5a:51:52:53:54:55",
							dst_mac="02:00:00:00:00:00",
							src_ip="192.168.1.100",
							dst_ip="192.168.1.128",
							sport=5678,
							dport=1234,
							payload = bytes([0,1,2,3,4,5,6,7,8,9]))
	for data, ctrl in datas:
		print(f"data = 0x{data:016x}, ctrl = 0x{ctrl:1x}")	
