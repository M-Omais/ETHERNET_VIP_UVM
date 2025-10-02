// Sequence generates the stimulus and sends to driver via sequencer.

class udp_seq extends uvm_sequence #(udp_seq_item);

    `uvm_object_utils(udp_seq)

    // Constructor
    function new(string name = "udp_seq");
        super.new(name);
    endfunction

    // Body task → Logic to generate and send the sequence_item is added inside the body() method
    virtual task body();

        udp_seq_item item;
        `uvm_info(get_type_name(), "Sequence running...", UVM_LOW)
        
        
        // Create a new sequence item
        item = udp_seq_item::type_id::create("item");

        start_item(item);
          // Randomize with specific constraints for a seq UDP packet
        if (!item.randomize() with {
            s_udp_ip_dscp        == 0;
            s_udp_ip_ecn         == 0;
            s_udp_ip_ttl         == 8'd64;
            s_udp_ip_source_ip   == dut_ip; // 192.168.1.100
            s_udp_ip_dest_ip     == master_ip; // 192.168.1.102
            s_udp_source_port == 16'd1234;
            s_udp_dest_port   == 16'd5678;
            s_udp_length      == 16'd1234; // payload + header
            s_udp_checksum    == 16'h0; // (DUT may recalc)
            s_udp_payload_data.size() == 32;
            foreach(s_udp_payload_data[i]) s_udp_payload_data[i] == i;
            s_udp_payload_last    == 1;
            s_udp_payload_user    == 0;
        }) begin
            `uvm_error("SEQ", "Randomization failed for udp_seq_item")
        end

        finish_item(item);

        `uvm_info("SEQ", $sformatf("Generated UDP packet: src=%0d, dst=%0d, len=%0d",item.s_udp_source_port, item.s_udp_dest_port, item.s_udp_length), UVM_LOW)
    endtask

endclass
