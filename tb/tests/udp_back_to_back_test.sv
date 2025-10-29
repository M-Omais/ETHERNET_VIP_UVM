class udp_back_to_back_test extends base_test;
  `uvm_component_utils(udp_back_to_back_test)

  udp_back_to_back_vseq vseq;

	function new(string name = "udp_back_to_back_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
      vseq = udp_back_to_back_vseq::type_id::create("vseq");
	endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
      vseq.start(env.virtual_seqr);
    phase.drop_objection(this);
  endtask
endclass
