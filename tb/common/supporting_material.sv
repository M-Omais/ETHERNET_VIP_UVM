parameter dut_ip = 32'hc0a80180;     // Data bus width
parameter master_ip = 32'hc0a80164;     // Master IP address
parameter dut_mac = 48'h02_00_00_00_00_00; // DUT MAC address
parameter master_mac = 48'h5a5152535455; // Master MAC address

// UDP -> XGMII frame conversion function
import "DPI-C" context function int xgmii_eth_frame_c(
        input  longint  src_mac,
        input  longint  dst_mac,
        input  int      src_ip,
        input  int      dst_ip,
        input  shortint eth_type,   
        input  int      sport,
        input  int      dport,
        input  byte     payload[],      // input payload bytes
        output longint  data_ray[],     // output frame bytes
        output longint  ctrl_ray[],
        input  shortint op     // output frame bytes
    );

// XGMII -> UDP frame conversion function
import "DPI-C" context function int scb_xgmii_to_udp(
    input  bit [63:0] data_ray[],     // XGMII data
    input  bit [7:0]  ctrl_ray[],     // XGMII control

    // Ethernet
    output longint unsigned m_udp_eth_dest_mac,
    output longint unsigned m_udp_eth_src_mac,
    output shortint unsigned m_udp_eth_type,
    // ARP
    output shortint unsigned arp_hwtype,
    output shortint unsigned arp_ptype,
    output byte unsigned arp_hwlen,
    output byte unsigned arp_plen,
    output shortint unsigned arp_op,

    // IP
    output byte unsigned m_udp_ip_version,
    output byte unsigned m_udp_ip_ihl,
    output byte unsigned m_udp_ip_dscp,
    output byte unsigned m_udp_ip_ecn,
    output shortint unsigned m_udp_ip_length,
    output shortint unsigned m_udp_ip_identification,
    output byte unsigned m_udp_ip_flags,
    output shortint unsigned m_udp_ip_fragment_offset,
    output byte unsigned m_udp_ip_ttl,
    output byte unsigned m_udp_ip_protocol,
    output shortint unsigned m_udp_ip_header_checksum,
    output int unsigned  m_udp_ip_source_ip,
    output int unsigned  m_udp_ip_dest_ip,

    // UDP
    output shortint unsigned m_udp_source_port,
    output shortint unsigned m_udp_dest_port,
    output shortint unsigned m_udp_length,
    output shortint unsigned m_udp_checksum,
    output  bit [63:0] m_udp_payload[]     // payload data
);

function string ip_to_string(bit [31:0] ip);
    return $sformatf("%0d.%0d.%0d.%0d",
        ip[31:24], ip[23:16], ip[15:8], ip[7:0]);
endfunction

function void arp_print(longint unsigned dst_mac, longint unsigned src_mac, shortint unsigned op,  int unsigned src_ip,  int unsigned dst_ip);
  string op_str;
  if (op == 16'h0001) begin
    op_str = "ARP Request";
  end 
  else if (op == 16'h0002) begin
    op_str = "ARP Reply";
  end
  else begin
    op_str = $sformatf("Unknown (0x%0h)", op);
  end
  `uvm_info("ARP", $sformatf("Ethernet: %012h -> %012h | %s | Src IP: %s | Dst IP: %s", src_mac, dst_mac, op_str,
  ip_to_string(src_ip), ip_to_string(dst_ip)),UVM_LOW);
endfunction

  function int data_create(xgmii_seq_item item, bit req=0);
      longint   mac_src;
      longint   mac_dst;
      longint   dataout[64];
      longint   ctrlout[64];
      int       ip_src;
      int       ip_dst;
      int       sport;
      int       dport;
      int       payload_len;
      int       ret_size;
      shortint  eth_type_s;
      shortint  op;
      byte      payload_bytes[];

      // Map class fields
      mac_src     = item.src_addr;
      mac_dst     = item.dst_addr;
      ip_src      = item.src_ip;
      ip_dst      = item.dst_ip;
      sport       = item.src_port;
      dport       = item.dst_port;
      payload_len = item.payload.size();
      eth_type_s  = item.eth_type;

    if (req) 
      op = 1; // ARP request
    else   
      op = 2; // ARP reply or normal UDP frame

      // Copy payload
    payload_bytes = new[payload_len];
    foreach (item.payload[i]) begin
        payload_bytes[i] = item.payload[i];
    end

    // Call frame creation function
    ret_size = xgmii_eth_frame_c(mac_src, mac_dst, ip_src, ip_dst, eth_type_s,
                                 sport, dport, payload_bytes, dataout, ctrlout, op);

    if (ret_size < 2)
      `uvm_error("DATA_CREATE", "DPI function xgmii_eth_frame_c failed")
    else 
      begin	
        `uvm_info("DATA_CREATE", "DPI function xgmii_eth_frame_c succeeded", UVM_LOW);
        // Copy output data to class fields
        item.data_out = new[ret_size];
        item.ctrl_out = new[ret_size];
        for (int i = 0; i < ret_size; i++) begin
            item.data_out[i] = dataout[i];
            item.ctrl_out[i] = ctrlout[i];
        end
      end
    return ret_size;
  endfunction