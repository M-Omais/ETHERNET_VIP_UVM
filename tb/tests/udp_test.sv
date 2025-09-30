// Base Test: Creates driver + sequencer, connects them, and starts sequence
// UDP Test: After a ARP handshake, send a UDP packet with specific constraints
class udp_test extends base_test;
	`uvm_component_utils(udp_test)
	arp_handshake_seq           xseq;
	udp_seq                     seq;

    // Constructor
	function new(string name = "udp_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		xseq = arp_handshake_seq::type_id::create("xseq");
		seq = udp_seq::type_id::create("seq");
	endfunction


	// run_phase: start the sequence
	task run_phase(uvm_phase phase);

		phase.raise_objection(this);
		`uvm_info(get_type_name(), "Starting arp_handshake_seq...", UVM_LOW)
		xseq.start(env.virtual_seqr);

		`uvm_info(get_type_name(), "Starting udp_seq...", UVM_LOW)
		seq.start(env.udp_agent_inst.seqr); //define which sequencer the sequence should run on.
		# 1ns; 
		phase.drop_objection(this);
	endtask

endclass : udp_test
