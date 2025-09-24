class arp_handshake_seq extends uvm_sequence;
	`uvm_object_utils(arp_handshake_seq)
	`uvm_declare_p_sequencer(virtual_sequencer)

	function new(string name="arp_handshake_seq");
		super.new(name);
	endfunction

	task body();
		no_payload_seq sA;
		xgmii_seq sB;

		sA = no_payload_seq::type_id::create("sA");
		sB = xgmii_seq::type_id::create("sB");
		sA.start(p_sequencer.udp_sequencer_inst);
		sB.start(p_sequencer.xgmii_sequencer_inst);
		
	endtask
endclass
