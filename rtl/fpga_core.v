/*

Copyright (c) 2014-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA core logic
 */
module fpga_core
(
    /*
     * Clock: 156.25MHz
     * Synchronous reset
     */
    input  wire       clk,
    input  wire       rst,

    /*
     * Ethernet: SFP+
     */
    input  wire        sfp_1_tx_clk,
    input  wire        sfp_1_tx_rst,
    output wire [63:0] sfp_1_txd,
    output wire [7:0]  sfp_1_txc,
    input  wire        sfp_1_rx_clk,
    input  wire        sfp_1_rx_rst,
    input  wire [63:0] sfp_1_rxd,
    input  wire [7:0]  sfp_1_rxc,
    
    /*
     * UDP layer
     */
    input wire  s_udp_hdr_valid,
    output wire  s_udp_hdr_ready,
    input wire [5:0]  s_udp_ip_dscp,
    input wire [1:0]  s_udp_ip_ecn,
    input wire [7:0]  s_udp_ip_ttl,
    input wire [31:0]  s_udp_ip_source_ip,
    input wire [31:0]  s_udp_ip_dest_ip,
    input wire [15:0]  s_udp_source_port,
    input wire [15:0]  s_udp_dest_port,
    input wire [15:0]  s_udp_length,
    input wire [15:0]  s_udp_checksum,
    input wire [63:0]  s_udp_payload_axis_tdata,
    input wire [7:0]  s_udp_payload_axis_tkeep,
    input wire  s_udp_payload_axis_tvalid,
    output wire  s_udp_payload_axis_tready,
    input wire  s_udp_payload_axis_tlast,
    input wire  s_udp_payload_axis_tuser,

    output wire  m_udp_hdr_valid,
    input wire  m_udp_hdr_ready,
    output wire [47:0]  m_udp_eth_dest_mac,
    output wire [47:0]  m_udp_eth_src_mac,
    output wire [15:0]  m_udp_eth_type,
    output wire [3:0]  m_udp_ip_version,
    output wire [3:0]  m_udp_ip_ihl,
    output wire [5:0]  m_udp_ip_dscp,
    output wire [1:0]  m_udp_ip_ecn,
    output wire [15:0]  m_udp_ip_length,
    output wire [15:0]  m_udp_ip_identification,
    output wire [2:0]  m_udp_ip_flags,
    output wire [12:0]  m_udp_ip_fragment_offset,
    output wire [7:0]  m_udp_ip_ttl,
    output wire [7:0]  m_udp_ip_protocol,
    output wire [15:0]  m_udp_ip_header_checksum,
    output wire [31:0]  m_udp_ip_source_ip,
    output wire [31:0]  m_udp_ip_dest_ip,
    output wire [15:0]  m_udp_source_port,
    output wire [15:0]  m_udp_dest_port,
    output wire [15:0]  m_udp_length,
    output wire [15:0]  m_udp_checksum,
    output wire [63:0]  m_udp_payload_axis_tdata,
    output wire [7:0]  m_udp_payload_axis_tkeep,
    output wire  m_udp_payload_axis_tvalid,
    input wire  m_udp_payload_axis_tready,
    output wire  m_udp_payload_axis_tlast,
    output wire  m_udp_payload_axis_tuser

);

// AXI between MAC and Ethernet modules
wire [63:0] rx_axis_tdata;
wire [7:0] rx_axis_tkeep;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;

wire [63:0] tx_axis_tdata;
wire [7:0] tx_axis_tkeep;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;

// Ethernet frame between Ethernet modules and UDP stack
wire rx_eth_hdr_ready;
wire rx_eth_hdr_valid;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [63:0] rx_eth_payload_axis_tdata;
wire [7:0] rx_eth_payload_axis_tkeep;
wire rx_eth_payload_axis_tvalid;
wire rx_eth_payload_axis_tready;
wire rx_eth_payload_axis_tlast;
wire rx_eth_payload_axis_tuser;

wire tx_eth_hdr_ready;
wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [63:0] tx_eth_payload_axis_tdata;
wire [7:0] tx_eth_payload_axis_tkeep;
wire tx_eth_payload_axis_tvalid;
wire tx_eth_payload_axis_tready;
wire tx_eth_payload_axis_tlast;
wire tx_eth_payload_axis_tuser;




// Configuration
wire [47:0] local_mac   = 48'h02_00_00_00_00_00;
wire [31:0] local_ip    = {8'd192, 8'd168, 8'd1,   8'd128};
wire [31:0] gateway_ip  = {8'd192, 8'd168, 8'd1,   8'd1};
wire [31:0] subnet_mask = {8'd255, 8'd255, 8'd255, 8'd0};



// Place first payload byte onto LEDs
reg valid_last = 0;
reg [7:0] led_reg = 0;


eth_mac_10g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_10g_fifo_inst (
    .rx_clk(sfp_1_rx_clk),
    .rx_rst(sfp_1_rx_rst),
    .tx_clk(sfp_1_tx_clk),
    .tx_rst(sfp_1_tx_rst),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep(tx_axis_tkeep),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tkeep(rx_axis_tkeep),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    .xgmii_rxd(sfp_1_rxd),
    .xgmii_rxc(sfp_1_rxc),
    .xgmii_txd(sfp_1_txd),
    .xgmii_txc(sfp_1_txc),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

eth_axis_rx #(
    .DATA_WIDTH(64)
)
eth_axis_rx_inst (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx_axis_tdata),
    .s_axis_tkeep(rx_axis_tkeep),
    .s_axis_tvalid(rx_axis_tvalid),
    .s_axis_tready(rx_axis_tready),
    .s_axis_tlast(rx_axis_tlast),
    .s_axis_tuser(rx_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid),
    .m_eth_hdr_ready(rx_eth_hdr_ready),
    .m_eth_dest_mac(rx_eth_dest_mac),
    .m_eth_src_mac(rx_eth_src_mac),
    .m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination()
);

eth_axis_tx #(
    .DATA_WIDTH(64)
)
eth_axis_tx_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid),
    .s_eth_hdr_ready(tx_eth_hdr_ready),
    .s_eth_dest_mac(tx_eth_dest_mac),
    .s_eth_src_mac(tx_eth_src_mac),
    .s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(tx_axis_tdata),
    .m_axis_tkeep(tx_axis_tkeep),
    .m_axis_tvalid(tx_axis_tvalid),
    .m_axis_tready(tx_axis_tready),
    .m_axis_tlast(tx_axis_tlast),
    .m_axis_tuser(tx_axis_tuser),
    // Status signals
    .busy()
);

udp_complete_64
udp_complete_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(rx_eth_hdr_valid),
    .s_eth_hdr_ready(rx_eth_hdr_ready),
    .s_eth_dest_mac(rx_eth_dest_mac),
    .s_eth_src_mac(rx_eth_src_mac),
    .s_eth_type(rx_eth_type),
    .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep),
    .s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(tx_eth_hdr_valid),
    .m_eth_hdr_ready(tx_eth_hdr_ready),
    .m_eth_dest_mac(tx_eth_dest_mac),
    .m_eth_src_mac(tx_eth_src_mac),
    .m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep),
    .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // UDP frame input
    .s_udp_hdr_valid(s_udp_hdr_valid),
    .s_udp_hdr_ready(s_udp_hdr_ready),
    .s_udp_ip_dscp(s_udp_ip_dscp),
    .s_udp_ip_ecn(s_udp_ip_ecn),
    .s_udp_ip_ttl(s_udp_ip_ttl),
    .s_udp_ip_source_ip(s_udp_ip_source_ip),
    .s_udp_ip_dest_ip(s_udp_ip_dest_ip),
    .s_udp_source_port(s_udp_source_port),
    .s_udp_dest_port(s_udp_dest_port),
    .s_udp_length(s_udp_length),
    .s_udp_checksum(s_udp_checksum),
    .s_udp_payload_axis_tdata(s_udp_payload_axis_tdata),
    .s_udp_payload_axis_tkeep(s_udp_payload_axis_tkeep),
    .s_udp_payload_axis_tvalid(s_udp_payload_axis_tvalid),
    .s_udp_payload_axis_tready(s_udp_payload_axis_tready),
    .s_udp_payload_axis_tlast(s_udp_payload_axis_tlast),
    .s_udp_payload_axis_tuser(s_udp_payload_axis_tuser),
    // UDP frame output
    .m_udp_hdr_valid(m_udp_hdr_valid),
    .m_udp_hdr_ready(m_udp_hdr_ready),
    .m_udp_eth_dest_mac(m_udp_eth_dest_mac),
    .m_udp_eth_src_mac(m_udp_eth_src_mac),
    .m_udp_eth_type(m_udp_eth_type),
    .m_udp_ip_version(m_udp_ip_version),
    .m_udp_ip_ihl(m_udp_ip_ihl),
    .m_udp_ip_dscp(m_udp_ip_dscp),
    .m_udp_ip_ecn(m_udp_ip_ecn),
    .m_udp_ip_length(m_udp_ip_length),
    .m_udp_ip_identification(m_udp_ip_identification),
    .m_udp_ip_flags(m_udp_ip_flags),
    .m_udp_ip_fragment_offset(m_udp_ip_fragment_offset),
    .m_udp_ip_ttl(m_udp_ip_ttl),
    .m_udp_ip_protocol(m_udp_ip_protocol),
    .m_udp_ip_header_checksum(m_udp_ip_header_checksum),
    .m_udp_ip_source_ip(m_udp_ip_source_ip),
    .m_udp_ip_dest_ip(m_udp_ip_dest_ip),
    .m_udp_source_port(m_udp_source_port),
    .m_udp_dest_port(m_udp_dest_port),
    .m_udp_length(m_udp_length),
    .m_udp_checksum(m_udp_checksum),
    .m_udp_payload_axis_tdata(m_udp_payload_axis_tdata),
    .m_udp_payload_axis_tkeep(m_udp_payload_axis_tkeep),
    .m_udp_payload_axis_tvalid(m_udp_payload_axis_tvalid),
    .m_udp_payload_axis_tready(m_udp_payload_axis_tready),
    .m_udp_payload_axis_tlast(m_udp_payload_axis_tlast),
    .m_udp_payload_axis_tuser(m_udp_payload_axis_tuser),
    // Status signals
    .ip_rx_busy(),
    .ip_tx_busy(),
    .udp_rx_busy(),
    .udp_tx_busy(),
    .ip_rx_error_header_early_termination(),
    .ip_rx_error_payload_early_termination(),
    .ip_rx_error_invalid_header(),
    .ip_rx_error_invalid_checksum(),
    .ip_tx_error_payload_early_termination(),
    .ip_tx_error_arp_failed(),
    .udp_rx_error_header_early_termination(),
    .udp_rx_error_payload_early_termination(),
    .udp_tx_error_payload_early_termination(),
    // Configuration
    .local_mac(local_mac),
    .local_ip(local_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(1'b0)
);


endmodule

`resetall