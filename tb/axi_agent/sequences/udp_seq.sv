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
            ip_dscp        == 0;
            ip_ecn         == 0;
            ip_ttl         == 8'd64;
            ip_source_ip   == 32'hc0a80164; // 192.168.1.100
            ip_dest_ip     == 32'hc0a80166; // 192.168.1.102
            udp_source_port == 16'd1234;
            udp_dest_port   == 16'd5678;
            udp_length      == 16'd1234; // payload + header
            udp_checksum    == 16'h0; // (DUT may recalc)
            payload_data.size() == 32;
            foreach(payload_data[i]) payload_data[i] == i;
            payload_last    == 1;
            payload_user    == 0;
        }) begin
            `uvm_error("SEQ", "Randomization failed for udp_seq_item")
        end

        finish_item(item);

        `uvm_info("SEQ", $sformatf("Generated UDP packet: src=%0d, dst=%0d, len=%0d",item.udp_source_port, item.udp_dest_port, item.udp_length), UVM_LOW)
    endtask

endclass
