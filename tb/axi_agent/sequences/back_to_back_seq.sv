class back_to_back_seq extends uvm_sequence #(udp_seq_item);

	`uvm_object_utils(back_to_back_seq)

	// knobs
	rand int unsigned num_packets;          // how many packets to send
	     int unsigned delay;               // delay cycles between packets
	     int unsigned rp;                 // repeat count (per packet)

	constraint c_num { num_packets inside {[1:10]}; } // example constraint

	// Constructor
	function new(string name = "back_to_back_seq");
		super.new(name);
		num_packets = 10;   // default
		delay       = 0;    // default no delay
		rp          = 1;    // default repeat count
	endfunction

	// Body: generate packets back to back
	virtual task body();
		udp_seq_item item;

		`uvm_info(get_type_name(), $sformatf("Running back_to_back_seq: num_packets=%0d, delay=%0d, rp=%0d", num_packets, delay, rp), UVM_LOW);

		for (int i = 0; i < num_packets; i++) begin
			// Repeat sending the same packet if rp > 1
			for (int j = 0; j < rp; j++) begin
				item = udp_seq_item::type_id::create($sformatf("item_%0d_%0d", i, j));

				// Generate & randomize payload and headers
				`uvm_do_with(item, {s_udp_ip_dscp                                        == 0;
          									s_udp_ip_ecn                                         == 0;
          									s_udp_ip_ttl                                         == 8'd64;
          									s_udp_ip_source_ip                                   == dut_ip;     // e.g. 192.168.1.100
          									s_udp_ip_dest_ip                                     == master_ip;  // e.g. 192.168.1.102
          									s_udp_source_port                                    == 16'd1234;
          									s_udp_dest_port                                      == 16'd5678;
          									s_udp_payload_data.size() < 25 &&
                            s_udp_payload_data.size() > 23; // large payload
          									s_udp_length                                         == (s_udp_payload_data.size()*8) + 8; // random legal length
          									s_udp_checksum                                       == 16'h0;      // let DUT recalc
          									foreach(s_udp_payload_data[i]) s_udp_payload_data[i] == i;
          									s_udp_payload_last                                   == 1;
          									s_udp_payload_user                                   == 0;
				});

				`uvm_info("SEQ", $sformatf("Pkt %0d/%0d (rep %0d): src=%0d dst=%0d len=%0d payload_sz=%0d", i+1, num_packets, j+1,
				item.s_udp_source_port, item.s_udp_dest_port, item.s_udp_length, item.s_udp_payload_data.size()), UVM_LOW)
				// #1ns;
				#(delay);
			end
		end
	endtask

endclass
