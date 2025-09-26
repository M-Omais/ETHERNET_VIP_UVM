// Sequence generates the stimulus and sends to driver via sequencer.

class no_payload_seq extends uvm_sequence #(udp_seq_item);
    `uvm_object_utils(no_payload_seq)

    // Constructor
    function new(string name = "no_payload_seq");
        super.new(name);
    endfunction
    // Body task → Logic to generate and send the sequence_item is added inside the body() method
    virtual task body();
        udp_seq_item item;
        `uvm_info(get_type_name(), "Sequence running...", UVM_LOW);
		item = udp_seq_item::type_id::create("item");
		// Use uvm_do to create and randomize the sequence item with constraints
		`uvm_do_with(item, {
			s_udp_ip_dscp        == 0;
			s_udp_ip_ecn         == 0;
			s_udp_ip_ttl         == 8'd64;
			s_udp_ip_source_ip   == dut_ip; // 192.168.1.100
			s_udp_ip_dest_ip     == master_ip; // 192.168.1.102
			s_udp_source_port == 16'd1234;
			s_udp_dest_port   == 16'd5678;
			s_udp_length      == 16'd1234; // payload + header
			s_udp_checksum    == 16'h0; // (DUT may recalc)
			s_udp_payload_data.size() == 5;
			foreach(s_udp_payload_data[i]) s_udp_payload_data[i] == i;
			s_udp_payload_last    == 1;
			s_udp_payload_user    == 0;
		});

        // `uvm_info("SEQ", $sformatf("Generated UDP packet: src=%0d, dst=%0d, len=%0d",item.udp_source_port, item.udp_dest_port, item.udp_length), UVM_LOW)
    endtask

endclass
