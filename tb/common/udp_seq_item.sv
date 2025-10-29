//Sequence item: Fields required to generate the stimulus are declared in the sequence_item.

`include "uvm_macros.svh" // Include UVM Macros

class udp_seq_item extends uvm_sequence_item;

    // INPUT SIDE (s_udp_*) → fields used to drive stimulus into DUT
    rand bit [5:0]  s_udp_ip_dscp;
    rand bit [1:0]  s_udp_ip_ecn;
    rand bit [7:0]  s_udp_ip_ttl;
    rand bit [31:0] s_udp_ip_source_ip;
    rand bit [31:0] s_udp_ip_dest_ip;
    rand bit [15:0] s_udp_source_port;
    rand bit [15:0] s_udp_dest_port;
    rand bit [15:0] s_udp_length;
    rand bit [15:0] s_udp_checksum;
    
    rand bit [63:0] s_udp_payload_data[$];
    rand bit        s_udp_payload_last;
    rand bit        s_udp_payload_user;
    rand bit [7:0]  s_udp_payload_keep[$];

    // Keep array sizes aligned
    constraint payload_keep_size_c {
        s_udp_payload_keep.size() == s_udp_payload_data.size();
    }

    // force every beat valid (all bytes used)
    constraint payload_keep_full_c {
        foreach (s_udp_payload_keep[i]) s_udp_payload_keep[i] == 8'hFF;
    }

    // OUTPUT SIDE (m_udp_*) → fields observed from DUT
    bit        m_udp_hdr_valid;
    bit        m_udp_hdr_ready;
    bit [47:0] m_udp_eth_dest_mac;
    bit [47:0] m_udp_eth_src_mac;
    bit [15:0] m_udp_eth_type;

    bit [3:0]  m_udp_ip_version;
    bit [3:0]  m_udp_ip_ihl;
    bit [5:0]  m_udp_ip_dscp;
    bit [1:0]  m_udp_ip_ecn;
    bit [15:0] m_udp_ip_length;
    bit [15:0] m_udp_ip_identification;
    bit [2:0]  m_udp_ip_flags;
    bit [12:0] m_udp_ip_fragment_offset;
    bit [7:0]  m_udp_ip_ttl;
    bit [7:0]  m_udp_ip_protocol;
    bit [15:0] m_udp_ip_header_checksum;
    bit [31:0] m_udp_ip_source_ip;
    bit [31:0] m_udp_ip_dest_ip;

    bit [15:0] m_udp_source_port;
    bit [15:0] m_udp_dest_port;
    bit [15:0] m_udp_length;
    bit [15:0] m_udp_checksum;

    bit [63:0] m_udp_payload_data[$]; // collect packet payload words
    bit [7:0]  m_udp_payload_keep[$];
    bit        m_udp_payload_last;
    bit        m_udp_payload_user;


    //In order to use the uvm_object methods ( copy, compare, pack, unpack, record, print, and etc ), all the fields are registered to uvm_field_* macros.
    `uvm_object_utils_begin(udp_seq_item)
         // inputs
        `uvm_field_int(s_udp_ip_dscp,            UVM_ALL_ON)
        `uvm_field_int(s_udp_ip_ecn,             UVM_ALL_ON)
        `uvm_field_int(s_udp_ip_ttl,             UVM_ALL_ON)
        `uvm_field_int(s_udp_ip_source_ip,       UVM_ALL_ON)
        `uvm_field_int(s_udp_ip_dest_ip,         UVM_ALL_ON)
        `uvm_field_int(s_udp_source_port,        UVM_ALL_ON)
        `uvm_field_int(s_udp_dest_port,          UVM_ALL_ON)
        `uvm_field_int(s_udp_length,             UVM_ALL_ON)
        `uvm_field_int(s_udp_checksum,           UVM_ALL_ON)
        `uvm_field_array_int(s_udp_payload_data, UVM_ALL_ON)
        `uvm_field_array_int(s_udp_payload_keep, UVM_ALL_ON)
        `uvm_field_int(s_udp_payload_last,       UVM_ALL_ON)
        `uvm_field_int(s_udp_payload_user,       UVM_ALL_ON)

        // outputs
        `uvm_field_int(m_udp_hdr_valid,          UVM_ALL_ON)
        `uvm_field_int(m_udp_hdr_ready,          UVM_ALL_ON)
        `uvm_field_int(m_udp_eth_dest_mac,       UVM_ALL_ON)
        `uvm_field_int(m_udp_eth_src_mac,        UVM_ALL_ON)
        `uvm_field_int(m_udp_eth_type,           UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_version,         UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_ihl,             UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_dscp,            UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_ecn,             UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_length,          UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_identification,  UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_flags,           UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_fragment_offset, UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_ttl,             UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_protocol,        UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_header_checksum, UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_source_ip,       UVM_ALL_ON)
        `uvm_field_int(m_udp_ip_dest_ip,         UVM_ALL_ON)
        `uvm_field_int(m_udp_source_port,        UVM_ALL_ON)
        `uvm_field_int(m_udp_dest_port,          UVM_ALL_ON)
        `uvm_field_int(m_udp_length,             UVM_ALL_ON)
        `uvm_field_int(m_udp_checksum,           UVM_ALL_ON)
        `uvm_field_array_int(m_udp_payload_data, UVM_ALL_ON)
        `uvm_field_array_int(m_udp_payload_keep, UVM_ALL_ON)
        `uvm_field_int(m_udp_payload_last,       UVM_ALL_ON)
        `uvm_field_int(m_udp_payload_user,       UVM_ALL_ON)
    `uvm_object_utils_end   


    // Constructor
    function new(string name = "udp_seq_item");
        super.new(name);
    endfunction

    // INPUT logs
    function string convert2string_s_udp();
    return $sformatf(
        "\n==============================   \n    UDP INPUT (s_udp)   \n==============================   \n SrcPort : %0d \n DstPort : %0d \n Len : %0d \n SrcIP : %08h \n DstIP : %08h \n Chksum : %04h \n Payload : %p \n==============================",
        s_udp_source_port,
        s_udp_dest_port,
        s_udp_length,
        s_udp_ip_source_ip,
        s_udp_ip_dest_ip,
        s_udp_checksum,
        s_udp_payload_data
    );
    endfunction


    // OUTPUT logs
    function string convert2string_m_udp();
        string payload_str;
        payload_str = (m_udp_payload_data.size() == 0) ? "<empty>" : "";

        // Build payload string word-by-word
        foreach (m_udp_payload_data[i]) begin
            payload_str = {payload_str, $sformatf("%016h ", m_udp_payload_data[i])};
            if (((i+1) % 4) == 0) 
                payload_str = {payload_str, "\n                      "}; 
            // break every 4 words, indent under "Payload:"
        end

        return $sformatf(
            "\n==============================\n    UDP OUTPUT (m_udp)\n==============================\n MAC Dst   : 0x%012h\n MAC Src   : 0x%012h\n EthType   : 0x%04h\n------------------------------\n SrcPort   : %0d\n DstPort   : %0d\n Length    : %0d\n SrcIP     : 0x%08h\n DstIP     : 0x%08h\n Chksum    : 0x%04h\n------------------------------\n Payload   :          %s\n==============================",
            m_udp_eth_dest_mac,
            m_udp_eth_src_mac,
            m_udp_eth_type,
            m_udp_source_port,
            m_udp_dest_port,
            m_udp_length,
            m_udp_ip_source_ip,
            m_udp_ip_dest_ip,
            m_udp_checksum,
            payload_str
        );
    endfunction

endclass