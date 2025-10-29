class arp_handshake_seq extends uvm_sequence;
	`uvm_object_utils(arp_handshake_seq)
	`uvm_declare_p_sequencer(virtual_sequencer)

	function new(string name="arp_handshake_seq");
		super.new(name);
	endfunction

	task body();
		no_payload_seq udp_send;
		arp_seq xgmii_send;

		udp_send = no_payload_seq::type_id::create("udp_send");
		xgmii_send = arp_seq::type_id::create("xgmii_send");
		udp_send.start(p_sequencer.axis_sequencer_inst);
		#500;
		xgmii_send.start(p_sequencer.xgmii_sequencer_inst);
		#500;

	endtask
endclass
