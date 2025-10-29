class variable_hanshake_seq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(variable_hanshake_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

	bit [47:0] custom_mac ;
	bit [31:0] custom_ip  ;

  function new(string name="variable_hanshake_seq");
      super.new(name);
      custom_mac = 48'h5a5152535455; // Master MAC address
      custom_ip  = 32'hc0a80164;     // Master IP address
  endfunction

  task body();
    udp_seq_item   udp_item;
    xgmii_seq_item arp_item;

    `uvm_info(get_type_name(), "ARP Handshake Sequence running...", UVM_LOW);

    // -----------------------------
    // Step 1: Generate a UDP packet
    // -----------------------------
    udp_item = udp_seq_item::type_id::create("udp_item");
    `uvm_do_on_with(udp_item,  p_sequencer.axis_sequencer_inst, {
      s_udp_ip_dscp                                        == 0;
      s_udp_ip_ecn                                         == 0;
      s_udp_ip_ttl                                         == 8'd64;
      s_udp_ip_source_ip                                   == dut_ip;     // 192.168.1.100
      s_udp_ip_dest_ip                                     == custom_ip;  // 192.168.1.102
      s_udp_source_port                                    == 16'd1234;
      s_udp_dest_port                                      == 16'd5678;
      s_udp_length                                         == 16'd1234;  // payload + header
      s_udp_checksum                                       == 16'h0;     // (DUT may recalc)
      s_udp_payload_data.size()                            == 5;
      foreach(s_udp_payload_data[i]) s_udp_payload_data[i] == i;
      s_udp_payload_last                                   == 1;
      s_udp_payload_user                                   == 0;
    });
    #500;
    // -----------------------------
    // Step 2: Generate an ARP frame
    // -----------------------------
    arp_item = xgmii_seq_item::type_id::create("arp_item");
    `uvm_do_on_with(arp_item, p_sequencer.xgmii_sequencer_inst, {
        src_addr == custom_mac;
        dst_addr == dut_mac;
        eth_type == 16'h0806;   // ARP
        src_ip   == custom_ip;
        dst_ip   == dut_ip;
    });

  endtask
endclass
