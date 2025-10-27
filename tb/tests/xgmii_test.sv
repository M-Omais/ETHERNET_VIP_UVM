// Base Test: Creates driver + sequencer, connects them, and starts sequence
// Xgmii Test: After a ARP handshake, send a Xgmii packet with specific constraints
class xgmii_test extends base_test;
	`uvm_component_utils(xgmii_test)
	arp_handshake_seq           xseq;
	xgmii_seq                    seq;

    // Constructor
	function new(string name = "xgmii_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		xseq = arp_handshake_seq::type_id::create("xseq");
		seq = xgmii_seq::type_id::create("seq");
	endfunction

	// run_phase: start the sequence
	task run_phase(uvm_phase phase);

		phase.raise_objection(this);
		`uvm_info(get_type_name(), "Starting arp_handshake_seq...", UVM_LOW)
		xseq.start(env.virtual_seqr);

		`uvm_info(get_type_name(), "Starting xgmii_seq...", UVM_LOW)
		seq.start(env.xgmii_agent_inst.seqr); //define which sequencer the sequence should run on.
		# 1ns; 
		phase.drop_objection(this);
	endtask

endclass : xgmii_test
