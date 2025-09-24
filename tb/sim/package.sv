package tx_pkg;
    import uvm_pkg::*;
    import "DPI-C" context function int xgmii_eth_frame_c(
        input longint src_mac,
        input longint dst_mac,
        input int src_ip,
        input int dst_ip,
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
    `include "uvm_macros.svh"
    `include "../common/sq_item.sv"
    `include "../common/udp_seq_item.sv"
    `include "../xgmii_agent/sequences/xgmii_seq.sv"
    `include "../xgmii_agent/xgmii_sequencer.sv"
    `include "../xgmii_agent/xgmii_driver.sv"
    `include "../xgmii_agent/xgmii_monitor.sv"
    `include "../xgmii_agent/xgmii_agent.sv"
	`include "../env/scoreboard.sv"
    `include "../axi_agent/udp_sequencer.sv"
    `include "../axi_agent/udp_driver.sv"
    `include "../axi_agent/udp_monitor.sv"
    `include "../axi_agent/sequences/udp_seq.sv"

    // include agent & env files
    `include "../axi_agent/udp_agent.sv"
    `include "../env/mac_env.sv"
    `include "../tests/base_test.sv"
    `include "../tests/udp_test.sv"
    // `include "../axi_agent/udp_env.sv"

endpackage