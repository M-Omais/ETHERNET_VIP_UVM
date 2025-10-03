class variable_ip_test extends base_test;
    `uvm_component_utils(variable_ip_test)

    function new(string name = "variable_ip_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase → construct env
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    // Run phase → kick off the variable_ip_seq
    task run_phase(uvm_phase phase);
        variable_ip_seq vseq;

        phase.raise_objection(this, "Starting variable_ip_test");

        // Create the virtual sequence
        vseq = variable_ip_seq::type_id::create("vseq");

        // Start on the virtual sequencer
        vseq.start(env.virtual_seqr);

        phase.drop_objection(this, "Finished variable_ip_test");
    endtask
endclass
