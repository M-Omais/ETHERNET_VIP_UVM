interface axi_stream_if;

	logic         s_eth_hdr_valid;
    logic        s_eth_hdr_ready;
    logic [47:0]  s_eth_dest_mac;
    logic [47:0]  s_eth_src_mac;
    logic [15:0]  s_eth_type;
    logic [63:0]  s_eth_payload_axis_tdata;
    logic [7:0]   s_eth_payload_axis_tkeep;
    logic         s_eth_payload_axis_tvalid;
    logic        s_eth_payload_axis_tready;
    logic         s_eth_payload_axis_tlast;
    logic         s_eth_payload_axis_tuser;
endinterface //axi_stream_if

