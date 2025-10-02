class xgmii_seq extends uvm_sequence#(sq_item);
	`uvm_object_utils(xgmii_seq)
	function new(string name = "xgmii_seq");
		super.new(name);
	endfunction

	virtual task body();
		sq_item tr;
		`uvm_do_with(tr, {src_addr == master_mac;
							dst_addr == dut_mac;
							eth_type == 16'h0800;
							src_ip == master_ip;
							dst_ip == dut_ip;
							src_port == 16'd5678;
							dst_port == 16'd1234;
							// payload.size() inside {[0:512]};
							payload.size() == 256;
							foreach(payload[i]) payload[i] == i;})

	endtask

endclass