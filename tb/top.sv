`timescale 1ps/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import tx_pkg::*;
module top;
	// Clock and Reset
	logic clk, rst_n;

	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end
	int data_width = 32;
	// Instantiate interface
	xgmii_if xgmii_i(clk, rst_n);
	axi_stream_if axis_i();
	udp_if udp_vif (.clk(clk), .rst(rst_n));
	// DUT interface
	// output declaration of module fpga_core
	wire [1:0] sfp_1_led;
	wire [1:0] sfp_2_led;
	wire [1:0] sma_led;
	wire [63:0] sfp_1_txd;
	wire [7:0] sfp_1_txc;
	wire [63:0] sfp_2_txd;
	wire [7:0] sfp_2_txc;
	
	fpga_core dut(
		.clk          	(clk),
		.rst          	(rst_n),
		.sfp_1_tx_clk 	(clk),
		.sfp_1_tx_rst 	(rst_n),
		.sfp_1_txd    	(xgmii_i.tdata),
		.sfp_1_txc    	(xgmii_i.tctrl),
		.sfp_1_rx_clk 	(clk),
		.sfp_1_rx_rst 	(rst_n),
		.sfp_1_rxd    	(xgmii_i.data),
		.sfp_1_rxc    	(xgmii_i.ctrl),
	    // UDP input
	    .s_udp_hdr_valid         (udp_vif.s_udp_hdr_valid),
	    .s_udp_hdr_ready         (udp_vif.s_udp_hdr_ready),
	    .s_udp_ip_dscp           (udp_vif.s_udp_ip_dscp),
	    .s_udp_ip_ecn            (udp_vif.s_udp_ip_ecn),
	    .s_udp_ip_ttl            (udp_vif.s_udp_ip_ttl),
	    .s_udp_ip_source_ip      (udp_vif.s_udp_ip_source_ip),
	    .s_udp_ip_dest_ip        (udp_vif.s_udp_ip_dest_ip),
	    .s_udp_source_port       (udp_vif.s_udp_source_port),
	    .s_udp_dest_port         (udp_vif.s_udp_dest_port),
	    .s_udp_length            (udp_vif.s_udp_length),
	    .s_udp_checksum          (udp_vif.s_udp_checksum),
	    .s_udp_payload_axis_tdata(udp_vif.s_udp_payload_axis_tdata),
	    .s_udp_payload_axis_tvalid(udp_vif.s_udp_payload_axis_tvalid),
	    .s_udp_payload_axis_tready(udp_vif.s_udp_payload_axis_tready),
	    .s_udp_payload_axis_tlast(udp_vif.s_udp_payload_axis_tlast),
	    .s_udp_payload_axis_tuser(udp_vif.s_udp_payload_axis_tuser),

	    // UDP output
	    .m_udp_hdr_valid         (udp_vif.m_udp_hdr_valid),
	    .m_udp_hdr_ready         (1'b1),
	    .m_udp_eth_dest_mac      (udp_vif.m_udp_eth_dest_mac),
	    .m_udp_eth_src_mac       (udp_vif.m_udp_eth_src_mac),
	    .m_udp_eth_type          (udp_vif.m_udp_eth_type),
	    .m_udp_ip_version        (udp_vif.m_udp_ip_version),
	    .m_udp_ip_ihl            (udp_vif.m_udp_ip_ihl),
	    .m_udp_ip_dscp           (udp_vif.m_udp_ip_dscp),
	    .m_udp_ip_ecn            (udp_vif.m_udp_ip_ecn),
	    .m_udp_ip_length         (udp_vif.m_udp_ip_length),
	    .m_udp_ip_identification (udp_vif.m_udp_ip_identification),
	    .m_udp_ip_flags          (udp_vif.m_udp_ip_flags),
	    .m_udp_ip_fragment_offset(udp_vif.m_udp_ip_fragment_offset),
	    .m_udp_ip_ttl            (udp_vif.m_udp_ip_ttl),
	    .m_udp_ip_protocol       (udp_vif.m_udp_ip_protocol),
	    .m_udp_ip_header_checksum(udp_vif.m_udp_ip_header_checksum),
	    .m_udp_ip_source_ip      (udp_vif.m_udp_ip_source_ip),
	    .m_udp_ip_dest_ip        (udp_vif.m_udp_ip_dest_ip),
	    .m_udp_source_port       (udp_vif.m_udp_source_port),
	    .m_udp_dest_port         (udp_vif.m_udp_dest_port),
	    .m_udp_length            (udp_vif.m_udp_length),
	    .m_udp_checksum          (udp_vif.m_udp_checksum),
	    .m_udp_payload_axis_tdata(udp_vif.m_udp_payload_axis_tdata),
	    .m_udp_payload_axis_tkeep(udp_vif.m_udp_payload_axis_tkeep),
	    .m_udp_payload_axis_tvalid(udp_vif.m_udp_payload_axis_tvalid),
	    .m_udp_payload_axis_tready(1'b1),
	    .m_udp_payload_axis_tlast(udp_vif.m_udp_payload_axis_tlast),
	    .m_udp_payload_axis_tuser(udp_vif.m_udp_payload_axis_tuser)
	);
	

	// DUT instantiation using modport

	// Clock generation

	// Reset logic
	initial begin
		rst_n = 0;
		#10 rst_n = 1;
		#100 rst_n = 0;
	end


	initial begin
		// Pass virtual interface to UVM testbench
		uvm_config_db#(virtual xgmii_if)::set(null, "uvm_test_top.env.xgmii_agent_inst.*", "vif", xgmii_i);
		uvm_config_db#(virtual axi_stream_if)::set(null, "uvm_test_top.env.xgmii_agent_inst.*", "vifa", axis_i);
	    uvm_config_db#(virtual udp_if)::set(null, "*", "udp_vif", udp_vif);

	    uvm_config_db#(uvm_active_passive_enum)::set(null, "uvm_test_top.env.xgmii_agent_inst", "is_active", UVM_ACTIVE); // or UVM_PASSIVE
	    uvm_config_db#(uvm_active_passive_enum)::set(null, "uvm_test_top.env.udp_agent_inst", "is_active", UVM_ACTIVE); // or UVM_PASSIVE

		// Run the test
		uvm_config_db#(int)            ::set(null, "", "recording_detail", 0);
		uvm_config_db#(uvm_bitstream_t)::set(null, "", "recording_detail", 0);
		run_test("base_test");
	end

endmodule : top	