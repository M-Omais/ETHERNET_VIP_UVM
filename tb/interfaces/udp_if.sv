// udp_if (the interface) is a bundle of DUT pins/signals (clk, rst, ports, payload buses) so we don’t connect each wire separately.
// It makes RTL connections cleaner — just one interface instance connects DUT ↔ TB.

//see virtual interface (vif) in tb_top

interface udp_if (input bit clk, input bit rst);
    
   /*
    * UDP input
    */
    logic        s_udp_hdr_valid;
    logic        s_udp_hdr_ready;
    logic [5:0]  s_udp_ip_dscp;
    logic [1:0]  s_udp_ip_ecn;
    logic [7:0]  s_udp_ip_ttl;
    logic [31:0] s_udp_ip_source_ip;
    logic [31:0] s_udp_ip_dest_ip;
    logic [15:0] s_udp_source_port;
    logic [15:0] s_udp_dest_port;
    logic [15:0] s_udp_length;
    logic [15:0] s_udp_checksum;
    logic [7:0]  s_udp_payload_axis_tdata;
    logic        s_udp_payload_axis_tvalid;
    logic        s_udp_payload_axis_tready;
    logic        s_udp_payload_axis_tlast;
    logic        s_udp_payload_axis_tuser;
   
   /*
    * UDP output
    */
    logic        m_udp_hdr_valid;
    logic        m_udp_hdr_ready;
    logic [47:0] m_udp_eth_dest_mac;
    logic [47:0] m_udp_eth_src_mac;
    logic [15:0] m_udp_eth_type;
    logic [3:0]  m_udp_ip_version;
    logic [3:0]  m_udp_ip_ihl;
    logic [5:0]  m_udp_ip_dscp;
    logic [1:0]  m_udp_ip_ecn;
    logic [15:0] m_udp_ip_length;
    logic [15:0] m_udp_ip_identification;
    logic [2:0]  m_udp_ip_flags;
    logic [12:0] m_udp_ip_fragment_offset;
    logic [7:0]  m_udp_ip_ttl;
    logic [7:0]  m_udp_ip_protocol;
    logic [15:0] m_udp_ip_header_checksum;
    logic [31:0] m_udp_ip_source_ip;
    logic [31:0] m_udp_ip_dest_ip;
    logic [15:0] m_udp_source_port;
    logic [15:0] m_udp_dest_port;
    logic [15:0] m_udp_length;
    logic [15:0] m_udp_checksum;
    logic [63:0] m_udp_payload_axis_tdata;
    logic [7:0]  m_udp_payload_axis_tkeep;
    logic        m_udp_payload_axis_tvalid;
    logic        m_udp_payload_axis_tready;
    logic        m_udp_payload_axis_tlast;
    logic        m_udp_payload_axis_tuser;

endinterface : udp_if
