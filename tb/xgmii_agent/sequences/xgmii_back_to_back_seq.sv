class xgmii_back_to_back_seq extends uvm_sequence#(sq_item);
	`uvm_object_utils(xgmii_back_to_back_seq)

	// knobs
	rand int unsigned num_packets;   // how many frames to send
	int unsigned delay;              // cycles or time units to wait between frames
	int unsigned rp;                 // repeat count per frame

	constraint c_num { num_packets inside {[1:100]}; }

	function new(string name = "xgmii_back_to_back_seq");
		super.new(name);
		num_packets = 5;   // default
		delay       = 0;   // no delay
		rp          = 1;   // no repetition
	endfunction

	virtual task body();
		sq_item tr;

		`uvm_info(get_type_name(), $sformatf("Running XGMII back-to-back seq: num_packets=%0d, rp=%0d, delay=%0d", num_packets, rp, delay), UVM_LOW);

		for (int i = 0; i < num_packets; i++) begin
			for (int j = 0; j < rp; j++) begin
				tr = sq_item::type_id::create($sformatf("xgmii_item_%0d_%0d", i, j));
				`uvm_do_with(tr, { src_addr == master_mac;
								dst_addr == dut_mac;
								eth_type == 16'h0800;
								src_ip   == master_ip;
								dst_ip   == dut_ip;
								src_port == 16'd5678;
								dst_port == 16'd1234;
								payload.size() > 64 && payload.size() < 256 && payload.size() % 8 == 0;
								foreach (payload[k]) payload[k] == k;
								})

				`uvm_info("XGMII_SEQ", $sformatf("Frame %0d/%0d (repeat %0d): Src=%012h Dst=%012h Len=%0d",
							i+1, num_packets, j+1, tr.src_addr, tr.dst_addr, tr.payload.size()), UVM_MEDIUM);

				// Optional delay
				// if (delay > 0 && !(i == num_packets-1 && j == rp-1)) begin
				// // choose your style: either cycle-based or time-based
				// // repeat (delay) @(posedge p_sequencer.vif.clk);
				#(delay);
				// end
			end
		end
	endtask

endclass
