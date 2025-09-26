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
        output longint ctrl_ray[]     // output frame bytes
    );
    import "DPI-C" context function int xgmii_arp_frame_c(
        input longint src_mac,
        input longint dst_mac,
        input int src_ip,
        input int dst_ip,
        output longint data_ray[],     // output frame bytes
        output longint ctrl_ray[]     // output frame bytes
    );
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
    // `include "../axi_agent/udp_env.sv"

endpackage