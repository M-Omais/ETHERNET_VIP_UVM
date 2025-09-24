// Base Test: Creates driver + sequencer, connects them, and starts sequence
class handshake_test extends base_test;
	`uvm_component_utils(handshake_test)
	arp_handshake_seq           seq;
	function new(string name = "handshake_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seq = arp_handshake_seq::type_id::create("seq");
		// xseq = xgmii_seq::type_id::create("xseq");
	endfunction


	// run_phase: start the sequence
	task run_phase(uvm_phase phase);
		seq = arp_handshake_seq::type_id::create("seq");
		phase.raise_objection(this);
		`uvm_info(get_type_name(), "Starting arp_handshake_seq...", UVM_LOW)
		seq.start(env.virtual_seqr); 
		# 5ns; 
		phase.drop_objection(this);
	endtask

endclass : handshake_test
