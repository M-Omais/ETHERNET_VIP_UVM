//Fields required to generate the stimulus are declared in the sequence_item.

`include "uvm_macros.svh" // Include UVM Macros

class udp_seq_item extends uvm_sequence_item;

    // UDP header fields
    rand bit [5:0]  ip_dscp;
    rand bit [1:0]  ip_ecn;
    rand bit [7:0]  ip_ttl;
    rand bit [31:0] ip_source_ip;
    rand bit [31:0] ip_dest_ip;
    rand bit [15:0] udp_source_port;
    rand bit [15:0] udp_dest_port;
    rand bit [15:0] udp_length;
    rand bit [15:0] udp_checksum;

    // Payload (we’ll send byte by byte for now)
    rand bit [7:0]  payload_data[$];
    rand bit        payload_last;
    rand bit        payload_user;

    //In order to use the uvm_object methods ( copy, compare, pack, unpack, record, print, and etc ), all the fields are registered to uvm_field_* macros.
    `uvm_object_utils_begin(udp_seq_item)
        `uvm_field_int(ip_dscp,         UVM_ALL_ON)
        `uvm_field_int(ip_ecn,          UVM_ALL_ON)
        `uvm_field_int(ip_ttl,          UVM_ALL_ON)
        `uvm_field_int(ip_source_ip,    UVM_ALL_ON)
        `uvm_field_int(ip_dest_ip,      UVM_ALL_ON)
        `uvm_field_int(udp_source_port, UVM_ALL_ON)
        `uvm_field_int(udp_dest_port,   UVM_ALL_ON)
        `uvm_field_int(udp_length,      UVM_ALL_ON)
        `uvm_field_int(udp_checksum,    UVM_ALL_ON)
        `uvm_field_array_int(payload_data, UVM_ALL_ON)
        `uvm_field_int(payload_last,    UVM_ALL_ON)
        `uvm_field_int(payload_user,    UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "udp_seq_item");
        super.new(name);
    endfunction

    // Pretty print for logs
    function string convert2string();
        return $sformatf({"--------------------------------------\n","UDP Packet:\n",
        "  Src Port = %0d\n","  Dst Port = %0d\n","  Length   = %0d\n","  Src IP   = %0h\n","  Dst IP   = %0h\n","  Checksum = %0h\n","  Payload  = %p\n","--------------------------------------"},
        udp_source_port,udp_dest_port,udp_length,ip_source_ip,ip_dest_ip,udp_checksum,payload_data);
    endfunction

endclass