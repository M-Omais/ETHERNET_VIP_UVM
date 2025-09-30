package tx_pkg;
    import uvm_pkg::*;
    import "DPI-C" context function int xgmii_eth_frame_c(
        input longint src_mac,
        input longint dst_mac,
        input int src_ip,
        input int dst_ip,
        input shortint eth_type,   
        input int sport,
        input int dport,
        input byte payload[],      // input payload bytes
        output longint data_ray[],     // output frame bytes
        output longint ctrl_ray[],
        input shortint op     // output frame bytes
    );
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
    parameter dut_ip = 32'hc0a80180;     // Data bus width
    parameter master_ip = 32'hc0a80164;     // Master IP address
    parameter dut_mac = 48'h02_00_00_00_00_00; // DUT MAC address
    parameter master_mac = 48'h5a5152535455; // Master MAC address
    `include "uvm_macros.svh"
    `include "../common/sq_item.sv"
    `include "../common/udp_seq_item.sv"

    `include "../xgmii_agent/xgmii_sequencer.sv"
    `include "../xgmii_agent/xgmii_driver.sv"
    `include "../xgmii_agent/xgmii_monitor.sv"
    `include "../xgmii_agent/xgmii_agent.sv"

    `include "../axi_agent/udp_sequencer.sv"
    `include "../axi_agent/udp_driver.sv"
    `include "../axi_agent/udp_monitor.sv"
    `include "../axi_agent/udp_agent.sv"

    // include agent & env files
	`include "../env/scoreboard.sv"
    `include "../env/virtual_sequencer.sv"
    `include "../env/mac_env.sv"

    `include "../xgmii_agent/sequences/arp_seq.sv"
    `include "../xgmii_agent/sequences/xgmii_seq.sv"
    `include "../axi_agent/sequences/udp_seq.sv"
    `include "../axi_agent/sequences/no_payload_seq.sv"
    `include "../env/virtual_sequences/arp_handshake_seq.sv"

    `include "../tests/base_test.sv"
    `include "../tests/udp_test.sv"
    `include "../tests/handshake_test.sv"
    `include "../tests/xgmii_test.sv"
    // `include "../axi_agent/udp_env.sv"

endpackage