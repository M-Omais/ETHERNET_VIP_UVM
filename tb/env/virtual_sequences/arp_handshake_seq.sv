class arp_handshake_seq extends uvm_sequence;
	`uvm_object_utils(arp_handshake_seq)
	`uvm_declare_p_sequencer(virtual_sequencer)

	function new(string name="arp_handshake_seq");
		super.new(name);
	endfunction

	task body();
		no_payload_seq sA;
		arp_seq sB;
		xgmii_seq sC;

		sA = no_payload_seq::type_id::create("sA");
		sB = arp_seq::type_id::create("sB");
		sC = xgmii_seq::type_id::create("sC");
		
		sA.start(p_sequencer.udp_sequencer_inst);
		#500;
		sB.start(p_sequencer.xgmii_sequencer_inst);
		#600;
		//sA.start(p_sequencer.udp_sequencer_inst);
	    //#500;
		//sC.start(p_sequencer.xgmii_sequencer_inst);
		//#600;
	endtask
endclass
