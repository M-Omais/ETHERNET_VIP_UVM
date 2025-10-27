// Test: Perform ARP handshake, then run back_to_back_seq (multiple UDP pkts)
class udp_back_to_back_test extends base_test;
  `uvm_component_utils(udp_back_to_back_test)

  arp_handshake_seq    xseq;
  back_to_back_seq     b2b_seq;

  // Constructor
  function new(string name = "udp_back_to_back_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    xseq     = arp_handshake_seq::type_id::create("xseq", this);
    b2b_seq  = back_to_back_seq::type_id::create("b2b_seq");
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Starting arp_handshake_seq...", UVM_LOW)
    // start ARP handshake sequence first
    xseq.start(env.virtual_seqr);

    `uvm_info(get_type_name(), "Starting back_to_back_seq...", UVM_LOW)
    // configure back-to-back sequence knobs before starting
    b2b_seq.num_packets = 12;  // for example
    b2b_seq.rp          = 2;  // repeat count per packet
    b2b_seq.delay       = 1000; // inter-packet delay (cycles or time, depending on seq code)

    b2b_seq.start(env.udp_agent_inst.seqr);

    phase.drop_objection(this);
  endtask

endclass : udp_back_to_back_test
