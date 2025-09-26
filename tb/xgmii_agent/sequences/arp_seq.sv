class arp_seq extends uvm_sequence#(sq_item);
	`uvm_object_utils(arp_seq)
	function new(string name = "arp_seq");
		super.new(name);
	endfunction

	virtual task body();
		sq_item tr;
		`uvm_do_with(tr, {src_addr == master_mac;
							dst_addr == dut_mac;
							eth_type == 16'h0806;
							src_ip == master_ip;
							dst_ip == dut_ip;})

	endtask

endclass