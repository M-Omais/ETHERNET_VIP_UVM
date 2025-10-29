package tx_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "../common/xgmii_seq_item.sv"
    `include "../common/supporting_material.sv"
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
    `include "../env/reference_model.sv"
    `include "../env/scoreboard.sv"
    `include "../env/virtual_sequencer.sv"
    `include "../env/mac_env.sv"

    `include "../xgmii_agent/sequences/arp_seq.sv"
    `include "../xgmii_agent/sequences/xgmii_seq.sv"
    `include "../xgmii_agent/sequences/xgmii_back_to_back_seq.sv"
    `include "../xgmii_agent/sequences/variable_xgmii_seq.sv"
    `include "../axi_agent/sequences/udp_seq.sv"
    `include "../axi_agent/sequences/back_to_back_seq.sv"
    `include "../axi_agent/sequences/variable_udp_seq.sv"

    `include "../axi_agent/sequences/no_payload_seq.sv"
    `include "../env/virtual_sequences/arp_handshake_seq.sv"
    `include "../env/virtual_sequences/variable_arp_seq.sv"
    `include "../env/virtual_sequences/variable_ip_seq.sv"

    `include "../tests/base_test.sv"
    `include "../tests/udp_test.sv"
    `include "../tests/handshake_test.sv"
    `include "../tests/xgmii_test.sv"
    `include "../tests/udp_back_to_back_test.sv"
    `include "../tests/xgmii_back_to_back_test.sv"
    `include "../tests/udp_xgmii_parallel_test.sv"
    `include "../tests/variable_ip_test.sv"

endpackage