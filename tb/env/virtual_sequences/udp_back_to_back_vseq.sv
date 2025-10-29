class udp_back_to_back_vseq extends uvm_sequence#(uvm_sequence_item);
  `uvm_object_utils(udp_back_to_back_vseq)
  `uvm_declare_p_sequencer(virtual_sequencer)
  arp_handshake_seq xseq;
  back_to_back_seq  b2b_seq;

	function new(string name="udp_back_to_back_vseq");
		super.new(name);
	endfunction

  task body();
    xseq = arp_handshake_seq::type_id::create("xseq");
    b2b_seq = back_to_back_seq::type_id::create("b2b_seq");
    `uvm_info(get_type_name(), "Starting ARP handshake...", UVM_LOW)
    xseq.start(p_sequencer);

    `uvm_info(get_type_name(), "Starting back-to-back UDP seq...", UVM_LOW)
    b2b_seq.num_packets = 12;
    b2b_seq.start(p_sequencer.udp_sequencer_inst);
  endtask
endclass
