// Test: Perform ARP handshake, then run UDP + XGMII back-to-back sequences in parallel
class udp_xgmii_parallel_test extends base_test;
    `uvm_component_utils(udp_xgmii_parallel_test)

    arp_handshake_seq        xseq;
    back_to_back_seq         udp_b2b_seq;
    xgmii_back_to_back_seq   xgmii_b2b_seq;

    // Constructor
    function new(string name = "udp_xgmii_parallel_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        xseq          = arp_handshake_seq       ::type_id::create("xseq", this);
        udp_b2b_seq   = back_to_back_seq        ::type_id::create("udp_b2b_seq");
        xgmii_b2b_seq = xgmii_back_to_back_seq  ::type_id::create("xgmii_b2b_seq");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting ARP handshake...", UVM_LOW)
        xseq.start(env.virtual_seqr);
        #1ns;
        // Configure sequences before starting
        udp_b2b_seq.num_packets   = 1;
        udp_b2b_seq.rp            = 2;
        udp_b2b_seq.delay         = 500;

        xgmii_b2b_seq.num_packets = 1;
        xgmii_b2b_seq.rp          = 2;
        xgmii_b2b_seq.delay       = 1000;

        `uvm_info(get_type_name(), "Starting UDP + XGMII back-to-back sequences in parallel", UVM_LOW)

        fork
            begin
                udp_b2b_seq.start(env.udp_agent_inst.seqr);
            end
            begin
                xgmii_b2b_seq.start(env.xgmii_agent_inst.sqr);
            end
        join

        #1ns;
        phase.drop_objection(this);
    endtask

endclass : udp_xgmii_parallel_test
