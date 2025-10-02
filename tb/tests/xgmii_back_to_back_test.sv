// Test: Perform ARP handshake, then run xgmii_back_to_back_seq (multiple XGMII frames)
class xgmii_back_to_back_test extends base_test;
    `uvm_component_utils(xgmii_back_to_back_test)

    arp_handshake_seq        xseq;
    xgmii_back_to_back_seq   b2b_xgmii;

    // Constructor
    function new(string name = "xgmii_back_to_back_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        xseq      = arp_handshake_seq       ::type_id::create("xseq", this);
        b2b_xgmii = xgmii_back_to_back_seq  ::type_id::create("b2b_xgmii");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting arp_handshake_seq...", UVM_LOW)
        xseq.start(env.virtual_seqr);

        `uvm_info(get_type_name(), "Starting xgmii_back_to_back_seq...", UVM_LOW)
        // Configure back-to-back sequence knobs
        b2b_xgmii.num_packets = 12;   // total number of frames
        b2b_xgmii.rp          = 2;    // repeat count per frame
        b2b_xgmii.delay       = 1000; // gap between frames (cycles or time)

        b2b_xgmii.start(env.xgmii_agent_inst.sqr);

        // #1ns;
        phase.drop_objection(this);
    endtask

endclass : xgmii_back_to_back_test
