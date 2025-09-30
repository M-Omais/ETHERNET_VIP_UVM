
// Base Test: Creates driver + sequencer, connects them, and starts sequence
// UDP Test: Sends a UDP packet with specific constraints after a ARP handshake
class udp_test extends base_test;
	`uvm_component_utils(udp_test)
	udp_seq           seq;
	arp_seq xseq;
	// Constructor
	function new(string name = "udp_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seq = udp_seq::type_id::create("seq");
		xseq = arp_seq::type_id::create("xseq");
	endfunction


	// run_phase: start the sequence
	task run_phase(uvm_phase phase);
		seq = udp_seq::type_id::create("seq");
		phase.raise_objection(this);
		`uvm_info(get_type_name(), "Starting udp_seq...", UVM_LOW)
		xseq.start(env.xgmii_agent_inst.sqr);
		// #10ns;
		seq.start(env.udp_agent_inst.seqr); //define which sequencer the sequence should run on.
		# 10ns; 
		phase.drop_objection(this);
	endtask

endclass : udp_test
